# Complexity Tiers (TanStack Start)

Use this to adapt the level of detail automatically based on project complexity.

## Simple
**Signals**: Few routes, basic loaders, no server functions.
**Example**: Add a route loader with minimal data fetch.

## Medium
**Signals**: Auth + server functions + nested layouts.
**Example**: Add a typed server function + route loader + form mutation.

## Complex
**Signals**: Streaming SSR, multiple integrations (Query/Form), large route tree.
**Example**: Prefetch data, stream route segments, and enforce type-safe boundaries.
