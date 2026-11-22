'use strict';

/**
 * Sets the local password of an Admin account.
 *
 *   npm run set-admin-password -- <username>
 *
 * The password is typed interactively (never passed on the command line, so
 * it does not end up in shell history) and only its bcrypt hash is stored.
 */
const readline = require('readline');
const userRepository = require('../src/repositories/userRepository');
const authService = require('../src/services/authService');
const { pool } = require('../src/db/pool');

const MIN_LENGTH = 10;

/**
 * Prompts for input without echoing it to the terminal. Lines are queued, so
 * it also works when the input is piped in all at once.
 */
function createPrompt() {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  const queued = [];
  let waiting = null;
  let muted = false;
  rl._writeToOutput = (text) => {
    if (!muted) rl.output.write(text);
  };
  rl.on('line', (line) => {
    if (waiting) {
      waiting(line);
      waiting = null;
    } else {
      queued.push(line);
    }
  });
  rl.on('close', () => waiting && waiting(''));

  const ask = (question) => {
    muted = false;
    rl.output.write(question);
    muted = true;
    const answer = queued.length > 0 ? Promise.resolve(queued.shift())
      : new Promise((resolve) => { waiting = resolve; });
    return answer.then((value) => {
      rl.output.write('\n');
      return value;
    });
  };
  return { ask, close: () => rl.close() };
}

async function main() {
  const username = process.argv[2];
  if (!username) throw new Error('Usage: npm run set-admin-password -- <username>');

  const user = await userRepository.findByUsername(username);
  if (!user) throw new Error(`User "${username}" not found.`);
  if (user.role !== 'Admin') throw new Error(`User "${username}" is not an Admin account.`);

  const prompt = createPrompt();
  let password;
  let repeat;
  try {
    password = await prompt.ask(`New password for ${username}: `);
    repeat = await prompt.ask('Repeat password: ');
  } finally {
    prompt.close();
  }
  if (password.length < MIN_LENGTH) {
    throw new Error(`Password must be at least ${MIN_LENGTH} characters.`);
  }
  if (password !== repeat) throw new Error('Passwords do not match.');

  await userRepository.setPasswordHash(user.user_id, await authService.hashPassword(password));
  console.log(`Password updated for ${username}.`);
}

main()
  .catch((err) => {
    console.error(err.message);
    process.exitCode = 1;
  })
  .finally(() => pool.end());
