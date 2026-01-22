import express from "express";
import { chatWithAI ,getChatHistory } from "../controller/chat.controller.js";
import { verifyToken } from "../middlewares/auth.middleware.js";

const router = express.Router();

router.post("/chat", verifyToken, chatWithAI);
router.get("/chat/history", verifyToken, getChatHistory);

export default router;
