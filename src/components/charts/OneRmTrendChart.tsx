"use client";

import { CartesianGrid, Legend, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { formatDate } from "@/lib/utils";

const COLORS = ["#171717", "#2563eb", "#dc2626", "#16a34a", "#ea580c", "#7c3aed", "#0891b2"];

export function OneRmTrendChart({ data, lifts }: { data: Record<string, unknown>[]; lifts: string[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <LineChart data={data} margin={{ top: 5, right: 16, bottom: 0, left: -16 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
        <XAxis dataKey="date" tickFormatter={(d) => formatDate(d, { month: "short", day: "numeric" })} tick={{ fontSize: 11 }} minTickGap={24} />
        <YAxis tick={{ fontSize: 11 }} width={40} domain={["auto", "auto"]} />
        <Tooltip labelFormatter={(d) => formatDate(d as string)} formatter={(value: unknown, name: unknown) => [Number(value).toFixed(0) + " lb", name as string]} />
        <Legend wrapperStyle={{ fontSize: 11 }} />
        {lifts.map((lift, i) => (
          <Line
            key={lift}
            type="monotone"
            dataKey={lift}
            name={lift}
            stroke={COLORS[i % COLORS.length]}
            strokeWidth={2}
            dot={{ r: 2 }}
            connectNulls
          />
        ))}
      </LineChart>
    </ResponsiveContainer>
  );
}
