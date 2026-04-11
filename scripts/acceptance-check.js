const baseUrl = process.env.BASE_URL || 'http://127.0.0.1:3000';

async function request(path, options = {}) {
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  };

  const response = await fetch(`${baseUrl}${path}`, {
    ...options,
    headers,
  });

  const text = await response.text();
  let body;

  try {
    body = text ? JSON.parse(text) : {};
  } catch {
    body = { raw: text };
  }

  return { ok: response.ok, status: response.status, body };
}

async function login(email, password = 'password123') {
  const response = await request('/api/auth/login', {
    method: 'POST',
    body: JSON.stringify({ email, password }),
  });
  assert(response.ok, `login failed for ${email}`);
  assert(response.body.token, `token missing for ${email}`);
  return response.body.token;
}

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

async function main() {
  console.log(`Acceptance checks against ${baseUrl}`);

  const issuerToken = await login('affairs@uni.edu');
  const merchantAToken = await login('cafe-a@merchant.uni.edu');
  const merchantBToken = await login('cafe-b@merchant.uni.edu');
  const merchantXToken = await login('cafe-x@merchant.uni.edu');
  const auditorToken = await login('audit@uni.edu');

  const reset = await request('/api/reset', {
    method: 'POST',
    headers: { Authorization: `Bearer ${issuerToken}` },
  });
  assert(reset.ok, 'reset failed');

  const bootstrap = await request('/api/bootstrap', {
    headers: { Authorization: `Bearer ${issuerToken}` },
  });
  assert(bootstrap.ok, 'bootstrap failed');
  assert(Array.isArray(bootstrap.body.vouchers), 'bootstrap vouchers missing');
  assert(Array.isArray(bootstrap.body.merchants), 'bootstrap merchants missing');

  const voucher = bootstrap.body.vouchers.find((entry) => entry.voucherId === 'VCH-1001');
  assert(voucher, 'seed voucher VCH-1001 missing');

  let result = await request('/api/merchant/verify', {
    method: 'POST',
    headers: { Authorization: `Bearer ${merchantAToken}` },
    body: JSON.stringify({
      voucherId: 'VCH-1001',
    }),
  });
  assert(result.ok, 'happy-path verify failed');
  assert(result.body.status === 'valid', `expected valid, got ${result.body.status}`);

  result = await request('/api/merchant/redeem', {
    method: 'POST',
    headers: { Authorization: `Bearer ${merchantAToken}` },
    body: JSON.stringify({
      voucherId: 'VCH-1001',
    }),
  });
  assert(result.ok, 'happy-path redeem failed');
  assert(result.body.status === 'redeemed', `expected redeemed, got ${result.body.status}`);
  assert(result.body.checkpointRef, 'redeem checkpoint missing');

  result = await request('/api/merchant/verify', {
    method: 'POST',
    headers: { Authorization: `Bearer ${merchantAToken}` },
    body: JSON.stringify({
      voucherId: 'VCH-1001',
    }),
  });
  assert(result.ok, 'duplicate verify failed');
  assert(
    result.body.status === 'already_redeemed',
    `expected already_redeemed, got ${result.body.status}`
  );

  result = await request('/api/merchant/redeem', {
    method: 'POST',
    headers: { Authorization: `Bearer ${merchantAToken}` },
    body: JSON.stringify({
      voucherId: 'VCH-1001',
    }),
  });
  assert(result.status === 409, `expected 409 on duplicate redeem, got ${result.status}`);
  assert(
    result.body.status === 'already_redeemed',
    `expected already_redeemed on duplicate redeem, got ${result.body.status}`
  );

  const issued = await request('/api/issuer/issue', {
    method: 'POST',
    headers: { Authorization: `Bearer ${issuerToken}` },
    body: JSON.stringify({ studentId: 'STU-1002' }),
  });
  assert(issued.ok, 'issuer issue failed');
  const revokedVoucherId = issued.body.voucher?.voucherId;
  assert(revokedVoucherId, 'issued voucher id missing');

  const revoked = await request('/api/issuer/revoke', {
    method: 'POST',
    headers: { Authorization: `Bearer ${issuerToken}` },
    body: JSON.stringify({
      voucherId: revokedVoucherId,
      reasonCode: 'admin_test_revoke',
    }),
  });
  assert(revoked.ok, 'issuer revoke failed');

  result = await request('/api/merchant/verify', {
    method: 'POST',
    headers: { Authorization: `Bearer ${merchantAToken}` },
    body: JSON.stringify({
      voucherId: revokedVoucherId,
    }),
  });
  assert(result.ok, 'revoked verify failed');
  assert(result.body.status === 'revoked', `expected revoked, got ${result.body.status}`);

  result = await request('/api/merchant/verify', {
    method: 'POST',
    headers: { Authorization: `Bearer ${merchantBToken}` },
    body: JSON.stringify({
      voucherId: 'VCH-1001',
    }),
  });
  assert(
    result.ok,
    `expected merchant B verify request to succeed, got ${result.status}`
  );
  assert(
    result.body.status === 'already_redeemed',
    `expected merchant B to see already_redeemed, got ${result.body.status}`
  );

  result = await request('/api/merchant/verify', {
    method: 'POST',
    headers: { Authorization: `Bearer ${merchantXToken}` },
    body: JSON.stringify({
      voucherId: 'VCH-1001',
    }),
  });
  assert(result.status === 403, `expected 403 for unauthorized merchant, got ${result.status}`);
  assert(
    result.body.status === 'merchant_not_approved',
    `expected merchant_not_approved, got ${result.body.status}`
  );

  const override = await request('/api/issuer/override', {
    method: 'POST',
    headers: { Authorization: `Bearer ${issuerToken}` },
    body: JSON.stringify({
      voucherId: revokedVoucherId,
      overrideReason: 'manual review approved replacement process',
    }),
  });
  assert(override.ok, 'override logging failed');
  assert(override.body.status === 'override_logged', 'override response mismatch');

  const history = await request('/api/auditor/history', {
    headers: { Authorization: `Bearer ${auditorToken}` },
  });
  assert(history.ok, 'auditor history failed');
  assert(Array.isArray(history.body.events), 'auditor events missing');

  const eventTypes = new Set(history.body.events.map((event) => event.type));
  assert(eventTypes.has('voucher_issued'), 'voucher_issued event missing');
  assert(eventTypes.has('voucher_redeemed'), 'voucher_redeemed event missing');
  assert(eventTypes.has('voucher_redemption_blocked'), 'voucher_redemption_blocked event missing');
  assert(eventTypes.has('voucher_revoked'), 'voucher_revoked event missing');
  assert(eventTypes.has('override_logged'), 'override_logged event missing');

  console.log('All acceptance checks passed.');
}

main().catch((error) => {
  console.error(error.message);
  process.exit(1);
});
