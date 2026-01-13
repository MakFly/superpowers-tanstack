# Reference

# Testing Patterns pour TanStack Start

## Concept

Les tests avec TanStack Start doivent couvrir les routes, les loaders, les server functions et les composants.

## Stratégie de Test

```
Unit Tests (Fonctions pures)
    ↓
Integration Tests (Routes + Loaders)
    ↓
E2E Tests (Flux complet)
```

## Patterns de Test

### 1. Tests de Routes avec Loaders

**`src/routes/__tests__/products.test.ts`**

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { createRouter, createMemoryHistory } from '@tanstack/react-router'
import { render, screen, waitFor } from '@testing-library/react'

// Mock des API
vi.mock('@/lib/api', () => ({
  fetchProducts: vi.fn(),
}))

import { fetchProducts } from '@/lib/api'

describe('Products Route', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('devrait charger et afficher les produits', async () => {
    // Arrange
    const mockProducts = [
      { id: '1', name: 'Produit 1', price: 100 },
      { id: '2', name: 'Produit 2', price: 200 },
    ]

    vi.mocked(fetchProducts).mockResolvedValue(mockProducts)

    // Act
    const { rerender } = render(<ProductsPage />)

    // Assert
    await waitFor(() => {
      expect(screen.getByText('Produit 1')).toBeInTheDocument()
      expect(screen.getByText('Produit 2')).toBeInTheDocument()
    })

    expect(fetchProducts).toHaveBeenCalledOnce()
  })

  it('devrait afficher un skeleton pendant le chargement', () => {
    // Arrange
    vi.mocked(fetchProducts).mockImplementation(
      () =>
        new Promise((resolve) => {
          // Jamais résolu pour voir le skeleton
          setTimeout(() => resolve([]), 10000)
        })
    )

    // Act
    render(<ProductsPage />)

    // Assert
    expect(screen.getByTestId('products-skeleton')).toBeInTheDocument()
  })

  it('devrait gérer les erreurs de chargement', async () => {
    // Arrange
    const error = new Error('API Error')
    vi.mocked(fetchProducts).mockRejectedValue(error)

    // Act
    render(<ProductsPage />)

    // Assert
    await waitFor(() => {
      expect(screen.getByText(/erreur/i)).toBeInTheDocument()
    })
  })

  it('devrait paginer les produits', async () => {
    // Arrange
    vi.mocked(fetchProducts).mockResolvedValue([
      { id: '1', name: 'Produit 1', price: 100 },
    ])

    // Act
    const { rerender } = render(
      <ProductsPage search={{ page: 1 }} />
    )

    expect(fetchProducts).toHaveBeenCalledWith({ page: 1 })

    // Naviguer vers page 2
    rerender(
      <ProductsPage search={{ page: 2 }} />
    )

    // Assert
    expect(fetchProducts).toHaveBeenCalledWith({ page: 2 })
  })
})
```

### 2. Tests de Server Functions

**`src/__tests__/signup.test.ts`**

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { validateSignup } from '@/lib/validation'

// Mock des dépendances serveur
vi.mock('@/lib/db', () => ({
  getUserByEmail: vi.fn(),
  createUser: vi.fn(),
}))

import { getUserByEmail, createUser } from '@/lib/db'

describe('Signup Server Function', () => {
  beforeEach(() => {
    vi.clearAllMocks()
  })

  it('devrait créer un utilisateur avec données valides', async () => {
    // Arrange
    const validData = {
      name: 'John Doe',
      email: 'john@example.com',
      password: 'SecurePass123!',
      confirmPassword: 'SecurePass123!',
      terms: true,
    }

    vi.mocked(getUserByEmail).mockResolvedValue(null)
    vi.mocked(createUser).mockResolvedValue({
      id: '1',
      ...validData,
    })

    // Act
    const result = await validateSignup(validData)

    // Assert
    expect(result).toEqual({ success: true, userId: '1' })
    expect(createUser).toHaveBeenCalledWith(
      expect.objectContaining({
        name: 'John Doe',
        email: 'john@example.com',
      })
    )
  })

  it('devrait rejeter les données invalides', async () => {
    // Arrange
    const invalidData = {
      name: 'J', // Trop court
      email: 'invalid-email',
      password: 'weak',
      confirmPassword: 'weak',
      terms: false,
    }

    // Act & Assert
    await expect(validateSignup(invalidData)).rejects.toThrow()
    expect(createUser).not.toHaveBeenCalled()
  })

  it('devrait empêcher les doublons d\'email', async () => {
    // Arrange
    const data = {
      name: 'John Doe',
      email: 'existing@example.com',
      password: 'SecurePass123!',
      confirmPassword: 'SecurePass123!',
      terms: true,
    }

    vi.mocked(getUserByEmail).mockResolvedValue({ id: '999' })

    // Act & Assert
    await expect(validateSignup(data)).rejects.toThrow(
      'Cet email est déjà utilisé'
    )
    expect(createUser).not.toHaveBeenCalled()
  })

  it('devrait enforcer rate limiting', async () => {
    // Arrange
    const data = {
      name: 'John Doe',
      email: 'john@example.com',
      password: 'SecurePass123!',
      confirmPassword: 'SecurePass123!',
      terms: true,
    }

    // Simuler 5 tentatives
    for (let i = 0; i < 5; i++) {
      vi.mocked(getUserByEmail).mockResolvedValue(null)
      await validateSignup(data)
    }

    // 6e tentative doit être rejetée
    // (necessiterait un vrai système de rate limiting)
  })
})
```

### 3. Tests de Composants avec Loader Data

**`src/routes/__tests__/profile.test.tsx`**

```typescript
import { describe, it, expect, beforeEach, vi } from 'vitest'
import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { createMemoryHistory, createRouter } from '@tanstack/react-router'

describe('Profile Component', () => {
  it('devrait afficher les données de profil', async () => {
    // Arrange
    const mockLoaderData = {
      user: {
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
        avatar: 'https://example.com/avatar.jpg',
      },
    }

    // Act
    render(
      <ProfilePage initialLoaderData={mockLoaderData} />
    )

    // Assert
    expect(screen.getByText('John Doe')).toBeInTheDocument()
    expect(screen.getByText('john@example.com')).toBeInTheDocument()
    expect(screen.getByAltText('John Doe')).toHaveAttribute(
      'src',
      'https://example.com/avatar.jpg'
    )
  })

  it('devrait permettre l\'édition du profil', async () => {
    // Arrange
    const user = userEvent.setup()
    const mockLoaderData = {
      user: {
        id: '1',
        name: 'John Doe',
        email: 'john@example.com',
      },
    }

    // Act
    render(<ProfilePage initialLoaderData={mockLoaderData} />)

    const editButton = screen.getByRole('button', { name: /edit/i })
    await user.click(editButton)

    const nameInput = screen.getByDisplayValue('John Doe')
    await user.clear(nameInput)
    await user.type(nameInput, 'Jane Doe')

    const saveButton = screen.getByRole('button', { name: /save/i })
    await user.click(saveButton)

    // Assert
    expect(screen.getByText(/profile updated/i)).toBeInTheDocument()
  })

  it('devrait afficher un message d\'erreur en cas d\'échec', async () => {
    // Arrange
    const mockLoaderData = { user: null, error: 'Failed to load profile' }

    // Act
    render(
      <ProfilePage initialLoaderData={mockLoaderData} />
    )

    // Assert
    expect(screen.getByText('Failed to load profile')).toBeInTheDocument()
  })
})
```

### 4. Tests d'Intégration Route-Loader

**`src/__tests__/integration/products-flow.test.ts`**

```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import { setupServer } from 'msw/node'
import { rest } from 'msw'

// Mock server avec MSW
const server = setupServer(
  rest.get('/api/products', (req, res, ctx) => {
    const page = req.url.searchParams.get('page') || '1'

    if (page === '1') {
      return res(
        ctx.json({
          products: [
            { id: '1', name: 'Product 1', price: 100 },
            { id: '2', name: 'Product 2', price: 200 },
          ],
          total: 2,
          page: 1,
        })
      )
    }

    return res(ctx.status(400))
  }),

  rest.get('/api/products/:id', (req, res, ctx) => {
    return res(
      ctx.json({
        id: req.params.id,
        name: 'Product ' + req.params.id,
        price: 100,
        description: 'Test product',
      })
    )
  })
)

describe('Products Flow Integration', () => {
  beforeEach(() => server.listen())
  afterEach(() => server.resetHandlers())
  afterEach(() => server.close())

  it('devrait charger et afficher la liste des produits', async () => {
    // Simuler le flow complet
    const response = await fetch('/api/products?page=1')
    const data = await response.json()

    expect(data.products).toHaveLength(2)
    expect(data.products[0].name).toBe('Product 1')
  })

  it('devrait charger les détails d\'un produit', async () => {
    // Charger la liste
    let response = await fetch('/api/products?page=1')
    let data = await response.json()

    // Charger les détails du premier produit
    response = await fetch(`/api/products/${data.products[0].id}`)
    const product = await response.json()

    expect(product.id).toBe('1')
    expect(product.name).toBe('Product 1')
  })

  it('devrait gérer les erreurs d\'API', async () => {
    // Page invalide
    const response = await fetch('/api/products?page=999')

    expect(response.status).toBe(400)
  })
})
```

### 5. Tests E2E avec Playwright

**`e2e/products.spec.ts`**

```typescript
import { test, expect } from '@playwright/test'

test.describe('Products E2E', () => {
  test('devrait afficher la liste des produits', async ({ page }) => {
    // Arrange
    await page.goto('http://localhost:3000/products')

    // Act & Assert
    // Attendre le chargement
    await page.waitForLoadState('networkidle')

    // Vérifier que les produits sont affichés
    const productCards = page.locator('[data-testid="product-card"]')
    await expect(productCards.first()).toBeVisible()

    // Vérifier le nombre de produits
    const count = await productCards.count()
    expect(count).toBeGreaterThan(0)
  })

  test('devrait naviguer vers les détails d\'un produit', async ({ page }) => {
    // Arrange
    await page.goto('http://localhost:3000/products')
    await page.waitForLoadState('networkidle')

    // Act
    const firstProduct = page.locator('[data-testid="product-card"]').first()
    await firstProduct.click()

    // Assert
    await expect(page).toHaveURL(/\/products\/\d+/)
    const productName = page.locator('h1')
    await expect(productName).toBeVisible()
  })

  test('devrait filtrer les produits', async ({ page }) => {
    // Arrange
    await page.goto('http://localhost:3000/products')
    await page.waitForLoadState('networkidle')

    // Act
    const searchInput = page.locator('input[name="search"]')
    await searchInput.fill('laptop')

    // Attendre la mise à jour
    await page.waitForLoadState('networkidle')

    // Assert
    const productCards = page.locator('[data-testid="product-card"]')
    const firstCardText = await productCards.first().textContent()
    expect(firstCardText).toContain('laptop')
  })

  test('devrait ajouter un produit au panier', async ({ page }) => {
    // Arrange
    await page.goto('http://localhost:3000/products/1')
    await page.waitForLoadState('networkidle')

    // Act
    const addButton = page.locator('button', { hasText: /add to cart/i })
    await addButton.click()

    // Assert
    const notification = page.locator('[data-testid="notification"]')
    await expect(notification).toBeVisible()
    await expect(notification).toContainText('Added to cart')

    // Vérifier le panier
    const cartBadge = page.locator('[data-testid="cart-count"]')
    await expect(cartBadge).toHaveText('1')
  })
})
```

## Best Practices

### 1. Isolation des Tests

```typescript
// ✅ Chaque test indépendant
beforeEach(() => {
  vi.clearAllMocks()
  // Reset état
})

afterEach(() => {
  vi.restoreAllMocks()
})
```

### 2. Test IDs pour E2E

```typescript
// ✅ Ajouter data-testid dans le composant
<div data-testid="product-card">
  {product.name}
</div>

// Utiliser dans E2E
page.locator('[data-testid="product-card"]')
```

### 3. Fixtures pour Données

```typescript
// ✅ Partager les données de test
export const mockProducts = [
  { id: '1', name: 'Product 1', price: 100 },
  { id: '2', name: 'Product 2', price: 200 },
]

it('...', () => {
  const products = [...mockProducts]
  // Test
})
```

## Avantages

- **Couverture Complète**: Unit + Integration + E2E
- **Isolation**: Mocks et fixtures
- **Maintenabilité**: Tests clairs et concis
- **Confiance**: Régressions détectées
- **CI/CD Ready**: Exécution automatisée
