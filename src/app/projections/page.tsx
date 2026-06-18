import { prisma } from "@/lib/db";
import { PROFILE, CONSERVATIVE_WEEKLY_LOSS_LB } from "@/lib/constants";
import {
  leanMass,
  ffmi as ffmiOf,
  bodyFatPercentAtGoal,
  estimateGoalDate,
  averageWeeklyRate,
  type DatedValue,
} from "@/lib/calculations";
import { StatCard } from "@/components/dashboard/StatCard";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { formatDate } from "@/lib/utils";

export const dynamic = "force-dynamic";

interface Scenario {
  label: string;
  description: string;
  leanMassLossLb: number;
}

export default async function GoalProjectionsPage() {
  const asOf = new Date();

  const [measurements, goal] = await Promise.all([
    prisma.bodyMeasurement.findMany({ orderBy: { date: "asc" } }),
    prisma.goal.findFirst({ where: { type: "weight" }, orderBy: { createdAt: "asc" } }),
  ]);

  if (measurements.length === 0) {
    return <p className="text-sm text-neutral-500">No data yet. Add a body measurement to get started.</p>;
  }

  const start = measurements[0];
  const current = measurements[measurements.length - 1];
  const goalWeight = goal?.targetValue ?? PROFILE.goalWeightLb;
  const weightRemaining = current.weight - goalWeight;

  const latestComp = [...measurements].filter((m) => m.bodyFatPercent !== null).pop() ?? null;
  const currentLeanMassLb = latestComp ? leanMass(latestComp.weight, latestComp.bodyFatPercent!) : null;

  const weightSeries: DatedValue[] = measurements.map((m) => ({ date: m.date, value: m.weight }));
  const recentRate = averageWeeklyRate(weightSeries, 28);

  const remainingToLose = Math.max(0, weightRemaining);
  const scenarios: Scenario[] = [
    {
      label: "Best Case",
      description: "Assumes only 5% of remaining weight lost is lean mass -- strong training/protein adherence preserves muscle.",
      leanMassLossLb: remainingToLose * 0.05,
    },
    {
      label: "Expected Case",
      description: "Assumes 15% of remaining weight lost is lean mass -- typical lean-mass loss rate during a sustained cut.",
      leanMassLossLb: remainingToLose * 0.15,
    },
    {
      label: "Worst Case",
      description: "Assumes 30% of remaining weight lost is lean mass -- inadequate protein/training or an aggressive deficit.",
      leanMassLossLb: remainingToLose * 0.3,
    },
  ];

  const goalDateAvgRate = estimateGoalDate(current.weight, goalWeight, recentRate, asOf);
  const goalDateConservative = estimateGoalDate(current.weight, goalWeight, CONSERVATIVE_WEEKLY_LOSS_LB, asOf);

  const daysUntil = (date: Date | null) => (date ? Math.round((date.getTime() - asOf.getTime()) / 86_400_000) : null);
  const avgRateDays = daysUntil(goalDateAvgRate);
  const conservativeDays = daysUntil(goalDateConservative);

  const goalProgress = ((start.weight - current.weight) / (start.weight - goalWeight)) * 100;

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">Goal Projections</h1>
        <p className="text-sm text-neutral-500">
          {formatDate(current.date)} &middot; {current.weight.toFixed(1)} lb &middot; Goal {goalWeight} lb
        </p>
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        <StatCard label="Current Weight" value={`${current.weight.toFixed(1)} lb`} sub={`Started at ${start.weight.toFixed(1)} lb`} />
        <StatCard label="Goal Weight" value={`${goalWeight.toFixed(1)} lb`} />
        <StatCard label="Weight Remaining" value={`${Math.max(0, weightRemaining).toFixed(1)} lb`} />
        <StatCard label="Current Pace" value={recentRate !== null ? `${recentRate.toFixed(1)} lb/wk` : "--"} sub="4-week average" />
      </div>

      {currentLeanMassLb !== null ? (
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          {scenarios.map((scenario) => {
            const bfAtGoal = bodyFatPercentAtGoal(goalWeight, currentLeanMassLb, scenario.leanMassLossLb);
            const leanAtGoal = currentLeanMassLb - scenario.leanMassLossLb;
            const fatAtGoal = goalWeight - leanAtGoal;
            const ffmiAtGoal = ffmiOf(leanAtGoal);
            return (
              <Card key={scenario.label}>
                <CardHeader className="pb-1">
                  <CardTitle>{scenario.label}</CardTitle>
                  <CardDescription>{scenario.description}</CardDescription>
                </CardHeader>
                <CardContent>
                  <div className="text-2xl font-bold">{bfAtGoal.toFixed(1)}%</div>
                  <p className="text-xs text-neutral-500">Body fat % at goal weight</p>
                  <dl className="mt-3 grid grid-cols-2 gap-y-1 text-xs text-neutral-500">
                    <dt>Lean mass lost</dt>
                    <dd className="text-right">{scenario.leanMassLossLb.toFixed(1)} lb</dd>
                    <dt>Lean mass at goal</dt>
                    <dd className="text-right">{leanAtGoal.toFixed(1)} lb</dd>
                    <dt>Fat mass at goal</dt>
                    <dd className="text-right">{fatAtGoal.toFixed(1)} lb</dd>
                    <dt>FFMI at goal</dt>
                    <dd className="text-right">{ffmiAtGoal.toFixed(1)}</dd>
                  </dl>
                </CardContent>
              </Card>
            );
          })}
        </div>
      ) : (
        <Card>
          <CardContent className="p-4 text-sm text-neutral-500">
            No body-fat scan data yet -- body composition (body fat %, lean mass, FFMI) projections at goal weight require at least one
            full body-composition measurement. Goal-date projections below don&apos;t require body fat data and are still shown.
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <Card>
          <CardHeader className="pb-1">
            <CardTitle>Projected Goal Date -- 4-Week Average Pace</CardTitle>
            <CardDescription>Based on the average weekly weight change over the last 28 days.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{goalDateAvgRate ? formatDate(goalDateAvgRate) : "--"}</div>
            <p className="mt-1 text-xs text-neutral-500">
              {avgRateDays !== null
                ? `${avgRateDays} day${avgRateDays === 1 ? "" : "s"} from now (~${(avgRateDays / 7).toFixed(1)} wk)`
                : "Not enough recent data, or not currently losing, to project."}
            </p>
            <Progress value={goalProgress} className="mt-3" />
            <p className="mt-2 text-xs text-neutral-500">
              {Math.max(0, goalProgress).toFixed(0)}% of the way there &middot; {Math.max(0, weightRemaining).toFixed(1)} lb remaining
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-1">
            <CardTitle>Projected Goal Date -- Conservative Pace</CardTitle>
            <CardDescription>{`Based on a fixed conservative rate of ${CONSERVATIVE_WEEKLY_LOSS_LB} lb/wk.`}</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="text-2xl font-bold">{goalDateConservative ? formatDate(goalDateConservative) : "--"}</div>
            <p className="mt-1 text-xs text-neutral-500">
              {conservativeDays !== null
                ? `${conservativeDays} day${conservativeDays === 1 ? "" : "s"} from now (~${(conservativeDays / 7).toFixed(1)} wk)`
                : "Already at or past goal weight."}
            </p>
            <Progress value={goalProgress} className="mt-3" />
            <p className="mt-2 text-xs text-neutral-500">
              {Math.max(0, goalProgress).toFixed(0)}% of the way there &middot; {Math.max(0, weightRemaining).toFixed(1)} lb remaining
            </p>
          </CardContent>
        </Card>
      </div>

      <p className="text-xs text-neutral-400">As of {formatDate(asOf)}</p>
    </div>
  );
}
