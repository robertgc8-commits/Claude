import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { cn } from "@/lib/utils";

export function StatCard({
  label,
  value,
  sub,
  accent,
}: {
  label: string;
  value: string;
  sub?: string;
  accent?: "default" | "good" | "bad" | "warn";
}) {
  const accentClass =
    accent === "good"
      ? "text-emerald-600"
      : accent === "bad"
        ? "text-red-600"
        : accent === "warn"
          ? "text-amber-600"
          : "text-neutral-900";

  return (
    <Card>
      <CardHeader className="pb-1">
        <CardTitle>{label}</CardTitle>
      </CardHeader>
      <CardContent>
        <div className={cn("text-2xl font-bold", accentClass)}>{value}</div>
        {sub && <p className="mt-1 text-xs text-neutral-500">{sub}</p>}
      </CardContent>
    </Card>
  );
}
