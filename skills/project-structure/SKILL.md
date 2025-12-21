---
name: tanstack:project-structure
description: Organize TanStack Start projects with feature-based folder structures
---

# Project Structure pour TanStack Start

## Concept

Une structure bien organisée rend le projet scalable et maintenable. Feature-based est mieux que layer-based pour les applications modernes.

## Structure Recommandée

### 1. Feature-Based Structure

```
src/
├── app/                          # Core app setup
│   ├── root.tsx                  # Root layout
│   ├── providers.tsx             # Global providers
│   └── config.ts                 # App config
│
├── features/                     # Features (domain-driven)
│   ├── auth/                     # Authentication feature
│   │   ├── routes/
│   │   │   ├── login.tsx
│   │   │   ├── signup.tsx
│   │   │   └── reset-password.tsx
│   │   ├── components/
│   │   │   ├── LoginForm.tsx
│   │   │   └── AuthCard.tsx
│   │   ├── hooks/
│   │   │   └── useAuth.ts
│   │   ├── services/
│   │   │   └── authService.ts
│   │   ├── types.ts
│   │   └── __tests__/
│   │       ├── auth.test.ts
│   │       └── useAuth.test.ts
│   │
│   ├── products/
│   │   ├── routes/
│   │   │   ├── products.tsx
│   │   │   ├── products.$id.tsx
│   │   │   └── products.new.tsx
│   │   ├── components/
│   │   │   ├── ProductCard.tsx
│   │   │   ├── ProductList.tsx
│   │   │   └── ProductForm.tsx
│   │   ├── hooks/
│   │   │   ├── useProducts.ts
│   │   │   └── useProduct.ts
│   │   ├── services/
│   │   │   └── productService.ts
│   │   ├── types.ts
│   │   └── __tests__/
│   │       ├── products.test.tsx
│   │       └── useProducts.test.ts
│   │
│   ├── dashboard/
│   │   ├── routes/
│   │   │   └── dashboard.tsx
│   │   ├── components/
│   │   │   ├── DashboardLayout.tsx
│   │   │   └── StatCard.tsx
│   │   ├── hooks/
│   │   │   └── useDashboardData.ts
│   │   └── types.ts
│   │
│   └── admin/
│       ├── routes/
│       │   ├── admin/__layout.tsx
│       │   ├── admin/users.tsx
│       │   └── admin/settings.tsx
│       ├── components/
│       ├── hooks/
│       └── services/
│
├── shared/                       # Shared across features
│   ├── components/
│   │   ├── Navigation.tsx
│   │   ├── Header.tsx
│   │   ├── Footer.tsx
│   │   └── common/
│   │       ├── Button.tsx
│   │       ├── Input.tsx
│   │       └── Modal.tsx
│   │
│   ├── hooks/
│   │   ├── useAsync.ts
│   │   ├── useDebounce.ts
│   │   ├── useLocalStorage.ts
│   │   └── useWindowSize.ts
│   │
│   ├── lib/
│   │   ├── api.ts              # API utilities
│   │   ├── utils.ts            # General utilities
│   │   ├── validation.ts       # Validation schemas
│   │   ├── dataLoader.ts       # Data loading
│   │   └── constants.ts        # Constants
│   │
│   ├── types/
│   │   ├── api.ts
│   │   ├── models.ts
│   │   └── index.ts
│   │
│   ├── styles/
│   │   ├── globals.css
│   │   ├── variables.css
│   │   └── utilities.css
│   │
│   └── __tests__/
│       ├── setup.ts
│       └── fixtures/
│           └── index.ts
│
├── routes/                       # File-based routes (TanStack Router)
│   ├── __layout.tsx
│   ├── index.tsx
│   ├── about.tsx
│   ├── contact.tsx
│   └── [other-routes-auto-mapped]
│
├── server/                       # Server-only code
│   ├── entry.ts                 # Server entry point
│   ├── middleware/
│   │   ├── auth.ts
│   │   └── logging.ts
│   ├── services/
│   │   ├── emailService.ts
│   │   └── databaseService.ts
│   └── functions/
│       ├── auth.server.ts
│       └── products.server.ts
│
├── styles/                       # Global styles
│   ├── globals.css
│   └── tailwind.css
│
└── env.ts                        # Environment config
```

### 2. Feature Structure Détaillée

**`src/features/products/types.ts`**

```typescript
// Types concentrés au niveau feature
export type Product = {
  id: string
  name: string
  price: number
  description: string
  stock: number
  category: string
  image: string
  createdAt: Date
  updatedAt: Date
};

export type ProductFilter = {
  search?: string
  category?: string
  minPrice?: number
  maxPrice?: number
  page?: number
  limit?: number
};

export type ProductResponse = {
  products: Product[]
  total: number
  page: number
  limit: number
};

export enum ProductStatus {
  ACTIVE = 'active',
  INACTIVE = 'inactive',
  ARCHIVED = 'archived',
}
```

**`src/features/products/services/productService.ts`**

```typescript
// Logique métier isolée
import { Product, ProductFilter, ProductResponse } from '../types'

export const productService = {
  async fetchProducts(
    filters: ProductFilter
  ): Promise<ProductResponse> {
    const params = new URLSearchParams({
      ...(filters.search && { search: filters.search }),
      ...(filters.category && { category: filters.category }),
      ...(filters.minPrice && { minPrice: String(filters.minPrice) }),
      page: String(filters.page || 1),
      limit: String(filters.limit || 20),
    })

    const response = await fetch(`/api/products?${params}`)
    if (!response.ok) throw new Error('Failed to fetch products')
    return response.json()
  },

  async fetchProduct(id: string): Promise<Product> {
    const response = await fetch(`/api/products/${id}`)
    if (!response.ok) throw new Error('Product not found')
    return response.json()
  },

  async createProduct(data: Omit<Product, 'id' | 'createdAt' | 'updatedAt'>): Promise<Product> {
    const response = await fetch('/api/products', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })
    if (!response.ok) throw new Error('Failed to create product')
    return response.json()
  },

  async updateProduct(id: string, data: Partial<Product>): Promise<Product> {
    const response = await fetch(`/api/products/${id}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(data),
    })
    if (!response.ok) throw new Error('Failed to update product')
    return response.json()
  },

  async deleteProduct(id: string): Promise<void> {
    const response = await fetch(`/api/products/${id}`, {
      method: 'DELETE',
    })
    if (!response.ok) throw new Error('Failed to delete product')
  },
}
```

**`src/features/products/hooks/useProducts.ts`**

```typescript
// Hooks réutilisables pour la feature
import { useState, useEffect } from 'react'
import { productService } from '../services/productService'
import { Product, ProductFilter } from '../types'

export function useProducts(filters: ProductFilter) {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState<Error | null>(null)

  useEffect(() => {
    const loadProducts = async () => {
      setLoading(true)
      try {
        const data = await productService.fetchProducts(filters)
        setProducts(data.products)
        setError(null)
      } catch (err) {
        setError(err instanceof Error ? err : new Error('Unknown error'))
      } finally {
        setLoading(false)
      }
    }

    loadProducts()
  }, [filters])

  return { products, loading, error }
}

export function useProduct(id: string) {
  const [product, setProduct] = useState<Product | null>(null)
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    const loadProduct = async () => {
      setLoading(true)
      try {
        const data = await productService.fetchProduct(id)
        setProduct(data)
      } finally {
        setLoading(false)
      }
    }

    loadProduct()
  }, [id])

  return { product, loading }
}
```

**`src/features/products/components/ProductCard.tsx`**

```typescript
// Composants au niveau feature
import { Product } from '../types'
import { Link } from '@tanstack/react-router'

type ProductCardProps = {
  product: Product
};

export function ProductCard({ product }: ProductCardProps) {
  return (
    <Link
      to="/products/$id"
      params={{ id: product.id }}
      className="border rounded p-4 hover:shadow-lg transition"
    >
      <img
        src={product.image}
        alt={product.name}
        className="w-full h-48 object-cover rounded mb-3"
      />
      <h3 className="font-bold text-blue-600 line-clamp-2">
        {product.name}
      </h3>
      <p className="text-lg font-bold">${product.price}</p>
      <p className="text-sm text-gray-600">Stock: {product.stock}</p>
    </Link>
  )
}
```

### 3. Routes Auto-Mapped

**`src/routes/__layout.tsx`**

```typescript
import { createRootRoute } from '@tanstack/react-router'
import { RootLayout } from '@/app/root'

export const Route = createRootRoute({
  component: RootLayout,
})
```

**`src/routes/index.tsx`**

```typescript
import { createFileRoute } from '@tanstack/react-router'
import { HomePage } from '@/features/home/pages/Home'

export const Route = createFileRoute('/')({
  component: HomePage,
})
```

**`src/routes/products/index.tsx`**

```typescript
import { createFileRoute } from '@tanstack/react-router'
import { ProductsPage } from '@/features/products/pages/Products'

export const Route = createFileRoute('/products')({
  component: ProductsPage,
})
```

**`src/routes/products/$id.tsx`**

```typescript
import { createFileRoute } from '@tanstack/react-router'
import { ProductDetailPage } from '@/features/products/pages/ProductDetail'

export const Route = createFileRoute('/products/$id')({
  component: ProductDetailPage,
})
```

### 4. Server Functions Organisées

**`src/features/auth/auth.server.ts`**

```typescript
import { createServerFn } from '@tanstack/start'
import { LoginSchema, SignupSchema } from '@/shared/lib/validation'

export const loginUser = createServerFn('POST', async (credentials) => {
  const validated = LoginSchema.parse(credentials)
  // Logique serveur
  return { token: 'xxx', user: { id: '1', name: 'John' } }
})

export const signupUser = createServerFn('POST', async (data) => {
  const validated = SignupSchema.parse(data)
  // Logique serveur
  return { token: 'xxx', user: { id: '1' } }
})
```

### 5. Tests Organisés

**`src/features/products/__tests__/products.test.tsx`**

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { fixtures } from '@/shared/__tests__/fixtures'
import { productService } from '../services/productService'

vi.mock('../services/productService')

describe('Products Feature', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('should fetch products', async () => {
    vi.mocked(productService.fetchProducts).mockResolvedValue({
      products: fixtures.products,
      total: 2,
      page: 1,
      limit: 20,
    })

    const result = await productService.fetchProducts({})

    expect(result.products).toHaveLength(2)
  })
})
```

### 6. Tsconfig avec Paths

**`tsconfig.json`**

```json
{
  "compilerOptions": {
    "baseUrl": ".",
    "paths": {
      "@/*": ["src/*"],
      "@app/*": ["src/app/*"],
      "@features/*": ["src/features/*"],
      "@shared/*": ["src/shared/*"],
      "@server/*": ["src/server/*"]
    }
  }
}
```

## Best Practices

### 1. Co-location Maximale

```typescript
// ✅ Garder les fichiers liés ensemble
features/products/
├── components/
├── hooks/
├── services/
├── types.ts
└── __tests__/
```

### 2. Public API par Feature

**`src/features/products/index.ts`**

```typescript
// Exporter seulement ce qui est public
export { ProductCard } from './components/ProductCard'
export { useProducts } from './hooks/useProducts'
export type { Product } from './types'
```

### 3. Éviter les Imports Croisés

```typescript
// ❌ Mauvais: créer des dépendances circulaires
import { userService } from '@features/auth'

// ✅ Bon: partager via shared
import { getCurrentUser } from '@shared/lib/api'
```

### 4. Grouper par Domaine

```typescript
// ✅ Grouper par domaine métier
features/
├── auth/
├── products/
├── orders/
├── users/
└── analytics/
```

## Avantages

- **Scalable**: Facile d'ajouter des features
- **Maintenable**: Isolation par domaine
- **Testable**: Co-location des tests
- **Découvrable**: Structure cohérente
- **Flexible**: Facile à refactoriser
