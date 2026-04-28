import express from "express";
import multer from "multer";
import { verifyToken } from "../middlewares/auth.middleware.js";
import{ saveDiagnosis, getUserDiagnoses,createDiagnosis,getAllPatients ,updateDoctorReview, getPatientById } from "../controller/diagnosis.controller.js";

const diagnosis_router = express.Router();
const upload = multer({ dest: "uploads/" });

diagnosis_router.post("/save", verifyToken, saveDiagnosis);
diagnosis_router.post(  "/create",  verifyToken,  upload.single("file"),  createDiagnosis);
diagnosis_router.get("/", verifyToken, getUserDiagnoses);
diagnosis_router.put("/:diagnosisId/review", verifyToken, updateDoctorReview);
diagnosis_router.get("/:diagnosisId", verifyToken, getPatientById);
diagnosis_router.get("/patients/all", verifyToken, getAllPatients);

export default diagnosis_router;