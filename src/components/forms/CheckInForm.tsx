import { ZEPBOUND_DOSES } from "@/lib/constants";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";

function toDateInputValue(): string {
  return new Date().toISOString().slice(0, 10);
}

export function CheckInForm({ action }: { action: (formData: FormData) => void }) {
  return (
    <form action={action} className="flex flex-col gap-6">
      <div className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-neutral-700">Body Measurement</h2>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="date">Date</Label>
            <Input id="date" name="date" type="date" required defaultValue={toDateInputValue()} />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="weight">Weight (lb)</Label>
            <Input id="weight" name="weight" type="number" step="0.1" required />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="bodyFatPercent">Body Fat %</Label>
            <Input id="bodyFatPercent" name="bodyFatPercent" type="number" step="0.1" />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="muscleMass">Muscle Mass (lb)</Label>
            <Input id="muscleMass" name="muscleMass" type="number" step="0.1" />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="skeletalMusclePercent">Skeletal Muscle %</Label>
            <Input id="skeletalMusclePercent" name="skeletalMusclePercent" type="number" step="0.1" />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="fatFreeBodyWeight">Fat-Free Body Weight (lb)</Label>
            <Input id="fatFreeBodyWeight" name="fatFreeBodyWeight" type="number" step="0.1" />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="visceralFat">Visceral Fat</Label>
            <Input id="visceralFat" name="visceralFat" type="number" step="0.1" />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="waist">Waist (in)</Label>
            <Input id="waist" name="waist" type="number" step="0.1" />
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-neutral-700">Photos</h2>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="photosNote">Photo Notes</Label>
          <Textarea id="photosNote" name="photosNote" placeholder="Note progress photo observations (optional)" />
        </div>
      </div>

      <div className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-neutral-700">Medication</h2>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="doseMg">Dose (mg)</Label>
            <Input id="doseMg" name="doseMg" type="number" step="0.5" list="zepbound-doses" />
            <datalist id="zepbound-doses">
              {ZEPBOUND_DOSES.map((dose) => (
                <option key={dose} value={dose} />
              ))}
            </datalist>
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="sideEffects">Side Effects</Label>
            <Textarea id="sideEffects" name="sideEffects" placeholder="Any side effects this week (optional)" />
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-neutral-700">How Are You Feeling</h2>
        <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="hungerRating">Hunger (1-10)</Label>
            <Input id="hungerRating" name="hungerRating" type="number" min="1" max="10" step="1" />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="energyRating">Energy (1-10)</Label>
            <Input id="energyRating" name="energyRating" type="number" min="1" max="10" step="1" />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="trainingConsistencyRating">Training Consistency (1-10)</Label>
            <Input id="trainingConsistencyRating" name="trainingConsistencyRating" type="number" min="1" max="10" step="1" />
          </div>
          <div className="flex flex-col gap-1.5">
            <Label htmlFor="proteinConsistencyRating">Protein Consistency (1-10)</Label>
            <Input id="proteinConsistencyRating" name="proteinConsistencyRating" type="number" min="1" max="10" step="1" />
          </div>
        </div>
      </div>

      <div className="flex flex-col gap-3">
        <h2 className="text-sm font-semibold text-neutral-700">Notes</h2>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="notes">Notes</Label>
          <Textarea id="notes" name="notes" />
        </div>
      </div>

      <Button type="submit" className="w-fit">
        Submit Check-In
      </Button>
    </form>
  );
}
