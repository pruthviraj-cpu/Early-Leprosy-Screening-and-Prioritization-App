import express from 'express';
import authMiddleware from '../middlewares/auth.middleware.js';
import {
  updateUserProfile,
  getUserProfile
} from '../controller/profile.controller.js';

const router = express.Router();

// Get logged-in user's profile
router.get('/me', authMiddleware, getUserProfile);

// Update logged-in user's profile
router.put('/me', authMiddleware, updateUserProfile);

export default router;
