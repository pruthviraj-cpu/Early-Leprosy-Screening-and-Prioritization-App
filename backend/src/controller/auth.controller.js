import authService from '../services/auth.service.js';

export const signup = async (req, res) => {
  try {
    const { email, password, role, adminSecret } = req.body;

    if (!email || !password) {
      return res.status(400).json({ error: "Email and password are required" });
    }

    const data = await authService.signup(email, password, role, adminSecret);

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
    const { email, password, role } = req.body;

    if (!email || !password || !role) {
      return res.status(400).json({ error: "Email, password, and role are required" });
    }

    const data = await authService.login(email, password, role);

    const { supabaseSession, ...responseData } = data;

    res.status(200).json(responseData);

  } catch (error) {
    console.error("Login error:", error);

    if (error.message.includes('Invalid email or password or role')) {
      return res.status(401).json({ error: "Invalid email or password or role" });
    }

    res.status(500).json({ error: error.message || "Login failed" });
  }
};

export const getCurrentUser = async (req, res) => {
  try {
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