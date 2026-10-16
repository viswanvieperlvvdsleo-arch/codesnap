import { createClient } from 'npm:@supabase/supabase-js@2';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers':
    'authorization, x-client-info, apikey, content-type',
};

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { ...corsHeaders, 'Content-Type': 'application/json' },
  });

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') {
    return json({ error: 'Method not allowed' }, 405);
  }

  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ error: 'Sign in before purchasing a PDF.' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    const stripeSecretKey = Deno.env.get('STRIPE_SECRET_KEY');
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: 'Supabase function environment is incomplete.' }, 500);
    }
    if (!stripeSecretKey) {
      return json({ error: 'Stripe Checkout is not configured yet.' }, 503);
    }

    const token = authHeader.slice('Bearer '.length);
    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const { data: authData, error: authError } = await admin.auth.getUser(token);
    const user = authData.user;
    if (authError || !user) {
      return json({ error: 'Your session is no longer valid.' }, 401);
    }

    const body = await request.json();
    const documentId = body.document_id?.toString();
    const returnUrl = body.return_url?.toString();
    if (!documentId || !returnUrl) {
      return json({ error: 'document_id and return_url are required.' }, 400);
    }

    const parsedReturnUrl = new URL(returnUrl);
    if (!['http:', 'https:'].includes(parsedReturnUrl.protocol)) {
      return json({ error: 'Invalid return URL.' }, 400);
    }
    const requestOrigin = request.headers.get('Origin');
    if (requestOrigin && parsedReturnUrl.origin !== requestOrigin) {
      return json({ error: 'Return URL must match the app origin.' }, 400);
    }

    const { data: document, error: documentError } = await admin
      .from('note_documents')
      .select('id, title, price, is_paid, owner_id')
      .eq('id', documentId)
      .single();
    if (documentError || !document) {
      return json({ error: 'PDF not found.' }, 404);
    }
    if (!document.is_paid) {
      return json({ error: 'This PDF does not require payment.' }, 400);
    }

    const { data: existingPurchase } = await admin
      .from('note_purchases')
      .select('id')
      .eq('document_id', documentId)
      .eq('user_id', user.id)
      .eq('status', 'completed')
      .maybeSingle();
    if (existingPurchase) {
      return json({ already_purchased: true });
    }

    const amountInPaise = Math.round(Number(document.price) * 100);
    if (!Number.isSafeInteger(amountInPaise) || amountInPaise < 50) {
      return json({ error: 'This PDF has an invalid checkout price.' }, 400);
    }

    const successUrl = new URL(parsedReturnUrl);
    successUrl.searchParams.set('note_payment', 'success');
    successUrl.searchParams.set('document_id', documentId);
    const cancelUrl = new URL(parsedReturnUrl);
    cancelUrl.searchParams.set('note_payment', 'cancelled');

    const params = new URLSearchParams();
    params.set('mode', 'payment');
    params.set('success_url', successUrl.toString());
    params.set('cancel_url', cancelUrl.toString());
    params.set('client_reference_id', user.id);
    if (user.email) params.set('customer_email', user.email);
    params.set('line_items[0][quantity]', '1');
    params.set('line_items[0][price_data][currency]', 'inr');
    params.set(
      'line_items[0][price_data][unit_amount]',
      amountInPaise.toString(),
    );
    params.set(
      'line_items[0][price_data][product_data][name]',
      document.title,
    );
    params.set('metadata[document_id]', documentId);
    params.set('metadata[user_id]', user.id);
    params.set('payment_intent_data[metadata][document_id]', documentId);
    params.set('payment_intent_data[metadata][user_id]', user.id);

    const stripeResponse = await fetch(
      'https://api.stripe.com/v1/checkout/sessions',
      {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${stripeSecretKey}`,
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: params,
      },
    );
    const session = await stripeResponse.json();
    if (!stripeResponse.ok || !session.url) {
      console.error('Stripe session creation failed', session?.error?.type);
      return json({ error: 'Unable to start secure checkout.' }, 502);
    }

    return json({ checkout_url: session.url, session_id: session.id });
  } catch (error) {
    console.error('create-note-checkout failed', error);
    return json({ error: 'Unable to start secure checkout.' }, 500);
  }
});
