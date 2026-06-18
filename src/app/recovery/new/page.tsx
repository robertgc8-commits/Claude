import { createRecoveryLog } from "@/lib/actions/recovery";
import { RecoveryLogForm } from "@/components/forms/RecoveryLogForm";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function NewRecoveryLogPage() {
  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-2xl font-bold">Add Recovery Log</h1>
      <Card>
        <CardHeader>
          <CardTitle>New Recovery Log</CardTitle>
        </CardHeader>
        <CardContent>
          <RecoveryLogForm action={createRecoveryLog} />
        </CardContent>
      </Card>
    </div>
  );
}
