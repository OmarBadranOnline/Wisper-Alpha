import { useEffect, useState } from "react";
import { useNavigate } from "react-router-dom";
import { targetApi } from "../services/targetApi";
import { sessionApi } from "../services/sessionApi";
import { runApi } from "../services/runApi";
import { Chip, SeverityChip, ConfidencePill } from "../components/ui/Chip";
import { ErrorAlert } from "../components/ui/ErrorAlert";
import { PageLoader } from "../components/ui/LoadingSpinner";
import { Run } from "../types/api";

const CONF_DIST = [8, 14, 22, 18, 26, 34, 42, 51, 38, 24];
const MAX_CONF = Math.max(...CONF_DIST);

const SOURCES = [
  ["subfinder", 184, 0.92], ["amass", 211, 0.88], ["crt.sh", 96, 0.74],
  ["shodan", 27, 0.62], ["censys", 41, 0.58], ["wayback", 1120, 0.45],
] as const;

const DELTA = [
  { sev: "High",   title: "Exposed development subdomain",        detail: "dev-admin.example.com · Shodan + Censys", conf: 87 },
  { sev: "Medium", title: "Staging TLS cert near expiry",         detail: "*.staging.example.com · Censys · 4 days", conf: 62 },
  { sev: "Low",    title: "Abandoned S3 endpoint in archive",     detail: "wayback · 2019 snapshot",                 conf: 48 },
];

export function DashboardPage() {
  const navigate = useNavigate();
  const [counts, setCounts] = useState({ targets: 0, sessions: 0, runs: 0, running: 0 });
  const [recentRuns, setRecentRuns] = useState<Run[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    Promise.all([targetApi.list(), sessionApi.list(), runApi.list()])
      .then(([t, s, r]) => {
        setCounts({ targets: t.total, sessions: s.total, runs: r.total, running: r.items.filter(x => x.status === "running").length });
        setRecentRuns(r.items.slice(0, 5));
      })
      .catch(e => setError(e.message))
      .finally(() => setLoading(false));
  }, []);

  if (loading) return <PageLoader />;

  return (
    <div>
      <header className="ws-page-hd">
        <div>
          <div className="ws-crumb">Dashboard</div>
          <h1 className="ws-h2">Reconnaissance overview</h1>
        </div>
        <div className="ws-hd-actions">
          <Chip kind="success" dot>System ready</Chip>
          <span className="ws-caps" style={{ color: "var(--fg3)" }}>Part 1 — platform baseline</span>
        </div>
      </header>

      {error && <div style={{ marginBottom: 16 }}><ErrorAlert message={error} onDismiss={() => setError(null)} /></div>}

      <section className="ws-guide">
        <div className="ws-guide-head">
          <h3 className="ws-h5">Guided reconnaissance flow</h3>
          <Chip kind="info">start here</Chip>
        </div>
        <div className="ws-guide-steps">
          <div className="ws-guide-step">
            <span>1</span>
            <div>
              <div className="ws-guide-title">Install dependencies</div>
              <div className="ws-small">Run <span className="ws-mono">./run-unit-tests.sh</span> in the project root to verify toolchain and checks.</div>
            </div>
          </div>
          <div className="ws-guide-step">
            <span>2</span>
            <div>
              <div className="ws-guide-title">Create target from URL</div>
              <div className="ws-small">Go to Targets and submit only the website URL. The system creates target/session automatically.</div>
            </div>
          </div>
          <div className="ws-guide-step">
            <span>3</span>
            <div>
              <div className="ws-guide-title">Monitor live run</div>
              <div className="ws-small">You are redirected to the run console for stage-by-stage progress and logs.</div>
            </div>
          </div>
          <div className="ws-guide-step">
            <span>4</span>
            <div>
              <div className="ws-guide-title">Review data and findings</div>
              <div className="ws-small">Use dashboard widgets and run history to inspect confidence, source coverage, and outcomes.</div>
            </div>
          </div>
        </div>
      </section>

      {/* Stats */}
      <div className="ws-grid-4">
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
          <div className="ws-stat-lbl">Total runs</div>
          <div className="ws-stat-num">{counts.runs}</div>
          <div className="ws-stat-delta">pipeline executions</div>
        </div>
        <div className="ws-stat">
          <div className="ws-stat-lbl">Active now</div>
          <div className="ws-stat-num">{counts.running}</div>
          <div className={`ws-stat-delta ${counts.running > 0 ? "pos" : ""}`}>{counts.running > 0 ? "runs in progress" : "no active runs"}</div>
        </div>
      </div>

      {/* Confidence + Source coverage (placeholder charts) */}
      <div className="ws-grid-2" style={{ marginTop: 20 }}>
        <section className="ws-panel">
          <header className="ws-panel-hd">
            <h3 className="ws-h5">Confidence distribution</h3>
            <span className="ws-caps" style={{ color: "var(--fg3)" }}>example run · 247 findings</span>
          </header>
          <div className="ws-bars">
            {CONF_DIST.map((v, i) => (
              <div key={i} className="ws-bar" style={{
                height: `${(v / MAX_CONF) * 100}%`,
                background: i < 4 ? "var(--state-danger)" : i < 7 ? "var(--state-warning)" : "var(--state-success)",
              }} />
            ))}
          </div>
          <div className="ws-bars-axis">
            <span>0</span><span>low</span><span>medium</span><span>high</span><span>100</span>
          </div>
        </section>

        <section className="ws-panel">
          <header className="ws-panel-hd">
            <h3 className="ws-h5">Source coverage</h3>
            <span className="ws-caps" style={{ color: "var(--fg3)" }}>6 adapters</span>
          </header>
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

      {/* Advanced-mode delta */}
      <section className="ws-panel" style={{ marginTop: 20 }}>
        <header className="ws-panel-hd">
          <h3 className="ws-h5">Advanced-mode delta</h3>
          <Chip kind="cyan">+34 assets only advanced mode found</Chip>
        </header>
        <div className="ws-delta">
          {DELTA.map((d, i) => (
            <div key={i} className="ws-delta-row">
              <SeverityChip level={d.sev} />
              <div>
                <div className="ws-delta-ttl">{d.title}</div>
                <div className="ws-mono" style={{ color: "var(--fg3)" }}>{d.detail}</div>
              </div>
              <ConfidencePill value={d.conf} />
            </div>
          ))}
        </div>
      </section>

      {/* Recent runs */}
      {recentRuns.length > 0 && (
        <section className="ws-panel" style={{ marginTop: 20, padding: 0, overflow: "hidden" }}>
          <div style={{ padding: "14px 18px 0", display: "flex", justifyContent: "space-between", alignItems: "center" }}>
            <h3 className="ws-h5">Recent runs</h3>
          </div>
          <table className="ws-table" style={{ marginTop: 10 }}>
            <thead>
              <tr>
                <th>Run ID</th><th>Stage</th><th>Status</th><th>Started</th>
              </tr>
            </thead>
            <tbody>
              {recentRuns.map(r => (
                <tr key={r.id} style={{ cursor: "pointer" }} onClick={() => navigate(`/runs/${r.id}`)}>
                  <td><span className="ws-mono" style={{ color: "var(--brand-cyan-600)", fontWeight: 600 }}>{r.id.slice(0, 8)}…</span></td>
                  <td><span className="ws-mono">{r.stage}</span></td>
                  <td>
                    <Chip kind={r.status === "completed" ? "success" : r.status === "running" ? "cyan" : r.status === "failed" ? "danger" : "neutral"} dot>
                      {r.status}
                    </Chip>
                  </td>
                  <td><span style={{ color: "var(--fg3)", fontSize: 12 }}>{r.started_at ? new Date(r.started_at).toLocaleString() : "—"}</span></td>
                </tr>
              ))}
            </tbody>
          </table>
        </section>
      )}
    </div>
  );
}
