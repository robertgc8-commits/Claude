import { PROFILE } from "./constants";

const LB_PER_KG = 0.45359237;
const DAY_MS = 86_400_000;

export interface DatedValue {
  date: Date;
  value: number;
}

// ---------------------------------------------------------------------------
// Body composition
// ---------------------------------------------------------------------------

/** Fat mass (lb) = body weight x body fat %. */
export function fatMass(weightLb: number, bodyFatPercent: number): number {
  return weightLb * (bodyFatPercent / 100);
}

/** Lean (fat-free) mass (lb) = body weight - fat mass. */
export function leanMass(weightLb: number, bodyFatPercent: number): number {
  return weightLb - fatMass(weightLb, bodyFatPercent);
}

/** FFMI = lean mass (kg) / height (m)^2. */
export function ffmi(leanMassLb: number, heightInches: number = PROFILE.heightInches): number {
  const leanKg = leanMassLb * LB_PER_KG;
  const heightM = heightInches * 0.0254;
  return leanKg / (heightM * heightM);
}

export function bmi(weightLb: number, heightInches: number = PROFILE.heightInches): number {
  return (weightLb / (heightInches * heightInches)) * 703;
}

// ---------------------------------------------------------------------------
// Strength
// ---------------------------------------------------------------------------

export interface OneRepMaxEstimate {
  epley: number;
  brzycki: number;
  lombardi: number;
  average: number;
}

/** Estimated 1RM using three common formulas, averaged for a consensus value. */
export function estimateOneRepMax(weight: number, reps: number): OneRepMaxEstimate {
  if (reps <= 0 || weight <= 0) return { epley: 0, brzycki: 0, lombardi: 0, average: 0 };
  const epley = weight * (1 + reps / 30);
  // Brzycki is undefined/unstable above ~36 reps; clamp to avoid blowing up.
  const brzycki = reps < 37 ? weight * (36 / (37 - reps)) : epley;
  const lombardi = weight * Math.pow(reps, 0.1);
  const average = (epley + brzycki + lombardi) / 3;
  return { epley, brzycki, lombardi, average };
}

export function volumeLoad(sets: { weight: number; reps: number }[]): number {
  return sets.reduce((sum, s) => sum + s.weight * s.reps, 0);
}

export function relativeVolumeLoad(totalVolume: number, bodyweightLb: number): number {
  if (!bodyweightLb) return 0;
  return totalVolume / bodyweightLb;
}

export function strengthToBodyweightRatio(estimatedOneRm: number, bodyweightLb: number): number {
  if (!bodyweightLb) return 0;
  return estimatedOneRm / bodyweightLb;
}

export function isHardSet(rpe: number | null | undefined, rir: number | null | undefined): boolean {
  if (rpe !== null && rpe !== undefined) return rpe >= 7;
  if (rir !== null && rir !== undefined) return rir <= 3;
  // No effort data recorded -- assume it counts (most logged working sets do).
  return true;
}

// ---------------------------------------------------------------------------
// Time series helpers
// ---------------------------------------------------------------------------

function sortByDate(series: DatedValue[]): DatedValue[] {
  return [...series].sort((a, b) => a.date.getTime() - b.date.getTime());
}

/** Trailing rolling average over a calendar-day window (default 7 days). */
export function rollingAverage(series: DatedValue[], windowDays = 7): DatedValue[] {
  const sorted = sortByDate(series);
  return sorted.map((point, i) => {
    const windowStart = point.date.getTime() - windowDays * DAY_MS;
    const inWindow = sorted.slice(0, i + 1).filter((p) => p.date.getTime() > windowStart);
    const avg = inWindow.reduce((s, p) => s + p.value, 0) / inWindow.length;
    return { date: point.date, value: avg };
  });
}

export interface TrendResult {
  slopePerDay: number;
  slopePerWeek: number;
  intercept: number;
  points: DatedValue[];
}

/** Ordinary least-squares linear trendline fit to a dated series. */
export function linearTrend(series: DatedValue[]): TrendResult {
  const sorted = sortByDate(series);
  if (sorted.length < 2) {
    return { slopePerDay: 0, slopePerWeek: 0, intercept: sorted[0]?.value ?? 0, points: sorted };
  }
  const t0 = sorted[0].date.getTime();
  const xs = sorted.map((p) => (p.date.getTime() - t0) / DAY_MS);
  const ys = sorted.map((p) => p.value);
  const n = xs.length;
  const sumX = xs.reduce((s, x) => s + x, 0);
  const sumY = ys.reduce((s, y) => s + y, 0);
  const sumXY = xs.reduce((s, x, i) => s + x * ys[i], 0);
  const sumXX = xs.reduce((s, x) => s + x * x, 0);
  const denom = n * sumXX - sumX * sumX;
  const slope = denom === 0 ? 0 : (n * sumXY - sumX * sumY) / denom;
  const intercept = (sumY - slope * sumX) / n;
  const points = sorted.map((p, i) => ({ date: p.date, value: intercept + slope * xs[i] }));
  return { slopePerDay: slope, slopePerWeek: slope * 7, intercept, points };
}

/** % change between the latest point and the nearest point >= `days` ago. Null if not enough history. */
export function percentChangeOverWindow(series: DatedValue[], days: number): number | null {
  const sorted = sortByDate(series);
  if (sorted.length < 2) return null;
  const latest = sorted[sorted.length - 1];
  const targetTime = latest.date.getTime() - days * DAY_MS;
  // Most recent point at or before the target time.
  let past: DatedValue | null = null;
  for (const p of sorted) {
    if (p.date.getTime() <= targetTime) past = p;
    else break;
  }
  if (!past || past.value === 0) return null;
  return ((latest.value - past.value) / past.value) * 100;
}

export function averageWeeklyRate(series: DatedValue[], windowDays: number): number | null {
  const sorted = sortByDate(series);
  if (sorted.length < 2) return null;
  const latest = sorted[sorted.length - 1];
  const cutoff = latest.date.getTime() - windowDays * DAY_MS;
  const inWindow = sorted.filter((p) => p.date.getTime() >= cutoff);
  if (inWindow.length < 2) return null;
  const first = inWindow[0];
  const days = (latest.date.getTime() - first.date.getTime()) / DAY_MS;
  if (days <= 0) return null;
  return ((first.value - latest.value) / days) * 7;
}

// ---------------------------------------------------------------------------
// Zepbound dose phases
// ---------------------------------------------------------------------------

export interface DoseRecord {
  date: Date;
  doseMg: number;
}

export interface DosePhase {
  doseMg: number;
  startDate: Date;
  endDate: Date;
  startWeight: number;
  endWeight: number;
  totalLossLb: number;
  days: number;
  weeks: number;
  avgWeeklyLossLb: number;
  measurementCount: number;
}

export function activeDoseForDate(doseRecords: DoseRecord[], date: Date): number | null {
  const sorted = [...doseRecords].sort((a, b) => a.date.getTime() - b.date.getTime());
  let active: number | null = null;
  for (const d of sorted) {
    if (d.date.getTime() <= date.getTime()) active = d.doseMg;
    else break;
  }
  return active;
}

export function buildDosePhases(
  measurements: { date: Date; weight: number }[],
  doseRecords: DoseRecord[]
): DosePhase[] {
  const sortedM = sortByDate(measurements.map((m) => ({ date: m.date, value: m.weight }))).map((p) => ({
    date: p.date,
    weight: p.value,
  }));
  const tagged = sortedM
    .map((m) => ({ ...m, dose: activeDoseForDate(doseRecords, m.date) }))
    .filter((m): m is { date: Date; weight: number; dose: number } => m.dose !== null);

  const phases: DosePhase[] = [];
  let group: typeof tagged = [];

  const flush = () => {
    if (group.length === 0) return;
    const start = group[0];
    const end = group[group.length - 1];
    const days = (end.date.getTime() - start.date.getTime()) / DAY_MS;
    const weeks = days / 7;
    const totalLossLb = start.weight - end.weight;
    phases.push({
      doseMg: start.dose,
      startDate: start.date,
      endDate: end.date,
      startWeight: start.weight,
      endWeight: end.weight,
      totalLossLb,
      days,
      weeks,
      avgWeeklyLossLb: weeks > 0 ? totalLossLb / weeks : 0,
      measurementCount: group.length,
    });
  };

  for (const m of tagged) {
    if (group.length === 0 || group[group.length - 1].dose === m.dose) {
      group.push(m);
    } else {
      flush();
      group = [m];
    }
  }
  flush();

  return phases;
}

// ---------------------------------------------------------------------------
// Goal projections
// ---------------------------------------------------------------------------

/** Body fat % at the goal weight assuming a given amount of lean mass is lost (0 = fully preserved). */
export function bodyFatPercentAtGoal(
  goalWeightLb: number,
  currentLeanMassLb: number,
  leanMassLossLb = 0
): number {
  const leanAtGoal = currentLeanMassLb - leanMassLossLb;
  const fatAtGoal = goalWeightLb - leanAtGoal;
  return (fatAtGoal / goalWeightLb) * 100;
}

export function estimateGoalDate(
  currentWeightLb: number,
  goalWeightLb: number,
  weeklyRateLb: number | null,
  fromDate: Date = new Date()
): Date | null {
  if (!weeklyRateLb || weeklyRateLb <= 0) return null;
  const remaining = currentWeightLb - goalWeightLb;
  if (remaining <= 0) return fromDate;
  const weeksNeeded = remaining / weeklyRateLb;
  const d = new Date(fromDate);
  d.setDate(d.getDate() + Math.round(weeksNeeded * 7));
  return d;
}

export function weeklyLossPercentOfBodyweight(weeklyLossLb: number, bodyweightLb: number): number {
  if (!bodyweightLb) return 0;
  return (weeklyLossLb / bodyweightLb) * 100;
}
