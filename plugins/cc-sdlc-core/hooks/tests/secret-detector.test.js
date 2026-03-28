#!/usr/bin/env node
/**
 * Unit tests for secret-detector.js hook.
 * Uses node:test (built-in, zero deps). Run: node --test plugins/cc-sdlc-core/hooks/tests/
 */
const { describe, it } = require('node:test');
const assert = require('node:assert/strict');

const SECRET_PATTERNS = [
  /(?:api[_-]?key|apikey)\s*[:=]\s*['"]?[A-Za-z0-9_\-]{20,}/i,
  /(?:secret|token|password|passwd|pwd)\s*[:=]\s*['"]?[A-Za-z0-9_\-]{8,}/i,
  /(?:aws_access_key_id|aws_secret_access_key)\s*[:=]\s*['"]?[A-Z0-9]{16,}/i,
  /AKIA[0-9A-Z]{16}/,
  /ghp_[A-Za-z0-9]{36}/,
  /gho_[A-Za-z0-9]{36}/,
  /github_pat_[A-Za-z0-9_]{22,}/,
  /sk-[A-Za-z0-9]{32,}/,
  /-----BEGIN (?:RSA |EC |DSA )?PRIVATE KEY-----/,
  /eyJ[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}\.[A-Za-z0-9_-]{10,}/,
];

function hasSecret(text) {
  return SECRET_PATTERNS.some(p => p.test(text));
}

describe('secret-detector: catches real secrets', () => {
  const secrets = [
    ['api_key = "sk_live_abc12345678901234567"', 'API key assignment'],
    ['apiKey: ABCDEFGHIJ1234567890xyz', 'camelCase apiKey'],
    ['token = "abcdefghijklmnop"', 'generic token'],
    ['password: "supersecret123"', 'password field'],
    ['SECRET=MyVeryLongSecretValue12345', 'SECRET env var'],
    ['aws_access_key_id = AKIAIOSFODNN7EXAMPLE', 'AWS access key'],
    ['aws_secret_access_key = WJALRXUTNFEMIKMDENGBPXRFICYEXAMPLEKEY', 'AWS secret key'],
    ['AKIAIOSFODNN7EXAMPLE', 'bare AWS key ID'],
    ['ghp_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij', 'GitHub PAT (ghp_)'],
    ['gho_ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghij', 'GitHub OAuth (gho_)'],
    ['github_pat_1234567890ABCDEFGHIJKLMNOPQRSTUVWXYZab', 'GitHub fine-grained PAT'],
    ['sk-1234567890abcdefghijklmnopqrstuv', 'OpenAI/Anthropic key (sk-)'],
    ['-----BEGIN RSA PRIVATE KEY-----', 'RSA private key header'],
    ['-----BEGIN PRIVATE KEY-----', 'Generic private key header'],
    ['-----BEGIN EC PRIVATE KEY-----', 'EC private key header'],
    ['eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiIxMjM0NTY3ODkwIn0.dozjgNryP4J3jVmNHl0w5N_XgL0n3I9PlFUP0THsR8U', 'JWT token'],
  ];

  for (const [text, label] of secrets) {
    it(`catches: ${label}`, () => {
      assert.ok(hasSecret(text), `Expected secret pattern to match: "${text.substring(0, 50)}..."`);
    });
  }
});

describe('secret-detector: passes clean text', () => {
  const clean = [
    ['Add user authentication using JWT', 'normal task description'],
    ['Fix the password reset flow', 'mentions password as concept'],
    ['Use api_key from environment variable', 'mentions api_key without value'],
    ['The token endpoint returns a JSON response', 'mentions token as concept'],
    ['Configure AWS IAM roles for the service', 'mentions AWS without keys'],
    ['Review the secret management documentation', 'mentions secret as concept'],
    ['Set up GitHub Actions for CI/CD', 'mentions GitHub without tokens'],
    ['sk-proj is the prefix for project keys', 'short sk- without enough chars'],
    ['Delete the old API key rotation script', 'no actual key value'],
    ['eyJh is a common JWT prefix', 'short JWT fragment without full structure'],
  ];

  for (const [text, label] of clean) {
    it(`passes: ${label}`, () => {
      assert.ok(!hasSecret(text), `Expected clean text to pass: "${text}"`);
    });
  }
});
