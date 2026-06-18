import Link from "next/link";
import { prisma } from "@/lib/db";
import { createWorkout } from "@/lib/actions/workouts";
import { WorkoutForm } from "@/components/forms/WorkoutForm";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export const dynamic = "force-dynamic";

export default async function NewWorkoutPage() {
  const exercises = await prisma.exercise.findMany({ orderBy: { name: "asc" } });

  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-2xl font-bold">Add Workout</h1>
      {exercises.length === 0 ? (
        <p className="text-sm text-neutral-500">
          Add exercises first.{" "}
          <Link href="/exercises/new" className="underline">
            Add an exercise
          </Link>
        </p>
      ) : (
        <Card>
          <CardHeader>
            <CardTitle>New Workout</CardTitle>
          </CardHeader>
          <CardContent>
            <WorkoutForm action={createWorkout} exercises={exercises} />
          </CardContent>
        </Card>
      )}
    </div>
  );
}
