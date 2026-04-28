import express from "express";
import { supabaseAdmin } from "../config/supabase.js";
import authMiddleware from "../middlewares/auth.middleware.js";

const devicetoken_router = express.Router();

devicetoken_router.post("/save-device-token",authMiddleware, async (req, res) => {
  try {
    const userId = req.user.id; // from auth middleware
    const { device_token } = req.body;

    if (!device_token) {
      return res.status(400).json({ error: "Token required" });
    }

    const { error } = await supabaseAdmin
      .from("profiles")
      .update({ device_token })
      .eq("id", userId);

    if (error) {
      return res.status(500).json({ error: error.message });
    }

    console.log("Token saved for user:", userId);

    res.json({ success: true });
  } catch (err) {
    res.status(500).json({ error: err.message });
  }
});

export default devicetoken_router;