import clsx from "clsx";

type Variant = "default" | "success" | "warning" | "danger" | "info" | "muted";

const styles: Record<Variant, string> = {
  default: "bg-slate-700 text-slate-200",
  success: "bg-green-900/60 text-green-400 border border-green-700/50",
  warning: "bg-yellow-900/60 text-yellow-400 border border-yellow-700/50",
  danger: "bg-red-900/60 text-red-400 border border-red-700/50",
  info: "bg-cyan-900/60 text-cyan-400 border border-cyan-700/50",
  muted: "bg-slate-800 text-slate-500",
};

interface BadgeProps {
  children: React.ReactNode;
  variant?: Variant;
  className?: string;
}

export function Badge({ children, variant = "default", className }: BadgeProps) {
  return (
    <span
      className={clsx(
        "inline-flex items-center px-2 py-0.5 rounded text-xs font-medium",
        styles[variant],
        className
      )}
    >
      {children}
    </span>
  );
}

export function statusBadge(status: string) {
  const map: Record<string, Variant> = {
    active: "success",
    archived: "muted",
    running: "info",
    completed: "success",
    failed: "danger",
    cancelled: "muted",
    pending: "warning",
    queued: "muted",
  };
  return <Badge variant={map[status] ?? "default"}>{status}</Badge>;
}
