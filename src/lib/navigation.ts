export interface NavItem {
  href: string;
  label: string;
}

export interface NavSection {
  title: string;
  items: NavItem[];
}

export const NAV_SECTIONS: NavSection[] = [
  {
    title: "Overview",
    items: [
      { href: "/", label: "Dashboard" },
      { href: "/checkin", label: "Wednesday Check-In" },
      { href: "/reports", label: "Progress Reports" },
    ],
  },
  {
    title: "Log",
    items: [
      { href: "/measurements", label: "Body Measurements" },
      { href: "/medication", label: "Medication" },
      { href: "/workouts", label: "Workouts" },
      { href: "/nutrition", label: "Nutrition" },
      { href: "/recovery", label: "Recovery" },
    ],
  },
  {
    title: "Manage",
    items: [
      { href: "/exercises", label: "Exercise Library" },
      { href: "/goals", label: "Goals" },
    ],
  },
  {
    title: "Analyze",
    items: [
      { href: "/dose-analysis", label: "Dose Analysis" },
      { href: "/lean-mass", label: "Lean Mass Preservation" },
      { href: "/strength", label: "Strength Preservation" },
      { href: "/projections", label: "Goal Projections" },
    ],
  },
];

export const MOBILE_PRIMARY_NAV: NavItem[] = [
  { href: "/", label: "Home" },
  { href: "/checkin", label: "Check-In" },
  { href: "/workouts", label: "Workouts" },
  { href: "/nutrition", label: "Nutrition" },
];
