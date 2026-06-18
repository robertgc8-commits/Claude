"use client";

import { Area, AreaChart, CartesianGrid, Legend, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { formatDate } from "@/lib/utils";

export interface FatLeanPoint {
  date: string;
  fatMass: number | null;
  leanMass: number | null;
}

export function FatLeanChart({ data }: { data: FatLeanPoint[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <AreaChart data={data} margin={{ top: 5, right: 16, bottom: 0, left: -16 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
        <XAxis dataKey="date" tickFormatter={(d) => formatDate(d, { month: "short", day: "numeric" })} tick={{ fontSize: 11 }} minTickGap={24} />
        <YAxis tick={{ fontSize: 11 }} width={40} />
        <Tooltip labelFormatter={(d) => formatDate(d as string)} formatter={(value: unknown, name: unknown) => [Number(value).toFixed(1) + " lb", name as string]} />
        <Legend wrapperStyle={{ fontSize: 12 }} />
        <Area type="monotone" dataKey="leanMass" name="Lean mass" stackId="1" stroke="#16a34a" fill="#16a34a" fillOpacity={0.25} connectNulls />
        <Area type="monotone" dataKey="fatMass" name="Fat mass" stackId="1" stroke="#dc2626" fill="#dc2626" fillOpacity={0.25} connectNulls />
      </AreaChart>
    </ResponsiveContainer>
  );
}
