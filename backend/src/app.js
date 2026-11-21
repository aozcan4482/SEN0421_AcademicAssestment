'use strict';

/**
 * Builds the Express application without starting the HTTP server, so the
 * same app can be started by server.js or imported by automated tests.
 */
const express = require('express');
const routes = require('./routes');
const { notFound, errorHandler } = require('./middleware/errorHandler');

function createApp() {
  const app = express();

  app.disable('x-powered-by'); // do not advertise the framework
  app.use(express.json({ limit: '1mb' }));

  app.use('/api', routes);

  app.use(notFound);
  app.use(errorHandler);

  return app;
}

module.exports = { createApp };
