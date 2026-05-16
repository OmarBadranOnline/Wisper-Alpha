import clsx from "clsx";
import { ButtonHTMLAttributes, ReactNode } from "react";

type Kind = "primary" | "secondary" | "accent" | "danger" | "ghost";
type Size = "sm" | "md" | "lg";

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  kind?: Kind;
  size?: Size;
  loading?: boolean;
  icon?: ReactNode;
}

export function Button({ kind = "secondary", size = "md", loading, icon, children, disabled, className, ...props }: ButtonProps) {
  const sizeClass = size === "sm" ? "ws-btn-sm" : size === "lg" ? "ws-btn-lg" : "";
  return (
    <button
      {...props}
      disabled={disabled || loading}
      className={clsx("ws-btn", `ws-btn-${kind}`, sizeClass, className)}
    >
      {loading ? <span className="ws-spin" /> : icon}
      {children}
    </button>
  );
}
