import { createMedicationDose } from "@/lib/actions/medication";
import { MedicationDoseForm } from "@/components/forms/MedicationDoseForm";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";

export default function NewMedicationDosePage() {
  return (
    <div className="flex flex-col gap-4">
      <h1 className="text-2xl font-bold">Add Dose</h1>
      <Card>
        <CardHeader>
          <CardTitle>New Medication Dose</CardTitle>
        </CardHeader>
        <CardContent>
          <MedicationDoseForm action={createMedicationDose} />
        </CardContent>
      </Card>
    </div>
  );
}
