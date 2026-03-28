#!/usr/bin/env node
/**
 * cc-jira MCP Server — Jira Cloud REST API integration for Claude Code.
 *
 * Tools: search_issues, get_issue, create_issue, update_issue,
 *        transition_issue, add_comment, get_sprint, get_project
 *
 * Auth: API token via environment variables (JIRA_BASE_URL, JIRA_USER_EMAIL, JIRA_API_TOKEN)
 * Docs: https://developer.atlassian.com/cloud/jira/platform/rest/v3/
 */
const https = require('https');
const http = require('http');

// --- Configuration ---
const JIRA_BASE_URL = (process.env.JIRA_BASE_URL || '').replace(/\/+$/, '');
const JIRA_USER_EMAIL = process.env.JIRA_USER_EMAIL || '';
const JIRA_API_TOKEN = process.env.JIRA_API_TOKEN || '';

if (!JIRA_BASE_URL || !JIRA_USER_EMAIL || !JIRA_API_TOKEN) {
  process.stderr.write(
    '[cc-jira] Missing required env vars: JIRA_BASE_URL, JIRA_USER_EMAIL, JIRA_API_TOKEN\n'
  );
}

// --- HTTP Client ---
function jiraFetch(method, path, body) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, JIRA_BASE_URL);

    // Only allow HTTPS in production; HTTP only for localhost/testing
    const isLocalhost = url.hostname === 'localhost' || url.hostname === '127.0.0.1';
    if (url.protocol !== 'https:' && !isLocalhost) {
      reject(new Error('JIRA_BASE_URL must use HTTPS for non-localhost connections'));
      return;
    }

    const auth = Buffer.from(`${JIRA_USER_EMAIL}:${JIRA_API_TOKEN}`).toString('base64');
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
          reject(new Error(`Jira API ${res.statusCode}: ${data.slice(0, 500)}`));
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
    name: 'search_issues',
    description: 'Search Jira issues using JQL (Jira Query Language). Returns key, summary, status, assignee, and priority.',
    inputSchema: {
      type: 'object',
      properties: {
        jql: { type: 'string', description: 'JQL query string (e.g., "project = PROJ AND status = Open")' },
        max_results: { type: 'number', description: 'Maximum results to return (default: 20, max: 50)', default: 20 },
      },
      required: ['jql'],
    },
  },
  {
    name: 'get_issue',
    description: 'Get full details of a Jira issue by key (e.g., PROJ-123). Returns summary, description, status, comments, and linked issues.',
    inputSchema: {
      type: 'object',
      properties: {
        issue_key: { type: 'string', description: 'Jira issue key (e.g., PROJ-123)' },
      },
      required: ['issue_key'],
    },
  },
  {
    name: 'create_issue',
    description: 'Create a new Jira issue. Returns the created issue key.',
    inputSchema: {
      type: 'object',
      properties: {
        project_key: { type: 'string', description: 'Project key (e.g., PROJ)' },
        summary: { type: 'string', description: 'Issue title' },
        description: { type: 'string', description: 'Issue description (plain text or ADF JSON)' },
        issue_type: { type: 'string', description: 'Issue type: Story, Task, Bug, Epic, Sub-task', default: 'Task' },
        priority: { type: 'string', description: 'Priority: Highest, High, Medium, Low, Lowest', default: 'Medium' },
        labels: { type: 'array', items: { type: 'string' }, description: 'Labels to apply' },
        assignee_id: { type: 'string', description: 'Atlassian account ID of assignee (optional)' },
        parent_key: { type: 'string', description: 'Parent issue key for sub-tasks or stories under epics' },
      },
      required: ['project_key', 'summary', 'issue_type'],
    },
  },
  {
    name: 'update_issue',
    description: 'Update fields on an existing Jira issue.',
    inputSchema: {
      type: 'object',
      properties: {
        issue_key: { type: 'string', description: 'Issue key to update' },
        summary: { type: 'string', description: 'New summary (optional)' },
        description: { type: 'string', description: 'New description (optional)' },
        priority: { type: 'string', description: 'New priority (optional)' },
        labels: { type: 'array', items: { type: 'string' }, description: 'Replace labels (optional)' },
        assignee_id: { type: 'string', description: 'New assignee account ID (optional)' },
      },
      required: ['issue_key'],
    },
  },
  {
    name: 'transition_issue',
    description: 'Transition a Jira issue to a new status (e.g., In Progress, Done). Lists available transitions if transition_id is omitted.',
    inputSchema: {
      type: 'object',
      properties: {
        issue_key: { type: 'string', description: 'Issue key to transition' },
        transition_id: { type: 'string', description: 'Transition ID (omit to list available transitions)' },
      },
      required: ['issue_key'],
    },
  },
  {
    name: 'add_comment',
    description: 'Add a comment to a Jira issue.',
    inputSchema: {
      type: 'object',
      properties: {
        issue_key: { type: 'string', description: 'Issue key' },
        body: { type: 'string', description: 'Comment text' },
      },
      required: ['issue_key', 'body'],
    },
  },
  {
    name: 'get_sprint',
    description: 'Get the active sprint for a board, including all issues in the sprint.',
    inputSchema: {
      type: 'object',
      properties: {
        board_id: { type: 'string', description: 'Jira board ID' },
      },
      required: ['board_id'],
    },
  },
  {
    name: 'get_project',
    description: 'Get project metadata including issue types, leads, and components.',
    inputSchema: {
      type: 'object',
      properties: {
        project_key: { type: 'string', description: 'Project key (e.g., PROJ)' },
      },
      required: ['project_key'],
    },
  },
];

// --- Tool Handlers ---
async function handleTool(name, args) {
  switch (name) {
    case 'search_issues': {
      const maxResults = Math.min(args.max_results || 20, 50);
      const result = await jiraFetch('GET',
        `/rest/api/3/search?jql=${encodeURIComponent(args.jql)}&maxResults=${maxResults}&fields=key,summary,status,assignee,priority,issuetype`
      );
      return (result.issues || []).map((i) => ({
        key: i.key,
        summary: i.fields?.summary,
        status: i.fields?.status?.name,
        assignee: i.fields?.assignee?.displayName || 'Unassigned',
        priority: i.fields?.priority?.name,
        type: i.fields?.issuetype?.name,
      }));
    }

    case 'get_issue': {
      const issue = await jiraFetch('GET',
        `/rest/api/3/issue/${encodeURIComponent(args.issue_key)}?fields=summary,description,status,assignee,priority,issuetype,labels,comment,issuelinks,parent,created,updated`
      );
      return {
        key: issue.key,
        summary: issue.fields?.summary,
        status: issue.fields?.status?.name,
        priority: issue.fields?.priority?.name,
        type: issue.fields?.issuetype?.name,
        assignee: issue.fields?.assignee?.displayName || 'Unassigned',
        labels: issue.fields?.labels || [],
        parent: issue.fields?.parent?.key || null,
        created: issue.fields?.created,
        updated: issue.fields?.updated,
        description: issue.fields?.description,
        comments: (issue.fields?.comment?.comments || []).slice(-5).map((c) => ({
          author: c.author?.displayName,
          created: c.created,
          body: c.body,
        })),
        links: (issue.fields?.issuelinks || []).map((l) => ({
          type: l.type?.name,
          inward: l.inwardIssue?.key,
          outward: l.outwardIssue?.key,
        })),
      };
    }

    case 'create_issue': {
      const fields = {
        project: { key: args.project_key },
        summary: args.summary,
        issuetype: { name: args.issue_type || 'Task' },
      };
      if (args.description) {
        fields.description = {
          type: 'doc', version: 1,
          content: [{ type: 'paragraph', content: [{ type: 'text', text: args.description }] }],
        };
      }
      if (args.priority) fields.priority = { name: args.priority };
      if (args.labels) fields.labels = args.labels;
      if (args.assignee_id) fields.assignee = { accountId: args.assignee_id };
      if (args.parent_key) fields.parent = { key: args.parent_key };

      const result = await jiraFetch('POST', '/rest/api/3/issue', { fields });
      return { key: result.key, self: result.self };
    }

    case 'update_issue': {
      const fields = {};
      if (args.summary) fields.summary = args.summary;
      if (args.description) {
        fields.description = {
          type: 'doc', version: 1,
          content: [{ type: 'paragraph', content: [{ type: 'text', text: args.description }] }],
        };
      }
      if (args.priority) fields.priority = { name: args.priority };
      if (args.labels) fields.labels = args.labels;
      if (args.assignee_id) fields.assignee = { accountId: args.assignee_id };

      await jiraFetch('PUT', `/rest/api/3/issue/${encodeURIComponent(args.issue_key)}`, { fields });
      return { updated: args.issue_key };
    }

    case 'transition_issue': {
      if (!args.transition_id) {
        const result = await jiraFetch('GET',
          `/rest/api/3/issue/${encodeURIComponent(args.issue_key)}/transitions`
        );
        return (result.transitions || []).map((t) => ({ id: t.id, name: t.name, to: t.to?.name }));
      }
      await jiraFetch('POST',
        `/rest/api/3/issue/${encodeURIComponent(args.issue_key)}/transitions`,
        { transition: { id: args.transition_id } }
      );
      return { transitioned: args.issue_key, transition_id: args.transition_id };
    }

    case 'add_comment': {
      const comment = {
        body: {
          type: 'doc', version: 1,
          content: [{ type: 'paragraph', content: [{ type: 'text', text: args.body }] }],
        },
      };
      const result = await jiraFetch('POST',
        `/rest/api/3/issue/${encodeURIComponent(args.issue_key)}/comment`, comment
      );
      return { id: result.id, issue_key: args.issue_key };
    }

    case 'get_sprint': {
      const sprints = await jiraFetch('GET',
        `/rest/agile/1.0/board/${encodeURIComponent(args.board_id)}/sprint?state=active`
      );
      const sprint = sprints.values?.[0];
      if (!sprint) return { message: 'No active sprint found' };

      const issues = await jiraFetch('GET',
        `/rest/agile/1.0/sprint/${sprint.id}/issue?fields=key,summary,status,assignee,priority`
      );
      return {
        sprint: { id: sprint.id, name: sprint.name, goal: sprint.goal, startDate: sprint.startDate, endDate: sprint.endDate },
        issues: (issues.issues || []).map((i) => ({
          key: i.key, summary: i.fields?.summary, status: i.fields?.status?.name,
          assignee: i.fields?.assignee?.displayName || 'Unassigned',
        })),
      };
    }

    case 'get_project': {
      const project = await jiraFetch('GET',
        `/rest/api/3/project/${encodeURIComponent(args.project_key)}`
      );
      return {
        key: project.key, name: project.name,
        lead: project.lead?.displayName,
        issueTypes: (project.issueTypes || []).map((t) => t.name),
        components: (project.components || []).map((c) => c.name),
      };
    }

    default:
      throw new Error(`Unknown tool: ${name}`);
  }
}

// --- MCP Server Bootstrap ---
// Uses @anthropic-ai/mcp SDK if available, otherwise falls back to stdio JSON-RPC
async function main() {
  try {
    const { McpServer } = require('@modelcontextprotocol/sdk/server/mcp.js');
    const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js');

    const server = new McpServer({ name: 'cc-jira', version: '0.1.0' });

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
    process.stderr.write(`[cc-jira] MCP SDK not found. Install: npm install @modelcontextprotocol/sdk\n`);
    process.stderr.write(`[cc-jira] Error: ${err.message}\n`);
    process.exit(1);
  }
}

main();