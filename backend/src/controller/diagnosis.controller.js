import {  saveDiagnosisService, getUserDiagnosesService,createDiagnosisService,getAllPatientsService } from "../services/diagnosis.service.js";
import fs from "fs";

/* analyze (HF only) */
// export const analyzeDiagnosis = async (req, res) => {
//     try {
//         if (!req.file) {
//             return res.status(400).json({ error: "Image file is required" });
//         }

//         const prediction = await analyzeImageService(req.file);

//         res.json(prediction);
//     } catch (error) {
//         res.status(500).json({ error: error.message });
//     }
// };

/* SAVE DIAGNOSIS  */
export const saveDiagnosis = async (req, res) => {
    try {
        const userId = req.user.id;

        const { full_name, symptoms, affected_area, probability, age, gender } = req.body;

        if(!full_name || !symptoms || !affected_area  || probability === undefined) {
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


/*  DOCTOR LEDGER CONTROLLER  */


export const getAllPatients = async (req, res) => {
    try {
        // Optional: Restrict to doctors only
        if (req.user.role !== "doctor" ) {
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