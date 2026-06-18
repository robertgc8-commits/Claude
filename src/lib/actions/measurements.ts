"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/db";
import { bodyMeasurementSchema } from "@/lib/validations";

export async function createBodyMeasurement(formData: FormData) {
  const parsed = bodyMeasurementSchema.parse(Object.fromEntries(formData));
  await prisma.bodyMeasurement.create({
    data: { ...parsed, date: new Date(parsed.date) },
  });
  revalidatePath("/measurements");
  revalidatePath("/");
}

export async function updateBodyMeasurement(id: string, formData: FormData) {
  const parsed = bodyMeasurementSchema.parse(Object.fromEntries(formData));
  await prisma.bodyMeasurement.update({
    where: { id },
    data: { ...parsed, date: new Date(parsed.date) },
  });
  revalidatePath("/measurements");
  revalidatePath("/");
}

export async function deleteBodyMeasurement(id: string) {
  await prisma.bodyMeasurement.delete({ where: { id } });
  revalidatePath("/measurements");
  revalidatePath("/");
}
