'use strict';

/**
 * An error that carries an HTTP status code. Throw it from a controller or
 * service; the central error handler turns it into a JSON response.
 */
class HttpError extends Error {
  /**
   * @param {number} status  HTTP status code (4xx / 5xx)
   * @param {string} message Message that is safe to show to the client
   */
  constructor(status, message) {
    super(message);
    this.name = 'HttpError';
    this.status = status;
  }
}

module.exports = HttpError;
