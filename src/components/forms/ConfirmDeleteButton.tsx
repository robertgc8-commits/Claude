"use client";

import { Button } from "@/components/ui/button";

export function ConfirmDeleteButton({
  action,
  label = "Delete",
  confirmMessage = "Are you sure you want to delete this? This cannot be undone.",
}: {
  action: () => Promise<void>;
  label?: string;
  confirmMessage?: string;
}) {
  return (
    <form
      action={action}
      onSubmit={(e) => {
        if (!confirm(confirmMessage)) e.preventDefault();
      }}
    >
      <Button type="submit" variant="destructive" size="sm">
        {label}
      </Button>
    </form>
  );
}
