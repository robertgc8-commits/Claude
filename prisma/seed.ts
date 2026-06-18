import { PrismaClient } from "@prisma/client";

const prisma = new PrismaClient();

const DAY_MS = 86_400_000;
const HEIGHT_INCHES = 70;

function bmiOf(weightLb: number): number {
  return (weightLb / (HEIGHT_INCHES * HEIGHT_INCHES)) * 703;
}

function addDays(date: Date, days: number): Date {
  return new Date(date.getTime() + days * DAY_MS);
}

function mondayOf(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay(); // 0=Sun..6=Sat
  const diff = day === 0 ? -6 : 1 - day;
  return addDays(d, diff);
}

// ---------------------------------------------------------------------------
// Historical weigh-ins (date, weight, dose active that week)
// ---------------------------------------------------------------------------
const WEIGH_INS: { date: string; weight: number; dose: number }[] = [
  { date: "2026-04-01", weight: 256.0, dose: 2.5 },
  { date: "2026-04-08", weight: 251.3, dose: 2.5 },
  { date: "2026-04-16", weight: 244.8, dose: 2.5 },
  { date: "2026-04-22", weight: 242.8, dose: 2.5 },
  { date: "2026-04-29", weight: 238.0, dose: 5.0 },
  { date: "2026-05-06", weight: 236.2, dose: 5.0 },
  { date: "2026-05-11", weight: 233.4, dose: 5.0 },
  { date: "2026-05-20", weight: 228.6, dose: 5.0 },
  { date: "2026-05-27", weight: 225.7, dose: 7.5 },
  { date: "2026-06-01", weight: 223.9, dose: 7.5 },
  { date: "2026-06-10", weight: 219.7, dose: 7.5 },
  { date: "2026-06-17", weight: 216.6, dose: 7.5 },
];

// Full body-composition scans exist for two dates; the rest are weight-only
// (matches what a smart scale / clinic visit realistically captures).
const FULL_COMPOSITION: Record<string, Record<string, number>> = {
  "2026-04-22": {
    bmi: 34.8,
    bodyFatPercent: 32.6,
    visceralFat: 17,
    subcutaneousFatPercent: 27.7,
    skeletalMusclePercent: 43.5,
    proteinPercent: 15.3,
    fatFreeBodyWeight: 163.6,
    boneMass: 8.2,
    bmr: 2271,
    muscleMass: 155.3,
    bodyWaterPercent: 48.6,
  },
  "2026-06-17": {
    bmi: 31.0,
    bodyFatPercent: 26.8,
    visceralFat: 13,
    subcutaneousFatPercent: 22.9,
    skeletalMusclePercent: 47.2,
    proteinPercent: 16.6,
    fatFreeBodyWeight: 158.5,
    boneMass: 7.9,
    bmr: 2111,
    muscleMass: 150.4,
    bodyWaterPercent: 52.8,
  },
};

// Linear interpolation across the known weigh-ins, used to give every
// generated workout a realistic bodyweight even on days between weigh-ins.
function interpolateWeight(date: Date): number {
  const points = WEIGH_INS.map((w) => ({ t: new Date(w.date).getTime(), v: w.weight }));
  const t = date.getTime();
  if (t <= points[0].t) return points[0].v;
  if (t >= points[points.length - 1].t) return points[points.length - 1].v;
  for (let i = 0; i < points.length - 1; i++) {
    const a = points[i];
    const b = points[i + 1];
    if (t >= a.t && t <= b.t) {
      const frac = (t - a.t) / (b.t - a.t);
      return a.v + (b.v - a.v) * frac;
    }
  }
  return points[points.length - 1].v;
}

// Weekly Zepbound injections -- matches the dose active for each weigh-in
// above, on a clean weekly cadence.
const MEDICATION_DOSES: { date: string; doseMg: number; nausea: number; appetite: number; hunger: number; energy: number }[] = [
  { date: "2026-04-01", doseMg: 2.5, nausea: 3, appetite: 4, hunger: 5, energy: 6 },
  { date: "2026-04-08", doseMg: 2.5, nausea: 2, appetite: 4, hunger: 5, energy: 6 },
  { date: "2026-04-15", doseMg: 2.5, nausea: 1, appetite: 3, hunger: 4, energy: 7 },
  { date: "2026-04-22", doseMg: 2.5, nausea: 1, appetite: 3, hunger: 4, energy: 7 },
  { date: "2026-04-29", doseMg: 5.0, nausea: 4, appetite: 2, hunger: 3, energy: 6 },
  { date: "2026-05-06", doseMg: 5.0, nausea: 3, appetite: 2, hunger: 3, energy: 6 },
  { date: "2026-05-13", doseMg: 5.0, nausea: 2, appetite: 2, hunger: 3, energy: 7 },
  { date: "2026-05-20", doseMg: 5.0, nausea: 1, appetite: 2, hunger: 2, energy: 7 },
  { date: "2026-05-27", doseMg: 7.5, nausea: 4, appetite: 2, hunger: 2, energy: 6 },
  { date: "2026-06-03", doseMg: 7.5, nausea: 3, appetite: 1, hunger: 2, energy: 6 },
  { date: "2026-06-10", doseMg: 7.5, nausea: 2, appetite: 1, hunger: 2, energy: 7 },
  { date: "2026-06-17", doseMg: 7.5, nausea: 1, appetite: 1, hunger: 2, energy: 7 },
];

const EXERCISES = [
  {
    name: "Bench Press",
    primaryMuscle: "Chest",
    secondaryMuscles: ["Front Delts", "Triceps"],
    pattern: "horizontal_push",
    laterality: "bilateral",
    exerciseType: "compound",
    muscleSetCredits: { Chest: 1.0, "Front Delts": 0.5, Triceps: 0.5 },
  },
  {
    name: "Squat",
    primaryMuscle: "Quads",
    secondaryMuscles: ["Glutes", "Abs"],
    pattern: "squat",
    laterality: "bilateral",
    exerciseType: "compound",
    muscleSetCredits: { Quads: 1.0, Glutes: 0.5, Abs: 0.25 },
  },
  {
    name: "Deadlift",
    primaryMuscle: "Hamstrings",
    secondaryMuscles: ["Glutes", "Back", "Traps"],
    pattern: "hinge",
    laterality: "bilateral",
    exerciseType: "compound",
    muscleSetCredits: { Hamstrings: 1.0, Glutes: 0.75, Back: 0.5, Traps: 0.5 },
  },
  {
    name: "Overhead Press",
    primaryMuscle: "Front Delts",
    secondaryMuscles: ["Side Delts", "Triceps"],
    pattern: "vertical_push",
    laterality: "bilateral",
    exerciseType: "compound",
    muscleSetCredits: { "Front Delts": 1.0, "Side Delts": 0.5, Triceps: 0.5 },
  },
  {
    name: "Pull-Up",
    primaryMuscle: "Lats",
    secondaryMuscles: ["Back", "Biceps"],
    pattern: "vertical_pull",
    laterality: "bilateral",
    exerciseType: "compound",
    muscleSetCredits: { Lats: 1.0, Back: 0.5, Biceps: 0.5 },
  },
  {
    name: "Weighted Pull-Up",
    primaryMuscle: "Lats",
    secondaryMuscles: ["Back", "Biceps"],
    pattern: "vertical_pull",
    laterality: "bilateral",
    exerciseType: "compound",
    muscleSetCredits: { Lats: 1.0, Back: 0.5, Biceps: 0.5 },
  },
  {
    name: "Barbell Row",
    primaryMuscle: "Back",
    secondaryMuscles: ["Lats", "Biceps"],
    pattern: "horizontal_pull",
    laterality: "bilateral",
    exerciseType: "compound",
    muscleSetCredits: { Back: 1.0, Lats: 0.5, Biceps: 0.5 },
  },
  {
    name: "Romanian Deadlift",
    primaryMuscle: "Hamstrings",
    secondaryMuscles: ["Glutes"],
    pattern: "hinge",
    laterality: "bilateral",
    exerciseType: "compound",
    muscleSetCredits: { Hamstrings: 1.0, Glutes: 0.5 },
  },
  {
    name: "Walking Lunge",
    primaryMuscle: "Quads",
    secondaryMuscles: ["Glutes"],
    pattern: "squat",
    laterality: "unilateral",
    exerciseType: "compound",
    muscleSetCredits: { Quads: 1.0, Glutes: 0.5 },
  },
  {
    name: "Dumbbell Lateral Raise",
    primaryMuscle: "Side Delts",
    secondaryMuscles: [],
    pattern: "isolation",
    laterality: "bilateral",
    exerciseType: "isolation",
    muscleSetCredits: { "Side Delts": 1.0 },
  },
  {
    name: "Face Pull",
    primaryMuscle: "Rear Delts",
    secondaryMuscles: ["Traps"],
    pattern: "horizontal_pull",
    laterality: "bilateral",
    exerciseType: "isolation",
    muscleSetCredits: { "Rear Delts": 1.0, Traps: 0.5 },
  },
  {
    name: "Barbell Curl",
    primaryMuscle: "Biceps",
    secondaryMuscles: [],
    pattern: "isolation",
    laterality: "bilateral",
    exerciseType: "isolation",
    muscleSetCredits: { Biceps: 1.0 },
  },
  {
    name: "Triceps Pushdown",
    primaryMuscle: "Triceps",
    secondaryMuscles: [],
    pattern: "isolation",
    laterality: "bilateral",
    exerciseType: "isolation",
    muscleSetCredits: { Triceps: 1.0 },
  },
  {
    name: "Cable Crunch",
    primaryMuscle: "Abs",
    secondaryMuscles: [],
    pattern: "core",
    laterality: "bilateral",
    exerciseType: "isolation",
    muscleSetCredits: { Abs: 1.0 },
  },
  {
    name: "Standing Calf Raise",
    primaryMuscle: "Calves",
    secondaryMuscles: [],
    pattern: "isolation",
    laterality: "bilateral",
    exerciseType: "isolation",
    muscleSetCredits: { Calves: 1.0 },
  },
];

async function main() {
  console.log("Seeding...");

  await prisma.recommendation.deleteMany();
  await prisma.insight.deleteMany();
  await prisma.weeklyProgressReport.deleteMany();
  await prisma.monthlyProgressReport.deleteMany();
  await prisma.weeklyCheckIn.deleteMany();
  await prisma.weighInSchedule.deleteMany();
  await prisma.workoutSet.deleteMany();
  await prisma.workout.deleteMany();
  await prisma.exercise.deleteMany();
  await prisma.nutritionLog.deleteMany();
  await prisma.recoveryLog.deleteMany();
  await prisma.medicationDose.deleteMany();
  await prisma.bodyMeasurement.deleteMany();
  await prisma.goal.deleteMany();

  // --- Body measurements ---------------------------------------------------
  const measurementIdByDate = new Map<string, string>();
  for (const w of WEIGH_INS) {
    const extra = FULL_COMPOSITION[w.date];
    const record = await prisma.bodyMeasurement.create({
      data: {
        date: new Date(`${w.date}T07:00:00`),
        weight: w.weight,
        bmi: extra?.bmi ?? Math.round(bmiOf(w.weight) * 10) / 10,
        bodyFatPercent: extra?.bodyFatPercent,
        visceralFat: extra?.visceralFat,
        subcutaneousFatPercent: extra?.subcutaneousFatPercent,
        skeletalMusclePercent: extra?.skeletalMusclePercent,
        muscleMass: extra?.muscleMass,
        fatFreeBodyWeight: extra?.fatFreeBodyWeight,
        bodyWaterPercent: extra?.bodyWaterPercent,
        proteinPercent: extra?.proteinPercent,
        boneMass: extra?.boneMass,
        bmr: extra?.bmr,
        source: "manual",
      },
    });
    measurementIdByDate.set(w.date, record.id);
  }
  console.log(`Created ${WEIGH_INS.length} body measurements`);

  // --- Medication doses ------------------------------------------------------
  const doseIdByDate = new Map<string, string>();
  for (const d of MEDICATION_DOSES) {
    const record = await prisma.medicationDose.create({
      data: {
        date: new Date(`${d.date}T07:30:00`),
        doseMg: d.doseMg,
        nauseaLevel: d.nausea,
        appetiteLevel: d.appetite,
        hungerLevel: d.hunger,
        energyLevel: d.energy,
        sideEffects: d.nausea >= 3 ? "Mild nausea, slight fatigue" : d.nausea >= 2 ? "Slight nausea" : "None notable",
        giSymptoms: d.nausea >= 3 ? "Occasional reflux" : null,
        missed: false,
        delayed: false,
      },
    });
    doseIdByDate.set(d.date, record.id);
  }
  console.log(`Created ${MEDICATION_DOSES.length} medication doses`);

  // --- Weigh-in schedule + weekly check-ins -----------------------------------
  await prisma.weighInSchedule.create({
    data: { dayOfWeek: 3, active: true },
  });

  for (const w of WEIGH_INS) {
    const date = new Date(`${w.date}T07:00:00`);
    if (date.getDay() !== 3) continue; // only Wednesdays are scheduled check-ins
    const measurementId = measurementIdByDate.get(w.date)!;
    const doseId = doseIdByDate.get(w.date);
    await prisma.weeklyCheckIn.create({
      data: {
        date,
        weekStartDate: mondayOf(date),
        bodyMeasurementId: measurementId,
        medicationDoseId: doseId,
        hungerRating: 10 - (MEDICATION_DOSES.find((m) => m.date === w.date)?.hunger ?? 5),
        energyRating: MEDICATION_DOSES.find((m) => m.date === w.date)?.energy ?? 6,
        trainingConsistencyRating: 8,
        proteinConsistencyRating: 7,
        completed: true,
      },
    });
  }
  console.log("Created weigh-in schedule + weekly check-ins");

  // --- Goal --------------------------------------------------------------
  await prisma.goal.create({
    data: {
      label: "Reach 180 lb while preserving lean mass",
      type: "weight",
      targetValue: 180,
      startValue: 256,
      startDate: new Date("2026-04-01T07:00:00"),
      achieved: false,
    },
  });
  console.log("Created goal");

  // --- Exercises -----------------------------------------------------------
  const exerciseByName = new Map<string, string>();
  for (const ex of EXERCISES) {
    const record = await prisma.exercise.create({
      data: {
        name: ex.name,
        primaryMuscle: ex.primaryMuscle,
        secondaryMuscles: JSON.stringify(ex.secondaryMuscles),
        pattern: ex.pattern,
        laterality: ex.laterality,
        exerciseType: ex.exerciseType,
        muscleSetCredits: JSON.stringify(ex.muscleSetCredits),
      },
    });
    exerciseByName.set(ex.name, record.id);
  }
  console.log(`Created ${EXERCISES.length} exercises`);

  // --- Workouts: 2x/week (Wed = Upper, Sat = Lower) for 12 weeks ------------
  const startDate = new Date("2026-04-01T18:00:00");
  let workoutCount = 0;
  let setCount = 0;

  for (let week = 0; week < 12; week++) {
    const upperDate = addDays(startDate, week * 7); // Wednesdays
    const lowerDate = addDays(startDate, week * 7 + 3); // Saturdays

    // Strength progression for key lifts across the cut.
    const benchWeight = week >= 7 ? 185 - (week - 7) * 3 : 185;
    const benchReps = 8;
    const squatWeight = 225 + week * 1;
    const squatReps = 6;
    const ohpWeight = 115 - week * 0.3;
    const ohpReps = 8;
    const pullupAdded = 25 - week * 0.4;
    const pullupReps = 6;
    const rowWeight = 155 - week * 0.5;
    const rowReps = 10;
    const deadliftWeight = 275 + week * 0.5;
    const deadliftReps = 5;
    const rdlWeight = 135 + week * 0.3;
    const rdlReps = 10;

    // Upper day
    const upperWorkout = await prisma.workout.create({
      data: {
        date: upperDate,
        type: "upper",
        bodyweight: Math.round(interpolateWeight(upperDate) * 10) / 10,
        notes: week === 7 ? "Felt flat on bench -- monitor recovery." : null,
      },
    });
    workoutCount++;
    const upperSets: { exercise: string; weight: number; reps: number; rpe: number }[] = [
      { exercise: "Bench Press", weight: benchWeight, reps: benchReps, rpe: 8 },
      { exercise: "Bench Press", weight: benchWeight - 10, reps: benchReps, rpe: 7.5 },
      { exercise: "Bench Press", weight: benchWeight - 10, reps: benchReps, rpe: 8 },
      { exercise: "Overhead Press", weight: ohpWeight, reps: ohpReps, rpe: 7.5 },
      { exercise: "Overhead Press", weight: ohpWeight, reps: ohpReps, rpe: 8 },
      { exercise: "Barbell Row", weight: rowWeight, reps: rowReps, rpe: 7.5 },
      { exercise: "Barbell Row", weight: rowWeight, reps: rowReps, rpe: 8 },
      { exercise: "Weighted Pull-Up", weight: Math.max(pullupAdded, 0), reps: pullupReps, rpe: 8 },
      { exercise: "Weighted Pull-Up", weight: Math.max(pullupAdded, 0), reps: pullupReps, rpe: 8.5 },
      { exercise: "Dumbbell Lateral Raise", weight: 20, reps: 15, rpe: 8 },
      { exercise: "Face Pull", weight: 40, reps: 15, rpe: 7 },
      { exercise: "Barbell Curl", weight: 65, reps: 10, rpe: 7.5 },
      { exercise: "Triceps Pushdown", weight: 60, reps: 12, rpe: 7.5 },
    ];
    for (let i = 0; i < upperSets.length; i++) {
      const s = upperSets[i];
      await prisma.workoutSet.create({
        data: {
          workoutId: upperWorkout.id,
          exerciseId: exerciseByName.get(s.exercise)!,
          setNumber: i + 1,
          weight: Math.round(s.weight * 10) / 10,
          reps: s.reps,
          rpe: s.rpe,
        },
      });
      setCount++;
    }

    // Lower day
    const lowerWorkout = await prisma.workout.create({
      data: {
        date: lowerDate,
        type: "lower",
        bodyweight: Math.round(interpolateWeight(lowerDate) * 10) / 10,
        notes: null,
      },
    });
    workoutCount++;
    const lowerSets: { exercise: string; weight: number; reps: number; rpe: number }[] = [
      { exercise: "Squat", weight: squatWeight, reps: squatReps, rpe: 8 },
      { exercise: "Squat", weight: squatWeight - 10, reps: squatReps, rpe: 7.5 },
      { exercise: "Squat", weight: squatWeight - 10, reps: squatReps, rpe: 8 },
      ...(week % 2 === 0
        ? [{ exercise: "Deadlift", weight: deadliftWeight, reps: deadliftReps, rpe: 8.5 }]
        : [{ exercise: "Romanian Deadlift", weight: rdlWeight, reps: rdlReps, rpe: 7.5 }]),
      { exercise: "Walking Lunge", weight: 40, reps: 12, rpe: 7.5 },
      { exercise: "Walking Lunge", weight: 40, reps: 12, rpe: 8 },
      { exercise: "Standing Calf Raise", weight: 90, reps: 15, rpe: 7.5 },
      { exercise: "Standing Calf Raise", weight: 90, reps: 15, rpe: 8 },
      { exercise: "Cable Crunch", weight: 50, reps: 15, rpe: 7.5 },
    ];
    for (let i = 0; i < lowerSets.length; i++) {
      const s = lowerSets[i];
      await prisma.workoutSet.create({
        data: {
          workoutId: lowerWorkout.id,
          exerciseId: exerciseByName.get(s.exercise)!,
          setNumber: i + 1,
          weight: Math.round(s.weight * 10) / 10,
          reps: s.reps,
          rpe: s.rpe,
        },
      });
      setCount++;
    }
  }
  console.log(`Created ${workoutCount} workouts with ${setCount} sets`);

  // --- Nutrition logs: daily from Apr 1 to Jun 17 -------------------------
  const totalDays = Math.round((new Date("2026-06-17").getTime() - new Date("2026-04-01").getTime()) / DAY_MS) + 1;
  let nutritionCount = 0;
  for (let i = 0; i < totalDays; i++) {
    const date = addDays(new Date("2026-04-01T12:00:00"), i);
    // Protein adherence improves gradually; occasional low days create realistic variance.
    const baseProtein = 140 + Math.min(i, 70) * 0.4;
    const dip = i % 11 === 0 ? -25 : 0;
    const calories = Math.round(2050 - Math.min(i, 60) * 3 + (i % 5 === 0 ? 80 : 0));
    await prisma.nutritionLog.create({
      data: {
        date,
        calories,
        proteinG: Math.round(baseProtein + dip),
        carbsG: Math.round(140 - i * 0.3 + (i % 4) * 10),
        fatG: Math.round(65 + (i % 3) * 5),
        waterOz: Math.round(80 + (i % 4) * 10),
        fiberG: Math.round(22 + (i % 5)),
      },
    });
    nutritionCount++;
  }
  console.log(`Created ${nutritionCount} nutrition logs`);

  // --- Recovery logs: every 2 days ----------------------------------------
  let recoveryCount = 0;
  for (let i = 0; i < totalDays; i += 2) {
    const date = addDays(new Date("2026-04-01T21:00:00"), i);
    await prisma.recoveryLog.create({
      data: {
        date,
        sleepHours: Math.round((6.8 + (i % 5) * 0.2) * 10) / 10,
        recoveryRating: 6 + (i % 4 === 0 ? -1 : 0),
        energyRating: 6 + (i % 6 === 0 ? -1 : 1),
        sorenessRating: 3 + (i % 5 === 0 ? 2 : 0),
        stressRating: 4 + (i % 7 === 0 ? 1 : 0),
      },
    });
    recoveryCount++;
  }
  console.log(`Created ${recoveryCount} recovery logs`);

  console.log("Seed complete.");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
