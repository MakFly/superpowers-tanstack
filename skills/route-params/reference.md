# Reference

# Route Parameters with TanStack Router

## Concept

Les paramètres de route permettent de créer des URLs dynamiques où certains segments sont des variables. TanStack Router offre une inférence de type complète pour ces paramètres, éliminant les risques d'erreurs de typage et fournissant une autocomplétion IDE robuste.

## Types de Paramètres

### 1. Paramètres Simples (Single Segment)

```
Route: /products/$id
URL: /products/123
Paramètre: { id: '123' }
```

### 2. Paramètres Multiples

```
Route: /users/$userId/posts/$postId
URL: /users/john/posts/42
Paramètres: { userId: 'john', postId: '42' }
```

### 3. Paramètres Catchall (Segments Multiples)

```
Route: /docs/$.  (* = catchall, tous les segments restants)
URL: /docs/getting-started/installation
Paramètre: { '*': 'getting-started/installation' }
```

## Inférence de Type Automatique

### Magic des Types TanStack

```typescript
// TanStack Router inère automatiquement les types
// ✅ C'est MAGIQUE - pas besoin de déclarer les types manuellement

import { createFileRoute, useParams, Link } from '@tanstack/react-router'

// Fichier: src/routes/users.$userId.tsx
export const Route = createFileRoute('/users/$userId')({
  component: UserPage,
})

function UserPage() {
  // ✅ TypeScript sait que userId existe et est string
  const { userId } = useParams({ from: '/users/$userId' })
  //    ^ Autocomplétion: userId, et c'est tout!

  return <div>User ID: {userId}</div>
}

// ✅ Les liens sont aussi type-safe
<Link
  to="/users/$userId"
  params={{ userId: '123' }} // ✅ Autocomplète!
>
  Voir l'utilisateur
</Link>
```

## Implémentation Complète

### 1. Paramètres Simples

**`src/routes/blog.$slug.tsx`**

```typescript
import { createFileRoute, useParams, Link } from '@tanstack/react-router'

type BlogPost = {
  slug: string
  title: string
  content: string
  author: string
  date: string
  readTime: number
};

export const Route = createFileRoute('/blog/$slug')({
  component: BlogPost,
  loader: async ({ params }) => {
    // ✅ params.slug est automatiquement typé en string
    const response = await fetch(`/api/blog/${params.slug}`)
    const post: BlogPost = await response.json()
    return { post }
  },
})

function BlogPost() {
  const { slug } = useParams({ from: '/blog/$slug' })
  // ✅ slug est typé comme string, autocomplétion activée

  return (
    <article>
      <h1>Article: {slug}</h1>
      <PostContent slug={slug} />
    </article>
  )
}

function PostContent({ slug }: { slug: string }) {
  // Utiliser le slug pour récupérer le contenu
  return <div>Contenu pour {slug}</div>
}
```

**Utilisation dans les Liens**

```typescript
import { Link } from '@tanstack/react-router'

// ✅ Autocomplétion complète
<Link
  to="/blog/$slug"
  params={{ slug: 'getting-started' }} // ✅ slug obligatoire et typé
>
  Lire l'article
</Link>

// ✅ Erreur TypeScript si slug est manquant
// <Link to="/blog/$slug">
// ❌ Erreur: Argument of type '{}' is not assignable to parameter of type 'RouteParams'
```

### 2. Paramètres Multiples

**`src/routes/users.$userId.posts.$postId.tsx`**

```typescript
import { createFileRoute, useParams, useLoaderData } from '@tanstack/react-router'

type Post = {
  id: string
  userId: string
  title: string
  content: string
  comments: Comment[]
};

type Comment = {
  id: string
  author: string
  text: string
  date: string
};

export const Route = createFileRoute('/users/$userId/posts/$postId')({
  // ✅ TanStack infère automatiquement: { userId: string, postId: string }
  component: UserPost,

  loader: async ({ params }) => {
    // ✅ params est typé comme { userId: string, postId: string }
    const [post, comments] = await Promise.all([
      fetch(`/api/users/${params.userId}/posts/${params.postId}`).then((r) =>
        r.json()
      ),
      fetch(
        `/api/users/${params.userId}/posts/${params.postId}/comments`
      ).then((r) => r.json()),
    ])

    return { post: { ...post, comments } }
  },

  beforeLoad: async ({ params }) => {
    // Valider que les IDs sont des nombres
    const userId = parseInt(params.userId)
    const postId = parseInt(params.postId)

    if (isNaN(userId) || isNaN(postId)) {
      throw new Error('IDs invalides')
    }

    return { userId, postId }
  },
})

function UserPost() {
  const { userId, postId } = useParams({
    from: '/users/$userId/posts/$postId',
  })
  // ✅ Autocomplétion: userId | postId

  const { post } = useLoaderData({
    from: '/users/$userId/posts/$postId',
  })

  return (
    <article>
      <header className="mb-6">
        <h1 className="text-4xl font-bold">{post.title}</h1>
        <div className="text-gray-600 mt-2">
          Par{' '}
          <Link
            to="/users/$userId"
            params={{ userId }}
            className="text-blue-600 hover:underline"
          >
            Utilisateur {userId}
          </Link>
        </div>
      </header>

      <div className="prose max-w-none mb-8">{post.content}</div>

      <section className="space-y-4">
        <h2 className="text-2xl font-bold">Commentaires ({post.comments.length})</h2>
        {post.comments.map((comment) => (
          <CommentCard key={comment.id} comment={comment} />
        ))}
      </section>

      <NavigationLinks userId={userId} postId={postId} />
    </article>
  )
}

function CommentCard({ comment }: { comment: Comment }) {
  return (
    <div className="border-l-4 border-blue-500 pl-4 py-2">
      <p className="font-bold">{comment.author}</p>
      <p className="text-gray-700">{comment.text}</p>
      <p className="text-sm text-gray-500">{comment.date}</p>
    </div>
  )
}

function NavigationLinks({
  userId,
  postId,
}: {
  userId: string
  postId: string
}) {
  return (
    <nav className="flex gap-4 mt-8 pt-4 border-t">
      <Link
        to="/users/$userId"
        params={{ userId }}
        className="text-blue-600 hover:underline"
      >
        Voir tous les posts de cet utilisateur
      </Link>
      <Link
        to="/users/$userId/posts/$postId/edit"
        params={{ userId, postId }}
        className="text-blue-600 hover:underline"
      >
        Éditer ce post
      </Link>
    </nav>
  )
}
```

### 3. Paramètres Catchall (Routes Dynamiques Profondes)

**`src/routes/docs.$.tsx`** (catchall pour /docs/*)

```typescript
import { createFileRoute, useParams, Link } from '@tanstack/react-router'
import { useMemo } from 'react'

type DocPage = {
  path: string
  title: string
  content: string
  breadcrumbs: { label: string; path: string }[]
  toc: { level: number; text: string; id: string }[]
};

export const Route = createFileRoute('/docs/$')({
  // $ = catchall - capture tous les segments restants
  // /docs/getting-started/installation → params['*'] = 'getting-started/installation'

  component: DocPage,

  loader: async ({ params }) => {
    // ✅ params['*'] contient le chemin complet après /docs/
    const path = params['*'] ?? 'index'
    const docPath = path.replace(/\//g, '/')

    const response = await fetch(`/api/docs/${docPath}`)
    if (!response.ok) {
      throw new Error(`Documentation "${path}" non trouvée`)
    }

    return response.json() as Promise<DocPage>
  },
})

function DocPage() {
  const params = useParams({ from: '/docs/$' })
  // ✅ params a la clé '*' qui contient le chemin complet
  const currentPath = params['*'] ?? 'index'

  const data = useLoaderData({ from: '/docs/$' })

  const breadcrumbs = useMemo(() => {
    const segments = currentPath.split('/').filter(Boolean)
    const crumbs: { label: string; path: string }[] = [
      { label: 'Docs', path: 'index' },
    ]

    let accumulatedPath = ''
    segments.forEach((segment) => {
      accumulatedPath += `${segment}/`
      crumbs.push({
        label: segment.charAt(0).toUpperCase() + segment.slice(1),
        path: accumulatedPath.slice(0, -1),
      })
    })

    return crumbs
  }, [currentPath])

  return (
    <div className="flex gap-6">
      {/* Sidebar Navigation */}
      <aside className="w-64 border-r pr-4">
        <nav className="space-y-2">
          <DocLink path="index" label="Home" />
          <DocLink path="getting-started/installation" label="Installation" />
          <DocLink path="getting-started/quick-start" label="Quick Start" />
          <DocLink path="advanced/type-safety" label="Type Safety" />
          <DocLink path="advanced/data-loading" label="Data Loading" />
        </nav>
      </aside>

      {/* Main Content */}
      <main className="flex-1">
        {/* Breadcrumbs */}
        <div className="flex gap-2 text-sm text-gray-600 mb-6">
          {breadcrumbs.map((crumb, i) => (
            <div key={crumb.path} className="flex items-center gap-2">
              <Link
                to="/docs/$"
                params={{ '*': crumb.path }}
                className="text-blue-600 hover:underline"
              >
                {crumb.label}
              </Link>
              {i < breadcrumbs.length - 1 && <span>/</span>}
            </div>
          ))}
        </div>

        {/* Article Content */}
        <article>
          <h1 className="text-4xl font-bold mb-4">{data.title}</h1>

          <div
            className="prose max-w-none mb-8"
            dangerouslySetInnerHTML={{ __html: data.content }}
          />

          {/* Table of Contents */}
          {data.toc.length > 0 && (
            <aside className="mt-12 pt-8 border-t">
              <h2 className="font-bold mb-3">Sur cette page</h2>
              <nav className="space-y-1 text-sm">
                {data.toc.map((item) => (
                  <a
                    key={item.id}
                    href={`#${item.id}`}
                    className="block text-blue-600 hover:underline"
                    style={{ paddingLeft: `${(item.level - 2) * 1.5}rem` }}
                  >
                    {item.text}
                  </a>
                ))}
              </nav>
            </aside>
          )}
        </article>
      </main>
    </div>
  )
}

function DocLink({ path, label }: { path: string; label: string }) {
  const params = useParams({ from: '/docs/$' })
  const isActive = (params['*'] ?? 'index') === path

  return (
    <Link
      to="/docs/$"
      params={{ '*': path }}
      className={`block px-3 py-1 rounded transition ${
        isActive
          ? 'bg-blue-100 text-blue-700 font-bold'
          : 'hover:bg-gray-100'
      }`}
    >
      {label}
    </Link>
  )
}
```

### 4. Validation et Transformation de Paramètres

**`src/routes/products.$id.tsx`** (avec validation)

```typescript
import { createFileRoute, useParams, useLoaderData, redirect } from '@tanstack/react-router'
import { z } from 'zod'

type Product = {
  id: number
  name: string
  price: number
  sku: string
  stock: number
};

// Schéma de validation
const productParamsSchema = z.object({
  id: z.coerce
    .number()
    .positive('ID doit être un nombre positif')
    .int('ID doit être un entier'),
})

export const Route = createFileRoute('/products/$id')({
  component: ProductDetail,

  beforeLoad: async ({ params }) => {
    // ✅ Valider les paramètres avec Zod
    try {
      const validated = productParamsSchema.parse({ id: params.id })
      return { validatedParams: validated }
    } catch (error) {
      // Rediriger vers la liste si l'ID est invalide
      throw redirect({
        to: '/products',
        replace: true,
      })
    }
  },

  loader: async ({ params }) => {
    // À ce stade, params.id est garanti d'être un nombre valide
    const productId = parseInt(params.id)

    try {
      const response = await fetch(`/api/products/${productId}`)

      if (response.status === 404) {
        throw new Error(`Produit #${productId} introuvable`)
      }

      if (!response.ok) {
        throw new Error('Erreur lors du chargement du produit')
      }

      const product: Product = await response.json()
      return { product }
    } catch (error) {
      console.error(`Erreur pour produit ${productId}:`, error)
      throw error
    }
  },

  errorComponent: ({ error }) => (
    <div className="p-6 bg-red-50 border border-red-200 rounded">
      <h1 className="text-red-800 font-bold text-lg mb-2">Erreur</h1>
      <p className="text-red-700 mb-4">{error.message}</p>
      <Link to="/products" className="text-blue-600 hover:underline">
        Retour aux produits
      </Link>
    </div>
  ),
})

function ProductDetail() {
  const { id } = useParams({ from: '/products/$id' })
  // ✅ id est une string (du paramètre d'URL)
  const { product } = useLoaderData({ from: '/products/$id' })
  // ✅ product est typé comme Product

  return (
    <div className="max-w-4xl mx-auto">
      <header className="mb-8">
        <h1 className="text-4xl font-bold">{product.name}</h1>
        <p className="text-gray-600 text-lg">SKU: {product.sku}</p>
      </header>

      <div className="grid grid-cols-3 gap-6">
        <div className="col-span-2">
          <div className="bg-gray-100 h-80 rounded flex items-center justify-center">
            <span className="text-gray-400">Image du produit</span>
          </div>
        </div>

        <div className="space-y-4">
          <div className="bg-white border rounded p-4">
            <p className="text-3xl font-bold text-blue-600">${product.price}</p>
            <p
              className={`text-sm mt-2 ${
                product.stock > 0 ? 'text-green-600' : 'text-red-600'
              }`}
            >
              {product.stock > 0 ? `${product.stock} en stock` : 'Indisponible'}
            </p>
          </div>

          <button
            disabled={product.stock === 0}
            className="w-full bg-blue-600 text-white py-3 rounded font-bold hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Ajouter au panier
          </button>

          <Link
            to="/products/$id/edit"
            params={{ id }}
            className="block w-full text-center border py-2 rounded hover:bg-gray-100"
          >
            Éditer
          </Link>
        </div>
      </div>
    </div>
  )
}
```

### 5. Paramètres Optionnels et Variables

**`src/routes/search.tsx`**

```typescript
import { createFileRoute, useSearch, Link } from '@tanstack/react-router'
import { useState } from 'react'

type SearchParams = {
  q: string
  category?: string
  sort?: 'relevance' | 'date' | 'price'
  page?: number
};

export const Route = createFileRoute('/search')({
  validateSearch: (search: Record<string, unknown>): SearchParams => {
    const sortValues = ['relevance', 'date', 'price'] as const

    return {
      q: (search.q as string) || '',
      category: search.category as string | undefined,
      sort: sortValues.includes(search.sort as any)
        ? (search.sort as any)
        : 'relevance',
      page: typeof search.page === 'string' ? parseInt(search.page) : 1,
    }
  },

  component: SearchPage,
})

function SearchPage() {
  // ✅ Récupérer et typer les paramètres de recherche
  const searchParams = useSearch({ from: '/search' })
  const [localQuery, setLocalQuery] = useState(searchParams.q)

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      <div className="space-y-2">
        <h1 className="text-3xl font-bold">Recherche</h1>
        <p className="text-gray-600">
          Résultats pour: <strong>{searchParams.q}</strong>
        </p>
      </div>

      <div className="flex gap-4">
        {/* Barre de recherche */}
        <div className="flex-1">
          <form
            onSubmit={(e) => {
              e.preventDefault()
              navigate({
                to: '/search',
                search: { ...searchParams, q: localQuery, page: 1 },
              })
            }}
          >
            <input
              type="text"
              value={localQuery}
              onChange={(e) => setLocalQuery(e.target.value)}
              placeholder="Rechercher..."
              className="w-full px-4 py-2 border rounded"
            />
          </form>
        </div>

        {/* Filtres */}
        <div className="space-y-2">
          <label>Catégorie:</label>
          <select
            value={searchParams.category || ''}
            onChange={(e) =>
              navigate({
                to: '/search',
                search: {
                  ...searchParams,
                  category: e.target.value || undefined,
                },
              })
            }
            className="px-3 py-2 border rounded"
          >
            <option value="">Toutes</option>
            <option value="electronics">Électronique</option>
            <option value="books">Livres</option>
            <option value="clothing">Vêtements</option>
          </select>
        </div>

        <div className="space-y-2">
          <label>Tri:</label>
          <select
            value={searchParams.sort}
            onChange={(e) =>
              navigate({
                to: '/search',
                search: {
                  ...searchParams,
                  sort: e.target.value as any,
                },
              })
            }
            className="px-3 py-2 border rounded"
          >
            <option value="relevance">Pertinence</option>
            <option value="date">Plus récent</option>
            <option value="price">Prix</option>
          </select>
        </div>
      </div>

      {/* Résultats */}
      <div className="space-y-4">
        {[1, 2, 3, 4, 5].map((i) => (
          <SearchResult
            key={i}
            id={i.toString()}
            title={`Résultat ${i}`}
          />
        ))}
      </div>

      {/* Pagination */}
      <div className="flex justify-center gap-2 pt-6">
        {Array.from({ length: 5 }).map((_, i) => (
          <Link
            key={i + 1}
            to="/search"
            search={{ ...searchParams, page: i + 1 }}
            className={`px-3 py-1 rounded ${
              searchParams.page === i + 1
                ? 'bg-blue-600 text-white'
                : 'border hover:bg-gray-100'
            }`}
          >
            {i + 1}
          </Link>
        ))}
      </div>
    </div>
  )
}

function SearchResult({ id, title }: { id: string; title: string }) {
  return (
    <div className="border p-4 rounded hover:shadow-lg transition">
      <h3 className="font-bold text-blue-600">{title}</h3>
      <p className="text-gray-600 text-sm">Description du produit</p>
    </div>
  )
}
```

## Patterns Avancés

### 1. Transformation de Paramètres

```typescript
// ✅ Slug → ID transformation
export const Route = createFileRoute('/blog/$slug')({
  loader: async ({ params }) => {
    // Transformer le slug en ID interne
    const id = await slugToId(params.slug)
    return await fetchBlogPost(id)
  },
})
```

### 2. Paramètres Type-Safe avec Zod

```typescript
const paramSchema = z.object({
  id: z.coerce.number().int().positive(),
  version: z.enum(['v1', 'v2']).optional(),
})

export const Route = createFileRoute('/api/$id')({
  beforeLoad: ({ params }) => {
    const validated = paramSchema.parse(params)
    return { params: validated }
  },
})
```

### 3. URLs Composées

```typescript
// ✅ Construire des URLs dynamiques type-safe
function UserPostLink({ userId, postId }: { userId: string; postId: string }) {
  return (
    <Link
      to="/users/$userId/posts/$postId"
      params={{ userId, postId }}
    >
      Voir le post
    </Link>
  )
}
```

## Avantages

- **Type Safety Complète**: Aucune string non-typée pour les paramètres
- **Autocomplétion IDE**: Tous les paramètres disponibles dans le contexte
- **Validation Automatique**: Zod ou autres validateurs intégrés
- **Refactoring Sûr**: Renommer un paramètre est détecté partout
- **Documentation Implicite**: Les types servent de documentation
