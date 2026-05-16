import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { Button } from "../components/ui/Button";
import { Chip, ConfidencePill, SeverityChip } from "../components/ui/Chip";
import { ErrorAlert } from "../components/ui/ErrorAlert";
import { PageLoader } from "../components/ui/LoadingSpinner";
import { runApi } from "../services/runApi";
import { sessionApi } from "../services/sessionApi";
import { targetApi } from "../services/targetApi";
import { Run, RunLogEntry, RunStatus } from "../types/api";

const TERMINAL_STATUSES: RunStatus[] = ["completed", "failed", "cancelled"];

const STAGES = [
  { key: "subdomain_discovery", label: "Subdomain discovery", tools: ["subfinder", "amass"] },
  { key: "dns_enrichment", label: "DNS enrichment", tools: ["dig", "dnsrecon"] },
  { key: "certificate_scan", label: "Certificate scan", tools: ["crt.sh"] },
  { key: "historical_urls", label: "Historical URLs", tools: ["waybackurls"] },
  { key: "metadata_collection", label: "Metadata collection", tools: ["theHarvester", "whatweb"] },
  { key: "normalization", label: "Normalize + score", tools: ["engine"] },
] as const;

const SOURCES = [
  ["subfinder", 184, 0.92],
  ["amass", 211, 0.88],
  ["crt.sh", 96, 0.74],
  ["shodan", 27, 0.62],
  ["censys", 41, 0.58],
  ["wayback", 1120, 0.45],
] as const;

const SAMPLE_TARGET = "http://testhtml5.vulnweb.com";
const SAMPLE_STACK = ["nginx", "Python", "Flask", "CouchDB"] as const;
const SAMPLE_LOGS: RunLogEntry[] = [
  { timestamp: "2026-05-12T10:40:38.000Z", level: "info", stage: "metadata_collection", message: "[Paste #1 - 68 lines] http://testhtml5.vulnweb.com - nginx, Python, Flask, CouchDB" },
  { timestamp: "2026-05-12T10:40:38.250Z", level: "info", stage: "normalization", message: "Stack profile recorded from sample output" },
  { timestamp: "2026-05-12T10:40:38.500Z", level: "warn", stage: "normalization", message: "Flask and CouchDB increase investigation priority" },
];

const FINDINGS = [
  { sev: "Critical", title: "Shadow admin surface exposed", detail: "Passive enumeration surfaced an admin-like endpoint", conf: 96 },
  { sev: "High", title: "Certificate SAN sprawl", detail: "crt.sh revealed extra hostnames in certificate SANs", conf: 84 },
  { sev: "Medium", title: "Archived endpoint still reachable", detail: "Wayback data kept a legacy path visible", conf: 67 },
  { sev: "Low", title: "Technology fingerprint leakage", detail: "Headers expose stack details that aid targeting", conf: 44 },
] as const;

function shortId(id: string) {
  return `${id.slice(0, 8)}…`;
}

function formatElapsed(seconds: number) {
  const mins = Math.floor(seconds / 60);
  const secs = String(seconds % 60).padStart(2, "0");
  return `${String(mins).padStart(2, "0")}:${secs}`;
}

function stageIndex(stage: string) {
  return STAGES.findIndex(s => s.key === stage);
}

function statusKind(status: RunStatus) {
  if (status === "completed") return "success";
  if (status === "running") return "cyan";
  if (status === "failed") return "danger";
  return "neutral";
}

function scoreTone(score: number) {
  if (score >= 80) return "danger";
  if (score >= 60) return "warning";
  return "success";
}

function computeElapsed(run: Run) {
  const start = run.started_at ?? run.created_at;
  const end = run.completed_at ?? new Date().toISOString();
  const diff = Math.max(0, Math.round((new Date(end).getTime() - new Date(start).getTime()) / 1000));
  return diff;
}

export function DashboardPage() {
  const [counts, setCounts] = useState({ targets: 0, sessions: 0, runs: 0, running: 0 });
  const [recentRuns, setRecentRuns] = useState<Run[]>([]);
  const [activeRunId, setActiveRunId] = useState<string | null>(null);
  const [activeRun, setActiveRun] = useState<Run | null>(null);
  const [logs, setLogs] = useState<RunLogEntry[]>([]);
  const [visibleLogCount, setVisibleLogCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [runLoading, setRunLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [elapsed, setElapsed] = useState(0);
  const pollingRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const timerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const loadOverview = useCallback(async () => {
    const [targets, sessions, runs] = await Promise.all([targetApi.list(), sessionApi.list(), runApi.list()]);
    const firstRun = runs.items.find(r => r.status === "running") ?? runs.items[0] ?? null;
    setCounts({
      targets: targets.total,
      sessions: sessions.total,
      runs: runs.total,
      running: runs.items.filter(x => x.status === "running").length,
    });
    setRecentRuns(runs.items.slice(0, 6));
    setActiveRunId(prev => prev ?? firstRun?.id ?? null);
  }, []);

  useEffect(() => {
    loadOverview().catch(e => setError(e.message)).finally(() => setLoading(false));
  }, [loadOverview]);

  const loadActiveRun = useCallback(async (runId: string) => {
    const [runData, logData] = await Promise.all([runApi.get(runId), runApi.logs(runId)]);
    return { runData, logs: logData.logs };
  }, []);

  useEffect(() => {
    if (!activeRunId) {
      setActiveRun(null);
      setLogs([]);
      setVisibleLogCount(0);
      setElapsed(0);
      return;
    }

    let cancelled = false;
    const clearTimers = () => {
      if (pollingRef.current) { clearInterval(pollingRef.current); pollingRef.current = null; }
      if (timerRef.current) { clearInterval(timerRef.current); timerRef.current = null; }
    };

    setRunLoading(true);
    clearTimers();

    loadActiveRun(activeRunId)
      .then(({ runData, logs: runLogs }) => {
        if (cancelled) return;
        setActiveRun(runData);
        setLogs(runLogs);
        setVisibleLogCount(0);
        setElapsed(computeElapsed(runData));
        if (runData.status === "running") {
          pollingRef.current = setInterval(async () => {
            try {
              const updated = await loadActiveRun(activeRunId);
              if (cancelled) return;
              setActiveRun(updated.runData);
              setLogs(updated.logs);
              if (TERMINAL_STATUSES.includes(updated.runData.status)) clearTimers();
            } catch {
              // keep the last good state on polling errors
            }
          }, 2000);
          timerRef.current = setInterval(() => setElapsed(v => v + 1), 1000);
        }
      })
      .catch(e => {
        if (!cancelled) setError(e.message);
      })
      .finally(() => {
        if (!cancelled) setRunLoading(false);
      });

    return () => {
      cancelled = true;
      clearTimers();
    };
  }, [activeRunId, loadActiveRun]);

  useEffect(() => {
    if (logs.length === 0) return;
    const id = window.setInterval(() => {
      setVisibleLogCount(curr => {
        if (curr >= logs.length) {
          window.clearInterval(id);
          return curr;
        }
        return curr + 1;
      });
    }, 45);
    return () => window.clearInterval(id);
  }, [logs.length]);

  const visibleLogs = logs.slice(0, visibleLogCount);
  const replayLogs = logs.length > 0 ? visibleLogs : SAMPLE_LOGS;
  const currentStageIndex = activeRun ? stageIndex(activeRun.stage) : -1;
  const progress = activeRun
    ? Math.min(100, Math.max(0, Math.round(((Math.max(currentStageIndex, 0) + 1) / STAGES.length) * 100)))
    : 0;
  const severityCounts = useMemo(() => FINDINGS.reduce<Record<string, number>>((acc, finding) => {
    acc[finding.sev] = (acc[finding.sev] ?? 0) + 1;
    return acc;
  }, {}), []);
  const averageScore = Math.round(FINDINGS.reduce((sum, finding) => sum + finding.conf, 0) / FINDINGS.length);
  const exposureScore = Math.min(100, averageScore + (activeRun?.status === "running" ? 4 : 0) + Math.max(currentStageIndex, 0));

  if (loading) return <PageLoader />;

  return (
    <div className="ws-onepage">
      <header className="ws-page-hd">
        <div>
          <div className="ws-crumb">Mission console</div>
          <h1 className="ws-h2">Single-page recon dashboard</h1>
          <div className="ws-small">Animated terminal replay, live-like process flow, and vulnerability scoring in one screen.</div>
        </div>
        <div className="ws-hd-actions">
          <Chip kind={activeRun ? statusKind(activeRun.status) : "neutral"} dot>
            {activeRun ? activeRun.status : "idle"}
          </Chip>
          <Chip kind="outline" mono>
            {activeRun ? activeRun.stage.replace(/_/g, " ") : "no active run"}
          </Chip>
        </div>
      </header>

      {error && <div style={{ marginBottom: 16 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}

      <section className="ws-panel ws-hero">
        <div className="ws-hero-grid">
          <div>
            <div className="ws-crumb ws-subtle">Live process</div>
            <h2 className="ws-h2" style={{ color: "#fff", marginBottom: 8 }}>Attack surface replay</h2>
            <p className="ws-small ws-subtle" style={{ maxWidth: 720 }}>
              The page stays focused on one workflow: watch the passive recon pipeline progress, review the collected data, and score the resulting exposure.
            </p>

            <div className="ws-hero-cta">
              <Button
                kind="accent"
                onClick={() => {
                  const running = recentRuns.find(r => r.status === "running");
                  setActiveRunId(running?.id ?? recentRuns[0]?.id ?? null);
                }}
                disabled={recentRuns.length === 0}
              >
                Replay latest run
              </Button>
              <Button
                kind="secondary"
                onClick={() => {
                  const running = recentRuns.find(r => r.status === "running");
                  if (running) setActiveRunId(running.id);
                }}
                disabled={!recentRuns.some(r => r.status === "running")}
              >
                Focus live run
              </Button>
            </div>

            <div className="ws-sample-intel">
              <div className="ws-sample-intel-hd">
                <span className="ws-caps" style={{ color: "var(--brand-cyan-400)" }}>Sample intelligence</span>
                <Chip kind="outline" mono>from pasted output</Chip>
              </div>
              <div className="ws-sample-target">{SAMPLE_TARGET}</div>
              <div className="ws-small ws-subtle">nginx + Python + Flask + CouchDB</div>
              <div className="ws-sample-stack">
                {SAMPLE_STACK.map(tool => <Chip key={tool} kind="outline" mono>{tool}</Chip>)}
              </div>
            </div>
          </div>

          <div className="ws-hero-score">
            <div
              className="ws-score-ring"
              style={{ background: `conic-gradient(var(--state-danger) 0 ${exposureScore}%, rgba(255,255,255,0.08) ${exposureScore}% 100%)` }}
            >
              <div className="ws-score-ring-inner">
                <div className="ws-score-label">Exposure score</div>
                <div className="ws-score-num">{exposureScore}</div>
                <div className="ws-score-meta">/ 100</div>
              </div>
            </div>
            <div className="ws-metric-row">
              <Chip kind="danger" dot>Critical {severityCounts.Critical ?? 0}</Chip>
              <Chip kind="warning" dot>High {severityCounts.High ?? 0}</Chip>
              <Chip kind="cyan" dot>Medium {severityCounts.Medium ?? 0}</Chip>
              <Chip kind="success" dot>Low {severityCounts.Low ?? 0}</Chip>
            </div>
            <div className="ws-small ws-subtle">
              {activeRun
                ? `Run ${shortId(activeRun.id)} is ${activeRun.status}; stage ${Math.max(currentStageIndex, 0) + 1} of ${STAGES.length}.`
                : "Awaiting the first run to build the exposure profile."}
            </div>
          </div>
        </div>
      </section>

      <div className="ws-grid-4" style={{ marginTop: 18 }}>
        <div className="ws-stat">
          <div className="ws-stat-lbl">Targets</div>
          <div className="ws-stat-num">{counts.targets}</div>
          <div className="ws-stat-delta">authorized scopes</div>
        </div>
        <div className="ws-stat">
          <div className="ws-stat-lbl">Sessions</div>
          <div className="ws-stat-num">{counts.sessions}</div>
          <div className="ws-stat-delta">recon sessions</div>
        </div>
        <div className="ws-stat">
          <div className="ws-stat-lbl">Runs</div>
          <div className="ws-stat-num">{counts.runs}</div>
          <div className="ws-stat-delta">pipeline executions</div>
        </div>
        <div className="ws-stat">
          <div className="ws-stat-lbl">Active now</div>
          <div className="ws-stat-num">{counts.running}</div>
          <div className={`ws-stat-delta ${counts.running > 0 ? "pos" : ""}`}>{counts.running > 0 ? "runs in progress" : "no active runs"}</div>
        </div>
      </div>

      <section className="ws-panel" style={{ marginTop: 20 }}>
        <header className="ws-panel-hd">
          <h3 className="ws-h5">Animated recon process</h3>
          <span className="ws-caps" style={{ color: "var(--fg3)" }}>
            {activeRun ? `${shortId(activeRun.id)} · ${formatElapsed(elapsed)}` : "waiting for a run"}
          </span>
        </header>
        <div className="ws-stage-grid">
          {STAGES.map((stage, i) => {
            const done = currentStageIndex > i || activeRun?.status === "completed";
            const current = activeRun?.stage === stage.key && activeRun.status === "running";
            return (
              <div key={stage.key} className={`ws-stage ${done ? "done" : ""} ${current ? "current" : ""}`}>
                <div className="ws-stage-dot">
                  {done ? (
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="3" strokeLinecap="round">
                      <polyline points="20 6 9 17 4 12" />
                    </svg>
                  ) : current ? (
                    <span className="ws-stage-pulse" />
                  ) : (
                    <span style={{ fontSize: 11, fontWeight: 600, color: "var(--slate-500)" }}>{i + 1}</span>
                  )}
                </div>
                <div>
                  <div className="ws-stage-name">{stage.label}</div>
                  <div className="ws-stage-tools">
                    {stage.tools.map(tool => <Chip key={tool} kind="neutral" mono>{tool}</Chip>)}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
        <div className="ws-progress">
          <div className="ws-progress-bar" style={{ width: `${progress}%` }} />
        </div>
      </section>

      <div className="ws-console-grid" style={{ marginTop: 20 }}>
        <section className="ws-terminal-shell">
          <div className="ws-console-hd">
            <span className="ws-console-hd-lbl">Terminal replay</span>
            <span className="ws-mono" style={{ color: "var(--brand-cyan-400)", fontSize: 12 }}>
              {runLoading ? "syncing..." : activeRun?.status ?? "idle"}
            </span>
          </div>
          <div className="ws-console">
            {replayLogs.length === 0 ? (
              <span style={{ color: "#6B7F9C" }}>Waiting for adapter output...</span>
            ) : (
              replayLogs.map((entry, i) => {
                const t = new Date(entry.timestamp);
                const ts = `${String(t.getHours()).padStart(2, "0")}:${String(t.getMinutes()).padStart(2, "0")}:${String(t.getSeconds()).padStart(2, "0")}`;
                const lvlClass = entry.level === "warn" ? "warn" : entry.level === "error" ? "err" : "ok";
                return (
                  <div key={`${entry.timestamp}-${i}`} className="ws-console-row ws-console-row-enter">
                    <span className="ws-console-t">{ts}</span>
                    <span className="ws-console-tag">[{entry.stage.replace(/_/g, "-")}]</span>
                    <span className={`ws-console-msg ${lvlClass}`}>{entry.message}</span>
                  </div>
                );
              })
            )}
            {!TERMINAL_STATUSES.includes(activeRun?.status as RunStatus) && activeRun && (
              <div className="ws-console-row">
                <span className="ws-console-t" />
                <span className="ws-console-tag">[{activeRun.stage}]</span>
                <span className="ws-console-msg"><span className="ws-caret" /></span>
              </div>
            )}
          </div>
        </section>

        <section className="ws-onepage-card">
          <header className="ws-panel-hd">
            <h3 className="ws-h5">Vulnerability scorecard</h3>
            <Chip kind={scoreTone(exposureScore)} dot>{exposureScore} / 100</Chip>
          </header>
          <div className="ws-findings">
            {FINDINGS.map(f => (
              <div key={f.title} className="ws-finding">
                <div>
                  <SeverityChip level={f.sev} />
                  <div className="ws-finding-title" style={{ marginTop: 8 }}>{f.title}</div>
                  <div className="ws-finding-detail">{f.detail}</div>
                </div>
                <ConfidencePill value={f.conf} />
              </div>
            ))}
          </div>

          <div className="ws-panel-hd" style={{ marginTop: 16 }}>
            <h3 className="ws-h5">Source coverage</h3>
            <span className="ws-caps" style={{ color: "var(--fg3)" }}>6 adapters</span>
          </div>
          <div className="ws-src-list">
            {SOURCES.map(([name, count, quality]) => (
              <div key={name} className="ws-src-row">
                <span className="ws-mono" style={{ fontWeight: 600 }}>{name}</span>
                <div className="ws-src-bar"><div style={{ width: `${quality * 100}%` }} /></div>
                <span className="ws-mono" style={{ color: "var(--fg3)", width: 42, textAlign: "right" }}>{count}</span>
              </div>
            ))}
          </div>
        </section>
      </div>

      {recentRuns.length > 0 && (
        <section className="ws-panel animate-slide-up" style={{ marginTop: 20, animationDelay: "0.4s" }}>
          <header className="ws-panel-hd">
            <h3 className="ws-h5">Recent runs</h3>
            <span className="ws-caps" style={{ color: "var(--fg3)" }}>click to replay</span>
          </header>
          <div className="ws-run-list">
            {recentRuns.map(run => (
              <button
                key={run.id}
                className={`ws-run-row ${run.id === activeRunId ? "active" : ""}`}
                onClick={() => setActiveRunId(run.id)}
              >
                <Chip kind={statusKind(run.status)} dot>{run.status}</Chip>
                <div>
                  <div className="ws-run-row-title">{shortId(run.id)} · {run.stage.replace(/_/g, " ")}</div>
                  <div className="ws-small" style={{ marginTop: 2 }}>{run.completed_at ? "completed" : "live replay"}</div>
                </div>
                <span className="ws-mono" style={{ color: "var(--fg3)" }}>{run.stage}</span>
                <span className="ws-mono" style={{ color: "var(--fg3)" }}>{run.started_at ? new Date(run.started_at).toLocaleTimeString() : "—"}</span>
              </button>
            ))}
          </div>
        </section>
      )}
    </div>
  );
}
