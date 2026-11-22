'use strict';

/**
 * Test configuration. Values already set in the environment (CI) or in
 * backend/.env win; these defaults only fill the gaps.
 * CATS is always mocked in tests: no real credentials are ever used.
 */
const path = require('path');
require('dotenv').config({ path: path.resolve(__dirname, '../../.env') });

process.env.NODE_ENV = 'test';
process.env.CATS_MODE = 'mock';
process.env.CATS_MOCK_PASSWORD = 'test-cats-password';
process.env.JWT_SECRET ||= 'test-only-secret-0123456789abcdef0123456789abcdef';
process.env.LOGIN_RATE_LIMIT ||= '1000';
process.env.DB_HOST ||= 'localhost';
process.env.DB_NAME ||= 'academic_assessment';
process.env.DB_USER ||= 'aams_app';
process.env.DB_PASSWORD ||= 'not-used-by-unit-tests';
