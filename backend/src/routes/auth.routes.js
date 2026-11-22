'use strict';

const express = require('express');
const authController = require('../controllers/authController');
const authenticate = require('../middleware/authenticate');
const { loginLimiter } = require('../middleware/rateLimit');

const router = express.Router();

router.post('/login', loginLimiter, authController.login);
router.get('/me', authenticate, authController.me);

module.exports = router;
