// Teste le véritable handler Edge sans réseau ni base de données.
// L'import Supabase et Deno sont remplacés uniquement dans ce bac de test.
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { stripTypeScriptTypes } from 'node:module';
import { runInNewContext } from 'node:vm';
import test from 'node:test';

const source = readFileSync(new URL('../supabase/functions/admin-create-user/index.ts', import.meta.url), 'utf8')
  .replace(/^import .*\r?\n/, '');
const javascript = stripTypeScriptTypes(source);

function setup({ role = 'admin', active = true, until = null, validToken = true } = {}) {
  let handler;
  let writes = 0;
  let created;
  const profile = { is_active: active, valid_until: until };
  const client = {
    auth: {
      getUser: async () => ({ data: { user: validToken ? { id: 'admin-id', app_metadata: { role }, user_metadata: { role: 'admin' } } : null }, error: null }),
      admin: {
        listUsers: async () => ({ data: { users: [] }, error: null }),
        createUser: async (values) => { writes++; created = values; return { data: { user: { id: 'new-id' } }, error: null }; },
      },
    },
    from: () => {
      const query = {
        select: () => query, eq: () => query, order: () => query,
        single: async () => ({ data: profile, error: null }),
        update: () => { writes++; return query; },
        then: (resolve) => Promise.resolve({ data: [], error: null }).then(resolve),
      };
      return query;
    },
  };
  runInNewContext(javascript, {
    createClient: () => client, Response, Request,
    Deno: { env: { get: (key) => key === 'ADMIN_PANEL_SECRET' ? 'test-secret' : 'test-value' }, serve: (fn) => { handler = fn; } },
  });
  return {
    request: (method = 'GET', body, headers = { authorization: 'Bearer test-token' }) => handler(new Request('https://local.test/admin', {
      method, headers, ...(body ? { body: JSON.stringify(body) } : {}),
    })),
    writes: () => writes, created: () => created,
  };
}

test('refuse les appels anonymes et les jetons invalides', async () => {
  const anonymous = setup();
  assert.equal((await anonymous.request('GET', null, {})).status, 401);
  const invalid = setup({ validToken: false });
  assert.equal((await invalid.request()).status, 401);
});

test('refuse un joueur même si user_metadata contient admin', async () => {
  const app = setup({ role: 'player' });
  assert.equal((await app.request('POST', { username: 'new-player' })).status, 403);
  assert.equal(app.writes(), 0);
});

test('refuse un administrateur bloqué ou expiré', async () => {
  for (const options of [{ active: false }, { until: '2000-01-01T00:00:00Z' }]) {
    const app = setup(options);
    assert.equal((await app.request()).status, 403);
    assert.equal(app.writes(), 0);
  }
});

test('accepte une session admin valide et conserve le panneau web', async () => {
  assert.equal((await setup().request()).status, 200);
  assert.equal((await setup({ role: 'player' }).request('GET', null, { 'x-admin-secret': 'test-secret' })).status, 200);
});

test('interdit de bloquer son propre compte', async () => {
  const app = setup();
  const response = await app.request('PATCH', { userId: 'admin-id', action: 'setActive', isActive: false });
  assert.equal(response.status, 400);
  assert.equal((await response.json()).error, 'SELF_DISABLE_FORBIDDEN');
  assert.equal(app.writes(), 0);
});

test('valide les limites avant toute création', async () => {
  const app = setup();
  const response = await app.request('POST', { username: 'alice', password: 'password123', maxDevices: 0, validityDays: 30 });
  assert.equal(response.status, 400);
  assert.equal(app.writes(), 0);
});

test('crée un compte désactivé avec un blocage Auth et profil', async () => {
  const app = setup();
  const response = await app.request('POST', { username: 'Alice', password: 'password123', maxDevices: 2, validityDays: 60, isActive: false });
  assert.equal(response.status, 200);
  assert.equal(app.created().email, 'alice@underover7.local');
  assert.equal(app.created().ban_duration, '876000h');
  assert.equal(app.writes(), 2);
});
