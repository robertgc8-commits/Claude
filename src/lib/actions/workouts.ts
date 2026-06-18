"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/db";
import { workoutSchema } from "@/lib/validations";

export async function createWorkout(formData: FormData) {
  const parsed = workoutSchema.parse(Object.fromEntries(formData));
  await prisma.workout.create({
    data: {
      date: new Date(parsed.date),
      type: parsed.type,
      bodyweight: parsed.bodyweight,
      notes: parsed.notes,
      sets: {
        create: parsed.sets.map((s, i) => ({
          setNumber: i + 1,
          exerciseId: s.exerciseId,
          weight: s.weight,
          reps: s.reps,
          rpe: s.rpe,
          rir: s.rir,
          tempo: s.tempo,
          restSeconds: s.restSeconds,
        })),
      },
    },
  });
  revalidatePath("/workouts");
  revalidatePath("/strength");
  revalidatePath("/");
}

export async function updateWorkout(id: string, formData: FormData) {
  const parsed = workoutSchema.parse(Object.fromEntries(formData));
  await prisma.$transaction([
    prisma.workoutSet.deleteMany({ where: { workoutId: id } }),
    prisma.workout.update({
      where: { id },
      data: {
        date: new Date(parsed.date),
        type: parsed.type,
        bodyweight: parsed.bodyweight,
        notes: parsed.notes,
        sets: {
          create: parsed.sets.map((s, i) => ({
            setNumber: i + 1,
            exerciseId: s.exerciseId,
            weight: s.weight,
            reps: s.reps,
            rpe: s.rpe,
            rir: s.rir,
            tempo: s.tempo,
            restSeconds: s.restSeconds,
          })),
        },
      },
    }),
  ]);
  revalidatePath("/workouts");
  revalidatePath("/strength");
  revalidatePath("/");
}

export async function deleteWorkout(id: string) {
  await prisma.workout.delete({ where: { id } });
  revalidatePath("/workouts");
  revalidatePath("/strength");
  revalidatePath("/");
}
