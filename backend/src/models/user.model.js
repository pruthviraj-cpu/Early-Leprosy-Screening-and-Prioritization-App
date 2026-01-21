// src/models/user.model.js
import { pool } from '../config/db.js';
import { hashPassword } from '../utility/hash.js'; // ADD THIS IMPORT

export const createUser = async (email, password) => {
  const hashed = await hashPassword(password); // Now hashPassword is defined
  
  const result = await pool.query(
    `INSERT INTO profiles (email, password) 
     VALUES ($1, $2) 
     RETURNING id, email`,
    [email, hashed]
  );
  return result.rows[0];
};

export const findUserByEmail = async (email) => {
  const result = await pool.query(
    `SELECT * FROM profiles WHERE email = $1`,
    [email]
  );
  return result.rows[0];
};