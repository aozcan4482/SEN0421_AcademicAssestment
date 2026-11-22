'use strict';

const db = require('../db/pool');

async function isJuryAssigned(juryId, projectId) {
  const { rowCount } = await db.query(
    'SELECT 1 FROM jury_assignments WHERE jury_id = $1 AND project_id = $2',
    [juryId, projectId]
  );
  return rowCount > 0;
}

module.exports = { isJuryAssigned };
