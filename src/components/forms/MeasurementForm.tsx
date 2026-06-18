import type { BodyMeasurement } from "@prisma/client";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";

function toDateInputValue(date: Date | undefined): string {
  if (!date) return new Date().toISOString().slice(0, 10);
  return new Date(date).toISOString().slice(0, 10);
}

export function MeasurementForm({
  action,
  defaultValues,
}: {
  action: (formData: FormData) => void;
  defaultValues?: BodyMeasurement;
}) {
  return (
    <form action={action} className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="date">Date</Label>
          <Input id="date" name="date" type="date" required defaultValue={toDateInputValue(defaultValues?.date)} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="weight">Weight (lb)</Label>
          <Input id="weight" name="weight" type="number" step="0.1" required defaultValue={defaultValues?.weight} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="bmi">BMI</Label>
          <Input id="bmi" name="bmi" type="number" step="0.1" defaultValue={defaultValues?.bmi ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="bodyFatPercent">Body Fat %</Label>
          <Input id="bodyFatPercent" name="bodyFatPercent" type="number" step="0.1" defaultValue={defaultValues?.bodyFatPercent ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="visceralFat">Visceral Fat</Label>
          <Input id="visceralFat" name="visceralFat" type="number" step="0.1" defaultValue={defaultValues?.visceralFat ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="subcutaneousFatPercent">Subcutaneous Fat %</Label>
          <Input id="subcutaneousFatPercent" name="subcutaneousFatPercent" type="number" step="0.1" defaultValue={defaultValues?.subcutaneousFatPercent ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="skeletalMusclePercent">Skeletal Muscle %</Label>
          <Input id="skeletalMusclePercent" name="skeletalMusclePercent" type="number" step="0.1" defaultValue={defaultValues?.skeletalMusclePercent ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="muscleMass">Muscle Mass (lb)</Label>
          <Input id="muscleMass" name="muscleMass" type="number" step="0.1" defaultValue={defaultValues?.muscleMass ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="fatFreeBodyWeight">Fat-Free Body Weight (lb)</Label>
          <Input id="fatFreeBodyWeight" name="fatFreeBodyWeight" type="number" step="0.1" defaultValue={defaultValues?.fatFreeBodyWeight ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="bodyWaterPercent">Body Water %</Label>
          <Input id="bodyWaterPercent" name="bodyWaterPercent" type="number" step="0.1" defaultValue={defaultValues?.bodyWaterPercent ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="proteinPercent">Protein %</Label>
          <Input id="proteinPercent" name="proteinPercent" type="number" step="0.1" defaultValue={defaultValues?.proteinPercent ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="boneMass">Bone Mass (lb)</Label>
          <Input id="boneMass" name="boneMass" type="number" step="0.1" defaultValue={defaultValues?.boneMass ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="bmr">BMR (kcal)</Label>
          <Input id="bmr" name="bmr" type="number" step="1" defaultValue={defaultValues?.bmr ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="metabolicAge">Metabolic Age</Label>
          <Input id="metabolicAge" name="metabolicAge" type="number" step="1" defaultValue={defaultValues?.metabolicAge ?? undefined} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="waist">Waist (in)</Label>
          <Input id="waist" name="waist" type="number" step="0.1" defaultValue={defaultValues?.waist ?? undefined} />
        </div>
      </div>
      <div className="flex flex-col gap-1.5">
        <Label htmlFor="notes">Notes</Label>
        <Textarea id="notes" name="notes" defaultValue={defaultValues?.notes ?? undefined} />
      </div>
      <Button type="submit" className="w-fit">
        {defaultValues ? "Save Changes" : "Add Measurement"}
      </Button>
    </form>
  );
}
