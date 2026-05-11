import http from "./apiClient";
import { APIResponse, PagedData, Target, TargetCreate, TargetUpdate } from "../types/api";

export const targetApi = {
  list: async (skip = 0, limit = 100): Promise<PagedData<Target>> => {
    const r = await http.get<APIResponse<PagedData<Target>>>("/targets", {
      params: { skip, limit },
    });
    return r.data.data!;
  },

  get: async (id: string): Promise<Target> => {
    const r = await http.get<APIResponse<Target>>(`/targets/${id}`);
    return r.data.data!;
  },

  create: async (body: TargetCreate): Promise<Target> => {
    const r = await http.post<APIResponse<Target>>("/targets", body);
    return r.data.data!;
  },

  update: async (id: string, body: TargetUpdate): Promise<Target> => {
    const r = await http.patch<APIResponse<Target>>(`/targets/${id}`, body);
    return r.data.data!;
  },

  delete: async (id: string): Promise<void> => {
    await http.delete(`/targets/${id}`);
  },
};
