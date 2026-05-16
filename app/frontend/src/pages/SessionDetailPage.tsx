import { useEffect, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import { Button } from "../components/ui/Button";
import { Chip, statusChip } from "../components/ui/Chip";
import { ErrorAlert } from "../components/ui/ErrorAlert";
import { PageLoader } from "../components/ui/LoadingSpinner";
import { sessionApi } from "../services/sessionApi";
import { targetApi } from "../services/targetApi";
import { runApi } from "../services/runApi";
import { useScopeContext } from "../components/layout/Layout";
import { Run, Session, Target } from "../types/api";

export function SessionDetailPage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const { setScope } = useScopeContext();
  const [session, setSession] = useState<Session | null>(null);
  const [target, setTarget] = useState<Target | null>(null);
  const [runs, setRuns] = useState<Run[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [locking, setLocking] = useState(false);
  const [starting, setStarting] = useState(false);

  const load = () => {
    if (!id) return;
    setLoading(true);
    sessionApi.get(id).then(async s => {
      setSession(s);
      const [t, r] = await Promise.all([targetApi.get(s.target_id), runApi.list(id)]);
      setTarget(t);
      setRuns(r.items);
      if (s.scope_locked) setScope(t.primary_domain, s.profile);
    }).catch(e => setError(e.message)).finally(() => setLoading(false));
  };
  useEffect(load, [id]);

  const handleLock = async () => {
    if (!id) return;
    setLocking(true);
    try {
      const updated = await sessionApi.lockScope(id);
      setSession(updated);
      if (target) setScope(target.primary_domain, updated.profile);
    } catch (e: unknown) { setError((e as Error).message); }
    finally { setLocking(false); }
  };

  const handleStartRun = async () => {
    if (!id) return;
    setStarting(true);
    try { const r = await runApi.start(id); navigate(`/runs/${r.id}`); }
    catch (e: unknown) { setError((e as Error).message); setStarting(false); }
  };

  if (loading) return <PageLoader />;
  if (!session) return <ErrorAlert message="Session not found" />;

  return (
    <div>
      <header className="ws-page-hd">
        <div>
          <div className="ws-crumb">
            <span style={{ cursor: "pointer", color: "var(--brand-cyan-600)" }} onClick={() => navigate("/sessions")}>Sessions</span>
            {" · "}
            {target?.name}
          </div>
          <h1 className="ws-h2">{session.name ?? session.id.slice(0, 8)}</h1>
        </div>
        <div className="ws-hd-actions">
          {!session.scope_locked && (
            <Button kind="secondary" loading={locking} onClick={handleLock}>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
              Lock scope
            </Button>
          )}
          <Button kind="accent" loading={starting} onClick={handleStartRun}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="currentColor"><polygon points="6 3 20 12 6 21 6 3"/></svg>
            Start recon
          </Button>
        </div>
      </header>

      {error && <div style={{ marginBottom: 16 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}

      {/* Session meta */}
      <section className="ws-panel">
        <div style={{ display: "grid", gridTemplateColumns: "repeat(3,1fr)", gap: 20 }}>
          <Detail label="Target">{target?.name ?? "—"}</Detail>
          <Detail label="Domain"><span className="ws-mono" style={{ color: "var(--brand-cyan-600)", fontWeight: 600 }}>{target?.primary_domain ?? "—"}</span></Detail>
          <Detail label="Profile"><Chip kind={session.profile === "advanced" ? "warning" : "info"} mono>{session.profile}</Chip></Detail>
          <Detail label="Scope">{session.scope_locked ? <Chip kind="success" dot>LOCKED</Chip> : <Chip kind="neutral" dot>OPEN — not yet locked</Chip>}</Detail>
          <Detail label="Status">{statusChip(session.status)}</Detail>
          <Detail label="Created"><span style={{ color: "var(--fg3)", fontSize: 12 }}>{new Date(session.created_at).toLocaleString()}</span></Detail>
        </div>
      </section>

      {/* Run history */}
      <section className="ws-panel" style={{ marginTop: 16, padding: 0, overflow: "hidden" }}>
        <div style={{ padding: "14px 18px 0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
          <h3 className="ws-h5">Run history</h3>
          <span className="ws-caps" style={{ color: "var(--fg3)" }}>{runs.length} run{runs.length !== 1 ? "s" : ""}</span>
        </div>
        {runs.length === 0 ? (
          <div className="ws-empty">No runs yet. Click "Start recon" to begin.</div>
        ) : (
          <table className="ws-table" style={{ marginTop: 10 }}>
            <thead>
              <tr><th>Run ID</th><th>Stage</th><th>Status</th><th>Started</th><th>Duration</th><th /></tr>
            </thead>
            <tbody>
              {runs.map(r => (
                <tr key={r.id} style={{ cursor: "pointer" }} onClick={() => navigate(`/runs/${r.id}`)}>
                  <td><span className="ws-mono" style={{ color: "var(--brand-cyan-600)", fontWeight: 600 }}>{r.id.slice(0, 8)}…</span></td>
                  <td><span className="ws-mono">{r.stage}</span></td>
                  <td><Chip kind={r.status === "completed" ? "success" : r.status === "running" ? "cyan" : r.status === "failed" ? "danger" : "neutral"} dot>{r.status}</Chip></td>
                  <td><span style={{ color: "var(--fg3)", fontSize: 12 }}>{r.started_at ? new Date(r.started_at).toLocaleTimeString() : "—"}</span></td>
                  <td><span className="ws-mono" style={{ color: "var(--fg3)" }}>
                    {r.started_at && r.completed_at
                      ? `${Math.round((new Date(r.completed_at).getTime() - new Date(r.started_at).getTime()) / 1000)}s`
                      : r.status === "running" ? "running…" : "—"}
                  </span></td>
                  <td><span style={{ color: "var(--brand-cyan-600)", fontSize: 12 }}>Console →</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>
    </div>
  );
}

function Detail({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <div className="ws-caps" style={{ marginBottom: 6 }}>{label}</div>
      <div>{children}</div>
    </div>
  );
}
