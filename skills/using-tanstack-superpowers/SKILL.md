---
name: tanstack:using-tanstack-superpowers
description: Entry point for TanStack Start Superpowers - lightweight workflow guidance and command map.
allowed-tools:
  - Read
  - Glob
  - Grep
---

# Using TanStack Start Superpowers (Compact)

## When to use
- TanStack Start routing, loaders, server functions, SSR/streaming
- Form handling, validation, Query integration

## How to operate
1. Detect TanStack Start version and router structure.
2. Keep server functions server-only; avoid leaking secrets client-side.
3. Ask before starting any dev server or build.
4. Use the project’s package manager; do not assume npm.

## Recommended entry skills
- `file-based-routing`, `route-configuration`, `route-loaders`
- `server-functions`, `server-only-fns`, `isomorphic-fns`
- `data-loaders`, `prefetching`, `suspense-patterns`

## Commands (only if user asks to run)
- `/superpowers-tanstack:write-plan`
- `/superpowers-tanstack:execute-plan`
- `/superpowers-tanstack:tanstack-check`
- `/superpowers-tanstack:tanstack-tdd`
