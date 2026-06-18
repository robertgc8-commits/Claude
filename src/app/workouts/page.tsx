import Link from "next/link";
import { prisma } from "@/lib/db";
import { formatDate } from "@/lib/utils";
import { volumeLoad } from "@/lib/calculations";
import { deleteWorkout } from "@/lib/actions/workouts";
import { WORKOUT_TYPE_LABELS, type WorkoutType } from "@/lib/constants";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";

export const dynamic = "force-dynamic";

export default async function WorkoutsPage() {
  const workouts = await prisma.workout.findMany({
    include: { sets: { include: { exercise: true } } },
    orderBy: { date: "desc" },
  });

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Workouts</h1>
        <Button asChild>
          <Link href="/workouts/new">Add Workout</Link>
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Date</TableHead>
            <TableHead>Type</TableHead>
            <TableHead># Sets</TableHead>
            <TableHead>Total Volume</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {workouts.map((w) => (
            <TableRow key={w.id}>
              <TableCell>{formatDate(w.date)}</TableCell>
              <TableCell>
                <Badge variant="secondary">{WORKOUT_TYPE_LABELS[w.type as WorkoutType] ?? w.type}</Badge>
              </TableCell>
              <TableCell>{w.sets.length}</TableCell>
              <TableCell>{volumeLoad(w.sets).toLocaleString()} lb</TableCell>
              <TableCell className="flex justify-end gap-2">
                <Button asChild variant="outline" size="sm">
                  <Link href={`/workouts/${w.id}/edit`}>Edit</Link>
                </Button>
                <ConfirmDeleteButton action={deleteWorkout.bind(null, w.id)} />
              </TableCell>
            </TableRow>
          ))}
          {workouts.length === 0 && (
            <TableRow>
              <TableCell colSpan={5} className="py-8 text-center text-neutral-500">
                No workouts yet.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
