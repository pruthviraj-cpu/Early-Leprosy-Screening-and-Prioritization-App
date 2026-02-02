import fs from "fs";
import FormData from "form-data";
import { supabaseAdmin } from "../config/supabase.js";

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
    const { flul_name, symptoms, affected_area, number, probability, age, gender, latitude, longitude, image_url } = payload;

    const { data, error } = await supabaseAdmin
        .from("diagnosis_results")
        .insert({ user_id: userId, flul_name, symptoms, affected_area, number, probability, age, gender, latitude, longitude, image_url })
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