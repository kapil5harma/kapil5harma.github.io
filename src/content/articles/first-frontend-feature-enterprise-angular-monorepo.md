---
title: 'My First Frontend Feature in an Enterprise Angular Monorepo'
description: 'Building a dropdown component across 7 PRs in my first month — in an Angular/Nx monorepo with NgRx, strict boundaries, and conventions I had never seen.'
pubDate: '2026-03-12'
tags: ['angular', 'ngrx', 'frontend', 'enterprise']
draft: false
---

A month into my new job, I had seven merged PRs. Not because I was fast — because enterprise features aren't built in one shot. They're shaped by code reviews, shifting requirements, and an understanding that deepens with every commit.

This is the frontend side of the story. If you've read [my backend article](/articles/impacts-api-pagination-refactoring), you know I was simultaneously building my first API endpoint. This is what was happening on the other side of the stack.

## The Setup

The frontend was a massive Angular monorepo managed by Nx. Hundreds of libraries, strict dependency boundaries enforced by linting, and state management through NgRx — stores, effects, selectors, reducers. I'd worked with Angular before. I'd never worked with *this*.

The codebase had conventions for everything: how to structure a component library, where shared types live, how effects chain together, which RxJS operators to use and in what order. None of this was in a single onboarding doc. It was embedded in the code itself — and I was about to learn it one PR at a time.

## The Feature

The task sounded straightforward: build a dropdown that lets users select from a list of records when scheduling changes. The component needed to:

- Load records from the backend
- Filter them by context (which parent entity was selected)
- Allow creating a new record inline
- Work across multiple modal types
- Only show records that hadn't already been processed

Simple dropdown. Five requirements. Seven PRs over four weeks.

## Week 1: Getting Data Flowing

My first two PRs landed on the same day — January 30th, one month in.

The first PR was the real work: wiring up the store to load data and pass it to the component. 303 additions across 20 files, 23 commits. I refactored a service to use a new API URL, added async loading logic, and connected everything through the NgRx store. A reviewer's comment stuck with me: "we should test this again manually in all usages before merging to develop." In a monorepo this size, your changes ripple.

The second PR was a 3-line bug fix — resetting cached data after a user action so the UI didn't show stale state. One file, one commit. The kind of fix that teaches you more about the data flow than reading architecture docs.

## Week 2: Making It Smart

Two weeks in, two PRs that shaped how the component actually behaved.

The third PR added the ability to create new records from within the dropdown. 19 commits, 235 additions. This is where a senior teammate's review taught me the team's standards. She caught that I was using a too-broad type where a narrower one was more precise, suggested `before` instead of `beforeEach` for test setup, and proposed throwing errors instead of returning null. She also left a praise comment on my function naming — which told me what the team valued just as much as the corrections did.

I also accidentally committed VS Code settings. She flagged it gently: "I'm not sure what the rules are for VS Code settings in this repo." I asked the broader team on Slack. Lesson learned: in a shared monorepo, even your editor config is a team decision.

The fourth PR added filtering by the selected parent entity. A focused change: 129 additions, 3 files, 2 commits. My engineering manager left a single comment about `takeUntil` operator ordering — putting the unsubscribe operator last to prevent subscription leaks. He included a link to the ESLint rule and added "although in this case it's not an issue." The gentlest kind of lesson: here's the principle, even though you didn't break anything.

## Week 3: Reuse and Refine

The fifth PR reused the component in a second modal. 595 additions across 5 files. The component I'd built for one context now needed to work in another with different behavior. This is where building incrementally paid off — the component was already isolated enough to reuse. No comments on this one. Clean merge.

## Week 4: Polish

The sixth PR was cleanup — 14 commits that refined the "create new" option behavior, improved search handling, and restructured some RxJS patterns. A senior teammate left several suggestions: use `concatLatestFrom` instead of manual observable plumbing, prefer `map` over `switchMap` when there's no async work, add a guard against empty strings. I applied all of them. Each one was a convention I wouldn't have discovered from reading docs.

The seventh PR added filtering by status — only showing records that hadn't already been processed. A reviewer caught that my test was testing the filter logic rather than the data — "I would probably write a list here instead of the filter, as we want to test the filter from the main code." I reverted to the better approach.

## What the Backend Article Didn't Tell You

While I was building the frontend component, I was also working on [my first backend feature](/articles/impacts-api-pagination-refactoring) — a paginated API endpoint. That backend work took three days and was merged on February 11th, right in the middle of the frontend effort.

For those first two weeks, I was context-switching between two codebases I'd never seen — an Angular/Nx monorepo on the frontend and a Node.js/DDD monorepo on the backend. Different architectural patterns, different conventions. The frontend needed data that didn't have an endpoint yet; instead of waiting for someone else to build it, I created a story and built it myself.

It was overwhelming. But it also meant I understood both sides of the feature — how the data was shaped in the database, how it flowed through the API, and how it rendered in the UI.

## The Lesson

Seven frontend PRs over four weeks. One backend PR in parallel. The feature was a dropdown.

But what I actually built was my understanding of the codebase. Each PR peeled back a layer: how the store connects to the UI, where shared types live, which RxJS operators the team prefers, how tests should be structured, what "reusable" actually means in a monorepo with hundreds of libraries.

Enterprise features aren't designed upfront and delivered in a single PR. They're shaped incrementally — by code reviews that teach you conventions, by requirements that surface new edge cases, and by an understanding that can only deepen through shipping real code.

Those first seven PRs were mine — and each one taught me something I couldn't have learned any other way.
