'use strict';

const HttpError = require('../utils/HttpError');

/** Answers requests that match no route with 404. */
function notFound(req, res, next) {
  next(new HttpError(404, `Route not found: ${req.method} ${req.originalUrl}`));
}

/**
 * Central error handler. Every error ends up here, so the response format is
 * always the same: { "error": "<message>" }.
 * Unexpected errors are logged in full on the server, but the client only
 * receives a generic message - internal details (SQL, stack traces) are never
 * sent over the network.
 */
function errorHandler(err, req, res, next) {
  if (err instanceof HttpError) {
    return res.status(err.status).json({ error: err.message });
  }

  // Malformed JSON body sent by the client.
  if (err.type === 'entity.parse.failed') {
    return res.status(400).json({ error: 'Request body is not valid JSON' });
  }

  console.error(`[${new Date().toISOString()}] ${req.method} ${req.originalUrl}`, err);
  return res.status(500).json({ error: 'Internal server error' });
}

module.exports = { notFound, errorHandler };
