const DAY_MS = 86_400_000;

export function mondayOf(date: Date): Date {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  const day = d.getDay();
  const diff = day === 0 ? -6 : 1 - day;
  return new Date(d.getTime() + diff * DAY_MS);
}

/** Next occurrence of `dayOfWeek` (0=Sun..6=Sat) at/after `from`. */
export function nextWeekday(from: Date, dayOfWeek: number): Date {
  const d = new Date(from);
  d.setHours(0, 0, 0, 0);
  const diff = (dayOfWeek - d.getDay() + 7) % 7;
  return new Date(d.getTime() + diff * DAY_MS);
}

export interface CheckInLike {
  weekStartDate: Date;
  completed: boolean;
}

export function isThisWeekCompleted(checkIns: CheckInLike[], asOf: Date, dayOfWeek = 3): boolean {
  const thisMonday = mondayOf(asOf);
  return checkIns.some((c) => c.completed && mondayOf(c.weekStartDate).getTime() === thisMonday.getTime());
}

/** Count consecutive completed weeks, walking backward from the most recent. */
export function computeStreak(checkIns: CheckInLike[], asOf: Date): number {
  const weeks = new Set(
    checkIns.filter((c) => c.completed).map((c) => mondayOf(c.weekStartDate).getTime())
  );
  let streak = 0;
  let cursor = mondayOf(asOf).getTime();
  // If this week isn't done yet, start counting from last week so an
  // in-progress week doesn't break an otherwise-intact streak.
  if (!weeks.has(cursor)) cursor -= 7 * DAY_MS;
  while (weeks.has(cursor)) {
    streak++;
    cursor -= 7 * DAY_MS;
  }
  return streak;
}

export function missedLastWeighIn(checkIns: CheckInLike[], asOf: Date, dayOfWeek = 3): boolean {
  const lastScheduled = nextWeekday(new Date(asOf.getTime() - 7 * DAY_MS), dayOfWeek);
  if (lastScheduled.getTime() >= mondayOf(asOf).getTime()) return false; // not due yet this cycle
  return !checkIns.some((c) => c.completed && mondayOf(c.weekStartDate).getTime() === mondayOf(lastScheduled).getTime());
}
