"use server";

import { revalidatePath } from "next/cache";
import { prisma } from "@/lib/db";
import { buildWeeklySummary, generateInsightsAndRecommendations, computeOverallRating } from "@/lib/insights";

const DAY_MS = 86_400_000;

function mondayOf(date: Date): Date {
  const d = new Date(date);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  return new Date(d.getTime() + diff * DAY_MS);
}

async function gatherInputs(asOf: Date) {
  const [measurements, doses, workouts, nutrition, recovery, goal] = await Promise.all([
    prisma.bodyMeasurement.findMany({ where: { date: { lte: asOf } }, orderBy: { date: "asc" } }),
    prisma.medicationDose.findMany({ where: { date: { lte: asOf } }, orderBy: { date: "asc" } }),
    prisma.workout.findMany({
      where: { date: { lte: asOf } },
      include: { sets: { include: { exercise: true } } },
      orderBy: { date: "asc" },
    }),
    prisma.nutritionLog.findMany({ where: { date: { lte: asOf } }, orderBy: { date: "asc" } }),
    prisma.recoveryLog.findMany({ where: { date: { lte: asOf } }, orderBy: { date: "asc" } }),
    prisma.goal.findFirst({ where: { type: "weight" }, orderBy: { createdAt: "asc" } }),
  ]);
  return { measurements, doses, workouts, nutrition, recovery, goal };
}

export async function generateWeeklyReport(asOfDate?: string) {
  const asOf = asOfDate ? new Date(asOfDate) : new Date();
  const inputs = await gatherInputs(asOf);
  const summary = buildWeeklySummary(inputs, asOf);
  const { insights, recommendations } = generateInsightsAndRecommendations(inputs, summary, asOf);
  const overallRating = computeOverallRating(insights);

  const weekStartDate = mondayOf(asOf);
  const weekEndDate = new Date(weekStartDate.getTime() + 6 * DAY_MS);

  await prisma.weeklyProgressReport.deleteMany({ where: { weekStartDate } });

  const report = await prisma.weeklyProgressReport.create({
    data: {
      weekStartDate,
      weekEndDate,
      overallRating,
      summaryJson: JSON.stringify(summary),
      insights: { create: insights.map((i) => ({ ...i, suggestedAction: i.suggestedAction ?? undefined })) },
      recommendations: { create: recommendations },
    },
  });

  revalidatePath("/reports");
  revalidatePath("/");
  return report.id;
}

export async function generateMonthlyReport(asOfDate?: string) {
  const asOf = asOfDate ? new Date(asOfDate) : new Date();
  const inputs = await gatherInputs(asOf);
  const summary = buildWeeklySummary(inputs, asOf);
  const { insights, recommendations } = generateInsightsAndRecommendations(inputs, summary, asOf);

  const monthStartDate = new Date(asOf.getFullYear(), asOf.getMonth(), 1);
  const monthEndDate = new Date(asOf.getFullYear(), asOf.getMonth() + 1, 0);

  await prisma.monthlyProgressReport.deleteMany({ where: { monthStartDate } });

  const report = await prisma.monthlyProgressReport.create({
    data: {
      monthStartDate,
      monthEndDate,
      summaryJson: JSON.stringify(summary),
      insights: { create: insights.map((i) => ({ ...i, suggestedAction: i.suggestedAction ?? undefined })) },
      recommendations: { create: recommendations },
    },
  });

  revalidatePath("/reports");
  revalidatePath("/");
  return report.id;
}

export async function resolveInsight(id: string) {
  await prisma.insight.update({ where: { id }, data: { resolved: true } });
  revalidatePath("/reports");
}

export async function resolveRecommendation(id: string) {
  await prisma.recommendation.update({ where: { id }, data: { resolved: true } });
  revalidatePath("/reports");
}
