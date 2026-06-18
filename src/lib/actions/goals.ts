"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/db";
import { goalSchema } from "@/lib/validations";

export async function createGoal(formData: FormData) {
  const parsed = goalSchema.parse(Object.fromEntries(formData));
  await prisma.goal.create({
    data: {
      ...parsed,
      targetDate: parsed.targetDate ? new Date(parsed.targetDate) : null,
      startDate: parsed.startDate ? new Date(parsed.startDate) : null,
    },
  });
  revalidatePath("/goals");
  revalidatePath("/");
}

export async function updateGoal(id: string, formData: FormData) {
  const parsed = goalSchema.parse(Object.fromEntries(formData));
  await prisma.goal.update({
    where: { id },
    data: {
      ...parsed,
      targetDate: parsed.targetDate ? new Date(parsed.targetDate) : null,
      startDate: parsed.startDate ? new Date(parsed.startDate) : null,
    },
  });
  revalidatePath("/goals");
  revalidatePath("/");
}

export async function deleteGoal(id: string) {
  await prisma.goal.delete({ where: { id } });
  revalidatePath("/goals");
  revalidatePath("/");
}
