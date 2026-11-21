'use strict';

/** Entry point: starts the HTTP server and shuts it down cleanly. */
const config = require('./config/env');
const { createApp } = require('./app');
const { pool } = require('./db/pool');

const app = createApp();

const server = app.listen(config.server.port, config.server.host, () => {
  console.log(`API listening on http://${config.server.host}:${config.server.port} (${config.env})`);
});

// On Ctrl+C or a stop signal: stop accepting requests, let running ones
// finish, then close the database pool.
function shutdown(signal) {
  console.log(`${signal} received, shutting down...`);
  server.close(async () => {
    await pool.end();
    process.exit(0);
  });
  // Force exit if something hangs.
  setTimeout(() => process.exit(1), 10000).unref();
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
