import { useNavigate } from "react-router-dom";

export function NotFoundPage() {
  const navigate = useNavigate();
  return (
    <div style={{ display: "flex", flexDirection: "column", alignItems: "center", justifyContent: "center", height: 300, gap: 12, textAlign: "center" }}>
      <div style={{ fontSize: 56, fontWeight: 700, color: "var(--slate-300)", lineHeight: 1 }}>404</div>
      <p style={{ color: "var(--fg3)", fontSize: 14, margin: 0 }}>Page not found.</p>
      <button onClick={() => navigate("/dashboard")} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--brand-cyan-600)", fontSize: 13, fontFamily: "var(--font-sans)" }}>
        ← Back to dashboard
      </button>
    </div>
  );
}
