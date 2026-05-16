import { Navigate, Outlet } from "react-router-dom";

// Auth placeholder — replace with real auth in production.
// For Part 1, all routes are accessible; the guard is wired but always passes.
const isAuthenticated = () => true;

export function ProtectedRoute() {
  if (!isAuthenticated()) {
    return <Navigate to="/login" replace />;
  }
  return <Outlet />;
}
