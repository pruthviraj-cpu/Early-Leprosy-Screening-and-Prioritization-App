import { generateAIResponse } from "../services/chat.service.js";
import { supabaseAdmin } from "../config/supabase.js";

export const chatWithAI = async (req, res) => {
  try {
    const { message } = req.body;
    const userId = req.user.id;

    // 1️⃣ Generate AI reply
    const aiReply = await generateAIResponse(message);

    // 2️⃣ Save USER message
    const { error: userError } = await supabaseAdmin
      .from("ai_chats")
      .insert({
        user_id: userId,
        role: "user",
        message: message
      });

    if (userError) throw userError;

    // 3️⃣ Save AI message
    const { error: aiError } = await supabaseAdmin
      .from("ai_chats")
      .insert({
        user_id: userId,
        role: "ai",
        message: aiReply
      });

    if (aiError) throw aiError;

    res.json({ reply: aiReply });

  } catch (err) {
    console.error("Chat error:", err);
    res.status(500).json({ error: "Chat failed" });
  }
};


export const getChatHistory = async (req, res) => {
  try {
    const userId = req.user.id;

    const { data, error } = await supabaseAdmin
      .from("ai_chats")
      .select("id, role, message, created_at")
      .eq("user_id", userId)
      .order("created_at", { ascending: true });

    if (error) throw error;

    res.json({
      count: data.length,
      chats: data
    });

  } catch (err) {
    console.error("Get chat history error:", err);
    res.status(500).json({ error: "Failed to fetch chat history" });
  }
};
