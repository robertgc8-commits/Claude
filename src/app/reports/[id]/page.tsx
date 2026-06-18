import { notFound } from "next/navigation";
import { prisma } from "@/lib/db";
import { resolveInsight, resolveRecommendation } from "@/lib/actions/reports";
import type { WeeklySummary } from "@/lib/insights";
import { RatingBadge, SeverityBadge } from "@/components/dashboard/RatingBadge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { Badge } from "@/components/ui/badge";
import { Button } from "@/components/ui/button";
import { formatDate } from "@/lib/utils";
import type { Rating } from "@/lib/constants";

function fmt(n: number | null | undefined, decimals = 1, suffix = ""): string {
  if (n === null || n === undefined || Number.isNaN(n)) return "--";
  return `${n.toFixed(decimals)}${suffix}`;
}

function fmtSigned(n: number | null | undefined, decimals = 1, suffix = ""): string {
  if (n === null || n === undefined || Number.isNaN(n)) return "--";
  return `${n >= 0 ? "+" : ""}${n.toFixed(decimals)}${suffix}`;
}

const PRIORITY_VARIANT: Record<string, "risk" | "warning" | "secondary"> = {
  high: "risk",
  medium: "warning",
  low: "secondary",
};

export default async function ReportDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;

  const weeklyReport = await prisma.weeklyProgressReport.findUnique({
    where: { id },
    include: { insights: true, recommendations: true },
  });
  const monthlyReport = weeklyReport
    ? null
    : await prisma.monthlyProgressReport.findUnique({
        where: { id },
        include: { insights: true, recommendations: true },
      });

  const report = weeklyReport ?? monthlyReport;
  if (!report) notFound();

  const summary = JSON.parse(report.summaryJson) as WeeklySummary;
  const startDate = weeklyReport ? weeklyReport.weekStartDate : monthlyReport!.monthStartDate;
  const endDate = weeklyReport ? weeklyReport.weekEndDate : monthlyReport!.monthEndDate;

  const keyLifts = Object.keys({ ...summary.training.keyLiftOneRm, ...summary.training.keyLiftChange30d });

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold">
            {weeklyReport ? "Weekly Report" : "Monthly Report"}
          </h1>
          <p className="text-sm text-neutral-500">
            {formatDate(startDate)} - {formatDate(endDate)} &middot; Generated {formatDate(report.generatedAt)}
          </p>
        </div>
        {weeklyReport && <RatingBadge rating={weeklyReport.overallRating as Rating} />}
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Weight</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
            <div>
              <p className="text-xs text-neutral-500">Current</p>
              <p className="text-lg font-semibold">{fmt(summary.weight.current, 1, " lb")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Change from Last Week</p>
              <p className="text-lg font-semibold">{fmtSigned(summary.weight.changeFromLastWeek, 1, " lb")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Change from 4 Weeks Ago</p>
              <p className="text-lg font-semibold">{fmtSigned(summary.weight.changeFromFourWeeksAgo, 1, " lb")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Total Loss from Start</p>
              <p className="text-lg font-semibold">{fmt(summary.weight.totalLossFromStart, 1, " lb")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Current Dose</p>
              <p className="text-lg font-semibold">
                {summary.weight.currentDoseMg ? `${summary.weight.currentDoseMg} mg` : "--"}
              </p>
              <p className="text-xs text-neutral-400">
                {summary.weight.daysOnCurrentDose !== null ? `${summary.weight.daysOnCurrentDose} days on dose` : ""}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Body Composition</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-6">
            <div>
              <p className="text-xs text-neutral-500">Fat Mass</p>
              <p className="text-lg font-semibold">{fmt(summary.bodyComposition.fatMassLb, 1, " lb")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Lean Mass</p>
              <p className="text-lg font-semibold">{fmt(summary.bodyComposition.leanMassLb, 1, " lb")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Muscle Mass</p>
              <p className="text-lg font-semibold">{fmt(summary.bodyComposition.muscleMassLb, 1, " lb")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Body Fat %</p>
              <p className="text-lg font-semibold">{fmt(summary.bodyComposition.bodyFatPercent, 1, "%")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">FFMI</p>
              <p className="text-lg font-semibold">{fmt(summary.bodyComposition.ffmi, 1)}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Fat / Lean Change</p>
              <p className="text-lg font-semibold">
                {fmtSigned(summary.bodyComposition.fatMassChangeLb, 1, " lb")} /{" "}
                {fmtSigned(summary.bodyComposition.leanMassChangeLb, 1, " lb")}
              </p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Training</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            <div>
              <p className="text-xs text-neutral-500">Workouts This Week</p>
              <p className="text-lg font-semibold">{summary.training.workoutsThisWeek}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Total Volume Load</p>
              <p className="text-lg font-semibold">{fmt(summary.training.totalVolumeLoad, 0, " lb")}</p>
            </div>
          </div>
          <div>
            <p className="mb-1 text-xs font-medium text-neutral-500">Hard Sets by Muscle</p>
            {Object.keys(summary.training.hardSetsByMuscle).length > 0 ? (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Muscle</TableHead>
                    <TableHead>Hard Sets</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {Object.entries(summary.training.hardSetsByMuscle).map(([muscle, sets]) => (
                    <TableRow key={muscle}>
                      <TableCell>{muscle}</TableCell>
                      <TableCell>{sets}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <p className="text-sm text-neutral-500">No training data this week.</p>
            )}
          </div>
          <div>
            <p className="mb-1 text-xs font-medium text-neutral-500">Key Lifts</p>
            {keyLifts.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Lift</TableHead>
                    <TableHead>Est. 1RM</TableHead>
                    <TableHead>30-Day Change</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {keyLifts.map((lift) => (
                    <TableRow key={lift}>
                      <TableCell>{lift}</TableCell>
                      <TableCell>{fmt(summary.training.keyLiftOneRm[lift], 0, " lb")}</TableCell>
                      <TableCell>{fmtSigned(summary.training.keyLiftChange30d[lift], 1, "%")}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <p className="text-sm text-neutral-500">No key lift data.</p>
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Nutrition</CardTitle>
        </CardHeader>
        <CardContent>
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3 lg:grid-cols-5">
            <div>
              <p className="text-xs text-neutral-500">Avg Calories</p>
              <p className="text-lg font-semibold">{fmt(summary.nutrition.avgCalories, 0)}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Avg Protein</p>
              <p className="text-lg font-semibold">{fmt(summary.nutrition.avgProtein, 0, " g")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Protein Target Hit Rate</p>
              <p className="text-lg font-semibold">{fmt(summary.nutrition.proteinTargetHitRate, 0, "%")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Avg Water</p>
              <p className="text-lg font-semibold">{fmt(summary.nutrition.avgWaterOz, 0, " oz")}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Avg Fiber</p>
              <p className="text-lg font-semibold">{fmt(summary.nutrition.avgFiber, 0, " g")}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Zepbound</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-4">
          <div className="grid grid-cols-2 gap-3 sm:grid-cols-3">
            <div>
              <p className="text-xs text-neutral-500">Current Dose</p>
              <p className="text-lg font-semibold">
                {summary.zepbound.currentDoseMg ? `${summary.zepbound.currentDoseMg} mg` : "--"}
              </p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Appetite Trend</p>
              <p className="text-lg font-semibold">{fmtSigned(summary.zepbound.appetiteTrend, 0)}</p>
            </div>
            <div>
              <p className="text-xs text-neutral-500">Side Effect Trend</p>
              <p className="text-lg font-semibold">{fmtSigned(summary.zepbound.sideEffectTrend, 0)}</p>
            </div>
          </div>
          <div>
            <p className="mb-1 text-xs font-medium text-neutral-500">Dose Phases</p>
            {summary.zepbound.dosePhases.length > 0 ? (
              <Table>
                <TableHeader>
                  <TableRow>
                    <TableHead>Dose</TableHead>
                    <TableHead>Total Loss</TableHead>
                    <TableHead>Avg Weekly Loss</TableHead>
                  </TableRow>
                </TableHeader>
                <TableBody>
                  {summary.zepbound.dosePhases.map((phase, i) => (
                    <TableRow key={i}>
                      <TableCell>{phase.doseMg} mg</TableCell>
                      <TableCell>{fmt(phase.totalLossLb, 1, " lb")}</TableCell>
                      <TableCell>{fmt(phase.avgWeeklyLossLb, 1, " lb")}</TableCell>
                    </TableRow>
                  ))}
                </TableBody>
              </Table>
            ) : (
              <p className="text-sm text-neutral-500">No dose phase data yet.</p>
            )}
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Insights</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-3">
          {report.insights.length === 0 && <p className="text-sm text-neutral-500">No insights for this period.</p>}
          {report.insights.map((insight) => (
            <div key={insight.id} className="flex flex-col gap-1 rounded-md border border-neutral-200 p-3">
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <SeverityBadge severity={insight.severity as "info" | "warning" | "risk"} />
                  <span className="text-sm font-medium">{insight.category}</span>
                  <span className="text-xs text-neutral-400">{insight.metric}</span>
                </div>
                {insight.resolved ? (
                  <Badge variant="secondary">Resolved</Badge>
                ) : (
                  <form action={resolveInsight.bind(null, insight.id)}>
                    <Button type="submit" variant="outline" size="sm">
                      Resolve
                    </Button>
                  </form>
                )}
              </div>
              <p className="text-sm text-neutral-700">{insight.explanation}</p>
              {insight.suggestedAction && (
                <p className="text-xs text-neutral-500">Suggested: {insight.suggestedAction}</p>
              )}
            </div>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Recommendations</CardTitle>
        </CardHeader>
        <CardContent className="flex flex-col gap-3">
          {report.recommendations.length === 0 && (
            <p className="text-sm text-neutral-500">No recommendations for this period.</p>
          )}
          {report.recommendations.map((rec) => (
            <div key={rec.id} className="flex flex-col gap-1 rounded-md border border-neutral-200 p-3">
              <div className="flex items-center justify-between gap-2">
                <div className="flex items-center gap-2">
                  <Badge variant={PRIORITY_VARIANT[rec.priority] ?? "secondary"}>{rec.priority.toUpperCase()}</Badge>
                  <span className="text-sm font-medium">{rec.category}</span>
                </div>
                {rec.resolved ? (
                  <Badge variant="secondary">Resolved</Badge>
                ) : (
                  <form action={resolveRecommendation.bind(null, rec.id)}>
                    <Button type="submit" variant="outline" size="sm">
                      Resolve
                    </Button>
                  </form>
                )}
              </div>
              <p className="text-sm text-neutral-700">{rec.message}</p>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
}
