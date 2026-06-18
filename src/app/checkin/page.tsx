import { prisma } from "@/lib/db";
import { submitWeeklyCheckIn } from "@/lib/actions/checkin";
import { CheckInForm } from "@/components/forms/CheckInForm";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { formatDate } from "@/lib/utils";

export const dynamic = "force-dynamic";

export default async function CheckInPage() {
  const lastCheckIn = await prisma.weeklyCheckIn.findFirst({ orderBy: { date: "desc" } });
  const asOf = new Date();
  const daysSinceLast = lastCheckIn
    ? Math.round((asOf.getTime() - lastCheckIn.date.getTime()) / 86_400_000)
    : null;

  return (
    <div className="flex flex-col gap-4">
      <div>
        <h1 className="text-2xl font-bold">Wednesday Check-In</h1>
        <p className="text-sm text-neutral-500">
          Log this week&apos;s body measurement, medication, and subjective ratings in one pass.
        </p>
        {lastCheckIn && (
          <p className="mt-1 text-xs text-neutral-400">
            Last check-in: {formatDate(lastCheckIn.date)} ({daysSinceLast} day{daysSinceLast === 1 ? "" : "s"} ago)
          </p>
        )}
      </div>
      <Card>
        <CardHeader>
          <CardTitle>New Weekly Check-In</CardTitle>
        </CardHeader>
        <CardContent>
          <CheckInForm action={submitWeeklyCheckIn} />
        </CardContent>
      </Card>
    </div>
  );
}
