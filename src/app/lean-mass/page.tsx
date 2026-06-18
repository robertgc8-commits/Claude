import { prisma } from "@/lib/db";
import { fatMass, leanMass, percentChangeOverWindow, type DatedValue } from "@/lib/calculations";
import { buildWeeklySummary, generateInsightsAndRecommendations } from "@/lib/insights";
import { PROTEIN_TARGET_G } from "@/lib/constants";
import { StatCard } from "@/components/dashboard/StatCard";
import { SeverityBadge } from "@/components/dashboard/RatingBadge";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { ChartCard } from "@/components/charts/ChartCard";
import { FatLeanChart } from "@/components/charts/FatLeanChart";
import { ProteinLeanChart } from "@/components/charts/ProteinLeanChart";
import { formatDate } from "@/lib/utils";

export const dynamic = "force-dynamic";

interface WarningRow {
  label: string;
  pass: boolean;
  severity: "info" | "warning" | "risk";
  explanation: string;
}

export default async function LeanMassPreservationPage() {
  const asOf = new Date();
  const [measurements, doses, workouts, nutrition, recovery, goal] = await Promise.all([
    prisma.bodyMeasurement.findMany({ orderBy: { date: "asc" } }),
    prisma.medicationDose.findMany({ orderBy: { date: "asc" } }),
    prisma.workout.findMany({ include: { sets: { include: { exercise: true } } }, orderBy: { date: "asc" } }),
    prisma.nutritionLog.findMany({ orderBy: { date: "asc" } }),
    prisma.recoveryLog.findMany({ orderBy: { date: "asc" } }),
    prisma.goal.findFirst({ where: { type: "weight" }, orderBy: { createdAt: "asc" } }),
  ]);

  if (measurements.length === 0) {
    return <p className="text-sm text-neutral-500">No data yet. Add a body measurement to get started.</p>;
  }

  const inputs = { measurements, doses, workouts, nutrition, recovery, goal };
  const summary = buildWeeklySummary(inputs, asOf);
  const { insights } = generateInsightsAndRecommendations(inputs, summary, asOf);

  const leanFFBWSeries: DatedValue[] = measurements
    .filter((m) => m.fatFreeBodyWeight !== null)
    .map((m) => ({ date: m.date, value: m.fatFreeBodyWeight! }));
  const leanChangePct = percentChangeOverWindow(leanFFBWSeries, 30);

  const leanDeclineWarning: WarningRow = {
    label: "Lean mass declining >1%/month",
    pass: !(leanChangePct !== null && leanChangePct < -1),
    severity: "risk",
    explanation:
      leanChangePct !== null
        ? `Fat-free mass changed ${leanChangePct.toFixed(1)}% over the last 30 days (threshold: -1%).`
        : "Not enough fat-free mass history yet to evaluate this window.",
  };

  const strengthRiskInsight = insights.find((i) => i.category === "strength" && i.severity === "risk");
  const strengthWarning: WarningRow = {
    label: "1RM declining >5% over 4 weeks",
    pass: !strengthRiskInsight,
    severity: "risk",
    explanation: strengthRiskInsight ? strengthRiskInsight.explanation : "No key lift is down more than 5% over the last 30 days.",
  };

  const weeklyLossInsight = insights.find((i) => i.metric === "Weekly loss rate (% bodyweight)");
  const weeklyLossWarning: WarningRow = {
    label: "Weekly weight loss >1.5% of bodyweight for multiple consecutive weeks",
    pass: !weeklyLossInsight,
    severity: "warning",
    explanation: weeklyLossInsight
      ? weeklyLossInsight.explanation
      : "Weekly loss rate has stayed under 1.5% of bodyweight, or hasn't sustained that pace for multiple weeks.",
  };

  const proteinBelowTarget = summary.nutrition.avgProtein !== null && summary.nutrition.avgProtein < PROTEIN_TARGET_G;
  const proteinInsight = insights.find((i) => i.category === "nutrition");
  const proteinWarning: WarningRow = {
    label: "Protein below target",
    pass: !proteinBelowTarget,
    severity: "warning",
    explanation:
      proteinInsight?.explanation ??
      (summary.nutrition.avgProtein !== null
        ? `Average protein was ${Math.round(summary.nutrition.avgProtein)} g/day against a ${PROTEIN_TARGET_G} g target.`
        : "No nutrition logs in the current window to evaluate protein intake."),
  };

  const warnings = [leanDeclineWarning, strengthWarning, weeklyLossWarning, proteinWarning];

  const compScans = measurements.filter((m) => m.bodyFatPercent !== null);
  const fatLeanChartData = compScans.map((m) => ({
    date: m.date.toISOString(),
    fatMass: fatMass(m.weight, m.bodyFatPercent!),
    leanMass: leanMass(m.weight, m.bodyFatPercent!),
  }));

  const leanByDate = compScans.map((m) => ({ date: m.date, leanMass: leanMass(m.weight, m.bodyFatPercent!) }));
  const proteinLeanChartData = nutrition.map((n) => {
    let carriedLean: number | null = null;
    for (const l of leanByDate) {
      if (l.date.getTime() <= n.date.getTime()) carriedLean = l.leanMass;
      else break;
    }
    return { date: n.date.toISOString(), proteinG: n.proteinG, leanMass: carriedLean };
  });

  const firstComp = compScans[0] ?? null;
  const lastComp = compScans[compScans.length - 1] ?? null;
  const fatLost = firstComp && lastComp ? fatMass(firstComp.weight, firstComp.bodyFatPercent!) - fatMass(lastComp.weight, lastComp.bodyFatPercent!) : null;
  const leanLost = firstComp && lastComp ? leanMass(firstComp.weight, firstComp.bodyFatPercent!) - leanMass(lastComp.weight, lastComp.bodyFatPercent!) : null;
  const totalChange = fatLost !== null && leanLost !== null ? fatLost + leanLost : null;
  const fatLossRatioPct = fatLost !== null && totalChange !== null && totalChange !== 0 ? (fatLost / totalChange) * 100 : null;
  const isRecomp = leanLost !== null && leanLost < 0;

  const muscleSeries: DatedValue[] = measurements.filter((m) => m.muscleMass !== null).map((m) => ({ date: m.date, value: m.muscleMass! }));
  const muscleChangePct = percentChangeOverWindow(muscleSeries, 30);
  const latestMuscleMass = muscleSeries.length ? muscleSeries[muscleSeries.length - 1].value : null;

  const passCount = warnings.filter((w) => w.pass).length;

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">Lean Mass Preservation</h1>
        <p className="text-sm text-neutral-500">Lean and muscle mass trends, fat-vs-lean loss composition, and early warning checks during the deficit.</p>
      </div>

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          label="Lean Mass (FFBW, 30d change)"
          value={leanChangePct !== null ? `${leanChangePct >= 0 ? "+" : ""}${leanChangePct.toFixed(1)}%` : "--"}
          sub={summary.bodyComposition.leanMassLb !== null ? `${summary.bodyComposition.leanMassLb.toFixed(1)} lb currently` : undefined}
          accent={leanChangePct !== null && leanChangePct < -1 ? "bad" : "good"}
        />
        <StatCard
          label="Muscle Mass (30d change)"
          value={muscleChangePct !== null ? `${muscleChangePct >= 0 ? "+" : ""}${muscleChangePct.toFixed(1)}%` : "--"}
          sub={latestMuscleMass !== null ? `${latestMuscleMass.toFixed(1)} lb currently` : undefined}
          accent={muscleChangePct !== null && muscleChangePct < -1.5 ? "bad" : "good"}
        />
        <StatCard
          label="Fat Loss vs Lean Loss Ratio"
          value={isRecomp ? "Recomposition" : fatLossRatioPct !== null ? `${fatLossRatioPct.toFixed(0)}% fat` : "--"}
          sub={
            isRecomp
              ? `Fat -${fatLost!.toFixed(1)} lb, lean +${Math.abs(leanLost!).toFixed(1)} lb`
              : fatLost !== null && leanLost !== null
                ? `Fat -${fatLost.toFixed(1)} lb, lean -${leanLost.toFixed(1)} lb since ${firstComp ? formatDate(firstComp.date) : ""}`
                : "Needs 2+ body-comp scans"
          }
          accent={isRecomp ? "good" : fatLossRatioPct !== null && fatLossRatioPct < 75 ? "warn" : "good"}
        />
        <StatCard
          label="Warning Checks Passing"
          value={`${passCount} / ${warnings.length}`}
          accent={passCount === warnings.length ? "good" : passCount >= warnings.length - 1 ? "warn" : "bad"}
        />
      </div>

      <Card>
        <CardHeader className="pb-1">
          <CardTitle>Lean Mass Warning Checklist</CardTitle>
          <CardDescription>Four checks that flag elevated risk of losing lean mass instead of fat during the deficit.</CardDescription>
        </CardHeader>
        <CardContent className="flex flex-col gap-3">
          {warnings.map((w) => (
            <div key={w.label} className="flex flex-col gap-1 rounded-lg border border-neutral-100 p-3 sm:flex-row sm:items-start sm:justify-between sm:gap-4">
              <div className="flex items-start gap-2">
                <span className={w.pass ? "text-emerald-600" : "text-red-600"}>{w.pass ? "✓" : "✗"}</span>
                <div>
                  <div className="text-sm font-medium text-neutral-900">{w.label}</div>
                  <p className="text-xs text-neutral-500">{w.explanation}</p>
                </div>
              </div>
              {w.pass ? <Badge variant="success">On track</Badge> : <SeverityBadge severity={w.severity} />}
            </div>
          ))}
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ChartCard title="Fat Mass vs Lean Mass" description="Computed from body-composition scans over time">
          <FatLeanChart data={fatLeanChartData} />
        </ChartCard>
        <ChartCard title="Protein Intake vs Lean Mass" description="Daily protein with lean mass carried forward from the nearest prior scan">
          <ProteinLeanChart data={proteinLeanChartData} />
        </ChartCard>
      </div>

      <p className="text-xs text-neutral-400">As of {formatDate(asOf)}</p>
    </div>
  );
}
