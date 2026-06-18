"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/db";
import { recoveryLogSchema } from "@/lib/validations";

export async function createRecoveryLog(formData: FormData) {
  const parsed = recoveryLogSchema.parse(Object.fromEntries(formData));
  await prisma.recoveryLog.create({ data: { ...parsed, date: new Date(parsed.date) } });
  revalidatePath("/recovery");
}

export async function updateRecoveryLog(id: string, formData: FormData) {
  const parsed = recoveryLogSchema.parse(Object.fromEntries(formData));
  await prisma.recoveryLog.update({ where: { id }, data: { ...parsed, date: new Date(parsed.date) } });
  revalidatePath("/recovery");
}

export async function deleteRecoveryLog(id: string) {
  await prisma.recoveryLog.delete({ where: { id } });
  revalidatePath("/recovery");
}
