'use strict';

const criteriaRepository = require('../repositories/criteriaRepository');

/** GET /api/criteria - the evaluation rubric with weights. */
async function list(req, res) {
  const criteria = await criteriaRepository.findAll();
  res.json(criteria);
}

module.exports = { list };
