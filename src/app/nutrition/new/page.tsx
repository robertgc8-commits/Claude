import { createNutritionLog } from "@/lib/actions/nutrition";
import { NutritionLogForm } from "@/components/forms/NutritionLogForm";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function NewNutritionLogPage() {
  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-2xl font-bold">Add Nutrition Log</h1>
      <Card>
        <CardHeader>
          <CardTitle>New Nutrition Log</CardTitle>
        </CardHeader>
        <CardContent>
          <NutritionLogForm action={createNutritionLog} />
        </CardContent>
      </Card>
    </div>
  );
}
