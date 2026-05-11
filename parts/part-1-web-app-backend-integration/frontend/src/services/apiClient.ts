import axios, { AxiosInstance, AxiosResponse } from "axios";
import { APIResponse } from "../types/api";

const BASE_URL = import.meta.env.VITE_API_URL ?? "/api/v1";

const http: AxiosInstance = axios.create({
  baseURL: BASE_URL,
  headers: { "Content-Type": "application/json" },
  timeout: 15_000,
});

// Attach correlation ID to every request
http.interceptors.request.use((config) => {
  config.headers["X-Correlation-ID"] = crypto.randomUUID();
  return config;
});

// Unwrap envelope or throw a structured error
http.interceptors.response.use(
  (res: AxiosResponse<APIResponse<unknown>>) => res,
  (err) => {
    const data = err.response?.data as APIResponse<unknown> | undefined;
    const message = data?.error?.message ?? err.message ?? "Unknown error";
    const code = data?.error?.code ?? "NETWORK_ERROR";
    const enhanced = new Error(message) as Error & { code: string; status: number };
    enhanced.code = code;
    enhanced.status = err.response?.status ?? 0;
    return Promise.reject(enhanced);
  }
);

export default http;
