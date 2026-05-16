import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/ui/Button";
import { Chip, statusChip } from "../components/ui/Chip";
import { Modal } from "../components/ui/Modal";
import { ErrorAlert } from "../components/ui/ErrorAlert";
import { PageLoader } from "../components/ui/LoadingSpinner";
import { targetApi } from "../services/targetApi";
import { sessionApi } from "../services/sessionApi";
import { runApi } from "../services/runApi";
import { Target, TargetCreate } from "../types/api";

export function TargetsPage() {
  const [targets, setTargets] = useState<Target[]>([]);
  const [total, setTotal] = useState(0);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [showCreate, setShowCreate] = useState(false);
  const navigate = useNavigate();

  const load = () => {
    setLoading(true);
    targetApi.list().then(d => { setTargets(d.items); setTotal(d.total); })
      .catch(e => setError(e.message)).finally(() => setLoading(false));
  };
  useEffect(load, []);

  const handleDelete = async (id: string, name: string) => {
    if (!confirm(`Delete target "${name}"? This also removes all sessions and runs.`)) return;
    try { await targetApi.delete(id); load(); }
    catch (e: unknown) { setError((e as Error).message); }
  };

  if (loading) return <PageLoader />;

  return (
    <div className="animate-fade-in">
      <header className="ws-page-hd animate-slide-up">
        <div>
          <div className="ws-crumb">Targets</div>
          <h1 className="ws-h2">{total} authorized {total === 1 ? "target" : "targets"}</h1>
        </div>
        <div className="ws-hd-actions">
          <Button kind="primary" onClick={() => setShowCreate(true)}>
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2.5" strokeLinecap="round"><line x1="12" y1="5" x2="12" y2="19"/><line x1="5" y1="12" x2="19" y2="12"/></svg>
            New target
          </Button>
        </div>
      </header>

      {error && <div style={{ marginBottom: 16 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}

      <section className="ws-panel animate-slide-up" style={{ padding: 0, overflow: "hidden", animationDelay: "0.1s" }}>
        {targets.length === 0 ? (
          <div className="ws-empty">No targets yet. Create a target to begin reconnaissance planning.</div>
        ) : (
          <table className="ws-table">
            <thead>
              <tr>
                <th>Name</th><th>Domain</th><th>Tags</th><th>Owner</th><th>Status</th><th>Created</th><th />
              </tr>
            </thead>
            <tbody>
              {targets.map(t => (
                <tr key={t.id} style={{ cursor: "pointer" }} onClick={() => navigate(`/sessions?target_id=${t.id}`)}>
                  <td style={{ fontWeight: 600 }}>{t.name}</td>
                  <td><span className="ws-mono" style={{ color: "var(--brand-cyan-600)", fontWeight: 600 }}>{t.primary_domain}</span></td>
                  <td>
                    <div className="ws-src-chips">
                      {(t.tags ?? []).map(tag => <Chip key={tag} kind="outline" mono>{tag}</Chip>)}
                    </div>
                  </td>
                  <td style={{ color: "var(--fg3)" }}>{t.owner ?? "—"}</td>
                  <td>{statusChip(t.status)}</td>
                  <td><span style={{ color: "var(--fg3)", fontSize: 12 }}>{new Date(t.created_at).toLocaleDateString()}</span></td>
                  <td onClick={e => e.stopPropagation()}>
                    <button onClick={() => handleDelete(t.id, t.name)} style={{ background: "none", border: "none", cursor: "pointer", color: "var(--fg3)", fontSize: 13 }} title="Delete">
                      ✕
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </section>

      {showCreate && (
        <CreateTargetModal
          onClose={() => setShowCreate(false)}
          onCreated={(runId) => {
            setShowCreate(false);
            load();
            if (runId) navigate(`/runs/${runId}`);
          }}
        />
      )}
    </div>
  );
}

function normalizeDomainFromInput(input: string): string {
  const cleaned = input.trim().toLowerCase();
  if (!cleaned) return "";
  const noProtocol = cleaned.replace(/^https?:\/\//, "");
  return noProtocol.split("/")[0].split("?")[0].split("#")[0].split(":")[0].replace(/\.$/, "");
}

function domainToName(domain: string): string {
  const first = domain.split(".")[0] || "target";
  return first
    .split(/[-_]+/)
    .filter(Boolean)
    .map((word) => word.charAt(0).toUpperCase() + word.slice(1))
    .join(" ");
}

function CreateTargetModal({ onClose, onCreated }: { onClose: () => void; onCreated: (runId?: string) => void }) {
  const [targetUrl, setTargetUrl] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const submit = async () => {
    const domain = normalizeDomainFromInput(targetUrl);
    if (!domain || !/^[a-z0-9]([a-z0-9\-.]*[a-z0-9])?$/.test(domain)) {
      setError("Please enter a valid URL or domain");
      return;
    }
    setSaving(true);
    try {
      const payload: TargetCreate = {
        name: domainToName(domain),
        primary_domain: domain,
        tags: ["auto-onboarded"],
      };
      const target = await targetApi.create(payload);
      const session = await sessionApi.create({
        target_id: target.id,
        name: `${domain}-baseline`,
        profile: "core",
        scope_definition: { source: "quick-target-form", input: targetUrl.trim() },
      });
      const run = await runApi.start(session.id);
      onCreated(run.id);
    }
    catch (e: unknown) { setError((e as Error).message); setSaving(false); }
  };

  return (
    <Modal title="Quick target onboarding" onClose={onClose}>
      {error && <div style={{ marginBottom: 12 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}
      <div className="ws-field">
        <label>Target URL *</label>
        <input
          className="ws-input"
          placeholder="https://example.com"
          value={targetUrl}
          onChange={e => setTargetUrl(e.target.value)}
          onKeyDown={e => e.key === "Enter" && (e.preventDefault(), submit())}
          style={{ fontFamily: "var(--font-mono)" }}
        />
      </div>
      <div className="ws-guide-note">
        <strong>What happens next:</strong> create target → create core session → start recon run → open live run console.
      </div>
      <div style={{ display: "flex", gap: 8, justifyContent: "flex-end", paddingTop: 4 }}>
        <Button kind="ghost" onClick={onClose}>Cancel</Button>
        <Button kind="primary" loading={saving} onClick={submit}>Start reconnaissance</Button>
      </div>
    </Modal>
  );
}
