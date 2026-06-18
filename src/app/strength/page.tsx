import { prisma } from "@/lib/db";
import { buildWeeklySummary, computeMuscleRetentionScore } from "@/lib/insights";
import { buildKeyLiftSeries, buildKeyLiftStatuses, buildWeeklyVolumeTrend, STRENGTH_DECLINE_WARNING } from "@/lib/strength";
import { tallyMuscleVolume, classifyWeeklyVolume } from "@/lib/muscleVolume";
import { KEY_LIFTS, MUSCLE_GROUPS } from "@/lib/constants";
import { StatCard } from "@/components/dashboard/StatCard";
import { Badge } from "@/components/ui/badge";
import { Card, CardContent, CardHeader, CardTitle, CardDescription } from "@/components/ui/card";
import { ChartCard } from "@/components/charts/ChartCard";
import { StrengthTrendChart } from "@/components/charts/StrengthTrendChart";
import { MuscleVolumeChart } from "@/components/charts/MuscleVolumeChart";
import { formatDate } from "@/lib/utils";

export const dynamic = "force-dynamic";

const RETENTION_LABELS: Record<string, string> = {
  excellent: "Excellent",
  good: "Good",
  moderate_risk: "Moderate Risk",
  high_risk: "High Risk",
};

const RETENTION_VARIANT: Record<string, "success" | "secondary" | "warning" | "risk"> = {
  excellent: "success",
  good: "success",
  moderate_risk: "warning",
  high_risk: "risk",
};

export default async function StrengthPreservationPage() {
  const asOf = new Date();
  const [measurements, doses, workouts, nutrition, recovery, goal] = await Promise.all([
    prisma.bodyMeasurement.findMany({ orderBy: { date: "asc" } }),
    prisma.medicationDose.findMany({ orderBy: { date: "asc" } }),
    prisma.workout.findMany({ include: { sets: { include: { exercise: true } } }, orderBy: { date: "asc" } }),
    prisma.nutritionLog.findMany({ orderBy: { date: "asc" } }),
    prisma.recoveryLog.findMany({ orderBy: { date: "asc" } }),
    prisma.goal.findFirst({ where: { type: "weight" }, orderBy: { createdAt: "asc" } }),
  ]);

  if (workouts.length === 0) {
    return <p className="text-sm text-neutral-500">No workouts logged yet. Log a workout to see strength preservation data.</p>;
  }

  const inputs = { measurements, doses, workouts, nutrition, recovery, goal };
  const summary = buildWeeklySummary(inputs, asOf);
  const retention = computeMuscleRetentionScore(inputs, summary, asOf);

  const liftStatuses = buildKeyLiftStatuses(workouts);
  const seriesByExercise: Record<string, ReturnType<typeof buildKeyLiftSeries>> = {};
  for (const lift of KEY_LIFTS) {
    const series = buildKeyLiftSeries(workouts, lift);
    if (series.length > 0) seriesByExercise[lift] = series;
  }

  const recentSets = workouts
    .filter((w) => asOf.getTime() - w.date.getTime() <= 7 * 86_400_000)
    .flatMap((w) => w.sets);
  const muscleTally = tallyMuscleVolume(recentSets);
  const volumeChartData = MUSCLE_GROUPS.map((muscle) => {
    const hardSets = Math.round((muscleTally[muscle]?.hardSets ?? 0) * 100) / 100;
    return { muscle, hardSets, classification: classifyWeeklyVolume(muscle, hardSets) };
  });

  const weeklyVolume = buildWeeklyVolumeTrend(workouts);
  const last4Weeks = weeklyVolume.slice(-4);
  const volumeDropoff =
    last4Weeks.length >= 2 && last4Weeks[0].volumeLoad > 0
      ? ((last4Weeks[last4Weeks.length - 1].volumeLoad - last4Weeks[0].volumeLoad) / last4Weeks[0].volumeLoad) * 100
      : null;

  const avgRecovery = recovery.length
    ? recovery
        .filter((r) => asOf.getTime() - r.date.getTime() <= 14 * 86_400_000)
        .reduce((sum, r, i, arr) => sum + (r.recoveryRating ?? 0) / arr.length, 0)
    : null;

  const warningLifts = liftStatuses.filter((l) => l.warning !== "none");

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">Strength Preservation</h1>
        <p className="text-sm text-neutral-500">Key lift trends, muscle retention score, and recovery monitoring during the deficit.</p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <Card className="md:col-span-1">
          <CardHeader className="pb-1">
            <CardTitle>Muscle Retention Score</CardTitle>
            <CardDescription>Composite of lean mass, muscle mass, strength, training consistency, and protein.</CardDescription>
          </CardHeader>
          <CardContent>
            <div className="flex items-baseline gap-2">
              <span className="text-3xl font-bold">{retention.score.toFixed(0)}</span>
              <span className="text-sm text-neutral-500">/ 100</span>
            </div>
            <Badge variant={RETENTION_VARIANT[retention.rating]} className="mt-2">
              {RETENTION_LABELS[retention.rating]}
            </Badge>
            <dl className="mt-3 grid grid-cols-2 gap-y-1 text-xs text-neutral-500">
              <dt>Lean mass</dt>
              <dd className="text-right">{retention.breakdown.leanMass.toFixed(0)}/30</dd>
              <dt>Muscle mass</dt>
              <dd className="text-right">{retention.breakdown.muscleMass.toFixed(0)}/20</dd>
              <dt>Strength</dt>
              <dd className="text-right">{retention.breakdown.strength.toFixed(0)}/25</dd>
              <dt>Consistency</dt>
              <dd className="text-right">{retention.breakdown.consistency.toFixed(0)}/15</dd>
              <dt>Protein</dt>
              <dd className="text-right">{retention.breakdown.protein.toFixed(0)}/10</dd>
            </dl>
          </CardContent>
        </Card>

        <StatCard
          label="Volume Load (last 4 wks)"
          value={volumeDropoff !== null ? `${volumeDropoff >= 0 ? "+" : ""}${volumeDropoff.toFixed(0)}%` : "--"}
          sub="Change in weekly total volume load"
          accent={volumeDropoff !== null && volumeDropoff < -20 ? "bad" : "default"}
        />
        <StatCard
          label="Avg Recovery Rating"
          value={avgRecovery !== null ? avgRecovery.toFixed(1) : "--"}
          sub="14-day average, 1-10 scale"
          accent={avgRecovery !== null && avgRecovery < 5 ? "warn" : "default"}
        />
      </div>

      {warningLifts.length > 0 && (
        <Card className="border-red-200 bg-red-50">
          <CardHeader className="pb-1">
            <CardTitle className="text-red-800">Strength Decline Warnings</CardTitle>
          </CardHeader>
          <CardContent className="flex flex-col gap-2">
            {warningLifts.map((l) => (
              <div key={l.lift} className="text-sm text-red-800">
                <span className="font-semibold">{l.lift}:</span>{" "}
                {l.warning === "decline_60d"
                  ? `down ${Math.abs(l.change60d ?? 0).toFixed(1)}% over 60 days (threshold 10%).`
                  : `down ${Math.abs(l.change30d ?? 0).toFixed(1)}% over 30 days (threshold 5%).`}{" "}
                {STRENGTH_DECLINE_WARNING}
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
        {liftStatuses.map((l) => (
          <Card key={l.lift}>
            <CardHeader className="pb-1">
              <CardTitle>{l.lift}</CardTitle>
            </CardHeader>
            <CardContent>
              <div className="text-xl font-bold">{l.hasData ? `${l.current1RM!.toFixed(0)} lb` : "--"}</div>
              <p className="text-xs text-neutral-500">Est. 1RM</p>
              {l.hasData && (
                <div className="mt-2 flex gap-3 text-xs">
                  <span className={l.change30d !== null && l.change30d <= -5 ? "font-semibold text-red-600" : "text-neutral-500"}>
                    30d: {l.change30d !== null ? `${l.change30d >= 0 ? "+" : ""}${l.change30d.toFixed(1)}%` : "--"}
                  </span>
                  <span className={l.change60d !== null && l.change60d <= -10 ? "font-semibold text-red-600" : "text-neutral-500"}>
                    90d: {l.change60d !== null ? `${l.change60d >= 0 ? "+" : ""}${l.change60d.toFixed(1)}%` : "--"}
                  </span>
                </div>
              )}
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        {Object.keys(seriesByExercise).length > 0 ? (
          <ChartCard title="Key Lift Trend" description="Top set weight and estimated 1RM by session">
            <StrengthTrendChart seriesByExercise={seriesByExercise} />
          </ChartCard>
        ) : (
          <Card>
            <CardContent className="flex h-72 items-center justify-center text-sm text-neutral-500">
              No key lift data yet. Log sets for {KEY_LIFTS.slice(0, 3).join(", ")}, etc.
            </CardContent>
          </Card>
        )}
        <ChartCard title="Weekly Muscle Volume" description="Hard sets per muscle group, last 7 days">
          <MuscleVolumeChart data={volumeChartData} />
        </ChartCard>
      </div>

      <p className="text-xs text-neutral-400">As of {formatDate(asOf)}</p>
    </div>
  );
}
