import fs from "fs";
import FormData from "form-data";
import { supabaseAdmin } from "../config/supabase.js";
import fetch from "node-fetch";


// /*  ANALYZE IMAGE (HF SPACE)  */
// export const analyzeImageService = async (file) => {
//     const form = new FormData();
//     form.append("file", fs.createReadStream(file.path));

//     const response = await fetch(
//         "https://tes112t-leprosy.hf.space/predict",
//         {
//             method: "POST",
//             body: form,
//             headers: form.getHeaders()
//         }
//     );

//     if (!response.ok) {
//         throw new Error("Failed to analyze image");
//     }

//     return response.json();
// };


/*  SAVE DIAGNOSIS  */
export const saveDiagnosisService = async (userId, payload) => {
    const { full_name, symptoms, affected_area, number, probability, age, gender, latitude, longitude, image_url } = payload;

    const { data, error } = await supabaseAdmin
        .from("diagnosis_results")
        .insert({ user_id: userId, full_name, symptoms, affected_area, number, probability, age, gender, latitude, longitude, image_url })
        .select()
        .single();

    if (error) throw new Error(error.message);

    return data;
};



/*  GET USER DIAGNOSES  */
export const getUserDiagnosesService = async (userId) => {
    const { data, error } = await supabaseAdmin
        .from("diagnosis_results")
        .select("*")
        .eq("user_id", userId)
        .order("created_at", { ascending: false });

    if (error) throw new Error(error.message);

    return data;
};



export const createDiagnosisService = async (userId, file, body) => {
    try {
        if (!file) {
            throw new Error("File not provided");
        }

        /* 1️⃣ SEND IMAGE TO HF */

        const form = new FormData();
        form.append("file", fs.createReadStream(file.path));

        const response = await fetch(
            "https://tes112t-leprosy.hf.space/predict",
            {
                method: "POST",
                body: form,
                headers: form.getHeaders() // IMPORTANT HERE
            }
        );

        if (!response.ok) {
            const text = await response.text();
            console.log("HF ERROR:", text);
            throw new Error("HF API failed");
        }

        const prediction = await response.json();
        console.log("HF RESPONSE:", prediction);

        /* 2️⃣ READ FILE BUFFER (ONLY FOR SUPABASE) */

        const fileBuffer = fs.readFileSync(file.path);

        const fileExt = file.originalname.split(".").pop();
        const filePath = `${userId}/${Date.now()}.${fileExt}`;

        const { error: uploadError } = await supabaseAdmin.storage
            .from("Skin_images")
            .upload(filePath, fileBuffer, {
                contentType: file.mimetype,
            });

        if (uploadError) {
            throw new Error(uploadError.message);
        }

        /* 3️⃣ INSERT INTO DB */

        const {
            symptoms,
            affected_area,
            age,
            gender,
            latitude,
            longitude,
            full_name
        } = body;

        const { data, error } = await supabaseAdmin
            .from("diagnosis_results")
            .insert({
                user_id: userId,
                full_name,
                probability: prediction.score,
                diagnosis_result: prediction.decision,
                symptoms,
                affected_area,
                age,
                gender,
                latitude,
                longitude,
                image_url: filePath
            })
            .select()
            .single();

        if (error) {
            throw new Error(error.message);
        }

        return data;

    } catch (error) {
        console.error("CREATE DIAGNOSIS ERROR:", error.message);
        throw error;
    }
};




export const getAllPatientsService = async () => {
    try {
        // Get all diagnosis results
        const { data: diagnoses, error: diagnosesError } = await supabaseAdmin
            .from("diagnosis_results")
            .select(`
                id,
                user_id,
                full_name,
                probability,
                diagnosis_result,
                symptoms,
                affected_area,
                age,
                gender,
                image_url,
                latitude,
                longitude,
                number,
                created_at
            `)
            .order("created_at", { ascending: false });

        if (diagnosesError) throw new Error(diagnosesError.message);

        if (!diagnoses || diagnoses.length === 0) {
            return [];
        }

        // Get all unique user IDs
        const userIds = [...new Set(diagnoses.map(d => d.user_id))];

        // Fetch profiles for these users
        const { data: profiles, error: profilesError } = await supabaseAdmin
            .from("profiles")
            .select(`
                id,
                email,
                role,
                phone
            `)
            .in("id", userIds);

        if (profilesError) throw new Error(profilesError.message);

        // Create a map of profiles by user_id
        const profilesMap = new Map();
        profiles?.forEach(profile => {
            profilesMap.set(profile.id, profile);
        });


        // !just changing for now will update further
        // Group by patient
        // const patientsMap = new Map();

        // diagnoses.forEach((item) => {
        //     const patientId = item.user_id;
        //     const profile = profilesMap.get(patientId);

        //     // ✅ FIX: Handle image URL properly
        //     let imageUrl = null;
        //     if (item.image_url) {
        //         // Check if it's already a full URL or just a path
        //         if (item.image_url.startsWith('http')) {
        //             imageUrl = item.image_url;
        //         } else {
        //             const { data: publicUrlData } = supabaseAdmin.storage
        //                 .from("Skin_images")
        //                 .getPublicUrl(item.image_url);
        //             imageUrl = publicUrlData.publicUrl;
        //         }
        //     }

        //     if (!patientsMap.has(patientId)) {
        //         patientsMap.set(patientId, {
        //             patient_id: patientId,
        //             full_name: item.full_name,
        //             email: profile?.email || null,
        //             phone: profile?.phone || item.number || null, // Use number from diagnosis if available
        //             role: profile?.role || 'patient',
        //             age: item.age,
        //             gender: item.gender,
        //             latest_diagnosis: {
        //                 id: item.id,
        //                 probability: item.probability,
        //                 diagnosis_result: item.diagnosis_result,
        //                 symptoms: item.symptoms,
        //                 affected_area: item.affected_area,
        //                 image_url: imageUrl,
        //                 latitude: item.latitude,
        //                 longitude: item.longitude,
        //                 created_at: item.created_at
        //             },
        //             diagnosis_count: 1,
        //             all_diagnoses: [{
        //                 id: item.id,
        //                 probability: item.probability,
        //                 diagnosis_result: item.diagnosis_result,
        //                 created_at: item.created_at,
        //                 image_url: imageUrl
        //             }]
        //         });
        //     } else {
        //         const patient = patientsMap.get(patientId);
        //         patient.diagnosis_count += 1;

        //         patient.all_diagnoses.push({
        //             id: item.id,
        //             probability: item.probability,
        //             diagnosis_result: item.diagnosis_result,
        //             created_at: item.created_at,
        //             image_url: imageUrl
        //         });

        //         // Update latest diagnosis if newer
        //         if (new Date(item.created_at) > new Date(patient.latest_diagnosis.created_at)) {
        //             patient.latest_diagnosis = {
        //                 id: item.id,
        //                 probability: item.probability,
        //                 diagnosis_result: item.diagnosis_result,
        //                 symptoms: item.symptoms,
        //                 affected_area: item.affected_area,
        //                 image_url: imageUrl,
        //                 latitude: item.latitude,
        //                 longitude: item.longitude,
        //                 created_at: item.created_at
        //             };
        //         }
        //     }
        // });

        // const patients = Array.from(patientsMap.values());
        // return patients;
        // Return all diagnoses as flat list (one case per item)
        const enrichedDiagnoses = diagnoses.map((item) => {
            const profile = profilesMap.get(item.user_id);

            let imageUrl = null;
            if (item.image_url) {
                if (item.image_url.startsWith("http")) {
                    imageUrl = item.image_url;
                } else {
                    const { data } = supabaseAdmin.storage
                        .from("Skin_images")
                        .getPublicUrl(item.image_url);
                    imageUrl = data.publicUrl;
                }
            }

            return {
                id: item.id,
                user_id: item.user_id,
                full_name: item.full_name,
                email: profile?.email || null,
                phone: profile?.phone || item.number || null,
                role: profile?.role || "patient",
                age: item.age,
                gender: item.gender,
                probability: item.probability,
                diagnosis_result: item.diagnosis_result,
                symptoms: item.symptoms,
                affected_area: item.affected_area,
                image_url: imageUrl,
                latitude: item.latitude,
                longitude: item.longitude,
                created_at: item.created_at
            };
        });

        return enrichedDiagnoses;

    } catch (error) {
        console.error("GET ALL PATIENTS ERROR:", error.message);
        throw error;
    }
};