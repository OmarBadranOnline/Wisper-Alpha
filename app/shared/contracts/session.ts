import type { ReconProfile } from "./api";

export interface Session {
  id: string;
  target_id: string;
  name: string | null;
  profile: ReconProfile;
  scope_definition: Record<string, unknown>;
  scope_locked: boolean;
  status: "active" | "archived";
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
  status?: "active" | "archived";
}
