---
title: 'What Code Reviews Taught Me That Documentation Couldn''t'
description: 'How specific PR comments from teammates became my real onboarding — operator ordering, RxJS patterns, test structure, and the conventions no wiki captures.'
pubDate: '2026-03-20'
tags: ['code-review', 'learning', 'team']
draft: true
---

In my first month at a new company, I learned more from PR review comments than from any onboarding document. Not because the docs were bad — but because the things that actually trip you up in a new codebase aren't documented anywhere. They live in the collective habits of the team, and they surface when you ship code that doesn't match.

Here are the specific comments that taught me how my team works.

## "Put the unsubscribe operator last"

My third week. I submitted a PR that added filtering to a dropdown component — a small, focused change. My engineering manager left a single comment:

> *note: I believe it's a good practice to always put the unsubscribe operator last. Although in this case it's not an issue.*

The comment linked to an ESLint rule explaining why: if you place `takeUntil` before other operators, those operators can resubscribe after the unsubscribe fires, causing memory leaks.

Three things about this comment stuck with me. First, it came with a link — not just "do this," but "here's why." Second, "although in this case it's not an issue" — it wasn't blocking my PR over a theoretical problem. It was teaching me a principle for the next time. Third, it was the only comment on the PR. One thing worth mentioning, mentioned clearly. No nitpicking, no style preferences. Just the one thing that mattered.

I've since seen this pattern in every Angular codebase that uses RxJS. That one comment turned an easy-to-overlook ordering detail into something I now check instinctively.

## "Use concatLatestFrom instead"

Fourth week. I submitted a cleanup PR for a dropdown component — refining behavior and search handling. A senior teammate left several comments, all suggestions:

**`concatLatestFrom` over manual plumbing.** I was manually combining observables in an effect. The suggestion was to use `concatLatestFrom` — an NgRx operator that does the same thing more idiomatically: it lazily adds store data to the action stream. Cleaner, and immediately recognizable to anyone who knows NgRx.

**`map` over `switchMap` when there's no async.** I used `switchMap` with an `of()` wrapper for a synchronous operation. The reviewer suggested `map` instead — simpler, no unnecessary observable wrapping. It's the kind of thing that works either way, but one signals "I know what I'm doing" and the other signals "I'm guessing."

**Guard against empty strings.** "Can we add a check to be sure we don't add empty string?" A defensive check I hadn't thought of. Not because empty strings were happening — but because the type system didn't prevent them, and a guard at the boundary is cheaper than debugging a downstream failure.

I replied "That's a good suggestion, applied the changes" to all three. Because they were. Each one was a convention I'd have taken weeks to absorb through reading code alone.

## "Reflect that in the typing"

Second week. My PR added the ability to create new records from within an existing workflow — a larger change with 19 commits. A senior teammate left five comments, each teaching something different:

**Narrow your types.** "Since we're only working with one subtype, maybe we should reflect that in the typing?" I was using a broader parent type because it worked. But broader types invite broader mistakes. When you can express "only this specific variant flows through here" in the type system, you should.

**`before` vs `beforeEach`.** "Would this make more sense as a before, rather than beforeEach?" A subtle testing distinction: `before` runs once for the whole suite, `beforeEach` runs before every test. When your setup is the same for all tests, `beforeEach` is redundant work. Small, but it signals intentionality.

**Throw, don't return null.** "Would it make more sense if we maybe throw an error here instead? That way it can be caught, instead of having to check for null." I tried it — it broke a test. I said so honestly: "That should also work, but it breaks the test for some reason." We moved on. Not every suggestion needs to be applied; the conversation itself is the value.

**The praise that teaches.** Between the suggestions, the same reviewer wrote: "I find this if and the naming of the functions nice and easy to read." Praise in code review is underrated. It tells you what the team values — in this case, readable conditionals and descriptive function names. That's a convention too.

## "Please use test-stubs for this"

The same month, on the backend. My first API endpoint — a paginated query in a Node.js/DDD monorepo. A teammate reviewed it:

**Test stubs exist. Use them.** Three comments pointing to the same shared file. The codebase had a dedicated test stubs module with factory functions for test data. I was hand-crafting test objects. The stubs existed specifically to prevent that — consistent test data, less maintenance, and the tests read as specifications rather than data setup.

**Types belong in specific folders.** "This we can move to the folder for the types." The comment included the exact path deep in the DAO layer. In a monorepo with hundreds of files, knowing where a type *should* live is knowledge you can only get from someone who's been there.

**Validate at the boundary.** A required filter parameter was already marked as required in the OpenAPI spec, but the code didn't enforce it. The reviewer wanted defense in depth: validate in the DAO too, so future callers can't pass undefined through to the database.

**Test exact matches, not counts.** "We are only testing the numbers match here. I think we should also test exact match. `toStrictEqual` is preferred." Testing that you got 3 results tells you the query ran. Testing *which* 3 results tells you the query is correct.

Then something happened that surprised me. I'd extracted a pagination parser into a helper function. The initial suggestion was to keep it inline — but then four other places in the codebase turned up with the same duplicated code. The reviewer changed course: "Good idea. We have a utils folder for this. We can also do a small cleanup of code in the next PR." My instinct to extract was right — I just needed someone to confirm the pattern and tell me where it belonged.

## The Pattern

Every one of these comments taught me a convention that wasn't written in a wiki. Operator ordering. Idiomatic NgRx patterns. Type narrowing preferences. Test data strategies. File organization rules. Boundary validation philosophy.

Documentation tells you where things are. Code review tells you how things should be.

The best part: each reviewer had a distinct style. My manager was precise and minimal — one comment, one link, maximum impact. One teammate was pattern-oriented — showing me the idiomatic way alongside what I'd written. Another balanced corrections with praise, teaching me what the team valued. A third was thorough and structural — not just what to fix, but where things belong.

If you're new to a codebase, the fastest way to learn isn't reading architecture docs. It's shipping code and listening carefully to the feedback. Every review comment is a convention made visible.
