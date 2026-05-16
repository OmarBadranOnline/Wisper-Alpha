import { useLocation, useNavigate } from "react-router-dom";

const NAV = [
  {
    id: "dashboard",
    label: "Dashboard",
    path: "/dashboard",
    icon: `<path d="M3 9l9-7 9 7v11a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2z"/><polyline points="9 22 9 12 15 12 15 22"/>`,
  },
  {
    id: "new-scan",
    label: "New Scan",
    path: "/new-scan",
    icon: `<circle cx="12" cy="12" r="10"/><line x1="12" y1="8" x2="12" y2="16"/><line x1="8" y1="12" x2="16" y2="12"/>`,
    accent: true,
  },
  {
    id: "targets",
    label: "Targets",
    path: "/targets",
    icon: `<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>`,
  },
  {
    id: "sessions",
    label: "Sessions",
    path: "/sessions",
    icon: `<path d="M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8z"/><polyline points="14 2 14 8 20 8"/><line x1="16" y1="13" x2="8" y2="13"/><line x1="16" y1="17" x2="8" y2="17"/><polyline points="10 9 9 9 8 9"/>`,
  },
];

interface NavProps {
  scope?: string;
  profile?: string;
}

export function Navigation({ scope, profile }: NavProps) {
  const location = useLocation();
  const navigate = useNavigate();

  const isActive = (path: string) => {
    if (path === "/sessions")
      return (
        location.pathname.startsWith("/sessions") ||
        location.pathname.startsWith("/runs")
      );
    return (
      location.pathname === path || location.pathname.startsWith(path + "/")
    );
  };

  return (
    <aside className="ws-rail">
      {/* Brand */}
      <div className="ws-brand">
        <div className="ws-brand-logo">
          <svg viewBox="0 0 28 32" fill="none" width="22" height="26">
            <path
              d="M14 2L4 8v8c0 5.5 4.3 10.7 10 12 5.7-1.3 10-6.5 10-12V8L14 2z"
              fill="url(#brandGrad)"
            />
            <path
              d="M10 16l3 3 5-5"
              stroke="#fff"
              strokeWidth="2"
              strokeLinecap="round"
              strokeLinejoin="round"
            />
            <defs>
              <linearGradient id="brandGrad" x1="4" y1="2" x2="24" y2="30" gradientUnits="userSpaceOnUse">
                <stop stopColor="#4AAFD9" />
                <stop offset="1" stopColor="#1B3A5C" />
              </linearGradient>
            </defs>
          </svg>
        </div>
        <div>
          <div className="ws-brand-name">
            <b>WISPER</b> <span>ALPHA</span>
          </div>
          <div className="ws-brand-tag">Silent guardian</div>
        </div>
      </div>

      {/* Section label */}
      <div className="ws-nav-section">Workspace</div>

      {/* Nav items */}
      <nav style={{ display: "flex", flexDirection: "column", gap: 2 }}>
        {NAV.map(({ id, label, path, icon, accent }) => (
          <button
            key={id}
            className={`ws-nav-item ${isActive(path) ? "active" : ""} ${accent ? "ws-nav-accent" : ""}`}
            onClick={() => navigate(path)}
            title={label}
          >
            <span className="ws-nav-icon">
              <svg
                width="18"
                height="18"
                viewBox="0 0 24 24"
                fill="none"
                stroke="currentColor"
                strokeWidth="2"
                strokeLinecap="round"
                strokeLinejoin="round"
                dangerouslySetInnerHTML={{ __html: icon }}
              />
            </span>
            <span className="ws-nav-label">{label}</span>
            {isActive(path) && <span className="ws-nav-indicator" />}
          </button>
        ))}
      </nav>

      {/* Divider */}
      <div className="ws-nav-divider" />

      {/* Scope widget */}
      <div className="ws-scope">
        <div className="ws-scope-lbl">
          <svg
            width="11"
            height="11"
            viewBox="0 0 24 24"
            fill="none"
            stroke="currentColor"
            strokeWidth="2"
            strokeLinecap="round"
            strokeLinejoin="round"
          >
            <rect x="3" y="11" width="18" height="11" rx="2" />
            <path d="M7 11V7a5 5 0 0 1 10 0v4" />
          </svg>
          {scope ? "Scope · locked" : "No scope selected"}
        </div>
        <div className="ws-scope-val">{scope ?? "—"}</div>
        <div className="ws-scope-prof">{profile ?? "select a session"}</div>
      </div>

      {/* Version */}
      <div className="ws-rail-footer">
        <span className="ws-caps" style={{ fontSize: 9, color: "var(--slate-600)" }}>
          Wisper Alpha · v1.0
        </span>
      </div>
    </aside>
  );
}
