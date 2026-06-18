import { notFound } from "next/navigation";
import { prisma } from "@/lib/db";
import { updateBodyMeasurement, deleteBodyMeasurement } from "@/lib/actions/measurements";
import { MeasurementForm } from "@/components/forms/MeasurementForm";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default async function EditMeasurementPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const measurement = await prisma.bodyMeasurement.findUnique({ where: { id } });
  if (!measurement) notFound();

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Edit Measurement</h1>
        <ConfirmDeleteButton action={deleteBodyMeasurement.bind(null, id)} />
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Edit Body Measurement</CardTitle>
        </CardHeader>
        <CardContent>
          <MeasurementForm action={updateBodyMeasurement.bind(null, id)} defaultValues={measurement} />
        </CardContent>
      </Card>
    </div>
  );
}
