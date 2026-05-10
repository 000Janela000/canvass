---
name: create-project
description: 'Reads an approved client brief from .claude/briefs/<slug>.md and scaffolds a new Next.js 16 + Tailwind 4 site at /Users/saba/Desktop/GitHub User/SiteCraft/<slug>/, matching SiteCraft conventions. Manual via /create-project <slug>.'
argument-hint: "<slug>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Bash, Glob, Grep, AskUserQuestion
effort: high
---
<!-- arcana-managed -->

# Create Project — Scaffold Client Site From Brief

The user has approved a brief produced by `/plan-project` and wants the actual website scaffolded. Your job: read the brief, set up a fresh Next.js 16 project as a sibling to SiteCraft, generate initial pages and theme from the brief, and start the dev server so the user can see the first draft.

**Input**: `$ARGUMENTS` — the brief slug (required, kebab-case).

**Target location:** `/Users/saba/Desktop/GitHub User/SiteCraft/<slug>/`
**Reference template:** `/Users/saba/Desktop/GitHub User/SiteCraft/Portfolio/` (read its package.json, components/, app/ for conventions)

## Gotchas

1. **Don't overwrite existing folders.** If `sitecraft-<slug>/` already exists, stop and ask the user before doing anything.
2. **Match SiteCraft's stack exactly.** Read SiteCraft's package.json — use the same Next.js, React, Tailwind, Radix versions. Do not silently upgrade.
3. **Never run `npm install` until package.json is written.** Bash will explode in a confusing way otherwise.
4. **Don't deploy or push.** Scaffold and dev-server only. Vercel + GitHub are separate manual steps after the user reviews the draft.
5. **The brief is the source of truth.** If the brief says "language: ka", the site copy MUST be in Georgian. Don't fall back to English defaults.
6. **Don't fabricate content the brief doesn't have.** If "Recommended Site Scope" lists 4 pages, scaffold exactly those 4. If brief is incomplete, stop and ask the user to update it before continuing.

---

## Step 1: Validate Input

1a. Confirm `$ARGUMENTS` is a non-empty kebab-case slug (no spaces, no slashes). If invalid, fail loudly.

1b. Read `.claude/briefs/$ARGUMENTS.md`. If missing, fail with: "No brief found at .claude/briefs/$ARGUMENTS.md. Run /plan-project first."

1c. Check target dir `/Users/saba/Desktop/GitHub User/sitecraft-$ARGUMENTS/` doesn't exist. If it does, use AskUserQuestion: overwrite (delete + rescaffold), pick new slug, or abort.

1d. Read the brief and parse all sections. If any of these are missing or empty, stop and ask the user to update the brief: Business Identity, Recommended Site Scope, Design Direction, Languages.

## Step 2: Read SiteCraft Conventions

2a. Read `/Users/saba/Desktop/GitHub User/SiteCraft/Portfolio/package.json` — note exact versions of next, react, tailwindcss, lucide-react, @radix-ui/*, class-variance-authority, clsx, tailwind-merge.

2b. Read SiteCraft's `tsconfig.json`, `next.config.mjs`, `postcss.config.mjs`, `components.json`. Use as templates.

2c. List `/Users/saba/Desktop/GitHub User/SiteCraft/Portfolio/app/` and `/Users/saba/Desktop/GitHub User/SiteCraft/Portfolio/components/` to understand layout and component naming conventions.

## Step 3: Scaffold Project Files

Create the new repo at `/Users/saba/Desktop/GitHub User/SiteCraft/<slug>/` with this structure:

```
sitecraft-<slug>/
├── app/
│   ├── layout.tsx          # Root layout, metadata from brief
│   ├── globals.css         # Tailwind 4 + theme tokens from brief colors
│   ├── page.tsx            # Home (hero + sections per brief)
│   └── <other-pages>/page.tsx  # One file per "Pages" entry in brief
├── components/
│   ├── ui/                 # Radix primitives copied from SiteCraft if needed
│   ├── Hero.tsx
│   ├── Section.tsx
│   └── Footer.tsx
├── lib/
│   └── utils.ts            # cn helper (copy from SiteCraft)
├── public/
│   └── README.md           # Notes on which placeholders to replace
├── next.config.mjs
├── package.json            # Versions matched to SiteCraft
├── postcss.config.mjs
├── tsconfig.json
├── components.json
├── .gitignore
└── README.md               # Brief summary, dev/build/deploy commands
```

3a. **Write each file** with the Write tool. Use brief data to fill content:
- **Hero**: business name + tagline from brief's "What they do"
- **Sections**: one section per item in brief's "Recommended Site Scope > Key features"
- **Page titles + meta descriptions**: in the brief's specified language(s)
- **Theme tokens** (CSS custom props in `globals.css`): colors from brief's Design Direction

3b. **Theme**: convert brief's hex colors into CSS custom properties:
```css
@theme inline {
  --color-primary: <hex1>;
  --color-secondary: <hex2>;
  --color-accent: <hex3>;
  --color-bg: <hex4 or #ffffff>;
  --color-fg: <hex5 or #0a0a0a>;
}
```
Use these in components via `bg-primary`, `text-fg`, etc. (Tailwind v4 picks them up automatically.)

3c. **Content language**: if brief says `ka`, all copy must be Georgian. If `en`, English. If `both`, scaffold a basic locale switch: keep `app/page.tsx` as default (ka) and add `app/en/page.tsx` mirroring it in English. No i18n library — just two route trees, simplest possible.

3d. **Placeholder images**: for each image slot, create a minimal SVG placeholder under `public/placeholders/` with a comment in the JSX: `{/* REPLACE: real photo of <what> */}`.

3e. **README.md** at project root summarizes:
- Business name, slug, brief generation date
- Stack (Next 16, React 19, Tailwind 4, Radix)
- `npm run dev`, `npm run build` commands
- Items from brief's "Need to create or request" list (so the user remembers what's missing)

## Step 4: Initialize Git and Install

4a. `cd` into the new dir. Run `git init -b main` (or just `git init` if older git).

4b. Run `npm install`. Stream output via Bash. If it fails, surface the full error and stop — don't try to recover.

4c. Run `git add -A && git commit -m "initial scaffold from /create-project for <slug>"`. Use the user's existing git config (do NOT override `user.name` or `user.email`).

## Step 5: Start Dev Server and Verify

5a. Run `npm run dev` in the **background** (use `run_in_background: true` on the Bash tool).

5b. Wait briefly, then `curl -s -o /dev/null -w "%{http_code}\n" http://localhost:3000`. Confirm 200.

5c. If port 3000 is already in use (LeadScout's frontend), kill the conflict warning and tell the user, suggesting they `docker compose down` LeadScout first OR use port 3001 by setting `PORT=3001 npm run dev`.

5d. Print: `✅ Dev server running at http://localhost:3000 — open in browser to see the first draft.`

## Step 6: Summary

Print:
```
✅ Scaffolded sitecraft-{slug} from brief

Location: /Users/saba/Desktop/GitHub User/sitecraft-{slug}/
Dev server: http://localhost:3000 (running in background)

First draft contains:
- {N} pages: {comma-separated list}
- Theme: {primary hex} primary, {secondary hex} accent
- Language: {ka | en | both}

What still needs human work (from brief's Content Plan):
- {bullet list of "Need to create or request" items}

Next steps:
1. Open http://localhost:3000 and review
2. Replace placeholders in public/placeholders/
3. Refine copy in app/page.tsx and per-page files
4. When ready: `gh repo create` and `vercel deploy`
```

## Guardrails

- NEVER deploy to Vercel automatically.
- NEVER push to GitHub automatically.
- NEVER touch SiteCraft itself. The new repo is a sibling, not nested.
- ALWAYS dev-server before declaring done — confirms the scaffold actually works.
- If the brief is incomplete (missing colors, pages, or "what they do"), stop and tell the user to update the brief first. Do not invent content.
- If a step fails (npm install, git init, port conflict), surface the error verbatim and stop. Do not silently retry or paper over.
