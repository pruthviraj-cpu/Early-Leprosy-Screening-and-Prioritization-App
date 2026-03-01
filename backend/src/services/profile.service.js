import { supabaseAdmin } from '../config/supabase.js';

export const updateProfile = async (userId, profileData) => {
  const { full_name, age, gender, phone } = profileData;

  const isProfileCompleted =
    full_name && age && gender && phone ? true : false;

  const { data, error } = await supabaseAdmin
    .from('profiles')
    .upsert(
      {
        id: userId,
        full_name,
        age,
        gender,
        phone,
        is_profile_completed: isProfileCompleted,
      },
      { onConflict: 'id' }
    )
    .select()
    .single();

  if (error) {
    console.error('Supabase error:', error);
    throw new Error(error.message);
  }

  return data;
};

export const getProfile = async (userId) => {
  const { data, error } = await supabaseAdmin
    .from('profiles')
    .select('*')
    .eq('id', userId)
    .single();

  if (error) {
    console.error('Get profile error:', error);
    throw new Error('Profile not found');
  }

  return data;
};
