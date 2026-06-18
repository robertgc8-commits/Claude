import { notFound } from "next/navigation";
import { prisma } from "@/lib/db";
import { updateWorkout, deleteWorkout } from "@/lib/actions/workouts";
import { WorkoutForm } from "@/components/forms/WorkoutForm";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export const dynamic = "force-dynamic";

export default async function EditWorkoutPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const [workout, exercises] = await Promise.all([
    prisma.workout.findUnique({
      where: { id },
      include: { sets: { include: { exercise: true } } },
    }),
    prisma.exercise.findMany({ orderBy: { name: "asc" } }),
  ]);
  if (!workout) notFound();

  const defaultValues = {
    date: workout.date,
    type: workout.type,
    bodyweight: workout.bodyweight,
    notes: workout.notes,
    sets: workout.sets.map((s) => ({
      exerciseId: s.exerciseId,
      weight: s.weight,
      reps: s.reps,
      rpe: s.rpe,
      rir: s.rir,
    })),
  };

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Edit Workout</h1>
        <ConfirmDeleteButton action={deleteWorkout.bind(null, id)} />
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Edit Workout</CardTitle>
        </CardHeader>
        <CardContent>
          <WorkoutForm action={updateWorkout.bind(null, id)} exercises={exercises} defaultValues={defaultValues} />
        </CardContent>
      </Card>
    </div>
  );
}
