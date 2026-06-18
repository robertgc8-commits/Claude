import type { MedicationDose } from "@prisma/client";
import { ZEPBOUND_DOSES } from "@/lib/constants";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";

function toDateInputValue(date: Date | undefined): string {
  if (!date) return new Date().toISOString().slice(0, 10);
  return new Date(date).toISOString().slice(0, 10);
}

export function MedicationDoseForm({
  action,
  defaultValues,
}: {
  action: (formData: FormData) => void;
  defaultValues?: MedicationDose;
}) {
  return (
    <form action={action} className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="date">Date</Label>
          <Input id="date" name="date" type="date" required defaultValue={toDateInputValue(defaultValues?.date)} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="doseMg">Dose (mg)</Label>
          <Input
            id="doseMg"
            name="doseMg"
            type="number"
            step="0.5"
            required
            list="zepbound-doses"
            defaultValue={defaultValues?.doseMg}
          />
          <datalist id="zepbound-doses">
            {ZEPBOUND_DOSES.map((dose) => (
              <option key={dose} value={dose} />
            ))}
          </datalist>
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="sideEffects">Side Effects</Label>
          <Input id="sideEffects" name="sideEffects" defaultValue={defaultValues?.sideEffects ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="appetiteLevel">Appetite Level (1-10)</Label>
          <Input
            id="appetiteLevel"
            name="appetiteLevel"
            type="number"
            min="1"
            max="10"
            step="1"
            defaultValue={defaultValues?.appetiteLevel ?? undefined}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="hungerLevel">Hunger Level (1-10)</Label>
          <Input
            id="hungerLevel"
            name="hungerLevel"
            type="number"
            min="1"
            max="10"
            step="1"
            defaultValue={defaultValues?.hungerLevel ?? undefined}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="energyLevel">Energy Level (1-10)</Label>
          <Input
            id="energyLevel"
            name="energyLevel"
            type="number"
            min="1"
            max="10"
            step="1"
            defaultValue={defaultValues?.energyLevel ?? undefined}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="nauseaLevel">Nausea Level (1-10)</Label>
          <Input
            id="nauseaLevel"
            name="nauseaLevel"
            type="number"
            min="1"
            max="10"
            step="1"
            defaultValue={defaultValues?.nauseaLevel ?? undefined}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="giSymptoms">GI Symptoms</Label>
          <Input id="giSymptoms" name="giSymptoms" defaultValue={defaultValues?.giSymptoms ?? undefined} />
        </div>
      </div>
      <div className="flex flex-wrap gap-6">
        <div className="flex items-center gap-2">
          <input
            id="missed"
            name="missed"
            type="checkbox"
            value="true"
            defaultChecked={defaultValues?.missed ?? false}
            className="h-4 w-4 rounded border-neutral-300"
          />
          <Label htmlFor="missed">Missed dose</Label>
        </div>
        <div className="flex items-center gap-2">
          <input
            id="delayed"
            name="delayed"
            type="checkbox"
            value="true"
            defaultChecked={defaultValues?.delayed ?? false}
            className="h-4 w-4 rounded border-neutral-300"
          />
          <Label htmlFor="delayed">Delayed dose</Label>
        </div>
      </div>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="notes">Notes</Label>
        <Textarea id="notes" name="notes" defaultValue={defaultValues?.notes ?? undefined} />
      </div>
      <Button type="submit" className="w-fit">
        {defaultValues ? "Save Changes" : "Add Dose"}
      </Button>
    </form>
  );
}
