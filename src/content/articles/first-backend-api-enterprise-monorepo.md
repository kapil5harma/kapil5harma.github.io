---
title: 'My First Backend API in an Enterprise Monorepo: 45 Commits of Learning'
description: 'What it was like to build my first backend API endpoint five weeks into a new job — in an Nx monorepo I had never seen before, with conventions I had never heard of.'
pubDate: '2026-03-06'
tags: ['backend', 'api-design', 'learning']
draft: false
---

Five weeks into my new job, I realized the frontend feature I was building needed a paginated API endpoint that didn't exist yet. So I created a story and built it myself. I had backend experience with Node.js and NestJS, but this codebase was different — its own flavor of DDD layering, an Nx monorepo I'd never navigated, and Knex instead of the TypeORM I was used to.

Forty-five commits later, the feature was merged. This is what I learned.

## The Setup

The backend was a Node.js/TypeScript monorepo managed by Nx, with multiple microservices and shared libraries. The architecture followed strict DDD layering:

```
Controllers → Use Cases → DAOs → Database Functions
```

I'd worked with DDD layering before, but every codebase implements it differently. Where exactly does validation live — controller or use case? What counts as "business logic" versus "just calling the database"? How strict are the boundaries between layers?

The concepts were familiar. The specific conventions were not. And in an enterprise monorepo, conventions are everything.

## The Overwhelming Part

It wasn't the code. Code is code — TypeScript on the backend isn't that different from TypeScript on the frontend. What overwhelmed me was everything *around* the code:

**The monorepo structure.** Nx organizes code into apps and libraries with strict dependency rules. You can't import from anywhere — there are boundaries enforced by linting. Which library owns the relevant types? Where do the DAO interfaces go? Why does this import fail with a circular dependency error?

**The conventions.** Commit message format. PR description template. Test file naming. How to structure a controller method versus a use case method. Where validation happens. Where types are defined. How to use the shared test stubs. None of this was written in a single document — it was spread across README files, linting rules, PR review comments, and the codebase itself.

**The review process.** My PR came back with comments I hadn't anticipated. Not because the code was bad — it worked. But I was hand-crafting test data instead of using the team's shared test stub factory functions. I'd put a new type definition in the wrong folder. I wasn't validating a required parameter at the DAO boundary. Every comment was a convention I didn't know existed.

## The Actual Feature

The task was to build a new paginated GET endpoint that returned records filtered by a given entity. The frontend needed to display these in a table, and loading everything at once wasn't going to scale.

**Offset-based pagination with `page` and `size`.** The consumer sends a page number and page size, the backend calculates the offset, and returns the slice along with a `totalCount`. I extracted the parameter parsing into a shared utility with its own tests — which let us clean up four other places in the codebase that had the same parsing logic duplicated inline.

**Paginate after mapping, not in the database.** My first instinct was to paginate in SQL — that's usually more efficient. So I did. And the results came back wrong — records went missing because the data gets assembled from multiple tables and transformed before it makes sense as a paginated list. The query joins records with their associated entities, then maps database rows into domain objects. Paginating before that assembly means you're slicing raw rows that haven't been grouped yet. I left a comment in the code for whoever encounters this next: *"Thought I was smart — paginated in SQL. Turns out, records went poof. Now we map first, then paginate. Trust me, future dev, this way works."*

**Layer-by-layer implementation.** The controller parses query parameters and delegates to the use case. The use case orchestrates two DAO calls — one to find the relevant parent records, another to fetch the grouped child data — then assembles and paginates the result. Each layer has its own tests and responsibilities.

**Validation at the right boundary.** A required filter parameter was already marked as required in the OpenAPI spec, but my reviewer pointed out that the use case should also throw a custom domain error if it's missing — defense in depth, so future callers can't accidentally pass undefined through to the database.

None of these decisions were hard in isolation. What made it 45 commits was that I was learning the *how* while figuring out the *what*.

## What 45 Commits Looks Like

The PR was started on a Thursday and merged the following Tuesday — three working days. Here's what that commit history actually represents:

**Thursday: Getting the skeleton working.** OpenAPI spec first — 84 lines defining the endpoint, parameters, and response schema. Then the controller, use case, and DAO wired up layer by layer. By the end of the day, a request could flow through all the layers and return paginated results. I also extracted the pagination parameter parser into a shared utility with its own tests.

**Friday: Writing tests and hardening.** Controller tests, use case tests, DAO tests. Added error handling — what happens when the required filter parameter is missing? Refactored tests to use the team's shared test stub factories instead of hand-crafted test data. Moved a new type definition to the proper folder in the DAO layer.

**Tuesday (after the weekend): Review fixes and the refactor that didn't work.** I tried two things that seemed cleaner: switching to existing shared DAO functions instead of dedicated ones, and changing import styles to use default imports. Both broke things. Two reverts. Then I found the right approach — rewriting the use case to properly compose existing DAO functions while keeping my dedicated query for the new data. Cleaned up: removed default values from the pagination parser (OpenAPI already enforces required parameters), fixed import paths, removed unused functions.

**Final commit: Merge.**

The reverts were the most educational part. They taught me that in a large codebase, "cleaner" isn't always better — especially when you don't yet understand all the downstream effects of a change.

## The Lesson That Stuck

The most important thing I learned wasn't pagination or DDD layering. It was this: **enterprise codebases are hard not because the code is complex, but because the conventions are invisible.**

The code itself was straightforward TypeScript. What made it hard was the ecosystem of unwritten rules: where things go, how things are named, what patterns are expected, which shared utilities already exist. You can't learn these from documentation because most of it isn't documented. You learn it from reading existing code, getting PR feedback, and making mistakes.

Forty-five commits taught me how to work in an enterprise monorepo. That first feature is still running in production. I'm still proud of every one of those commits — including the two reverts. Each one represents something I didn't know the day before.
