import { supabase, supabaseAdmin } from '../config/supabase.js';
import jwt from 'jsonwebtoken';

export const signup = async (email, password, role, adminSecret) => {
  try {

    if (role === "doctor") {
      if (!adminSecret || adminSecret !== "SuperStrongSecretKey_987!") {
        throw new Error("Invalid admin password");
      }
    }

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

    const { error: profileError } = await supabaseAdmin
      .from('profiles')
      .insert({
        id: authData.user.id,
        email: email,
        role: role === 'doctor' ? 'doctor' : 'normal_user',
        is_profile_completed: false,
        created_at: new Date().toISOString()
      });

    if (profileError) {
      console.error('Profile creation error:', profileError);
    }

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
        is_profile_completed: false,
        created_at: authData.user.created_at
      },
      token,
      supabaseSession: authData.session
    };

  } catch (error) {
    console.error('Signup service error:', error);
    throw error;
  }
};

export const login = async (email, password, role) => {
  try {
    const { data: authData, error: authError } = await supabase.auth.signInWithPassword({
      email,
      password,
    });

    if (authError) {
      if (authError.message.includes('Email not confirmed')) {
        console.log('Email not confirmed, trying to confirm...');

        const { data: userList } = await supabaseAdmin.auth.admin.listUsers();
        const user = userList.users.find(u => u.email === email);

        if (user) {
          await supabaseAdmin.auth.admin.updateUserById(user.id, {
            email_confirm: true
          });

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

    const { data: profile, error: profileError } = await supabase
      .from('profiles')
      .select('role, is_profile_completed')
      .eq('id', authData.user.id)
      .single();

    if (profileError || !profile) {
      throw new Error('Profile not found');
    }

    if (!role) {
      throw new Error('Role is required');
    }

    if (profile.role.toLowerCase() !== role.toLowerCase()) {
      throw new Error('Invalid role selected');
    }

    const token = jwt.sign(
      {
        id: authData.user.id,
        email: authData.user.email,
        role: profile.role || 'normal_user',
        is_profile_completed: profile.is_profile_completed,
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
        is_profile_completed: profile.is_profile_completed
      }
    };

  } catch (error) {
    console.error('Login service error:', error);
    throw new Error('Invalid email or password or role');
  }
};

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