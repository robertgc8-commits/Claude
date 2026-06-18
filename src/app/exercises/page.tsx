import Link from "next/link";
import { prisma } from "@/lib/db";
import { deleteExercise } from "@/lib/actions/exercises";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";
import { MOVEMENT_PATTERN_LABELS, type MovementPattern } from "@/lib/constants";

export const dynamic = "force-dynamic";

export default async function ExercisesPage() {
  const exercises = await prisma.exercise.findMany({ orderBy: { name: "asc" } });

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Exercise Library</h1>
        <Button asChild>
          <Link href="/exercises/new">Add Exercise</Link>
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Name</TableHead>
            <TableHead>Primary Muscle</TableHead>
            <TableHead>Pattern</TableHead>
            <TableHead>Type</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {exercises.map((exercise) => (
            <TableRow key={exercise.id}>
              <TableCell className="font-medium">{exercise.name}</TableCell>
              <TableCell>{exercise.primaryMuscle}</TableCell>
              <TableCell>{MOVEMENT_PATTERN_LABELS[exercise.pattern as MovementPattern] ?? exercise.pattern}</TableCell>
              <TableCell>
                <Badge variant={exercise.exerciseType === "compound" ? "default" : "secondary"}>
                  {exercise.exerciseType}
                </Badge>
              </TableCell>
              <TableCell className="flex justify-end gap-2">
                <Button asChild variant="outline" size="sm">
                  <Link href={`/exercises/${exercise.id}/edit`}>Edit</Link>
                </Button>
                <ConfirmDeleteButton action={deleteExercise.bind(null, exercise.id)} />
              </TableCell>
            </TableRow>
          ))}
          {exercises.length === 0 && (
            <TableRow>
              <TableCell colSpan={5} className="py-8 text-center text-neutral-500">
                No exercises yet.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
