import { Badge } from "@/components/ui/badge";
import { RATING_LABELS, type Rating } from "@/lib/constants";

const VARIANT_BY_RATING: Record<Rating, "success" | "secondary" | "warning" | "risk"> = {
  excellent: "success",
  good: "success",
  acceptable: "secondary",
  needs_attention: "warning",
  high_risk: "risk",
};

export function RatingBadge({ rating }: { rating: Rating }) {
  return <Badge variant={VARIANT_BY_RATING[rating]}>{RATING_LABELS[rating]}</Badge>;
}

export function SeverityBadge({ severity }: { severity: "info" | "warning" | "risk" }) {
  const variant = severity === "risk" ? "risk" : severity === "warning" ? "warning" : "secondary";
  return <Badge variant={variant}>{severity.toUpperCase()}</Badge>;
}
