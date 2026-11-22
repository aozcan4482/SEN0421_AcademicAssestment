'use strict';

/**
 * Builds the Express application without starting the HTTP server, so the
 * same app can be started by server.js or imported by automated tests.
 */
const express = require('express');
const helmet = require('helmet');
const config = require('./config/env');
const routes = require('./routes');
const { notFound, errorHandler } = require('./middleware/errorHandler');

function createApp() {
  const app = express();

  app.disable('x-powered-by'); // do not advertise the framework
  if (config.server.trustProxy) app.set('trust proxy', 1);
  app.use(helmet()); // standard security headers
  app.use(express.json({ limit: '1mb' }));

  app.use('/api', routes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
