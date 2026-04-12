// Cloudflare Worker - 海关数据 API + Zoho CRM 代理
const API_BASE = 'https://cd.210k.cc';

export default {
  async fetch(request) {
    if (request.method === 'OPTIONS') {
      return new Response(null, { headers: corsHeaders() });
    }

    const url = new URL(request.url);
    const path = url.pathname + url.search;

    // 代理 Zoho CRM API
    if (path.startsWith('/zoho/')) {
      return handleZoho(request, path);
    }

    // 代理海关数据 API
    if (path.startsWith('/api/')) {
      return proxyRequest(API_BASE + path, request);
    }

    return new Response('Kicky Customs API Proxy is running.', {
      headers: { 'Content-Type': 'text/plain' },
    });
  },
};

async function handleZoho(request, path) {
  // /zoho/crm/v2/Leads -> https://www.zohoapis.com/crm/v2/Leads
  const zohoPath = path.replace('/zoho/', '/');
  const zohoUrl = 'https://www.zohoapis.com' + zohoPath;

  try {
    const headers = new Headers();
    headers.set('Content-Type', 'application/json');
    const auth = request.headers.get('Authorization');
    if (auth) headers.set('Authorization', auth);

    const fetchOptions = { method: request.method, headers };
    if (request.method === 'POST' || request.method === 'PUT') {
      fetchOptions.body = await request.text();
    }

    const response = await fetch(zohoUrl, fetchOptions);
    const body = await response.text();

    return new Response(body, {
      status: response.status,
      headers: { 'Content-Type': 'application/json; charset=utf-8', ...corsHeaders() },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 502,
      headers: { 'Content-Type': 'application/json', ...corsHeaders() },
    });
  }
}

async function proxyRequest(targetUrl, request) {
  try {
    const headers = new Headers();
    headers.set('Content-Type', request.headers.get('Content-Type') || 'application/json');
    const auth = request.headers.get('Authorization');
    if (auth) headers.set('Authorization', auth);

    const fetchOptions = { method: request.method, headers };
    if (request.method === 'POST') {
      fetchOptions.body = await request.text();
    }

    const response = await fetch(targetUrl, fetchOptions);
    const body = await response.text();

    return new Response(body, {
      status: response.status,
      headers: { 'Content-Type': 'application/json; charset=utf-8', ...corsHeaders() },
    });
  } catch (err) {
    return new Response(JSON.stringify({ error: err.message }), {
      status: 502,
      headers: { 'Content-Type': 'application/json', ...corsHeaders() },
    });
  }
}

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}
