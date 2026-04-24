/**
 * schema-filter.js
 * ─────────────────────────────────────────────────────────────────
 * Lightweight reverse proxy: Claude Code → [8317] → CLIProxyAPI [8318]
 *
 * Purpose: Strip JSON Schema keywords unsupported by Gemini/Antigravity API
 * before requests reach CLIProxyAPI, preventing 400 "propertyNames" errors.
 *
 * Stripped keywords: propertyNames, patternProperties, unevaluatedProperties,
 *                    $schema, $id, $defs, $anchor, $recursiveRef
 *
 * Usage: node schema-filter.js [LISTEN_PORT] [UPSTREAM_PORT]
 *        Default: node schema-filter.js 8317 8318
 */

'use strict';
const http = require('http');

const LISTEN_PORT  = parseInt(process.argv[2] || '8317', 10);
const UPSTREAM_PORT = parseInt(process.argv[3] || '8318', 10);
const UPSTREAM_HOST = '127.0.0.1';

// JSON Schema keywords not supported by Gemini/Antigravity API
const STRIP_KEYS = new Set([
  'propertyNames',
  'patternProperties',
  'unevaluatedProperties',
  'unevaluatedItems',
  '$schema',
  '$id',
  '$defs',
  '$anchor',
  '$recursiveRef',
  '$recursiveAnchor',
]);

/** Recursively strip unsupported keywords from a JSON Schema object */
function stripSchema(obj) {
  if (Array.isArray(obj)) return obj.map(stripSchema);
  if (obj !== null && typeof obj === 'object') {
    const out = {};
    for (const [k, v] of Object.entries(obj)) {
      if (!STRIP_KEYS.has(k)) {
        out[k] = stripSchema(v);
      }
    }
    return out;
  }
  return obj;
}

/** Apply schema stripping to Claude API format tools array */
function cleanPayload(json) {
  if (!json || !Array.isArray(json.tools)) return json;
  try {
    json.tools = json.tools.map(tool => {
      if (tool && tool.input_schema) {
        return { ...tool, input_schema: stripSchema(tool.input_schema) };
      }
      return tool;
    });
  } catch (e) {
    process.stderr.write(`[schema-filter] WARN: could not clean tools: ${e.message}\n`);
  }
  return json;
}

const server = http.createServer((req, res) => {
  // Absorb health-check pings (HEAD /) locally -- do not forward to CLIProxyAPI
  // to prevent spurious 404 error log files being created upstream.
  if (req.method === 'HEAD' && req.url === '/') {
    res.writeHead(200);
    res.end();
    return;
  }

  const chunks = [];
  req.on('data', c => chunks.push(c));
  req.on('end', () => {
    let body = Buffer.concat(chunks);
    let stripped = 0;

    // Only process POST requests with a JSON body (tool-bearing requests)
    if (req.method === 'POST' && body.length > 0) {
      const ct = (req.headers['content-type'] || '').toLowerCase();
      if (ct.includes('application/json')) {
        try {
          const parsed = JSON.parse(body.toString('utf-8'));
          const before = JSON.stringify(parsed);
          const cleaned = cleanPayload(parsed);
          const after = JSON.stringify(cleaned);
          if (before !== after) {
            body = Buffer.from(after, 'utf-8');
            stripped = 1;
          }
        } catch (e) {
          // Not valid JSON or couldn't parse — forward as-is
        }
      }
    }

    const upstreamHeaders = {
      ...req.headers,
      host: `${UPSTREAM_HOST}:${UPSTREAM_PORT}`,
      'content-length': body.length.toString(),
    };

    const opts = {
      hostname: UPSTREAM_HOST,
      port: UPSTREAM_PORT,
      path: req.url,
      method: req.method,
      headers: upstreamHeaders,
      // 10-minute timeout: required for Claude Opus + extended thinking
      // on large context payloads (400-600KB) to prevent TCP connection abort
      timeout: 600_000,
    };

    const fwd = http.request(opts, upstream => {
      res.writeHead(upstream.statusCode, upstream.headers);
      upstream.pipe(res, { end: true });
    });

    fwd.on('timeout', () => {
      process.stderr.write(`[schema-filter] upstream timeout after 600s — destroying socket\n`);
      fwd.destroy();
      if (!res.headersSent) {
        res.writeHead(504, { 'Content-Type': 'text/plain' });
        res.end('Schema-filter: upstream timeout (>600s). Consider reducing thinking budget or max_tokens.');
      }
    });

    fwd.on('error', err => {
      process.stderr.write(`[schema-filter] upstream error: ${err.message}\n`);
      if (!res.headersSent) {
        res.writeHead(502, { 'Content-Type': 'text/plain' });
        res.end(`Schema-filter upstream error: ${err.message}`);
      }
    });

    fwd.write(body);
    fwd.end();

    if (stripped) {
      process.stdout.write(
        `[schema-filter] ${req.method} ${req.url} — stripped unsupported schema keywords\n`
      );
    }
  });
});

server.on('error', err => {
  process.stderr.write(`[schema-filter] Server error: ${err.message}\n`);
  process.exit(1);
});

server.listen(LISTEN_PORT, '127.0.0.1', () => {
  process.stdout.write(
    `[schema-filter] Listening on :${LISTEN_PORT} → CLIProxyAPI :${UPSTREAM_PORT}\n`
  );
  process.stdout.write(
    `[schema-filter] Stripping: ${[...STRIP_KEYS].join(', ')}\n`
  );
});

// Graceful shutdown
process.on('SIGTERM', () => server.close());
process.on('SIGINT',  () => server.close());
