# Recomp Tracker

A private, single-user tracker for body composition, Zepbound dosing, and strength training during a fat-loss phase. Built with Next.js (App Router), TypeScript, Prisma + SQLite, Tailwind CSS, and Recharts.

No authentication is built in — this is intended to run locally or on a private deployment for one person. The data layer and server actions are structured so an auth/session layer (and a multi-tenant `userId` column) could be added later without restructuring the app: every Prisma model and query is already scoped to flow through a single `prisma` client, and pages fetch data server-side rather than trusting client state.

## Stack

- **Next.js 16** App Router, Server Actions for all writes (no separate API routes needed)
- **Prisma 6** + SQLite for local storage (swap the `datasource` provider/url in `prisma/schema.prisma` to point at Postgres later — no model changes required)
- **Zod 4** for all form validation
- **Tailwind CSS v4** + hand-rolled Radix-based UI primitives in `src/components/ui`
- **Recharts** for all charts

## Getting Started

```bash
npm install
npm run db:push   # create the SQLite database from prisma/schema.prisma
npm run db:seed   # populate it with sample historical data
npm run dev        # start the dev server at http://localhost:3000
```

The seed script (`prisma/seed.ts`) creates a realistic history: weekly weigh-ins, two full body-composition scans, Zepbound dose escalation, workouts with sets, nutrition logs, and recovery logs spanning roughly April–June. Use it as a reference for the shape of data each page expects, or wipe it and start fresh.

## Database commands

| Command | What it does |
|---|---|
| `npm run db:push` | Applies `prisma/schema.prisma` to the SQLite database (creates `prisma/prisma/dev.db` if missing) |
| `npm run db:seed` | Runs `prisma/seed.ts` to populate sample data |
| `npm run db:studio` | Opens Prisma Studio, a GUI for browsing/editing the database directly |
| `npm run db:reset` | Drops and recreates the schema, then reseeds — use this if you want to start over |

After editing `prisma/schema.prisma`, run `npm run db:push` again to apply the change (this project uses `db push` rather than migrations, which is the simpler workflow for a single-developer local app — switch to `prisma migrate` if you need a migration history later).

## Adding new body measurement fields

The body-composition metrics tracked (weight, body fat %, muscle mass, visceral fat, etc.) live in three places that need to stay in sync:

1. **`prisma/schema.prisma`** — add the column to the `BodyMeasurement` model, then run `npm run db:push`.
2. **`src/lib/validations.ts`** — add the field to `bodyMeasurementSchema` (use the `optionalNumber`/`optionalInt`/`optionalString` helpers already defined there for nullable fields).
3. **`src/components/forms/MeasurementForm.tsx`** — add an `<Input>` for the new field.

If the new metric should also factor into the weekly check-in flow, add it to `weeklyCheckInSchema` in the same file, the `CheckInForm` component, and the `submitWeeklyCheckIn` action in `src/lib/actions/checkin.ts`.

## App structure

- `src/lib/calculations.ts` — pure functions for body-composition math (FFMI, fat/lean mass), 1RM estimates (Epley/Brzycki/Lombardi), volume load, rolling averages, linear trendlines, and Zepbound dose-phase grouping.
- `src/lib/insights.ts` — builds the weekly summary, generates insights/recommendations, computes the overall rating and Muscle Retention Score.
- `src/lib/strength.ts` — key-lift trend series and the 5%/30-day and 10%/60-day strength-decline warnings.
- `src/lib/muscleVolume.ts` — hard-set classification and per-muscle-group weekly volume tallying.
- `src/lib/schedule.ts` — Wednesday weigh-in scheduling, streak, and missed-check-in logic.
- `src/lib/actions/*` — all server actions (one file per entity), each validating with Zod before writing through Prisma.
- `src/app/*` — one route per entity (list/new/`[id]/edit`) plus the analysis pages: `/dose-analysis`, `/lean-mass`, `/strength`, `/projections`, `/checkin`, `/reports`.

## Deployment

This app has no auth and reads/writes a local SQLite file, so it's meant for a private deployment (e.g., a personal VPS, a Vercel deployment with the database swapped to managed Postgres, or just running `npm run build && npm run start` on a machine you control). Before deploying anywhere reachable from the internet, add an authentication layer — the server actions in `src/lib/actions/*` are the natural place to add a session/ownership check.

To deploy with Postgres instead of SQLite:
1. Change `datasource db { provider = "postgresql" ... }` in `prisma/schema.prisma`.
2. Set `DATABASE_URL` to your Postgres connection string.
3. Run `npm run db:push` (or switch to `prisma migrate deploy` for a tracked migration history) against the new database.
4. `npm run build && npm run start`.
