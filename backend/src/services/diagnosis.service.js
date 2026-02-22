import fs from "fs";
import FormData from "form-data";
import { supabaseAdmin } from "../config/supabase.js";
import fetch from "node-fetch";


/*  ANALYZE IMAGE (HF SPACE)  */
export const analyzeImageService = async (file) => {
    const form = new FormData();
    form.append("file", fs.createReadStream(file.path));

    const response = await fetch(
        "https://tes112t-leprosy.hf.space/predict",
        {
            method: "POST",
            body: form,
            headers: form.getHeaders()
        }
    );

    if (!response.ok) {
        throw new Error("Failed to analyze image");
    }

    return response.json();
};

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