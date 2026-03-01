import express from "express";
import multer from "multer";
import { verifyToken } from "../middlewares/auth.middleware.js";
import{ saveDiagnosis, getUserDiagnoses,createDiagnosis,getAllPatients } from "../controller/diagnosis.controller.js";

const diagnosis_router = express.Router();
const upload = multer({ dest: "uploads/" });

// //Analyze image (HF only, no DB)
// diagnosis_router.post("/analyze", verifyToken, upload.single("file"), analyzeDiagnosis);
//Aave diagnosis to DB
diagnosis_router.post("/save", verifyToken, saveDiagnosis);

//Create diagnosis (analyze + save)
diagnosis_router.post(  "/create",  verifyToken,  upload.single("file"),  createDiagnosis);

//Get user diagnosis history
diagnosis_router.get("/", verifyToken, getUserDiagnoses);



diagnosis_router.get("/patients/all", verifyToken, getAllPatients);

export default diagnosis_router;