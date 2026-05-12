import type { RunStatus } from "./api";

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

export interface RunCreate {
  session_id: string;
}

export interface RunLogEntry {
  timestamp: string;
  level: "info" | "warn" | "error" | "debug";
  stage: string;
  message: string;
}

export interface RunLogs {
  run_id: string;
  status: RunStatus;
  stage: string;
  logs: RunLogEntry[];
}
