import http from "./apiClient";
import {
  APIResponse,
  PagedData,
  Session,
  SessionCreate,
  SessionUpdate,
} from "../types/api";

export const sessionApi = {
  list: async (targetId?: string, skip = 0, limit = 100): Promise<PagedData<Session>> => {
    const r = await http.get<APIResponse<PagedData<Session>>>("/sessions", {
      params: { target_id: targetId, skip, limit },
    });
    return r.data.data!;
  },

  get: async (id: string): Promise<Session> => {
    const r = await http.get<APIResponse<Session>>(`/sessions/${id}`);
    return r.data.data!;
  },

  create: async (body: SessionCreate): Promise<Session> => {
    const r = await http.post<APIResponse<Session>>("/sessions", body);
    return r.data.data!;
  },

  update: async (id: string, body: SessionUpdate): Promise<Session> => {
    const r = await http.patch<APIResponse<Session>>(`/sessions/${id}`, body);
    return r.data.data!;
  },

  lockScope: async (id: string): Promise<Session> => {
    const r = await http.post<APIResponse<Session>>(`/sessions/${id}/lock-scope`);
    return r.data.data!;
  },
};
