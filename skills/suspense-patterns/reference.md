# Reference

# Suspense Patterns avec TanStack Start

## Concept

Suspense permet de déclarer des sections qui chargent des données asynchrones sans durcir à l'expérience utilisateur. Au lieu de bloquer, on montre un fallback jusqu'à ce que les données soient prêtes.

## Architecture Suspense

```
Component Render
    ├─ Données prêtes → Afficher le composant
    └─ Données en attente → Fallback
        ├─ Prêtes → Remplacer le fallback
        └─ Erreur → Error boundary
```

## Patterns Complets

### 1. Suspense Basique avec Await

**`src/routes/posts.tsx`**

```typescript
import {
  createFileRoute,
  useLoaderData,
  Await,
} from '@tanstack/react-router'
import { Suspense } from 'react'

type Post = {
  id: string
  title: string
  content: string
  author: string
};

type PostsLoaderData = {
  posts: Promise<Post[]>
};

export const Route = createFileRoute('/posts')({
  loader: async (): Promise<PostsLoaderData> => {
    // ✅ Retourner une Promise, pas await
    const posts = fetch('/api/posts').then((r) => r.json())

    return { posts }
  },

  component: PostsPage,

  errorComponent: ({ error }) => (
    <div className="p-6 bg-red-50 rounded">
      <h1 className="text-red-800 font-bold">Erreur</h1>
      <p className="text-red-700">{error.message}</p>
    </div>
  ),
})

function PostsPage() {
  const { posts } = useLoaderData({ from: '/posts' })

  return (
    <div className="space-y-6">
      <h1 className="text-4xl font-bold">Articles</h1>

      <Suspense
        fallback={
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div
                key={i}
                className="border rounded p-6 space-y-3 animate-pulse"
              >
                <div className="h-6 bg-gray-200 rounded w-2/3"></div>
                <div className="h-4 bg-gray-200 rounded"></div>
                <div className="h-4 bg-gray-200 rounded w-5/6"></div>
              </div>
            ))}
          </div>
        }
      >
        <Await promise={posts}>
          {(resolvedPosts) => (
            <div className="space-y-6">
              {resolvedPosts.map((post) => (
                <article
                  key={post.id}
                  className="border rounded p-6 hover:shadow-lg"
                >
                  <h2 className="text-2xl font-bold mb-2 text-blue-600">
                    {post.title}
                  </h2>
                  <p className="text-gray-600 mb-4">{post.content}</p>
                  <p className="text-sm text-gray-500">Par {post.author}</p>
                </article>
              ))}
            </div>
          )}
        </Await>
      </Suspense>
    </div>
  )
}
```

### 2. Suspense Imbriquée avec Priorités

**`src/routes/dashboard.tsx`**

```typescript
import {
  createFileRoute,
  useLoaderData,
  Await,
} from '@tanstack/react-router'
import { Suspense } from 'react'

type DashboardData = {
  // Données rapides (pas Suspense)
  user: { name: string; id: string }

  // Données lentes (Suspense)
  stats: Promise<{ revenue: number; users: number }>
  recentOrders: Promise<Array<{ id: string; status: string }>>
  topProducts: Promise<Array<{ id: string; sales: number }>>
};

export const Route = createFileRoute('/dashboard')({
  loader: async (): Promise<DashboardData> => {
    // Données synchrones
    const userRes = await fetch('/api/me')
    const user = await userRes.json()

    // Données asynchrones
    const statsPromise = fetch('/api/stats').then((r) => r.json())
    const ordersPromise = fetch('/api/orders').then((r) => r.json())
    const productsPromise = fetch('/api/products/top').then((r) => r.json())

    return {
      user,
      stats: statsPromise,
      recentOrders: ordersPromise,
      topProducts: productsPromise,
    }
  },

  component: DashboardPage,
})

function DashboardPage() {
  const data = useLoaderData({ from: '/dashboard' })

  return (
    <div className="space-y-6">
      {/* Header - Immédiat (pas Suspense) */}
      <header className="border-b pb-4">
        <h1 className="text-4xl font-bold">Tableau de Bord</h1>
        <p className="text-gray-600">Bienvenue, {data.user.name}</p>
      </header>

      {/* Stats - Suspense avec priorité haute */}
      <Suspense
        fallback={
          <div className="grid grid-cols-2 gap-6">
            {[1, 2].map((i) => (
              <div
                key={i}
                className="bg-white border rounded p-6 h-24 animate-pulse bg-gray-100"
              ></div>
            ))}
          </div>
        }
      >
        <Await promise={data.stats}>
          {(stats) => (
            <div className="grid grid-cols-2 gap-6">
              <div className="bg-white border rounded p-6">
                <p className="text-gray-600 text-sm mb-2">Revenus</p>
                <p className="text-4xl font-bold">${stats.revenue}</p>
              </div>
              <div className="bg-white border rounded p-6">
                <p className="text-gray-600 text-sm mb-2">Utilisateurs</p>
                <p className="text-4xl font-bold">{stats.users}</p>
              </div>
            </div>
          )}
        </Await>
      </Suspense>

      {/* Contenu - Plusieurs Suspense indépendantes */}
      <div className="grid grid-cols-2 gap-6">
        {/* Commandes Récentes */}
        <div className="border rounded p-6">
          <h2 className="text-2xl font-bold mb-4">Commandes Récentes</h2>

          <Suspense
            fallback={
              <div className="space-y-2">
                {[1, 2, 3].map((i) => (
                  <div
                    key={i}
                    className="h-6 bg-gray-200 rounded animate-pulse"
                  ></div>
                ))}
              </div>
            }
          >
            <Await promise={data.recentOrders}>
              {(orders) => (
                <div className="space-y-2">
                  {orders.map((order) => (
                    <div
                      key={order.id}
                      className="flex justify-between py-2 border-b"
                    >
                      <span>Commande {order.id}</span>
                      <span
                        className={`px-2 py-1 rounded text-white text-sm ${
                          order.status === 'completed'
                            ? 'bg-green-500'
                            : 'bg-yellow-500'
                        }`}
                      >
                        {order.status}
                      </span>
                    </div>
                  ))}
                </div>
              )}
            </Await>
          </Suspense>
        </div>

        {/* Produits Populaires */}
        <div className="border rounded p-6">
          <h2 className="text-2xl font-bold mb-4">Produits Populaires</h2>

          <Suspense
            fallback={
              <div className="space-y-2">
                {[1, 2, 3].map((i) => (
                  <div
                    key={i}
                    className="h-6 bg-gray-200 rounded animate-pulse"
                  ></div>
                ))}
              </div>
            }
          >
            <Await promise={data.topProducts}>
              {(products) => (
                <div className="space-y-2">
                  {products.map((product) => (
                    <div
                      key={product.id}
                      className="flex justify-between py-2 border-b"
                    >
                      <span>Produit {product.id}</span>
                      <span className="text-gray-600">{product.sales} ventes</span>
                    </div>
                  ))}
                </div>
              )}
            </Await>
          </Suspense>
        </div>
      </div>
    </div>
  )
}
```

### 3. Suspense avec Erreurs Partielles

**`src/routes/catalog.tsx`**

```typescript
import {
  createFileRoute,
  useLoaderData,
  Await,
} from '@tanstack/react-router'
import { Suspense, ReactNode } from 'react'

type CatalogData = {
  categories: Promise<Array<{ id: string; name: string }>>
  products: Promise<Array<{ id: string; name: string; price: number }>>
};

export const Route = createFileRoute('/catalog')({
  loader: async (): Promise<CatalogData> => {
    return {
      categories: fetch('/api/categories').then((r) => r.json()),
      products: fetch('/api/products').then((r) => r.json()),
    }
  },

  component: CatalogPage,
})

function CatalogPage() {
  const data = useLoaderData({ from: '/catalog' })

  return (
    <div className="space-y-6">
      <h1 className="text-4xl font-bold">Catalogue</h1>

      <div className="grid grid-cols-4 gap-6">
        {/* Catégories */}
        <aside className="col-span-1">
          <h2 className="text-xl font-bold mb-4">Catégories</h2>

          <ErrorBoundarySection>
            <Suspense
              fallback={
                <div className="space-y-2">
                  {[1, 2, 3].map((i) => (
                    <div
                      key={i}
                      className="h-6 bg-gray-200 rounded animate-pulse"
                    ></div>
                  ))}
                </div>
              }
            >
              <Await promise={data.categories}>
                {(categories) => (
                  <nav className="space-y-2">
                    {categories.map((cat) => (
                      <a
                        key={cat.id}
                        href={`?category=${cat.id}`}
                        className="block px-3 py-2 rounded hover:bg-blue-100"
                      >
                        {cat.name}
                      </a>
                    ))}
                  </nav>
                )}
              </Await>
            </Suspense>
          </ErrorBoundarySection>
        </aside>

        {/* Produits */}
        <main className="col-span-3">
          <ErrorBoundarySection>
            <Suspense
              fallback={
                <div className="grid grid-cols-3 gap-4">
                  {[1, 2, 3, 4, 5, 6].map((i) => (
                    <div
                      key={i}
                      className="border rounded p-4 space-y-3 animate-pulse"
                    >
                      <div className="h-32 bg-gray-200 rounded"></div>
                      <div className="h-4 bg-gray-200 rounded w-2/3"></div>
                      <div className="h-4 bg-gray-200 rounded"></div>
                    </div>
                  ))}
                </div>
              }
            >
              <Await promise={data.products}>
                {(products) => (
                  <div className="grid grid-cols-3 gap-4">
                    {products.map((product) => (
                      <a
                        key={product.id}
                        href={`/products/${product.id}`}
                        className="border rounded p-4 hover:shadow-lg"
                      >
                        <div className="h-32 bg-gray-200 rounded mb-3"></div>
                        <h3 className="font-bold text-blue-600 line-clamp-2">
                          {product.name}
                        </h3>
                        <p className="text-lg font-bold">${product.price}</p>
                      </a>
                    ))}
                  </div>
                )}
              </Await>
            </Suspense>
          </ErrorBoundarySection>
        </main>
      </div>
    </div>
  )
}

// Component d'erreur pour une section
function ErrorBoundarySection({ children }: { children: ReactNode }) {
  // En production, utiliser une vrai error boundary
  return <>{children}</>
}
```

### 4. Suspense Progressive avec useTransition

**`src/routes/search.tsx`**

```typescript
import { createFileRoute, useLoaderData } from '@tanstack/react-router'
import { Suspense, useTransition, useState, ReactNode } from 'react'

type SearchResult = {
  id: string
  title: string
  relevance: number
};

type SearchData = {
  results: Promise<SearchResult[]>
};

export const Route = createFileRoute('/search')({
  validateSearch: (search: Record<string, unknown>) => ({
    q: (search.q as string) || '',
  }),

  loader: async ({ search }) => {
    if (!search.q) return { results: Promise.resolve([]) }

    return {
      results: fetch(`/api/search?q=${encodeURIComponent(search.q)}`).then(
        (r) => r.json()
      ),
    }
  },

  component: SearchPage,
})

function SearchPage() {
  const navigate = Route.useNavigate()
  const search = Route.useSearch()
  const data = useLoaderData({ from: '/search' })
  const [isPending, startTransition] = useTransition()
  const [searchValue, setSearchValue] = useState(search.q)

  const handleSearch = (newQuery: string) => {
    setSearchValue(newQuery)

    // ✅ useTransition permet le rendu optimiste
    startTransition(() => {
      navigate({
        search: { q: newQuery },
      })
    })
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <h1 className="text-4xl font-bold">Recherche</h1>

      <input
        value={searchValue}
        onChange={(e) => handleSearch(e.target.value)}
        placeholder="Rechercher..."
        className="w-full px-4 py-2 border rounded"
      />

      {/* État de transition */}
      {isPending && (
        <div className="text-center text-gray-500">Recherche en cours...</div>
      )}

      {/* Résultats avec Suspense */}
      <Suspense
        fallback={
          <div className="space-y-4">
            {[1, 2, 3].map((i) => (
              <div
                key={i}
                className="border rounded p-4 space-y-2 animate-pulse"
              >
                <div className="h-6 bg-gray-200 rounded w-2/3"></div>
                <div className="h-4 bg-gray-200 rounded"></div>
              </div>
            ))}
          </div>
        }
      >
        <SearchResults results={data.results} />
      </Suspense>
    </div>
  )
}

function SearchResults({ results }: { results: Promise<SearchResult[]> }) {
  const [resolved, setResolved] = useState<SearchResult[] | null>(null)

  // Résoudre la Promise
  Promise.resolve(results).then(setResolved)

  if (!resolved) return null

  return (
    <div className="space-y-4">
      {resolved.length === 0 ? (
        <p className="text-gray-600 text-center">Aucun résultat trouvé</p>
      ) : (
        resolved.map((result) => (
          <div key={result.id} className="border rounded p-4">
            <h3 className="font-bold text-blue-600">{result.title}</h3>
            <p className="text-sm text-gray-600">
              Pertinence: {Math.round(result.relevance * 100)}%
            </p>
          </div>
        ))
      )}
    </div>
  )
}
```

### 5. Suspense pour Streaming SSR

**`src/entry-server.tsx`**

```typescript
import { createMemoryHistory, createRootRoute, createRoute, createRouter, RootRoute } from '@tanstack/react-router'
import { renderToReadableStream } from 'react-dom/server'

// Streaming avec Suspense
async function render() {
  const memoryHistory = createMemoryHistory({
    initialEntries: ['/'],
  })

  const router = createRouter()

  const stream = await renderToReadableStream(
    <RootComponent router={router} />,
    {
      // Streaming configuration
      onError: (error) => {
        console.error('Streaming error:', error)
      },
    }
  )

  // Flush immédiatement pour permettre le streaming
  stream.flush()

  return stream
}

function RootComponent({ router }) {
  return (
    <html>
      <body>
        {/* Le contenu commence à s'afficher immédiatement */}
        <Suspense fallback={<LoadingShell />}>
          <App router={router} />
        </Suspense>

        {/* Le reste du contenu s'ajoute progressivement */}
        <script
          dangerouslySetInnerHTML={{
            __html: `
              // Hydrater progressivement
              document.addEventListener('DOMContentLoaded', () => {
                console.log('Hydrating...')
              })
            `,
          }}
        />
      </body>
    </html>
  )
}

function LoadingShell() {
  return (
    <div className="space-y-6 p-6 max-w-6xl mx-auto">
      <div className="h-12 bg-gray-200 rounded w-1/3 animate-pulse"></div>
      <div className="space-y-4">
        {[1, 2, 3].map((i) => (
          <div
            key={i}
            className="h-32 bg-gray-200 rounded animate-pulse"
          ></div>
        ))}
      </div>
    </div>
  )
}
```

## Best Practices

### 1. Placer Suspense Stratégiquement

```typescript
// ✅ Grouper les données avec timing similaire
<Suspense fallback={<Loading />}>
  <Await promise={fastAndSlowTogether} />
</Suspense>

// ❌ Éviter de bloquer sur une donnée lente
<Suspense>
  <Await promise={fastData} /> {/* Bloquée par slowData */}
  <Await promise={slowData} />
</Suspense>
```

### 2. Skeleton Screens Appropriés

```typescript
// ✅ Skeleton qui ressemble à la vraie donnée
<Suspense
  fallback={
    <div className="space-y-4">
      <div className="h-6 bg-gray-200 rounded"></div>
      <div className="h-4 bg-gray-200 rounded"></div>
    </div>
  }
>
  <Posts />
</Suspense>
```

### 3. Erreurs dans Suspense

```typescript
// ✅ Combine Suspense et error boundaries
<ErrorBoundary fallback={<Error />}>
  <Suspense fallback={<Loading />}>
    <Await promise={data} />
  </Suspense>
</ErrorBoundary>
```

## Avantages

- **UX Progressive**: Contenu affiché progressivement
- **Non-Blocking**: N'attendez pas les données lentes
- **Streaming Ready**: Parfait pour SSR
- **Composable**: Plusieurs Suspense indépendantes
- **Type Safe**: Entièrement typé avec TypeScript
