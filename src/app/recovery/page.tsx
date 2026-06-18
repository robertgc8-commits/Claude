import Link from "next/link";
import { prisma } from "@/lib/db";
import { formatDate } from "@/lib/utils";
import { deleteRecoveryLog } from "@/lib/actions/recovery";
import { Button } from "@/components/ui/button";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";

export const dynamic = "force-dynamic";

export default async function RecoveryPage() {
  const logs = await prisma.recoveryLog.findMany({ orderBy: { date: "desc" } });

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Recovery Logs</h1>
        <Button asChild>
          <Link href="/recovery/new">Add Log</Link>
        </Button>
      </div>

      <Table>
        <TableHeader>
          <TableRow>
            <TableHead>Date</TableHead>
            <TableHead>Sleep (hrs)</TableHead>
            <TableHead>Recovery</TableHead>
            <TableHead>Energy</TableHead>
            <TableHead>Soreness</TableHead>
            <TableHead>Stress</TableHead>
            <TableHead></TableHead>
          </TableRow>
        </TableHeader>
        <TableBody>
          {logs.map((l) => (
            <TableRow key={l.id}>
              <TableCell>{formatDate(l.date)}</TableCell>
              <TableCell>{l.sleepHours !== null ? l.sleepHours.toFixed(1) : "--"}</TableCell>
              <TableCell>{l.recoveryRating ?? "--"}</TableCell>
              <TableCell>{l.energyRating ?? "--"}</TableCell>
              <TableCell>{l.sorenessRating ?? "--"}</TableCell>
              <TableCell>{l.stressRating ?? "--"}</TableCell>
              <TableCell className="flex justify-end gap-2">
                <Button asChild variant="outline" size="sm">
                  <Link href={`/recovery/${l.id}/edit`}>Edit</Link>
                </Button>
                <ConfirmDeleteButton action={deleteRecoveryLog.bind(null, l.id)} />
              </TableCell>
            </TableRow>
          ))}
          {logs.length === 0 && (
            <TableRow>
              <TableCell colSpan={7} className="py-8 text-center text-neutral-500">
                No recovery logs yet.
              </TableCell>
            </TableRow>
          )}
        </TableBody>
      </Table>
    </div>
  );
}
