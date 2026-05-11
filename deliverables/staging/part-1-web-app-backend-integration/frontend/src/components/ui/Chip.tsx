import clsx from "clsx";
import { ReactNode } from "react";

type ChipKind = "neutral" | "success" | "warning" | "danger" | "cyan" | "outline" | "info";

interface ChipProps {
  kind?: ChipKind;
  mono?: boolean;
  dot?: boolean;
  children: ReactNode;
  className?: string;
}

export function Chip({ kind = "neutral", mono, dot, children, className }: ChipProps) {
  return (
    <span className={clsx(`ws-chip ws-chip-${kind}`, mono && "ws-chip-mono", className)}>
      {dot && <span className="ws-chip-dot" />}
      {children}
    </span>
  );
}

// Status → chip
export function statusChip(status: string) {
  const map: Record<string, ChipKind> = {
    active: "success",
    archived: "neutral",
    running: "cyan",
    completed: "success",
    failed: "danger",
    cancelled: "neutral",
    pending: "warning",
    queued: "neutral",
    locked: "success",
  };
  return (
    <Chip kind={map[status] ?? "neutral"} dot>
      {status}
    </Chip>
  );
}

interface SeverityChipProps { level: string }
export function SeverityChip({ level }: SeverityChipProps) {
  const map: Record<string, string> = { Critical: "crit", High: "high", Medium: "med", Low: "low", Info: "info" };
  return <span className={`ws-sev ws-sev-${map[level] ?? "info"}`}>{level}</span>;
}

interface ConfidencePillProps { value: number }
export function ConfidencePill({ value }: ConfidencePillProps) {
  const tone = value >= 80 ? "high" : value >= 50 ? "med" : "low";
  return <span className={`ws-conf ws-conf-${tone}`}>{value}</span>;
}
