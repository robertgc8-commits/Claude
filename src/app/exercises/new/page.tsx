import { createExercise } from "@/lib/actions/exercises";
import { ExerciseForm } from "@/components/forms/ExerciseForm";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function NewExercisePage() {
  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-2xl font-bold">Add Exercise</h1>
      <Card>
        <CardHeader>
          <CardTitle>New Exercise</CardTitle>
        </CardHeader>
        <CardContent>
          <ExerciseForm action={createExercise} />
        </CardContent>
      </Card>
    </div>
  );
}
