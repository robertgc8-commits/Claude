import { createGoal } from "@/lib/actions/goals";
import { GoalForm } from "@/components/forms/GoalForm";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function NewGoalPage() {
  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-2xl font-bold">Add Goal</h1>
      <Card>
        <CardHeader>
          <CardTitle>New Goal</CardTitle>
        </CardHeader>
        <CardContent>
          <GoalForm action={createGoal} />
        </CardContent>
      </Card>
    </div>
  );
}
