"use client";

import { Bar, BarChart, CartesianGrid, Cell, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

export interface MuscleVolumeBar {
  muscle: string;
  hardSets: number;
  classification: "understimulated" | "optimal" | "excessive";
}

const COLOR_BY_CLASS: Record<string, string> = {
  understimulated: "#f59e0b",
  optimal: "#16a34a",
  excessive: "#dc2626",
};

export function MuscleVolumeChart({ data }: { data: MuscleVolumeBar[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={data} layout="vertical" margin={{ top: 5, right: 16, bottom: 0, left: 8 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
        <XAxis type="number" tick={{ fontSize: 11 }} />
        <YAxis type="category" dataKey="muscle" tick={{ fontSize: 11 }} width={80} />
        <Tooltip formatter={(value: unknown) => [Number(value).toFixed(1) + " hard sets"]} />
        <Bar dataKey="hardSets" radius={[0, 4, 4, 0]}>
          {data.map((d) => (
            <Cell key={d.muscle} fill={COLOR_BY_CLASS[d.classification]} />
          ))}
        </Bar>
      </BarChart>
    </ResponsiveContainer>
  );
}
