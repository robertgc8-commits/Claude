import type { Goal } from "@prisma/client";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select } from "@/components/ui/select";
import { Button } from "@/components/ui/button";

function toDateInputValue(date: Date | null | undefined): string | undefined {
  if (!date) return undefined;
  return new Date(date).toISOString().slice(0, 10);
}

export function GoalForm({
  action,
  defaultValues,
}: {
  action: (formData: FormData) => void;
  defaultValues?: Goal;
}) {
  return (
    <form action={action} className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="label">Label</Label>
          <Input id="label" name="label" type="text" required defaultValue={defaultValues?.label} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="type">Type</Label>
          <Select id="type" name="type" required defaultValue={defaultValues?.type ?? "weight"}>
            <option value="weight">Weight</option>
            <option value="body_fat">Body Fat %</option>
            <option value="lean_mass">Lean Mass</option>
            <option value="custom">Custom</option>
          </Select>
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="targetValue">Target Value</Label>
          <Input
            id="targetValue"
            name="targetValue"
            type="number"
            step="0.1"
            required
            defaultValue={defaultValues?.targetValue}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="targetDate">Target Date</Label>
          <Input
            id="targetDate"
            name="targetDate"
            type="date"
            defaultValue={toDateInputValue(defaultValues?.targetDate)}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="startValue">Start Value</Label>
          <Input
            id="startValue"
            name="startValue"
            type="number"
            step="0.1"
            defaultValue={defaultValues?.startValue ?? undefined}
          />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="startDate">Start Date</Label>
          <Input
            id="startDate"
            name="startDate"
            type="date"
            defaultValue={toDateInputValue(defaultValues?.startDate)}
          />
        </div>
      </div>
      <div className="flex items-center gap-2">
        <input
          id="achieved"
          name="achieved"
          type="checkbox"
          value="true"
          defaultChecked={defaultValues?.achieved ?? false}
          className="h-4 w-4 rounded border-neutral-300"
        />
        <Label htmlFor="achieved">Achieved</Label>
      </div>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="notes">Notes</Label>
        <Textarea id="notes" name="notes" defaultValue={defaultValues?.notes ?? undefined} />
      </div>
      <Button type="submit" className="w-fit">
        {defaultValues ? "Save Changes" : "Add Goal"}
      </Button>
    </form>
  );
}
