import type { RecoveryLog } from "@prisma/client";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";

function toDateInputValue(date: Date | undefined): string {
  if (!date) return new Date().toISOString().slice(0, 10);
  return new Date(date).toISOString().slice(0, 10);
}

export function RecoveryLogForm({
  action,
  defaultValues,
}: {
  action: (formData: FormData) => void;
  defaultValues?: RecoveryLog;
}) {
  return (
    <form action={action} className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="date">Date</Label>
          <Input id="date" name="date" type="date" required defaultValue={toDateInputValue(defaultValues?.date)} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="sleepHours">Sleep (hrs)</Label>
          <Input id="sleepHours" name="sleepHours" type="number" step="0.1" defaultValue={defaultValues?.sleepHours ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="recoveryRating">Recovery (1-10)</Label>
          <Input
            id="recoveryRating"
            name="recoveryRating"
            type="number"
            step="1"
            min="1"
            max="10"
            defaultValue={defaultValues?.recoveryRating ?? undefined}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="energyRating">Energy (1-10)</Label>
          <Input
            id="energyRating"
            name="energyRating"
            type="number"
            step="1"
            min="1"
            max="10"
            defaultValue={defaultValues?.energyRating ?? undefined}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="sorenessRating">Soreness (1-10)</Label>
          <Input
            id="sorenessRating"
            name="sorenessRating"
            type="number"
            step="1"
            min="1"
            max="10"
            defaultValue={defaultValues?.sorenessRating ?? undefined}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="stressRating">Stress (1-10)</Label>
          <Input
            id="stressRating"
            name="stressRating"
            type="number"
            step="1"
            min="1"
            max="10"
            defaultValue={defaultValues?.stressRating ?? undefined}
          />
        </div>
      </div>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="notes">Notes</Label>
        <Textarea id="notes" name="notes" defaultValue={defaultValues?.notes ?? undefined} />
      </div>
      <Button type="submit" className="w-fit">
        {defaultValues ? "Save Changes" : "Add Log"}
      </Button>
    </form>
  );
}
