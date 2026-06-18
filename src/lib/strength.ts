import { KEY_LIFTS } from "./constants";
import { estimateOneRepMax, percentChangeOverWindow, volumeLoad, type DatedValue } from "./calculations";
import type { WorkoutWithSets } from "./insights";

export interface KeyLiftSessionPoint {
  date: string;
  topWeight: number;
  estimated1RM: number;
}

/** Per-session best set (by weight) for a lift, matched case-insensitively against Exercise.name. */
export function buildKeyLiftSeries(workouts: WorkoutWithSets[], liftName: string): KeyLiftSessionPoint[] {
  const points: KeyLiftSessionPoint[] = [];
  for (const w of workouts) {
    const matching = w.sets.filter((s) => s.exercise.name.toLowerCase() === liftName.toLowerCase());
    if (matching.length === 0) continue;
    const best = matching.reduce((a, b) => (b.weight > a.weight ? b : a));
    points.push({
      date: w.date.toISOString(),
      topWeight: best.weight,
      estimated1RM: estimateOneRepMax(best.weight, best.reps).average,
    });
  }
  return points.sort((a, b) => a.date.localeCompare(b.date));
}

export interface KeyLiftStatus {
  lift: string;
  hasData: boolean;
  current1RM: number | null;
  change30d: number | null;
  change60d: number | null;
  warning: "none" | "decline_30d" | "decline_60d";
}

const DECLINE_30D_THRESHOLD = -5; // % over 30 days
const DECLINE_60D_THRESHOLD = -10; // % over 60 days

export const STRENGTH_DECLINE_WARNING = "Potential muscle loss or recovery issue detected.";

export function buildKeyLiftStatuses(workouts: WorkoutWithSets[]): KeyLiftStatus[] {
  return KEY_LIFTS.map((lift) => {
    const series = buildKeyLiftSeries(workouts, lift);
    if (series.length === 0) {
      return { lift, hasData: false, current1RM: null, change30d: null, change60d: null, warning: "none" };
    }
    const dated: DatedValue[] = series.map((p) => ({ date: new Date(p.date), value: p.estimated1RM }));
    const change30d = percentChangeOverWindow(dated, 30);
    const change60d = percentChangeOverWindow(dated, 60);
    let warning: KeyLiftStatus["warning"] = "none";
    if (change60d !== null && change60d <= DECLINE_60D_THRESHOLD) warning = "decline_60d";
    else if (change30d !== null && change30d <= DECLINE_30D_THRESHOLD) warning = "decline_30d";
    return {
      lift,
      hasData: true,
      current1RM: dated[dated.length - 1].value,
      change30d,
      change60d,
      warning,
    };
  });
}

export interface WeeklyVolumeTrendPoint {
  weekStart: string;
  volumeLoad: number;
}

/** Total volume load grouped into calendar weeks (Mon-start), for spotting recovery-driven volume drop-off. */
export function buildWeeklyVolumeTrend(workouts: WorkoutWithSets[]): WeeklyVolumeTrendPoint[] {
  const DAY_MS = 86_400_000;
  const byWeek = new Map<string, number>();
  for (const w of workouts) {
    const d = new Date(w.date);
    const day = d.getDay();
    const diff = day === 0 ? -6 : 1 - day;
    const monday = new Date(d.getTime() + diff * DAY_MS);
    const key = monday.toISOString().slice(0, 10);
    byWeek.set(key, (byWeek.get(key) ?? 0) + volumeLoad(w.sets));
  }
  return [...byWeek.entries()].sort(([a], [b]) => a.localeCompare(b)).map(([weekStart, vol]) => ({ weekStart, volumeLoad: vol }));
}
