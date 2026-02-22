// src/controller/auth.controller.js
import authService from '../services/auth.service.js';

export const signup = async (req, res) => {
  try {
    const { email, password, role } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required" });
    }

    const data = await authService.signup(email, password, role);

    // Remove supabaseSession from response if you don't need it
    const { supabaseSession, ...responseData } = data;

    res.status(201).json(responseData);

  } catch (error) {
    console.error("Signup error:", error);

    // Handle specific Supabase errors
    if (error.message.includes('User already registered')) {
      return res.status(409).json({ error: "Email already exists" });
    }

    if (error.message.includes('Password should be at least')) {
      return res.status(400).json({ error: "Password is too weak" });
    }

    if (error.message.includes('Invalid email')) {
      return res.status(400).json({ error: "Invalid email format" });
    }

    res.status(500).json({ error: error.message || "Signup failed" });
  }
};

export const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required" });
    }

    const data = await authService.login(email, password);

    // Remove supabaseSession from response if you don't need it
    const { supabaseSession, ...responseData } = data;

    res.status(200).json(responseData);

  } catch (error) {
    console.error("Login error:", error);

    if (error.message.includes('Invalid email or password')) {
      return res.status(401).json({ error: "Invalid email or password" });
    }

    res.status(500).json({ error: error.message || "Login failed" });
  }
};

// Optional: Get current user
export const getCurrentUser = async (req, res) => {
  try {
    // Assuming you have auth middleware that sets req.user
    if (!req.user || !req.user.id) {
      return res.status(401).json({ error: "Not authenticated" });
    }

    const profile = await authService.getUserProfile(req.user.id);

    res.status(200).json({
      user: {
        id: req.user.id,
        email: req.user.email,
        ...profile
      }
    });

  } catch (error) {
    console.error("Get current user error:", error);
    res.status(500).json({ error: error.message });
  }
};