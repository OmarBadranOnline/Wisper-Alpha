import { useEffect, useState } from "react";
import { useNavigate, useSearchParams } from "react-router-dom";
import { Button } from "../components/ui/Button";
import { Chip, statusChip } from "../components/ui/Chip";
import { Modal } from "../components/ui/Modal";
import { ErrorAlert } from "../components/ui/ErrorAlert";
import { PageLoader } from "../components/ui/LoadingSpinner";
import { sessionApi } from "../services/sessionApi";
import { targetApi } from "../services/targetApi";
import { runApi } from "../services/runApi";
import { Session, SessionCreate, Target } from "../types/api";

export function SessionsPage() {
  const [sessions, setSessions] = useState<Session[]>([]);
  const [total, setTotal] = useState(0);
  const [targets, setTargets] = useState<Target[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const [searchParams] = useSearchParams();
  const targetFilter = searchParams.get("target_id") ?? undefined;
  const navigate = useNavigate();

  const load = () => {
    setLoading(true);
    Promise.all([sessionApi.list(targetFilter), targetApi.list()])
      .then(([s, t]) => { setSessions(s.items); setTotal(s.total); setTargets(t.items); })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  };
  useEffect(load, [targetFilter]);

  const handleStartRun = async (e: React.MouseEvent, sessionId: string) => {
    e.stopPropagation();
    try { const r = await runApi.start(sessionId); navigate(`/runs/${r.id}`); }
    catch (ex: unknown) { setError((ex as Error).message); }
  };

  const targetName = (tid: string) => targets.find(t => t.id === tid)?.name ?? tid.slice(0, 8) + "…";

  if (loading) return <PageLoader />;

  return (
    <div>
      <header className="ws-page-hd">
        <div>
          <div className="ws-crumb">{targetFilter ? `Targets · ${targetName(targetFilter)}` : "Sessions"}</div>
          <h1 className="ws-h2">{total} recon {total === 1 ? "session" : "sessions"}</h1>
        </div>
        <div className="ws-hd-actions">
          {targetFilter && (
            <Button kind="ghost" size="sm" onClick={() => navigate("/sessions")}>All sessions</Button>
          )}
          <Button kind="primary" onClick={() => setShowCreate(true)}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            New session
          </Button>
        </div>
      </header>

      {error && <div style={{ marginBottom: 16 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}

      <section className="ws-panel" style={{ padding: 0, overflow: "hidden" }}>
        {sessions.length === 0 ? (
          <div className="ws-empty">No sessions yet. Create a session to lock scope for a target.</div>
        ) : (
          <table className="ws-table">
            <thead>
              <tr>
                <th>Name</th><th>Target</th><th>Profile</th><th>Scope</th><th>Status</th><th>Created</th><th />
              </tr>
            </thead>
            <tbody>
              {sessions.map(s => (
                <tr key={s.id} style={{ cursor: "pointer" }} onClick={() => navigate(`/sessions/${s.id}`)}>
                  <td style={{ fontWeight: 600 }}>
                    {s.name ?? <span className="ws-mono" style={{ color: "var(--fg3)" }}>{s.id.slice(0, 8)}…</span>}
                  </td>
                  <td style={{ color: "var(--brand-cyan-600)", fontWeight: 600 }}>{targetName(s.target_id)}</td>
                  <td><Chip kind={s.profile === "advanced" ? "warning" : "info"} mono>{s.profile}</Chip></td>
                  <td>
                    {s.scope_locked
                      ? <Chip kind="success" dot>LOCKED</Chip>
                      : <Chip kind="neutral" dot>OPEN</Chip>}
                  </td>
                  <td>{statusChip(s.status)}</td>
                  <td><span style={{ color: "var(--fg3)", fontSize: 12 }}>{new Date(s.created_at).toLocaleDateString()}</span></td>
                  <td onClick={e => e.stopPropagation()}>
                    <Button kind="accent" size="sm" onClick={e => handleStartRun(e, s.id)}>
                      <svg width="11" height="11" viewBox="0 0 24 24" fill="currentColor"><polygon points="6 3 20 12 6 21 6 3"/></svg>
                      Start recon
                    </Button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      {showCreate && (
        <CreateSessionModal targets={targets} defaultTargetId={targetFilter}
          onClose={() => setShowCreate(false)} onCreated={() => { setShowCreate(false); load(); }} />
      )}
    </div>
  );
}

function CreateSessionModal({ targets, defaultTargetId, onClose, onCreated }: {
  targets: Target[]; defaultTargetId?: string; onClose: () => void; onCreated: () => void;
}) {
  const [form, setForm] = useState<SessionCreate>({
    target_id: defaultTargetId ?? targets[0]?.id ?? "",
    name: "", profile: "core", scope_definition: {},
  });
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    if (!form.target_id) { setError("Select a target"); return; }
    setSaving(true);
    try { await sessionApi.create({ ...form, name: form.name || undefined }); onCreated(); }
    catch (e: unknown) { setError((e as Error).message); setSaving(false); }
  };

  const profiles = [
    { value: "core",     label: "Core",     desc: "Fast baseline" },
    { value: "advanced", label: "Advanced", desc: "Deeper enrichment" },
  ] as const;

  return (
    <Modal title="New session" onClose={onClose}>
      {error && <div style={{ marginBottom: 12 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}
      <div className="ws-field">
        <label>Target *</label>
        <select className="ws-select" value={form.target_id}
          onChange={e => setForm(f => ({ ...f, target_id: e.target.value }))}>
          {targets.length === 0 && <option value="">No targets — create one first</option>}
          {targets.map(t => <option key={t.id} value={t.id}>{t.name} ({t.primary_domain})</option>)}
        </select>
      </div>
      <div className="ws-field">
        <label>Session name</label>
        <input className="ws-input" placeholder="q2-baseline-scan" value={form.name}
          onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
      </div>
      <div className="ws-field">
        <label>Recon profile</label>
        <div className="ws-prof-grid">
          {profiles.map(p => (
            <button key={p.value} className={`ws-prof ${form.profile === p.value ? "sel" : ""}`}
              onClick={() => setForm(f => ({ ...f, profile: p.value }))}>
              <div className="ws-h5" style={{ fontSize: 14 }}>{p.label}</div>
              <div className="ws-small" style={{ color: "var(--fg3)", marginTop: 2 }}>{p.desc}</div>
            </button>
          ))}
        </div>
      </div>
      <div style={{ display: "flex", gap: 8, justifyContent: "flex-end", paddingTop: 4 }}>
        <Button kind="ghost" onClick={onClose}>Cancel</Button>
        <Button kind="accent" loading={saving} disabled={targets.length === 0} onClick={submit}>
          <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><rect x="3" y="11" width="18" height="11" rx="2"/><path d="M7 11V7a5 5 0 0 1 10 0v4"/></svg>
          Lock scope & start
        </Button>
      </div>
    </Modal>
  );
}
