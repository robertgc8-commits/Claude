"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/db";
import { nutritionLogSchema } from "@/lib/validations";

export async function createNutritionLog(formData: FormData) {
  const parsed = nutritionLogSchema.parse(Object.fromEntries(formData));
  await prisma.nutritionLog.create({ data: { ...parsed, date: new Date(parsed.date) } });
  revalidatePath("/nutrition");
}

export async function updateNutritionLog(id: string, formData: FormData) {
  const parsed = nutritionLogSchema.parse(Object.fromEntries(formData));
  await prisma.nutritionLog.update({ where: { id }, data: { ...parsed, date: new Date(parsed.date) } });
  revalidatePath("/nutrition");
}

export async function deleteNutritionLog(id: string) {
  await prisma.nutritionLog.delete({ where: { id } });
  revalidatePath("/nutrition");
}
