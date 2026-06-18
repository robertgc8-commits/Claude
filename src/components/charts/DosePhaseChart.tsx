"use client";

import { Bar, BarChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";

export interface DosePhaseBar {
  phase: string;
  totalLossLb: number;
  avgWeeklyLossLb: number;
}

export function DosePhaseChart({ data }: { data: DosePhaseBar[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <BarChart data={data} margin={{ top: 5, right: 16, bottom: 0, left: -16 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
        <XAxis dataKey="phase" tick={{ fontSize: 11 }} />
        <YAxis tick={{ fontSize: 11 }} width={40} />
        <Tooltip formatter={(value: unknown, name: unknown) => [Number(value).toFixed(1) + " lb", name as string]} />
        <Legend wrapperStyle={{ fontSize: 12 }} />
        <Bar dataKey="totalLossLb" name="Total loss" fill="#171717" radius={[4, 4, 0, 0]} />
        <Bar dataKey="avgWeeklyLossLb" name="Avg loss/week" fill="#a3a3a3" radius={[4, 4, 0, 0]} />
      </BarChart>
    </ResponsiveContainer>
  );
}
