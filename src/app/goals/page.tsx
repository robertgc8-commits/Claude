import Link from "next/link";
import { prisma } from "@/lib/db";
import { formatDate, formatNumber } from "@/lib/utils";
import { deleteGoal } from "@/lib/actions/goals";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";

export const dynamic = "force-dynamic";

const TYPE_LABELS: Record<string, string> = {
  weight: "Weight",
  body_fat: "Body Fat %",
  lean_mass: "Lean Mass",
  custom: "Custom",
};

export default async function GoalsPage() {
  const goals = await prisma.goal.findMany({ orderBy: { createdAt: "desc" } });

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Goals</h1>
        <Button asChild>
          <Link href="/goals/new">Add Goal</Link>
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Label</TableHead>
            <TableHead>Type</TableHead>
            <TableHead>Target</TableHead>
            <TableHead>Progress</TableHead>
            <TableHead>Achieved</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {goals.map((g) => (
            <TableRow key={g.id}>
              <TableCell>{g.label}</TableCell>
              <TableCell>{TYPE_LABELS[g.type] ?? g.type}</TableCell>
              <TableCell>
                {formatNumber(g.targetValue)}
                {g.targetDate ? ` by ${formatDate(g.targetDate)}` : ""}
              </TableCell>
              <TableCell>
                {g.startValue !== null ? formatNumber(g.startValue) : "--"}
                {" → "}
                {formatNumber(g.targetValue)}
              </TableCell>
              <TableCell>
                {g.achieved ? <Badge variant="success">Achieved</Badge> : <Badge variant="secondary">In Progress</Badge>}
              </TableCell>
              <TableCell className="flex justify-end gap-2">
                <Button asChild variant="outline" size="sm">
                  <Link href={`/goals/${g.id}/edit`}>Edit</Link>
                </Button>
                <ConfirmDeleteButton action={deleteGoal.bind(null, g.id)} />
              </TableCell>
            </TableRow>
          ))}
          {goals.length === 0 && (
            <TableRow>
              <TableCell colSpan={6} className="py-8 text-center text-neutral-500">
                No goals yet.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
