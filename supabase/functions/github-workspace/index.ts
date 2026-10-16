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

const validRepoPart = /^[A-Za-z0-9_.-]+$/;
const maxFiles = 250;
const maxFileBytes = 1024 * 1024;
const maxTotalBytes = 8 * 1024 * 1024;
const excludedSegments = new Set([
  '.git',
  '.dart_tool',
  '.gradle',
  'build',
  'coverage',
  'node_modules',
  'Pods',
  'ephemeral',
]);
const binaryExtensions = new Set([
  '7z', 'aab', 'apk', 'avi', 'bin', 'bmp', 'class', 'db', 'dll', 'dylib',
  'exe', 'gif', 'gz', 'ico', 'jar', 'jpeg', 'jpg', 'mov', 'mp3', 'mp4',
  'otf', 'pdf', 'png', 'so', 'sqlite', 'tar', 'ttf', 'wasm', 'webm',
  'webp', 'woff', 'woff2', 'zip',
]);

function decodeBase64(value: string): Uint8Array {
  const compact = value.replace(/\s/g, '');
  const binary = atob(compact);
  return Uint8Array.from(binary, (character) => character.charCodeAt(0));
}

function encodeBase64(value: string): string {
  const bytes = new TextEncoder().encode(value);
  let binary = '';
  for (let offset = 0; offset < bytes.length; offset += 0x8000) {
    binary += String.fromCharCode(...bytes.subarray(offset, offset + 0x8000));
  }
  return btoa(binary);
}

function isText(bytes: Uint8Array): boolean {
  const sample = bytes.subarray(0, Math.min(bytes.length, 8000));
  if (sample.some((byte) => byte === 0)) return false;
  try {
    new TextDecoder('utf-8', { fatal: true }).decode(sample);
    return true;
  } catch (_) {
    return false;
  }
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }
  if (request.method !== 'POST') return json({ error: 'Method not allowed.' }, 405);

  try {
    const authHeader = request.headers.get('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
      return json({ error: 'Sign in before using GitHub workspace.' }, 401);
    }

    const supabaseUrl = Deno.env.get('SUPABASE_URL');
    const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY');
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: 'Supabase function environment is incomplete.' }, 500);
    }

    const admin = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const token = authHeader.slice('Bearer '.length);
    const { data: authData, error: authError } = await admin.auth.getUser(token);
    if (authError || !authData.user) {
      return json({ error: 'Your session is no longer valid.' }, 401);
    }

    const body = await request.json();
    const operation = body.operation?.toString();
    const owner = body.owner?.toString();
    const repo = body.repo?.toString();
    const branch = body.branch?.toString();
    const githubToken = body.github_token?.toString().trim();
    if (!operation || !owner || !repo ||
        !validRepoPart.test(owner) || !validRepoPart.test(repo)) {
      return json({ error: 'A valid GitHub owner and repository are required.' }, 400);
    }

    const github = async (path: string, init: RequestInit = {}) => {
      const response = await fetch(`https://api.github.com${path}`, {
        ...init,
        headers: {
          Accept: 'application/vnd.github+json',
          'X-GitHub-Api-Version': '2022-11-28',
          'User-Agent': 'CodeSnap-Workspace',
          ...(githubToken ? { Authorization: `Bearer ${githubToken}` } : {}),
          ...(init.headers ?? {}),
        },
      });
      const payload = await response.json().catch(() => ({}));
      if (!response.ok) {
        const message = payload?.message?.toString() ?? 'GitHub request failed.';
        throw new Error(`${response.status}: ${message}`);
      }
      return payload;
    };

    if (operation === 'repository') {
      const repository = await github(`/repos/${owner}/${repo}`);
      return json({
        owner: repository.owner?.login,
        name: repository.name,
        url: repository.html_url,
        default_branch: repository.default_branch,
        description: repository.description,
        private: repository.private === true,
      });
    }

    if (!branch || branch.length > 255) {
      return json({ error: 'A valid branch is required.' }, 400);
    }

    const fetchTree = async () => {
      const encodedBranch = encodeURIComponent(branch);
      const tree = await github(
        `/repos/${owner}/${repo}/git/trees/${encodedBranch}?recursive=1`,
      );
      if (tree.truncated === true) {
        throw new Error('Repository tree is too large to load safely.');
      }
      return (tree.tree ?? []) as Array<Record<string, unknown>>;
    };

    if (operation === 'tree') {
      const tree = await fetchTree();
      return json({
        entries: tree.map((entry) => ({
          path: entry.path,
          type: entry.type,
          sha: entry.sha,
          size: entry.size ?? 0,
        })),
      });
    }

    if (operation === 'load') {
      const tree = await fetchTree();
      const candidates = tree.filter((entry) => {
        if (entry.type !== 'blob' || Number(entry.size ?? 0) > maxFileBytes) {
          return false;
        }
        const path = entry.path?.toString() ?? '';
        const parts = path.split('/');
        const extension = parts.at(-1)?.split('.').at(-1)?.toLowerCase() ?? '';
        return !parts.some((part) => excludedSegments.has(part)) &&
          !binaryExtensions.has(extension);
      });
      if (candidates.length > maxFiles) {
        return json({
          error: `Repository has more than ${maxFiles} loadable files. Narrow it before loading.`,
        }, 413);
      }

      const blobShas: Record<string, string> = {};
      const skippedFiles: string[] = [];
      let totalBytes = 0;
      const selected = candidates.filter((entry) => {
        const size = Number(entry.size ?? 0);
        if (totalBytes + size > maxTotalBytes) {
          skippedFiles.push(entry.path?.toString() ?? 'unknown');
          return false;
        }
        totalBytes += size;
        return true;
      });

      const files: Record<string, string> = {};
      const batchSize = 12;
      const loadFile = async (entry: Record<string, unknown>) => {
        const path = entry.path?.toString() ?? '';
        const sha = entry.sha?.toString() ?? '';
        if (!path || !sha) return;

        const encodedPath = path.split('/').map(encodeURIComponent).join('/');
        const url = githubToken
          ? `https://api.github.com/repos/${owner}/${repo}/contents/${encodedPath}?ref=${encodeURIComponent(branch)}`
          : `https://raw.githubusercontent.com/${owner}/${repo}/${encodeURIComponent(branch)}/${encodedPath}`;
        const response = await fetch(url, {
          headers: {
            Accept: githubToken
              ? 'application/vnd.github.raw+json'
              : 'text/plain, application/octet-stream',
            'X-GitHub-Api-Version': '2022-11-28',
            'User-Agent': 'CodeSnap-Workspace',
            ...(githubToken ? { Authorization: `Bearer ${githubToken}` } : {}),
          },
        });
        if (!response.ok) {
          skippedFiles.push(path);
          return;
        }

        const bytes = new Uint8Array(await response.arrayBuffer());
        if (bytes.length > maxFileBytes || !isText(bytes)) {
          skippedFiles.push(path);
          return;
        }
        files[path] = new TextDecoder().decode(bytes);
        blobShas[path] = sha;
      };

      for (let offset = 0; offset < selected.length; offset += batchSize) {
        await Promise.all(selected.slice(offset, offset + batchSize).map(loadFile));
      }

      if (selected.length > 0 && Object.keys(files).length === 0) {
        return json({ error: 'GitHub source files could not be downloaded.' }, 502);
      }
      return json({
        files,
        blob_shas: blobShas,
        skipped_files: skippedFiles,
      });
    }

    if (operation === 'commit_file') {
      if (!githubToken) {
        return json({ error: 'A GitHub token is required to push commits.' }, 401);
      }
      const sourceProjectId = body.source_project_id?.toString();
      const personalCopy = body.personal_copy === true;
      if (!sourceProjectId) {
        return json({ error: 'A source project is required for GitHub commits.' }, 400);
      }

      if (personalCopy) {
        const viewer = await github('/user');
        if (viewer.login?.toString().toLowerCase() !== owner.toLowerCase()) {
          return json({
            error: 'Personal-copy commits must target a repository owned by your GitHub account.',
          }, 403);
        }
      } else {
        const { data: sourceProject, error: sourceError } = await admin
          .from('workspace_projects')
          .select('user_id, git_owner, git_repo_name')
          .eq('id', sourceProjectId)
          .maybeSingle();
        if (sourceError || !sourceProject ||
            sourceProject.user_id !== authData.user.id ||
            sourceProject.git_owner?.toString().toLowerCase() !== owner.toLowerCase() ||
            sourceProject.git_repo_name?.toString().toLowerCase() !== repo.toLowerCase()) {
          return json({
            error: 'You cannot push commits to another user\'s original project.',
          }, 403);
        }
      }

      const path = body.path?.toString().replace(/^\/+/, '');
      const content = body.content?.toString();
      const message = body.message?.toString().trim();
      const sha = body.sha?.toString();
      if (!path || path.includes('..') || content == null || !message) {
        return json({ error: 'A safe path, content, and commit message are required.' }, 400);
      }
      if (new TextEncoder().encode(content).length > maxFileBytes) {
        return json({ error: 'Files larger than 1 MB cannot be pushed from Workspace.' }, 413);
      }
      const result = await github(
        `/repos/${owner}/${repo}/contents/${path.split('/').map(encodeURIComponent).join('/')}`,
        {
          method: 'PUT',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify({
            message,
            content: encodeBase64(content),
            branch,
            ...(sha ? { sha } : {}),
          }),
        },
      );
      return json({
        commit_sha: result.commit?.sha,
        blob_sha: result.content?.sha,
        html_url: result.commit?.html_url,
      });
    }

    return json({ error: 'Unsupported GitHub workspace operation.' }, 400);
  } catch (error) {
    const message = error instanceof Error ? error.message : 'GitHub request failed.';
    const status = /^4\d\d:/.test(message) ? Number(message.slice(0, 3)) : 500;
    return json({ error: message.replace(/^\d{3}:\s*/, '') }, status);
  }
});
