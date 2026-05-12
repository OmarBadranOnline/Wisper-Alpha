import { createContext, useContext, useState } from "react";
import { Outlet } from "react-router-dom";
import { Navigation } from "./Navigation";

interface ScopeCtx { scope: string; profile: string; setScope: (s: string, p: string) => void }
const ScopeContext = createContext<ScopeCtx>({ scope: "", profile: "", setScope: () => {} });
export const useScopeContext = () => useContext(ScopeContext);

export function Layout() {
  const [scope, setScope] = useState("");
  const [profile, setProfile] = useState("");

  return (
    <ScopeContext.Provider value={{ scope, profile, setScope: (s, p) => { setScope(s); setProfile(p); } }}>
      <div className="ws-shell">
        <Navigation scope={scope || undefined} profile={profile || undefined} />
        <div style={{ overflowY: "auto", minHeight: "100vh" }}>
          <div className="ws-main">
            <Outlet />
          </div>
        </div>
      </div>
    </ScopeContext.Provider>
  );
}
