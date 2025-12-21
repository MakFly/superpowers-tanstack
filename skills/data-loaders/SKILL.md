---
name: tanstack:data-loaders
description: Implement data loaders with prefetching, caching, and streaming patterns
---

# Data Loaders avec TanStack

## Concept

Les data loaders sont des fonctions spécialisées qui gèrent le chargement, la mise en cache et le préchargement des données. Ils permettent de centraliser la logique de données et d'implémenter des patterns avancés comme l'invalidation de cache, les revalidations intelligentes et le streaming.

## Architecture du Data Loading

```
Route Navigation
    ↓
Route Loader Triggers
    ↓
Cache Check
    ├─ Hit → Retourner données en cache
    └─ Miss → Fetch fresh data
    ↓
Data Fetched
    ↓
Cache Store
    ↓
Component Renders
```

## Patterns Avancés

### 1. Cache Layer Complète

**`src/lib/dataLoader.ts`**

```typescript
// Cache manager pour toutes les données
type CacheEntry<T> = {
  data: T
  timestamp: number
  ttl: number // Time to live en ms
};

class DataLoader {
  private cache = new Map<string, CacheEntry<any>>()
  private requests = new Map<string, Promise<any>>()

  isExpired(key: string): boolean {
    const entry = this.cache.get(key)
    if (!entry) return true
    return Date.now() - entry.timestamp > entry.ttl
  }

  async load<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttl: number = 5 * 60 * 1000 // 5 min par défaut
  ): Promise<T> {
    // Vérifier le cache
    if (this.cache.has(key) && !this.isExpired(key)) {
      const cached = this.cache.get(key) as CacheEntry<T>
      return cached.data
    }

    // Éviter les requêtes en doublon
    if (this.requests.has(key)) {
      return this.requests.get(key)!
    }

    // Créer la requête
    const promise = fetcher()
      .then((data) => {
        this.cache.set(key, {
          data,
          timestamp: Date.now(),
          ttl,
        })
        this.requests.delete(key)
        return data
      })
      .catch((error) => {
        this.requests.delete(key)
        throw error
      })

    this.requests.set(key, promise)
    return promise
  }

  invalidate(pattern?: string | RegExp): void {
    if (!pattern) {
      this.cache.clear()
      return
    }

    const regex =
      typeof pattern === 'string'
        ? new RegExp(pattern.replace(/\*/g, '.*'))
        : pattern

    for (const key of this.cache.keys()) {
      if (regex.test(key)) {
        this.cache.delete(key)
      }
    }
  }

  prefetch<T>(
    key: string,
    fetcher: () => Promise<T>,
    ttl?: number
  ): void {
    // Précharger sans bloquer
    this.load(key, fetcher, ttl).catch(() => {
      // Silencieusement échouer si pas critique
    })
  }
}

export const dataLoader = new DataLoader()
```

### 2. Route Loader avec Cache

**`src/routes/products/index.tsx`**

```typescript
import { createFileRoute, useLoaderData } from '@tanstack/react-router'
import { dataLoader } from '@/lib/dataLoader'

type Product = {
  id: string
  name: string
  price: number
  image: string
  stock: number
};

type ProductsLoaderData = {
  products: Product[]
  total: number
  page: number
};

export const Route = createFileRoute('/products/')({
  loader: async ({ search }: { search: { page?: number; q?: string } }) => {
    const pageNum = search?.page ?? 1
    const query = search?.q ?? ''

    // Clé de cache basée sur les paramètres
    const cacheKey = `products:${pageNum}:${query}`

    return dataLoader.load<ProductsLoaderData>(
      cacheKey,
      async () => {
        const params = new URLSearchParams({
          page: String(pageNum),
          ...(query && { q: query }),
        })

        const res = await fetch(`/api/products?${params}`)
        if (!res.ok) throw new Error('Erreur produits')

        return res.json()
      },
      10 * 60 * 1000 // 10 min de cache
    )
  },

  // Précharger les données voisines
  preload: 'intent',

  component: ProductsPage,
})

function ProductsPage() {
  const data = useLoaderData({ from: '/products/' })

  return (
    <div className="space-y-6">
      <h1 className="text-4xl font-bold">Produits</h1>

      <div className="grid grid-cols-4 gap-6">
        {data.products.map((product) => (
          <a
            key={product.id}
            href={`/products/${product.id}`}
            className="border rounded p-4 hover:shadow-lg transition"
          >
            <div className="bg-gray-200 h-48 rounded mb-3 flex items-center justify-center">
              {product.image ? (
                <img
                  src={product.image}
                  alt={product.name}
                  className="w-full h-full object-cover"
                />
              ) : (
                <span className="text-gray-400">Image</span>
              )}
            </div>
            <h3 className="font-bold text-blue-600 line-clamp-2">
              {product.name}
            </h3>
            <p className="text-lg font-bold">${product.price}</p>
            <p className="text-sm text-gray-600">Stock: {product.stock}</p>
          </a>
        ))}
      </div>

      {/* Pagination */}
      <div className="flex gap-2 justify-center">
        {Array.from({ length: 5 }).map((_, i) => (
          <a
            key={i}
            href={`?page=${i + 1}`}
            className={`px-4 py-2 rounded ${
              data.page === i + 1
                ? 'bg-blue-600 text-white'
                : 'border hover:bg-gray-100'
            }`}
          >
            {i + 1}
          </a>
        ))}
      </div>
    </div>
  )
}
```

### 3. Invalidation de Cache après Mutations

**`src/routes/products/$id/edit.tsx`**

```typescript
import { createFileRoute, useNavigate } from '@tanstack/react-router'
import { dataLoader } from '@/lib/dataLoader'
import { useState } from 'react'

export const Route = createFileRoute('/products/$id/edit')({
  component: EditProductPage,
})

function EditProductPage() {
  const { id } = Route.useParams()
  const navigate = useNavigate()
  const [loading, setLoading] = useState(false)

  const handleSave = async (formData: FormData) => {
    setLoading(true)
    try {
      const response = await fetch(`/api/products/${id}`, {
        method: 'PUT',
        body: formData,
      })

      if (!response.ok) throw new Error('Erreur sauvegarde')

      // ✅ Invalider tous les caches relatifs aux produits
      dataLoader.invalidate(/^products:/)
      dataLoader.invalidate(`product:${id}`)

      // Naviguer vers la page
      navigate({ to: `/products/${id}` })
    } finally {
      setLoading(false)
    }
  }

  return (
    <form
      onSubmit={(e) => {
        e.preventDefault()
        handleSave(new FormData(e.currentTarget))
      }}
      className="max-w-2xl mx-auto space-y-4"
    >
      <input name="name" placeholder="Nom" required className="w-full p-2 border rounded" />
      <input
        name="price"
        type="number"
        placeholder="Prix"
        required
        className="w-full p-2 border rounded"
      />
      <button
        type="submit"
        disabled={loading}
        className="w-full bg-blue-600 text-white py-2 rounded font-bold hover:bg-blue-700 disabled:opacity-50"
      >
        {loading ? 'Sauvegarde...' : 'Sauvegarder'}
      </button>
    </form>
  )
}
```

### 4. Streaming avec Données Partielles

**`src/routes/dashboard.tsx`**

```typescript
import {
  createFileRoute,
  useLoaderData,
  Await,
} from '@tanstack/react-router'
import { dataLoader } from '@/lib/dataLoader'
import { Suspense } from 'react'

type DashboardData = {
  summary: {
    totalUsers: number
    totalRevenue: number
  }
  recentActivity: Promise<Array<{ id: string; action: string; time: string }>>
  topProducts: Promise<Array<{ id: string; name: string; sales: number }>>
};

export const Route = createFileRoute('/dashboard')({
  loader: async (): Promise<DashboardData> => {
    // Données rapides
    const summary = await dataLoader.load(
      'dashboard:summary',
      async () => {
        const res = await fetch('/api/dashboard/summary')
        return res.json()
      },
      60 * 1000 // 1 min
    )

    // Données lentes (streaming)
    const recentActivity = dataLoader.load(
      'dashboard:activity',
      async () => {
        const res = await fetch('/api/dashboard/activity')
        return res.json()
      },
      5 * 60 * 1000 // 5 min
    )

    const topProducts = dataLoader.load(
      'dashboard:products',
      async () => {
        const res = await fetch('/api/dashboard/products')
        return res.json()
      },
      10 * 60 * 1000 // 10 min
    )

    return {
      summary,
      recentActivity,
      topProducts,
    }
  },

  component: DashboardPage,
})

function DashboardPage() {
  const { summary, recentActivity, topProducts } = useLoaderData({
    from: '/dashboard',
  })

  return (
    <div className="space-y-6">
      {/* Summary - Immédiat */}
      <div className="grid grid-cols-2 gap-6">
        <div className="bg-white border rounded p-6">
          <p className="text-gray-600 text-sm mb-2">Utilisateurs</p>
          <p className="text-4xl font-bold">{summary.totalUsers}</p>
        </div>
        <div className="bg-white border rounded p-6">
          <p className="text-gray-600 text-sm mb-2">Revenus</p>
          <p className="text-4xl font-bold">${summary.totalRevenue}</p>
        </div>
      </div>

      {/* Activité récente - Streaming */}
      <div className="border rounded p-6">
        <h2 className="text-2xl font-bold mb-4">Activité Récente</h2>
        <Suspense fallback={<div className="text-gray-400">Chargement...</div>}>
          <Await promise={recentActivity}>
            {(activity) => (
              <div className="space-y-2">
                {activity.map((item) => (
                  <div key={item.id} className="flex justify-between py-2 border-b">
                    <span>{item.action}</span>
                    <span className="text-gray-600">{item.time}</span>
                  </div>
                ))}
              </div>
            )}
          </Await>
        </Suspense>
      </div>

      {/* Produits populaires - Streaming */}
      <div className="border rounded p-6">
        <h2 className="text-2xl font-bold mb-4">Produits Populaires</h2>
        <Suspense fallback={<div className="text-gray-400">Chargement...</div>}>
          <Await promise={topProducts}>
            {(products) => (
              <div className="grid grid-cols-3 gap-4">
                {products.map((product) => (
                  <div key={product.id} className="border rounded p-3">
                    <p className="font-bold">{product.name}</p>
                    <p className="text-gray-600">{product.sales} ventes</p>
                  </div>
                ))}
              </div>
            )}
          </Await>
        </Suspense>
      </div>
    </div>
  )
}
```

### 5. Prefetching Intelligent

**`src/lib/prefetcher.ts`**

```typescript
import { dataLoader } from './dataLoader'

class PrefetcherManager {
  prefetchProductList(page: number): void {
    dataLoader.prefetch(
      `products:${page}:`,
      async () => {
        const res = await fetch(`/api/products?page=${page}`)
        return res.json()
      },
      10 * 60 * 1000
    )
  }

  prefetchProduct(id: string): void {
    dataLoader.prefetch(
      `product:${id}`,
      async () => {
        const res = await fetch(`/api/products/${id}`)
        return res.json()
      },
      15 * 60 * 1000
    )
  }

  prefetchRelated(productId: string): void {
    dataLoader.prefetch(
      `product:${productId}:related`,
      async () => {
        const res = await fetch(`/api/products/${productId}/related`)
        return res.json()
      },
      20 * 60 * 1000
    )
  }

  // Précharger au survol du lien
  prefetchOnHover(event: React.MouseEvent<HTMLAnchorElement>): void {
    const href = event.currentTarget.href
    const id = href.split('/').pop()

    if (id && /^[0-9]+$/.test(id)) {
      this.prefetchProduct(id)
    }
  }
}

export const prefetcher = new PrefetcherManager()
```

### 6. Revalidation Avec WebSockets

**`src/lib/realtimeDataLoader.ts`**

```typescript
import { dataLoader } from './dataLoader'

class RealtimeDataLoader {
  private ws: WebSocket | null = null
  private subscribers = new Map<string, Set<() => void>>()

  connect(url: string): void {
    this.ws = new WebSocket(url)

    this.ws.onmessage = (event) => {
      const { type, pattern } = JSON.parse(event.data)

      // Invalider le cache basé sur le pattern
      dataLoader.invalidate(new RegExp(pattern))

      // Notifier les subscribers
      const callbacks = this.subscribers.get(pattern) || new Set()
      callbacks.forEach((cb) => cb())
    }
  }

  subscribe(pattern: string, callback: () => void): () => void {
    if (!this.subscribers.has(pattern)) {
      this.subscribers.set(pattern, new Set())
    }

    this.subscribers.get(pattern)!.add(callback)

    // Retourner fonction de désabonnement
    return () => {
      this.subscribers.get(pattern)?.delete(callback)
    }
  }

  disconnect(): void {
    this.ws?.close()
  }
}

export const realtimeLoader = new RealtimeDataLoader()
```

## Best Practices

### 1. TTL Stratégique

```typescript
// ✅ Adapter le TTL au contexte
const USER_CACHE_TTL = 1 * 60 * 1000        // 1 min - données sensibles
const PRODUCTS_CACHE_TTL = 10 * 60 * 1000   // 10 min - changent rarement
const STATS_CACHE_TTL = 5 * 60 * 1000       // 5 min - changent souvent
```

### 2. Pattern Matching pour Invalidation

```typescript
// ✅ Invalider plusieurs caches avec patterns
dataLoader.invalidate(/^products:/)     // Tous les produits
dataLoader.invalidate(/^user:123:/)     // Données utilisateur 123
```

### 3. Deduplication Automatique

```typescript
// ✅ Éviter les requêtes en doublon
const sameRequest1 = dataLoader.load('user:123', fetchUser)
const sameRequest2 = dataLoader.load('user:123', fetchUser)

// ← Seule UNE requête est faite, les deux attendent la même Promise
```

## Avantages

- **Centralisé**: Toute la logique de cache en un endroit
- **Intelligent**: Déduplication automatique des requêtes
- **Flexible**: TTL configurable par clé
- **Pattern-based**: Invalidation basée sur patterns
- **Type Safe**: Fortement typé en TypeScript
- **Streaming Ready**: Compatible avec Suspense et streaming
