import pool from "../config/db.js";

export const saveChat = async (userId, prompt, response) => {
  const query = `
    INSERT INTO chats (user_id, prompt, response)
    VALUES ($1, $2, $3)
    RETURNING *
  `;
  const values = [userId, prompt, response];
  const result = await pool.query(query, values);
  return result.rows[0];
};
