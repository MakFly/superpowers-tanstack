# Reference

# File-Based Routing with TanStack Router

## Concept

Le routing basé sur les fichiers est un paradigme où la structure des répertoires définit automatiquement la structure des routes. TanStack Router génère un arbre de routes (`routeTree.gen.ts`) en scannant votre système de fichiers, éliminant le besoin de configuration manuelle et garantissant la cohérence.

## Architecture

### Structure de Fichiers Standard

```
src/
├── routes/
│   ├── __root.tsx           # Route racine (layout principal)
│   ├── index.tsx            # Page d'accueil (/)
│   ├── about.tsx            # /about
│   ├── products.tsx         # /products
│   ├── products.$id.tsx     # /products/:id (paramètre dynamique)
│   ├── products_.$id.edit.tsx  # /products/:id/edit (notation alternative)
│   ├── api/
│   │   ├── __layout.tsx     # Layout pour /api/*
│   │   └── status.tsx       # /api/status
│   └── admin/
│       ├── __layout.tsx     # Layout pour /admin/*
│       ├── index.tsx        # /admin
│       └── users.tsx        # /admin/users
├── routeTree.gen.ts        # Généré automatiquement
└── main.tsx
```

### Conventions de Nommage

| Pattern | Route | Exemple |
|---------|-------|---------|
| `index.tsx` | `/` ou chemin courant | `routes/products/index.tsx` → `/products` |
| `about.tsx` | `/about` | `routes/about.tsx` → `/about` |
| `$param.tsx` | `/:param` (dynamique) | `routes/products.$id.tsx` → `/products/:id` |
| `_.$param.tsx` | `/:param` (variante) | `routes/_.$id.tsx` → `/:id` |
| `__layout.tsx` | Layout sans segment | `routes/admin/__layout.tsx` → layout `/admin/*` |
| `__layout-1.tsx` | Layout nommé | Layouts multiples dans même répertoire |

## Implémentation Complète

### 1. Configuration TanStack Router

**`src/router.ts`**

```typescript
import { RootRoute, Router, createMemoryHistory } from '@tanstack/react-router'
import { routeTree } from './routeTree.gen'

// Créer l'instance du router
export const router = new Router({
  routeTree: routeTree,
  history: createMemoryHistory(),
  defaultPreload: 'intent', // Précharge les routes au survol
  defaultPendingComponent: () => <div>Chargement...</div>,
})

// Enregistrer le router pour la sérialisation
declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}
```

### 2. Route Racine avec Layout Global

**`src/routes/__root.tsx`**

```typescript
import { Outlet, RootRoute, useRouterState } from '@tanstack/react-router'
import { Suspense } from 'react'
import { Header } from '@/components/Header'
import { Sidebar } from '@/components/Sidebar'
import { Footer } from '@/components/Footer'

// Créer la route racine
export const Route = new RootRoute({
  component: RootLayout,
  notFoundComponent: () => <div>404 - Page non trouvée</div>,
  errorComponent: ({ error }) => (
    <div className="text-red-500">
      <h1>Erreur</h1>
      <pre>{error.message}</pre>
    </div>
  ),
})

function RootLayout() {
  const routerState = useRouterState()

  return (
    <div className="flex flex-col min-h-screen">
      <Header />
      <div className="flex flex-1">
        <Sidebar />
        <main className="flex-1 p-6">
          <Suspense fallback={<div>Chargement...</div>}>
            <Outlet />
          </Suspense>
        </main>
      </div>
      <Footer />
    </div>
  )
}
```

### 3. Routes Simples

**`src/routes/index.tsx`** (Page d'accueil - /)

```typescript
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/')({
  component: IndexPage,
})

function IndexPage() {
  return (
    <div className="space-y-4">
      <h1 className="text-4xl font-bold">Bienvenue</h1>
      <p>Page d'accueil de l'application</p>
    </div>
  )
}
```

**`src/routes/about.tsx`** (/about)

```typescript
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/about')({
  component: AboutPage,
  meta: () => ({
    title: 'À Propos',
    description: 'Découvrez notre histoire',
  }),
})

function AboutPage() {
  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-3xl font-bold mb-4">À Propos de Nous</h1>
      <p>Contenu détaillé sur votre entreprise...</p>
    </div>
  )
}
```

### 4. Routes avec Paramètres Dynamiques

**`src/routes/products.tsx`** (/products)

```typescript
import { createFileRoute, Link } from '@tanstack/react-router'

export const Route = createFileRoute('/products')({
  component: ProductsPage,
})

type Product = {
  id: string
  name: string
  price: number
};

function ProductsPage() {
  const products: Product[] = [
    { id: '1', name: 'Produit A', price: 29.99 },
    { id: '2', name: 'Produit B', price: 49.99 },
    { id: '3', name: 'Produit C', price: 79.99 },
  ]

  return (
    <div>
      <h1 className="text-3xl font-bold mb-6">Produits</h1>
      <div className="grid grid-cols-3 gap-4">
        {products.map((product) => (
          <Link
            key={product.id}
            to={`/products/$id`}
            params={{ id: product.id }}
            className="border p-4 rounded hover:shadow-lg"
          >
            <h3 className="font-bold">{product.name}</h3>
            <p className="text-gray-600">${product.price}</p>
          </Link>
        ))}
      </div>
    </div>
  )
}
```

**`src/routes/products.$id.tsx`** (/products/:id)

```typescript
import { createFileRoute, useParams } from '@tanstack/react-router'
import { useState } from 'react'

export const Route = createFileRoute('/products/$id')({
  component: ProductDetail,
  loader: async ({ params }) => {
    // Simuler un appel API
    return {
      id: params.id,
      name: `Produit ${params.id}`,
      description: 'Description détaillée du produit',
      price: 99.99,
      inStock: true,
    }
  },
})

function ProductDetail() {
  const { id } = useParams({ from: '/products/$id' })
  const [quantity, setQuantity] = useState(1)

  return (
    <div className="space-y-4">
      <h1 className="text-3xl font-bold">Produit {id}</h1>
      <div className="space-y-2">
        <p className="text-gray-600">Description détaillée</p>
        <p className="text-2xl font-bold">$99.99</p>
      </div>
      <div className="flex items-center gap-2">
        <label>Quantité:</label>
        <input
          type="number"
          min="1"
          value={quantity}
          onChange={(e) => setQuantity(parseInt(e.target.value))}
          className="border px-2 py-1 w-16"
        />
      </div>
      <button className="bg-blue-600 text-white px-6 py-2 rounded">
        Ajouter au panier
      </button>
    </div>
  )
}
```

### 5. Routes Imbriquées avec Layouts

**`src/routes/admin/__layout.tsx`** (Layout pour /admin/*)

```typescript
import { Outlet, createFileRoute } from '@tanstack/react-router'
import { AdminNav } from '@/components/AdminNav'

export const Route = createFileRoute('/admin')({
  component: AdminLayout,
})

function AdminLayout() {
  return (
    <div className="flex gap-6">
      <AdminNav />
      <main className="flex-1">
        <Outlet />
      </main>
    </div>
  )
}
```

**`src/routes/admin/index.tsx`** (/admin)

```typescript
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/admin/')({
  component: AdminDashboard,
})

function AdminDashboard() {
  return (
    <div>
      <h1 className="text-3xl font-bold">Tableau de Bord Admin</h1>
      <div className="grid grid-cols-3 gap-4 mt-6">
        <StatCard label="Utilisateurs" value="1,234" />
        <StatCard label="Commandes" value="567" />
        <StatCard label="Revenus" value="$45,678" />
      </div>
    </div>
  )
}

function StatCard({ label, value }: { label: string; value: string }) {
  return (
    <div className="border p-4 rounded bg-gray-50">
      <p className="text-gray-600 text-sm">{label}</p>
      <p className="text-2xl font-bold">{value}</p>
    </div>
  )
}
```

**`src/routes/admin/users.tsx`** (/admin/users)

```typescript
import { createFileRoute, Link } from '@tanstack/react-router'

export const Route = createFileRoute('/admin/users')({
  component: AdminUsers,
})

type User = {
  id: string
  name: string
  email: string
  role: 'admin' | 'user'
};

function AdminUsers() {
  const users: User[] = [
    { id: '1', name: 'Alice', email: 'alice@example.com', role: 'admin' },
    { id: '2', name: 'Bob', email: 'bob@example.com', role: 'user' },
    { id: '3', name: 'Charlie', email: 'charlie@example.com', role: 'user' },
  ]

  return (
    <div>
      <div className="flex justify-between items-center mb-6">
        <h1 className="text-3xl font-bold">Gestion des Utilisateurs</h1>
        <Link
          to="/admin/users/new"
          className="bg-blue-600 text-white px-4 py-2 rounded"
        >
          Ajouter Utilisateur
        </Link>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full border-collapse border">
          <thead>
            <tr className="bg-gray-100">
              <th className="border p-2 text-left">Nom</th>
              <th className="border p-2 text-left">Email</th>
              <th className="border p-2 text-left">Rôle</th>
              <th className="border p-2 text-left">Actions</th>
            </tr>
          </thead>
          <tbody>
            {users.map((user) => (
              <tr key={user.id} className="hover:bg-gray-50">
                <td className="border p-2">{user.name}</td>
                <td className="border p-2">{user.email}</td>
                <td className="border p-2">
                  <span
                    className={`px-2 py-1 rounded text-white text-sm ${
                      user.role === 'admin' ? 'bg-red-500' : 'bg-blue-500'
                    }`}
                  >
                    {user.role}
                  </span>
                </td>
                <td className="border p-2">
                  <Link
                    to={`/admin/users/$id`}
                    params={{ id: user.id }}
                    className="text-blue-600 hover:underline"
                  >
                    Éditer
                  </Link>
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  )
}
```

### 6. Génération du routeTree.gen.ts

**Configuration Vite (`vite.config.ts`)**

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import { TanStackRouterVite } from '@tanstack/router-plugin/vite'

export default defineConfig({
  plugins: [TanStackRouterVite(), react()],
  resolve: {
    alias: {
      '@': '/src',
    },
  },
})
```

**Configuration TypeScript (`tsconfig.json`)**

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "jsx": "react-jsx",
    "jsxImportSource": "react",
    "moduleResolution": "bundler",
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    },
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true
  }
}
```

## Best Practices

### 1. Organisation Hiérarchique

```typescript
// ✅ BON: Structure cohérente et prévisible
src/routes/
├── auth/
│   ├── __layout.tsx
│   ├── login.tsx
│   └── register.tsx
└── dashboard/
    ├── __layout.tsx
    ├── index.tsx
    └── settings/
        ├── __layout.tsx
        ├── profile.tsx
        └── security.tsx
```

### 2. Types Sécurisés pour les Routes

```typescript
// ✅ Utiliser les types génériques fournis par TanStack Router
import { createFileRoute, useParams, useSearch } from '@tanstack/react-router'

export const Route = createFileRoute('/users/$userId')({
  validateSearch: (search): UserSearchParams => ({
    tab: (search.tab as string) ?? 'profile',
    sortBy: (search.sortBy as 'name' | 'email') ?? 'name',
  }),
  component: UserPage,
})

type UserSearchParams = {
  tab: string
  sortBy: 'name' | 'email'
};

function UserPage() {
  // Types auto-inférés
  const { userId } = useParams({ from: '/users/$userId' })
  const searchParams = useSearch({ from: '/users/$userId' })

  return <div>Utilisateur {userId}, Tab: {searchParams.tab}</div>
}
```

### 3. Lazy Loading de Routes

```typescript
// ✅ Charger les composants de route à la demande
import { lazy } from 'react'

const AdminPage = lazy(() =>
  import('./admin/index').then(m => ({ default: m.Route.component }))
)

export const Route = createFileRoute('/admin')({
  component: AdminPage,
})
```

## Avantages

- **Type Safety**: Génération automatique de types pour les routes
- **Zero Configuration**: Pas de configuration manuelle d'arbre de routes
- **Scalabilité**: Ajouter des routes en créant simplement des fichiers
- **Cohérence**: Structure de fichiers = structure de routes
- **DX**: Autocomplétion et vérification de types
- **Performance**: Code splitting automatique par route
