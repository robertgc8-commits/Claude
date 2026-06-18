"use client";

import { Bar, CartesianGrid, ComposedChart, Legend, Line, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { formatDate } from "@/lib/utils";

export interface ProteinLeanPoint {
  date: string;
  proteinG: number | null;
  leanMass: number | null;
}

export function ProteinLeanChart({ data }: { data: ProteinLeanPoint[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <ComposedChart data={data} margin={{ top: 5, right: 16, bottom: 0, left: -16 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
        <XAxis dataKey="date" tickFormatter={(d) => formatDate(d, { month: "short", day: "numeric" })} tick={{ fontSize: 11 }} minTickGap={24} />
        <YAxis yAxisId="left" tick={{ fontSize: 11 }} width={40} />
        <YAxis yAxisId="right" orientation="right" tick={{ fontSize: 11 }} width={40} domain={["auto", "auto"]} />
        <Tooltip labelFormatter={(d) => formatDate(d as string)} />
        <Legend wrapperStyle={{ fontSize: 12 }} />
        <Bar yAxisId="left" dataKey="proteinG" name="Protein (g)" fill="#a3a3a3" radius={[3, 3, 0, 0]} />
        <Line yAxisId="right" type="monotone" dataKey="leanMass" name="Lean mass (lb)" stroke="#16a34a" strokeWidth={2} dot={{ r: 3 }} connectNulls />
      </ComposedChart>
    </ResponsiveContainer>
  );
}
