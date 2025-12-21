---
name: tanstack:executing-plans
description: Test-driven execution for TanStack Start - implementing features with comprehensive testing and quality assurance
---

# Executing Plans - TDD for TanStack Start

This skill provides test-driven development workflows for implementing TanStack Start features, ensuring quality through tests.

## TDD Workflow Overview

### Red Phase: Write Failing Tests

Start by defining behavior through tests:

```typescript
// tests/server/products.test.ts
import { describe, it, expect } from 'vitest';
import { getProduct, listProducts } from '@/server/products';

describe('Product Server Functions', () => {
  // List products
  it('should return paginated products', async () => {
    const result = await listProducts({ page: 1, limit: 10 });

    expect(result).toHaveProperty('items');
    expect(result).toHaveProperty('total');
    expect(result.items).toHaveLength(10);
  });

  it('should filter products by category', async () => {
    const result = await listProducts({ category: 'electronics' });

    expect(result.items).toBeDefined();
    expect(result.items.every(p => p.category === 'electronics')).toBe(true);
  });

  // Get single product
  it('should return product details', async () => {
    const product = await getProduct('123');

    expect(product).toHaveProperty('id');
    expect(product).toHaveProperty('name');
    expect(product).toHaveProperty('price');
  });

  it('should throw error for non-existent product', async () => {
    await expect(getProduct('invalid')).rejects.toThrow();
  });
});
```

### Green Phase: Implement Minimum Code

Write just enough to pass tests:

```typescript
// src/server/products.ts
import { db } from '@/lib/db';

export async function listProducts({
  page = 1,
  limit = 20,
  category,
  search,
}: {
  page?: number;
  limit?: number;
  category?: string;
  search?: string;
} = {}) {
  const where: any = {};

  if (category) {
    where.category = category;
  }

  if (search) {
    where.name = { contains: search, mode: 'insensitive' };
  }

  const items = await db.product.findMany({
    where,
    skip: (page - 1) * limit,
    take: limit,
  });

  const total = await db.product.count({ where });

  return {
    items,
    total,
    page,
    limit,
    hasMore: (page * limit) < total,
  };
}

export async function getProduct(id: string) {
  const product = await db.product.findUniqueOrThrow({
    where: { id },
  });

  if (!product) {
    throw new Error(`Product ${id} not found`);
  }

  return product;
}
```

### Refactor Phase: Improve Code

Enhance while keeping tests passing:

```typescript
// src/server/products.ts
import { db } from '@/lib/db';
import { z } from 'zod';

// Validation schemas
const listSchema = z.object({
  page: z.number().min(1).default(1),
  limit: z.number().min(1).max(100).default(20),
  category: z.string().optional(),
  search: z.string().optional(),
});

type ListParams = z.infer<typeof listSchema>;

// Helper function
function buildWhereClause(params: ListParams) {
  const where: any = {};

  if (params.category) {
    where.category = params.category;
  }

  if (params.search) {
    where.OR = [
      { name: { contains: params.search, mode: 'insensitive' } },
      { description: { contains: params.search, mode: 'insensitive' } },
    ];
  }

  return where;
}

// Improved functions
export async function listProducts(params?: Partial<ListParams>) {
  const validated = listSchema.parse(params || {});
  const where = buildWhereClause(validated);

  const [items, total] = await Promise.all([
    db.product.findMany({
      where,
      skip: (validated.page - 1) * validated.limit,
      take: validated.limit,
      orderBy: { createdAt: 'desc' },
    }),
    db.product.count({ where }),
  ]);

  return {
    items,
    total,
    page: validated.page,
    limit: validated.limit,
    hasMore: (validated.page * validated.limit) < total,
  };
}

export async function getProduct(id: string) {
  const product = await db.product.findUnique({
    where: { id },
  });

  if (!product) {
    throw new Error(`Product not found: ${id}`);
  }

  return product;
}
```

## Route Testing

### Test Route Loaders

```typescript
// tests/routes/products.test.ts
import { describe, it, expect, beforeEach, afterEach } from 'vitest';
import { renderRoute } from '@/test-utils';

describe('Products Routes', () => {
  describe('GET /products', () => {
    it('should load products list', async () => {
      const { getByText, getByRole } = await renderRoute('/products');

      expect(getByText('Products')).toBeInTheDocument();
      expect(getByRole('list')).toBeInTheDocument();
    });

    it('should display product cards', async () => {
      const { getAllByTestId } = await renderRoute('/products');

      const cards = getAllByTestId('product-card');
      expect(cards.length).toBeGreaterThan(0);
    });

    it('should handle pagination', async () => {
      const { getByRole } = await renderRoute('/products');

      const nextButton = getByRole('button', { name: /next/i });
      expect(nextButton).toBeInTheDocument();
    });
  });

  describe('GET /products/:id', () => {
    it('should load product details', async () => {
      const { getByText } = await renderRoute('/products/123');

      expect(getByText('Product Details')).toBeInTheDocument();
    });

    it('should show not found for invalid ID', async () => {
      const { getByText } = await renderRoute('/products/invalid');

      expect(getByText('Product not found')).toBeInTheDocument();
    });
  });
});
```

## Component Testing

### Server Component Tests

```typescript
// tests/components/ProductList.test.tsx
import { render, screen } from '@testing-library/react';
import { ProductList } from '@/components/ProductList';

// Mock server function
vi.mock('@/server/products', () => ({
  listProducts: vi.fn().mockResolvedValue({
    items: [
      { id: '1', name: 'Product 1' },
      { id: '2', name: 'Product 2' },
    ],
    total: 2,
  }),
}));

describe('ProductList Component', () => {
  it('should render products', async () => {
    render(await ProductList());

    expect(screen.getByText('Product 1')).toBeInTheDocument();
  });

  it('should show loading state', async () => {
    render(
      <Suspense fallback={<div>Loading...</div>}>
        <ProductList />
      </Suspense>
    );

    expect(screen.getByText('Loading...')).toBeInTheDocument();
  });
});
```

### Client Component Tests

```typescript
// tests/components/ProductFilter.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from '@/lib/query-client';
import { ProductFilter } from '@/components/ProductFilter';

function Wrapper({ children }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}

describe('ProductFilter', () => {
  it('should filter by category', async () => {
    const { getByRole } = render(
      <ProductFilter onFilter={vi.fn()} />,
      { wrapper: Wrapper }
    );

    const select = getByRole('combobox');
    fireEvent.change(select, { target: { value: 'electronics' } });

    await waitFor(() => {
      expect(select).toHaveValue('electronics');
    });
  });

  it('should debounce search input', async () => {
    const mockFilter = vi.fn();
    const { getByRole } = render(
      <ProductFilter onFilter={mockFilter} />,
      { wrapper: Wrapper }
    );

    const input = getByRole('textbox', { name: /search/i });
    fireEvent.change(input, { target: { value: 'test' } });

    expect(mockFilter).not.toHaveBeenCalled();

    await waitFor(() => {
      expect(mockFilter).toHaveBeenCalled();
    }, { timeout: 400 });
  });
});
```

## Form Testing

### Test TanStack Form

```typescript
// tests/components/ProductForm.test.tsx
import { render, screen, fireEvent, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClientProvider } from '@tanstack/react-query';
import { ProductForm } from '@/components/ProductForm';
import { queryClient } from '@/lib/query-client';

function Wrapper({ children }) {
  return (
    <QueryClientProvider client={queryClient}>
      {children}
    </QueryClientProvider>
  );
}

describe('ProductForm', () => {
  it('should validate required fields', async () => {
    const user = userEvent.setup();
    render(<ProductForm />, { wrapper: Wrapper });

    const submitButton = screen.getByRole('button', { name: /submit/i });
    await user.click(submitButton);

    await waitFor(() => {
      expect(screen.getByText(/name is required/i)).toBeInTheDocument();
      expect(screen.getByText(/price is required/i)).toBeInTheDocument();
    });
  });

  it('should submit valid form', async () => {
    const user = userEvent.setup();
    const mockSubmit = vi.fn();

    render(<ProductForm onSubmit={mockSubmit} />, { wrapper: Wrapper });

    await user.type(screen.getByLabelText('Name'), 'Test Product');
    await user.type(screen.getByLabelText('Price'), '99.99');
    await user.type(screen.getByLabelText('Category'), 'electronics');

    await user.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(mockSubmit).toHaveBeenCalledWith({
        name: 'Test Product',
        price: 99.99,
        category: 'electronics',
      });
    });
  });

  it('should handle server errors', async () => {
    const user = userEvent.setup();

    vi.mock('@/server/products', () => ({
      createProduct: vi.fn().mockRejectedValue(
        new Error('Server error')
      ),
    }));

    render(<ProductForm />, { wrapper: Wrapper });

    // Fill and submit form
    await user.type(screen.getByLabelText('Name'), 'Test');
    await user.click(screen.getByRole('button', { name: /submit/i }));

    await waitFor(() => {
      expect(screen.getByText(/server error/i)).toBeInTheDocument();
    });
  });
});
```

## Integration Testing

### API + Component Integration

```typescript
// tests/integration/create-product.test.ts
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from '@/lib/query-client';
import { createProduct } from '@/server/products';
import { ProductForm } from '@/components/ProductForm';

describe('Create Product Flow', () => {
  beforeEach(() => {
    queryClient.clear();
  });

  it('should create product end-to-end', async () => {
    const user = userEvent.setup();

    const { container } = render(
      <QueryClientProvider client={queryClient}>
        <ProductForm />
      </QueryClientProvider>
    );

    // Fill form
    await user.type(screen.getByLabelText('Name'), 'New Product');
    await user.type(screen.getByLabelText('Price'), '49.99');

    // Submit
    await user.click(screen.getByRole('button', { name: /create/i }));

    // Verify API called
    await waitFor(() => {
      expect(screen.getByText(/created successfully/i)).toBeInTheDocument();
    });

    // Verify data in cache
    const products = queryClient.getQueryData(['products']);
    expect(products).toContainEqual(
      expect.objectContaining({ name: 'New Product' })
    );
  });
});
```

## E2E Testing with Playwright

```typescript
// tests/e2e/products.spec.ts
import { test, expect } from '@playwright/test';

test.describe('Products Feature', () => {
  test('should browse and view products', async ({ page }) => {
    // Navigate to products
    await page.goto('/products');

    // Wait for list to load
    await page.waitForSelector('[data-testid="product-card"]');

    // Count products
    const cards = await page.locator('[data-testid="product-card"]').count();
    expect(cards).toBeGreaterThan(0);

    // Click first product
    await page.locator('[data-testid="product-card"]').first().click();

    // Verify detail page
    await expect(page).toHaveURL(/products\/\d+/);
    await expect(page.locator('h1')).toBeTruthy();
  });

  test('should create product', async ({ page }) => {
    await page.goto('/products');

    // Click create button
    await page.click('button:has-text("New Product")');

    // Fill form
    await page.fill('input[name="name"]', 'Test Product');
    await page.fill('input[name="price"]', '99.99');
    await page.selectOption('select[name="category"]', 'electronics');

    // Submit
    await page.click('button:has-text("Create")');

    // Verify success
    await expect(page.locator('text=created successfully')).toBeTruthy();
  });

  test('should update product', async ({ page }) => {
    await page.goto('/products/1');

    // Click edit
    await page.click('button:has-text("Edit")');

    // Modify name
    await page.fill('input[name="name"]', 'Updated Name');

    // Submit
    await page.click('button:has-text("Save")');

    // Verify update
    await expect(page.locator('h1')).toContainText('Updated Name');
  });
});
```

## Performance Testing

```typescript
// tests/performance/products.perf.ts
import { bench, describe } from 'vitest';
import { listProducts, getProduct } from '@/server/products';

describe('Product Performance', () => {
  bench('listProducts should be fast', async () => {
    await listProducts({ page: 1, limit: 20 });
  });

  bench('getProduct should be fast', async () => {
    await getProduct('123');
  });
});
```

## Testing Utilities

### Test Setup

```typescript
// tests/setup.ts
import { beforeEach, afterEach, vi } from 'vitest';
import { cleanup } from '@testing-library/react';
import { queryClient } from '@/lib/query-client';

// Cleanup after each test
afterEach(() => {
  cleanup();
  queryClient.clear();
  vi.clearAllMocks();
});

// Mock server
beforeEach(() => {
  vi.clearAllMocks();
});
```

### Mock Factory

```typescript
// tests/factories.ts
export function createMockProduct(overrides = {}) {
  return {
    id: '1',
    name: 'Test Product',
    price: 99.99,
    category: 'electronics',
    createdAt: new Date(),
    ...overrides,
  };
}

export function createMockProducts(count = 3) {
  return Array.from({ length: count }, (_, i) =>
    createMockProduct({ id: String(i + 1) })
  );
}
```

## Continuous Testing

```bash
# Run all tests
npm test

# Watch mode
npm test -- --watch

# Coverage report
npm test -- --coverage

# E2E tests
npm run test:e2e

# Performance tests
npm run test:performance
```

## Resources

- [Vitest Documentation](https://vitest.dev)
- [Testing Library Guide](https://testing-library.com)
- [Playwright Docs](https://playwright.dev)
- [TDD Best Practices](https://kentcdodds.com/blog/common-mistakes-with-react-testing-library)
