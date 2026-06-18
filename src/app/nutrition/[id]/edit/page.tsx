import { notFound } from "next/navigation";
import { prisma } from "@/lib/db";
import { updateNutritionLog, deleteNutritionLog } from "@/lib/actions/nutrition";
import { NutritionLogForm } from "@/components/forms/NutritionLogForm";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default async function EditNutritionLogPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const log = await prisma.nutritionLog.findUnique({ where: { id } });
  if (!log) notFound();

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Edit Nutrition Log</h1>
        <ConfirmDeleteButton action={deleteNutritionLog.bind(null, id)} />
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Edit Nutrition Log</CardTitle>
        </CardHeader>
        <CardContent>
          <NutritionLogForm action={updateNutritionLog.bind(null, id)} defaultValues={log} />
        </CardContent>
      </Card>
    </div>
  );
}
