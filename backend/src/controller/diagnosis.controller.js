import { analyzeImageService, saveDiagnosisService, getUserDiagnosesService } from "../services/diagnosis.service.js";

/* analyze (HF only) */
export const analyzeDiagnosis = async (req, res) => {
    try {
        if (!req.file) {
            return res.status(400).json({ error: "Image file is required" });
        }

        const prediction = await analyzeImageService(req.file);

        res.json(prediction);
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

/* SAVE DIAGNOSIS  */
export const saveDiagnosis = async (req, res) => {
    try {
        const userId = req.user.id;

        const { flul_name, symptoms, affected_area, probabilty, age, gender } = req.body;

        if(!flul_name || !symptoms || !affected_area || !probabilty === undefined) {
            return res.status(400).json({
                success: false,
                message: "Missing required fields."
            });
        }

        const diagnosis = await saveDiagnosisService(userId, req.body);

        res.status(200).json({
            message: "Diagnosis saved successfully",
            diagnosis
        });
    } catch (error) {
        res.status(500).json({ error: error.message });
    }
};

/*  GET DIAGNOSIS HISTORY*/
export const getUserDiagnoses = async (req, res) => {
    try {
        const userId = req.user.id;

        const diagnoses = await getUserDiagnosesService(userId);

        return res.status(200).json({
            success: true,
            data: diagnoses
        });
    } catch (error) {
        res.status(500).json({ 
            success: false,
            error: error.message 
        });
    }
};
