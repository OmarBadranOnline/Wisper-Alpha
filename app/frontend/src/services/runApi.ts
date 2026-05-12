import http from "./apiClient";
import { APIResponse, PagedData, Run, RunLogs } from "../types/api";

export const runApi = {
  list: async (sessionId?: string, skip = 0, limit = 50): Promise<PagedData<Run>> => {
    const r = await http.get<APIResponse<PagedData<Run>>>("/runs", {
      params: { session_id: sessionId, skip, limit },
    });
    return r.data.data!;
  },

  start: async (sessionId: string): Promise<Run> => {
    const r = await http.post<APIResponse<Run>>("/runs", { session_id: sessionId });
    return r.data.data!;
  },

  get: async (id: string): Promise<Run> => {
    const r = await http.get<APIResponse<Run>>(`/runs/${id}`);
    return r.data.data!;
  },

  logs: async (id: string): Promise<RunLogs> => {
    const r = await http.get<APIResponse<RunLogs>>(`/runs/${id}/logs`);
    return r.data.data!;
  },

  cancel: async (id: string): Promise<Run> => {
    const r = await http.post<APIResponse<Run>>(`/runs/${id}/cancel`);
    return r.data.data!;
  },
};
