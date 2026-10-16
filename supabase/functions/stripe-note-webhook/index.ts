import { createClient } from 'npm:@supabase/supabase-js@2';

const encoder = new TextEncoder();

const toHex = (bytes: ArrayBuffer) =>
  [...new Uint8Array(bytes)]
    .map((byte) => byte.toString(16).padStart(2, '0'))
    .join('');

const safeEqual = (left: string, right: string) => {
  if (left.length !== right.length) return false;
  let mismatch = 0;
  for (let index = 0; index < left.length; index++) {
    mismatch |= left.charCodeAt(index) ^ right.charCodeAt(index);
  }
  return mismatch === 0;
};

const verifyStripeSignature = async (
  rawBody: string,
  signatureHeader: string,
  secret: string,
) => {
  const parts = signatureHeader.split(',');
  const timestamp = parts.find((part) => part.startsWith('t='))?.slice(2);
  const signatures = parts
    .filter((part) => part.startsWith('v1='))
    .map((part) => part.slice(3));
  if (!timestamp || signatures.length === 0) return false;

  const timestampSeconds = Number(timestamp);
  if (
    !Number.isFinite(timestampSeconds) ||
    Math.abs(Date.now() / 1000 - timestampSeconds) > 300
  ) {
    return false;
  }

  const key = await crypto.subtle.importKey(
    'raw',
    encoder.encode(secret),
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign'],
  );
  const digest = await crypto.subtle.sign(
    'HMAC',
    key,
    encoder.encode(`${timestamp}.${rawBody}`),
  );
  const expected = toHex(digest);
  return signatures.some((signature) => safeEqual(signature, expected));
};

Deno.serve(async (request) => {
  if (request.method !== 'POST') {
    return new Response('Method not allowed', { status: 405 });
  }

  const webhookSecret = Deno.env.get('STRIPE_WEBHOOK_SIGNING_SECRET');
  const supabaseUrl = Deno.env.get('SUPABASE_URL');
  const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
  if (!webhookSecret || !supabaseUrl || !serviceRoleKey) {
    return new Response('Webhook is not configured', { status: 503 });
  }

  const rawBody = await request.text();
  const signature = request.headers.get('Stripe-Signature');
  if (
    !signature ||
    !(await verifyStripeSignature(rawBody, signature, webhookSecret))
  ) {
    return new Response('Invalid signature', { status: 400 });
  }

  const event = JSON.parse(rawBody);
  if (
    !['checkout.session.completed', 'checkout.session.async_payment_succeeded']
      .includes(event.type)
  ) {
    return new Response(JSON.stringify({ received: true }), {
      headers: { 'Content-Type': 'application/json' },
    });
  }

  const session = event.data?.object;
  const documentId = session?.metadata?.document_id;
  const userId = session?.metadata?.user_id;
  if (!documentId || !userId || session.payment_status !== 'paid') {
    return new Response('Incomplete payment metadata', { status: 400 });
  }

  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data: document, error: documentError } = await admin
    .from('note_documents')
    .select('price, is_paid')
    .eq('id', documentId)
    .single();
  const expectedAmount = Math.round(Number(document?.price) * 100);
  if (
    documentError ||
    !document?.is_paid ||
    session.currency?.toLowerCase() !== 'inr' ||
    session.amount_total !== expectedAmount
  ) {
    console.error('Rejected mismatched Stripe payment', session.id);
    return new Response('Payment does not match the PDF price', { status: 400 });
  }

  const { error: purchaseError } = await admin.from('note_purchases').upsert(
    {
      document_id: documentId,
      user_id: userId,
      status: 'completed',
      amount: expectedAmount / 100,
      currency: 'INR',
      payment_method: 'Stripe Checkout',
      provider: 'stripe',
      provider_payment_id: session.payment_intent ?? session.id,
      provider_session_id: session.id,
      purchased_at: new Date().toISOString(),
    },
    { onConflict: 'document_id,user_id' },
  );
  if (purchaseError) {
    console.error('Unable to persist note purchase', purchaseError.code);
    return new Response('Unable to record purchase', { status: 500 });
  }

  return new Response(JSON.stringify({ received: true }), {
    headers: { 'Content-Type': 'application/json' },
  });
});
