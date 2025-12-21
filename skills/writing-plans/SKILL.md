---
name: tanstack:writing-plans
description: Implementation planning for TanStack Start - task decomposition, routing architecture, and execution roadmaps
---

# Writing Plans Skill for TanStack Start

This skill helps create detailed implementation plans for TanStack Start features, with emphasis on routing, server functions, and data flow.

## Implementation Plan Template

### 1. Feature Overview

```markdown
## Feature: [Feature Name]
**Status**: PLANNED / IN_PROGRESS / REVIEW / COMPLETED

### Summary
Brief description of what you're building.

### User Story
As a [user type], I want to [action], so that [benefit].

### Objectives
- Primary goal
- Secondary goals
- Non-goals

### Success Criteria
- User metrics
- Performance targets
- Quality metrics

### Timeline
- **Start**: YYYY-MM-DD
- **Target**: YYYY-MM-DD
- **Buffer**: 20%

### Team
- **Lead**: [Name]
- **Developers**: [Names]
- **Designer**: [Name]
```

### 2. Technical Requirements

```markdown
## Technical Specification

### API Requirements
```typescript
// Endpoints needed
GET /api/products - List products
GET /api/products/:id - Get product
POST /api/products - Create product
PUT /api/products/:id - Update product
DELETE /api/products/:id - Delete product

// Server functions needed
getProduct(id: string): Promise<Product>
listProducts(filters): Promise<Product[]>
createProduct(data): Promise<Product>
```

### Database Schema
```typescript
// Tables/collections
Products table:
- id: UUID
- name: string
- description: text
- price: decimal
- category: string
- createdAt: timestamp
- updatedAt: timestamp
```

### Routing Structure
```
src/routes/
├── products/
│   ├── __layout.tsx        # Products layout
│   ├── index.tsx           # /products (list)
│   └── $productId/
│       ├── __layout.tsx    # Product detail layout
│       ├── index.tsx       # /products/:id (view)
│       └── edit.tsx        # /products/:id/edit
```

### Data Flow
```
User opens /products/:id
    ↓
Route loader fetches product
    ↓
Server renders page with data
    ↓
TanStack Query takes over
    ↓
User clicks "Edit"
    ↓
Modal opens with form
    ↓
User submits (server function)
    ↓
Cache invalidates
    ↓
Page updates
```
```

### 3. Task Breakdown

```markdown
## Phase 1: Foundation (Week 1)

### Task 1.1: Database Setup
- **Owner**: Backend Lead
- **Effort**: 6 hours
- **Dependencies**: None
- **Description**: Create database schema, migrations
- **Acceptance Criteria**:
  - [ ] Schema created
  - [ ] Migrations run
  - [ ] Test data seeded
- **Subtasks**:
  - [ ] Design schema
  - [ ] Create migrations
  - [ ] Seed test data

### Task 1.2: Server Functions
- **Owner**: Backend
- **Effort**: 8 hours
- **Dependencies**: Task 1.1
- **Description**: Implement API server functions
- **Acceptance Criteria**:
  - [ ] CRUD operations work
  - [ ] Validation in place
  - [ ] Error handling complete
  - [ ] Types generated
- **Subtasks**:
  - [ ] Create getProduct function
  - [ ] Create listProducts function
  - [ ] Create createProduct function
  - [ ] Add validation with Zod

## Phase 2: Frontend (Week 1-2)

### Task 2.1: Routing Setup
- **Owner**: Frontend Lead
- **Effort**: 4 hours
- **Dependencies**: Task 1.2
- **Description**: Create route files and loaders
- **Acceptance Criteria**:
  - [ ] Routes created
  - [ ] Loaders fetch data
  - [ ] Navigation works
- **Subtasks**:
  - [ ] Create __layout.tsx
  - [ ] Create index.tsx for list
  - [ ] Create detail route
  - [ ] Setup route loaders

### Task 2.2: List Page UI
- **Owner**: Frontend
- **Effort**: 8 hours
- **Dependencies**: Task 2.1
- **Description**: Build product list page
- **Acceptance Criteria**:
  - [ ] Products display
  - [ ] Pagination works
  - [ ] Filters work
  - [ ] Mobile responsive
- **Subtasks**:
  - [ ] Create ProductList component
  - [ ] Add filters
  - [ ] Add pagination
  - [ ] Add search

### Task 2.3: Detail Page UI
- **Owner**: Frontend
- **Effort**: 8 hours
- **Dependencies**: Task 2.1
- **Description**: Build product detail page
- **Acceptance Criteria**:
  - [ ] Product details show
  - [ ] Related products show
  - [ ] Actions work (edit, delete)
- **Subtasks**:
  - [ ] Create ProductDetail component
  - [ ] Add related products
  - [ ] Add action buttons
  - [ ] Add reviews section

### Task 2.4: Forms & Mutations
- **Owner**: Frontend
- **Effort**: 10 hours
- **Dependencies**: Task 1.2, Task 2.3
- **Description**: Implement form and mutations
- **Acceptance Criteria**:
  - [ ] Form displays
  - [ ] Validation works
  - [ ] Submission works
  - [ ] Errors handle
  - [ ] Cache updates
- **Subtasks**:
  - [ ] Create ProductForm
  - [ ] Add TanStack Form setup
  - [ ] Add validation with Zod
  - [ ] Wire server mutations

## Phase 3: Integration & Polish (Week 2)

### Task 3.1: Data Fetching
- **Owner**: Frontend
- **Effort**: 6 hours
- **Dependencies**: Phase 2 complete
- **Description**: Setup TanStack Query
- **Acceptance Criteria**:
  - [ ] Data fetches correctly
  - [ ] Cache works
  - [ ] Refetch works
  - [ ] Loading states show
- **Subtasks**:
  - [ ] Configure TanStack Query
  - [ ] Create query hooks
  - [ ] Add loading skeletons
  - [ ] Add error boundaries

### Task 3.2: Testing
- **Owner**: QA / Frontend
- **Effort**: 12 hours
- **Dependencies**: Phase 2 complete
- **Description**: Test feature end-to-end
- **Acceptance Criteria**:
  - [ ] Happy path works
  - [ ] Edge cases handled
  - [ ] No console errors
  - [ ] Performance good
- **Subtasks**:
  - [ ] Manual testing
  - [ ] Automated tests (E2E)
  - [ ] Performance audit
  - [ ] Accessibility check

### Task 3.3: Documentation
- **Owner**: Tech Lead
- **Effort**: 4 hours
- **Dependencies**: Phase 2 complete
- **Description**: Document feature
- **Acceptance Criteria**:
  - [ ] README updated
  - [ ] Routes documented
  - [ ] Server functions documented
  - [ ] Setup instructions clear
- **Subtasks**:
  - [ ] Write README section
  - [ ] Document API
  - [ ] Create code examples
  - [ ] Document assumptions
```

### 4. Routing Plan

```markdown
## Route Architecture

### Route Hierarchy
```
root (__root.tsx)
├── products
│   ├── __layout.tsx (Products layout)
│   ├── index.tsx (List: /products)
│   └── $productId (Dynamic segment)
│       ├── __layout.tsx
│       ├── index.tsx (Detail: /products/:id)
│       └── edit.tsx (Edit: /products/:id/edit)
├── dashboard
│   ├── index.tsx
│   └── analytics (Advanced routing)
└── (auth)
    ├── login.tsx
    └── register.tsx
```

### Route Implementation Plan

#### Route 1: Product List
```typescript
// src/routes/products/index.tsx
export const Route = createRoute({
  getParentRoute: () => productsLayout,
  path: '/',
  component: ProductsPage,
  loader: async ({ context }) => {
    // Load initial products
    return await context.queryClient.fetchQuery({
      queryKey: ['products', { page: 1 }],
      queryFn: () => getProducts({ page: 1 }),
    });
  },
});
```

#### Route 2: Product Detail
```typescript
// src/routes/products/$productId/index.tsx
export const Route = createRoute({
  getParentRoute: () => productDetailLayout,
  path: '/',
  component: ProductDetailPage,
  loader: async ({ params, context }) => {
    return await context.queryClient.fetchQuery({
      queryKey: ['product', params.productId],
      queryFn: () => getProduct(params.productId),
    });
  },
});
```
```

### 5. Server Functions Plan

```markdown
## Server Function Implementation

### Functions to Create

#### getProduct(id: string)
- Location: src/server/products.ts
- Input: product ID
- Output: Product with details
- Caching: 5 minutes
- Error handling: 404 if not found

#### listProducts(filters: Filters)
- Location: src/server/products.ts
- Input: page, limit, category, search
- Output: { items: Product[], total: number }
- Pagination: 20 items per page
- Validation: Validate filters with Zod

#### createProduct(data: CreateProductInput)
- Location: src/server/products.ts
- Auth: Requires admin role
- Input: name, description, price, category
- Output: Created Product
- Validation: Server-side with Zod
- Error handling: Return validation errors

#### updateProduct(id: string, data: UpdateProductInput)
- Location: src/server/products.ts
- Auth: Requires admin role
- Input: Partial product data
- Output: Updated Product
- Cache invalidation: Invalidate product + list

#### deleteProduct(id: string)
- Location: src/server/products.ts
- Auth: Requires admin role
- Input: Product ID
- Output: { success: boolean }
- Cascade: Handle related data
```

### 6. Data Flow Diagram

```markdown
## Complete Data Flow

### View Product Flow
```
User clicks /products/123
    ↓
Route loader executes
    ↓
Server function: getProduct(123)
    ↓
Database query
    ↓
TanStack Query caches result
    ↓
Server renders page with data
    ↓
Hydrate on client
    ↓
Interactive form ready
    ↓
User clicks Edit
    ↓
Modal opens
    ↓
Form initialized from cache
    ↓
User submits
    ↓
Server function: updateProduct()
    ↓
Mutation succeeds
    ↓
TanStack Query invalidates
    ↓
Auto-refetch product
    ↓
UI updates
```

### Cache Invalidation Strategy
- After create: Invalidate list
- After update: Invalidate product + list
- After delete: Invalidate list
- Manual refetch on: Route change, user action
```

### 7. Risk Assessment

```markdown
## Risks & Mitigations

### Risk 1: N+1 Query Problem
- **Impact**: Performance degradation
- **Likelihood**: Medium
- **Mitigation**:
  - [ ] Use database joins
  - [ ] Load testing
  - [ ] Query monitoring
- **Owner**: Backend Lead

### Risk 2: Stale Cache Issues
- **Impact**: Data inconsistency
- **Likelihood**: Medium
- **Mitigation**:
  - [ ] Proper invalidation
  - [ ] Sync logic
  - [ ] Conflict resolution
- **Owner**: Frontend Lead

### Risk 3: Large Dataset Performance
- **Impact**: Slow page loads
- **Likelihood**: Low
- **Mitigation**:
  - [ ] Implement pagination
  - [ ] Virtual scrolling
  - [ ] Lazy loading
- **Owner**: Frontend Lead

### Risk 4: Concurrent Updates
- **Impact**: Data loss
- **Likelihood**: Low
- **Mitigation**:
  - [ ] Optimistic updates
  - [ ] Conflict detection
  - [ ] User notification
- **Owner**: Backend Lead
```

### 8. Success Metrics

```markdown
## Definition of Done

### Feature Complete
- [ ] All routes created
- [ ] All server functions work
- [ ] All mutations implemented
- [ ] Forms functional
- [ ] Validation working

### Performance
- [ ] LCP < 2.5s
- [ ] TTI < 3.7s
- [ ] Bundle size acceptable
- [ ] No N+1 queries

### Code Quality
- [ ] TypeScript: No errors
- [ ] ESLint: 0 errors
- [ ] Test coverage: > 80%
- [ ] Code reviewed

### User Experience
- [ ] Mobile responsive
- [ ] Loading states
- [ ] Error messages clear
- [ ] Accessibility: WCAG AA
- [ ] No console errors

### Documentation
- [ ] README updated
- [ ] Routes documented
- [ ] Server functions documented
- [ ] Assumptions listed
```

## Task Management

### Estimation

```typescript
// Story Points (Fibonacci)
1 = < 2 hours
2 = 2-4 hours
3 = 4-8 hours
5 = 1-2 days
8 = 2-3 days
13 = 3-5 days

Total effort: Sum all task points
Team velocity: Points per week (typically 15-20)
Estimated weeks: Total effort / velocity
```

### Status Tracking

```markdown
## Weekly Progress

### Completed (Week 1)
- [x] Database schema
- [x] Server functions
- [x] Route structure
- [x] TanStack Query setup

### In Progress (Week 2)
- [ ] List page UI (80%)
- [ ] Detail page UI (40%)
- [ ] Forms (30%)
- [ ] Testing (20%)

### Blocked
- Form integration awaiting design approval (due Fri)

### Next Week
- Complete UI implementation
- Begin testing
- Performance optimization
- Documentation
```

## Tools & Templates

### Dependency Diagram Template

```
Phase 1
├── Task 1.1 (DB) ──→ Task 1.2 (Server) ──→ Task 2.1 (Routes)
│                                              ↓
├────────────────────────────────────→ Task 2.2 (List UI)
│                                      ↓
├────────────────────────────────────→ Task 2.3 (Detail UI)
│                                      ↓
└────────────────────────────────────→ Task 2.4 (Forms)
                                           ↓
                                    Phase 2: Testing
```

## Resources

- [TanStack Start Docs](https://tanstack.com/start/latest)
- [Project Planning Guide](https://www.atlassian.com/agile/project-management)
- [Estimation Techniques](https://www.mountaingoatsoftware.com/agile/scrum)
