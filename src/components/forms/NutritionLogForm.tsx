import type { NutritionLog } from "@prisma/client";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { PROTEIN_TARGET_G } from "@/lib/constants";

function toDateInputValue(date: Date | undefined): string {
  if (!date) return new Date().toISOString().slice(0, 10);
  return new Date(date).toISOString().slice(0, 10);
}

export function NutritionLogForm({
  action,
  defaultValues,
}: {
  action: (formData: FormData) => void;
  defaultValues?: NutritionLog;
}) {
  return (
    <form action={action} className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="date">Date</Label>
          <Input id="date" name="date" type="date" required defaultValue={toDateInputValue(defaultValues?.date)} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="calories">Calories</Label>
          <Input id="calories" name="calories" type="number" step="1" defaultValue={defaultValues?.calories ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="proteinG">Protein (g)</Label>
          <Input
            id="proteinG"
            name="proteinG"
            type="number"
            step="0.1"
            placeholder={`Target: ${PROTEIN_TARGET_G}g`}
            defaultValue={defaultValues?.proteinG ?? undefined}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="carbsG">Carbs (g)</Label>
          <Input id="carbsG" name="carbsG" type="number" step="0.1" defaultValue={defaultValues?.carbsG ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="fatG">Fat (g)</Label>
          <Input id="fatG" name="fatG" type="number" step="0.1" defaultValue={defaultValues?.fatG ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="waterOz">Water (oz)</Label>
          <Input id="waterOz" name="waterOz" type="number" step="0.1" defaultValue={defaultValues?.waterOz ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="fiberG">Fiber (g)</Label>
          <Input id="fiberG" name="fiberG" type="number" step="0.1" defaultValue={defaultValues?.fiberG ?? undefined} />
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
