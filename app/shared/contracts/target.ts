export interface Target {
  id: string;
  name: string;
  primary_domain: string;
  tags: string[];
  owner: string | null;
  status: "active" | "archived";
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
  status?: "active" | "archived";
}
