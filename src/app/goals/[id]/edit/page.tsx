import { notFound } from "next/navigation";
import { prisma } from "@/lib/db";
import { updateGoal, deleteGoal } from "@/lib/actions/goals";
import { GoalForm } from "@/components/forms/GoalForm";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default async function EditGoalPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const goal = await prisma.goal.findUnique({ where: { id } });
  if (!goal) notFound();

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Edit Goal</h1>
        <ConfirmDeleteButton action={deleteGoal.bind(null, id)} />
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Edit Goal</CardTitle>
        </CardHeader>
        <CardContent>
          <GoalForm action={updateGoal.bind(null, id)} defaultValues={goal} />
        </CardContent>
      </Card>
    </div>
  );
}
