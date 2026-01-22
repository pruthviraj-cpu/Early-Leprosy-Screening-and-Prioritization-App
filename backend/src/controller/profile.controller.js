import { updateProfile, getProfile } from '../services/profile.service.js';

export const updateUserProfile = async (req, res) => {
  try {
    const userId = req.user.id; // from JWT
    const profile = await updateProfile(userId, req.body);

    res.json({
      message: 'Profile updated successfully',
      profile
    });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

export const getUserProfile = async (req, res) => {
  try {
    const userId = req.user.id;
    const profile = await getProfile(userId);

    res.json(profile);
  } catch (error) {
    res.status(404).json({ error: error.message });
  }
};
