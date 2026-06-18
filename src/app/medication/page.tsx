import Link from "next/link";
import { prisma } from "@/lib/db";
import { formatDate } from "@/lib/utils";
import { deleteMedicationDose } from "@/lib/actions/medication";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";

export const dynamic = "force-dynamic";

export default async function MedicationPage() {
  const doses = await prisma.medicationDose.findMany({ orderBy: { date: "desc" } });

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Medication</h1>
        <Button asChild>
          <Link href="/medication/new">Add Dose</Link>
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Date</TableHead>
            <TableHead>Dose (mg)</TableHead>
            <TableHead>Side Effects</TableHead>
            <TableHead>Status</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {doses.map((dose) => (
            <TableRow key={dose.id}>
              <TableCell>{formatDate(dose.date)}</TableCell>
              <TableCell>{dose.doseMg} mg</TableCell>
              <TableCell>{dose.sideEffects ?? "--"}</TableCell>
              <TableCell className="flex gap-2">
                {dose.missed && <Badge variant="risk">Missed</Badge>}
                {dose.delayed && <Badge variant="warning">Delayed</Badge>}
              </TableCell>
              <TableCell className="flex justify-end gap-2">
                <Button asChild variant="outline" size="sm">
                  <Link href={`/medication/${dose.id}/edit`}>Edit</Link>
                </Button>
                <ConfirmDeleteButton action={deleteMedicationDose.bind(null, dose.id)} />
              </TableCell>
            </TableRow>
          ))}
          {doses.length === 0 && (
            <TableRow>
              <TableCell colSpan={5} className="py-8 text-center text-neutral-500">
                No doses logged yet.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
