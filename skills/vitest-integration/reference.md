# Reference

# Vitest Integration avec TanStack Start

## Concept

Vitest est le test runner moderne pour TanStack Start. Il faut configurer le mocking des server functions, l'HMR, et les fixtures.

## Configuration Vitest

### 1. Configuration Vitest Complète

**`vitest.config.ts`**

```typescript
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import { TanStackRouterVite } from '@tanstack/router-plugin/vite'
import path from 'path'

export default defineConfig({
  plugins: [TanStackRouterVite(), react()],

  test: {
    // Environment
    environment: 'jsdom',

    // Globals (jest-like API)
    globals: true,

    // Setup files
    setupFiles: ['./vitest.setup.ts'],

    // Coverage
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html', 'lcov'],
      exclude: [
        'node_modules/',
        'vitest.setup.ts',
        '**/*.test.{ts,tsx}',
        '**/__tests__/**',
      ],
      lines: 80,
      functions: 80,
      branches: 75,
      statements: 80,
    },

    // Paths alias
    alias: {
      '@': path.resolve(__dirname, './src'),
    },

    // Include patterns
    include: [
      'src/**/*.test.{ts,tsx}',
      'src/**/__tests__/**/*.{ts,tsx}',
    ],

    // Exclude patterns
    exclude: [
      'node_modules',
      'dist',
      '.idea',
      '.git',
      '.cache',
    ],

    // Globals
    testTimeout: 10000,

    // Mock reset
    mockReset: true,
    restoreMocks: true,

    // Reporters
    reporters: ['verbose'],

    // Watch mode exclusions
    watchExclude: ['node_modules', 'dist'],
  },

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
})
```

### 2. Setup Vitest avec Mocks

**`vitest.setup.ts`**

```typescript
import { expect, afterEach, vi, beforeEach } from 'vitest'
import { cleanup } from '@testing-library/react'

// Cleanup après chaque test
afterEach(() => {
  cleanup()
  vi.clearAllMocks()
})

// Mock des APIs globales
global.fetch = vi.fn()
global.localStorage = {
  getItem: vi.fn(),
  setItem: vi.fn(),
  removeItem: vi.fn(),
  clear: vi.fn(),
  length: 0,
  key: vi.fn(),
}

// Mock des Server Functions
vi.mock('@tanstack/start', async () => {
  const actual = await vi.importActual('@tanstack/start')
  return {
    ...actual,
    createServerFn: (method: string, handler: Function) => {
      return async (data: any) => {
        return handler(data)
      }
    },
  }
})

// Custom matchers
expect.extend({
  toBeWithinRange(received: number, floor: number, ceiling: number) {
    const pass = received >= floor && received <= ceiling
    if (pass) {
      return {
        message: () =>
          `expected ${received} not to be within range ${floor} - ${ceiling}`,
        pass: true,
      }
    } else {
      return {
        message: () =>
          `expected ${received} to be within range ${floor} - ${ceiling}`,
        pass: false,
      }
    }
  },
})

// Extend matchers types
declare global {
  namespace Vi {
    interface Matchers<R> {
      toBeWithinRange(floor: number, ceiling: number): R
    }
  }
}
```

### 3. Mocking des Server Functions

**`src/__tests__/utils/serverMocks.ts`**

```typescript
import { vi } from 'vitest'

// Mock factory pour server functions
export function mockServerFn<T extends (...args: any[]) => Promise<any>>(
  implementation: T,
  defaultReturn?: Awaited<ReturnType<T>>
) {
  return vi.fn(implementation).mockResolvedValue(
    defaultReturn || { success: true }
  )
}

// Mocks courants
export const mocks = {
  // Auth
  createServerFn: vi.fn(async (data: any) => ({
    success: true,
    userId: '1',
  })),

  // Produits
  fetchProducts: vi.fn(async () => [
    { id: '1', name: 'Product 1', price: 100 },
    { id: '2', name: 'Product 2', price: 200 },
  ]),

  fetchProduct: vi.fn(async (id: string) => ({
    id,
    name: `Product ${id}`,
    price: 100,
    description: 'Test product',
  })),

  // Utilisateurs
  fetchUser: vi.fn(async () => ({
    id: '1',
    name: 'John Doe',
    email: 'john@example.com',
  })),

  updateUser: vi.fn(async (data: any) => ({
    success: true,
    user: data,
  })),
}

// Reset factory
export function resetMocks() {
  Object.values(mocks).forEach((mock) => {
    if (typeof mock.mockClear === 'function') {
      mock.mockClear()
    }
  })
}
```

### 4. Fixtures et Factories

**`src/__tests__/fixtures/index.ts`**

```typescript
import { faker } from '@faker-js/faker'

// User fixtures
export const createMockUser = (overrides = {}) => ({
  id: faker.string.uuid(),
  name: faker.person.fullName(),
  email: faker.internet.email(),
  avatar: faker.image.avatar(),
  createdAt: faker.date.past(),
  ...overrides,
})

export const mockUser = createMockUser({
  id: '1',
  name: 'John Doe',
  email: 'john@example.com',
})

// Product fixtures
export const createMockProduct = (overrides = {}) => ({
  id: faker.string.uuid(),
  name: faker.commerce.productName(),
  price: parseFloat(faker.commerce.price({ min: 10, max: 1000 })),
  description: faker.commerce.productDescription(),
  stock: faker.number.int({ min: 0, max: 100 }),
  category: faker.helpers.arrayElement(['electronics', 'books', 'clothing']),
  image: faker.image.url(),
  createdAt: faker.date.past(),
  ...overrides,
})

export const mockProduct = createMockProduct({
  id: '1',
  name: 'Test Product',
  price: 100,
})

export const mockProducts = [
  createMockProduct({ id: '1', name: 'Product 1' }),
  createMockProduct({ id: '2', name: 'Product 2' }),
  createMockProduct({ id: '3', name: 'Product 3' }),
]

// Order fixtures
export const createMockOrder = (overrides = {}) => ({
  id: faker.string.uuid(),
  userId: faker.string.uuid(),
  items: [
    {
      productId: '1',
      quantity: faker.number.int({ min: 1, max: 5 }),
      price: 100,
    },
  ],
  total: faker.number.int({ min: 100, max: 1000 }),
  status: faker.helpers.arrayElement(['pending', 'shipped', 'delivered']),
  createdAt: faker.date.past(),
  ...overrides,
})

export const mockOrder = createMockOrder({
  id: '1',
  userId: '1',
  status: 'pending',
})

// Suite fixtures
export const fixtures = {
  user: mockUser,
  product: mockProduct,
  products: mockProducts,
  order: mockOrder,
  createUser: createMockUser,
  createProduct: createMockProduct,
  createOrder: createMockOrder,
}
```

### 5. Test Helpers

**`src/__tests__/utils/testHelpers.ts`**

```typescript
import { render, RenderOptions } from '@testing-library/react'
import React from 'react'

// Custom render avec providers
export function renderWithProviders(
  component: React.ReactElement,
  options?: Omit<RenderOptions, 'wrapper'>
) {
  const Wrapper = ({ children }: { children: React.ReactNode }) => (
    <div>{children}</div>
  )

  return render(component, { wrapper: Wrapper, ...options })
}

// Wait for async operations
export async function waitForAsync(ms = 0) {
  return new Promise((resolve) => setTimeout(resolve, ms))
}

// Create mock loader data
export function createMockLoaderData(overrides = {}) {
  return {
    user: { id: '1', name: 'Test User' },
    ...overrides,
  }
}

// Setup router for tests
export function setupTestRouter() {
  // Configuration du router pour les tests
  return {
    push: vi.fn(),
    navigate: vi.fn(),
  }
}

// Wait for element with retry
export async function waitForElementWithRetry(
  querySelector: () => HTMLElement,
  timeout = 3000
) {
  const start = Date.now()

  while (Date.now() - start < timeout) {
    try {
      return querySelector()
    } catch {
      await waitForAsync(100)
    }
  }

  throw new Error('Element not found within timeout')
}
```

### 6. Tests avec Vitest Complets

**`src/routes/__tests__/products.test.tsx`**

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { fixtures } from '../fixtures'
import { renderWithProviders } from '../utils/testHelpers'

describe('Products Route - Vitest Integration', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('devrait afficher la liste des produits', async () => {
    // Arrange
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      json: async () => fixtures.products,
    } as any)

    // Act
    renderWithProviders(<ProductsPage />)

    // Assert
    await waitFor(() => {
      expect(screen.getByText('Product 1')).toBeInTheDocument()
      expect(screen.getByText('Product 2')).toBeInTheDocument()
    })
  })

  it('devrait filtrer les produits', async () => {
    // Arrange
    const user = userEvent.setup()
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      json: async () => [fixtures.products[0]],
    } as any)

    // Act
    renderWithProviders(<ProductsPage />)
    const input = screen.getByPlaceholderText(/search/i)
    await user.type(input, 'Product 1')

    // Assert
    await waitFor(() => {
      expect(fetch).toHaveBeenCalledWith(
        expect.stringContaining('search=Product%201')
      )
    })
  })

  it('devrait gérer les erreurs API', async () => {
    // Arrange
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: false,
      status: 500,
    } as any)

    // Act
    renderWithProviders(<ProductsPage />)

    // Assert
    await waitFor(() => {
      expect(screen.getByText(/error/i)).toBeInTheDocument()
    })
  })

  it('devrait supporter la pagination', async () => {
    // Arrange
    vi.mocked(fetch).mockResolvedValueOnce({
      ok: true,
      json: async () => fixtures.products,
    } as any)

    // Act
    const { rerender } = renderWithProviders(
      <ProductsPage search={{ page: '1' }} />
    )

    // Naviguer vers page 2
    rerender(<ProductsPage search={{ page: '2' }} />)

    // Assert
    expect(fetch).toHaveBeenCalledWith(
      expect.stringContaining('page=2')
    )
  })
})
```

### 7. Scripts NPM pour Vitest

**`package.json`**

```json
{
  "scripts": {
    "test": "vitest",
    "test:ui": "vitest --ui",
    "test:run": "vitest run",
    "test:coverage": "vitest run --coverage",
    "test:watch": "vitest watch",
    "test:debug": "vitest --inspect-brk --inspect --single-thread",
    "test:server-functions": "vitest run src/**/*.server.test.ts",
    "test:routes": "vitest run src/routes/**/*.test.tsx",
    "test:e2e": "playwright test"
  }
}
```

## Best Practices

### 1. Mocking Structure

```typescript
// ✅ Organiser les mocks
vi.mock('@/lib/api', () => ({
  fetchProducts: vi.fn(),
  fetchUser: vi.fn(),
}))

vi.mock('@/lib/db', () => ({
  getUserByEmail: vi.fn(),
}))
```

### 2. Fixtures avec Factories

```typescript
// ✅ Réutiliser les données
const user = createMockUser({ name: 'Jane' })
const products = Array.from({ length: 5 }, createMockProduct)
```

### 3. Coverage Tracking

```typescript
// ✅ Exécuter avec coverage
npm run test:coverage

// Générer un rapport HTML
vitest run --coverage
```

## Avantages

- **Rapide**: Vite powered
- **Moderne**: ESM native
- **Flexible**: Setup customisable
- **Intégré**: HMR et watch
- **Type Safe**: TypeScript support
