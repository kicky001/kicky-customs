// Cloudflare Worker - 海关数据 API CORS 代理
// 部署方法见下方说明

const API_BASE = 'https://cd.210k.cc';

export default {
  async fetch(request) {
    // 处理预检请求
    if (request.method === 'OPTIONS') {
      return new Response(null, {
        headers: corsHeaders(),
      });
    }

    const url = new URL(request.url);
    const path = url.pathname + url.search;

    // 只代理 /api/ 路径
    if (!path.startsWith('/api/')) {
      return new Response('Kicky Customs API Proxy is running.', {
        headers: { 'Content-Type': 'text/plain' },
      });
    }

    try {
      const targetUrl = API_BASE + path;
      const headers = new Headers();
      headers.set('Content-Type', request.headers.get('Content-Type') || 'application/json');
      const auth = request.headers.get('Authorization');
      if (auth) headers.set('Authorization', auth);

      const fetchOptions = {
        method: request.method,
        headers,
      };

      if (request.method === 'POST') {
        fetchOptions.body = await request.text();
      }

      const response = await fetch(targetUrl, fetchOptions);
      const body = await response.text();

      return new Response(body, {
        status: response.status,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          ...corsHeaders(),
        },
      });
    } catch (err) {
      return new Response(JSON.stringify({ error: err.message }), {
        status: 502,
        headers: {
          'Content-Type': 'application/json',
          ...corsHeaders(),
        },
      });
    }
  },
};

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type, Authorization',
    'Access-Control-Max-Age': '86400',
  };
}
