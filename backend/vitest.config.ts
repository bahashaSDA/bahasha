import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    environment: 'node',
    include: ['tests/**/*.test.ts'],
    // Config validates env at import; give the unit tests a minimal valid set so
    // importing modules that read config does not exit the process.
    env: {
      NODE_ENV: 'test',
      SUPABASE_URL: 'https://test.supabase.co',
      SUPABASE_SERVICE_ROLE_KEY: 'test-service-role-key-1234567890',
      DARAJA_CONSUMER_KEY: 'test-consumer-key',
      DARAJA_CONSUMER_SECRET: 'test-consumer-secret',
      DARAJA_PASSKEY: 'test-passkey',
      DARAJA_SHORTCODE: '174379',
      DARAJA_CALLBACK_URL: 'https://test.example.com/api/v1/mpesa/callback/x',
      DARAJA_CALLBACK_SECRET: 'test-callback-secret-must-be-32-characters',
      HUB_API_KEY_SECRET: 'test-hub-secret-must-be-32-characters-long',
    },
  },
});
