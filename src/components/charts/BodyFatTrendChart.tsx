"use client";

import { CartesianGrid, Line, LineChart, ResponsiveContainer, Tooltip, XAxis, YAxis } from "recharts";
import { formatDate } from "@/lib/utils";

export interface BodyFatChartPoint {
  date: string;
  bodyFatPercent: number | null;
  trend: number | null;
}

export function BodyFatTrendChart({ data }: { data: BodyFatChartPoint[] }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <LineChart data={data} margin={{ top: 5, right: 16, bottom: 0, left: -16 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
        <XAxis dataKey="date" tickFormatter={(d) => formatDate(d, { month: "short", day: "numeric" })} tick={{ fontSize: 11 }} minTickGap={24} />
        <YAxis domain={["auto", "auto"]} tick={{ fontSize: 11 }} width={40} unit="%" />
        <Tooltip labelFormatter={(d) => formatDate(d as string)} formatter={(value: unknown, name: unknown) => [Number(value).toFixed(1) + "%", name as string]} />
        <Line type="monotone" dataKey="bodyFatPercent" name="Body fat %" stroke="#ea580c" strokeWidth={2} dot={{ r: 3 }} connectNulls />
        <Line type="monotone" dataKey="trend" name="Trend" stroke="#2563eb" strokeWidth={1.5} strokeDasharray="5 3" dot={false} connectNulls />
      </LineChart>
    </ResponsiveContainer>
  );
}
