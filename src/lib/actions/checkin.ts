"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/db";
import { weeklyCheckInSchema } from "@/lib/validations";
import { generateWeeklyReport } from "./reports";

const DAY_MS = 86_400_000;

function mondayOf(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  return new Date(d.getTime() + diff * DAY_MS);
}

export async function submitWeeklyCheckIn(formData: FormData) {
  const parsed = weeklyCheckInSchema.parse(Object.fromEntries(formData));
  const date = new Date(parsed.date);

  const measurement = await prisma.bodyMeasurement.create({
    data: {
      date,
      weight: parsed.weight,
      bodyFatPercent: parsed.bodyFatPercent,
      muscleMass: parsed.muscleMass,
      skeletalMusclePercent: parsed.skeletalMusclePercent,
      fatFreeBodyWeight: parsed.fatFreeBodyWeight,
      visceralFat: parsed.visceralFat,
      waist: parsed.waist,
      notes: parsed.notes,
      source: "weekly_checkin",
    },
  });

  let doseId: string | null = null;
  if (parsed.doseMg) {
    const dose = await prisma.medicationDose.create({
      data: {
        date,
        doseMg: parsed.doseMg,
        sideEffects: parsed.sideEffects,
      },
    });
    doseId = dose.id;
  }

  await prisma.weeklyCheckIn.create({
    data: {
      date,
      weekStartDate: mondayOf(date),
      bodyMeasurementId: measurement.id,
      medicationDoseId: doseId,
      waist: parsed.waist,
      photosNote: parsed.photosNote,
      hungerRating: parsed.hungerRating,
      energyRating: parsed.energyRating,
      trainingConsistencyRating: parsed.trainingConsistencyRating,
      proteinConsistencyRating: parsed.proteinConsistencyRating,
      sideEffects: parsed.sideEffects,
      notes: parsed.notes,
      completed: true,
    },
  });

  await generateWeeklyReport(parsed.date);

  revalidatePath("/checkin");
  revalidatePath("/measurements");
  revalidatePath("/medication");
  revalidatePath("/");
  revalidatePath("/reports");
}
