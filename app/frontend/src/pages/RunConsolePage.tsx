import { useCallback, useEffect, useRef, useState } from "react";
import { useNavigate, useParams } from "react-router-dom";
import clsx from "clsx";
import { Button } from "../components/ui/Button";
import { Chip } from "../components/ui/Chip";
import { ErrorAlert } from "../components/ui/ErrorAlert";
import { PageLoader } from "../components/ui/LoadingSpinner";
import { runApi } from "../services/runApi";
import { Run, RunLogEntry, RunStatus } from "../types/api";

const TERMINAL_STATUSES: RunStatus[] = ["completed", "failed", "cancelled"];

const STAGE_DEFS = [
  { key: "subdomain_discovery", label: "Subdomain discovery", tools: ["subfinder", "amass"] },
  { key: "dns_enrichment",      label: "DNS enrichment",      tools: ["dig", "dnsrecon"] },
  { key: "certificate_scan",    label: "Certificate scan",    tools: ["crt.sh"] },
  { key: "historical_urls",     label: "Historical URLs",     tools: ["wayback"] },
  { key: "normalization",       label: "Normalize + score",   tools: ["engine"] },
];

const STAGE_ORDER = ["queued", "subdomain_discovery", "dns_enrichment", "certificate_scan", "historical_urls", "metadata_collection", "normalization", "completed"];

function fmt(secs: number) {
  const m = Math.floor(secs / 60);
  const s = String(Math.floor(secs % 60)).padStart(2, "0");
  return `${String(m).padStart(2, "0")}:${s}`;
}

export function RunConsolePage() {
  const { id } = useParams<{ id: string }>();
  const navigate = useNavigate();
  const [run, setRun] = useState<Run | null>(null);
  const [logs, setLogs] = useState<RunLogEntry[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [cancelling, setCancelling] = useState(false);
  const [elapsed, setElapsed] = useState(0);
  const logRef = useRef<HTMLDivElement>(null);
  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const fetchState = useCallback(async () => {
    if (!id) return;
    const [runData, logData] = await Promise.all([runApi.get(id), runApi.logs(id)]);
    setRun(runData);
    setLogs(logData.logs);
    return runData.status;
  }, [id]);

  useEffect(() => {
    if (!id) return;
    fetchState()
      .then(status => {
        setLoading(false);
        if (status && !TERMINAL_STATUSES.includes(status as RunStatus)) {
          pollingRef.current = setInterval(async () => {
            const s = await fetchState().catch(() => undefined);
            if (s && TERMINAL_STATUSES.includes(s as RunStatus)) stopPolling();
          }, 2000);
          timerRef.current = setInterval(() => setElapsed(e => e + 1), 1000);
        }
      })
      .catch(e => { setError(e.message); setLoading(false); });

    return () => { stopPolling(); };
  }, [id]);

  useEffect(() => {
    if (logRef.current) logRef.current.scrollTop = logRef.current.scrollHeight;
  }, [logs]);

  const stopPolling = () => {
    if (pollingRef.current) { clearInterval(pollingRef.current); pollingRef.current = null; }
    if (timerRef.current) { clearInterval(timerRef.current); timerRef.current = null; }
  };

  const handleCancel = async () => {
    if (!id) return;
    setCancelling(true);
    stopPolling();
    try { const r = await runApi.cancel(id); setRun(r); await fetchState(); }
    catch (e: unknown) { setError((e as Error).message); }
    finally { setCancelling(false); }
  };

  if (loading) return <PageLoader />;
  if (!run) return <ErrorAlert message="Run not found" />;

  const isTerminal = TERMINAL_STATUSES.includes(run.status);
  const currentStageIdx = STAGE_ORDER.indexOf(run.stage);

  return (
    <div className="animate-fade-in">
      <header className="ws-page-hd animate-slide-up">
        <div>
          <div className="ws-crumb">
            <span style={{ cursor: "pointer", color: "var(--brand-cyan-600)" }} onClick={() => navigate(-1)}>← Back</span>
            {" · Run console · "}
            <span className="ws-mono">{run.id.slice(0, 8)}</span>
          </div>
          <h1 className="ws-h2">Passive recon pipeline</h1>
        </div>
        <div className="ws-hd-actions">
          {!isTerminal && (
            <Button kind="danger" loading={cancelling} onClick={handleCancel}>
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2"><circle cx="12" cy="12" r="10"/><rect x="9" y="9" width="6" height="6"/></svg>
              Stop run
            </Button>
          )}
          <Chip kind={run.status === "completed" ? "success" : run.status === "running" ? "cyan" : run.status === "failed" ? "danger" : "neutral"} dot>
            {run.status}
          </Chip>
          {!isTerminal && (
            <span className="ws-mono" style={{ color: "var(--fg3)", fontSize: 12 }}>elapsed {fmt(elapsed)}</span>
          )}
        </div>
      </header>

      {error && <div style={{ marginBottom: 16 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}

      {/* Stages */}
      <div className="ws-stages">
        {STAGE_DEFS.map(({ key, label, tools }, i) => {
          const stageIdx = STAGE_ORDER.indexOf(key);
          const done = stageIdx < currentStageIdx || run.status === "completed";
          const current = run.stage === key && run.status === "running";
          return (
            <div key={key} className={clsx("ws-stage", done && "done", current && "current")}>
              <div className="ws-stage-dot">
                {done
                  ? <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round"><polyline points="20 6 9 17 4 12"/></svg>
                  : current
                    ? <span className="ws-stage-pulse" />
                    : <span style={{ fontSize: 11, fontWeight: 600, color: "var(--slate-500)" }}>{i + 1}</span>
                }
              </div>
              <div>
                <div className="ws-stage-name">{label}</div>
                <div className="ws-stage-tools">
                  {tools.map(t => <Chip key={t} kind="neutral" mono>{t}</Chip>)}
                </div>
              </div>
            </div>
          );
        })}
      </div>

      {/* Console */}
      <section className="ws-console-wrap animate-slide-up" style={{ animationDelay: "0.2s" }}>
        <div className="ws-console-hd">
          <span className="ws-console-hd-lbl">Adapter log · {logs.length} lines</span>
          <span className="ws-mono" style={{ color: "var(--brand-cyan-400)", fontSize: 12 }}>
            {run.started_at && run.completed_at
              ? `completed in ${Math.round((new Date(run.completed_at).getTime() - new Date(run.started_at).getTime()) / 1000)}s`
              : run.status === "running" ? `elapsed ${fmt(elapsed)}` : run.status}
          </span>
        </div>
        <div className="ws-console" ref={logRef}>
          {logs.length === 0
            ? <span style={{ color: "#6B7F9C" }}>Waiting for adapter output…</span>
            : logs.map((entry, i) => {
                const t = new Date(entry.timestamp);
                const ts = `${String(t.getHours()).padStart(2, "0")}:${String(t.getMinutes()).padStart(2, "0")}:${String(t.getSeconds()).padStart(2, "0")}`;
                const lvlClass = entry.level === "warn" ? "warn" : entry.level === "error" ? "err" : "ok";
                return (
                  <div key={i} className="ws-console-row">
                    <span className="ws-console-t">{ts}</span>
                    <span className="ws-console-tag">[{entry.stage.replace(/_/g, "-")}]</span>
                    <span className={`ws-console-msg ${lvlClass}`}>{entry.message}</span>
                  </div>
                );
              })
          }
          {!isTerminal && (
            <div className="ws-console-row">
              <span className="ws-console-t" />
              <span className="ws-console-tag">[{run.stage}]</span>
              <span className="ws-console-msg"><span className="ws-caret" /></span>
            </div>
          )}
        </div>
      </section>

      {run.error && (
        <div style={{ marginTop: 12 }}><ErrorAlert message={`Adapter error: ${run.error}`} /></div>
      )}
    </div>
  );
}
