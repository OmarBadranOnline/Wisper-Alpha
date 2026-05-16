import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { targetApi } from "../services/targetApi";
import { sessionApi } from "../services/sessionApi";
import { runApi } from "../services/runApi";
import { Target, ReconProfile } from "../types/api";
import { Button } from "../components/ui/Button";
import { ErrorAlert } from "../components/ui/ErrorAlert";
import { PageLoader } from "../components/ui/LoadingSpinner";
import { useScopeContext } from "../components/layout/Layout";

export function NewScanPage() {
  const navigate = useNavigate();
  const { setScope } = useScopeContext();
  
  const [step, setStep] = useState<1 | 2 | 3>(1);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  // Targets state
  const [targets, setTargets] = useState<Target[]>([]);
  const [loadingTargets, setLoadingTargets] = useState(true);
  
  // Wizard state
  const [selectedTargetId, setSelectedTargetId] = useState<string>("");
  const [newTargetUrl, setNewTargetUrl] = useState("");
  const [isCreatingTarget, setIsCreatingTarget] = useState(false);
  
  const [sessionName, setSessionName] = useState("");
  const [profile, setProfile] = useState<ReconProfile>("core");

  useEffect(() => {
    targetApi.list(0, 100).then(res => {
      setTargets(res.items);
      setLoadingTargets(false);
    }).catch(err => {
      setError(err.message);
      setLoadingTargets(false);
    });
  }, []);

  const handleNextStep1 = async () => {
    setError(null);
    if (isCreatingTarget) {
      if (!newTargetUrl) { setError("Please provide a target URL or domain."); return; }
      setStep(2);
    } else {
      if (!selectedTargetId) { setError("Please select an existing target."); return; }
      setStep(2);
    }
  };

  const handleNextStep2 = () => {
    setError(null);
    if (!sessionName) { setError("Please provide a session name."); return; }
    setStep(3);
  };

  const handleLaunch = async () => {
    setError(null);
    setLoading(true);
    
    try {
      let finalTargetId = selectedTargetId;
      
      // 1. Create target if needed
      if (isCreatingTarget) {
        let domain = newTargetUrl.trim().toLowerCase();
        domain = domain.replace(/^https?:\/\//, "").split("/")[0].split("?")[0].split("#")[0].split(":")[0];
        const name = domain.split(".")[0].charAt(0).toUpperCase() + domain.split(".")[0].slice(1);
        
        const target = await targetApi.create({ name, primary_domain: domain, tags: ["web-gui"] });
        finalTargetId = target.id;
      }
      
      // 2. Create session
      const session = await sessionApi.create({
        target_id: finalTargetId,
        name: sessionName,
        profile,
        scope_definition: { source: "web-wizard", input: newTargetUrl || targets.find(t => t.id === finalTargetId)?.primary_domain }
      });
      
      // 3. Launch run
      const run = await runApi.start(session.id);
      
      // Update global context
      const tInfo = newTargetUrl || targets.find(t => t.id === finalTargetId)?.primary_domain || "Unknown";
      setScope(tInfo, profile);
      
      // Navigate to terminal
      navigate(`/runs/${run.id}`);
      
    } catch (err: any) {
      setError(err.message || "An error occurred starting the scan.");
      setLoading(false);
    }
  };

  if (loadingTargets) return <PageLoader />;

  return (
    <div className="animate-fade-in">
      <header className="ws-page-hd">
        <div>
          <div className="ws-crumb">Wizard</div>
          <h1 className="ws-h2">New Reconnaissance Scan</h1>
        </div>
      </header>

      {error && <div style={{ marginBottom: 24 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}

      <div className="ws-guide animate-slide-up">
        <div className="ws-guide-head">
          <h3 className="ws-h4">Scan Configuration</h3>
          <span className="ws-caps">Step {step} of 3</span>
        </div>
        
        <div style={{ display: "flex", gap: 8, marginBottom: 24 }}>
          {[1, 2, 3].map(i => (
            <div key={i} style={{ flex: 1, height: 4, borderRadius: 2, background: i <= step ? "var(--brand-cyan-500)" : "rgba(255,255,255,0.1)", transition: "background 0.3s ease" }} />
          ))}
        </div>

        {step === 1 && (
          <div className="animate-slide-right">
            <h4 className="ws-h5" style={{ marginBottom: 16 }}>Select Target</h4>
            
            <div className="ws-field" style={{ display: "flex", gap: 16 }}>
              <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer", background: !isCreatingTarget ? "rgba(74,175,217,0.1)" : "transparent", padding: "12px 16px", borderRadius: 8, border: `1px solid ${!isCreatingTarget ? "var(--brand-cyan-400)" : "var(--border-default)"}`, flex: 1 }}>
                <input type="radio" checked={!isCreatingTarget} onChange={() => setIsCreatingTarget(false)} />
                <span className="ws-body">Existing Target</span>
              </label>
              <label style={{ display: "flex", alignItems: "center", gap: 8, cursor: "pointer", background: isCreatingTarget ? "rgba(74,175,217,0.1)" : "transparent", padding: "12px 16px", borderRadius: 8, border: `1px solid ${isCreatingTarget ? "var(--brand-cyan-400)" : "var(--border-default)"}`, flex: 1 }}>
                <input type="radio" checked={isCreatingTarget} onChange={() => setIsCreatingTarget(true)} />
                <span className="ws-body">New Target</span>
              </label>
            </div>

            {isCreatingTarget ? (
              <div className="ws-field">
                <label>Target URL or Domain *</label>
                <input className="ws-input" placeholder="example.com" value={newTargetUrl} onChange={e => setNewTargetUrl(e.target.value)} />
              </div>
            ) : (
              <div className="ws-field">
                <label>Select Target *</label>
                <select className="ws-select" value={selectedTargetId} onChange={e => setSelectedTargetId(e.target.value)}>
                  <option value="" disabled>Select a target...</option>
                  {targets.map(t => <option key={t.id} value={t.id}>{t.name} ({t.primary_domain})</option>)}
                </select>
              </div>
            )}

            <div style={{ display: "flex", justifyContent: "flex-end", marginTop: 32 }}>
              <Button kind="primary" onClick={handleNextStep1}>Continue →</Button>
            </div>
          </div>
        )}

        {step === 2 && (
          <div className="animate-slide-right">
            <h4 className="ws-h5" style={{ marginBottom: 16 }}>Session Profile</h4>
            
            <div className="ws-field">
              <label>Session Name *</label>
              <input className="ws-input" placeholder="e.g. Q3 External Baseline" value={sessionName} onChange={e => setSessionName(e.target.value)} />
            </div>

            <div className="ws-field" style={{ marginTop: 24 }}>
              <label>Reconnaissance Profile *</label>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16 }}>
                <div onClick={() => setProfile("core")} style={{ cursor: "pointer", padding: 20, borderRadius: 12, border: `1px solid ${profile === "core" ? "var(--brand-cyan-500)" : "var(--border-default)"}`, background: profile === "core" ? "rgba(74,175,217,0.1)" : "rgba(0,0,0,0.2)" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
                    <span className="ws-h5" style={{ color: profile === "core" ? "var(--brand-cyan-400)" : "var(--white)" }}>Core Passive</span>
                    {profile === "core" && <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--brand-cyan-400)" strokeWidth="2"><polyline points="20 6 9 17 4 12"/></svg>}
                  </div>
                  <p className="ws-small" style={{ margin: 0 }}>Subdomain enumeration, DNS resolution, and live host discovery. Safe and fast.</p>
                </div>
                
                <div onClick={() => setProfile("advanced")} style={{ cursor: "pointer", padding: 20, borderRadius: 12, border: `1px solid ${profile === "advanced" ? "var(--brand-cyan-500)" : "var(--border-default)"}`, background: profile === "advanced" ? "rgba(74,175,217,0.1)" : "rgba(0,0,0,0.2)" }}>
                  <div style={{ display: "flex", justifyContent: "space-between", marginBottom: 8 }}>
                    <span className="ws-h5" style={{ color: profile === "advanced" ? "var(--brand-cyan-400)" : "var(--white)" }}>Advanced Active</span>
                    {profile === "advanced" && <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="var(--brand-cyan-400)" strokeWidth="2"><polyline points="20 6 9 17 4 12"/></svg>}
                  </div>
                  <p className="ws-small" style={{ margin: 0 }}>Includes vulnerability scanning, port scanning, and deeper enumeration. Slower, leaves traces.</p>
                </div>
              </div>
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 32 }}>
              <Button kind="ghost" onClick={() => setStep(1)}>← Back</Button>
              <Button kind="primary" onClick={handleNextStep2}>Review Setup →</Button>
            </div>
          </div>
        )}

        {step === 3 && (
          <div className="animate-slide-right">
            <h4 className="ws-h5" style={{ marginBottom: 16 }}>Review & Launch</h4>
            
            <div className="ws-panel ws-glass" style={{ marginBottom: 24 }}>
              <div style={{ display: "grid", gridTemplateColumns: "1fr 1fr", gap: 24 }}>
                <div>
                  <span className="ws-caps">Target</span>
                  <div className="ws-h4" style={{ marginTop: 8 }}>{isCreatingTarget ? newTargetUrl : targets.find(t => t.id === selectedTargetId)?.primary_domain}</div>
                </div>
                <div>
                  <span className="ws-caps">Profile</span>
                  <div className="ws-h4" style={{ marginTop: 8, color: "var(--brand-cyan-400)", textTransform: "capitalize" }}>{profile}</div>
                </div>
                <div style={{ gridColumn: "1 / -1" }}>
                  <span className="ws-caps">Session Name</span>
                  <div className="ws-body" style={{ marginTop: 8 }}>{sessionName}</div>
                </div>
              </div>
            </div>

            <div className="ws-guide-note">
              <span style={{ color: "var(--brand-cyan-400)", fontWeight: 600 }}>Note:</span> Launching this scan will initialize a new background process orchestrated by the Wisper CLI engine. You will be redirected to the live terminal console.
            </div>

            <div style={{ display: "flex", justifyContent: "space-between", marginTop: 32 }}>
              <Button kind="ghost" onClick={() => setStep(2)}>← Back</Button>
              <Button kind="accent" loading={loading} onClick={handleLaunch}>
                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><polygon points="5 3 19 12 5 21 5 3"/></svg>
                Initialize Orchestrator
              </Button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}
