---
name: plan-project
description: 'Deep-researches a prospect business via Facebook/Instagram/website analysis and produces a structured client brief at .claude/briefs/<slug>.md ready to feed /create-project. Manual via /plan-project.'
argument-hint: "<facebook-url | instagram-url | leadscout-id | business-name-and-city>"
disable-model-invocation: true
allowed-tools: Read, Write, Edit, Glob, Grep, Bash, Agent, AskUserQuestion, WebSearch, WebFetch, mcp__apify__*, mcp__playwright__*
effort: high
---
<!-- arcana-managed -->

# Plan Project — Client Research & Brief Generation

The user has identified a prospect (a Georgian SMB without a website, surfaced by LeadScout or known directly). Your job: deep-research the business, understand who they are and who their customers are, identify what kind of website would actually help them, and produce a brief that `/create-project` can act on.

**Input**: `$ARGUMENTS` — may be:
- A LeadScout lead ID (integer): query backend SQLite at `backend/data/leads.db`
- A Facebook URL: `https://facebook.com/...`
- An Instagram URL: `https://instagram.com/...`
- Free text business name with city: `"Cafe Aragvi Tbilisi"`
- Empty: ask the user interactively for one of the above

## Gotchas

1. **Apify costs real money.** Each Facebook Pages Scraper or Instagram Profile Scraper run costs ~$0.30–$1.50 in Apify credit. Budget: at most ONE of each per skill invocation. Do NOT batch or loop. If both FB and IG URLs are known, run both. If only one is known, run only that one.
2. **The brief is for /create-project, not for the user to read prose.** Write it as structured Markdown sections that another Claude session can parse mechanically. Use bullet lists and clear headings; avoid soft prose.
3. **Don't make up data.** If the FB scrape returns empty, the brief should literally say "Facebook page found but no posts/photos accessible." Never invent followers, posts, or product info.
4. **Q&A is one question at a time.** Use AskUserQuestion. Do NOT bundle multiple questions. The user explicitly asked for one-at-a-time interaction.
5. **Slug must be deterministic.** Generate from business name: lowercase, hyphens, no special chars (e.g., "Cafe Aragvi" → `cafe-aragvi`). Confirm with the user before writing the brief if the auto-slug feels wrong.
6. **Stop on insufficient signal.** If the prospect has no FB, no IG, no website, and no LeadScout phone/email/address, stop. Tell the user the prospect is unanalysable; don't fabricate a brief from nothing.

---

## Step 1: Resolve Input

1a. **Detect input type** from `$ARGUMENTS`:
- Pure integer → LeadScout lead ID
- Matches `^https?://(www\.)?facebook\.com` → FB URL
- Matches `^https?://(www\.)?instagram\.com` → IG URL
- Other text → business name search
- Empty → interactive

1b. **If empty**, use AskUserQuestion: "What prospect should I analyze?" with options for the four input types. Then re-route based on answer.

1c. **If LeadScout ID**: query SQLite at `backend/data/leads.db`:
```bash
sqlite3 backend/data/leads.db "SELECT name, city, category, phone, email, address, facebook_url, google_rating, google_review_count FROM leads WHERE id = $ID;"
```
Extract those fields as known facts.

1d. **If FB or IG URL only**: extract the page handle from the URL. Set `business_name` from the handle as a placeholder; refine after scraping.

1e. **If business name only**: use WebSearch to find their FB and IG. Confirm the match with the user via AskUserQuestion before paying for an Apify scrape.

1f. **Generate slug** from final business name (kebab-case, ≤30 chars, ASCII only — transliterate Georgian if needed). Print it. If it feels wrong, AskUserQuestion to confirm or override.

## Step 2: Pull Data

Create `.claude/research/` if it doesn't exist (mkdir -p via Bash).

2a. **Facebook scrape (if FB URL exists):**
Use the Apify MCP. The actor is `apify/facebook-pages-scraper`. Pass the FB URL with parameters: `resultsLimit: 30` (posts), include photos and reviews. Save raw JSON to `.claude/research/<slug>-fb.json`.

2b. **Instagram scrape (if IG URL exists):**
Use the Apify MCP. The actor is `apify/instagram-profile-scraper`. Pass the IG handle. Request: profile details, posts (limit 20), reels (limit 5). Save raw JSON to `.claude/research/<slug>-ig.json`.

2c. **Existing website (if any):**
Use the Playwright MCP. Navigate to the site. Take a homepage screenshot (save under `.claude/research/<slug>-site.png`). Extract page text and meta. Capture observations to `.claude/research/<slug>-site.md`:
- SSL valid?
- Mobile viewport works?
- Last-modified or copyright year visible in footer?
- Tech stack hints (Next, WordPress, static, builder)?
- Obvious design issues?

2d. **No-data fallback:**
If neither FB nor IG nor website is reachable AND no LeadScout data exists, stop. Tell the user this prospect can't be analyzed without more input. Do NOT proceed to Step 3.

2e. **Apify failure fallback:**
If Apify call errors (no credit, blocked, network), use the Playwright MCP to navigate to the FB/IG page directly and read whatever public content is visible. The brief gets thinner but still useful. Note the fallback explicitly in the brief's "Current Online Presence" section.

## Step 3: Analyze

Read the JSON, screenshots, and notes you gathered. Synthesize the following internally before writing anything:

3a. **Business identity** — what they actually do, in one sentence. Inferable price point (cheap / mid / premium) from photos and reviews. Languages they post in.

3b. **Target customer** — based on who comments, what posts get engagement, who's tagged. Demographic signals: locals vs tourists, age range, casual vs professional context.

3c. **Brand voice** — formal/casual, posting frequency (daily/weekly/dead), emoji usage, professional photography vs phone snapshots, use of branded graphics or stock.

3d. **Pain points / website opportunity:**
- Do customers ask the same questions repeatedly in comments? → FAQ candidate
- Are prices visible anywhere? If not, do customers ask about prices? → pricing page candidate
- Are hours, address, menu, services easy to find on FB? (Usually no — website wins.)
- Do they get DMs about booking, ordering, or quotes? → form/scheduling candidate
- Photography quality? → flag if a photo shoot is needed before launch.

3e. **Brand colors / mood** — extract 3–5 dominant colors from cover photo + recent posts. Note: warm/cool, minimal/busy, modern/traditional.

## Step 4: Interactive Q&A (One at a Time)

Use AskUserQuestion **one question at a time**. Aim for 2–4 total; stop earlier if the picture is already clear.

Pick the highest-leverage questions for THIS prospect. Examples:
- "Their photos look amateur — should we plan a photo shoot or use what they have for the first draft?"
- "They post in Georgian and English — site language: ka, en, or bilingual?"
- "I see no prices anywhere on FB — should the site show prices, or just 'request a quote'?"
- "I see {N} repeated questions about {topic} in their comments — should we add {feature X}?"
- "Their FB suggests {industry-specific need: delivery / booking / portfolio / online order} — confirm that's a Phase 1 priority?"

DO NOT ask:
- Questions whose answer is already in the data ("what's their phone")
- Vague preference questions you have no signal on ("what colors do you want") — extract from their existing brand instead

## Step 5: Write the Brief

Create `.claude/briefs/<slug>.md` with this exact structure:

```markdown
# Client Brief — {Business Name}

> Generated by /plan-project on YYYY-MM-DD
> Slug: {slug}
> Sources: {fb | ig | website | leadscout — list which}

## Business Identity
- **Name:** ...
- **City:** ...
- **Category:** ...
- **What they do:** (1 sentence)
- **Price point:** (cheap | mid | premium)
- **Languages:** (ka | en | ru | mix)

## Their Customers
- **Primary audience:** ...
- **Demographic signals:** ...
- **What they ask about most:** ...

## Current Online Presence
- **Facebook:** {url} — {N} followers, last post {date}, ~{posts/month}
- **Instagram:** {url or "none"} — {followers, posts/month}
- **Existing website:** {url or "none"} — {top 3 issues if any}

## Why They Need a Website
1. ...
2. ...
3. ...

## Recommended Site Scope (Phase 1)
- **Pages:** Home, About, {Services|Menu|Portfolio}, Contact, ...
- **Key features:** {booking | ordering | gallery | reservations | ...}
- **Integrations:** {google maps embed | FB feed | calendar | ...}
- **Languages:** {ka | en | both}

## Design Direction
- **Mood:** ...
- **Colors:** {3-5 hex codes extracted from their brand}
- **Typography hint:** {modern sans | traditional serif | display | ...}
- **Reference vibe:** {1 line — e.g. "warm/inviting like a Tbilisi family restaurant"}

## Content Plan
- **Already have (from FB/IG):**
  - {photo count}
  - {usable copy snippets — quote or summarize}
  - {services/menu items}
- **Need to create or request:**
  - {pricing}
  - {professional photos of X}
  - {about copy}

## Open Questions
{anything the user couldn't answer in Q&A — flagged for follow-up before launch}
```

Write only this file. Do not write code, scaffold projects, or create folders outside `.claude/`.

## Step 6: Hand-off

Print to user:
```
✅ Brief written to .claude/briefs/{slug}.md

Review it, edit anything wrong, then run:
  /create-project {slug}

Open questions for you to resolve manually before launch:
- {list any items from the "Open Questions" section}
```

Stop. Do NOT scaffold. The user controls when `/create-project` runs.

## Guardrails

- NEVER scrape the same target twice in one invocation (Apify credits are real money).
- NEVER write code, run `npm install`, or scaffold a project. That's `/create-project`'s job.
- NEVER skip Step 4 (Q&A). The brief without user input is just data, not a brief.
- ALWAYS write the brief even if some sections are sparse. Empty sections are signal too.
- If Apify is unavailable, fall back to Playwright + manual analysis. The brief still gets written.
- The brief MUST be parseable by another Claude session. Use the exact heading structure in Step 5.
