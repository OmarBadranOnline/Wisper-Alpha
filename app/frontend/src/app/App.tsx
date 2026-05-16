import { BrowserRouter, Navigate, Route, Routes } from "react-router-dom";
import { ProtectedRoute } from "../routes/ProtectedRoute";
import { Layout } from "../components/layout/Layout";
import { DashboardPage } from "../pages/DashboardPage";
import { TargetsPage } from "../pages/TargetsPage";
import { SessionsPage } from "../pages/SessionsPage";
import { RunConsolePage } from "../pages/RunConsolePage";
import { SessionDetailPage } from "../pages/SessionDetailPage";
import { NewScanPage } from "../pages/NewScanPage";

export default function App() {
  return (
    <BrowserRouter>
      <Routes>
        <Route element={<ProtectedRoute />}>
          <Route element={<Layout />}>
            <Route index element={<Navigate to="/dashboard" replace />} />
            <Route path="/dashboard" element={<DashboardPage />} />
            <Route path="/targets" element={<TargetsPage />} />
            <Route path="/sessions" element={<SessionsPage />} />
            <Route path="/sessions/:id" element={<SessionDetailPage />} />
            <Route path="/runs/:id" element={<RunConsolePage />} />
            <Route path="/new-scan" element={<NewScanPage />} />
            <Route path="*" element={<Navigate to="/dashboard" replace />} />
          </Route>
        </Route>
      </Routes>
    </BrowserRouter>
  );
}
