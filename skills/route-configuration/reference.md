# Reference

# Route Configuration with TanStack Router

## Concept

La configuration des routes est le cœur de TanStack Router. Chaque route peut être configurée avec `createFileRoute()` pour définir ses comportements, ses loaders, ses validateurs, ses métadonnées, et bien plus. Le système `routeTree.gen.ts` génère automatiquement une arborescence type-safe des routes.

## Architecture de Configuration

### Flow de Initialisation

```
src/routes/*.tsx
        ↓
Plugin Vite @tanstack/router-plugin/vite
        ↓
Scanne la structure des fichiers
        ↓
Génère routeTree.gen.ts (types auto)
        ↓
Router compilé avec types complets
        ↓
Application lancée avec autocomplétion
```

## API createFileRoute() Complète

### Signature de Base

```typescript
import { createFileRoute } from '@tanstack/react-router'

export const Route = createFileRoute('/path/to/route')({
  // Configuration
  component: PageComponent,
  errorComponent: ErrorComponent,
  notFoundComponent: NotFoundComponent,
  loader: async (context) => ({ /* data */ }),
  beforeLoad: async (context) => ({ /* validation */ }),
  validateSearch: (search) => ({ /* validated search */ }),
  shouldRevalidate: (opts) => true,
  preload: 'intent', // 'intent' | 'render' | 'none'
  meta: () => ({ /* metadata */ }),
})
```

## Implémentation Détaillée

### 1. Configuration Simple avec Validation

**`src/routes/profile.tsx`**

```typescript
import { createFileRoute, useParams } from '@tanstack/react-router'

type SearchParams = {
  tab?: 'overview' | 'settings' | 'activity'
  view?: 'card' | 'list'
};

export const Route = createFileRoute('/profile')({
  // Composant principal
  component: ProfilePage,

  // Validation des paramètres de recherche (query string)
  validateSearch: (search: Record<string, unknown>): SearchParams => {
    const tabs = ['overview', 'settings', 'activity'] as const
    const views = ['card', 'list'] as const

    return {
      tab: tabs.includes(search.tab as any) ? (search.tab as any) : 'overview',
      view: views.includes(search.view as any) ? (search.view as any) : 'card',
    }
  },

  // Métadonnées pour SEO et head management
  meta: () => ({
    title: 'Mon Profil',
    description: 'Gérez votre profil utilisateur',
    ogImage: 'https://example.com/og-profile.png',
  }),

  // Composant d'erreur personnalisé
  errorComponent: ({ error }) => (
    <div className="p-4 bg-red-50 border border-red-200 rounded">
      <h2 className="text-red-800 font-bold">Erreur lors du chargement</h2>
      <p className="text-red-700">{error.message}</p>
    </div>
  ),

  // Chargement progressif (avant que le composant ne soit rendu)
  preload: 'intent', // Précharge quand on passe la souris sur un lien
})

function ProfilePage() {
  const search = useSearch({ from: '/profile' })

  return (
    <div className="space-y-4">
      <h1 className="text-3xl font-bold">Mon Profil</h1>
      <div className="flex gap-2 mb-4">
        <Link
          to="/profile"
          search={{ tab: 'overview', view: search.view }}
          className={`px-4 py-2 rounded ${search.tab === 'overview' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
        >
          Aperçu
        </Link>
        <Link
          to="/profile"
          search={{ tab: 'settings', view: search.view }}
          className={`px-4 py-2 rounded ${search.tab === 'settings' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
        >
          Paramètres
        </Link>
        <Link
          to="/profile"
          search={{ tab: 'activity', view: search.view }}
          className={`px-4 py-2 rounded ${search.tab === 'activity' ? 'bg-blue-600 text-white' : 'bg-gray-200'}`}
        >
          Activité
        </Link>
      </div>
      <ContentArea tab={search.tab} view={search.view} />
    </div>
  )
}

function ContentArea({ tab, view }: { tab: string; view: string }) {
  switch (tab) {
    case 'overview':
      return <div>Vue d'ensemble</div>
    case 'settings':
      return <div>Paramètres</div>
    case 'activity':
      return <div>Activité récente</div>
    default:
      return null
  }
}
```

### 2. beforeLoad pour la Validation et les Guards

**`src/routes/admin/__layout.tsx`**

```typescript
import { createFileRoute, Outlet, redirect } from '@tanstack/react-router'
import { useAuthStore } from '@/stores/auth'

type BeforeLoadContext = {
  params?: Record<string, string>
  search?: Record<string, unknown>
};

export const Route = createFileRoute('/admin')({
  // Exécuté AVANT le rendu du composant
  beforeLoad: async ({ context }) => {
    const { user } = useAuthStore.getState()

    // Redirection si pas authentifié
    if (!user) {
      throw redirect({
        to: '/login',
        search: { redirect: '/admin' },
      })
    }

    // Vérifier l'autorisation
    if (user.role !== 'admin') {
      throw redirect({
        to: '/forbidden',
        replace: true,
      })
    }

    // Retourner un contexte pour les routes enfants
    return {
      user,
      permissions: ['read', 'write', 'delete'],
    }
  },

  component: AdminLayout,
  errorComponent: ({ error }) => (
    <div className="p-8 bg-red-50 rounded-lg">
      <h1 className="text-2xl font-bold text-red-800 mb-4">Accès Refusé</h1>
      <p className="text-red-700">{error.message}</p>
    </div>
  ),
})

function AdminLayout() {
  return (
    <div className="flex gap-6">
      <aside className="w-64 bg-gray-800 text-white p-4 rounded">
        <nav className="space-y-2">
          <a href="/admin" className="block p-2 hover:bg-gray-700 rounded">
            Dashboard
          </a>
          <a href="/admin/users" className="block p-2 hover:bg-gray-700 rounded">
            Utilisateurs
          </a>
          <a href="/admin/settings" className="block p-2 hover:bg-gray-700 rounded">
            Paramètres
          </a>
        </nav>
      </aside>
      <main className="flex-1">
        <Outlet />
      </main>
    </div>
  )
}
```

### 3. Loader pour le Chargement de Données

**`src/routes/blog.$slug.tsx`**

```typescript
import { createFileRoute, useParams, useLoaderData } from '@tanstack/react-router'
import { Suspense } from 'react'

type BlogPost = {
  id: string
  slug: string
  title: string
  content: string
  author: string
  publishedAt: string
  tags: string[]
};

export const Route = createFileRoute('/blog/$slug')({
  // Loader: chargement de données avant le rendu
  loader: async ({ params }) => {
    // Appel API
    const response = await fetch(`/api/blog/${params.slug}`)

    if (!response.ok) {
      throw new Error(`Article "${params.slug}" non trouvé`)
    }

    const post: BlogPost = await response.json()

    return {
      post,
      relatedPosts: await fetchRelatedPosts(post.tags),
    }
  },

  // beforeLoad s'exécute AVANT le loader
  beforeLoad: async ({ params }) => {
    console.log(`Chargement de l'article: ${params.slug}`)
  },

  // Validation du paramètre slug
  validateSearch: (search: Record<string, unknown>) => ({
    highlightKeyword: search.highlightKeyword as string | undefined,
  }),

  component: BlogPostPage,

  // Composant affiché pendant le chargement
  pendingComponent: () => (
    <div className="space-y-4 animate-pulse">
      <div className="h-8 bg-gray-200 rounded w-3/4"></div>
      <div className="space-y-2">
        <div className="h-4 bg-gray-200 rounded"></div>
        <div className="h-4 bg-gray-200 rounded"></div>
        <div className="h-4 bg-gray-200 rounded w-5/6"></div>
      </div>
    </div>
  ),

  // Gestion des erreurs lors du chargement
  errorComponent: ({ error }) => (
    <div className="p-6 bg-yellow-50 border border-yellow-200 rounded">
      <h2 className="text-yellow-800 font-bold mb-2">Article non trouvé</h2>
      <p className="text-yellow-700">{error.message}</p>
      <a href="/blog" className="text-blue-600 hover:underline mt-4 inline-block">
        Retour à la liste des articles
      </a>
    </div>
  ),

  // Revalidation des données
  shouldRevalidate: (opts) => {
    // Revalider si l'URL a changé
    if (opts.cause === 'search' && opts.fromSearch.highlightKeyword) {
      return false // Ne pas recharger les données pour les changements de search
    }
    return true
  },
})

function BlogPostPage() {
  const { slug } = useParams({ from: '/blog/$slug' })
  const { post, relatedPosts } = useLoaderData({ from: '/blog/$slug' })
  const search = useSearch({ from: '/blog/$slug' })

  return (
    <article className="max-w-3xl mx-auto">
      <header className="mb-8">
        <h1 className="text-4xl font-bold mb-4">{post.title}</h1>
        <div className="flex items-center justify-between text-gray-600 mb-4">
          <span>{post.author}</span>
          <time>{new Date(post.publishedAt).toLocaleDateString('fr-FR')}</time>
        </div>
        <div className="flex gap-2">
          {post.tags.map((tag) => (
            <span
              key={tag}
              className="px-2 py-1 bg-blue-100 text-blue-800 rounded text-sm"
            >
              {tag}
            </span>
          ))}
        </div>
      </header>

      <div
        className="prose max-w-none mb-8"
        dangerouslySetInnerHTML={{
          __html: highlightText(post.content, search.highlightKeyword),
        }}
      />

      <section className="mt-12 pt-8 border-t">
        <h2 className="text-2xl font-bold mb-4">Articles Connexes</h2>
        <div className="grid grid-cols-2 gap-4">
          {relatedPosts.map((related) => (
            <a
              key={related.slug}
              href={`/blog/${related.slug}`}
              className="border p-4 rounded hover:shadow-lg transition"
            >
              <h3 className="font-bold text-blue-600 hover:underline">
                {related.title}
              </h3>
            </a>
          ))}
        </div>
      </section>
    </article>
  )
}

async function fetchRelatedPosts(tags: string[]): Promise<BlogPost[]> {
  const response = await fetch(
    `/api/blog/related?tags=${tags.join(',')}&limit=4`
  )
  return response.json()
}

function highlightText(text: string, keyword?: string): string {
  if (!keyword) return text
  const regex = new RegExp(`(${keyword})`, 'gi')
  return text.replace(regex, '<mark>$1</mark>')
}
```

### 4. Contexte Partagé entre Routes (RouteContext)

**`src/routes/dashboard/__layout.tsx`**

```typescript
import { createFileRoute, Outlet } from '@tanstack/react-router'
import { createContext, useContext } from 'react'

type DashboardContext = {
  userId: string
  permissions: string[]
  settings: {
    theme: 'light' | 'dark'
    sidebarCollapsed: boolean
  }
};

const DashboardContextProvider = createContext<DashboardContext | null>(null)

export const useDashboardContext = () => {
  const context = useContext(DashboardContextProvider)
  if (!context) {
    throw new Error('useDashboardContext must be used within DashboardLayout')
  }
  return context
}

export const Route = createFileRoute('/dashboard')({
  beforeLoad: async () => {
    const user = await fetchCurrentUser()
    return {
      dashboardContext: {
        userId: user.id,
        permissions: user.permissions,
        settings: user.settings,
      },
    }
  },

  component: DashboardLayout,
})

function DashboardLayout() {
  const { dashboardContext } = useLoaderData({
    from: '/dashboard',
  })

  return (
    <DashboardContextProvider.Provider value={dashboardContext}>
      <div className="flex">
        <aside className="w-64 bg-gray-900 text-white p-4">
          <DashboardSidebar />
        </aside>
        <main className="flex-1">
          <Outlet />
        </main>
      </div>
    </DashboardContextProvider.Provider>
  )
}

function DashboardSidebar() {
  const { userId, permissions } = useDashboardContext()

  return (
    <nav className="space-y-2">
      <div className="text-sm text-gray-400 uppercase tracking-wide mb-4">
        {userId}
      </div>
      {permissions.includes('read:dashboard') && (
        <a href="/dashboard" className="block p-2 hover:bg-gray-800 rounded">
          Dashboard
        </a>
      )}
      {permissions.includes('read:analytics') && (
        <a
          href="/dashboard/analytics"
          className="block p-2 hover:bg-gray-800 rounded"
        >
          Analytique
        </a>
      )}
      {permissions.includes('read:settings') && (
        <a href="/dashboard/settings" className="block p-2 hover:bg-gray-800 rounded">
          Paramètres
        </a>
      )}
    </nav>
  )
}

async function fetchCurrentUser() {
  return {
    id: 'user-123',
    permissions: ['read:dashboard', 'read:analytics'],
    settings: {
      theme: 'light' as const,
      sidebarCollapsed: false,
    },
  }
}
```

### 5. Configuration Complète avec Toutes les Options

**`src/routes/products.$id.edit.tsx`**

```typescript
import { createFileRoute, useParams, useLoaderData, useNavigate } from '@tanstack/react-router'
import { useState } from 'react'

type Product = {
  id: string
  name: string
  description: string
  price: number
  category: string
  stock: number
};

type EditSearchParams = {
  unsavedChanges?: boolean
  returnTo?: string
};

export const Route = createFileRoute('/products/$id/edit')({
  // Validation des paramètres dynamiques
  params: {
    encode: (params) => ({
      id: params.id,
    }),
    decode: (params) => ({
      id: params.id,
    }),
  },

  // Validation des paramètres de recherche
  validateSearch: (search: Record<string, unknown>): EditSearchParams => ({
    unsavedChanges: search.unsavedChanges === 'true',
    returnTo: (search.returnTo as string) || '/products',
  }),

  // Avant le chargement (authentification, etc.)
  beforeLoad: async ({ params, search }) => {
    // Vérifier les permissions
    const { user } = await getAuthState()
    if (!user?.permissions.includes('edit:products')) {
      throw redirect({ to: '/forbidden' })
    }

    return {
      canEdit: true,
      editedBy: user.name,
    }
  },

  // Chargement des données
  loader: async ({ params }) => {
    const response = await fetch(`/api/products/${params.id}`)
    if (!response.ok) throw new Error('Produit non trouvé')
    return response.json() as Promise<Product>
  },

  // Options de revalidation
  shouldRevalidate: (opts) => {
    if (opts.cause === 'search') {
      return opts.fromSearch.unsavedChanges !== opts.toSearch.unsavedChanges
    }
    return true
  },

  // Métadonnées
  meta: () => ({
    title: 'Éditer Produit',
    description: 'Modifier les détails du produit',
  }),

  // Préchargement
  preload: 'intent',

  // Composant principal
  component: EditProductPage,

  // États de chargement et erreur
  pendingComponent: () => <LoadingSpinner />,
  errorComponent: ({ error }) => <ErrorDisplay error={error} />,
  notFoundComponent: () => <NotFoundPage />,
})

function EditProductPage() {
  const navigate = useNavigate()
  const { id } = useParams({ from: '/products/$id/edit' })
  const product = useLoaderData({ from: '/products/$id/edit' })
  const search = useSearch({ from: '/products/$id/edit' })

  const [formData, setFormData] = useState(product)
  const [isSaving, setIsSaving] = useState(false)
  const [errors, setErrors] = useState<Record<string, string>>({})

  const hasChanges =
    JSON.stringify(formData) !== JSON.stringify(product)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setIsSaving(true)

    try {
      const response = await fetch(`/api/products/${id}`, {
        method: 'PUT',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(formData),
      })

      if (!response.ok) {
        const error = await response.json()
        setErrors(error.fieldErrors || {})
        return
      }

      navigate({ to: search.returnTo })
    } finally {
      setIsSaving(false)
    }
  }

  const handleCancel = () => {
    if (hasChanges) {
      navigate({
        to: '/products/$id/edit',
        params: { id },
        search: { unsavedChanges: true, returnTo: search.returnTo },
      })
    } else {
      navigate({ to: search.returnTo })
    }
  }

  return (
    <div className="max-w-2xl mx-auto">
      <h1 className="text-3xl font-bold mb-6">Éditer Produit</h1>

      <form onSubmit={handleSubmit} className="space-y-6 bg-white p-6 rounded shadow">
        <FormField
          label="Nom"
          value={formData.name}
          onChange={(name) => setFormData({ ...formData, name })}
          error={errors.name}
        />

        <FormField
          label="Description"
          type="textarea"
          value={formData.description}
          onChange={(description) => setFormData({ ...formData, description })}
          error={errors.description}
        />

        <FormField
          label="Prix"
          type="number"
          value={formData.price}
          onChange={(price) =>
            setFormData({ ...formData, price: parseFloat(price) })
          }
          error={errors.price}
        />

        <FormField
          label="Catégorie"
          value={formData.category}
          onChange={(category) => setFormData({ ...formData, category })}
          error={errors.category}
        />

        <FormField
          label="Stock"
          type="number"
          value={formData.stock}
          onChange={(stock) =>
            setFormData({ ...formData, stock: parseInt(stock) })
          }
          error={errors.stock}
        />

        <div className="flex gap-4 pt-4">
          <button
            type="submit"
            disabled={isSaving || !hasChanges}
            className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 disabled:opacity-50"
          >
            {isSaving ? 'Enregistrement...' : 'Enregistrer'}
          </button>
          <button
            type="button"
            onClick={handleCancel}
            className="bg-gray-200 text-gray-800 px-6 py-2 rounded hover:bg-gray-300"
          >
            Annuler
          </button>
        </div>
      </form>
    </div>
  )
}

function FormField({
  label,
  type = 'text',
  value,
  onChange,
  error,
}: {
  label: string
  type?: string
  value: any
  onChange: (value: string) => void
  error?: string
}) {
  const Element = type === 'textarea' ? 'textarea' : 'input'

  return (
    <div>
      <label className="block text-sm font-medium text-gray-700 mb-1">
        {label}
      </label>
      <Element
        type={type}
        value={value}
        onChange={(e) => onChange(e.target.value)}
        className={`w-full px-3 py-2 border rounded ${
          error ? 'border-red-500 bg-red-50' : 'border-gray-300'
        }`}
      />
      {error && <p className="text-red-600 text-sm mt-1">{error}</p>}
    </div>
  )
}

function LoadingSpinner() {
  return <div className="text-center py-8">Chargement...</div>
}

function ErrorDisplay({ error }: { error: Error }) {
  return <div className="text-red-600 p-4 bg-red-50 rounded">{error.message}</div>
}

function NotFoundPage() {
  return <div className="text-center py-8">Produit non trouvé</div>
}

async function getAuthState() {
  return {
    user: {
      name: 'John Doe',
      permissions: ['edit:products'],
    },
  }
}
```

## Best Practices

### 1. Pattern: Données + Validations

```typescript
export const Route = createFileRoute('/secure/$id')({
  beforeLoad: validateAuth,
  loader: loadData,
  validateSearch: validateSearch,
  shouldRevalidate: decideRevalidate,
  component: Page,
})
```

### 2. Gérer les Erreurs Gracieusement

```typescript
export const Route = createFileRoute('/api/users')({
  loader: async () => {
    try {
      return await fetchUsers()
    } catch (error) {
      console.error('Erreur:', error)
      return { users: [], error: 'Impossible de charger les utilisateurs' }
    }
  },
  errorComponent: ({ error }) => (
    <ErrorBoundary error={error} />
  ),
})
```

### 3. Pattern: Revalidation Intelligente

```typescript
shouldRevalidate: (opts) => {
  // Revalider uniquement si les params ont changé
  if (opts.cause === 'search') return false
  if (opts.cause === 'action') return true
  return opts.fromPathname !== opts.toPathname
}
```

## Avantages de la Configuration

- **Type Safety**: Tous les paramètres et search params sont typés
- **Flexibilité**: Contrôle fin du comportement de chaque route
- **Performance**: Préchargement intelligent et revalidation sélective
- **Expérience Utilisateur**: Gestion des états de chargement et erreur
- **Maintenabilité**: Configuration co-localisée avec le composant
