// src/services/auth.service.js
import { supabase, supabaseAdmin } from '../config/supabase.js';
import jwt from 'jsonwebtoken';

export const signup = async (email, password, role, adminSecret) => {
  try {


    // Optional: Check admin secret for doctor signup
    if (role === "doctor") {
      if (!adminSecret || adminSecret !== "SuperStrongSecretKey_987!") {
        throw new Error("Invalid admin password");
      }
    }

    // 1. Sign up user with Supabase Auth
    const { data: authData, error: authError } = await supabase.auth.signUp({
      email,
      password,
      options: {
        data: {
          email_verified: false
        }
      }
    });

    if (authError) {
      console.error('Supabase signup error:', authError);
      throw new Error(authError.message);
    }

    if (!authData.user) {
      throw new Error('User creation failed');
    }

    // 2. Create profile in profiles table (your existing table)
    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: authData.user.id,
        email: email,
        role: role === 'doctor' ? 'doctor' : 'normal_user',
        created_at: new Date().toISOString()
      });

    if (profileError) {
      console.error('Profile creation error:', profileError);
      // Don't throw - user is created in auth, just profile failed
    }

    // 3. Generate your own JWT token (or use Supabase's session)
    const token = jwt.sign(
      {
        id: authData.user.id,
        email: authData.user.email,
        role: role === 'doctor' ? 'doctor' : 'normal_user',
        sub: authData.user.id
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return {
      user: {
        id: authData.user.id,
        email: authData.user.email,
        role: role === 'doctor' ? 'doctor' : 'normal_user',
        created_at: authData.user.created_at
      },
      token,
      // Also return Supabase session if needed
      supabaseSession: authData.session
    };

  } catch (error) {
    console.error('Signup service error:', error);
    throw error;
  }
};

export const login = async (email, password, role) => {
  try {
    // First try regular login
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (authError) {
      // If error is about unconfirmed email, use admin to confirm
      if (authError.message.includes('Email not confirmed')) {
        console.log('Email not confirmed, trying to confirm...');

        // Get user
        const { data: userList } = await supabaseAdmin.auth.admin.listUsers();
        const user = userList.users.find(u => u.email === email);

        if (user) {
          // Confirm email
          await supabaseAdmin.auth.admin.updateUserById(user.id, {
            email_confirm: true
          });

          // Try login again
          const { data: retryData, error: retryError } = await supabase.auth.signInWithPassword({
            email,
            password,
          });

          if (retryError) throw new Error('Invalid credentials');

          authData = retryData;
        } else {
          throw new Error('Invalid credentials');
        }
      } else {
        throw new Error('Invalid credentials');
      }
    }

    if (!authData.user) {
      throw new Error('Authentication failed');
    }

    // Get role from profiles table
    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('role')
      .eq('id', authData.user.id)
      .single();

    // Check profile first
    if (profileError || !profile) {
      throw new Error('Profile not found');
    }

    // Check role
    if (!role) {
      throw new Error('Role is required');
    }

    if (profile.role.toLowerCase() !== role.toLowerCase()) {
      throw new Error('Invalid role selected');
    }

    // Generate your own JWT token
    const token = jwt.sign(
      {
        id: authData.user.id,
        email: authData.user.email,
        role: profile.role || 'normal_user',
        sub: authData.user.id
      },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    return {
      token,
      user: {
        id: authData.user.id,
        email: authData.user.email,
        role: profile.role || 'normal_user',
      }
    };

  } catch (error) {
    console.error('Login service error:', error);
    throw new Error('Invalid email or password or role');
  }
};

// Optional: Get user profile
export const getUserProfile = async (userId) => {
  try {
    const { data, error } = await supabase
      .from('profiles')
      .select('*')
      .eq('id', userId)
      .single();

    if (error) throw error;
    return data;
  } catch (error) {
    console.error('Get profile error:', error);
    return null;
  }
};

export default {
  signup,
  login,
  getUserProfile
};