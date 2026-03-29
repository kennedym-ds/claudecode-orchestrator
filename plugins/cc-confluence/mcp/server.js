#!/usr/bin/env node
/**
 * cc-confluence MCP Server — Confluence Cloud REST API integration for Claude Code.
 *
 * Tools: search_pages, get_page, create_page, update_page, get_space, get_page_children
 *
 * Auth: API token via environment variables
 * Docs: https://developer.atlassian.com/cloud/confluence/rest/v2/
 */
const https = require('https');
const http = require('http');

// --- Configuration ---
const CONFLUENCE_BASE_URL = (process.env.CONFLUENCE_BASE_URL || '').replace(/\/+$/, '');
const CONFLUENCE_USER_EMAIL = process.env.CONFLUENCE_USER_EMAIL || '';
const CONFLUENCE_API_TOKEN = process.env.CONFLUENCE_API_TOKEN || '';

if (!CONFLUENCE_BASE_URL || !CONFLUENCE_USER_EMAIL || !CONFLUENCE_API_TOKEN) {
  process.stderr.write(
    '[cc-confluence] Missing required env vars: CONFLUENCE_BASE_URL, CONFLUENCE_USER_EMAIL, CONFLUENCE_API_TOKEN\n'
  );
}

// --- HTTP Client ---
function confluenceFetch(method, path, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, CONFLUENCE_BASE_URL);

    const isLocalhost = /^(localhost|127\.\d+\.\d+\.\d+|\[?::1\]?|0\.0\.0\.0)$/.test(url.hostname);
    if (url.protocol !== 'https:' && !isLocalhost) {
      reject(new Error('CONFLUENCE_BASE_URL must use HTTPS for non-localhost connections'));
      return;
    }

    const auth = Buffer.from(`${CONFLUENCE_USER_EMAIL}:${CONFLUENCE_API_TOKEN}`).toString('base64');
    const options = {
      method,
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      headers: {
        'Authorization': `Basic ${auth}`,
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      },
    };

    const transport = url.protocol === 'https:' ? https : http;
    const req = transport.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode >= 200 && res.statusCode < 300) {
          try { resolve(data ? JSON.parse(data) : {}); }
          catch { resolve({ raw: data }); }
        } else {
          reject(new Error(`Confluence API ${res.statusCode}: ${data.slice(0, 500)}`));
        }
      });
    });

    req.on('error', reject);
    req.setTimeout(30000, () => { req.destroy(); reject(new Error('Request timeout')); });

    if (body) req.write(JSON.stringify(body));
    req.end();
  });
}

// --- Tool Definitions ---
const TOOLS = [
  {
    name: 'search_pages',
    description: 'Search Confluence pages. Accepts plain text (auto-converted to CQL text search) or explicit CQL. Returns title, space, last modified.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Search text or CQL query (e.g., "type = page AND space = DEV AND title ~ auth")' },
        space_key: { type: 'string', description: 'Limit search to this space (optional)' },
        max_results: { type: 'number', description: 'Maximum results (default: 10, max: 25)', default: 10 },
      },
      required: ['query'],
    },
  },
  {
    name: 'get_page',
    description: 'Get a Confluence page by ID or title. Returns title, body content (storage format), labels, and version.',
    inputSchema: {
      type: 'object',
      properties: {
        page_id: { type: 'string', description: 'Confluence page ID' },
        title: { type: 'string', description: 'Page title (used with space_key if page_id not provided)' },
        space_key: { type: 'string', description: 'Space key (required if using title)' },
        body_format: { type: 'string', description: 'Body format: storage, atlas_doc_format, or view', default: 'storage' },
      },
    },
  },
  {
    name: 'create_page',
    description: 'Create a new Confluence page in a space. Supports storage format (XHTML) or plain text body.',
    inputSchema: {
      type: 'object',
      properties: {
        space_key: { type: 'string', description: 'Space key where page will be created' },
        title: { type: 'string', description: 'Page title' },
        body: { type: 'string', description: 'Page body content (XHTML storage format or plain text)' },
        parent_id: { type: 'string', description: 'Parent page ID (optional, creates under space root if omitted)' },
        labels: { type: 'array', items: { type: 'string' }, description: 'Labels to apply (optional)' },
      },
      required: ['space_key', 'title', 'body'],
    },
  },
  {
    name: 'update_page',
    description: 'Update an existing Confluence page. Requires current version number.',
    inputSchema: {
      type: 'object',
      properties: {
        page_id: { type: 'string', description: 'Page ID to update' },
        title: { type: 'string', description: 'New title (optional, keeps existing if omitted)' },
        body: { type: 'string', description: 'New body content (XHTML storage format)' },
        version_number: { type: 'number', description: 'Current version number (required for optimistic locking)' },
        version_message: { type: 'string', description: 'Version comment (optional)' },
      },
      required: ['page_id', 'body', 'version_number'],
    },
  },
  {
    name: 'get_space',
    description: 'Get Confluence space metadata including homepage, description, and permissions.',
    inputSchema: {
      type: 'object',
      properties: {
        space_key: { type: 'string', description: 'Space key (e.g., DEV, PROJ)' },
      },
      required: ['space_key'],
    },
  },
  {
    name: 'get_page_children',
    description: 'Get child pages of a Confluence page.',
    inputSchema: {
      type: 'object',
      properties: {
        page_id: { type: 'string', description: 'Parent page ID' },
        max_results: { type: 'number', description: 'Maximum results (default: 25)', default: 25 },
      },
      required: ['page_id'],
    },
  },
];

// --- Input Validation ---
const MAX_STRING_LENGTH = 10240; // 10 KB cap on string inputs
const MAX_BODY_LENGTH = 1048576; // 1 MB cap on page body content

function requireString(val, name, maxLen = MAX_STRING_LENGTH) {
  if (typeof val !== 'string' || val.trim().length === 0) {
    throw new Error(`${name} is required and must be a non-empty string`);
  }
  if (val.length > maxLen) {
    throw new Error(`${name} exceeds maximum length of ${maxLen} characters`);
  }
  return val.trim();
}

function clampPagination(val, defaultVal, max) {
  const n = typeof val === 'number' ? val : defaultVal;
  return Math.max(1, Math.min(n, max));
}

const VALID_BODY_FORMATS = new Set(['storage', 'atlas_doc_format', 'view']);

function validateBodyFormat(val) {
  const fmt = val || 'storage';
  if (!VALID_BODY_FORMATS.has(fmt)) {
    throw new Error(`body_format must be one of: ${[...VALID_BODY_FORMATS].join(', ')}`);
  }
  return fmt;
}

function validateSpaceKey(val) {
  const key = requireString(val, 'space_key');
  if (!/^[A-Za-z0-9_-]+$/.test(key)) {
    throw new Error('space_key must contain only alphanumeric characters, hyphens, and underscores');
  }
  return key;
}

// --- Tool Handlers ---
async function handleTool(name, args) {
  switch (name) {
    case 'search_pages': {
      requireString(args.query, 'query');
      const maxResults = clampPagination(args.max_results, 10, 25);
      let cql = args.query;
      // Auto-wrap plain text in CQL text~ search if it doesn't look like CQL
      // (CQL operators: =, ~, !=, IN, AND, OR, NOT, space, type, label, etc.)
      if (!/[=~!]|(?:^|\s)(?:AND|OR|NOT|IN|type|space|label|ancestor|parent)\b/i.test(cql)) {
        cql = `type = "page" AND text ~ "${cql.replace(/\\/g, '\\\\').replace(/"/g, '\\"')}"`;
      }
      if (args.space_key && !cql.toLowerCase().includes('space')) {
        const safeSpaceKey = validateSpaceKey(args.space_key);
        cql = `space = "${safeSpaceKey}" AND (${cql})`;
      }
      const result = await confluenceFetch('GET',
        `/wiki/rest/api/content/search?cql=${encodeURIComponent(cql)}&limit=${maxResults}&expand=space,version`
      );
      return (result.results || []).map((p) => ({
        id: p.id, title: p.title,
        space: p.space?.key, spaceTitle: p.space?.name,
        lastModified: p.version?.when,
        modifiedBy: p.version?.by?.displayName,
      }));
    }

    case 'get_page': {
      const bodyFormat = validateBodyFormat(args.body_format);
      let page;
      if (args.page_id) {
        requireString(args.page_id, 'page_id');
        page = await confluenceFetch('GET',
          `/wiki/rest/api/content/${encodeURIComponent(args.page_id)}?expand=body.${bodyFormat},version,space,metadata.labels`
        );
      } else if (args.title && args.space_key) {
        requireString(args.title, 'title');
        const safeSpaceKey = validateSpaceKey(args.space_key);
        const results = await confluenceFetch('GET',
          `/wiki/rest/api/content?title=${encodeURIComponent(args.title)}&spaceKey=${encodeURIComponent(safeSpaceKey)}&expand=body.${bodyFormat},version,metadata.labels`
        );
        page = results.results?.[0];
        if (!page) return { error: `Page not found: "${args.title}" in space ${safeSpaceKey}` };
      } else {
        return { error: 'Provide either page_id or both title and space_key' };
      }

      return {
        id: page.id, title: page.title,
        space: page.space?.key,
        version: page.version?.number,
        lastModified: page.version?.when,
        modifiedBy: page.version?.by?.displayName,
        labels: (page.metadata?.labels?.results || []).map((l) => l.name),
        body: page.body?.[bodyFormat]?.value || '',
      };
    }

    case 'create_page': {
      const spaceKey = validateSpaceKey(args.space_key);
      requireString(args.title, 'title');
      requireString(args.body, 'body', MAX_BODY_LENGTH);
      const payload = {
        type: 'page',
        title: args.title,
        space: { key: spaceKey },
        body: {
          storage: {
            value: args.body,
            representation: 'storage',
          },
        },
      };
      if (args.parent_id) {
        payload.ancestors = [{ id: args.parent_id }];
      }

      const result = await confluenceFetch('POST', '/wiki/rest/api/content', payload);

      // Add labels if provided
      if (args.labels && args.labels.length > 0 && result.id) {
        const labelPayload = args.labels.map((l) => ({ prefix: 'global', name: l }));
        await confluenceFetch('POST',
          `/wiki/rest/api/content/${result.id}/label`, labelPayload
        );
      }

      return { id: result.id, title: result.title, space: spaceKey };
    }

    case 'update_page': {
      requireString(args.page_id, 'page_id');
      requireString(args.body, 'body', MAX_BODY_LENGTH);
      if (typeof args.version_number !== 'number' || args.version_number < 1) {
        throw new Error('version_number is required and must be a positive integer');
      }
      // Fetch existing page to preserve title when not provided
      let title = args.title;
      if (!title) {
        const existing = await confluenceFetch('GET',
          `/wiki/rest/api/content/${encodeURIComponent(args.page_id)}?expand=version`
        );
        title = existing.title;
      }

      const payload = {
        version: {
          number: args.version_number + 1,
          message: args.version_message || 'Updated via Claude Code cc-confluence plugin',
        },
        title,
        type: 'page',
        body: {
          storage: {
            value: args.body,
            representation: 'storage',
          },
        },
      };

      const result = await confluenceFetch('PUT',
        `/wiki/rest/api/content/${encodeURIComponent(args.page_id)}`, payload
      );
      return { id: result.id, title: result.title, version: result.version?.number };
    }

    case 'get_space': {
      const spaceKey = validateSpaceKey(args.space_key);
      const space = await confluenceFetch('GET',
        `/wiki/rest/api/space/${encodeURIComponent(spaceKey)}?expand=description.plain,homepage`
      );
      return {
        key: space.key, name: space.name,
        description: space.description?.plain?.value || '',
        homepage: space.homepage ? { id: space.homepage.id, title: space.homepage.title } : null,
        type: space.type,
      };
    }

    case 'get_page_children': {
      requireString(args.page_id, 'page_id');
      const maxResults = clampPagination(args.max_results, 25, 50);
      const result = await confluenceFetch('GET',
        `/wiki/rest/api/content/${encodeURIComponent(args.page_id)}/child/page?limit=${maxResults}&expand=version`
      );
      return (result.results || []).map((p) => ({
        id: p.id, title: p.title,
        version: p.version?.number,
        lastModified: p.version?.when,
      }));
    }

    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

// --- MCP Server Bootstrap ---
async function main() {
  try {
    const { McpServer } = require('@modelcontextprotocol/sdk/server/mcp.js');
    const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');

    const server = new McpServer({ name: 'cc-confluence', version: '2.0.0' });

    for (const tool of TOOLS) {
      server.tool(tool.name, tool.description, tool.inputSchema, async (args) => {
        try {
          const result = await handleTool(tool.name, args);
          return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] };
        } catch (err) {
          return { content: [{ type: 'text', text: `Error: ${err.message}` }], isError: true };
        }
      });
    }

    const transport = new StdioServerTransport();
    await server.connect(transport);
  } catch (err) {
    process.stderr.write(`[cc-confluence] MCP SDK not found. Install: npm install @modelcontextprotocol/sdk\n`);
    process.stderr.write(`[cc-confluence] Error: ${err.message}\n`);
    process.exit(1);
  }
}

main();