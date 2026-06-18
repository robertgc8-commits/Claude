"use client";

import { useState } from "react";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Textarea } from "@/components/ui/textarea";
import { Select } from "@/components/ui/select";
import { Button } from "@/components/ui/button";
import { WORKOUT_TYPES, WORKOUT_TYPE_LABELS } from "@/lib/constants";

export interface WorkoutSetRow {
  exerciseId: string;
  weight: number;
  reps: number;
  rpe?: number;
  rir?: number;
  tempo?: string;
  restSeconds?: number;
}

export interface WorkoutFormDefaultValues {
  date: Date;
  type: string;
  bodyweight: number | null;
  notes: string | null;
  sets: {
    exerciseId: string;
    weight: number;
    reps: number;
    rpe: number | null;
    rir: number | null;
  }[];
}

function toDateInputValue(date: Date | undefined): string {
  if (!date) return new Date().toISOString().slice(0, 10);
  return new Date(date).toISOString().slice(0, 10);
}

export function WorkoutForm({
  action,
  exercises,
  defaultValues,
}: {
  action: (formData: FormData) => void;
  exercises: { id: string; name: string }[];
  defaultValues?: WorkoutFormDefaultValues;
}) {
  const [sets, setSets] = useState<WorkoutSetRow[]>(
    defaultValues?.sets.map((s) => ({
      exerciseId: s.exerciseId,
      weight: s.weight,
      reps: s.reps,
      rpe: s.rpe ?? undefined,
      rir: s.rir ?? undefined,
    })) ?? []
  );

  function addSet() {
    setSets((prev) => [
      ...prev,
      {
        exerciseId: exercises[0]?.id ?? "",
        weight: 0,
        reps: 0,
      },
    ]);
  }

  function removeSet(index: number) {
    setSets((prev) => prev.filter((_, i) => i !== index));
  }

  function updateSet(index: number, patch: Partial<WorkoutSetRow>) {
    setSets((prev) => prev.map((s, i) => (i === index ? { ...s, ...patch } : s)));
  }

  return (
    <form action={action} className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-4 md:grid-cols-4">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="date">Date</Label>
          <Input id="date" name="date" type="date" required defaultValue={toDateInputValue(defaultValues?.date)} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="type">Type</Label>
          <Select id="type" name="type" required defaultValue={defaultValues?.type ?? WORKOUT_TYPES[0]}>
            {WORKOUT_TYPES.map((t) => (
              <option key={t} value={t}>
                {WORKOUT_TYPE_LABELS[t]}
              </option>
            ))}
          </Select>
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="bodyweight">Bodyweight (lb)</Label>
          <Input
            id="bodyweight"
            name="bodyweight"
            type="number"
            step="0.1"
            defaultValue={defaultValues?.bodyweight ?? undefined}
          />
        </div>
      </div>

      <div className="flex flex-col gap-1.5">
        <Label htmlFor="notes">Notes</Label>
        <Textarea id="notes" name="notes" defaultValue={defaultValues?.notes ?? undefined} />
      </div>

      <div className="flex flex-col gap-2">
        <div className="flex items-center justify-between">
          <Label>Sets</Label>
          <Button type="button" variant="outline" size="sm" onClick={addSet}>
            Add Set
          </Button>
        </div>

        <div className="flex flex-col gap-2">
          {sets.map((set, index) => (
            <div
              key={index}
              className="grid grid-cols-2 items-end gap-2 rounded-md border border-neutral-200 p-3 md:grid-cols-6"
            >
              <div className="flex flex-col gap-1.5 md:col-span-2">
                <Label htmlFor={`set-exercise-${index}`}>Exercise</Label>
                <Select
                  id={`set-exercise-${index}`}
                  value={set.exerciseId}
                  onChange={(e) => updateSet(index, { exerciseId: e.target.value })}
                >
                  {exercises.map((ex) => (
                    <option key={ex.id} value={ex.id}>
                      {ex.name}
                    </option>
                  ))}
                </Select>
              </div>
              <div className="flex flex-col gap-1.5">
                <Label htmlFor={`set-weight-${index}`}>Weight</Label>
                <Input
                  id={`set-weight-${index}`}
                  type="number"
                  step="0.5"
                  min={0}
                  value={set.weight}
                  onChange={(e) => updateSet(index, { weight: Number(e.target.value) })}
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <Label htmlFor={`set-reps-${index}`}>Reps</Label>
                <Input
                  id={`set-reps-${index}`}
                  type="number"
                  step="1"
                  min={1}
                  value={set.reps}
                  onChange={(e) => updateSet(index, { reps: Number(e.target.value) })}
                />
              </div>
              <div className="flex flex-col gap-1.5">
                <Label htmlFor={`set-rpe-${index}`}>RPE</Label>
                <Input
                  id={`set-rpe-${index}`}
                  type="number"
                  step="0.5"
                  placeholder="RPE"
                  value={set.rpe ?? ""}
                  onChange={(e) =>
                    updateSet(index, { rpe: e.target.value === "" ? undefined : Number(e.target.value) })
                  }
                />
              </div>
              <div className="flex items-end gap-2">
                <div className="flex flex-1 flex-col gap-1.5">
                  <Label htmlFor={`set-rir-${index}`}>RIR</Label>
                  <Input
                    id={`set-rir-${index}`}
                    type="number"
                    step="1"
                    placeholder="RIR"
                    value={set.rir ?? ""}
                    onChange={(e) =>
                      updateSet(index, { rir: e.target.value === "" ? undefined : Number(e.target.value) })
                    }
                  />
                </div>
                <Button type="button" variant="ghost" size="sm" onClick={() => removeSet(index)}>
                  Remove
                </Button>
              </div>
            </div>
          ))}
          {sets.length === 0 && (
            <p className="py-4 text-center text-sm text-neutral-500">
              No sets yet. Click &quot;Add Set&quot; to get started.
            </p>
          )}
        </div>
      </div>

      <input type="hidden" name="sets" value={JSON.stringify(sets)} />

      <Button type="submit" className="w-fit">
        {defaultValues ? "Save Changes" : "Save Workout"}
      </Button>
    </form>
  );
}
