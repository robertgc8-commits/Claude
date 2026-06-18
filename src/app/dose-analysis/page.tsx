import { prisma } from "@/lib/db";
import { buildDosePhases, leanMass, type DosePhase } from "@/lib/calculations";
import { StatCard } from "@/components/dashboard/StatCard";
import { ChartCard } from "@/components/charts/ChartCard";
import { DosePhaseChart } from "@/components/charts/DosePhaseChart";
import { Card, CardContent } from "@/components/ui/card";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { formatDate } from "@/lib/utils";

export const dynamic = "force-dynamic";

function formatDoseMg(doseMg: number): string {
  return Number.isInteger(doseMg) ? doseMg.toString() : doseMg.toFixed(1);
}

interface BodyCompSnapshot {
  date: Date;
  bodyFatPercent: number;
  weight: number;
}

interface PhaseComposition {
  bodyFatChange: number | null;
  leanMassChangeLb: number | null;
}

function nearestScanAtOrBefore(scans: BodyCompSnapshot[], date: Date): BodyCompSnapshot | null {
  let nearest: BodyCompSnapshot | null = null;
  for (const s of scans) {
    if (s.date.getTime() <= date.getTime()) nearest = s;
    else break;
  }
  return nearest;
}

function computePhaseComposition(phase: DosePhase, scans: BodyCompSnapshot[]): PhaseComposition {
  const startScan = nearestScanAtOrBefore(scans, phase.startDate);
  const endScan = nearestScanAtOrBefore(scans, phase.endDate);
  if (!startScan || !endScan || startScan === endScan) {
    return { bodyFatChange: null, leanMassChangeLb: null };
  }
  const startLean = leanMass(startScan.weight, startScan.bodyFatPercent);
  const endLean = leanMass(endScan.weight, endScan.bodyFatPercent);
  return {
    bodyFatChange: endScan.bodyFatPercent - startScan.bodyFatPercent,
    leanMassChangeLb: endLean - startLean,
  };
}

export default async function DoseAnalysisPage() {
  const [measurements, doses] = await Promise.all([
    prisma.bodyMeasurement.findMany({ orderBy: { date: "asc" } }),
    prisma.medicationDose.findMany({ orderBy: { date: "asc" } }),
  ]);

  if (measurements.length === 0) {
    return <p className="text-sm text-neutral-500">No data yet. Add a body measurement to get started.</p>;
  }

  const phases = buildDosePhases(
    measurements.map((m) => ({ date: m.date, weight: m.weight })),
    doses.map((d) => ({ date: d.date, doseMg: d.doseMg }))
  );

  // Scans sorted ascending so nearestScanAtOrBefore can scan forward and stop at the first overshoot.
  const scans: BodyCompSnapshot[] = measurements
    .filter((m) => m.bodyFatPercent !== null)
    .map((m) => ({ date: m.date, bodyFatPercent: m.bodyFatPercent!, weight: m.weight }));

  const phaseRows = phases.map((phase) => ({ phase, composition: computePhaseComposition(phase, scans) }));

  const currentDoseMg = doses.length > 0 ? doses[doses.length - 1].doseMg : null;
  const bestPhase = phases.length > 0 ? phases.reduce((a, b) => (b.avgWeeklyLossLb > a.avgWeeklyLossLb ? b : a)) : null;
  const longestPhase = phases.length > 0 ? phases.reduce((a, b) => (b.days > a.days ? b : a)) : null;

  return (
    <div className="flex flex-col gap-6">
      <div>
        <h1 className="text-2xl font-bold">Dose Analysis</h1>
        <p className="text-sm text-neutral-500">Weight loss and body-composition change broken down by Zepbound dose phase.</p>
      </div>

      <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
        <StatCard label="Current Dose" value={currentDoseMg !== null ? `${formatDoseMg(currentDoseMg)} mg` : "--"} />
        <StatCard label="Phases Tracked" value={phases.length.toString()} />
        <StatCard
          label="Best Phase"
          value={bestPhase ? `${formatDoseMg(bestPhase.doseMg)} mg` : "--"}
          accent="good"
          sub={bestPhase ? `${bestPhase.avgWeeklyLossLb.toFixed(1)} lb/wk avg` : undefined}
        />
        <StatCard
          label="Longest Phase"
          value={longestPhase ? `${formatDoseMg(longestPhase.doseMg)} mg` : "--"}
          sub={longestPhase ? `${longestPhase.weeks.toFixed(1)} weeks` : undefined}
        />
      </div>

      {phases.length > 0 ? (
        <ChartCard title="Loss by Dose Phase" description="Total and average weekly loss for each dose period">
          <DosePhaseChart
            data={phases.map((p) => ({
              phase: `${formatDoseMg(p.doseMg)}mg`,
              totalLossLb: p.totalLossLb,
              avgWeeklyLossLb: p.avgWeeklyLossLb,
            }))}
          />
        </ChartCard>
      ) : (
        <Card>
          <CardContent className="flex h-32 items-center justify-center text-sm text-neutral-500">
            Not enough data yet. Log dose records alongside weigh-ins to see phase analysis.
          </CardContent>
        </Card>
      )}

      <Card>
        <Table>
          <TableHeader>
            <TableRow>
              <TableHead>Dose</TableHead>
              <TableHead>Start Date</TableHead>
              <TableHead>End Date</TableHead>
              <TableHead>Duration</TableHead>
              <TableHead>Total Loss</TableHead>
              <TableHead>Avg Weekly Loss</TableHead>
              <TableHead>Body Fat % Change</TableHead>
              <TableHead>Lean Mass Change</TableHead>
            </TableRow>
          </TableHeader>
          <TableBody>
            {phaseRows.map(({ phase, composition }) => (
              <TableRow key={`${phase.doseMg}-${phase.startDate.toISOString()}`}>
                <TableCell>{formatDoseMg(phase.doseMg)} mg</TableCell>
                <TableCell>{formatDate(phase.startDate)}</TableCell>
                <TableCell>{formatDate(phase.endDate)}</TableCell>
                <TableCell>{phase.weeks.toFixed(1)} wk</TableCell>
                <TableCell>{phase.totalLossLb.toFixed(1)} lb</TableCell>
                <TableCell>{phase.avgWeeklyLossLb.toFixed(1)} lb/wk</TableCell>
                <TableCell>
                  {composition.bodyFatChange !== null
                    ? `${composition.bodyFatChange >= 0 ? "+" : ""}${composition.bodyFatChange.toFixed(1)}%`
                    : "--"}
                </TableCell>
                <TableCell>
                  {composition.leanMassChangeLb !== null
                    ? `${composition.leanMassChangeLb >= 0 ? "+" : ""}${composition.leanMassChangeLb.toFixed(1)} lb`
                    : "--"}
                </TableCell>
              </TableRow>
            ))}
            {phaseRows.length === 0 && (
              <TableRow>
                <TableCell colSpan={8} className="text-center text-sm text-neutral-500">
                  No dose phases found.
                </TableCell>
              </TableRow>
            )}
          </TableBody>
        </Table>
      </Card>
    </div>
  );
}
