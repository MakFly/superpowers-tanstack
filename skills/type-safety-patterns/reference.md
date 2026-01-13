# Reference

# Type Safety Patterns avec TanStack Start

## Concept

TanStack Router offre l'inférence complète des types à travers les loaders, les routes et les composants. Cela élimine les bugs et améliore l'autocomplétion.

## Full Type Inference

### 1. Route avec Types Complets

**`src/routes/products.tsx`**

```typescript
import {
  createFileRoute,
  useLoaderData,
  useRouteContext,
  useParams,
  useSearch,
} from '@tanstack/react-router'

// ✅ Définir les types directement dans la route
type ProductsSearchParams = {
  search?: string
  category?: string
  page?: number
};

type Product = {
  id: string
  name: string
  price: number
  category: string
};

type ProductsLoaderData = {
  products: Product[]
  total: number
  page: number
};

export const Route = createFileRoute('/products')({
  // ✅ Typer les search params
  validateSearch: (search: Record<string, unknown>): ProductsSearchParams => ({
    search: search.search as string | undefined,
    category: search.category as string | undefined,
    page: typeof search.page === 'string' ? parseInt(search.page) : undefined,
  }),

  // ✅ Loader avec types complets
  loader: async ({
    search,
  }): Promise<ProductsLoaderData> => {
    const params = new URLSearchParams({
      ...(search.search && { search: search.search }),
      ...(search.category && { category: search.category }),
      page: String(search.page || 1),
    })

    const response = await fetch(`/api/products?${params}`)
    if (!response.ok) throw new Error('Failed to load products')

    return response.json()
  },

  // ✅ Component avec inférence de types
  component: ProductsPage,
})

// ✅ Types automatiquement inférés
function ProductsPage() {
  // Les types sont automatiquement inférés des loaders
  const { products, total, page } = useLoaderData({ from: '/products' })

  // Les types des search params sont aussi inférés
  const search = useSearch({ from: '/products' })

  // Les types des params URL sont inférés
  const params = useParams({ from: '/products' })

  return (
    <div>
      <h1>Products ({total})</h1>
      {/* TypeScript sait que products est Product[] */}
      {products.map((product) => (
        // ✅ Autocomplétion complète
        <div key={product.id}>
          <h3>{product.name}</h3>
          <p>${product.price}</p>
        </div>
      ))}
    </div>
  )
}
```

### 2. Routes Paramétrées Typées

**`src/routes/products.$id.tsx`**

```typescript
import { createFileRoute, useLoaderData, useParams } from '@tanstack/react-router'

type Product = {
  id: string
  name: string
  price: number
  description: string
  reviews: Review[]
};

type Review = {
  id: string
  rating: number
  text: string
};

// ✅ Typer les params dynamiques
type RouteParams = {
  id: string
};

export const Route = createFileRoute('/products/$id')({
  // ✅ Valider et typer les params
  parseParams: (params): RouteParams => ({
    id: params.id,
  }),

  // ✅ Accéder aux params typés
  loader: async ({ params }): Promise<Product> => {
    // params.id est typé comme string
    const response = await fetch(`/api/products/${params.id}`)
    if (!response.ok) throw new Error('Product not found')

    return response.json()
  },

  component: ProductDetailPage,
})

function ProductDetailPage() {
  // ✅ Types inférés automatiquement
  const product = useLoaderData({ from: '/products/$id' })

  // ✅ Params aussi typés
  const { id } = useParams({ from: '/products/$id' })

  return (
    <div className="max-w-4xl mx-auto">
      <h1>{product.name}</h1>
      <p className="text-2xl font-bold">${product.price}</p>
      <p>{product.description}</p>

      <section>
        <h2>Reviews</h2>
        {/* ✅ Reviews est inféré comme Review[] */}
        {product.reviews.map((review) => (
          <div key={review.id}>
            <div className="stars">{'★'.repeat(review.rating)}</div>
            <p>{review.text}</p>
          </div>
        ))}
      </section>
    </div>
  )
}
```

### 3. Server Functions Typées

**`src/lib/serverFunctions.ts`**

```typescript
import { createServerFn } from '@tanstack/start'

// ✅ Typer les inputs et outputs
type SignupInput = {
  name: string
  email: string
  password: string
};

type SignupOutput = {
  userId: string
  token: string
};

// ✅ Les types sont propagés automatiquement
export const signupUser = createServerFn(
  'POST',
  async (input: SignupInput): Promise<SignupOutput> => {
    // input.name est string
    // Doit retourner SignupOutput

    // Validation
    if (!input.email.includes('@')) {
      throw new Error('Invalid email')
    }

    // Server logic
    const user = await createUser(input)

    return {
      userId: user.id,
      token: generateToken(user.id),
    }
  }
)

// ✅ Utilisation avec types complets
export async function useSignup() {
  return async (credentials: SignupInput) => {
    // result est inféré comme SignupOutput
    const result = await signupUser(credentials)

    // TypeScript sait que result.userId existe
    return result.userId
  }
}
```

### 4. Context Typé

**`src/lib/context.ts`**

```typescript
import { RootRouteWithContext } from '@tanstack/react-router'
import { createContext } from 'react'

// ✅ Définir le contexte typé
export type AppContext = {
  user: {
    id: string
    name: string
    email: string
  } | null
  theme: 'light' | 'dark'
  locale: string
};

export const AppContextValue = createContext<AppContext | null>(null)

// ✅ Typer la root route avec le contexte
export const rootRoute = new RootRouteWithContext<AppContext>()({
  component: RootComponent,
})

function RootComponent() {
  const context = rootRoute.useRouteContext()

  // ✅ context.user est typé
  return (
    <div>
      {context.user && <p>Hello {context.user.name}</p>}
    </div>
  )
}
```

### 5. Validation avec Zod et Inférence

**`src/lib/validation.ts`**

```typescript
import { z } from 'zod'

// ✅ Définir les schémas Zod
export const UserSchema = z.object({
  id: z.string().uuid(),
  name: z.string().min(2),
  email: z.string().email(),
  role: z.enum(['admin', 'user', 'guest']),
})

// ✅ Inférer les types depuis Zod
export type User = z.infer<typeof UserSchema>

// Les types sont automatiquement corrects
const user: User = {
  id: '123',
  name: 'John',
  email: 'john@example.com',
  role: 'user', // TypeScript vérifie que c'est 'admin' | 'user' | 'guest'
}

// ✅ Server function avec validation
export const updateUser = createServerFn(
  'PUT',
  async (data: User): Promise<User> => {
    const validated = UserSchema.parse(data)
    // validated est typé comme User
    return await saveUser(validated)
  }
)
```

### 6. Hook Generique Typé

**`src/hooks/useAsync.ts`**

```typescript
import { useState, useEffect } from 'react'

// ✅ Hook générique avec types
type UseAsyncState<T> = {
  data: T | null
  loading: boolean
  error: Error | null
};

export function useAsync<T>(
  // La fonction doit retourner une Promise<T>
  fn: () => Promise<T>,
  deps?: any[]
): UseAsyncState<T> {
  const [state, setState] = useState<UseAsyncState<T>>({
    data: null,
    loading: true,
    error: null,
  })

  useEffect(() => {
    const load = async () => {
      try {
        const data = await fn()
        setState({ data, loading: false, error: null })
      } catch (error) {
        setState({ data: null, loading: false, error: error as Error })
      }
    }

    load()
  }, deps)

  return state
}

// ✅ Utilisation avec inférence complète
function MyComponent() {
  const { data: products, loading, error } = useAsync(
    async () => {
      const res = await fetch('/api/products')
      return res.json() as Promise<Product[]>
    },
    []
  )

  // data est inféré comme Product[] | null
  return (
    <div>
      {loading && <p>Loading...</p>}
      {error && <p>Error: {error.message}</p>}
      {products?.map((p) => (
        <div key={p.id}>{p.name}</div>
      ))}
    </div>
  )
}
```

### 7. Route Tree Typée

**`src/routes/index.ts`**

```typescript
import { RootRoute } from '@tanstack/react-router'
import { rootRoute } from '@/lib/rootRoute'
import { Route as ProductsRoute } from './products'
import { Route as ProductDetailRoute } from './products.$id'
import { Route as LoginRoute } from './login'

// ✅ Construire l'arbre des routes avec types
export const routeTree = rootRoute.addChildren([
  ProductsRoute.addChildren([
    ProductDetailRoute,
  ]),
  LoginRoute,
])

// ✅ Le router sait maintenant tous les types de toutes les routes
export type RouteTree = typeof routeTree
```

### 8. Composant de Lien Typé

**`src/components/TypedLink.tsx`**

```typescript
import { Link, LinkProps } from '@tanstack/react-router'
import React from 'react'

// ✅ Link est déjà bien typé par défaut
type TypedLinkProps<T extends string> = Omit<LinkProps<T>, 'to'> & {
  to: T
};

export function TypedLink<T extends string>({
  to,
  ...props
}: TypedLinkProps<T>) {
  return <Link to={to} {...props} />
}

// Utilisation
export function ProductLinks() {
  return (
    <div>
      {/* ✅ to est typé - seulement les routes valides */}
      <TypedLink to="/products">All Products</TypedLink>

      {/* TypeScript vérifie que les params existent */}
      <TypedLink to="/products/$id" params={{ id: '123' }}>
        Product Detail
      </TypedLink>

      {/* ❌ Ceci ferait une erreur TypeScript */}
      {/* <TypedLink to="/invalid-route" /> */}
    </div>
  )
}
```

## Best Practices

### 1. Toujours Typer les Loaders

```typescript
// ✅ Complet
export const Route = createFileRoute('/path')({
  loader: async (): Promise<MyData> => {
    return { /* data */ }
  },
  component: MyComponent,
})

// ❌ Incomplet
export const Route = createFileRoute('/path')({
  loader: async () => {
    return { /* data */ }
  },
})
```

### 2. Utiliser les Types Inférés

```typescript
// ✅ Laisser TypeScript inférer
function MyComponent() {
  const data = useLoaderData({ from: '/path' })
  // data est automatiquement typé

  return <div>{data.name}</div>
}

// ❌ Typer manuellement (redondant)
function MyComponent() {
  const data: MyData = useLoaderData({ from: '/path' })
}
```

### 3. Schémas Zod pour Validation

```typescript
// ✅ Source de vérité unique
const schema = z.object({ name: z.string() })
type Data = z.infer<typeof schema>

// ❌ Dupliquer les types
type Data = { name: string };
const schema = z.object({ name: z.string() })
```

## Avantages

- **Zero Runtime Errors**: Les erreurs sont détectées à la compilation
- **Autocomplétion Parfaite**: L'IDE propose tous les champs
- **Refactoring Sûr**: Renommer un champ met à jour partout
- **Self-Documenting**: Les types documentent le code
- **No String References**: Pas de typos dans les clés
