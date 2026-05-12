// Shared API contract definitions — consumed by frontend types/api.ts
// and referenced by backend schemas.py

export interface APIEnvelope<T = unknown> {
  success: boolean;
  correlation_id: string | null;
  data: T | null;
  error: { code: string; message: string } | null;
}

export interface PagedPayload<T> {
  items: T[];
  total: number;
}

export type ReconProfile = "core" | "advanced";
export type RunStatus = "pending" | "running" | "completed" | "failed" | "cancelled";
export type TargetStatus = "active" | "archived";
export type SessionStatus = "active" | "archived";
