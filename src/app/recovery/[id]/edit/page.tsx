import { notFound } from "next/navigation";
import { prisma } from "@/lib/db";
import { updateRecoveryLog, deleteRecoveryLog } from "@/lib/actions/recovery";
import { RecoveryLogForm } from "@/components/forms/RecoveryLogForm";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default async function EditRecoveryLogPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const log = await prisma.recoveryLog.findUnique({ where: { id } });
  if (!log) notFound();

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Edit Recovery Log</h1>
        <ConfirmDeleteButton action={deleteRecoveryLog.bind(null, id)} />
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Edit Recovery Log</CardTitle>
        </CardHeader>
        <CardContent>
          <RecoveryLogForm action={updateRecoveryLog.bind(null, id)} defaultValues={log} />
        </CardContent>
      </Card>
    </div>
  );
}
