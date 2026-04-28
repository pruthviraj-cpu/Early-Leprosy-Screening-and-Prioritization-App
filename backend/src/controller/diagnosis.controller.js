import { saveDiagnosisService, getUserDiagnosesService, createDiagnosisService, getAllPatientsService,updateDoctorReviewService ,getPatientByIdService} from "../services/diagnosis.service.js";
import fs from "fs";

export const saveDiagnosis = async (req, res) => {
    try {
        const userId = req.user.id;

        const { full_name, symptoms, affected_area, probability, age, gender } = req.body;

        if (!full_name || !symptoms || !affected_area || probability === undefined) {
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

export const createDiagnosis = async (req, res) => {
    try {
        const userId = req.user.id;


        if (!req.file) {
            return res.status(400).json({
                success: false,
                message: "Image file is required"
            });
        }

        const result = await createDiagnosisService(
            userId,
            req.file,
            req.body
        );

        // remove temp file
        fs.unlinkSync(req.file.path);

        return res.status(200).json({
            success: true,
            message: "Diagnosis stored successfully",
            data: result
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

export const getAllPatients = async (req, res) => {
    try {
        // Optional: Restrict to doctors only
        if (req.user.role !== "doctor") {
            return res.status(403).json({
                success: false,
                message: "Access restricted to doctors and admins only"
            });
        }

        const patients = await getAllPatientsService();

        return res.status(200).json({
            success: true,
            count: patients.length,
            data: patients
        });
    } catch (error) {
        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
};


export const updateDoctorReview = async (req, res) => {
    try {
        // Check if user is doctor
        if (req.user.role !== "doctor") {
            return res.status(403).json({
                success: false,
                message: "Only doctors can update reviews"
            });
        }

        const { diagnosisId } = req.params;
        const { doctor_review } = req.body;
        const doctorId = req.user.id;

        if (!diagnosisId || !doctor_review) {
            return res.status(400).json({
                success: false,
                message: "Diagnosis ID and review are required"
            });
        }

        const updatedDiagnosis = await updateDoctorReviewService(
            diagnosisId,
            doctorId,
            doctor_review
        );

        return res.status(200).json({
            success: true,
            message: "Doctor review updated successfully",
            data: updatedDiagnosis
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
};

export const getPatientById = async (req, res) => {
    try {
        const { diagnosisId } = req.params;

        if (!diagnosisId) {
            return res.status(400).json({
                success: false,
                message: "Diagnosis ID is required"
            });
        }

        const patient = await getPatientByIdService(diagnosisId);

        return res.status(200).json({
            success: true,
            data: patient
        });

    } catch (error) {
        return res.status(500).json({
            success: false,
            error: error.message
        });
    }
};