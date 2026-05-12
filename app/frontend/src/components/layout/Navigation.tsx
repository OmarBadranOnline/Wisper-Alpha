import { useLocation, useNavigate } from "react-router-dom";

const NAV = [
  { id: "dashboard", label: "Dashboard",       path: "/dashboard",  icon: '<rect x="3" y="3" width="7" height="7"/><rect x="14" y="3" width="7" height="7"/><rect x="3" y="14" width="7" height="7"/><rect x="14" y="14" width="7" height="7"/>' },
  { id: "console",   label: "Run console",     path: "/sessions",   icon: '<polyline points="4 17 10 11 4 5"/><line x1="12" y1="19" x2="20" y2="19"/>' },
  { id: "targets",   label: "Targets",         path: "/targets",    icon: '<circle cx="12" cy="12" r="10"/><circle cx="12" cy="12" r="6"/><circle cx="12" cy="12" r="2"/>' },
];

interface NavProps {
  scope?: string;
  profile?: string;
}

export function Navigation({ scope, profile }: NavProps) {
  const location = useLocation();
  const navigate = useNavigate();

  const isActive = (path: string) => {
    if (path === "/sessions") return location.pathname.startsWith("/sessions") || location.pathname.startsWith("/runs");
    return location.pathname === path || location.pathname.startsWith(path + "/");
  };

  return (
    <aside className="ws-rail">
      {/* Brand */}
      <div className="ws-brand">
        <img src="/assets/logo-mark.svg" width="26" height="30" alt="" />
        <div>
          <div className="ws-brand-name"><b>WISPER</b> <span>ALPHA</span></div>
          <div className="ws-brand-tag">Silent guardian</div>
        </div>
      </div>

      {/* Nav */}
      <nav style={{ display: "flex", flexDirection: "column", gap: 2 }}>
        {NAV.map(({ id, label, path, icon }) => (
          <button
            key={id}
            className={`ws-nav-item ${isActive(path) ? "active" : ""}`}
            onClick={() => navigate(path)}
          >
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" dangerouslySetInnerHTML={{ __html: icon }} />
            <span>{label}</span>
          </button>
        ))}
      </nav>

      {/* Scope widget */}
      <div className="ws-scope">
        <div className="ws-scope-lbl">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round">
            <rect x="3" y="11" width="18" height="11" rx="2"/>
            <path d="M7 11V7a5 5 0 0 1 10 0v4"/>
          </svg>
          {scope ? "Scope · locked" : "No scope selected"}
        </div>
        <div className="ws-scope-val">{scope ?? "—"}</div>
        <div className="ws-scope-prof">{profile ?? "select a session"}</div>
      </div>
    </aside>
  );
}
