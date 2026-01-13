# Reference

# Error Boundaries avec TanStack Start

## Concept

Les error boundaries capturent les erreurs et affichent un UI alternatif au lieu de crash. TanStack Router intègre cela nativement.

## Architecture Error Handling

```
Error Occurs
    ├─ Renderer Error → ErrorComponent
    ├─ Loader Error → errorComponent
    └─ Server Error → Error Boundary
    ↓
Display Error UI
    ├─ Message clair
    ├─ Actions de recovery
    └─ Logging
```

## Patterns Complets

### 1. Error Boundary Basique

**`src/routes/__layout.tsx`**

```typescript
import { createFileRoute } from '@tanstack/react-router'
import { Outlet } from '@tanstack/react-router'
import React from 'react'

export const Route = createFileRoute('/')({
  errorComponent: RootErrorComponent,
  component: RootLayout,
})

function RootLayout() {
  return (
    <div className="min-h-screen flex flex-col">
      <header className="bg-blue-600 text-white p-4">
        <h1>My App</h1>
      </header>

      <main className="flex-1">
        {/* Erreurs enfants affichées ici */}
        <Outlet />
      </main>

      <footer className="bg-gray-800 text-white p-4">
        <p>Footer</p>
      </footer>
    </div>
  )
}

function RootErrorComponent({ error }: { error: Error }) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-red-50">
      <div className="max-w-md bg-white rounded shadow-lg p-8">
        <h1 className="text-2xl font-bold text-red-600 mb-4">
          Oops! Something went wrong
        </h1>

        <div className="bg-red-100 border border-red-300 rounded p-4 mb-6">
          <p className="text-sm text-red-800">
            {error?.message || 'An unexpected error occurred'}
          </p>
        </div>

        <div className="space-y-2">
          <button
            onClick={() => window.location.href = '/'}
            className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700"
          >
            Go Home
          </button>

          <button
            onClick={() => window.location.reload()}
            className="w-full border border-gray-300 py-2 rounded hover:bg-gray-50"
          >
            Refresh Page
          </button>
        </div>

        {process.env.NODE_ENV === 'development' && (
          <details className="mt-6">
            <summary className="cursor-pointer text-gray-600">
              Error Details
            </summary>
            <pre className="mt-2 text-xs bg-gray-100 p-3 rounded overflow-auto max-h-64">
              {error?.stack}
            </pre>
          </details>
        )}
      </div>
    </div>
  )
}
```

### 2. Error Handling par Route

**`src/routes/products.tsx`**

```typescript
import { createFileRoute } from '@tanstack/react-router'

type Product = {
  id: string
  name: string
  price: number
};

type ProductsData = {
  products: Product[]
};

export const Route = createFileRoute('/products')({
  // ✅ Loader avec error handling
  loader: async (): Promise<ProductsData> => {
    try {
      const response = await fetch('/api/products')

      if (!response.ok) {
        if (response.status === 404) {
          throw new Error('Products endpoint not found')
        }
        if (response.status === 500) {
          throw new Error('Server error - Please try again later')
        }
        throw new Error(`Failed to load products (${response.status})`)
      }

      return response.json()
    } catch (error) {
      console.error('Loader error:', error)
      throw error // Rethrow pour que errorComponent le reçoive
    }
  },

  // ✅ Component affiché pendant le chargement
  pendingComponent: () => (
    <div className="max-w-6xl mx-auto">
      <div className="h-8 bg-gray-200 rounded animate-pulse mb-4"></div>
      <div className="grid grid-cols-4 gap-4">
        {[1, 2, 3, 4].map((i) => (
          <div key={i} className="border rounded p-4 space-y-3 animate-pulse">
            <div className="h-32 bg-gray-200 rounded"></div>
            <div className="h-4 bg-gray-200 rounded"></div>
          </div>
        ))}
      </div>
    </div>
  ),

  // ✅ Component affiché en cas d'erreur
  errorComponent: ProductsErrorComponent,

  component: ProductsPage,
})

function ProductsPage() {
  const { products } = Route.useLoaderData()

  return (
    <div className="max-w-6xl mx-auto py-8">
      <h1 className="text-4xl font-bold mb-8">Products</h1>

      <div className="grid grid-cols-4 gap-4">
        {products.map((product) => (
          <div key={product.id} className="border rounded p-4">
            <h3 className="font-bold">{product.name}</h3>
            <p className="text-lg font-bold">${product.price}</p>
          </div>
        ))}
      </div>
    </div>
  )
}

function ProductsErrorComponent({
  error,
  reset,
}: {
  error: Error
  reset: () => void
}) {
  return (
    <div className="max-w-2xl mx-auto py-8">
      <div className="bg-red-50 border border-red-200 rounded p-8">
        <h2 className="text-2xl font-bold text-red-800 mb-4">
          Failed to Load Products
        </h2>

        <p className="text-red-700 mb-6">{error.message}</p>

        {/* Suggestions basées sur l'erreur */}
        {error.message.includes('not found') && (
          <div className="mb-6 bg-blue-50 border border-blue-200 rounded p-4">
            <p className="text-blue-800">
              The products service seems to be unavailable. Our team is working on it.
            </p>
          </div>
        )}

        {error.message.includes('Server error') && (
          <div className="mb-6 bg-yellow-50 border border-yellow-200 rounded p-4">
            <p className="text-yellow-800">
              Please try again in a few moments.
            </p>
          </div>
        )}

        <div className="space-y-2">
          <button
            onClick={() => window.location.reload()}
            className="w-full bg-blue-600 text-white py-2 rounded hover:bg-blue-700"
          >
            Retry
          </button>

          <a
            href="/"
            className="block text-center border border-gray-300 py-2 rounded hover:bg-gray-50"
          >
            Go to Home
          </a>
        </div>
      </div>
    </div>
  )
}
```

### 3. Erreurs avec Context (beforeLoad)

**`src/routes/admin/__layout.tsx`**

```typescript
import { createFileRoute, redirect } from '@tanstack/react-router'

export const Route = createFileRoute('/admin')({
  // ✅ beforeLoad pour la validation
  beforeLoad: async () => {
    try {
      const response = await fetch('/api/me')

      if (!response.ok) {
        if (response.status === 401) {
          throw redirect({
            to: '/login',
            search: { from: window.location.pathname },
          })
        }

        throw new Error('Failed to load user data')
      }

      const user = await response.json()

      if (user.role !== 'admin') {
        throw new Error('Access denied - Admin role required')
      }

      return { user }
    } catch (error) {
      if (error instanceof Response) {
        throw error
      }

      console.error('Admin auth check failed:', error)
      throw error
    }
  },

  errorComponent: ({ error }) => (
    <div className="p-8 bg-red-50 rounded text-center">
      <h1 className="text-2xl font-bold text-red-800 mb-4">Access Denied</h1>

      {error.message === 'Access denied - Admin role required' ? (
        <p className="text-red-700 mb-6">
          You don't have permission to access the admin panel.
        </p>
      ) : (
        <p className="text-red-700 mb-6">{error.message}</p>
      )}

      <a
        href="/"
        className="inline-block bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700"
      >
        Go Back Home
      </a>
    </div>
  ),

  component: AdminLayout,
})

function AdminLayout() {
  const { user } = Route.useRouteContext()

  return (
    <div className="flex gap-8">
      <aside className="w-64 bg-gray-900 text-white p-4">
        <p className="mb-4">Logged in as: {user.name}</p>
        {/* Admin nav */}
      </aside>

      <main className="flex-1">
        {/* Admin content */}
      </main>
    </div>
  )
}
```

### 4. Erreur Boundaries Custom

**`src/components/ErrorBoundary.tsx`**

```typescript
import React, { ReactNode, ComponentType, ReactElement } from 'react'

type ErrorBoundaryProps = {
  children: ReactNode
  fallback?: ComponentType<{ error: Error; reset: () => void }>
  onError?: (error: Error, errorInfo: React.ErrorInfo) => void
};

type ErrorBoundaryState = {
  hasError: boolean
  error: Error | null
};

export class ErrorBoundary extends React.Component<
  ErrorBoundaryProps,
  ErrorBoundaryState
> {
  constructor(props: ErrorBoundaryProps) {
    super(props)
    this.state = { hasError: false, error: null }
  }

  static getDerivedStateFromError(error: Error): ErrorBoundaryState {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    // Log l'erreur
    console.error('Error caught by boundary:', error, errorInfo)

    // Callback optionnel
    this.props.onError?.(error, errorInfo)

    // Envoyer à un service de logging
    if (typeof window !== 'undefined') {
      fetch('/api/errors', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          message: error.message,
          stack: error.stack,
          componentStack: errorInfo.componentStack,
          timestamp: new Date().toISOString(),
        }),
      }).catch(() => {
        // Silencieusement échouer si le logging échoue
      })
    }
  }

  reset = () => {
    this.setState({ hasError: false, error: null })
  }

  render(): ReactElement {
    if (this.state.hasError && this.state.error) {
      const Fallback = this.props.fallback

      if (Fallback) {
        return (
          <Fallback error={this.state.error} reset={this.reset} />
        )
      }

      // Default fallback
      return (
        <div className="p-8 bg-red-50 rounded">
          <h2 className="text-2xl font-bold text-red-800 mb-4">
            Something went wrong
          </h2>
          <p className="text-red-700 mb-6">{this.state.error.message}</p>
          <button
            onClick={this.reset}
            className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700"
          >
            Try Again
          </button>
        </div>
      )
    }

    return this.props.children as ReactElement
  }
}
```

### 5. Logging Centralisé des Erreurs

**`src/lib/errorLogger.ts`**

```typescript
type ErrorLog = {
  message: string
  stack?: string
  severity: 'error' | 'warning' | 'info'
  timestamp: string
  url: string
  userAgent: string
  context?: Record<string, any>
};

class ErrorLogger {
  async log(error: Error | string, context?: Record<string, any>) {
    const errorLog: ErrorLog = {
      message:
        typeof error === 'string' ? error : error.message,
      stack: typeof error === 'object' ? error.stack : undefined,
      severity: 'error',
      timestamp: new Date().toISOString(),
      url: typeof window !== 'undefined' ? window.location.href : '',
      userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : '',
      context,
    }

    // Log localement
    console.error('Error logged:', errorLog)

    // Envoyer au serveur
    if (typeof window !== 'undefined') {
      try {
        await fetch('/api/errors', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json' },
          body: JSON.stringify(errorLog),
        })
      } catch {
        // Silencieusement échouer si l'envoi échoue
      }
    }
  }

  async warn(message: string, context?: Record<string, any>) {
    const log: ErrorLog = {
      message,
      severity: 'warning',
      timestamp: new Date().toISOString(),
      url: typeof window !== 'undefined' ? window.location.href : '',
      userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : '',
      context,
    }

    console.warn('Warning logged:', log)
  }

  async info(message: string, context?: Record<string, any>) {
    const log: ErrorLog = {
      message,
      severity: 'info',
      timestamp: new Date().toISOString(),
      url: typeof window !== 'undefined' ? window.location.href : '',
      userAgent: typeof navigator !== 'undefined' ? navigator.userAgent : '',
      context,
    }

    console.log('Info logged:', log)
  }
}

export const errorLogger = new ErrorLogger()
```

### 6. Retry Logic

**`src/lib/retry.ts`**

```typescript
type RetryOptions = {
  maxAttempts?: number
  delay?: number
  backoff?: (attempt: number) => number
  onRetry?: (attempt: number, error: Error) => void
};

export async function withRetry<T>(
  fn: () => Promise<T>,
  options: RetryOptions = {}
): Promise<T> {
  const {
    maxAttempts = 3,
    delay = 1000,
    backoff = (attempt) => delay * Math.pow(2, attempt - 1),
    onRetry,
  } = options

  let lastError: Error | null = null

  for (let attempt = 1; attempt <= maxAttempts; attempt++) {
    try {
      return await fn()
    } catch (error) {
      lastError = error instanceof Error ? error : new Error(String(error))

      if (attempt < maxAttempts) {
        const waitTime = backoff(attempt)
        onRetry?.(attempt, lastError)
        await new Promise((resolve) => setTimeout(resolve, waitTime))
      }
    }
  }

  throw lastError || new Error('Retry failed')
}

// Utilisation dans un loader
export const Route = createFileRoute('/data')({
  loader: async () => {
    return withRetry(
      () => fetch('/api/data').then((r) => r.json()),
      {
        maxAttempts: 3,
        onRetry: (attempt, error) => {
          console.log(`Retry attempt ${attempt}:`, error.message)
        },
      }
    )
  },
})
```

## Best Practices

### 1. Erreurs Contextualisées

```typescript
// ✅ Erreur claire avec contexte
throw new Error('Failed to load products: API returned 500')

// ❌ Erreur vague
throw new Error('Error')
```

### 2. Recovery Actions

```typescript
// ✅ Offrir des actions de récupération
<button onClick={() => window.location.reload()}>Retry</button>
<button onClick={() => navigate({ to: '/' })}>Go Home</button>

// ❌ Juste afficher l'erreur
<p>{error.message}</p>
```

### 3. Logging Centralisé

```typescript
// ✅ Logger toutes les erreurs
if (error) {
  errorLogger.log(error, { context: 'products-loader' })
}

// ❌ Pas de logging
console.error(error)
```

## Avantages

- **Graceful Degradation**: Pas de white screen of death
- **User Friendly**: Messages clairs en français
- **Debugging**: Logging centralisé
- **Resilient**: Retry et recovery patterns
- **Production Ready**: Error tracking intégré
