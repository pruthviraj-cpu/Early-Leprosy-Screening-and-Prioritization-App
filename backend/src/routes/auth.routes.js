// src/routes/auth.routes.js
import express from 'express';
import { signup, login } from '../controller/auth.controller.js';

const router = express.Router();

router.post('/signup', signup);
router.post('/login', login);

export default router;  // Must be default export