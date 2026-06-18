"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/db";
import { medicationDoseSchema } from "@/lib/validations";

export async function createMedicationDose(formData: FormData) {
  const parsed = medicationDoseSchema.parse(Object.fromEntries(formData));
  await prisma.medicationDose.create({
    data: { ...parsed, date: new Date(parsed.date) },
  });
  revalidatePath("/medication");
  revalidatePath("/");
  revalidatePath("/dose-analysis");
}

export async function updateMedicationDose(id: string, formData: FormData) {
  const parsed = medicationDoseSchema.parse(Object.fromEntries(formData));
  await prisma.medicationDose.update({
    where: { id },
    data: { ...parsed, date: new Date(parsed.date) },
  });
  revalidatePath("/medication");
  revalidatePath("/");
  revalidatePath("/dose-analysis");
}

export async function deleteMedicationDose(id: string) {
  await prisma.medicationDose.delete({ where: { id } });
  revalidatePath("/medication");
  revalidatePath("/");
  revalidatePath("/dose-analysis");
}
