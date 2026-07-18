/**
 * Phone normalisation tests. The database rejects anything but strict E.164, so
 * every accepted input form must land on the same canonical output, and every
 * invalid form must be refused rather than stored malformed.
 */

import { describe, expect, it } from 'vitest';
import { isE164Msisdn, normalizeMsisdn, toDarajaMsisdn } from '../src/lib/phone.js';

describe('normalizeMsisdn', () => {
  it('accepts every common Kenyan input form and canonicalises it', () => {
    const expected = '+254712345678';
    for (const input of [
      '0712345678',
      '712345678',
      '254712345678',
      '+254712345678',
      '+254 712 345 678',
      '0712 345 678',
      '(0712)-345-678',
    ]) {
      expect(normalizeMsisdn(input), input).toBe(expected);
    }
  });

  it('handles the 01 (Airtel/Telkom) range', () => {
    expect(normalizeMsisdn('0112345678')).toBe('+254112345678');
    expect(normalizeMsisdn('112345678')).toBe('+254112345678');
  });

  it('rejects numbers that are not Kenyan mobiles', () => {
    for (const bad of [
      '',
      '12345',
      '0812345678', // invalid leading digit (not 1 or 7)
      '+255712345678', // Tanzania
      '071234567', // too short
      '07123456789', // too long
      'not a number',
      '+254712345',
    ]) {
      expect(normalizeMsisdn(bad), bad).toBeNull();
    }
  });
});

describe('isE164Msisdn', () => {
  it('recognises canonical numbers only', () => {
    expect(isE164Msisdn('+254712345678')).toBe(true);
    expect(isE164Msisdn('0712345678')).toBe(false);
  });
});

describe('toDarajaMsisdn', () => {
  it('strips the leading + for Daraja', () => {
    expect(toDarajaMsisdn('+254712345678')).toBe('254712345678');
  });
});
