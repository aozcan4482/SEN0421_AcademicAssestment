'use strict';

/**
 * Code quality rules (ESLint flat config).
 * Formatting is left to Prettier; ESLint checks for real problems.
 */
const js = require('@eslint/js');
const globals = require('globals');
const jestPlugin = require('eslint-plugin-jest');
const prettier = require('eslint-config-prettier');

module.exports = [
  { ignores: ['node_modules/', 'coverage/'] },
  js.configs.recommended,
  {
    files: ['**/*.js'],
    languageOptions: {
      ecmaVersion: 2023,
      sourceType: 'commonjs',
      globals: { ...globals.node },
    },
    rules: {
      'no-unused-vars': ['error', { argsIgnorePattern: '^(_|req|res|next)' }],
      eqeqeq: ['error', 'always'],
      'prefer-const': 'error',
      'no-var': 'error',
      strict: ['error', 'global'],
    },
  },
  {
    files: ['tests/**/*.js'],
    ...jestPlugin.configs['flat/recommended'],
    languageOptions: {
      globals: { ...globals.node, ...globals.jest },
    },
  },
  prettier,
];
