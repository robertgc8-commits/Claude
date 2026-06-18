"use client";

import { useState } from "react";
import {
  MUSCLE_GROUPS,
  MOVEMENT_PATTERNS,
  MOVEMENT_PATTERN_LABELS,
  LATERALITIES,
  EXERCISE_TYPES,
} from "@/lib/constants";
import { Label } from "@/components/ui/label";
import { Input } from "@/components/ui/input";
import { Select } from "@/components/ui/select";
import { Button } from "@/components/ui/button";

export interface ExerciseDefaultValues {
  id: string;
  name: string;
  primaryMuscle: string;
  secondaryMuscles: string;
  pattern: string;
  laterality: string;
  exerciseType: string;
  muscleSetCredits: string;
}

function safeParseArray(json: string | undefined): string[] {
  if (!json) return [];
  try {
    const parsed = JSON.parse(json);
    return Array.isArray(parsed) ? parsed : [];
  } catch {
    return [];
  }
}

function safeParseRecord(json: string | undefined): Record<string, number> {
  if (!json) return {};
  try {
    const parsed = JSON.parse(json);
    return parsed && typeof parsed === "object" ? parsed : {};
  } catch {
    return {};
  }
}

export function ExerciseForm({
  action,
  defaultValues,
}: {
  action: (formData: FormData) => void;
  defaultValues?: ExerciseDefaultValues;
}) {
  const [secondaryMuscles, setSecondaryMuscles] = useState<string[]>(
    safeParseArray(defaultValues?.secondaryMuscles)
  );
  const [muscleSetCredits, setMuscleSetCredits] = useState<Record<string, number>>(
    safeParseRecord(defaultValues?.muscleSetCredits)
  );

  function toggleSecondaryMuscle(muscle: string, checked: boolean) {
    setSecondaryMuscles((prev) =>
      checked ? [...prev, muscle] : prev.filter((m) => m !== muscle)
    );
  }

  function setCredit(muscle: string, value: string) {
    const n = value === "" ? NaN : Number(value);
    setMuscleSetCredits((prev) => {
      const next = { ...prev };
      if (value === "" || Number.isNaN(n) || n === 0) {
        delete next[muscle];
      } else {
        next[muscle] = n;
      }
      return next;
    });
  }

  return (
    <form action={action} className="flex flex-col gap-4">
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="name">Name</Label>
          <Input id="name" name="name" required defaultValue={defaultValues?.name} />
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="primaryMuscle">Primary Muscle</Label>
          <Select id="primaryMuscle" name="primaryMuscle" required defaultValue={defaultValues?.primaryMuscle ?? ""}>
            <option value="" disabled>
              Select muscle
            </option>
            {MUSCLE_GROUPS.map((muscle) => (
              <option key={muscle} value={muscle}>
                {muscle}
              </option>
            ))}
          </Select>
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="pattern">Movement Pattern</Label>
          <Select id="pattern" name="pattern" required defaultValue={defaultValues?.pattern ?? ""}>
            <option value="" disabled>
              Select pattern
            </option>
            {MOVEMENT_PATTERNS.map((pattern) => (
              <option key={pattern} value={pattern}>
                {MOVEMENT_PATTERN_LABELS[pattern]}
              </option>
            ))}
          </Select>
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="laterality">Laterality</Label>
          <Select id="laterality" name="laterality" required defaultValue={defaultValues?.laterality ?? ""}>
            <option value="" disabled>
              Select laterality
            </option>
            {LATERALITIES.map((laterality) => (
              <option key={laterality} value={laterality}>
                {laterality}
              </option>
            ))}
          </Select>
        </div>
        <div className="flex flex-col gap-1.5">
          <Label htmlFor="exerciseType">Exercise Type</Label>
          <Select id="exerciseType" name="exerciseType" required defaultValue={defaultValues?.exerciseType ?? ""}>
            <option value="" disabled>
              Select type
            </option>
            {EXERCISE_TYPES.map((type) => (
              <option key={type} value={type}>
                {type}
              </option>
            ))}
          </Select>
        </div>
      </div>

      <div className="flex flex-col gap-1.5">
        <Label>Secondary Muscles</Label>
        <div className="grid grid-cols-2 gap-2 rounded-md border border-neutral-200 p-3 sm:grid-cols-3 md:grid-cols-4">
          {MUSCLE_GROUPS.map((muscle) => (
            <label key={muscle} className="flex items-center gap-2 text-sm text-neutral-700">
              <input
                type="checkbox"
                checked={secondaryMuscles.includes(muscle)}
                onChange={(e) => toggleSecondaryMuscle(muscle, e.target.checked)}
                className="h-4 w-4 rounded border-neutral-300"
              />
              {muscle}
            </label>
          ))}
        </div>
        <input type="hidden" name="secondaryMuscles" value={JSON.stringify(secondaryMuscles)} />
      </div>

      <div className="flex flex-col gap-1.5">
        <Label>Muscle Set Credits</Label>
        <p className="text-xs text-neutral-500">
          Fractional set credit per muscle group (e.g. 1.0 for full credit, 0.5 for half).
        </p>
        <div className="grid grid-cols-2 gap-3 rounded-md border border-neutral-200 p-3 sm:grid-cols-3 md:grid-cols-4">
          {MUSCLE_GROUPS.map((muscle) => (
            <div key={muscle} className="flex flex-col gap-1">
              <Label htmlFor={`credit-${muscle}`} className="text-xs font-normal text-neutral-600">
                {muscle}
              </Label>
              <Input
                id={`credit-${muscle}`}
                type="number"
                step="0.25"
                placeholder="0"
                value={muscleSetCredits[muscle] ?? ""}
                onChange={(e) => setCredit(muscle, e.target.value)}
              />
            </div>
          ))}
        </div>
        <input type="hidden" name="muscleSetCredits" value={JSON.stringify(muscleSetCredits)} />
      </div>

      <Button type="submit" className="w-fit">
        {defaultValues ? "Save Changes" : "Add Exercise"}
      </Button>
    </form>
  );
}
