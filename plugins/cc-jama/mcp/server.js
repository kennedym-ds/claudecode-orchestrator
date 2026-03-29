#!/usr/bin/env node
/**
 * cc-jama MCP Server — Jama Connect REST API integration for Claude Code.
 *
 * Tools: get_items, get_item, search_items, get_item_children, get_relationships,
 *        get_test_runs, get_item_types, get_projects
 *
 * Auth: OAuth 2.0 client credentials (client_id + client_secret)
 * Docs: https://dev.jamasoftware.com/rest
 */
const https = require('https');
const http = require('http');

// --- Configuration ---
const JAMA_BASE_URL = (process.env.JAMA_BASE_URL || '').replace(/\/+$/, '');
const JAMA_CLIENT_ID = process.env.JAMA_CLIENT_ID || '';
const JAMA_CLIENT_SECRET = process.env.JAMA_CLIENT_SECRET || '';

if (!JAMA_BASE_URL || !JAMA_CLIENT_ID || !JAMA_CLIENT_SECRET) {
  process.stderr.write(
    '[cc-jama] Missing required env vars: JAMA_BASE_URL, JAMA_CLIENT_ID, JAMA_CLIENT_SECRET\n'
  );
}

// --- Token Cache ---
let tokenCache = { token: null, expiresAt: 0 };

async function getAccessToken() {
  if (tokenCache.token && Date.now() < tokenCache.expiresAt - 30000) {
    return tokenCache.token;
  }

  const url = new URL('/rest/oauth/token', JAMA_BASE_URL);
  const isLocalhost = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
  if (url.protocol !== 'https:' && !isLocalhost) {
    throw new Error('JAMA_BASE_URL must use HTTPS for non-localhost connections');
  }

  return new Promise((resolve, reject) => {
    const postData = 'grant_type=client_credentials';
    const auth = Buffer.from(`${JAMA_CLIENT_ID}:${JAMA_CLIENT_SECRET}`).toString('base64');

    const options = {
      method: 'POST',
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname,
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
        'Content-Length': Buffer.byteLength(postData),
      },
    };

    const transport = url.protocol === 'https:' ? https : http;
    const req = transport.request(options, (res) => {
      let data = '';
      res.on('data', (chunk) => (data += chunk));
      res.on('end', () => {
        if (res.statusCode === 200) {
          try {
            const body = JSON.parse(data);
            tokenCache.token = body.access_token;
            tokenCache.expiresAt = Date.now() + (body.expires_in || 3600) * 1000;
            resolve(body.access_token);
          } catch (e) { reject(new Error('Failed to parse token response')); }
        } else {
          reject(new Error(`Token request failed (${res.statusCode}): ${data.slice(0, 300)}`));
        }
      });
    });
    req.on('error', reject);
    req.setTimeout(15000, () => { req.destroy(); reject(new Error('Token request timeout')); });
    req.write(postData);
    req.end();
  });
}

// --- HTTP Client ---
async function jamaFetch(method, path, body) {
  const token = await getAccessToken();
  const url = new URL(path, JAMA_BASE_URL);

  return new Promise((resolve, reject) => {
    const options = {
      method,
      hostname: url.hostname,
      port: url.port || (url.protocol === 'https:' ? 443 : 80),
      path: url.pathname + url.search,
      headers: {
        'Authorization': `Bearer ${token}`,
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
          reject(new Error(`Jama API ${res.statusCode}: ${data.slice(0, 500)}`));
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
    name: 'get_items',
    description: 'Get items from a Jama project. Items are requirements, test cases, features, etc.',
    inputSchema: {
      type: 'object',
      properties: {
        project_id: { type: 'number', description: 'Jama project ID' },
        item_type: { type: 'number', description: 'Filter by item type ID (optional)' },
        max_results: { type: 'number', description: 'Maximum results (default: 20, max: 50)', default: 20 },
        start_at: { type: 'number', description: 'Pagination offset (default: 0)', default: 0 },
      },
      required: ['project_id'],
    },
  },
  {
    name: 'search_items',
    description: 'Search for items across Jama by text query. Returns matching requirements, test cases, and other items.',
    inputSchema: {
      type: 'object',
      properties: {
        query: { type: 'string', description: 'Search text (searches name, description, and custom fields)' },
        project_id: { type: 'number', description: 'Limit search to a specific project (optional)' },
        item_type: { type: 'number', description: 'Limit search to a specific item type (optional)' },
        max_results: { type: 'number', description: 'Maximum results (default: 20, max: 50)', default: 20 },
      },
      required: ['query'],
    },
  },
  {
    name: 'get_item',
    description: 'Get a single Jama item by ID with full details including fields, status, and relationships count.',
    inputSchema: {
      type: 'object',
      properties: {
        item_id: { type: 'number', description: 'Jama item ID' },
      },
      required: ['item_id'],
    },
  },
  {
    name: 'get_item_children',
    description: 'Get child items of a Jama item (hierarchical tree navigation).',
    inputSchema: {
      type: 'object',
      properties: {
        item_id: { type: 'number', description: 'Parent item ID' },
        max_results: { type: 'number', description: 'Maximum results (default: 20)', default: 20 },
      },
      required: ['item_id'],
    },
  },
  {
    name: 'get_relationships',
    description: 'Get upstream and downstream relationships (traces) for a Jama item. Essential for requirements traceability.',
    inputSchema: {
      type: 'object',
      properties: {
        item_id: { type: 'number', description: 'Item ID to get relationships for' },
        direction: { type: 'string', description: 'Filter direction: upstream, downstream, or both (default: both)' },
      },
      required: ['item_id'],
    },
  },
  {
    name: 'get_test_runs',
    description: 'Get test runs associated with a test cycle or test plan. Shows execution status and results.',
    inputSchema: {
      type: 'object',
      properties: {
        test_cycle_id: { type: 'number', description: 'Test cycle ID to get runs for' },
        max_results: { type: 'number', description: 'Maximum results (default: 20)', default: 20 },
      },
      required: ['test_cycle_id'],
    },
  },
  {
    name: 'get_projects',
    description: 'List all Jama projects the authenticated user has access to.',
    inputSchema: {
      type: 'object',
      properties: {
        max_results: { type: 'number', description: 'Maximum results (default: 20)', default: 20 },
      },
    },
  },
  {
    name: 'get_item_types',
    description: 'List item types available in a Jama project (requirements, test cases, features, etc.).',
    inputSchema: {
      type: 'object',
      properties: {
        project_id: { type: 'number', description: 'Project ID (optional, lists global types if omitted)' },
      },
    },
  },
];

// --- Input Validation ---
function requireNumber(val, name) {
  if (typeof val !== 'number' || !Number.isFinite(val) || val < 0) {
    throw new Error(`${name} is required and must be a non-negative number`);
  }
  return val;
}

function requireString(val, name) {
  if (typeof val !== 'string' || val.trim().length === 0) {
    throw new Error(`${name} is required and must be a non-empty string`);
  }
  return val.trim();
}

function clampPagination(val, defaultVal, max) {
  const n = typeof val === 'number' ? val : defaultVal;
  return Math.max(1, Math.min(n, max));
}

// --- Tool Handlers ---
function formatItem(item) {
  return {
    id: item.id,
    documentKey: item.documentKey,
    name: item.fields?.name || '',
    description: item.fields?.description || '',
    itemType: item.itemType,
    project: item.project,
    status: item.fields?.status,
    priority: item.fields?.priority,
    createdDate: item.createdDate,
    modifiedDate: item.modifiedDate,
  };
}

async function handleTool(name, args) {
  switch (name) {
    case 'get_items': {
      requireNumber(args.project_id, 'project_id');
      const maxResults = clampPagination(args.max_results, 20, 50);
      const startAt = Math.max(args.start_at || 0, 0);
      let path = `/rest/v1/items?project=${args.project_id}&startAt=${startAt}&maxResults=${maxResults}`;
      if (args.item_type) path += `&itemType=${args.item_type}`;
      const result = await jamaFetch('GET', path);
      return {
        items: (result.data || []).map(formatItem),
        totalResults: result.meta?.pageInfo?.totalResults || 0,
        startAt,
        maxResults,
      };
    }

    case 'search_items': {
      requireString(args.query, 'query');
      const maxResults = clampPagination(args.max_results, 20, 50);
      let path = `/rest/v1/abstractitems?contains=${encodeURIComponent(args.query)}&maxResults=${maxResults}`;
      if (args.project_id) path += `&project=${args.project_id}`;
      if (args.item_type) path += `&itemType=${args.item_type}`;
      const result = await jamaFetch('GET', path);
      return {
        items: (result.data || []).map(formatItem),
        totalResults: result.meta?.pageInfo?.totalResults || 0,
      };
    }

    case 'get_item': {
      requireNumber(args.item_id, 'item_id');
      const result = await jamaFetch('GET', `/rest/v1/items/${encodeURIComponent(args.item_id)}`);
      return formatItem(result.data);
    }

    case 'get_item_children': {
      requireNumber(args.item_id, 'item_id');
      const maxResults = clampPagination(args.max_results, 20, 50);
      const result = await jamaFetch('GET',
        `/rest/v1/items/${encodeURIComponent(args.item_id)}/children?maxResults=${maxResults}`
      );
      return {
        children: (result.data || []).map(formatItem),
        totalResults: result.meta?.pageInfo?.totalResults || 0,
      };
    }

    case 'get_relationships': {
      requireNumber(args.item_id, 'item_id');
      const validDirections = ['upstream', 'downstream', 'both'];
      const direction = validDirections.includes(args.direction) ? args.direction : 'both';
      const relationships = [];

      if (direction === 'upstream' || direction === 'both') {
        const up = await jamaFetch('GET',
          `/rest/v1/items/${encodeURIComponent(args.item_id)}/upstreamrelationships`
        );
        (up.data || []).forEach((r) => {
          relationships.push({
            id: r.id, direction: 'upstream',
            fromItem: r.fromItem, toItem: r.toItem,
            relationshipType: r.relationshipType,
          });
        });
      }

      if (direction === 'downstream' || direction === 'both') {
        const down = await jamaFetch('GET',
          `/rest/v1/items/${encodeURIComponent(args.item_id)}/downstreamrelationships`
        );
        (down.data || []).forEach((r) => {
          relationships.push({
            id: r.id, direction: 'downstream',
            fromItem: r.fromItem, toItem: r.toItem,
            relationshipType: r.relationshipType,
          });
        });
      }

      return { itemId: args.item_id, relationships };
    }

    case 'get_test_runs': {
      requireNumber(args.test_cycle_id, 'test_cycle_id');
      const maxResults = clampPagination(args.max_results, 20, 50);
      const result = await jamaFetch('GET',
        `/rest/v1/testcycles/${encodeURIComponent(args.test_cycle_id)}/testruns?maxResults=${maxResults}`
      );
      return {
        testRuns: (result.data || []).map((tr) => ({
          id: tr.id,
          testCaseId: tr.fields?.testCase,
          status: tr.fields?.testRunStatus,
          result: tr.fields?.testRunResult,
          executedBy: tr.fields?.executedBy,
          executionDate: tr.fields?.executionDate,
        })),
        totalResults: result.meta?.pageInfo?.totalResults || 0,
      };
    }

    case 'get_projects': {
      const maxResults = clampPagination(args.max_results, 20, 50);
      const result = await jamaFetch('GET', `/rest/v1/projects?maxResults=${maxResults}`);
      return (result.data || []).map((p) => ({
        id: p.id, projectKey: p.projectKey,
        name: p.fields?.name || '', description: p.fields?.description || '',
        isFolder: p.isFolder, createdDate: p.createdDate,
      }));
    }

    case 'get_item_types': {
      let path = '/rest/v1/itemtypes';
      if (args.project_id) path = `/rest/v1/projects/${encodeURIComponent(args.project_id)}/itemtypes`;
      const result = await jamaFetch('GET', path);
      return (result.data || []).map((t) => ({
        id: t.id, typeKey: t.typeKey,
        display: t.display, category: t.category,
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

    const server = new McpServer({ name: 'cc-jama', version: '0.1.0' });

    for (const tool of TOOLS) {
      server.tool(tool.name, tool.description, tool.inputSchema.properties, async (args) => {
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
    process.stderr.write(`[cc-jama] MCP SDK not found. Install: npm install @modelcontextprotocol/sdk\n`);
    process.stderr.write(`[cc-jama] Error: ${err.message}\n`);
    process.exit(1);
  }
}

main();