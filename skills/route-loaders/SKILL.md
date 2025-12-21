---
name: tanstack:route-loaders
description: Implement route loaders for data fetching with beforeLoad and loader functions
---

# Route Loaders with TanStack Router

## Concept

Les route loaders sont des fonctions qui chargent les données nécessaires à une route AVANT que le composant ne soit rendu. Cela permet d'implémenter des patterns modernes comme le SSR-ready data fetching, la validation de l'authentification, et les redirections basées sur les permissions.

## Lifecycle des Loaders

```
URL Change
    ↓
beforeLoad() ← Validation, authentification, redirects
    ↓
loader() ← Chargement des données
    ↓
Component Render (avec les données disponibles)
    ↓
useLoaderData() ← Accès typé aux données
```

## Architecture Complète

### 1. beforeLoad vs loader

| Aspect | beforeLoad | loader |
|--------|-----------|--------|
| Exécution | AVANT loader | APRÈS beforeLoad |
| Usage | Auth, validation, redirects | Fetch data, queries |
| Erreur | Rejeté = Redirect | Rejeté = Error boundary |
| Contexte | Contexte parent disponible | Loaders parents exécutés |
| Revalidation | Rarement | Souvent |

## Implémentation Détaillée

### 1. Pattern Basique: Loader Simple

**`src/routes/profile.tsx`**

```typescript
import {
  createFileRoute,
  useLoaderData,
  Await,
} from '@tanstack/react-router'
import { Suspense } from 'react'

type UserProfile = {
  id: string
  name: string
  email: string
  avatar: string
  bio: string
  joinDate: string
};

export const Route = createFileRoute('/profile')({
  // Loader: Chargement des données AVANT le rendu
  loader: async () => {
    // Appel API
    const response = await fetch('/api/me')
    if (!response.ok) throw new Error('Impossible de charger le profil')
    const profile: UserProfile = await response.json()

    return {
      profile,
      lastUpdated: new Date().toISOString(),
    }
  },

  // Composant affiché pendant le chargement (avant que le loader se termine)
  pendingComponent: () => (
    <div className="space-y-4 animate-pulse">
      <div className="h-32 bg-gray-200 rounded-full w-32 mx-auto"></div>
      <div className="h-8 bg-gray-200 rounded w-1/2 mx-auto"></div>
      <div className="h-4 bg-gray-200 rounded w-3/4 mx-auto"></div>
    </div>
  ),

  component: ProfilePage,
})

function ProfilePage() {
  // ✅ Les données sont GARANTIES d'être disponibles
  const { profile, lastUpdated } = useLoaderData({ from: '/profile' })

  return (
    <div className="max-w-2xl mx-auto">
      <div className="text-center">
        <img
          src={profile.avatar}
          alt={profile.name}
          className="w-32 h-32 rounded-full mx-auto mb-4"
        />
        <h1 className="text-4xl font-bold">{profile.name}</h1>
        <p className="text-gray-600">{profile.email}</p>
      </div>

      <div className="mt-8 bg-white p-6 rounded border">
        <h2 className="text-xl font-bold mb-4">À Propos</h2>
        <p className="text-gray-700">{profile.bio}</p>
        <p className="text-sm text-gray-500 mt-4">
          Membre depuis {new Date(profile.joinDate).toLocaleDateString('fr-FR')}
        </p>
        <p className="text-xs text-gray-400 mt-2">
          Mis à jour: {new Date(lastUpdated).toLocaleTimeString('fr-FR')}
        </p>
      </div>
    </div>
  )
}
```

### 2. beforeLoad: Authentification et Autorisation

**`src/routes/admin/__layout.tsx`**

```typescript
import {
  createFileRoute,
  Outlet,
  redirect,
  useLoaderData,
} from '@tanstack/react-router'
import { useAuthStore } from '@/stores/auth'

type AdminContext = {
  user: {
    id: string
    name: string
    email: string
  }
  permissions: string[]
  role: 'admin' | 'moderator'
};

export const Route = createFileRoute('/admin')({
  // beforeLoad: Exécuté AVANT loader
  // Idéal pour l'authentification et la validation
  beforeLoad: async () => {
    const { user } = useAuthStore.getState()

    // ✅ Redirection si pas authentifié
    if (!user) {
      throw redirect({
        to: '/login',
        search: { from: window.location.pathname },
      })
    }

    // ✅ Redirection si pas admin
    if (!['admin', 'moderator'].includes(user.role)) {
      throw redirect({
        to: '/forbidden',
        replace: true,
      })
    }

    // Retourner le contexte pour les routes enfants
    return {
      adminContext: {
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
        },
        permissions: user.permissions,
        role: user.role,
      } as AdminContext,
    }
  },

  component: AdminLayout,

  // Composant d'erreur personnalisé
  errorComponent: ({ error }) => (
    <div className="p-8 bg-red-50 rounded">
      <h1 className="text-2xl font-bold text-red-800">Accès Refusé</h1>
      <p className="text-red-700">{error.message}</p>
    </div>
  ),
})

function AdminLayout() {
  const { adminContext } = useLoaderData({ from: '/admin' })

  return (
    <div className="flex gap-6">
      <aside className="w-64 bg-gray-900 text-white p-4 rounded">
        <div className="mb-6 pb-6 border-b border-gray-700">
          <p className="text-sm text-gray-400">Connecté en tant que:</p>
          <p className="font-bold">{adminContext.user.name}</p>
          <span className="inline-block mt-2 px-2 py-1 bg-blue-600 text-white text-xs rounded">
            {adminContext.role.toUpperCase()}
          </span>
        </div>

        <nav className="space-y-2">
          {adminContext.permissions.includes('admin:dashboard') && (
            <a
              href="/admin"
              className="block px-4 py-2 rounded hover:bg-gray-800 transition"
            >
              Dashboard
            </a>
          )}
          {adminContext.permissions.includes('admin:users') && (
            <a
              href="/admin/users"
              className="block px-4 py-2 rounded hover:bg-gray-800 transition"
            >
              Utilisateurs
            </a>
          )}
          {adminContext.permissions.includes('admin:content') && (
            <a
              href="/admin/content"
              className="block px-4 py-2 rounded hover:bg-gray-800 transition"
            >
              Contenu
            </a>
          )}
          {adminContext.permissions.includes('admin:settings') && (
            <a
              href="/admin/settings"
              className="block px-4 py-2 rounded hover:bg-gray-800 transition"
            >
              Paramètres
            </a>
          )}
        </nav>
      </aside>

      <main className="flex-1">
        <Outlet />
      </main>
    </div>
  )
}
```

### 3. Loader avec Données Multiples (Parallèle)

**`src/routes/dashboard.index.tsx`**

```typescript
import { createFileRoute, useLoaderData } from '@tanstack/react-router'

type DashboardData = {
  user: { id: string; name: string }
  stats: {
    totalUsers: number
    totalRevenue: number
    activeOrders: number
  }
  recentOrders: Array<{ id: string; amount: number; status: string }>
  topProducts: Array<{ id: string; name: string; sales: number }>
};

export const Route = createFileRoute('/dashboard/')({
  loader: async (): Promise<DashboardData> => {
    // ✅ Charger les données en parallèle
    const [userRes, statsRes, ordersRes, productsRes] = await Promise.all([
      fetch('/api/me'),
      fetch('/api/stats'),
      fetch('/api/orders?limit=10&sort=recent'),
      fetch('/api/products?limit=5&sort=sales'),
    ])

    if (!userRes.ok || !statsRes.ok || !ordersRes.ok || !productsRes.ok) {
      throw new Error('Erreur lors du chargement des données du dashboard')
    }

    const [user, stats, recentOrders, topProducts] = await Promise.all([
      userRes.json(),
      statsRes.json(),
      ordersRes.json(),
      productsRes.json(),
    ])

    return {
      user,
      stats,
      recentOrders,
      topProducts,
    }
  },

  pendingComponent: () => <DashboardSkeleton />,

  component: DashboardPage,
})

function DashboardPage() {
  const data = useLoaderData({ from: '/dashboard/' })

  return (
    <div className="space-y-6">
      <header>
        <h1 className="text-4xl font-bold">Tableau de Bord</h1>
        <p className="text-gray-600">Bienvenue, {data.user.name}</p>
      </header>

      {/* Statistiques */}
      <div className="grid grid-cols-3 gap-6">
        <StatCard
          title="Utilisateurs"
          value={data.stats.totalUsers.toLocaleString()}
          change="+12%"
        />
        <StatCard
          title="Revenus"
          value={`$${data.stats.totalRevenue.toLocaleString()}`}
          change="+8%"
        />
        <StatCard
          title="Commandes Actives"
          value={data.stats.activeOrders}
          change="+5%"
        />
      </div>

      {/* Commandes Récentes */}
      <div className="bg-white rounded border p-6">
        <h2 className="text-2xl font-bold mb-4">Commandes Récentes</h2>
        <table className="w-full">
          <thead>
            <tr className="border-b">
              <th className="text-left py-2">ID</th>
              <th className="text-left py-2">Montant</th>
              <th className="text-left py-2">Statut</th>
            </tr>
          </thead>
          <tbody>
            {data.recentOrders.map((order) => (
              <tr key={order.id} className="border-b hover:bg-gray-50">
                <td className="py-2">{order.id}</td>
                <td className="py-2">${order.amount}</td>
                <td className="py-2">
                  <span
                    className={`px-2 py-1 rounded text-white text-sm ${
                      order.status === 'completed'
                        ? 'bg-green-500'
                        : 'bg-yellow-500'
                    }`}
                  >
                    {order.status}
                  </span>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>

      {/* Produits Populaires */}
      <div className="bg-white rounded border p-6">
        <h2 className="text-2xl font-bold mb-4">Produits Populaires</h2>
        <div className="grid grid-cols-5 gap-4">
          {data.topProducts.map((product) => (
            <div key={product.id} className="border rounded p-3 text-center">
              <p className="font-bold text-sm truncate">{product.name}</p>
              <p className="text-gray-600 text-lg">{product.sales} ventes</p>
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}

function StatCard({
  title,
  value,
  change,
}: {
  title: string
  value: string
  change: string
}) {
  return (
    <div className="bg-white border rounded p-6">
      <p className="text-gray-600 text-sm mb-2">{title}</p>
      <p className="text-3xl font-bold mb-2">{value}</p>
      <p className="text-green-600 text-sm font-bold">{change}</p>
    </div>
  )
}

function DashboardSkeleton() {
  return (
    <div className="space-y-6">
      <div className="h-8 bg-gray-200 rounded w-1/3 animate-pulse"></div>
      <div className="grid grid-cols-3 gap-6">
        {[1, 2, 3].map((i) => (
          <div key={i} className="bg-gray-200 h-32 rounded animate-pulse"></div>
        ))}
      </div>
    </div>
  )
}
```

### 4. Loader avec Streaming et Suspense

**`src/routes/posts.tsx`**

```typescript
import {
  createFileRoute,
  useLoaderData,
  Await,
} from '@tanstack/react-router'
import { Suspense } from 'react'

type PostsLoaderData = {
  posts: Promise<Array<{ id: string; title: string; excerpt: string }>>
  categories: Array<{ id: string; name: string }>
};

export const Route = createFileRoute('/posts')({
  loader: async (): Promise<PostsLoaderData> => {
    // Données rapides
    const categoriesRes = await fetch('/api/categories')
    const categories = await categoriesRes.json()

    // Données lentes (Promise non-awaited)
    const postsPromise = fetch('/api/posts').then((r) => r.json())

    // Retourner immédiatement, posts sera en Suspense
    return {
      categories,
      posts: postsPromise,
    }
  },

  component: PostsPage,

  pendingComponent: () => <LoadingSpinner />,

  errorComponent: ({ error }) => (
    <div className="p-6 bg-red-50 rounded">
      <h2 className="text-red-800 font-bold">Erreur</h2>
      <p>{error.message}</p>
    </div>
  ),
})

function PostsPage() {
  const { categories, posts } = useLoaderData({ from: '/posts' })

  return (
    <div className="space-y-6">
      <h1 className="text-4xl font-bold">Articles</h1>

      {/* Catégories - Rendues immédiatement */}
      <div className="flex gap-2 flex-wrap">
        <button className="px-4 py-2 rounded bg-blue-600 text-white">
          Tous
        </button>
        {categories.map((cat) => (
          <button
            key={cat.id}
            className="px-4 py-2 rounded border hover:bg-gray-100"
          >
            {cat.name}
          </button>
        ))}
      </div>

      {/* Articles - En Suspense pendant le chargement */}
      <Suspense fallback={<PostsSkeleton />}>
        <Await promise={posts}>
          {(resolvedPosts) => (
            <div className="grid grid-cols-2 gap-6">
              {resolvedPosts.map((post) => (
                <article
                  key={post.id}
                  className="border rounded p-4 hover:shadow-lg transition"
                >
                  <h3 className="text-xl font-bold mb-2 text-blue-600">
                    {post.title}
                  </h3>
                  <p className="text-gray-600">{post.excerpt}</p>
                </article>
              ))}
            </div>
          )}
        </Await>
      </Suspense>
    </div>
  )
}

function PostsSkeleton() {
  return (
    <div className="grid grid-cols-2 gap-6">
      {[1, 2, 3, 4].map((i) => (
        <div
          key={i}
          className="border rounded p-4 space-y-3 animate-pulse"
        >
          <div className="h-6 bg-gray-200 rounded w-2/3"></div>
          <div className="h-4 bg-gray-200 rounded"></div>
          <div className="h-4 bg-gray-200 rounded w-5/6"></div>
        </div>
      ))}
    </div>
  )
}

function LoadingSpinner() {
  return <div className="text-center py-8 text-gray-600">Chargement...</div>
}
```

### 5. Loader avec Revalidation Intelligente

**`src/routes/products.$id.tsx`**

```typescript
import { createFileRoute, useLoaderData } from '@tanstack/react-router'

type Product = {
  id: string
  name: string
  price: number
  stock: number
  reviews: Array<{ id: string; rating: number; text: string }>
  relatedProducts: Array<{ id: string; name: string }>
};

export const Route = createFileRoute('/products/$id')({
  loader: async ({ params }) => {
    const [productRes, reviewsRes, relatedRes] = await Promise.all([
      fetch(`/api/products/${params.id}`),
      fetch(`/api/products/${params.id}/reviews`),
      fetch(`/api/products/${params.id}/related`),
    ])

    if (!productRes.ok) throw new Error('Produit non trouvé')

    const product: Product = await productRes.json()
    product.reviews = await reviewsRes.json()
    product.relatedProducts = await relatedRes.json()

    return { product }
  },

  // Décider quand recharger les données
  shouldRevalidate: (opts) => {
    // Revalider si on change de produit
    if (opts.fromPathname !== opts.toPathname) return true

    // Ne pas revalider si on change juste les paramètres de recherche
    if (opts.cause === 'search') return false

    // Ne pas revalider si on scrolle
    if (opts.cause === 'beforeLoad') return false

    return true
  },

  // Contrôler le préchargement
  preload: 'intent', // Précharger au survol du lien

  component: ProductPage,
})

function ProductPage() {
  const { product } = useLoaderData({ from: '/products/$id' })

  return (
    <div className="max-w-4xl mx-auto space-y-8">
      {/* En-tête Produit */}
      <div className="grid grid-cols-2 gap-8">
        <div className="bg-gray-200 h-96 rounded flex items-center justify-center">
          <span className="text-gray-400">Image</span>
        </div>

        <div className="space-y-6">
          <div>
            <h1 className="text-4xl font-bold">{product.name}</h1>
            <p className="text-3xl font-bold text-blue-600 mt-2">
              ${product.price}
            </p>
          </div>

          <div>
            <p
              className={`text-lg font-bold ${
                product.stock > 0 ? 'text-green-600' : 'text-red-600'
              }`}
            >
              {product.stock > 0
                ? `${product.stock} en stock`
                : 'Indisponible'}
            </p>
          </div>

          <div className="flex gap-4">
            <button className="flex-1 bg-blue-600 text-white py-3 rounded font-bold hover:bg-blue-700">
              Ajouter au panier
            </button>
            <button className="flex-1 border py-3 rounded font-bold hover:bg-gray-100">
              Ajouter à la liste de souhaits
            </button>
          </div>
        </div>
      </div>

      {/* Avis */}
      <section className="border-t pt-8">
        <h2 className="text-2xl font-bold mb-4">Avis Clients</h2>
        <div className="space-y-4">
          {product.reviews.map((review) => (
            <div key={review.id} className="border rounded p-4">
              <div className="flex items-center mb-2">
                {Array.from({ length: review.rating }).map((_, i) => (
                  <span key={i} className="text-yellow-400">★</span>
                ))}
              </div>
              <p className="text-gray-700">{review.text}</p>
            </div>
          ))}
        </div>
      </section>

      {/* Produits Connexes */}
      <section className="border-t pt-8">
        <h2 className="text-2xl font-bold mb-4">Produits Connexes</h2>
        <div className="grid grid-cols-4 gap-4">
          {product.relatedProducts.map((related) => (
            <a
              key={related.id}
              href={`/products/${related.id}`}
              className="border rounded p-4 hover:shadow-lg transition"
            >
              <div className="bg-gray-200 h-32 rounded mb-2"></div>
              <p className="font-bold text-sm text-blue-600">{related.name}</p>
            </a>
          ))}
        </div>
      </section>
    </div>
  )
}
```

### 6. Loader avec Gestion d'Erreurs Avancée

**`src/routes/checkout.tsx`**

```typescript
import {
  createFileRoute,
  useLoaderData,
  redirect,
} from '@tanstack/react-router'

type CheckoutData = {
  cart: { items: Array<{ id: string; quantity: number }> }
  shippingMethods: Array<{ id: string; name: string; price: number }>
  paymentMethods: Array<{ id: string; name: string }>
};

export const Route = createFileRoute('/checkout')({
  beforeLoad: async () => {
    // Vérifier que l'utilisateur est connecté
    const response = await fetch('/api/me')
    if (!response.ok) {
      throw redirect({
        to: '/login',
        search: { next: '/checkout' },
      })
    }
    return {}
  },

  loader: async (): Promise<CheckoutData> => {
    try {
      // Vérifier le panier
      const cartRes = await fetch('/api/cart')
      if (!cartRes.ok) {
        throw new Error('Impossible de charger le panier')
      }

      const cart = await cartRes.json()

      // Vérifier que le panier n'est pas vide
      if (!cart.items || cart.items.length === 0) {
        throw redirect({
          to: '/products',
          replace: true,
        })
      }

      // Charger les méthodes
      const [shippingRes, paymentRes] = await Promise.all([
        fetch('/api/shipping-methods'),
        fetch('/api/payment-methods'),
      ])

      if (!shippingRes.ok || !paymentRes.ok) {
        throw new Error('Erreur lors du chargement des méthodes de paiement')
      }

      const [shippingMethods, paymentMethods] = await Promise.all([
        shippingRes.json(),
        paymentRes.json(),
      ])

      return {
        cart,
        shippingMethods,
        paymentMethods,
      }
    } catch (error) {
      if (error instanceof Error && error.message === 'redirect') {
        throw error
      }
      console.error('Erreur checkout:', error)
      throw new Error(
        'Une erreur est survenue lors de la préparation du paiement'
      )
    }
  },

  errorComponent: ({ error }) => (
    <div className="max-w-2xl mx-auto p-6 bg-red-50 rounded border border-red-200">
      <h1 className="text-red-800 font-bold text-2xl mb-2">Erreur</h1>
      <p className="text-red-700 mb-4">{error.message}</p>
      <a href="/products" className="text-blue-600 hover:underline">
        Retour au shopping
      </a>
    </div>
  ),

  component: CheckoutPage,
})

function CheckoutPage() {
  const { cart, shippingMethods, paymentMethods } = useLoaderData({
    from: '/checkout',
  })

  return (
    <div className="max-w-2xl mx-auto py-8 space-y-8">
      <h1 className="text-4xl font-bold">Finaliser la commande</h1>

      <div className="space-y-6">
        {/* Résumé du Panier */}
        <section className="border rounded p-6">
          <h2 className="text-2xl font-bold mb-4">Votre Panier</h2>
          <div className="space-y-2 border-b pb-4 mb-4">
            {cart.items.map((item) => (
              <div key={item.id} className="flex justify-between">
                <span>Produit {item.id}</span>
                <span>Quantité: {item.quantity}</span>
              </div>
            ))}
          </div>
          <p className="text-xl font-bold">Total: $199.98</p>
        </section>

        {/* Méthode de Livraison */}
        <section className="border rounded p-6">
          <h2 className="text-2xl font-bold mb-4">Livraison</h2>
          <div className="space-y-2">
            {shippingMethods.map((method) => (
              <label key={method.id} className="flex items-center gap-3 p-3 border rounded">
                <input type="radio" name="shipping" defaultChecked />
                <span className="flex-1">{method.name}</span>
                <span className="font-bold">${method.price}</span>
              </label>
            ))}
          </div>
        </section>

        {/* Méthode de Paiement */}
        <section className="border rounded p-6">
          <h2 className="text-2xl font-bold mb-4">Paiement</h2>
          <div className="space-y-2">
            {paymentMethods.map((method) => (
              <label key={method.id} className="flex items-center gap-3 p-3 border rounded">
                <input type="radio" name="payment" defaultChecked />
                <span>{method.name}</span>
              </label>
            ))}
          </div>
        </section>

        {/* Bouton Paiement */}
        <button className="w-full bg-blue-600 text-white py-4 rounded font-bold text-lg hover:bg-blue-700">
          Procéder au Paiement
        </button>
      </div>
    </div>
  )
}
```

## Best Practices

### 1. Separation of Concerns

```typescript
// ✅ Séparer beforeLoad (validation) et loader (données)
export const Route = createFileRoute('/protected/data')({
  beforeLoad: validateAuth,   // ← Authentification
  loader: loadProtectedData,   // ← Données
  component: ProtectedPage,
})
```

### 2. Erreur Handling Centré

```typescript
export const Route = createFileRoute('/data')({
  loader: async () => {
    try {
      return await fetchData()
    } catch (error) {
      console.error('Loader error:', error)
      throw new Error('Failed to load data')
    }
  },
  errorComponent: ({ error }) => <ErrorBoundary error={error} />,
})
```

### 3. Streaming pour UX Meilleure

```typescript
// ✅ Retourner Promises pour le streaming
export const Route = createFileRoute('/fast-slow')({
  loader: async () => {
    const fast = await fetchFastData()
    const slowPromise = fetchSlowData() // Pas await

    return { fast, slow: slowPromise }
  },
})
```

### 4. Revalidation Stratégique

```typescript
shouldRevalidate: (opts) => {
  // Ne revalider que si vraiment nécessaire
  if (opts.cause === 'search') return false // Les filtres ne changent pas les données
  if (opts.fromPathname === opts.toPathname) return false // Même page
  return true // Sinon, recharger
}
```

## Avantages

- **Type Safety**: Données typées automatiquement
- **Composants Garantis**: Les données sont garanties avant le rendu
- **Suspense Support**: Streaming natif avec React Suspense
- **Error Handling**: Gestion centralisée des erreurs
- **Performance**: Chargement précoce, pas de waterfall
- **SEO-Ready**: Données disponibles pour le SSR
