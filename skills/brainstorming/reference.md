# Reference

# Brainstorming Skill for TanStack Start

This skill guides structured ideation and feature discovery for TanStack Start applications, helping you design solutions before implementation.

## Overview

Brainstorming Process:

- **Problem Analysis**: Understand core requirements and constraints
- **Solution Exploration**: Generate multiple architectural approaches
- **Technology Evaluation**: Select appropriate TanStack libraries
- **Data Flow Design**: Plan routing and state patterns
- **Architecture Planning**: Component organization and server/client split
- **Risk Assessment**: Identify challenges and mitigations

## Problem Definition Phase

### Problem Statement Framework

```markdown
## Problem Definition

### What are we solving?
- User pain point
- Business requirement
- Technical challenge

### Project Context
- Single Page App (SPA)
- Server-rendered
- Hybrid (SPA + SSR)

### Constraints
- Browser compatibility requirements
- Performance targets
- User device capabilities
- Team expertise

### Success Criteria
- User metrics (engagement, conversion)
- Performance targets (load time, responsiveness)
- Code maintainability goals
- Scalability requirements

### User Journey
- Key user flows
- Critical interactions
- Error scenarios
- Edge cases
```

### Example: E-commerce Platform

```markdown
## Problem: Build Modern E-commerce Platform

### Context
Existing platform struggles with:
- Slow product page loads
- Poor mobile experience
- State management complexity
- Server-side rendering not implemented

### Constraints
- Support modern browsers only (last 2 years)
- Performance: LCP < 2s, TTI < 3s
- Mobile-first design
- Existing backend API (GraphQL + REST)
- 3-month delivery timeline

### Success Metrics
- 30% improvement in mobile conversion
- 50% reduction in page load time
- 95+ Lighthouse score
- Developer satisfaction > 4.0/5.0
```

## Solution Exploration Phase

### Architecture Pattern Selection

```markdown
## Architecture Decision: SPA vs SSR vs Hybrid

### Option 1: Traditional SPA
- React + TanStack Router + TanStack Query
- Client-side rendering only
- Pros: Simple, offline-capable, dynamic
- Cons: Poor initial load, SEO challenges, larger JS bundle

### Option 2: Server-Side Rendering
- TanStack Start with server functions
- Server renders initial HTML
- Pros: Fast initial load, great SEO, smaller JS
- Cons: Server overhead, harder to scale, stateful

### Option 3: Hybrid (Recommended)
- TanStack Start for SSR where needed
- Selective client-side rendering for interactive sections
- Server functions for data fetching and mutations
- Pros: Best of both worlds, optimized performance
- Cons: More complex, larger codebase

### Decision
Use Hybrid approach with TanStack Start
- Initial page load: Server-rendered
- Interactive features: Client-side
- Data fetching: Server functions + TanStack Query
```

### Data Flow Architecture

```markdown
## Data Flow Patterns

### Pattern A: Full Client-Side State
```
User Interaction
     ↓
TanStack Query (client)
     ↓
API call
     ↓
Cache update
     ↓
Component re-render
```

Best for: Interactive features, frequent updates

### Pattern B: Server Functions
```
User Interaction
     ↓
Server Function
     ↓
Database/API
     ↓
Response + optimistic update
     ↓
TanStack Query invalidation
     ↓
Component re-render
```

Best for: Data mutations, sensitive operations

### Pattern C: Streaming (Real-time)
```
Initial load (Server-rendered)
     ↓
Suspense boundaries
     ↓
Stream data chunks from server
     ↓
Progressive enhancement
     ↓
Client takes over
```

Best for: Large datasets, progressive loading

### Decision
Use Pattern B (Server Functions) for mutations
Combine with Pattern A for queries
```

## Technology Selection

### Routing Strategy

```markdown
## File-based vs Manual Routing

### TanStack Router (File-based)
✓ Automatic route generation
✓ Type-safe route parameters
✓ Built-in preloading
✓ Loaders per route
✗ Less flexible for complex URL structures

### Manual Route Configuration
✓ Maximum flexibility
✓ Dynamic route generation
✓ Complex URL patterns
✗ More boilerplate
✗ Runtime errors possible

### Decision
Use TanStack Router with file-based routing
File-based provides safety and DX
```

### State Management

```markdown
## Where to Store State?

### Server State (via TanStack Query)
- User data
- List data
- Cached API responses
- Remote mutations

### URL State (TanStack Router)
- Current page
- Filters/search
- Pagination
- User selections for navigation

### Client State (Context/Zustand)
- UI state (modals, menus)
- Temporary form data
- Animation state
- User preferences

### Decision Matrix
| State Type | Storage | Library | Reason |
|-----------|---------|---------|--------|
| Product list | Server | TanStack Query | Cache management |
| Search filters | URL | TanStack Router | Bookmarkable, shareable |
| Modal open/close | Client | Context | Local UI state |
| User cart | Server + URL | Query + Router | Persist + share |
```

### Form Architecture

```markdown
## Form Handling Strategy

### Simple Forms (< 5 fields)
- Use TanStack Form + Zod
- Client-side validation
- Direct server function calls

### Complex Forms (> 10 fields, multi-step)
- TanStack Form for structure
- Draft persistence (localStorage)
- Progressive validation
- Server-side validation on submit

### Real-time Forms (auto-save)
- TanStack Form for state
- Debounced server mutations
- Optimistic updates
- Conflict resolution

### Decision
Use TanStack Form consistently
Auto-save for longer forms
Server validation for sensitive data
```

## Architecture Design Phase

### Route Structure Planning

```markdown
## File-based Route Organization

### Structure
```
src/routes/
├── __root.tsx                 # Root layout
├── index.tsx                  # Home (/)
├── products/
│   ├── __layout.tsx          # Layout for /products
│   ├── index.tsx             # /products list
│   └── $productId.tsx        # /products/:id detail
├── dashboard/
│   ├── __layout.tsx
│   ├── index.tsx
│   ├── analytics/
│   │   └── index.tsx
│   └── settings/
│       └── index.tsx
├── (auth)/
│   ├── login.tsx             # /login
│   └── register.tsx          # /register
└── api/                       # Server functions
    ├── products.server.ts
    └── users.server.ts
```

### Route Loaders

```typescript
// Before rendering route, load data
export const Route = createRoute({
  getParentRoute: () => rootRoute,
  path: '/products/$productId',
  component: ProductDetail,
  loader: async ({ params }) => {
    // Load product data before render
    return await getProduct(params.productId);
  },
});
```
```

### Component Organization

```markdown
## Component Structure

### Page Components
- src/routes/products/index.tsx
- Represent full page views
- Include layout composition
- Handle high-level logic

### Layout Components
- src/components/layouts/
- Shared page templates
- Header, sidebar, footer
- Navigation management

### Feature Components
- src/components/products/
- ProductCard, ProductFilter
- ProductRating, ProductReviews
- Reusable feature pieces

### Shared Components
- src/components/ui/
- Button, Input, Modal
- Form elements
- Common patterns

### Server Components
- src/components/server/
- Server-only functions
- Database queries
- Sensitive operations

### Hooks
- src/hooks/
- Custom React hooks
- useProductData, useCart
- useAuth, useNotifications

### Utilities
- src/lib/
- Helper functions
- API clients
- Formatters, validators
```

## Performance Planning

### Performance Patterns

```markdown
## Optimization Strategy

### Code Splitting
- Route-based splitting (automatic with TanStack Router)
- Component-level code splitting
- Lazy load third-party libraries

### Image Strategy
- Optimize with WebP, AVIF formats
- Lazy load images below fold
- Responsive images for different devices
- Use CDN with caching

### Data Loading
- Prefetch next routes on hover
- Stream critical data first
- Progressive enhancement
- Prioritize above-fold data

### Bundle Optimization
- Tree-shake unused code
- Minimize third-party dependencies
- Use dynamic imports for optional features
- Monitor bundle size regularly

### Metrics Targets
- LCP (Largest Contentful Paint): < 2.5s
- FID (First Input Delay): < 100ms
- CLS (Cumulative Layout Shift): < 0.1
- TTI (Time to Interactive): < 3.7s
```

## Error Handling & Edge Cases

### Error Scenarios

```markdown
## Error Handling Strategy

### Network Errors
- [ ] Retry logic with exponential backoff
- [ ] Fallback UI
- [ ] Offline detection
- [ ] Request deduplication

### Data Validation
- [ ] Client-side validation (UX)
- [ ] Server-side validation (security)
- [ ] Type safety (TypeScript)
- [ ] Schema validation (Zod)

### State Management Errors
- [ ] Invalid state transitions
- [ ] Missing data handling
- [ ] Race condition prevention
- [ ] Cache invalidation bugs

### Routing Errors
- [ ] 404 handling
- [ ] Unauthorized redirects
- [ ] Invalid parameters
- [ ] Missing loaders

### Edge Cases
- [ ] Empty states
- [ ] Loading states
- [ ] Null/undefined handling
- [ ] Duplicate submissions
- [ ] Concurrent mutations
```

## Brainstorming Templates

### Feature Brainstorming Template

```markdown
## Feature: [Feature Name]

### User Story
As a [user type], I want to [action], so that [benefit].

### Functional Requirements
- [ ] Requirement 1
- [ ] Requirement 2
- [ ] Requirement 3

### Technical Implementation
**TanStack Technologies**:
- [ ] TanStack Router - routing and navigation
- [ ] TanStack Query - data fetching
- [ ] TanStack Form - form handling
- [ ] TanStack Store - state management

**Architecture**:
- Data source: Server function, external API, or cache?
- Rendering: SSR, CSR, or hybrid?
- State location: Server, URL, or client?
- Validation: Client-side, server-side, or both?

### Performance Considerations
- Load time budget
- Interaction responsiveness
- Bundle size impact
- Cache strategy

### Success Metrics
- User engagement metrics
- Performance metrics
- Error rates
- User feedback

### Risks & Mitigations
| Risk | Impact | Mitigation |
|------|--------|-----------|
| Performance degradation | High | Code splitting, caching |
| Data inconsistency | High | Server functions, validation |
| User confusion | Medium | Clear UI, help text |
```

## Decision Making

### Decision Record Template

```markdown
## ADR: [Decision Title]

### Status
PROPOSED / ACCEPTED / DEPRECATED

### Context
What forces us to this decision?
- Technical constraints
- Business requirements
- User needs
- Team capabilities

### Alternatives Considered
1. Option A - Pros and cons
2. Option B - Pros and cons
3. Option C - Pros and cons (chosen)

### Decision
We choose Option C because:
- Better performance
- Aligns with team expertise
- Simpler maintenance

### Consequences
**Positive**:
- Outcome 1
- Outcome 2

**Risks**:
- Risk 1 - mitigation
- Risk 2 - mitigation

### Related Decisions
- ADR-001: Routing strategy
- ADR-003: State management
```

## Team Collaboration

### Brainstorming Session Plan

1. **Problem Setup (10 min)**
   - Explain requirement
   - Define constraints
   - Discuss success criteria

2. **Individual Ideation (15 min)**
   - Everyone proposes solutions silently
   - Write on shared board
   - No criticism yet

3. **Discussion (20 min)**
   - Present each idea
   - Ask clarifying questions
   - Build on ideas

4. **Clustering (10 min)**
   - Group similar ideas
   - Identify themes
   - Eliminate duplicates

5. **Evaluation (15 min)**
   - Assess feasibility
   - Discuss trade-offs
   - Pick direction

6. **Decision (10 min)**
   - Document decision
   - Assign next steps
   - Communicate to team

## Common Brainstorming Topics

### State Management

```markdown
## TanStack Query vs Local State

### Use TanStack Query for:
- Product lists
- User profiles
- API responses
- Cached data
- Mutations

### Use React State for:
- UI toggles (modals, menus)
- Form inputs (before submission)
- Animations
- Temporary selections

### Use TanStack Router URL for:
- Page parameters
- Filters/search
- Pagination
- User selections
```

### Authentication Flow

```markdown
## Authentication Architecture

### Approach 1: Stateless (JWT)
- Token in localStorage
- Verify on each request
- Pros: Scalable, stateless
- Cons: Token hijacking risk

### Approach 2: Server Sessions
- Session stored server-side
- Cookie-based
- Pros: Secure, traditional
- Cons: Requires sessions

### Approach 3: Hybrid
- Server functions for auth
- Token for client requests
- Session validation on server
- Pros: Best security + scalability

### Decision
Use server functions for auth operations
Server validates all sensitive operations
Client stores auth state in TanStack Query
```

## Documentation

### Architecture Decision Log

```markdown
# Architecture Decisions

## ADR-001: Use TanStack Router for routing
- Date: 2024-01-15
- Status: ACCEPTED
- Rationale: Type-safe, file-based, built-in loaders
- Trade-offs: Less flexible than manual routing

## ADR-002: TanStack Query for server state
- Date: 2024-01-15
- Status: ACCEPTED
- Rationale: Automatic caching, deduplication, background sync
- Trade-offs: Learning curve for new team members

## ADR-003: Server functions for mutations
- Date: 2024-01-20
- Status: ACCEPTED
- Rationale: Security, direct DB access, automatic validation
- Trade-offs: Requires server infrastructure

## ADR-004: Zod for validation
- Date: 2024-01-20
- Status: ACCEPTED
- Rationale: Type-safe schemas, runtime validation
- Trade-offs: Slight runtime overhead
```

## Resources

- [TanStack Start Documentation](https://tanstack.com/start/latest)
- [TanStack Router Guide](https://tanstack.com/router/latest)
- [System Design Patterns](https://www.patterns.dev)
- [Full-Stack Best Practices](https://fullstackopen.com)
