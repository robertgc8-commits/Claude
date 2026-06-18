import { z } from "zod";

// FormData always yields strings (or File), so optional numeric fields need
// to coerce from string -> number themselves rather than relying on
// z.coerce, which expects the field to already be present.
const optionalNumber = z
  .union([z.string(), z.number()])
  .nullish()
  .transform((v) => {
    if (v === undefined || v === null || v === "") return null;
    const n = typeof v === "number" ? v : Number(v);
    return Number.isNaN(n) ? null : n;
  });

const optionalInt = optionalNumber.transform((n) => (n === null ? null : Math.round(n)));

const optionalString = z
  .union([z.string(), z.literal("")])
  .nullish()
  .transform((v) => (v === "" || v === undefined || v === null ? null : v));

// A handful of fields (multi-select muscle lists, per-set workout data,
// muscle-credit maps) are richer than a single form field can express, so
// the client serializes them to a JSON string and the server parses it back.
function jsonField<T extends z.ZodTypeAny>(schema: T, fallback: z.infer<T>) {
  return z
    .string()
    .nullish()
    .transform((v) => {
      if (!v) return fallback;
      try {
        return JSON.parse(v);
      } catch {
        return fallback;
      }
    })
    .pipe(schema);
}

export const bodyMeasurementSchema = z.object({
  date: z.string().min(1, "Date is required"),
  weight: z.coerce.number().positive("Weight must be positive"),
  bmi: optionalNumber,
  bodyFatPercent: optionalNumber,
  visceralFat: optionalNumber,
  subcutaneousFatPercent: optionalNumber,
  skeletalMusclePercent: optionalNumber,
  muscleMass: optionalNumber,
  fatFreeBodyWeight: optionalNumber,
  bodyWaterPercent: optionalNumber,
  proteinPercent: optionalNumber,
  boneMass: optionalNumber,
  bmr: optionalNumber,
  metabolicAge: optionalInt,
  waist: optionalNumber,
  notes: optionalString,
});
export type BodyMeasurementInput = z.input<typeof bodyMeasurementSchema>;

export const medicationDoseSchema = z.object({
  date: z.string().min(1, "Date is required"),
  doseMg: z.coerce.number().positive("Dose is required"),
  sideEffects: optionalString,
  appetiteLevel: optionalInt,
  hungerLevel: optionalInt,
  energyLevel: optionalInt,
  nauseaLevel: optionalInt,
  giSymptoms: optionalString,
  missed: z.coerce.boolean().optional().default(false),
  delayed: z.coerce.boolean().optional().default(false),
  notes: optionalString,
});
export type MedicationDoseInput = z.input<typeof medicationDoseSchema>;

export const exerciseSchema = z.object({
  name: z.string().min(1, "Name is required"),
  primaryMuscle: z.string().min(1, "Primary muscle is required"),
  secondaryMuscles: jsonField(z.array(z.string()), []),
  pattern: z.string().min(1),
  laterality: z.string().min(1),
  exerciseType: z.string().min(1),
  muscleSetCredits: jsonField(z.record(z.string(), z.number()), {}),
});
export type ExerciseInput = z.input<typeof exerciseSchema>;

export const workoutSetSchema = z.object({
  exerciseId: z.string().min(1, "Exercise is required"),
  weight: z.coerce.number().min(0),
  reps: z.coerce.number().int().min(1),
  rpe: optionalNumber,
  rir: optionalNumber,
  tempo: optionalString,
  restSeconds: optionalInt,
});

export const workoutSchema = z.object({
  date: z.string().min(1, "Date is required"),
  type: z.string().min(1),
  bodyweight: optionalNumber,
  notes: optionalString,
  sets: jsonField(z.array(workoutSetSchema), []),
});
export type WorkoutInput = z.input<typeof workoutSchema>;

export const nutritionLogSchema = z.object({
  date: z.string().min(1, "Date is required"),
  calories: optionalInt,
  proteinG: optionalNumber,
  carbsG: optionalNumber,
  fatG: optionalNumber,
  waterOz: optionalNumber,
  fiberG: optionalNumber,
  notes: optionalString,
});
export type NutritionLogInput = z.input<typeof nutritionLogSchema>;

export const goalSchema = z.object({
  label: z.string().min(1, "Label is required"),
  type: z.string().min(1),
  targetValue: z.coerce.number(),
  targetDate: optionalString,
  startValue: optionalNumber,
  startDate: optionalString,
  achieved: z.coerce.boolean().optional().default(false),
  notes: optionalString,
});
export type GoalInput = z.input<typeof goalSchema>;

export const recoveryLogSchema = z.object({
  date: z.string().min(1, "Date is required"),
  sleepHours: optionalNumber,
  recoveryRating: optionalInt,
  energyRating: optionalInt,
  sorenessRating: optionalInt,
  stressRating: optionalInt,
  notes: optionalString,
});
export type RecoveryLogInput = z.input<typeof recoveryLogSchema>;

export const weeklyCheckInSchema = z.object({
  date: z.string().min(1, "Date is required"),
  weight: z.coerce.number().positive(),
  bodyFatPercent: optionalNumber,
  muscleMass: optionalNumber,
  skeletalMusclePercent: optionalNumber,
  fatFreeBodyWeight: optionalNumber,
  visceralFat: optionalNumber,
  waist: optionalNumber,
  photosNote: optionalString,
  doseMg: optionalNumber,
  sideEffects: optionalString,
  hungerRating: optionalInt,
  energyRating: optionalInt,
  trainingConsistencyRating: optionalInt,
  proteinConsistencyRating: optionalInt,
  notes: optionalString,
});
export type WeeklyCheckInInput = z.input<typeof weeklyCheckInSchema>;
