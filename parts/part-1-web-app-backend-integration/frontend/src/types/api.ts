// ── API envelope ─────────────────────────────────────────────────────────────

export interface APIResponse<T = unknown> {
  success: boolean;
  correlation_id: string | null;
  data: T | null;
  error: { code: string; message: string } | null;
}

export interface PagedData<T> {
  items: T[];
  total: number;
}

// ── Target ───────────────────────────────────────────────────────────────────

export interface Target {
  id: string;
  name: string;
  primary_domain: string;
  tags: string[];
  owner: string | null;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface TargetCreate {
  name: string;
  primary_domain: string;
  tags?: string[];
  owner?: string;
}

export interface TargetUpdate {
  name?: string;
  tags?: string[];
  owner?: string;
  status?: string;
}

// ── Session ───────────────────────────────────────────────────────────────────

export type ReconProfile = "core" | "advanced";

export interface Session {
  id: string;
  target_id: string;
  name: string | null;
  profile: ReconProfile;
  scope_definition: Record<string, unknown>;
  scope_locked: boolean;
  status: string;
  created_at: string;
  updated_at: string;
}

export interface SessionCreate {
  target_id: string;
  name?: string;
  profile?: ReconProfile;
  scope_definition?: Record<string, unknown>;
}

export interface SessionUpdate {
  name?: string;
  profile?: ReconProfile;
  scope_definition?: Record<string, unknown>;
  status?: string;
}

// ── Run ───────────────────────────────────────────────────────────────────────

export type RunStatus = "pending" | "running" | "completed" | "failed" | "cancelled";

export interface Run {
  id: string;
  session_id: string;
  stage: string;
  status: RunStatus;
  started_at: string | null;
  completed_at: string | null;
  error: string | null;
  created_at: string;
  updated_at: string;
}

export interface RunLogEntry {
  timestamp: string;
  level: string;
  stage: string;
  message: string;
}

export interface RunLogs {
  run_id: string;
  status: RunStatus;
  stage: string;
  logs: RunLogEntry[];
}

// ── Health ────────────────────────────────────────────────────────────────────

export interface Health {
  status: string;
  version: string;
  database: string;
}
