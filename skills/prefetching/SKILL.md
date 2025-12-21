---
name: tanstack:prefetching
description: Prefetch route data on hover and navigation intent for instant transitions
---

# Prefetching Routes avec TanStack Router

## Concept

Le prefetching consiste à charger les données d'une route AVANT que l'utilisateur ne clique dessus. Cela crée une expérience ultra-fluide où la navigation est instantanée.

## Stratégies de Prefetching

```
User Hovers Link
    ↓
Detect Hover/Intent
    ↓
Load Route Data
    ↓
Cache Data
    ↓
User Clicks Link
    ↓
Data Instantly Available ← ZERO delay!
```

## Implémentation Complète

### 1. Prefetch au Survol avec useLoaderData

**`src/routes/products/index.tsx`**

```typescript
import { createFileRoute, useLoaderData, useRouter } from '@tanstack/react-router'
import { useState, useCallback } from 'react'

type Product = {
  id: string
  name: string
  price: number
  stock: number
};

type ProductsData = {
  products: Product[]
};

export const Route = createFileRoute('/products/')({
  loader: async () => {
    const res = await fetch('/api/products')
    return res.json() as Promise<ProductsData>
  },

  // ✅ Déclencher le loader au survol des liens
  preload: 'intent',

  component: ProductsPage,
})

function ProductsPage() {
  const data = useLoaderData({ from: '/products/' })
  const router = useRouter()

  const handleMouseEnter = useCallback(
    async (productId: string) => {
      // Précharger la route du produit
      router.preloadRoute({
        to: '/products/$id',
        params: { id: productId },
      })
    },
    [router]
  )

  return (
    <div className="space-y-6">
      <h1 className="text-4xl font-bold">Produits</h1>

      <div className="grid grid-cols-4 gap-6">
        {data.products.map((product) => (
          <a
            key={product.id}
            href={`/products/${product.id}`}
            onMouseEnter={() => handleMouseEnter(product.id)}
            className="border rounded p-4 hover:shadow-lg transition group"
          >
            <div className="bg-gray-200 h-48 rounded mb-3 flex items-center justify-center group-hover:bg-gray-300 transition">
              <span className="text-gray-400">Image</span>
            </div>
            <h3 className="font-bold text-blue-600 group-hover:text-blue-800 transition line-clamp-2">
              {product.name}
            </h3>
            <p className="text-lg font-bold">${product.price}</p>
            <p className="text-sm text-gray-600">Stock: {product.stock}</p>
          </a>
        ))}
      </div>
    </div>
  )
}
```

### 2. Prefetch Inteligente avec Navigation Intent

**`src/lib/navigationPrefetcher.ts`**

```typescript
import { useRouter } from '@tanstack/react-router'
import { useEffect } from 'react'

type PrefetchConfig = {
  delay?: number
  onPathnames?: string[]
  excludePatterns?: RegExp[]
};

export function usePrefetchOnIntent(config: PrefetchConfig = {}) {
  const {
    delay = 150, // Délai avant de précharger
    onPathnames = ['/products', '/posts'],
    excludePatterns = [/^\/admin/, /^\/api/],
  } = config

  const router = useRouter()

  useEffect(() => {
    let timeoutId: ReturnType<typeof setTimeout>

    const handleMouseEnter = (e: MouseEvent) => {
      const link = (e.target as HTMLElement).closest('a')
      if (!link) return

      const href = link.getAttribute('href')
      if (!href) return

      // ✅ Vérifier les exclusions
      if (excludePatterns.some((pattern) => pattern.test(href))) {
        return
      }

      // ✅ Vérifier les pathnames autorisés
      if (onPathnames.length && !onPathnames.some((p) => href.startsWith(p))) {
        return
      }

      // Attendre un peu avant de précharger
      timeoutId = setTimeout(() => {
        try {
          router.preloadRoute({ to: href as any })
        } catch {
          // Route invalide, ignorer
        }
      }, delay)
    }

    const handleMouseLeave = () => {
      clearTimeout(timeoutId)
    }

    document.addEventListener('mouseenter', handleMouseEnter, true)
    document.addEventListener('mouseleave', handleMouseLeave, true)

    return () => {
      document.removeEventListener('mouseenter', handleMouseEnter, true)
      document.removeEventListener('mouseleave', handleMouseLeave, true)
    }
  }, [router, delay, onPathnames, excludePatterns])
}
```

### 3. Prefetch avec Détection d'Inactivité

**`src/routes/users/index.tsx`**

```typescript
import { createFileRoute, useLoaderData, useRouter } from '@tanstack/react-router'
import { useEffect, useRef } from 'react'

type User = {
  id: string
  name: string
  email: string
  avatar: string
};

type UsersData = {
  users: User[]
};

export const Route = createFileRoute('/users/')({
  loader: async () => {
    const res = await fetch('/api/users')
    return res.json() as Promise<UsersData>
  },

  preload: 'intent',

  component: UsersPage,
})

function UsersPage() {
  const data = useLoaderData({ from: '/users/' })
  const router = useRouter()
  const visibleUsersRef = useRef<Set<string>>(new Set())

  // ✅ Prefetch au scroll (lazy loading)
  useEffect(() => {
    const observer = new IntersectionObserver(
      (entries) => {
        entries.forEach((entry) => {
          if (entry.isIntersecting) {
            const userId = (entry.target as HTMLElement).dataset.userId
            if (userId && !visibleUsersRef.current.has(userId)) {
              visibleUsersRef.current.add(userId)

              // Précharger immédiatement
              router.preloadRoute({
                to: '/users/$id',
                params: { id: userId },
              })
            }
          }
        })
      },
      { rootMargin: '50px' } // Précharger 50px avant d'entrer en vue
    )

    document.querySelectorAll('[data-user-id]').forEach((el) => {
      observer.observe(el)
    })

    return () => observer.disconnect()
  }, [router])

  return (
    <div className="space-y-6">
      <h1 className="text-4xl font-bold">Utilisateurs</h1>

      <div className="grid grid-cols-1 gap-4">
        {data.users.map((user) => (
          <a
            key={user.id}
            href={`/users/${user.id}`}
            data-user-id={user.id}
            className="border rounded p-4 hover:shadow-lg transition flex gap-4"
          >
            <div className="w-16 h-16 rounded-full bg-gray-200 flex-shrink-0">
              {user.avatar && (
                <img
                  src={user.avatar}
                  alt={user.name}
                  className="w-full h-full object-cover rounded-full"
                />
              )}
            </div>
            <div className="flex-1">
              <h3 className="font-bold text-lg text-blue-600 hover:text-blue-800">
                {user.name}
              </h3>
              <p className="text-gray-600">{user.email}</p>
            </div>
          </a>
        ))}
      </div>
    </div>
  )
}
```

### 4. Prefetch avec Priorité et Bandwidth Awareness

**`src/lib/smartPrefetcher.ts`**

```typescript
import { useRouter } from '@tanstack/react-router'
import { useEffect, useState } from 'react'

type PrefetchRequest = {
  href: string
  priority: 'high' | 'normal' | 'low'
  timestamp: number
};

export function useSmartPrefetch() {
  const router = useRouter()
  const [connection, setConnection] = useState<
    'slow-2g' | '2g' | '3g' | '4g' | 'unknown'
  >('4g')

  // ✅ Détecter la connexion réseau
  useEffect(() => {
    const nav = navigator as any
    if (!nav.connection) return

    const updateConnection = () => {
      setConnection(nav.connection.effectiveType || '4g')
    }

    nav.connection.addEventListener('change', updateConnection)
    updateConnection()

    return () =>
      nav.connection.removeEventListener('change', updateConnection)
  }, [])

  const shouldPrefetch = (priority: 'high' | 'normal' | 'low'): boolean => {
    // ✅ Adapter à la connexion réseau
    if (connection === 'slow-2g' || connection === '2g') {
      return priority === 'high' // Précharger que les priorités hautes
    }
    if (connection === '3g') {
      return priority !== 'low' // Précharger normales et hautes
    }
    return true // 4g: tout précharger
  }

  const prefetch = (href: string, priority: 'high' | 'normal' | 'low' = 'normal') => {
    if (shouldPrefetch(priority)) {
      try {
        router.preloadRoute({ to: href as any })
      } catch {
        // Route invalide
      }
    }
  }

  return { prefetch, connection }
}

// Utilisation dans un composant
export function ProductLink({ id, name }: { id: string; name: string }) {
  const { prefetch } = useSmartPrefetch()

  return (
    <a
      href={`/products/${id}`}
      onMouseEnter={() => prefetch(`/products/${id}`, 'normal')}
      className="text-blue-600 hover:text-blue-800"
    >
      {name}
    </a>
  )
}
```

### 5. Prefetch avec Délai Progressif

**`src/routes/catalog.tsx`**

```typescript
import { createFileRoute, useLoaderData, useRouter } from '@tanstack/react-router'
import { useEffect } from 'react'

type Product = {
  id: string
  name: string
};

type CatalogData = {
  products: Product[]
};

export const Route = createFileRoute('/catalog')({
  loader: async () => {
    const res = await fetch('/api/products?limit=50')
    return res.json() as Promise<CatalogData>
  },

  preload: 'intent',

  component: CatalogPage,
})

function CatalogPage() {
  const data = useLoaderData({ from: '/catalog' })
  const router = useRouter()

  // ✅ Précharger progressivement pendant l'inactivité
  useEffect(() => {
    let index = 0
    let timeoutId: ReturnType<typeof setTimeout>

    const prefetchNext = () => {
      if (index >= data.products.length) return

      const product = data.products[index]

      router.preloadRoute({
        to: '/products/$id',
        params: { id: product.id },
      })

      index++

      // Délai progressif: plus long pour les produits lointains
      const delay = 100 + index * 50 // 100ms pour le 1er, 150ms pour le 2e, etc.

      timeoutId = setTimeout(prefetchNext, delay)
    }

    // Commencer après 2 secondes d'inactivité
    const initialDelay = setTimeout(prefetchNext, 2000)

    return () => {
      clearTimeout(initialDelay)
      clearTimeout(timeoutId)
    }
  }, [router, data.products])

  return (
    <div className="grid grid-cols-4 gap-6">
      {data.products.map((product) => (
        <a
          key={product.id}
          href={`/products/${product.id}`}
          className="border rounded p-4 hover:shadow-lg"
        >
          {product.name}
        </a>
      ))}
    </div>
  )
}
```

### 6. Prefetch avec Retry et Error Handling

**`src/lib/reliablePrefetcher.ts`**

```typescript
import { useRouter } from '@tanstack/react-router'

type PrefetchOptions = {
  retries?: number
  timeout?: number
  ignoreErrors?: boolean
};

export function useReliablePrefetch() {
  const router = useRouter()

  const prefetchWithRetry = async (
    href: string,
    options: PrefetchOptions = {}
  ) => {
    const {
      retries = 3,
      timeout = 5000,
      ignoreErrors = true,
    } = options

    let lastError: Error | null = null

    for (let attempt = 0; attempt < retries; attempt++) {
      try {
        const controller = new AbortController()
        const timeoutId = setTimeout(() => controller.abort(), timeout)

        await new Promise<void>((resolve, reject) => {
          try {
            router.preloadRoute({ to: href as any })
            resolve()
          } catch (error) {
            reject(error)
          }
        })

        clearTimeout(timeoutId)
        return // Succès!
      } catch (error) {
        lastError = error instanceof Error ? error : new Error(String(error))

        if (!ignoreErrors && attempt === retries - 1) {
          console.error(`Prefetch failed after ${retries} attempts:`, lastError)
        }

        // Attendre avant retry
        if (attempt < retries - 1) {
          await new Promise((resolve) =>
            setTimeout(resolve, 100 * (attempt + 1))
          )
        }
      }
    }
  }

  return { prefetchWithRetry }
}
```

## Best Practices

### 1. Détection Automatique

```typescript
// ✅ Ajouter une fois dans l'app root
function AppRoot() {
  usePrefetchOnIntent({
    delay: 150,
    onPathnames: ['/products', '/users', '/posts'],
  })

  return <Outlet />
}
```

### 2. Respecter les Préférences Utilisateur

```typescript
// ✅ Respecter prefers-reduced-motion
const prefetch = (href: string) => {
  const reducedMotion = window.matchMedia(
    '(prefers-reduced-motion: reduce)'
  ).matches

  if (!reducedMotion) {
    router.preloadRoute({ to: href })
  }
}
```

### 3. Adapter au Contexte

```typescript
// ✅ Plus agressif pour les produits, moins pour l'admin
export function usePrefetch(context: 'public' | 'admin') {
  const { prefetch } = useSmartPrefetch()

  return {
    prefetchProduct: (id: string) =>
      prefetch(`/products/${id}`, context === 'public' ? 'normal' : 'low'),
  }
}
```

## Avantages

- **UX Instantanée**: Navigation sans délai perceptible
- **Intelligent**: S'adapte à la connexion réseau
- **Efficace**: Demande d'énergie par défaut
- **Flexible**: Contrôlable et désactivable
- **Transparent**: Zéro configuration par défaut
