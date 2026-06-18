import { HYPERTROPHY_WEEKLY_SET_RANGE, MuscleGroup } from "./constants";
import { isHardSet } from "./calculations";

export interface SetWithExercise {
  weight: number;
  reps: number;
  rpe: number | null;
  rir: number | null;
  exercise: { muscleSetCredits: string };
}

export function parseMuscleSetCredits(muscleSetCreditsJson: string): Partial<Record<MuscleGroup, number>> {
  try {
    return JSON.parse(muscleSetCreditsJson);
  } catch {
    return {};
  }
}

export interface MuscleGroupTally {
  totalSets: number;
  hardSets: number;
}

/** Sum fractional set credit per muscle group across a collection of sets (e.g. one workout, one week). */
export function tallyMuscleVolume(sets: SetWithExercise[]): Record<string, MuscleGroupTally> {
  const tally: Record<string, MuscleGroupTally> = {};
  for (const set of sets) {
    const credits = parseMuscleSetCredits(set.exercise.muscleSetCredits);
    const hard = isHardSet(set.rpe, set.rir);
    for (const [muscle, credit] of Object.entries(credits)) {
      if (!tally[muscle]) tally[muscle] = { totalSets: 0, hardSets: 0 };
      tally[muscle].totalSets += credit ?? 0;
      if (hard) tally[muscle].hardSets += credit ?? 0;
    }
  }
  return tally;
}

export type VolumeClassification = "understimulated" | "optimal" | "excessive";

export function classifyWeeklyVolume(muscle: MuscleGroup, weeklyHardSets: number): VolumeClassification {
  const [low, high] = HYPERTROPHY_WEEKLY_SET_RANGE[muscle];
  if (weeklyHardSets < low) return "understimulated";
  if (weeklyHardSets > high) return "excessive";
  return "optimal";
}
