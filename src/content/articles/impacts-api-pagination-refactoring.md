---
title: 'My First Backend API in an Enterprise Monorepo: 42 Commits of Learning'
description: 'What it was like to build my first backend API endpoint two months into a new job — in an Nx monorepo I had never seen before, with conventions I had never heard of.'
pubDate: '2026-03-06'
tags: ['backend', 'api-design', 'career', 'learning']
draft: false
---

Two months into my new job, I was asked to build a new paginated API endpoint. I was a frontend developer. I had worked with DDD before, but never in a Node.js backend. I had never touched an Nx monorepo. I barely knew Knex.

Forty-two commits later, the feature was merged. This is what I learned — and why I think AI tools would have cut that learning curve in half.

## The Setup

The backend was a Node.js/TypeScript monorepo managed by Nx, with multiple microservices and shared libraries. The architecture followed strict DDD layering:

```
Controllers → Use Cases → DAOs → Database Functions
```

I'd worked with DDD layering before, but every codebase implements it differently. Where exactly does validation live — controller or use case? What counts as "business logic" versus "just calling the database"? How strict are the boundaries between layers?

The concepts were familiar. The specific conventions were not. And in an enterprise monorepo, conventions are everything.

## The Overwhelming Part

It wasn't the code. Code is code — TypeScript on the backend isn't that different from TypeScript on the frontend. What overwhelmed me was everything *around* the code:

**The monorepo structure.** Nx organizes code into apps and libraries with strict dependency rules. You can't import from anywhere — there are boundaries enforced by linting. I spent my first week just figuring out *where* things lived. Which library owns the impact types? Where do the DAO interfaces go? Why does this import fail with a circular dependency error?

**The conventions.** Commit message format. PR description template. Test file naming. How to structure a controller method versus a use case method. Where validation happens (controller boundary, not deep in the use case). How errors are thrown (custom domain errors, not generic `throw new Error()`). None of this was written in a single document — it was spread across README files, linting rules, PR review comments, and the codebase itself.

**The review process.** My PR came back with comments I hadn't anticipated. Not because the code was bad — it worked. But I had validation logic in the wrong layer. I was throwing generic errors instead of custom domain errors. My test mocked at the wrong boundary.

Every comment was a convention I didn't know existed.

## The Actual Feature

The task was to build a new `GET` endpoint that returned impact records filtered by a given fact sheet, with pagination. The frontend needed to display these in a table, and loading everything at once wasn't going to scale.

The design decisions were straightforward once I understood the patterns:

**Offset-based pagination with `page` and `size`.** The consumer sends a page number and page size, the backend calculates the offset (`(page - 1) * size`), and returns the slice along with a `totalCount`. Simple, stateless, and easy to implement.

**Paginate after mapping, not in SQL.** I initially tried to paginate at the database level — seemed like the smart thing to do. Turns out, the data needed filtering and transformation after the query (mapping database rows to domain objects, removing invalid entries). Paginating in SQL meant items would silently disappear from results. The pragmatic fix: fetch all matching rows, map and filter them, *then* slice for the requested page.

**Layer-by-layer implementation.** Controller parses and validates query parameters. Use case orchestrates the call and builds the paginated response. DAO handles the database query and applies the pagination slice. Each layer's changes are isolated and testable.

**A single JOIN instead of N+1 queries.** The original data model required fetching impacts and then separately fetching their related fact sheets. I refactored the database function to use a single `INNER JOIN` query, then mapped the flattened rows back to nested objects in TypeScript.

None of these decisions were hard in isolation. What made it 42 commits was that I was learning the *how* while figuring out the *what*.

## What 42 Commits Looks Like

Here's what that commit history actually represents — not a clean progression, but the real messy process of learning:

**Days 1-2: Getting the skeleton working.** OpenAPI spec first, then the database function, then wiring up the controller and use case. Four commits just to get a request flowing through all the layers.

**Days 2-3: Optimizing the query.** Refactored the database function from multiple queries to a single JOIN. Introduced a `Map` for grouping results instead of nested filter loops. Implemented the actual pagination calculation — `calculateOffset(page, size)` and `slice()` on the mapped results.

**Days 3-4: Writing tests, discovering edge cases.** Controller tests, use case tests, DAO tests. Added error handling — what happens when the required filter parameter is missing? Added a secondary filter (`excludeExecuted`) that required a `LEFT JOIN` to the transformations table.

**Day 5: The refactor that didn't work.** I tried to restructure how the DAO was called — using existing shared functions instead of dedicated ones. It seemed cleaner. It broke things. I also tried changing import styles across the codebase. That broke more things. Two reverts, covering changes across 30+ files. Back to what worked.

**Days 5-6: Cleaning up.** Removed default values from the pagination parser (OpenAPI enforces required parameters, so the code shouldn't duplicate that logic). Rewrote test mocking strategies. Fixed import paths. Removed unused functions.

**Final commit: Merge.**

The reverts were the most educational part. They taught me that in a large codebase, "cleaner" isn't always better — especially when you don't yet understand all the downstream effects of a change.

## The Lesson That Stuck

The most important thing I learned wasn't pagination or how this team implemented DDD. It was this: **enterprise codebases are hard not because the code is complex, but because the conventions are invisible.**

The code itself was straightforward TypeScript. What made it hard was the ecosystem of unwritten rules: where things go, how things are named, what patterns are expected, how errors flow through layers. You can't learn these from documentation because most of it isn't documented. You learn it from reading existing code, getting PR feedback, and making mistakes.

Forty-two commits taught me how to work in an enterprise monorepo. That first feature is still running in production. I'm still proud of every one of those commits — including the two reverts. Each one represents something I didn't know the day before.
