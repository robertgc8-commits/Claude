import { createBodyMeasurement } from "@/lib/actions/measurements";
import { MeasurementForm } from "@/components/forms/MeasurementForm";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function NewMeasurementPage() {
  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-2xl font-bold">Add Measurement</h1>
      <Card>
        <CardHeader>
          <CardTitle>New Body Measurement</CardTitle>
        </CardHeader>
        <CardContent>
          <MeasurementForm action={createBodyMeasurement} />
        </CardContent>
      </Card>
    </div>
  );
}
