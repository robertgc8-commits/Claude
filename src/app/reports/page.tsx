import Link from "next/link";
import { prisma } from "@/lib/db";
import { generateWeeklyReport, generateMonthlyReport } from "@/lib/actions/reports";
import { RatingBadge } from "@/components/dashboard/RatingBadge";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Table, TableHeader, TableBody, TableRow, TableHead, TableCell } from "@/components/ui/table";
import { Button } from "@/components/ui/button";
import { formatDate } from "@/lib/utils";
import type { Rating } from "@/lib/constants";

export const dynamic = "force-dynamic";

export default async function ReportsPage() {
  const [weeklyReports, monthlyReports] = await Promise.all([
    prisma.weeklyProgressReport.findMany({
      orderBy: { weekStartDate: "desc" },
      include: { insights: true, recommendations: true },
    }),
    prisma.monthlyProgressReport.findMany({
      orderBy: { monthStartDate: "desc" },
      include: { insights: true, recommendations: true },
    }),
  ]);

  return (
    <div className="flex flex-col gap-6">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Progress Reports</h1>
        <div className="flex gap-2">
          <form
            action={async () => {
              "use server";
              await generateWeeklyReport();
            }}
          >
            <Button type="submit" variant="outline" size="sm">
              Generate Weekly Report
            </Button>
          </form>
          <form
            action={async () => {
              "use server";
              await generateMonthlyReport();
            }}
          >
            <Button type="submit" variant="outline" size="sm">
              Generate Monthly Report
            </Button>
          </form>
        </div>
      </div>

      <Card>
        <CardHeader>
          <CardTitle>Weekly Reports</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Week</TableHead>
                <TableHead>Overall Rating</TableHead>
                <TableHead>Unresolved Insights</TableHead>
                <TableHead>Unresolved Recommendations</TableHead>
                <TableHead></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {weeklyReports.map((r) => (
                <TableRow key={r.id}>
                  <TableCell>
                    {formatDate(r.weekStartDate)} - {formatDate(r.weekEndDate)}
                  </TableCell>
                  <TableCell>
                    <RatingBadge rating={r.overallRating as Rating} />
                  </TableCell>
                  <TableCell>{r.insights.filter((i) => !i.resolved).length}</TableCell>
                  <TableCell>{r.recommendations.filter((rec) => !rec.resolved).length}</TableCell>
                  <TableCell className="text-right">
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/reports/${r.id}`}>View</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {weeklyReports.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="py-8 text-center text-neutral-500">
                    No weekly reports yet.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>Monthly Reports</CardTitle>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Month</TableHead>
                <TableHead>Generated</TableHead>
                <TableHead>Unresolved Insights</TableHead>
                <TableHead>Unresolved Recommendations</TableHead>
                <TableHead></TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {monthlyReports.map((r) => (
                <TableRow key={r.id}>
                  <TableCell>
                    {formatDate(r.monthStartDate)} - {formatDate(r.monthEndDate)}
                  </TableCell>
                  <TableCell>{formatDate(r.generatedAt)}</TableCell>
                  <TableCell>{r.insights.filter((i) => !i.resolved).length}</TableCell>
                  <TableCell>{r.recommendations.filter((rec) => !rec.resolved).length}</TableCell>
                  <TableCell className="text-right">
                    <Button asChild variant="outline" size="sm">
                      <Link href={`/reports/${r.id}`}>View</Link>
                    </Button>
                  </TableCell>
                </TableRow>
              ))}
              {monthlyReports.length === 0 && (
                <TableRow>
                  <TableCell colSpan={5} className="py-8 text-center text-neutral-500">
                    No monthly reports yet.
                  </TableCell>
                </TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}
