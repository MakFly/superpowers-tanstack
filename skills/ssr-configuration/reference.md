# Reference

# SSR Configuration avec TanStack Start

## Concept

SSR (Server-Side Rendering) rend les pages côté serveur pour une meilleure performance et SEO.

## Architecture SSR

```
User Request
    ↓
Server Renders React
    ├─ Execute Loaders
    ├─ Render Components
    └─ Stream HTML
    ↓
Browser Receives HTML
    ↓
Client Hydrate
    ├─ Attach Listeners
    └─ Enable Interactivity
```

## Configuration Complète

### 1. Entry Server

**`src/entry-server.tsx`**

```typescript
import * as React from 'react'
import { renderToReadableStream } from 'react-dom/server'
import { RootRoute } from './root'
import { createMemoryHistory, createRouter } from '@tanstack/react-router'

export default async function render(
  url: string,
  manifest?: Record<string, string[]>
) {
  // Créer un router en mémoire pour cette requête
  const memoryHistory = createMemoryHistory({
    initialEntries: [url],
  })

  const router = createRouter({
    routeTree: RootRoute,
    history: memoryHistory,
  })

  // Lancer la navigation jusqu'à résolution
  await router.load()

  // Créer le stream
  const readableStream = await renderToReadableStream(
    React.createElement(RootRoute.component, { router })
  )

  return readableStream
}
```

### 2. Entry Client

**`src/entry-client.tsx`**

```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import { RootRoute } from './root'
import { createBrowserHistory, createRouter } from '@tanstack/react-router'

// Créer le router côté client
const router = createRouter({
  routeTree: RootRoute,
  history: createBrowserHistory(),
})

// Hydrater le DOM
const root = ReactDOM.hydrateRoot(
  document.getElementById('root')!,
  React.createElement(RootRoute.component, { router })
)

// Cleanup
root.unmount()
```

### 3. Root Layout avec SSR

**`src/root.tsx`**

```typescript
import { RootRoute as TanstackRootRoute } from '@tanstack/react-router'
import { Outlet } from '@tanstack/react-router'
import * as React from 'react'

export const RootRoute = new TanstackRootRoute({
  component: RootComponent,
  notFoundComponent: () => <div>Not Found</div>,
  errorComponent: ({ error }) => <div>Error: {error.message}</div>,
})

export function RootComponent() {
  return (
    <html lang="en">
      <head>
        <meta charSet="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title>My App</title>

        {/* Styles */}
        <link rel="stylesheet" href="/styles.css" />

        {/* Scripts pour client-side navigation */}
        <script
          type="module"
          src="/src/entry-client.tsx"
          async
        ></script>
      </head>
      <body>
        <div id="root">
          <Outlet />
        </div>
      </body>
    </html>
  )
}
```

### 4. Server Entry Point

**`src/server.ts`** ou **`server.ts`**

```typescript
import express from 'express'
import compression from 'compression'
import fs from 'fs'
import path from 'path'
import render from './entry-server'

const app = express()

// Middleware
app.use(compression())
app.use(express.json())
app.use(express.static('dist/public'))

// Log middleware
app.use((req, res, next) => {
  console.log(`[SSR] ${req.method} ${req.url}`)
  next()
})

// SSR Route
app.get('*', async (req, res) => {
  try {
    // Render côté serveur
    const readableStream = await render(req.url)

    // Headers
    res.setHeader('Content-Type', 'text/html; charset=utf-8')
    res.setHeader('Cache-Control', 'public, max-age=3600')

    // Pipe le stream
    readableStream.pipe(res)
  } catch (error) {
    console.error('SSR Error:', error)

    // Fallback: Servir le shell HTML
    res.status(500).send(`
      <!DOCTYPE html>
      <html>
        <head>
          <title>Error</title>
          <meta charset="utf-8" />
          <meta name="viewport" content="width=device-width" />
        </head>
        <body>
          <div id="root">
            <p>Server error. Please refresh.</p>
          </div>
          <script type="module" src="/entry-client.js"></script>
        </body>
      </html>
    `)
  }
})

const PORT = process.env.PORT || 3000
app.listen(PORT, () => {
  console.log(`Server running on http://localhost:${PORT}`)
})
```

### 5. Configuration Vite avec SSR

**`vite.config.ts`**

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { TanStackRouterVite } from '@tanstack/router-plugin/vite'
import path from 'path'

export default defineConfig({
  plugins: [TanStackRouterVite(), react()],

  ssr: {
    // Modules externes à exclure du bundling SSR
    external: ['express', 'compression'],

    // Modules qui nécessitent un traitement
    noExternal: ['@tanstack/react-router'],
  },

  build: {
    // Client build
    rollupOptions: {
      input: 'src/entry-client.tsx',
      output: {
        dir: 'dist/public',
        format: 'es',
      },
    },
  },

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

### 6. Route avec SSR Lazy Loading

**`src/routes/products.tsx`**

```typescript
import { createFileRoute, useLoaderData } from '@tanstack/react-router'
import { Suspense } from 'react'
import { Await } from '@tanstack/react-router'

type Product = {
  id: string
  name: string
  price: number
};

export const Route = createFileRoute('/products')({
  // Loader exécuté sur serveur ET client
  loader: async () => {
    // ✅ Sur serveur: exécuté pendant le rendu
    // ✅ Sur client: exécuté lors de la navigation
    const response = await fetch(
      `${typeof window === 'undefined' ? 'http://localhost:3000' : ''}/api/products`
    )

    if (!response.ok) {
      throw new Error('Failed to load products')
    }

    return response.json() as Promise<{ products: Product[] }>
  },

  // Metadata pour le serveur
  meta: () => [
    { title: 'Produits - My App' },
    { name: 'description', content: 'Browse our products' },
  ],

  component: ProductsPage,
  pendingComponent: () => <div>Chargement...</div>,
  errorComponent: ({ error }) => <div>Erreur: {error.message}</div>,
})

function ProductsPage() {
  const { products } = useLoaderData({ from: '/products' })

  return (
    <div className="space-y-6">
      <h1 className="text-4xl font-bold">Produits</h1>

      <div className="grid grid-cols-4 gap-6">
        {products.map((product) => (
          <a
            key={product.id}
            href={`/products/${product.id}`}
            className="border rounded p-4 hover:shadow-lg"
          >
            <h3 className="font-bold text-blue-600">{product.name}</h3>
            <p className="text-lg font-bold">${product.price}</p>
          </a>
        ))}
      </div>
    </div>
  )
}
```

### 7. Meta Tags et Head Management

**`src/root.tsx`** (updated)

```typescript
import { useLocation } from '@tanstack/react-router'
import { Helmet } from 'react-helmet'

export function RootComponent() {
  const location = useLocation()

  return (
    <html lang="en">
      <Helmet>
        <title>My App</title>
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />

        {/* Dynamic meta tags */}
        <meta name="description" content="Welcome to my app" />
        <meta property="og:url" content={`https://example.com${location.pathname}`} />
        <meta property="og:type" content="website" />
        <meta property="og:title" content="My App" />
        <meta property="og:description" content="Welcome to my app" />

        {/* Preload criticial resources */}
        <link rel="preload" href="/fonts/inter.woff2" as="font" type="font/woff2" />

        {/* Styles */}
        <link rel="stylesheet" href="/styles.css" />
      </Helmet>

      <body>
        <div id="root">
          <Outlet />
        </div>

        {/* Client entry point */}
        <script type="module" src="/entry-client.js"></script>
      </body>
    </html>
  )
}
```

## Best Practices

### 1. Absolute URLs côté serveur

```typescript
// ✅ Utiliser des URLs absolues pendant SSR
const baseUrl = typeof window === 'undefined'
  ? 'http://localhost:3000'
  : ''

const response = await fetch(`${baseUrl}/api/data`)
```

### 2. Éviter le Side Effects côté serveur

```typescript
// ❌ Ne pas faire ça côté serveur
if (typeof window !== 'undefined') {
  localStorage.setItem('key', value)
}

// ✅ Checker d'abord
export function MyComponent() {
  const [value, setValue] = React.useState<string | null>(null)

  React.useEffect(() => {
    setValue(localStorage.getItem('key'))
  }, [])

  return <div>{value}</div>
}
```

### 3. Caching Stratégique

```typescript
// ✅ Utiliser les headers pour le caching
res.setHeader('Cache-Control', 'public, max-age=3600')

// ✅ Pour les assets statiques
app.use(express.static('dist/public', {
  maxAge: '1d',
  etag: false,
}))
```

### 4. Streaming pour UX

```typescript
// ✅ Streamer les chunks progressivement
const stream = await renderToReadableStream(
  <App />,
  {
    onError: (error) => {
      console.error('Streaming error:', error)
    },
  }
)

stream.pipe(res)
```

## Avantages

- **SEO**: Content indexable par moteurs de recherche
- **Performance**: Reduced Time to First Paint
- **Progressive Enhancement**: Fonctionne sans JavaScript
- **Hydration Efficace**: Client prend le relais
- **Streaming**: UX progressive
