"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/db";
import { exerciseSchema } from "@/lib/validations";

export async function createExercise(formData: FormData) {
  const parsed = exerciseSchema.parse(Object.fromEntries(formData));
  await prisma.exercise.create({
    data: {
      ...parsed,
      secondaryMuscles: JSON.stringify(parsed.secondaryMuscles),
      muscleSetCredits: JSON.stringify(parsed.muscleSetCredits),
    },
  });
  revalidatePath("/exercises");
}

export async function updateExercise(id: string, formData: FormData) {
  const parsed = exerciseSchema.parse(Object.fromEntries(formData));
  await prisma.exercise.update({
    where: { id },
    data: {
      ...parsed,
      secondaryMuscles: JSON.stringify(parsed.secondaryMuscles),
      muscleSetCredits: JSON.stringify(parsed.muscleSetCredits),
    },
  });
  revalidatePath("/exercises");
}

export async function deleteExercise(id: string) {
  await prisma.exercise.delete({ where: { id } });
  revalidatePath("/exercises");
}
