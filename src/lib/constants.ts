// Personal profile baseline. Editable here until a Settings page / multi-user
// auth is introduced -- the rest of the app reads from this single source.
export const PROFILE = {
  sex: "male" as const,
  age: 25,
  heightInches: 70, // 5'10"
  heightMeters: 70 * 0.0254,
  goalWeightLb: 180,
};

export const ZEPBOUND_DOSES = [2.5, 5, 7.5, 10, 12.5, 15] as const;
export type ZepboundDose = (typeof ZEPBOUND_DOSES)[number];

export const WORKOUT_TYPES = [
  "full_body",
  "upper",
  "lower",
  "push",
  "pull",
  "legs",
  "cardio",
  "custom",
] as const;
export type WorkoutType = (typeof WORKOUT_TYPES)[number];

export const WORKOUT_TYPE_LABELS: Record<WorkoutType, string> = {
  full_body: "Full Body",
  upper: "Upper",
  lower: "Lower",
  push: "Push",
  pull: "Pull",
  legs: "Legs",
  cardio: "Cardio",
  custom: "Custom",
};

export const MOVEMENT_PATTERNS = [
  "squat",
  "hinge",
  "horizontal_push",
  "horizontal_pull",
  "vertical_push",
  "vertical_pull",
  "carry",
  "core",
  "isolation",
] as const;
export type MovementPattern = (typeof MOVEMENT_PATTERNS)[number];

export const MOVEMENT_PATTERN_LABELS: Record<MovementPattern, string> = {
  squat: "Squat",
  hinge: "Hinge",
  horizontal_push: "Horizontal Push",
  horizontal_pull: "Horizontal Pull",
  vertical_push: "Vertical Push",
  vertical_pull: "Vertical Pull",
  carry: "Carry",
  core: "Core",
  isolation: "Isolation",
};

export const LATERALITIES = ["unilateral", "bilateral"] as const;
export type Laterality = (typeof LATERALITIES)[number];

export const EXERCISE_TYPES = ["compound", "isolation"] as const;
export type ExerciseTypeKind = (typeof EXERCISE_TYPES)[number];

export const MUSCLE_GROUPS = [
  "Chest",
  "Back",
  "Lats",
  "Traps",
  "Front Delts",
  "Side Delts",
  "Rear Delts",
  "Triceps",
  "Biceps",
  "Quads",
  "Hamstrings",
  "Glutes",
  "Calves",
  "Abs",
] as const;
export type MuscleGroup = (typeof MUSCLE_GROUPS)[number];

// Evidence-informed weekly hard-set landmarks per muscle group used to label
// volume as understimulated / optimal / excessive on the muscle group volume
// chart. These are deliberately generic ranges (most muscle groups respond
// well to roughly 10-20 weekly hard sets); a few smaller/easier-recovered
// groups get wider ranges.
export const HYPERTROPHY_WEEKLY_SET_RANGE: Record<MuscleGroup, [number, number]> = {
  Chest: [10, 20],
  Back: [10, 20],
  Lats: [10, 20],
  Traps: [8, 16],
  "Front Delts": [6, 14],
  "Side Delts": [10, 22],
  "Rear Delts": [8, 18],
  Triceps: [8, 18],
  Biceps: [8, 18],
  Quads: [10, 20],
  Hamstrings: [8, 16],
  Glutes: [8, 18],
  Calves: [8, 18],
  Abs: [8, 20],
};

// A "hard set" counts toward effective hypertrophy volume.
export const HARD_SET_RPE_THRESHOLD = 7;
export const HARD_SET_RIR_THRESHOLD = 3;

// Key lifts tracked on the Strength Preservation dashboard. Matched against
// Exercise.name (case-insensitive, substring-tolerant) -- see lib/strength.ts.
export const KEY_LIFTS = [
  "Bench Press",
  "Squat",
  "Deadlift",
  "Overhead Press",
  "Pull-Up",
  "Weighted Pull-Up",
  "Barbell Row",
] as const;

export const RATINGS = ["excellent", "good", "acceptable", "needs_attention", "high_risk"] as const;
export type Rating = (typeof RATINGS)[number];

export const RATING_LABELS: Record<Rating, string> = {
  excellent: "Excellent",
  good: "Good",
  acceptable: "Acceptable",
  needs_attention: "Needs Attention",
  high_risk: "High Risk",
};

export const SEVERITIES = ["info", "warning", "risk"] as const;
export type Severity = (typeof SEVERITIES)[number];

// Daily protein target -- ~1g/lb of goal bodyweight is a common high-protein
// recomposition target; used by the recommendation engine.
export const PROTEIN_TARGET_G = 180;

export const CONSERVATIVE_WEEKLY_LOSS_LB = 1.5;
