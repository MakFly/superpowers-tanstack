# Superpowers TanStack

A TanStack Start focused toolkit for Claude Code providing file-based routing, server functions, data loaders, forms, SSR, streaming, and full-stack type-safe patterns.

## Features

- **File-Based Routing** - Type-safe routes with automatic generation
- **Server Functions** - Secure server-only execution with full type inference
- **Data Loading** - Route loaders, prefetching, streaming patterns
- **Forms** - Type-safe form handling with TanStack Form integration
- **SSR & Streaming** - Full SSR with streaming and progressive hydration
- **TanStack Ecosystem** - Query, Form, Table integrations

## Installation

```bash
claude plugins add superpowers-tanstack
```

Or add to your Claude Code plugins configuration.

## Quick Start

Once installed, the plugin automatically detects TanStack Start projects and provides context-aware assistance.

### Interactive Commands

- `/superpowers-tanstack:brainstorm` - Structured ideation for features
- `/superpowers-tanstack:write-plan` - Implementation planning
- `/superpowers-tanstack:execute-plan` - Methodical TDD execution
- `/superpowers-tanstack:tanstack-check` - Quality validation
- `/superpowers-tanstack:tanstack-tdd` - TDD workflow with Vitest

### Key Skills

| Category | Skills |
|----------|--------|
| Routing | `file-based-routing`, `route-configuration`, `route-params`, `route-loaders` |
| Server | `server-functions`, `server-only-fns`, `isomorphic-fns` |
| Data | `data-loaders`, `prefetching`, `suspense-patterns` |
| Forms | `form-handling`, `form-validation` |
| SSR | `ssr-configuration`, `streaming`, `hydration` |

## Environment Detection

The plugin automatically detects:

- TanStack Start version
- Package manager (npm, yarn, pnpm, bun)
- Vite configuration
- TypeScript configuration
- TanStack integrations (Query, Form, Table)
- Test framework (Vitest, Playwright)
- Styling solution

## Version Support

| TanStack Start | Status |
|----------------|--------|
| 1.x (RC) | Full support |

## Philosophy

- **Type-safe end-to-end** - Full TypeScript inference from routes to components
- **Router-first** - TanStack Router at the core
- **Server functions** - Secure, typed server-side execution
- **Vite-powered** - Fast development with HMR

## License

MIT License - See [LICENSE](LICENSE) for details.
