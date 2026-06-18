import type { BodyMeasurement, MedicationDose, NutritionLog, RecoveryLog, Goal } from "@prisma/client";
import {
  activeDoseForDate,
  averageWeeklyRate,
  buildDosePhases,
  estimateOneRepMax,
  fatMass,
  ffmi,
  isHardSet,
  leanMass,
  percentChangeOverWindow,
  volumeLoad,
  weeklyLossPercentOfBodyweight,
  type DatedValue,
} from "./calculations";
import { tallyMuscleVolume } from "./muscleVolume";
import { KEY_LIFTS, PROTEIN_TARGET_G, type Rating } from "./constants";

const DAY_MS = 86_400_000;

export type WorkoutWithSets = {
  id: string;
  date: Date;
  type: string;
  bodyweight: number | null;
  sets: {
    weight: number;
    reps: number;
    rpe: number | null;
    rir: number | null;
    exercise: { name: string; muscleSetCredits: string };
  }[];
};

export interface ReportInputs {
  measurements: BodyMeasurement[];
  doses: MedicationDose[];
  workouts: WorkoutWithSets[];
  nutrition: NutritionLog[];
  recovery: RecoveryLog[];
  goal: Goal | null;
}

export interface InsightItem {
  category: string;
  severity: "info" | "warning" | "risk";
  metric: string;
  explanation: string;
  suggestedAction: string | null;
}

export interface RecommendationItem {
  category: string;
  message: string;
  priority: "low" | "medium" | "high";
}

function withinWindow(date: Date, asOf: Date, days: number, fromDays = 0): boolean {
  const end = asOf.getTime() - fromDays * DAY_MS;
  const start = asOf.getTime() - days * DAY_MS;
  const t = date.getTime();
  return t <= end && t > start;
}

function nearestAtOrBefore<T extends { date: Date }>(items: T[], target: Date): T | null {
  let result: T | null = null;
  for (const item of items) {
    if (item.date.getTime() <= target.getTime()) result = item;
    else break;
  }
  return result;
}

function avg(nums: number[]): number | null {
  if (nums.length === 0) return null;
  return nums.reduce((s, n) => s + n, 0) / nums.length;
}

function keyLiftSeries(workouts: WorkoutWithSets[], liftName: string): DatedValue[] {
  const series: DatedValue[] = [];
  for (const w of workouts) {
    const matchingSets = w.sets.filter((s) => s.exercise.name.toLowerCase() === liftName.toLowerCase());
    if (matchingSets.length === 0) continue;
    const best = Math.max(...matchingSets.map((s) => estimateOneRepMax(s.weight, s.reps).average));
    series.push({ date: w.date, value: best });
  }
  return series.sort((a, b) => a.date.getTime() - b.date.getTime());
}

export interface WeeklySummary {
  weight: {
    current: number | null;
    changeFromLastWeek: number | null;
    changeFromFourWeeksAgo: number | null;
    totalLossFromStart: number | null;
    currentDoseMg: number | null;
    daysOnCurrentDose: number | null;
  };
  bodyComposition: {
    fatMassLb: number | null;
    leanMassLb: number | null;
    muscleMassLb: number | null;
    bodyFatPercent: number | null;
    ffmi: number | null;
    fatMassChangeLb: number | null;
    leanMassChangeLb: number | null;
  };
  training: {
    workoutsThisWeek: number;
    totalVolumeLoad: number;
    hardSetsByMuscle: Record<string, number>;
    keyLiftOneRm: Record<string, number | null>;
    keyLiftChange30d: Record<string, number | null>;
  };
  nutrition: {
    avgCalories: number | null;
    avgProtein: number | null;
    proteinTargetHitRate: number | null;
    avgWaterOz: number | null;
    avgFiber: number | null;
  };
  zepbound: {
    currentDoseMg: number | null;
    appetiteTrend: number | null;
    sideEffectTrend: number | null;
    dosePhases: ReturnType<typeof buildDosePhases>;
  };
}

export function buildWeeklySummary(inputs: ReportInputs, asOf: Date): WeeklySummary {
  const { measurements, doses, workouts, nutrition, goal } = inputs;

  const weightSeries: DatedValue[] = measurements.map((m) => ({ date: m.date, value: m.weight }));
  const current = nearestAtOrBefore(measurements, asOf);
  const weekAgo = nearestAtOrBefore(measurements, new Date(asOf.getTime() - 7 * DAY_MS));
  const fourWeekAgo = nearestAtOrBefore(measurements, new Date(asOf.getTime() - 28 * DAY_MS));
  const start = measurements[0] ?? null;

  const currentDoseMg = activeDoseForDate(doses, asOf);
  let doseStartDate: Date | null = null;
  {
    let lastDose: number | null = null;
    for (const d of doses) {
      if (d.date.getTime() > asOf.getTime()) break;
      if (d.doseMg !== lastDose) doseStartDate = d.date;
      lastDose = d.doseMg;
    }
  }

  const latestComp = [...measurements].filter((m) => m.bodyFatPercent !== null && m.date.getTime() <= asOf.getTime()).pop() ?? null;
  const priorComp =
    [...measurements]
      .filter((m) => m.bodyFatPercent !== null && m.date.getTime() < (latestComp?.date.getTime() ?? 0))
      .pop() ?? null;

  const fatNow = latestComp ? fatMass(latestComp.weight, latestComp.bodyFatPercent!) : null;
  const leanNow = latestComp ? leanMass(latestComp.weight, latestComp.bodyFatPercent!) : null;
  const fatPrior = priorComp ? fatMass(priorComp.weight, priorComp.bodyFatPercent!) : null;
  const leanPrior = priorComp ? leanMass(priorComp.weight, priorComp.bodyFatPercent!) : null;

  const weekWorkouts = workouts.filter((w) => withinWindow(w.date, asOf, 7));
  const allSetsThisWeek = weekWorkouts.flatMap((w) => w.sets);
  const totalVolumeLoad = volumeLoad(allSetsThisWeek);
  const muscleTally = tallyMuscleVolume(allSetsThisWeek);
  const hardSetsByMuscle: Record<string, number> = {};
  for (const [muscle, t] of Object.entries(muscleTally)) hardSetsByMuscle[muscle] = Math.round(t.hardSets * 100) / 100;

  const keyLiftOneRm: Record<string, number | null> = {};
  const keyLiftChange30d: Record<string, number | null> = {};
  for (const lift of KEY_LIFTS) {
    const series = keyLiftSeries(workouts, lift);
    const latest = series.length ? series[series.length - 1].value : null;
    keyLiftOneRm[lift] = latest;
    keyLiftChange30d[lift] = percentChangeOverWindow(series, 30);
  }

  const weekNutrition = nutrition.filter((n) => withinWindow(n.date, asOf, 7));
  const proteinValues = weekNutrition.map((n) => n.proteinG).filter((v): v is number => v !== null);
  const daysHittingTarget = proteinValues.filter((v) => v >= PROTEIN_TARGET_G).length;

  const doseHistory = doses.filter((d) => d.date.getTime() <= asOf.getTime());
  const latestDose = doseHistory[doseHistory.length - 1] ?? null;
  const priorDose = doseHistory[doseHistory.length - 2] ?? null;

  return {
    weight: {
      current: current?.weight ?? null,
      changeFromLastWeek: current && weekAgo ? weekAgo.weight - current.weight : null,
      changeFromFourWeeksAgo: current && fourWeekAgo ? fourWeekAgo.weight - current.weight : null,
      totalLossFromStart: current && start ? start.weight - current.weight : null,
      currentDoseMg,
      daysOnCurrentDose: doseStartDate ? Math.round((asOf.getTime() - doseStartDate.getTime()) / DAY_MS) : null,
    },
    bodyComposition: {
      fatMassLb: fatNow,
      leanMassLb: leanNow,
      muscleMassLb: latestComp?.muscleMass ?? null,
      bodyFatPercent: latestComp?.bodyFatPercent ?? null,
      ffmi: leanNow ? ffmi(leanNow) : null,
      fatMassChangeLb: fatNow !== null && fatPrior !== null ? fatPrior - fatNow : null,
      leanMassChangeLb: leanNow !== null && leanPrior !== null ? leanNow - leanPrior : null,
    },
    training: {
      workoutsThisWeek: weekWorkouts.length,
      totalVolumeLoad,
      hardSetsByMuscle,
      keyLiftOneRm,
      keyLiftChange30d,
    },
    nutrition: {
      avgCalories: avg(weekNutrition.map((n) => n.calories).filter((v): v is number => v !== null)),
      avgProtein: avg(proteinValues),
      proteinTargetHitRate: weekNutrition.length ? (daysHittingTarget / weekNutrition.length) * 100 : null,
      avgWaterOz: avg(weekNutrition.map((n) => n.waterOz).filter((v): v is number => v !== null)),
      avgFiber: avg(weekNutrition.map((n) => n.fiberG).filter((v): v is number => v !== null)),
    },
    zepbound: {
      currentDoseMg,
      appetiteTrend:
        latestDose?.appetiteLevel !== undefined && priorDose?.appetiteLevel !== undefined && latestDose && priorDose
          ? (latestDose.appetiteLevel ?? 0) - (priorDose.appetiteLevel ?? 0)
          : null,
      sideEffectTrend:
        latestDose && priorDose ? (latestDose.nauseaLevel ?? 0) - (priorDose.nauseaLevel ?? 0) : null,
      dosePhases: buildDosePhases(weightSeries.map((p) => ({ date: p.date, weight: p.value })), doses),
    },
  };
}

export function generateInsightsAndRecommendations(
  inputs: ReportInputs,
  summary: WeeklySummary,
  asOf: Date
): { insights: InsightItem[]; recommendations: RecommendationItem[] } {
  const insights: InsightItem[] = [];
  const recommendations: RecommendationItem[] = [];
  const { measurements, doses, workouts, recovery } = inputs;

  const weightSeries: DatedValue[] = measurements.map((m) => ({ date: m.date, value: m.weight }));
  const recentWeeklyRate = averageWeeklyRate(weightSeries, 7);
  const priorWeeklyRate = averageWeeklyRate(
    weightSeries.filter((p) => p.date.getTime() <= asOf.getTime() - 7 * DAY_MS),
    7
  );

  // 1. Accelerating / slowing / plateau.
  if (recentWeeklyRate !== null && priorWeeklyRate !== null) {
    if (recentWeeklyRate > priorWeeklyRate + 0.5) {
      insights.push({
        category: "weight_trend",
        severity: "info",
        metric: "Weekly loss rate",
        explanation: `Your weight loss rate increased from ${priorWeeklyRate.toFixed(1)} lb/week to ${recentWeeklyRate.toFixed(1)} lb/week.`,
        suggestedAction: null,
      });
    } else if (recentWeeklyRate < priorWeeklyRate - 0.5) {
      insights.push({
        category: "weight_trend",
        severity: "info",
        metric: "Weekly loss rate",
        explanation: `Your 4-week average loss rate has slowed from ${priorWeeklyRate.toFixed(1)} lb/week to ${recentWeeklyRate.toFixed(1)} lb/week, which is expected as body weight drops.`,
        suggestedAction: null,
      });
    }
  }
  if (recentWeeklyRate !== null && Math.abs(recentWeeklyRate) < 0.25) {
    insights.push({
      category: "weight_trend",
      severity: "warning",
      metric: "Plateau risk",
      explanation: "Scale weight has barely moved over the last week. This may be a plateau or water-retention noise.",
      suggestedAction: "Hold steady for another week before changing calories -- check waist/body fat trend too.",
    });
  }

  // 2. Lean mass / muscle mass trend (>1%/month warning).
  const leanSeries: DatedValue[] = measurements
    .filter((m) => m.fatFreeBodyWeight !== null)
    .map((m) => ({ date: m.date, value: m.fatFreeBodyWeight! }));
  const leanChangePct = percentChangeOverWindow(leanSeries, 30);
  if (leanChangePct !== null) {
    if (leanChangePct < -1) {
      insights.push({
        category: "lean_mass",
        severity: "risk",
        metric: "Lean mass (30-day change)",
        explanation: `Fat-free mass dropped ${Math.abs(leanChangePct).toFixed(1)}% over the last 30 days, above the 1%/month caution threshold.`,
        suggestedAction: "Prioritize protein and resistance training volume; consider a smaller deficit.",
      });
    } else if (leanChangePct > -0.3) {
      insights.push({
        category: "lean_mass",
        severity: "info",
        metric: "Lean mass (30-day change)",
        explanation: "Lean mass has remained essentially stable over the last month -- strong sign of fat-focused weight loss.",
        suggestedAction: null,
      });
    }
  }

  const muscleSeries: DatedValue[] = measurements
    .filter((m) => m.muscleMass !== null)
    .map((m) => ({ date: m.date, value: m.muscleMass! }));
  const muscleChangePct = percentChangeOverWindow(muscleSeries, 30);
  if (muscleChangePct !== null && muscleChangePct > -1) {
    insights.push({
      category: "lean_mass",
      severity: "info",
      metric: "Muscle mass",
      explanation: "Muscle mass is holding steady despite the weight loss.",
      suggestedAction: null,
    });
  }

  // 3. Body fat dropping faster than scale weight (recomposition signal).
  const bfSeries: DatedValue[] = measurements
    .filter((m) => m.bodyFatPercent !== null)
    .map((m) => ({ date: m.date, value: m.bodyFatPercent! }));
  const bfChangePct = percentChangeOverWindow(bfSeries, 30);
  const weightChangePct = percentChangeOverWindow(weightSeries, 30);
  if (bfChangePct !== null && weightChangePct !== null && bfChangePct < weightChangePct - 1) {
    insights.push({
      category: "body_composition",
      severity: "info",
      metric: "Body fat % vs scale weight",
      explanation: "Body fat % is decreasing faster than scale weight -- a strong body recomposition signal.",
      suggestedAction: null,
    });
  }

  // 4. Strength stable / declining.
  const liftChanges = Object.entries(summary.training.keyLiftChange30d).filter(([, v]) => v !== null) as [
    string,
    number,
  ][];
  const decliningLifts = liftChanges.filter(([, v]) => v <= -5);
  if (decliningLifts.length > 0) {
    for (const [lift, change] of decliningLifts) {
      insights.push({
        category: "strength",
        severity: "risk",
        metric: `${lift} estimated 1RM`,
        explanation: `${lift} estimated 1RM is down ${Math.abs(change).toFixed(1)}% over 30 days. This may indicate recovery or lean-mass preservation issues. Potential muscle loss or recovery issue detected.`,
        suggestedAction: "Reduce deficit slightly or add one higher-calorie training day around this lift.",
      });
    }
  } else if (liftChanges.length > 0 && liftChanges.every(([, v]) => Math.abs(v) <= 3)) {
    insights.push({
      category: "strength",
      severity: "info",
      metric: "Key lifts",
      explanation: "Strength is stable across key lifts despite ongoing weight loss.",
      suggestedAction: null,
    });
  }

  // 5. Protein below target.
  if (summary.nutrition.avgProtein !== null && summary.nutrition.avgProtein < PROTEIN_TARGET_G) {
    insights.push({
      category: "nutrition",
      severity: "warning",
      metric: "Average protein",
      explanation: `Your protein average was ${Math.round(summary.nutrition.avgProtein)} g/day against a ${PROTEIN_TARGET_G} g target. This increases risk of lean-mass loss.`,
      suggestedAction: "Add a protein source to breakfast and one snack to close the gap.",
    });
  }

  // 6. Weight loss rate too aggressive (multiple weeks above 1.5% bodyweight/week).
  if (summary.weight.current && summary.weight.changeFromLastWeek !== null) {
    const pct = weeklyLossPercentOfBodyweight(summary.weight.changeFromLastWeek, summary.weight.current);
    const weeksAggressive = [0, 7, 14].filter((offset) => {
      const w = nearestAtOrBefore(measurements, new Date(asOf.getTime() - offset * DAY_MS));
      const wPrev = nearestAtOrBefore(measurements, new Date(asOf.getTime() - (offset + 7) * DAY_MS));
      if (!w || !wPrev) return false;
      return weeklyLossPercentOfBodyweight(wPrev.weight - w.weight, w.weight) > 1.5;
    }).length;
    if (pct > 1.5 && weeksAggressive >= 2) {
      insights.push({
        category: "weight_trend",
        severity: "warning",
        metric: "Weekly loss rate (% bodyweight)",
        explanation: `Your weight loss rate is above 1.5% of body weight per week for multiple weeks (currently ${pct.toFixed(1)}%/week). Monitor strength and protein closely.`,
        suggestedAction: "Consider easing the deficit slightly to protect lean mass.",
      });
    }
  }

  // 7. Dose escalation + side effects.
  const recentDoseChange = doses.filter((d) => withinWindow(d.date, asOf, 14)).length > 0 &&
    summary.zepbound.currentDoseMg !== null &&
    doses.some((d) => d.date.getTime() < asOf.getTime() - 14 * DAY_MS && d.doseMg < (summary.zepbound.currentDoseMg ?? 0));
  if (recentDoseChange && summary.zepbound.sideEffectTrend !== null && summary.zepbound.sideEffectTrend > 0) {
    insights.push({
      category: "dose",
      severity: "warning",
      metric: "Side effects after dose escalation",
      explanation: "Side effects (nausea/GI) increased after the recent dose escalation.",
      suggestedAction: "Track hydration, fiber, meal size, and nausea. Flag this dose phase for review.",
    });
    recommendations.push({
      category: "dose",
      message: "Track hydration, fiber, meal size, and nausea. Flag this dose phase for review.",
      priority: "medium",
    });
  }

  // 8. Training consistency.
  const recentWorkouts = workouts.filter((w) => withinWindow(w.date, asOf, 14)).length;
  const priorWorkouts = workouts.filter((w) => withinWindow(w.date, asOf, 28, 14)).length;
  if (recentWorkouts > priorWorkouts) {
    insights.push({
      category: "training",
      severity: "info",
      metric: "Training consistency",
      explanation: "Training consistency is improving compared to the prior two weeks.",
      suggestedAction: null,
    });
  } else if (recentWorkouts < priorWorkouts) {
    insights.push({
      category: "training",
      severity: "warning",
      metric: "Training consistency",
      explanation: "Training consistency has dropped compared to the prior two weeks.",
      suggestedAction: null,
    });
  }
  if (summary.training.workoutsThisWeek < 2) {
    recommendations.push({
      category: "training",
      message: "Prioritize two full-body sessions minimum this week to preserve lean mass.",
      priority: "high",
    });
  }

  // 9. Recovery affecting performance.
  const recentRecovery = recovery.filter((r) => withinWindow(r.date, asOf, 7));
  const avgRecovery = avg(recentRecovery.map((r) => r.recoveryRating).filter((v): v is number => v !== null));
  if (avgRecovery !== null && avgRecovery < 5 && decliningLifts.length > 0) {
    insights.push({
      category: "recovery",
      severity: "warning",
      metric: "Recovery rating",
      explanation: "Low recovery ratings this week line up with declining strength -- recovery may be a bigger factor than the deficit itself.",
      suggestedAction: "Prioritize sleep and consider a lighter training day.",
    });
  }

  // Recommendation: lean mass dropping + protein low.
  if (leanChangePct !== null && leanChangePct < -1 && summary.nutrition.avgProtein !== null && summary.nutrition.avgProtein < PROTEIN_TARGET_G) {
    recommendations.push({
      category: "lean_mass",
      message: "Increase protein target compliance before increasing cardio or cutting calories further.",
      priority: "high",
    });
  }

  // Recommendation: strength dropping + weight loss fast.
  if (decliningLifts.length > 0 && summary.weight.current && summary.weight.changeFromLastWeek !== null) {
    const pct = weeklyLossPercentOfBodyweight(summary.weight.changeFromLastWeek, summary.weight.current);
    if (pct > 1.2) {
      recommendations.push({
        category: "strength",
        message: "Reduce deficit slightly or add one higher-calorie training day.",
        priority: "high",
      });
    }
  }

  // Recommendation: weight flat but body fat dropping -> recomposition.
  if (
    summary.weight.changeFromLastWeek !== null &&
    Math.abs(summary.weight.changeFromLastWeek) < 0.3 &&
    bfChangePct !== null &&
    bfChangePct < -0.5
  ) {
    recommendations.push({
      category: "body_composition",
      message: "Do not treat this as a failed week. Body recomposition may be occurring.",
      priority: "low",
    });
  }

  return { insights, recommendations };
}

export function computeOverallRating(insights: InsightItem[]): Rating {
  let score = 100;
  for (const insight of insights) {
    if (insight.severity === "risk") score -= 25;
    else if (insight.severity === "warning") score -= 10;
  }
  if (score >= 90) return "excellent";
  if (score >= 75) return "good";
  if (score >= 60) return "acceptable";
  if (score >= 40) return "needs_attention";
  return "high_risk";
}

export type MuscleRetentionRating = "excellent" | "good" | "moderate_risk" | "high_risk";

export interface MuscleRetentionScore {
  score: number; // 0-100
  rating: MuscleRetentionRating;
  breakdown: {
    leanMass: number;
    muscleMass: number;
    strength: number;
    consistency: number;
    protein: number;
  };
}

// Weighted composite: lean mass trend matters most for "is this fat loss or
// muscle loss", strength trend is the most sensitive early-warning signal,
// consistency/protein are leading indicators rather than outcomes -- hence
// the smaller weights.
function bucketScore(changePct: number | null, thresholds: [number, number], max: number, nullScore: number): number {
  if (changePct === null) return nullScore;
  const [mild, severe] = thresholds;
  if (changePct >= mild) return max;
  if (changePct >= severe) return max * 0.5;
  return 0;
}

export function computeMuscleRetentionScore(
  inputs: ReportInputs,
  summary: WeeklySummary,
  asOf: Date
): MuscleRetentionScore {
  const { measurements, workouts } = inputs;

  const leanSeries: DatedValue[] = measurements
    .filter((m) => m.fatFreeBodyWeight !== null)
    .map((m) => ({ date: m.date, value: m.fatFreeBodyWeight! }));
  const leanChangePct = percentChangeOverWindow(leanSeries, 30);

  const muscleSeries: DatedValue[] = measurements
    .filter((m) => m.muscleMass !== null)
    .map((m) => ({ date: m.date, value: m.muscleMass! }));
  const muscleChangePct = percentChangeOverWindow(muscleSeries, 30);

  const liftChanges = Object.values(summary.training.keyLiftChange30d).filter((v): v is number => v !== null);
  const avgStrengthChangePct = liftChanges.length ? avg(liftChanges) : null;

  const recentWorkouts = workouts.filter((w) => withinWindow(w.date, asOf, 28));
  const workoutsPerWeek = recentWorkouts.length / 4;

  const leanMass = bucketScore(leanChangePct, [-0.3, -2], 30, 15);
  const muscleMass = bucketScore(muscleChangePct, [-0.5, -1.5], 20, 10);
  const strength = bucketScore(avgStrengthChangePct, [-2, -10], 25, 12);
  const consistency = workoutsPerWeek >= 3 ? 15 : workoutsPerWeek >= 2 ? 10 : workoutsPerWeek >= 1 ? 5 : 0;
  const protein =
    summary.nutrition.avgProtein === null
      ? 5
      : summary.nutrition.avgProtein >= PROTEIN_TARGET_G
        ? 10
        : summary.nutrition.avgProtein >= PROTEIN_TARGET_G * 0.8
          ? 6
          : 0;

  const score = leanMass + muscleMass + strength + consistency + protein;
  const rating: MuscleRetentionRating = score >= 85 ? "excellent" : score >= 65 ? "good" : score >= 40 ? "moderate_risk" : "high_risk";

  return { score, rating, breakdown: { leanMass, muscleMass, strength, consistency, protein } };
}

export { isHardSet };
