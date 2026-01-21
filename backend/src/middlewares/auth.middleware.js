// src/middleware/auth.middleware.js
import jwt from 'jsonwebtoken';
import { supabase } from '../config/supabase.js';

// Option 1: Use your own JWT
export default (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: "Authentication required" });
  }

  try {
    // Verify your custom JWT
    req.user = jwt.verify(token, process.env.JWT_SECRET);
    next();
  } catch (error) {
    console.error('JWT verification error:', error.message);
    return res.status(403).json({ error: "Invalid token" });
  }
};

// Option 2: Use Supabase's JWT verification
export const supabaseAuthMiddleware = async (req, res, next) => {
  const token = req.headers.authorization?.split(' ')[1];
  
  if (!token) {
    return res.status(401).json({ error: "Authentication required" });
  }

  try {
    // Verify with Supabase
    const { data: { user }, error } = await supabase.auth.getUser(token);
    
    if (error || !user) {
      return res.status(403).json({ error: "Invalid token" });
    }
    
    req.user = {
      id: user.id,
      email: user.email,
      ...user.user_metadata
    };
    
    next();
  } catch (error) {
    console.error('Supabase auth error:', error);
    return res.status(403).json({ error: "Authentication failed" });
  }
};