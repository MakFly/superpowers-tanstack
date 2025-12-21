---
name: tanstack:using-tanstack-superpowers
description: Entry point for TanStack Start Superpowers - essential workflows, philosophy, and interactive commands
---

# Using TanStack Start Superpowers

Welcome to TanStack Start Superpowers! This guide introduces you to the essential workflows, core philosophy, and interactive commands that make TanStack Start a powerful full-stack framework for building modern web applications.

## Package Manager Runner Selection

Choose your preferred package manager based on your project setup:

| Package Manager | Install Command | Run Dev | Run Build | Add Package | Remove Package |
|-----------------|-----------------|---------|-----------|-------------|----------------|
| **npm** | `npm install` | `npm run dev` | `npm run build` | `npm install <pkg>` | `npm uninstall <pkg>` |
| **yarn** | `yarn install` | `yarn dev` | `yarn build` | `yarn add <pkg>` | `yarn remove <pkg>` |
| **pnpm** | `pnpm install` | `pnpm dev` | `pnpm build` | `pnpm add <pkg>` | `pnpm remove <pkg>` |
| **bun** | `bun install` | `bun dev` | `bun run build` | `bun add <pkg>` | `bun remove <pkg>` |

## Core Philosophy

### Type-Safe End-to-End Development

TanStack Start provides complete type safety from your server to your client, eliminating the traditional boundary between frontend and backend. Every API call, form submission, and data fetch is fully typed without manual schema definitions.

**Key Benefits:**
- Catch errors at compile time, not runtime
- Automatic type inference across server-client boundaries
- No need for separate API documentation
- Refactor with confidence knowing all usages are caught

### Router-First Architecture

The router is the foundation of TanStack Start applications. Every route becomes a natural place to:
- Define server functions that execute on the backend
- Handle authentication and authorization
- Manage data loading and mutations
- Implement streaming responses for better performance

**Advantages:**
- Colocate related code (server logic, UI, validation)
- Automatic code splitting based on route structure
- Lazy loading of components and data
- Built-in error boundaries per route

## Essential Workflows

### 1. Starting Development

```bash
# Run the development server with hot-reload
npm run dev

# The app automatically reloads when you save files
# Your server and client code are updated instantly
```

**What happens:**
- Vite starts the development server on `http://localhost:5173`
- File watcher monitors changes in `src/` directory
- Hot module replacement (HMR) refreshes your browser
- Server-side changes trigger full page reload when necessary

### 2. Building for Production

```bash
# Create an optimized production build
npm run build

# Start the production server
npm run start
```

**Output includes:**
- Minified client code with tree-shaking
- Optimized server bundle
- Pre-rendered routes (when configured)
- Asset fingerprinting for cache busting

### 3. Adding Server Functions

Server functions are the bridge between your client and backend. They execute securely on the server with full access to databases, APIs, and secrets.

```typescript
// src/routes/__root.tsx
import { createServerFn } from '@tanstack/start'
import { db } from '@/lib/db'

export const fetchUserData = createServerFn({
  method: 'POST',
  async handler(userId: string) {
    // This code runs only on the server
    const user = await db.users.findById(userId)
    return {
      id: user.id,
      email: user.email,
      name: user.name,
    }
  },
})

export default function Root() {
  const [user] = useMutation({ fn: fetchUserData })

  return (
    <div>
      <button onClick={() => user.mutate('user-123')}>
        Load User
      </button>
    </div>
  )
}
```

### 4. Routing and Nested Layouts

TanStack Router provides file-based routing with powerful features:

```
src/routes/
├── __root.tsx          # Root layout
├── index.tsx           # Home page
├── dashboard/
│   ├── __layout.tsx    # Dashboard layout
│   ├── index.tsx       # Dashboard home
│   ├── $userId.tsx     # Dynamic route parameter
│   └── settings/
│       └── index.tsx   # Nested route
└── (group)/
    ├── about.tsx       # Route groups for organization
    └── pricing.tsx
```

### 5. Form Submissions and Mutations

TanStack Start uses `createServerFn` for type-safe form handling:

```typescript
export const submitForm = createServerFn({
  method: 'POST',
  async handler(data: FormData) {
    const name = data.get('name')
    const email = data.get('email')

    // Validate on server
    if (!name || !email) {
      throw new Error('Missing required fields')
    }

    // Save to database
    const user = await db.users.create({ name, email })
    return { success: true, userId: user.id }
  },
})

function MyForm() {
  const [state, mutate] = useMutation({ fn: submitForm })

  return (
    <form onSubmit={(e) => {
      e.preventDefault()
      mutate(new FormData(e.currentTarget))
    }}>
      <input name="name" required />
      <input name="email" type="email" required />
      <button>Submit</button>
    </form>
  )
}
```

### 6. Authentication and Authorization

Implement security patterns directly in your routes:

```typescript
export const checkAuth = createServerFn(async () => {
  const session = await getSession()
  if (!session?.user) {
    throw redirect({ to: '/login' })
  }
  return session.user
})

export default function ProtectedRoute() {
  const [user] = useSuspenseQuery({
    queryKey: ['auth'],
    queryFn: () => checkAuth(),
  })

  return <div>Welcome, {user.name}!</div>
}
```

## Interactive Commands Reference

### Development Commands

| Command | Purpose | Usage |
|---------|---------|-------|
| `npm run dev` | Start development server with HMR | Daily development |
| `npm run build` | Create production build | Before deployment |
| `npm run preview` | Preview production build locally | Test production build |
| `npm run type-check` | Run TypeScript compiler | CI/CD, pre-commit |
| `npm run lint` | Run ESLint on codebase | Code quality check |

### Project Management

| Command | Purpose | Usage |
|---------|---------|-------|
| `npm install` | Install dependencies | Initial setup, dependency updates |
| `npm update` | Update dependencies | Keep packages current |
| `npm list` | Show installed packages | Verify versions |
| `npm outdated` | Show outdated packages | Plan upgrades |

### Debugging

| Command | Purpose | Usage |
|---------|---------|-------|
| `NODE_DEBUG=* npm run dev` | Enable Node.js debugging | Troubleshoot server issues |
| `npm run build -- --sourcemap` | Build with source maps | Debug production builds |

## Version Support and Compatibility

### Minimum Requirements

- **Node.js**: 18.0.0 or later (20+ recommended)
- **TypeScript**: 5.0.0 or later
- **React**: 18.0.0 or later
- **Vite**: 5.0.0 or later
- **TanStack Router**: 1.30.0 or later
- **TanStack Start**: 1.0.0 or later

### Browser Support

| Browser | Minimum Version | Status |
|---------|-----------------|--------|
| Chrome | 90+ | Full support |
| Firefox | 88+ | Full support |
| Safari | 14+ | Full support |
| Edge | 90+ | Full support |

## Quick Reference Card

### Directory Structure

```
superpowers-tanstack/
├── src/
│   ├── routes/           # File-based routing
│   ├── components/       # Reusable components
│   ├── lib/             # Utilities and helpers
│   ├── server/          # Server-only code
│   └── types/           # TypeScript type definitions
├── public/              # Static assets
├── vite.config.ts       # Vite configuration
├── tsconfig.json        # TypeScript configuration
├── package.json         # Dependencies and scripts
└── router.config.ts     # TanStack Router config
```

### Key Files to Remember

- **vite.config.ts**: Build configuration, plugins, optimization
- **tsconfig.json**: TypeScript compiler settings, path aliases
- **package.json**: Dependencies, scripts, metadata
- **src/routes/__root.tsx**: Root layout and global setup
- **.env.local**: Local environment variables (never commit)

### Useful Keyboard Shortcuts (in Dev)

| Shortcut | Action |
|----------|--------|
| `Ctrl+S` / `Cmd+S` | Save and HMR reload |
| `Ctrl+Shift+D` / `Cmd+Shift+D` | Open DevTools |
| `Ctrl+L` / `Cmd+L` | Clear console |
| `F5` | Full page refresh |

## Next Steps

1. **Run `tanstack:runner-selection`** to identify and configure your package manager
2. **Run `tanstack:bootstrap-check`** to verify your project setup is complete
3. Start building your first route in `src/routes/`
4. Explore server functions for backend integration
5. Implement authentication and data fetching patterns

## Getting Help

- **Documentation**: https://tanstack.com/start/latest
- **Discord Community**: Join TanStack Discord for real-time help
- **GitHub Issues**: Report bugs and request features
- **Type Safety**: Use IntelliSense in your IDE for instant API documentation
