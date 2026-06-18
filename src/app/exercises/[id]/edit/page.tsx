import { notFound } from "next/navigation";
import { prisma } from "@/lib/db";
import { updateExercise, deleteExercise } from "@/lib/actions/exercises";
import { ExerciseForm } from "@/components/forms/ExerciseForm";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default async function EditExercisePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const exercise = await prisma.exercise.findUnique({ where: { id } });
  if (!exercise) notFound();

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Edit Exercise</h1>
        <ConfirmDeleteButton action={deleteExercise.bind(null, id)} />
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Edit Exercise</CardTitle>
        </CardHeader>
        <CardContent>
          <ExerciseForm action={updateExercise.bind(null, id)} defaultValues={exercise} />
        </CardContent>
      </Card>
    </div>
  );
}
