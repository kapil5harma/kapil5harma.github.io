---
title: "Multi-Region Analytics Without Code Duplication"
description: "Building analytics across more than a dozen geographic regions with a two-tier pattern, macro systems, and the medallion architecture — without duplicating a single query."
pubDate: "2026-05-11"
tags: ["data-engineering", "architecture", "analytics"]
draft: false
---

Our platform operates in more than a dozen geographic regions. Each region has its own database cluster, its own data pipeline, and its own regulatory requirements. When we set out to build product analytics — tracking feature adoption, usage patterns, and system health — we faced a fundamental architecture decision: how do you query data across all regions without duplicating code for each one?

This is the story of the pattern we built, why it works, and the trade-offs we accepted.

## The Problem: N Regions, 1 Analytics Pipeline

Each region is an independent deployment. Each has its own PostgreSQL cluster, its own application servers, its own data. This isolation is by design — it satisfies data residency requirements and provides fault isolation.

But analytics needs to see across regions. Product teams want to know: "How many users adopted feature X globally?" Engineering wants to know: "What's the error rate for service Y across all regions?" These questions require aggregating data from all regions.

The naive approach: write a query, copy it to every regional pipeline, union the results. This works until you have 50 queries. Then 100. Each change requires updating every copy. One missed region means that region's data is silently excluded, and nobody notices for weeks.

We needed a pattern where each query is written once and runs everywhere.

## The Two-Tier Architecture

Our solution is a two-tier pipeline architecture:

**Tier 1: Regional Bundles**
Each region runs a set of data transformations (we call them "bundles") that process regional data into standardized analytical tables. These bundles run inside the region, on regional infrastructure, using regional data only.

**Tier 2: Global Bundles**
A central analytics environment unions the outputs from all regional bundles into global views. These bundles run in a central location and reference regional data through cross-region connections.

```
Region EU   ──→ [Regional Bundle] ──→ silver.customer_activity_eu
Region US   ──→ [Regional Bundle] ──→ silver.customer_activity_us
Region ...  ──→ [Regional Bundle] ──→ silver.customer_activity_...
...
                            ↓
                [Global Bundle]
                            ↓
                gold.customer_activity (global)
```

The key insight: regional bundles contain all the business logic. Global bundles are mechanical — they just union regional tables and add a `region` column. This means:

- Business logic exists in exactly one place (the regional bundle)
- Adding a new region means running the same bundle on a new data source
- Global views are generated, not hand-written

## The Medallion Architecture

Within each tier, we follow the medallion pattern (bronze → silver → gold):

**Bronze:** Raw data, minimal transformation. Direct copies from source systems with standardized column names and types. Schema-on-read.

```sql
-- Bronze: raw order data, one table per source
CREATE TABLE bronze.raw_orders AS
SELECT
    order_id,
    customer_id,
    product_id,
    quantity,
    total_amount,
    order_status,
    ordered_at
FROM source.orders;
```

**Silver:** Cleaned, deduplicated, business-logic-applied data. This is where most of the transformation happens. Silver tables are the "single source of truth" for a given concept.

```sql
-- Silver: cleaned and enriched customer activity
CREATE TABLE silver.customer_activity AS
SELECT
    customer_id,
    first_order_at,
    last_order_at,
    order_count_30d,
    order_count_90d,
    total_revenue,
    customer_segment  -- 'new' | 'active' | 'power_buyer' | 'churned'
FROM bronze.raw_orders
GROUP BY customer_id
-- ... complex logic for segment classification
```

**Gold:** Aggregated, dashboard-ready data. Gold tables answer specific business questions and are optimized for query performance.

```sql
-- Gold: global customer activity summary
CREATE TABLE gold.customer_activity_summary AS
SELECT
    customer_segment,
    region,
    COUNT(DISTINCT customer_id) as total_customers,
    COUNT(DISTINCT CASE WHEN order_count_30d > 0 THEN customer_id END) as active_count,
    ROUND(active_count::numeric / NULLIF(total_customers, 0) * 100, 1) as active_rate_pct
FROM gold.customer_activity  -- global union view
GROUP BY customer_segment, region;
```

## Macro Systems for DRY Global Views

The most elegant part of the system is how we generate global views without duplication. We use a macro system (think of it as a template engine for SQL) that generates the union queries automatically.

Here's the concept:

```python
# Macro definition
def generate_global_view(table_name: str, regions: list[str]) -> str:
    union_parts = []
    for region in regions:
        union_parts.append(f"""
            SELECT *, '{region}' as region
            FROM {region}_catalog.silver.{table_name}
        """)

    return f"""
        CREATE OR REPLACE VIEW gold.{table_name} AS
        {' UNION ALL '.join(union_parts)}
    """

# Usage - generates a view that unions all regions
REGIONS = ['eu', 'us']  # ... and more

generate_global_view('customer_activity', REGIONS)
```

This generates:

```sql
CREATE OR REPLACE VIEW gold.customer_activity AS
SELECT *, 'eu' as region FROM eu_catalog.silver.customer_activity
UNION ALL
SELECT *, 'us' as region FROM us_catalog.silver.customer_activity
UNION ALL
-- ... one entry per region
```

When we add a new region, we add one entry to the `REGIONS` list. Every global view regenerates automatically. Zero risk of missing a query.

## Materialized Tables vs. Views: The Trade-Off

We spent significant time debating whether global tables should be materialized (physical copies) or views (virtual unions).

**Views:**

- Always fresh — no staleness
- No storage cost
- Slower to query (multi-region union at read time)
- No independent scheduling needed

**Materialized Tables:**

- Fast to query (single table scan)
- Additional storage cost
- Can become stale between refreshes
- Need scheduling and monitoring

The materialization strategy varies by use case — some global tables are views (always fresh, no storage cost), while others are materialized for performance where dashboards need faster query times. The trade-off between freshness and query speed is made per-table based on how it's consumed.

## Regional Differences

Not all regions are identical. Some regions have different timezone configurations. The architecture supports region-specific overrides through the dbt configuration — each region's target includes its own settings, and the regional bundles pick up the right configuration at runtime. This keeps the business logic uniform while allowing region-specific adaptations where needed.

## Lessons Learned

### Write Once, Test Once, Run Everywhere

The single biggest win is that a bug fix in a regional bundle automatically fixes every region. Before this pattern, a colleague found a calculation error in a revenue metric and had to update the query in multiple places — some of which had already drifted from the original. With the two-tier pattern, it's one fix, one test, one deployment.

### Monitor Regional Parity

Even with shared code, regional data can differ. We built parity checks that compare row counts, null rates, and value distributions across regions. When one region deviates significantly, we investigate. Usually it's a data source issue, not a code issue — but without parity monitoring, we wouldn't catch it.

### The Macro System Pays for Itself

The initial investment in building the macro system has saved significant cumulative maintenance time. Every new analytical table we add is automatically global. The alternative — manually writing union queries — doesn't scale.

### Naming Conventions Are Load-Bearing

Our table naming convention (`bronze.raw_*`, `silver.clean_*`, `gold.agg_*`) makes the data lineage visible without opening any documentation. A new team member can look at a table name and immediately know what tier it belongs to, what level of transformation it's had, and where to find its upstream source.

## The Architecture Today

We now have dozens of analytical tables flowing through this pattern. Adding a new region takes about a day — mostly verifying network connectivity and data source access. Adding a new analytical table takes a few hours — write the regional bundle, the global view generates itself.

The pattern isn't perfect. The multi-region union views can be slow for ad-hoc exploration. The macro system adds a layer of indirection that new team members need to learn.

But compared to the alternative — maintaining a separate copy of every query per region — we'll take these trade-offs every time.
