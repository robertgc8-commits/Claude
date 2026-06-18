"use client";

import {
  CartesianGrid,
  Line,
  LineChart,
  ReferenceLine,
  ResponsiveContainer,
  Tooltip,
  XAxis,
  YAxis,
} from "recharts";
import { formatDate } from "@/lib/utils";

export interface WeightChartPoint {
  date: string;
  weight: number;
  rollingAvg: number | null;
  trend: number | null;
}

export function WeightTrendChart({ data, goalWeight }: { data: WeightChartPoint[]; goalWeight: number }) {
  return (
    <ResponsiveContainer width="100%" height="100%">
      <LineChart data={data} margin={{ top: 5, right: 16, bottom: 0, left: -16 }}>
        <CartesianGrid strokeDasharray="3 3" stroke="#e5e5e5" />
        <XAxis
          dataKey="date"
          tickFormatter={(d) => formatDate(d, { month: "short", day: "numeric" })}
          tick={{ fontSize: 11 }}
          minTickGap={24}
        />
        <YAxis domain={["auto", "auto"]} tick={{ fontSize: 11 }} width={40} />
        <Tooltip
          labelFormatter={(d) => formatDate(d as string)}
          formatter={(value: unknown, name: unknown) => [Number(value).toFixed(1), name as string]}
        />
        <ReferenceLine y={goalWeight} stroke="#16a34a" strokeDasharray="4 4" label={{ value: "Goal", fontSize: 11, fill: "#16a34a" }} />
        <Line type="monotone" dataKey="weight" name="Weight" stroke="#a3a3a3" strokeWidth={1.5} dot={{ r: 2 }} />
        <Line type="monotone" dataKey="rollingAvg" name="7-day avg" stroke="#171717" strokeWidth={2} dot={false} />
        <Line type="monotone" dataKey="trend" name="Trend" stroke="#2563eb" strokeWidth={1.5} strokeDasharray="5 3" dot={false} />
      </LineChart>
    </ResponsiveContainer>
  );
}
