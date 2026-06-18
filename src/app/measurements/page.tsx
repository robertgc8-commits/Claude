import Link from "next/link";
import { prisma } from "@/lib/db";
import { formatDate } from "@/lib/utils";
import { deleteBodyMeasurement } from "@/lib/actions/measurements";
import { Button } from "@/components/ui/button";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";

export const dynamic = "force-dynamic";

export default async function MeasurementsPage() {
  const measurements = await prisma.bodyMeasurement.findMany({ orderBy: { date: "desc" } });

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Body Measurements</h1>
        <Button asChild>
          <Link href="/measurements/new">Add Measurement</Link>
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Date</TableHead>
            <TableHead>Weight</TableHead>
            <TableHead>Body Fat %</TableHead>
            <TableHead>Muscle Mass</TableHead>
            <TableHead>Source</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {measurements.map((m) => (
            <TableRow key={m.id}>
              <TableCell>{formatDate(m.date)}</TableCell>
              <TableCell>{m.weight.toFixed(1)} lb</TableCell>
              <TableCell>{m.bodyFatPercent !== null ? `${m.bodyFatPercent.toFixed(1)}%` : "--"}</TableCell>
              <TableCell>{m.muscleMass !== null ? `${m.muscleMass.toFixed(1)} lb` : "--"}</TableCell>
              <TableCell className="text-xs text-neutral-500">{m.source === "weekly_checkin" ? "Check-in" : "Manual"}</TableCell>
              <TableCell className="flex justify-end gap-2">
                <Button asChild variant="outline" size="sm">
                  <Link href={`/measurements/${m.id}/edit`}>Edit</Link>
                </Button>
                <ConfirmDeleteButton action={deleteBodyMeasurement.bind(null, m.id)} />
              </TableCell>
            </TableRow>
          ))}
          {measurements.length === 0 && (
            <TableRow>
              <TableCell colSpan={6} className="py-8 text-center text-neutral-500">
                No measurements yet.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
