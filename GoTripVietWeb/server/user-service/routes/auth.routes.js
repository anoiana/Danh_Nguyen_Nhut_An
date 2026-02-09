// routes/auth.routes.js
const express = require('express');
const router = express.Router();
const userController = require('../controllers/user.controller'); // Tầng 1 (Controller)

// Định nghĩa các endpoints

// POST /auth/register
router.post('/register', userController.register);

// POST /auth/login
router.post('/login', userController.login);

// POST /auth/forgot-password
router.post('/forgot-password', userController.forgotPassword);

// POST /auth/reset-password
// (Lưu ý: token nằm trong query, password nằm trong body)
router.post('/reset-password', userController.resetPassword);


module.exports = router;