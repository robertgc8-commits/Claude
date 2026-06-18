import { notFound } from "next/navigation";
import { prisma } from "@/lib/db";
import { updateMedicationDose, deleteMedicationDose } from "@/lib/actions/medication";
import { MedicationDoseForm } from "@/components/forms/MedicationDoseForm";
import { ConfirmDeleteButton } from "@/components/forms/ConfirmDeleteButton";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default async function EditMedicationDosePage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = await params;
  const dose = await prisma.medicationDose.findUnique({ where: { id } });
  if (!dose) notFound();

  return (
    <div className="flex flex-col gap-4">
      <div className="flex items-center justify-between">
        <h1 className="text-2xl font-bold">Edit Dose</h1>
        <ConfirmDeleteButton action={deleteMedicationDose.bind(null, id)} />
      </div>
      <Card>
        <CardHeader>
          <CardTitle>Edit Medication Dose</CardTitle>
        </CardHeader>
        <CardContent>
          <MedicationDoseForm action={updateMedicationDose.bind(null, id)} defaultValues={dose} />
        </CardContent>
      </Card>
    </div>
  );
}
