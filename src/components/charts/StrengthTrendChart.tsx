"use client";

import { useMemo, useState } from "react";
import { CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { formatDate } from "@/lib/utils";
import { Select } from "@/components/ui/select";

export interface StrengthSeriesPoint {
  date: string;
  topWeight: number;
  estimated1RM: number;
}

export function StrengthTrendChart({ seriesByExercise }: { seriesByExercise: Record<string, StrengthSeriesPoint[]> }) {
  const exerciseNames = useMemo(() => Object.keys(seriesByExercise), [seriesByExercise]);
  const [selected, setSelected] = useState(exerciseNames[0] ?? "");
  const data = seriesByExercise[selected] ?? [];

  return (
    <div className="flex h-full flex-col gap-2">
      <Select value={selected} onChange={(e) => setSelected(e.target.value)} className="h-8 w-48 text-xs">
        {exerciseNames.map((name) => (
          <option key={name} value={name}>
            {name}
          </option>
        ))}
      </Select>
      <div className="flex-1">
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={data} margin={{ top: 5, right: 16, bottom: 0, left: -16 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
            <XAxis dataKey="date" tickFormatter={(d) => formatDate(d, { month: "short", day: "numeric" })} tick={{ fontSize: 11 }} minTickGap={24} />
            <YAxis tick={{ fontSize: 11 }} width={40} domain={["auto", "auto"]} />
            <Tooltip labelFormatter={(d) => formatDate(d as string)} formatter={(value: unknown, name: unknown) => [Number(value).toFixed(0) + " lb", name as string]} />
            <Line type="monotone" dataKey="topWeight" name="Top set weight" stroke="#171717" strokeWidth={2} dot={{ r: 2 }} />
            <Line type="monotone" dataKey="estimated1RM" name="Est. 1RM" stroke="#2563eb" strokeWidth={1.5} strokeDasharray="5 3" dot={false} />
          </LineChart>
        </ResponsiveContainer>
      </div>
    </div>
  );
}
