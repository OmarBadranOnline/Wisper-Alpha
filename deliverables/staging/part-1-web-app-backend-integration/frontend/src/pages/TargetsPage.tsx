import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { Button } from "../components/ui/Button";
import { Chip, statusChip } from "../components/ui/Chip";
import { Modal } from "../components/ui/Modal";
import { ErrorAlert } from "../components/ui/ErrorAlert";
import { PageLoader } from "../components/ui/LoadingSpinner";
import { targetApi } from "../services/targetApi";
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
    <div>
      <header className="ws-page-hd">
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

      <section className="ws-panel" style={{ padding: 0, overflow: "hidden" }}>
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
        <CreateTargetModal onClose={() => setShowCreate(false)} onCreated={() => { setShowCreate(false); load(); }} />
      )}
    </div>
  );
}

function CreateTargetModal({ onClose, onCreated }: { onClose: () => void; onCreated: () => void }) {
  const [form, setForm] = useState<TargetCreate>({ name: "", primary_domain: "", tags: [], owner: "" });
  const [tagInput, setTagInput] = useState("");
  const [saving, setSaving] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const addTag = () => {
    const t = tagInput.trim();
    if (t && !form.tags!.includes(t)) setForm(f => ({ ...f, tags: [...(f.tags ?? []), t] }));
    setTagInput("");
  };

  const submit = async () => {
    if (!form.name || !form.primary_domain) { setError("Name and domain are required"); return; }
    setSaving(true);
    try { await targetApi.create({ ...form, owner: form.owner || undefined }); onCreated(); }
    catch (e: unknown) { setError((e as Error).message); setSaving(false); }
  };

  return (
    <Modal title="New target" onClose={onClose}>
      {error && <div style={{ marginBottom: 12 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}
      <div className="ws-field">
        <label>Name *</label>
        <input className="ws-input" placeholder="ACME Corp" value={form.name}
          onChange={e => setForm(f => ({ ...f, name: e.target.value }))} />
      </div>
      <div className="ws-field">
        <label>Primary domain *</label>
        <input className="ws-input" placeholder="acme.com" style={{ fontFamily: "var(--font-mono)" }}
          value={form.primary_domain}
          onChange={e => setForm(f => ({ ...f, primary_domain: e.target.value.toLowerCase().trim() }))} />
      </div>
      <div className="ws-field">
        <label>Owner</label>
        <input className="ws-input" placeholder="alice" value={form.owner}
          onChange={e => setForm(f => ({ ...f, owner: e.target.value }))} />
      </div>
      <div className="ws-field">
        <label>Tags</label>
        <div style={{ display: "flex", gap: 8 }}>
          <input className="ws-input" placeholder="bug-bounty" value={tagInput}
            onChange={e => setTagInput(e.target.value)}
            onKeyDown={e => e.key === "Enter" && (e.preventDefault(), addTag())}
            style={{ flex: 1 }} />
          <Button kind="secondary" size="sm" onClick={addTag}>Add</Button>
        </div>
        <div className="ws-tag-row">
          {(form.tags ?? []).map(tag => (
            <span key={tag} className="ws-tag-item"
              onClick={() => setForm(f => ({ ...f, tags: f.tags!.filter(t => t !== tag) }))}>
              {tag} ✕
            </span>
          ))}
        </div>
      </div>
      <div style={{ display: "flex", gap: 8, justifyContent: "flex-end", paddingTop: 4 }}>
        <Button kind="ghost" onClick={onClose}>Cancel</Button>
        <Button kind="primary" loading={saving} onClick={submit}>Create target</Button>
      </div>
    </Modal>
  );
}
