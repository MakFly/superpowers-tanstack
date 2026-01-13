# Reference

# Quality Checks Skill for TanStack Start

Comprehensive quality assurance framework for TanStack Start applications, ensuring code meets standards and performance targets.

## Overview

Quality Gates:

- **TypeScript**: Strict type safety
- **Testing**: Unit, integration, E2E coverage
- **Performance**: Lighthouse, bundle analysis
- **Accessibility**: WCAG 2.1 compliance
- **Security**: Vulnerability scanning
- **Code Quality**: Linting and formatting

## 1. TypeScript Configuration

### Strict tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "jsx": "react-jsx",
    "strict": true,
    "noImplicitAny": true,
    "strictNullChecks": true,
    "strictFunctionTypes": true,
    "strictBindCallApply": true,
    "strictPropertyInitialization": true,
    "noImplicitThis": true,
    "alwaysStrict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    },
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist", ".output"]
}
```

### Type Checking

```bash
# Run TypeScript check
npm run type-check

# Check with details
npx tsc --noEmit --pretty

# Verify no implicit any
npx tsc --noImplicitAny --noEmit
```

### Type Checking Examples

```typescript
// ✓ Good: Explicit return type
async function getProduct(id: string): Promise<Product> {
  const response = await fetch(`/api/products/${id}`);
  return response.json();
}

// ✗ Bad: Missing return type
async function getProduct(id: string) {
  const response = await fetch(`/api/products/${id}`);
  return response.json();
}

// ✓ Good: Proper typing
function handleClick(event: React.MouseEvent<HTMLButtonElement>): void {
  console.log('Clicked');
}

// ✗ Bad: Any typing
function handleClick(event: any) {
  console.log('Clicked');
}

// ✓ Good: Type-safe route params
type ProductRouteParams = {
  productId: string;
};

// ✗ Bad: Untyped params
const productId = params.productId;
```

## 2. ESLint Configuration

```javascript
// eslint.config.js
import typescriptPlugin from '@typescript-eslint/eslint-plugin';
import reactPlugin from 'eslint-plugin-react';
import hooksPlugin from 'eslint-plugin-react-hooks';

export default [
  {
    files: ['**/*.ts', '**/*.tsx'],
    languageOptions: {
      parser: '@typescript-eslint/parser',
    },
    plugins: {
      '@typescript-eslint': typescriptPlugin,
      'react': reactPlugin,
      'react-hooks': hooksPlugin,
    },
    rules: {
      '@typescript-eslint/explicit-function-return-types': 'warn',
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/no-unused-vars': 'error',
      'react-hooks/rules-of-hooks': 'error',
      'react-hooks/exhaustive-deps': 'warn',
      'no-console': ['warn', { allow: ['warn', 'error'] }],
      'prefer-const': 'error',
    },
  },
];
```

### ESLint Commands

```bash
# Check code
npm run lint:check

# Fix issues
npm run lint:fix

# Check specific file
npx eslint src/components/Button.tsx
```

## 3. Testing Requirements

### Test Coverage Goals

```markdown
## Coverage Targets

| Metric | Target | Reason |
|--------|--------|--------|
| Statements | 80%+ | Comprehensive logic |
| Branches | 75%+ | Edge cases |
| Functions | 80%+ | All code paths |
| Lines | 80%+ | Overall coverage |

## Critical Areas (100%)
- Server functions (security)
- Route loaders
- Data validation
- Error handling
- Authentication

## Should Test (80%+)
- UI components
- Hooks
- Utilities
- Formatters

## Can Test (70%+)
- CSS/styling
- Animations
- Accessibility
```

### Vitest Configuration

```typescript
// vitest.config.ts
import { defineConfig } from 'vitest/config';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  test: {
    globals: true,
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'json', 'html'],
      statements: 80,
      branches: 75,
      functions: 80,
      lines: 80,
      exclude: [
        'node_modules/',
        'dist/',
        '.output/',
        '**/*.d.ts',
      ],
    },
  },
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
```

### Running Tests

```bash
# Run tests
npm test

# Watch mode
npm test -- --watch

# Coverage
npm test -- --coverage

# Specific file
npm test -- ProductList.test.tsx

# E2E tests
npm run test:e2e
```

## 4. Performance Checks

### Lighthouse Audit

```bash
# Run Lighthouse
npm run build
npm run preview &
npx lighthouse http://localhost:4173 --output-path=./lighthouse-report.html
```

### Lighthouse Targets

```markdown
## Performance Metrics

### Scores (target > 90)
- Performance: 95+
- Accessibility: 95+
- Best Practices: 95+
- SEO: 100

### Core Web Vitals
- LCP (Largest Contentful Paint): < 2.5s
- FID (First Input Delay): < 100ms
- CLS (Cumulative Layout Shift): < 0.1

### Load Times
- FCP (First Contentful Paint): < 1.8s
- TTI (Time to Interactive): < 3.7s
- TBT (Total Blocking Time): < 300ms
```

### Bundle Analysis

```bash
# Analyze bundle
npm run build -- --analyze

# Check size
du -sh dist/

# Check chunks
ls -lh dist/assets/
```

### Performance Examples

```typescript
// ✓ Good: Code splitting
const ProductDetail = lazy(() => import('./ProductDetail'));

// ✗ Bad: All routes in main bundle
import ProductDetail from './ProductDetail';
import Dashboard from './Dashboard';
import Settings from './Settings';

// ✓ Good: Image optimization
<img
  src="product.webp"
  alt="Product"
  loading="lazy"
  width={400}
  height={300}
/>

// ✗ Bad: Unoptimized
<img src="product.jpg" />

// ✓ Good: Prefetch on hover
<Link
  href={`/products/${product.id}`}
  onMouseEnter={() => prefetchProduct(product.id)}
>
  View Product
</Link>
```

## 5. Accessibility Checks

### Accessibility Standards

```markdown
## WCAG 2.1 Level AA

### Perceivable
- [ ] Color contrast >= 4.5:1
- [ ] Alt text on images
- [ ] Captions on videos
- [ ] Not color-only

### Operable
- [ ] Keyboard accessible
- [ ] No keyboard traps
- [ ] Focus visible
- [ ] Logical tab order

### Understandable
- [ ] Clear language
- [ ] Readable text
- [ ] Consistent navigation
- [ ] Error messages helpful

### Robust
- [ ] Valid HTML
- [ ] Semantic markup
- [ ] ARIA used correctly
- [ ] No accessibility conflicts
```

### Accessibility Testing

```bash
# Run accessibility tests
npm run test:a11y

# Manual audit
npx axe-playwright

# Check color contrast
npm install -D contrast-checker
```

### Accessibility Examples

```typescript
// ✓ Good: Semantic HTML + ARIA
<button
  onClick={toggleMenu}
  aria-expanded={isOpen}
  aria-haspopup="menu"
>
  Menu
</button>

// ✗ Bad: Non-semantic
<div onClick={toggleMenu}>Menu</div>

// ✓ Good: Alt text
<img src="product.jpg" alt="Red winter jacket, size M" />

// ✗ Bad: Missing alt
<img src="product.jpg" />

// ✓ Good: Associated labels
<label htmlFor="email">Email</label>
<input id="email" type="email" />

// ✗ Bad: Unassociated
<label>Email</label>
<input type="email" />

// ✓ Good: ARIA for complex UI
<div role="menu" aria-label="Navigation">
  <button role="menuitem">Products</button>
</div>
```

## 6. Security Checks

### Dependency Audit

```bash
# Check vulnerabilities
npm audit

# Fix automatically
npm audit fix

# Fix with review
npm audit fix --dry-run
npm audit fix

# Detailed report
npm audit --json > audit.json
```

### Security Best Practices

```typescript
// ✓ Good: Parameterized queries
const user = await db.user.findUnique({
  where: { email },
});

// ✗ Bad: String concatenation
const query = `SELECT * FROM users WHERE email = '${email}'`;

// ✓ Good: Environment variables
const apiKey = process.env.API_KEY;

// ✗ Bad: Hardcoded secrets
const apiKey = 'sk_live_123456789';

// ✓ Good: Input validation
const schema = z.object({
  email: z.string().email(),
});
const data = schema.parse(input);

// ✗ Bad: No validation
const email = req.body.email;

// ✓ Good: Sanitized output
import DOMPurify from 'isomorphic-dompurify';
const safe = DOMPurify.sanitize(userInput);

// ✗ Bad: Unsafe HTML
<div dangerouslySetInnerHTML={{ __html: userInput }} />
```

## 7. Code Quality

### Code Review Checklist

```markdown
## Before Merging PR

### Code
- [ ] No console.log statements
- [ ] No hardcoded values
- [ ] DRY principle followed
- [ ] Single responsibility
- [ ] Error handling complete

### Types
- [ ] TypeScript strict mode
- [ ] No implicit any
- [ ] All functions typed
- [ ] Return types specified

### Tests
- [ ] New code has tests
- [ ] Coverage >= 80%
- [ ] All tests passing
- [ ] No flaky tests

### Performance
- [ ] Bundle size checked
- [ ] No N+1 queries
- [ ] Caching strategy
- [ ] Images optimized

### Security
- [ ] No exposed secrets
- [ ] Input validated
- [ ] CSRF protected
- [ ] XSS prevented

### Accessibility
- [ ] Semantic HTML
- [ ] ARIA labels
- [ ] Keyboard navigation
- [ ] Color contrast
- [ ] Alt text on images

### Documentation
- [ ] Complex logic commented
- [ ] README updated
- [ ] API documented
- [ ] Types documented
```

## 8. Pre-commit Hooks

### Setup Husky

```bash
# Install husky
npx husky-init && npm install

# Add pre-commit check
npx husky add .husky/pre-commit "npm run quality:check"

# Add pre-push check
npx husky add .husky/pre-push "npm run test && npm run build"
```

### package.json Scripts

```json
{
  "scripts": {
    "quality:check": "npm run type-check && npm run lint:check",
    "type-check": "tsc --noEmit",
    "lint:check": "eslint src",
    "lint:fix": "eslint src --fix",
    "test": "vitest run",
    "test:watch": "vitest",
    "test:coverage": "vitest run --coverage",
    "test:e2e": "playwright test",
    "build": "vite build",
    "preview": "vite preview"
  }
}
```

## 9. CI/CD Pipeline

### GitHub Actions

```yaml
# .github/workflows/quality.yml
name: Quality Checks

on: [push, pull_request]

jobs:
  quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3

      - name: Setup Node
        uses: actions/setup-node@v3
        with:
          node-version: '18'
          cache: 'npm'

      - name: Install
        run: npm ci

      - name: Type Check
        run: npm run type-check

      - name: Lint
        run: npm run lint:check

      - name: Test
        run: npm run test:coverage

      - name: Upload Coverage
        uses: codecov/codecov-action@v3

      - name: Build
        run: npm run build

      - name: E2E Tests
        run: npm run test:e2e

      - name: Security Audit
        run: npm audit --audit-level=moderate
```

## 10. Quality Dashboard

### Generate Report

```markdown
# Quality Report - Week of 2024-01-22

## Summary
✓ All quality gates passing
✓ No blockers

## Metrics

### Type Safety
- TypeScript: ✓ 0 errors
- Strict mode: ✓ Enabled

### Tests
- Coverage: 84% (target: 80%)
- Passing: 256/256 ✓
- E2E: All passing ✓

### Performance
- Lighthouse Score: 94
- Bundle Size: 245KB (target: 300KB)
- LCP: 2.1s (target: 2.5s)

### Code Quality
- ESLint: 0 errors ✓
- Complexity: Average 6.2 ✓

### Security
- Vulnerabilities: 0 ✓
- Audit: Passed ✓

### Accessibility
- Score: 98 ✓
- WCAG 2.1: Level AA ✓

## Issues
None

## Next Steps
- Continue monitoring metrics
- Performance optimization sprint
```

## Resources

- [TypeScript Strict Mode](https://www.typescriptlang.org/tsconfig#strict)
- [ESLint Rules](https://eslint.org/docs/rules/)
- [Vitest Documentation](https://vitest.dev)
- [Lighthouse](https://developers.google.com/web/tools/lighthouse)
- [WCAG Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [OWASP Security](https://owasp.org)
