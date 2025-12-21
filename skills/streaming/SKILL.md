---
name: tanstack:streaming
description: Implement streaming SSR with deferred data and progressive rendering
---

# Streaming SSR avec TanStack Start

## Concept

Streaming SSR envoie le HTML progressivement au lieu d'attendre que tout soit prêt. Cela réduit drastiquement le Time to First Byte.

## Architecture Streaming

```
Server Start Rendering
    ├─ Send HTML Shell
    ├─ Send Critical Content
    └─ Stream Deferred Data
    ↓
Browser Renders Shell Immédiatement
    ├─ Affiche Layout et Critique
    └─ Hydrate progressivement
    ↓
Data Arrive → Remplacer Placeholders
```

## Patterns de Streaming

### 1. Setup Streaming SSR

**`src/entry-server.tsx`**

```typescript
import React from 'react'
import { renderToReadableStream } from 'react-dom/server'
import { createMemoryHistory, createRouter } from '@tanstack/react-router'
import { RootRoute } from './root'

export default async function render(url: string) {
  // Créer le router
  const memoryHistory = createMemoryHistory({
    initialEntries: [url],
  })

  const router = createRouter({
    routeTree: RootRoute,
    history: memoryHistory,
  })

  // Loader les données route
  await router.load()

  // ✅ Configuration streaming
  const readableStream = await renderToReadableStream(
    React.createElement(RootRoute.component, { router }),
    {
      // Bootstrapping data
      bootstrapScriptContent: `
        window.__INITIAL_STATE__ = ${JSON.stringify({
          router: router.dehydrate(),
        })};
      `,

      // Onshell ready pour envoyer headers HTTP
      onShellReady() {
        // À ce stade, le shell HTML est prêt
        // Mais pas la data deferred
      },

      // On all ready pour flush tout
      onAllReady() {
        // Toutes les données sont prêtes
      },

      // Error handler
      onError(error: unknown) {
        console.error('Streaming error:', error)
      },
    }
  )

  return readableStream
}
```

### 2. Deferred Data Pattern

**`src/routes/dashboard.tsx`**

```typescript
import {
  createFileRoute,
  useLoaderData,
  Await,
} from '@tanstack/react-router'
import { Suspense } from 'react'

type DashboardData = {
  // Données critiques (streamed immédiatement)
  user: {
    id: string
    name: string
  }

  // Données deferred (streamed après shell)
  analytics: Promise<{
    pageViews: number
    users: number
    revenue: number
  }>

  recommendations: Promise<Array<{ id: string; title: string }>>
};

export const Route = createFileRoute('/dashboard')({
  loader: async (): Promise<DashboardData> => {
    // ✅ Données synchrones
    const userRes = await fetch('/api/me')
    const user = await userRes.json()

    // ✅ Deferred: Retourner les Promises
    const analyticsPromise = fetch('/api/analytics').then((r) => r.json())
    const recommendationsPromise = fetch('/api/recommendations').then((r) =>
      r.json()
    )

    return {
      user,
      // On retourne les Promises NON awaited
      analytics: analyticsPromise,
      recommendations: recommendationsPromise,
    }
  },

  meta: () => [
    { title: 'Dashboard' },
    { name: 'description', content: 'Your dashboard' },
  ],

  component: DashboardPage,

  errorComponent: ({ error }) => (
    <div className="p-6 bg-red-50">
      <h1 className="font-bold text-red-800">Error</h1>
      <p>{error.message}</p>
    </div>
  ),
})

function DashboardPage() {
  const { user, analytics, recommendations } = useLoaderData({
    from: '/dashboard',
  })

  return (
    <div className="space-y-6">
      {/* User - Critère, affiché immédiatement */}
      <header className="border-b pb-4">
        <h1 className="text-4xl font-bold">Bienvenue, {user.name}</h1>
      </header>

      {/* Analytics - Streaming avec Suspense */}
      <Suspense
        fallback={
          <div className="grid grid-cols-3 gap-6">
            {[1, 2, 3].map((i) => (
              <div
                key={i}
                className="bg-white border rounded p-6 h-24 animate-pulse bg-gray-100"
              ></div>
            ))}
          </div>
        }
      >
        <Await promise={analytics}>
          {(stats) => (
            <div className="grid grid-cols-3 gap-6">
              <StatCard
                label="Page Views"
                value={stats.pageViews.toLocaleString()}
              />
              <StatCard label="Users" value={stats.users.toLocaleString()} />
              <StatCard
                label="Revenue"
                value={`$${stats.revenue.toLocaleString()}`}
              />
            </div>
          )}
        </Await>
      </Suspense>

      {/* Recommendations - Streaming indépendant */}
      <Suspense
        fallback={
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div
                key={i}
                className="h-12 bg-gray-200 rounded animate-pulse"
              ></div>
            ))}
          </div>
        }
      >
        <Await promise={recommendations}>
          {(items) => (
            <div className="border rounded p-6">
              <h2 className="text-2xl font-bold mb-4">Recommendations</h2>
              <div className="space-y-2">
                {items.map((item) => (
                  <a
                    key={item.id}
                    href={`/items/${item.id}`}
                    className="block p-3 border rounded hover:bg-gray-50"
                  >
                    {item.title}
                  </a>
                ))}
              </div>
            </div>
          )}
        </Await>
      </Suspense>
    </div>
  )
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="bg-white border rounded p-6">
      <p className="text-gray-600 text-sm">{label}</p>
      <p className="text-4xl font-bold mt-2">{value}</p>
    </div>
  )
}
```

### 3. Progressive Hydration

**`src/entry-client.tsx`**

```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import { createBrowserHistory, createRouter } from '@tanstack/react-router'
import { RootRoute } from './root'

// Attendre que le DOM soit prêt
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', hydrateApp)
} else {
  hydrateApp()
}

async function hydrateApp() {
  // ✅ Progressive hydration: attendre que le DOM soit prêt
  const root = document.getElementById('root')
  if (!root) {
    console.error('Root element not found')
    return
  }

  // Créer le router
  const router = createRouter({
    routeTree: RootRoute,
    history: createBrowserHistory(),
    // Récupérer l'état côté serveur si dispo
    dehydrate: () => (window as any).__INITIAL_STATE__?.router,
  })

  // Hydrater le DOM
  const reactRoot = ReactDOM.hydrateRoot(
    root,
    React.createElement(RootRoute.component, { router })
  )

  // Optional: cleanup après hydration
  return () => reactRoot.unmount()
}

// ✅ Prefetch des ressources critiques
if ('requestIdleCallback' in window) {
  requestIdleCallback(() => {
    prefetchCriticalResources()
  })
} else {
  setTimeout(prefetchCriticalResources, 2000)
}

function prefetchCriticalResources() {
  // Prefetch des scripts
  const link = document.createElement('link')
  link.rel = 'prefetch'
  link.href = '/js/vendors.js'
  document.head.appendChild(link)
}
```

### 4. Server avec Streaming

**`src/server.ts`**

```typescript
import express from 'express'
import compression from 'compression'
import render from './entry-server'

const app = express()

app.use(compression())
app.use(express.json())
app.use(express.static('dist/public'))

// ✅ SSR avec streaming
app.get('*', async (req, res) => {
  try {
    // Render côté serveur
    const readableStream = await render(req.url)

    // ✅ Headers critiques
    res.setHeader('Content-Type', 'text/html; charset=utf-8')
    res.setHeader('Transfer-Encoding', 'chunked')

    // Cache pour un jour
    res.setHeader('Cache-Control', 'public, max-age=86400, must-revalidate')

    // Security headers
    res.setHeader('X-Content-Type-Options', 'nosniff')
    res.setHeader('X-Frame-Options', 'DENY')

    // ✅ Streamer le contenu
    readableStream.on('error', (error) => {
      console.error('Stream error:', error)
      if (!res.headersSent) {
        res.status(500).send('Internal Server Error')
      }
    })

    readableStream.pipe(res)
  } catch (error) {
    console.error('SSR Error:', error)

    if (!res.headersSent) {
      res.status(500).send(`
        <!DOCTYPE html>
        <html>
          <head>
            <title>Error</title>
          </head>
          <body>
            <p>Server error</p>
          </body>
        </html>
      `)
    }
  }
})

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`Server streaming on http://localhost:${PORT}`)
})
```

### 5. Timing et Metriques

**`src/components/PerformanceMonitor.tsx`**

```typescript
import { useEffect } from 'react'

export function PerformanceMonitor() {
  useEffect(() => {
    // Attendre la fin du loading
    window.addEventListener('load', () => {
      // Web Vitals
      const perfData = performance.getEntriesByType('navigation')[0] as PerformanceNavigationTiming

      console.log('=== Performance Metrics ===')
      console.log(`TTFB: ${Math.round(perfData.responseStart - perfData.requestStart)}ms`)
      console.log(`FCP: ${Math.round(perfData.responseEnd - perfData.requestStart)}ms`)
      console.log(`LCP: ${Math.round(perfData.loadEventStart - perfData.requestStart)}ms`)

      // Deferred data timing
      performance.getEntriesByType('resource').forEach((entry) => {
        if ((entry as any).initiatorType === 'fetch') {
          console.log(`Fetch ${entry.name}: ${Math.round(entry.duration)}ms`)
        }
      })
    })

    // Monitor Suspense completion
    const observer = new MutationObserver((mutations) => {
      mutations.forEach((mutation) => {
        if (mutation.type === 'childList') {
          console.log('DOM updated - Suspense resolved')
        }
      })
    })

    observer.observe(document.body, {
      childList: true,
      subtree: true,
    })

    return () => observer.disconnect()
  }, [])

  return null
}
```

## Best Practices

### 1. Séparer Données Critiques et Deferred

```typescript
// ✅ Critiques: await
const user = await fetchUser()

// ✅ Deferred: Promise non-awaited
const analytics = fetchAnalytics()

return { user, analytics }
```

### 2. Fallbacks Bien Conçus

```typescript
// ✅ Skeleton qui ressemble à la vraie donnée
<Suspense fallback={<AnalyticsSkeleton />}>
  <Await promise={analytics} />
</Suspense>
```

### 3. Error Boundaries pour Sections

```typescript
// ✅ Erreur dans une section n'affecte pas les autres
<ErrorBoundary fallback={<AnalyticsError />}>
  <Suspense fallback={<Skeleton />}>
    <Await promise={analytics} />
  </Suspense>
</ErrorBoundary>
```

## Avantages

- **TTFB Rapide**: HTML envoyé immédiatement
- **UX Progressive**: Contenu affiché progressivement
- **SEO Optimal**: Shell HTML indexable
- **Performance**: Hydration progressive
- **Network Efficient**: Données non critiques streamed
