import Groq from "groq-sdk";

const groq = new Groq({
  apiKey: process.env.GROQ_API_KEY
});

export const generateAIResponse = async (userMessage) => {
  const completion = await groq.chat.completions.create({
    model:"llama-3.3-70b-versatile",
    messages: [
      { role: "system", content: "You are a helpful medical AI assistant." },
      { role: "user", content: userMessage }
    ],
  });

  return completion.choices[0].message.content;
};
