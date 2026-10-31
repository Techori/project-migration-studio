import { describe, expect, it } from 'vitest';
import { compareSchema, parseSqlTables, expectedTables, type Table } from './setup-contract';
const table: Table = { name: 'employees', rls: true, columns: [{ name: 'id', type: 'uuid', nullable: false }] };
describe('read-only schema comparison', () => {
  it('detects missing tables', () => expect(compareSchema([table], [])).toEqual([{ severity: 'error', object: 'employees', expected: 'Table present', actual: 'Missing table' }]));
  it('detects type mismatch', () => expect(compareSchema([table], [{ ...table, columns: [{ name: 'id', type: 'text', nullable: false }] }])[0]?.actual).toBe('text'));
  it('detects nullable mismatch', () => expect(compareSchema([table], [{ ...table, columns: [{ name: 'id', type: 'uuid', nullable: true }] }])[0]?.actual).toBe('Nullable'));
  it('detects missing columns', () => expect(compareSchema([table], [{ ...table, columns: [] }])[0]?.actual).toBe('Missing column'));
  it('flags disabled row security', () => expect(compareSchema([table], [{ ...table, rls: false }])[0]?.actual).toBe('Disabled'));
  it('reports additional tables', () => expect(compareSchema([], [table])[0]?.actual).toBe('Additional table'));
  it('does not mutate inputs', () => { const before = JSON.stringify(table); compareSchema([table], [table]); expect(JSON.stringify(table)).toBe(before); });
  it('retains all required tables', () => expect(expectedTables.map(t => t.name).sort()).toEqual(['contact_submissions','customer_reports','employee_verification_attempts','employees','form_submission_limits','people_profiles','prototype_ai_access_state','prototype_submissions','registration_applications','user_roles']));
  it('parses SQL requiredness', () => expect(parseSqlTables('CREATE TABLE public.test (\n id uuid PRIMARY KEY,\n note text\n);')[0]?.columns).toEqual([{ name: 'id', type: 'uuid', nullable: false }, { name: 'note', type: 'text', nullable: true }]));
});
