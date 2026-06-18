import Link from "next/link";
import { prisma } from "@/lib/db";
import { formatDate } from "@/lib/utils";
import { deleteNutritionLog } from "@/lib/actions/nutrition";
import { Button } from "@/components/ui/button";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";

export const dynamic = "force-dynamic";

export default async function NutritionPage() {
  const logs = await prisma.nutritionLog.findMany({ orderBy: { date: "desc" } });

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Nutrition Logs</h1>
        <Button asChild>
          <Link href="/nutrition/new">Add Log</Link>
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Date</TableHead>
            <TableHead>Calories</TableHead>
            <TableHead>Protein (g)</TableHead>
            <TableHead>Carbs (g)</TableHead>
            <TableHead>Fat (g)</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {logs.map((l) => (
            <TableRow key={l.id}>
              <TableCell>{formatDate(l.date)}</TableCell>
              <TableCell>{l.calories ?? "--"}</TableCell>
              <TableCell>{l.proteinG !== null ? l.proteinG.toFixed(1) : "--"}</TableCell>
              <TableCell>{l.carbsG !== null ? l.carbsG.toFixed(1) : "--"}</TableCell>
              <TableCell>{l.fatG !== null ? l.fatG.toFixed(1) : "--"}</TableCell>
              <TableCell className="flex justify-end gap-2">
                <Button asChild variant="outline" size="sm">
                  <Link href={`/nutrition/${l.id}/edit`}>Edit</Link>
                </Button>
                <ConfirmDeleteButton action={deleteNutritionLog.bind(null, l.id)} />
              </TableCell>
            </TableRow>
          ))}
          {logs.length === 0 && (
            <TableRow>
              <TableCell colSpan={6} className="py-8 text-center text-neutral-500">
                No nutrition logs yet.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
