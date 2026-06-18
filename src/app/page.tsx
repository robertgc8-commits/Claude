import Link from "next/link";
import { prisma } from "@/lib/db";
import { PROFILE, RATING_LABELS } from "@/lib/constants";
import {
  fatMass,
  leanMass,
  ffmi as ffmiOf,
  rollingAverage,
  linearTrend,
  averageWeeklyRate,
  type DatedValue,
} from "@/lib/calculations";
import { buildWeeklySummary, generateInsightsAndRecommendations, computeOverallRating } from "@/lib/insights";
import { mondayOf, nextWeekday, isThisWeekCompleted, computeStreak, missedLastWeighIn } from "@/lib/schedule";
import { StatCard } from "@/components/dashboard/StatCard";
import { RatingBadge } from "@/components/dashboard/RatingBadge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Progress } from "@/components/ui/progress";
import { ChartCard } from "@/components/charts/ChartCard";
import { WeightTrendChart } from "@/components/charts/WeightTrendChart";
import { BodyFatTrendChart } from "@/components/charts/BodyFatTrendChart";
import { generateWeeklyReport } from "@/lib/actions/reports";
import { formatDate } from "@/lib/utils";

export const dynamic = "force-dynamic";

export default async function DashboardPage() {
  const asOf = new Date();

  const [measurements, doses, workouts, nutrition, recovery, goal, checkIns, latestReport] = await Promise.all([
    prisma.bodyMeasurement.findMany({ orderBy: { date: "asc" } }),
    prisma.medicationDose.findMany({ orderBy: { date: "asc" } }),
    prisma.workout.findMany({ include: { sets: { include: { exercise: true } } }, orderBy: { date: "asc" } }),
    prisma.nutritionLog.findMany({ orderBy: { date: "asc" } }),
    prisma.recoveryLog.findMany({ orderBy: { date: "asc" } }),
    prisma.goal.findFirst({ where: { type: "weight" }, orderBy: { createdAt: "asc" } }),
    prisma.weeklyCheckIn.findMany({ orderBy: { weekStartDate: "asc" } }),
    prisma.weeklyProgressReport.findFirst({ orderBy: { weekStartDate: "desc" }, include: { recommendations: true } }),
  ]);

  if (measurements.length === 0) {
    return <p className="text-sm text-neutral-500">No data yet. Add a body measurement to get started.</p>;
  }

  const inputs = { measurements, doses, workouts, nutrition, recovery, goal };
  const summary = buildWeeklySummary(inputs, asOf);
  const { insights } = generateInsightsAndRecommendations(inputs, summary, asOf);
  const liveRating = computeOverallRating(insights);

  const start = measurements[0];
  const current = measurements[measurements.length - 1];
  const goalWeight = goal?.targetValue ?? PROFILE.goalWeightLb;

  const weightSeries: DatedValue[] = measurements.map((m) => ({ date: m.date, value: m.weight }));
  const recentRate = averageWeeklyRate(weightSeries, 14);
  const totalLoss = start.weight - current.weight;
  const goalProgress = ((start.weight - current.weight) / (start.weight - goalWeight)) * 100;

  const latestComp = [...measurements].filter((m) => m.bodyFatPercent !== null).pop() ?? null;
  const fm = latestComp ? fatMass(latestComp.weight, latestComp.bodyFatPercent!) : null;
  const lm = latestComp ? leanMass(latestComp.weight, latestComp.bodyFatPercent!) : null;
  const ffmiValue = lm ? ffmiOf(lm) : null;

  let trendLabel = "Maintaining";
  if (recentRate !== null) {
    if (Math.abs(recentRate) < 0.25) trendLabel = "Plateau Risk";
    else if (recentRate > 0) trendLabel = "Losing";
    else trendLabel = "Gaining";
  }

  const leanInsight = insights.find((i) => i.category === "lean_mass");
  const leanStatus = leanInsight?.severity === "risk" ? "At Risk" : leanInsight?.severity === "warning" ? "Watch" : "Preserved";

  const strengthInsight = insights.find((i) => i.category === "strength");
  const strengthStatus = strengthInsight?.severity === "risk" ? "Declining" : "Stable";

  const proteinHit = summary.nutrition.proteinTargetHitRate;

  const nextWeighIn = nextWeekday(isThisWeekCompleted(checkIns, asOf) ? new Date(asOf.getTime() + 86_400_000) : asOf, 3);
  const daysUntil = Math.round((nextWeighIn.getTime() - asOf.getTime()) / 86_400_000);
  const thisWeekDone = isThisWeekCompleted(checkIns, asOf);
  const streak = computeStreak(checkIns, asOf);
  const missedLast = missedLastWeighIn(checkIns, asOf);

  const rolling = rollingAverage(weightSeries, 7);
  const trend = linearTrend(weightSeries);
  const weightChartData = weightSeries.map((p, i) => ({
    date: p.date.toISOString(),
    weight: p.value,
    rollingAvg: rolling[i]?.value ?? null,
    trend: trend.points[i]?.value ?? null,
  }));

  const bfSeries: DatedValue[] = measurements.filter((m) => m.bodyFatPercent !== null).map((m) => ({ date: m.date, value: m.bodyFatPercent! }));
  const bfTrend = linearTrend(bfSeries);
  const bodyFatChartData = bfSeries.map((p, i) => ({
    date: p.date.toISOString(),
    bodyFatPercent: p.value,
    trend: bfTrend.points[i]?.value ?? null,
  }));

  const reportThisWeek = latestReport && mondayOf(latestReport.weekStartDate).getTime() === mondayOf(asOf).getTime();
  const topRecommendation = latestReport?.recommendations.find((r) => !r.resolved)?.message ?? "No active recommendations -- keep current habits.";

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">Dashboard</h1>
        <p className="text-sm text-neutral-500">
          {formatDate(current.date)} &middot; {current.weight.toFixed(1)} lb &middot; Goal {goalWeight} lb
        </p>
      </div>

      <div className="grid grid-cols-2 gap-3 md:grid-cols-3 lg:grid-cols-5">
        <StatCard label="Current Weight" value={`${current.weight.toFixed(1)} lb`} sub={`Started at ${start.weight.toFixed(1)} lb`} />
        <StatCard label="Total Loss" value={`${totalLoss.toFixed(1)} lb`} accent="good" sub={formatDate(start.date) + " to now"} />
        <StatCard label="Weekly Loss Rate" value={recentRate !== null ? `${recentRate.toFixed(1)} lb/wk` : "--"} sub="14-day average" />
        <StatCard
          label="Body Fat %"
          value={latestComp?.bodyFatPercent !== null && latestComp?.bodyFatPercent !== undefined ? `${latestComp.bodyFatPercent.toFixed(1)}%` : "--"}
          sub={latestComp ? formatDate(latestComp.date) : "No scan yet"}
        />
        <StatCard label="Fat Mass" value={fm !== null ? `${fm.toFixed(1)} lb` : "--"} />
        <StatCard label="Lean Mass" value={lm !== null ? `${lm.toFixed(1)} lb` : "--"} accent="good" />
        <StatCard label="FFMI" value={ffmiValue !== null ? ffmiValue.toFixed(1) : "--"} />
        <StatCard
          label="Current Dose"
          value={summary.weight.currentDoseMg ? `${summary.weight.currentDoseMg} mg` : "--"}
          sub={summary.weight.daysOnCurrentDose !== null ? `${summary.weight.daysOnCurrentDose} days on dose` : undefined}
        />
        <Card className="col-span-2">
          <CardHeader className="pb-1">
            <CardTitle>Goal Progress</CardTitle>
          </CardHeader>
          <CardContent>
            <Progress value={goalProgress} />
            <p className="mt-2 text-xs text-neutral-500">
              {Math.max(0, goalProgress).toFixed(0)}% to {goalWeight} lb &middot; {(current.weight - goalWeight).toFixed(1)} lb remaining
            </p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-4">
        <Card>
          <CardHeader className="pb-1">
            <CardTitle>Next Wednesday Weigh-In</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-lg font-bold">{thisWeekDone ? "Done this week" : `${daysUntil} day${daysUntil === 1 ? "" : "s"}`}</div>
            <p className="text-xs text-neutral-500">
              {formatDate(nextWeighIn)} &middot; Streak: {streak} wk
            </p>
            {missedLast && <p className="mt-1 text-xs font-medium text-red-600">Missed last week&apos;s weigh-in</p>}
            <Link href="/checkin" className="mt-2 inline-block text-xs font-medium text-blue-600 underline">
              Go to check-in
            </Link>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-1">
            <CardTitle>Weekly Report Status</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-lg font-bold">{reportThisWeek ? "Generated" : "Not yet generated"}</div>
            {!reportThisWeek && (
              <form
                action={async () => {
                  "use server";
                  await generateWeeklyReport();
                }}
              >
                <button className="mt-2 text-xs font-medium text-blue-600 underline" type="submit">
                  Generate now
                </button>
              </form>
            )}
            {reportThisWeek && (
              <Link href="/reports" className="mt-2 inline-block text-xs font-medium text-blue-600 underline">
                View report
              </Link>
            )}
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-1">
            <CardTitle>Current Trend</CardTitle>
          </CardHeader>
          <CardContent>
            <div className="text-lg font-bold">{trendLabel}</div>
            <p className="text-xs text-neutral-500">
              Lean mass: {leanStatus} &middot; Strength: {strengthStatus}
            </p>
          </CardContent>
        </Card>
        <Card>
          <CardHeader className="pb-1">
            <CardTitle>Current Risk Level</CardTitle>
          </CardHeader>
          <CardContent>
            <RatingBadge rating={liveRating} />
            <p className="mt-2 text-xs text-neutral-500">{topRecommendation}</p>
          </CardContent>
        </Card>
      </div>

      <div className="grid grid-cols-1 gap-3 md:grid-cols-2 lg:grid-cols-4">
        <StatCard label="Protein Compliance" value={proteinHit !== null ? `${proteinHit.toFixed(0)}%` : "--"} sub="Days hitting target this week" />
        <StatCard label="Lean-Mass Preservation" value={leanStatus} accent={leanStatus === "Preserved" ? "good" : leanStatus === "Watch" ? "warn" : "bad"} />
        <StatCard label="Strength Preservation" value={strengthStatus} accent={strengthStatus === "Stable" ? "good" : "bad"} />
        <StatCard label="Overall Rating" value={RATING_LABELS[liveRating]} />
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <ChartCard title="Weight Over Time" description="Raw weigh-ins, 7-day rolling average, and overall trend">
          <WeightTrendChart data={weightChartData} goalWeight={goalWeight} />
        </ChartCard>
        <ChartCard title="Body Fat % Over Time" description="From full body-composition scans">
          <BodyFatTrendChart data={bodyFatChartData} />
        </ChartCard>
      </div>
    </div>
  );
}
