---
name: tanstack:route-search-params
description: Manage search parameters with type-safe validation and serialization
---

# Route Search Parameters with TanStack Router

## Concept

Les paramètres de recherche (query string) permettent de passer des données optionnelles dans l'URL. TanStack Router fournit une validation et une sérialisation type-safe avec support complet pour les types complexes, les enums, et les tableaux.

## Différences: Params vs Search

| Aspect | Route Params | Search Params |
|--------|-------------|--------------|
| Syntaxe | `/products/123` | `/products?tab=specs&sort=price` |
| Obligatoire | Oui, défini dans le chemin | Non, optionnel |
| Type | String (URL segment) | String (query string) |
| Usage | Identifier une ressource | Filtrer/trier/paginer |
| Exemple | ID utilisateur | Filtre, tri, page |

## Architecture de Validation

```
URL: /search?q=laptop&category=tech&page=2
                ↓
Query String Parser
                ↓
validateSearch() → { q: string, category?: string, page: number }
                ↓
Type-Safe Typed Object
                ↓
useSearch() → Accès typé et sûr
```

## Implémentation Complète

### 1. Paramètres de Recherche Simples

**`src/routes/products.tsx`**

```typescript
import { createFileRoute, useSearch, Link } from '@tanstack/react-router'

type ProductSearchParams = {
  search?: string
  category?: string
  minPrice?: number
  maxPrice?: number
  inStock?: boolean
  page?: number
  limit?: number
};

export const Route = createFileRoute('/products')({
  // ✅ Valider et transformer les search params
  validateSearch: (search: Record<string, unknown>): ProductSearchParams => {
    return {
      // Convertir les strings en types appropriés
      search: (search.search as string) || undefined,
      category: (search.category as string) || undefined,
      minPrice: search.minPrice
        ? parseInt(search.minPrice as string)
        : undefined,
      maxPrice: search.maxPrice
        ? parseInt(search.maxPrice as string)
        : undefined,
      inStock: search.inStock === 'true' ? true : undefined,
      page: search.page ? parseInt(search.page as string) : 1,
      limit: search.limit ? parseInt(search.limit as string) : 20,
    }
  },

  component: ProductsPage,
})

function ProductsPage() {
  // ✅ Accès typé aux paramètres de recherche
  const searchParams = useSearch({ from: '/products' })

  return (
    <div className="space-y-6">
      <h1 className="text-3xl font-bold">Produits</h1>

      <div className="grid grid-cols-4 gap-6">
        {/* Sidebar Filtres */}
        <aside className="space-y-6">
          <FilterSection title="Catégorie">
            <CategoryFilter currentCategory={searchParams.category} />
          </FilterSection>

          <FilterSection title="Prix">
            <PriceFilter
              minPrice={searchParams.minPrice}
              maxPrice={searchParams.maxPrice}
            />
          </FilterSection>

          <FilterSection title="Disponibilité">
            <StockFilter inStock={searchParams.inStock} />
          </FilterSection>
        </aside>

        {/* Contenu Principal */}
        <main className="col-span-3 space-y-6">
          {/* Barre de Recherche */}
          <SearchBar currentSearch={searchParams.search} />

          {/* Résultats */}
          <div className="grid grid-cols-3 gap-4">
            {/* Les produits seraient chargés ici */}
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <ProductCard key={i} id={i.toString()} />
            ))}
          </div>

          {/* Pagination */}
          <Pagination
            currentPage={searchParams.page}
            totalPages={5}
            searchParams={searchParams}
          />
        </main>
      </div>
    </div>
  )
}

function CategoryFilter({ currentCategory }: { currentCategory?: string }) {
  const categories = ['Electronics', 'Clothing', 'Books', 'Home']
  const navigate = useNavigate()
  const searchParams = useSearch({ from: '/products' })

  return (
    <div className="space-y-2">
      {categories.map((category) => (
        <label key={category} className="flex items-center gap-2">
          <input
            type="checkbox"
            checked={currentCategory === category}
            onChange={(e) => {
              navigate({
                to: '/products',
                search: {
                  ...searchParams,
                  category: e.target.checked ? category : undefined,
                  page: 1, // Réinitialiser la pagination
                },
              })
            }}
          />
          {category}
        </label>
      ))}
    </div>
  )
}

function PriceFilter({
  minPrice,
  maxPrice,
}: {
  minPrice?: number
  maxPrice?: number
}) {
  const navigate = useNavigate()
  const searchParams = useSearch({ from: '/products' })

  return (
    <div className="space-y-3">
      <div>
        <label className="block text-sm font-medium mb-1">Prix Min</label>
        <input
          type="number"
          value={minPrice || ''}
          onChange={(e) => {
            navigate({
              to: '/products',
              search: {
                ...searchParams,
                minPrice: e.target.value ? parseInt(e.target.value) : undefined,
                page: 1,
              },
            })
          }}
          placeholder="0"
          className="w-full px-2 py-1 border rounded"
        />
      </div>
      <div>
        <label className="block text-sm font-medium mb-1">Prix Max</label>
        <input
          type="number"
          value={maxPrice || ''}
          onChange={(e) => {
            navigate({
              to: '/products',
              search: {
                ...searchParams,
                maxPrice: e.target.value ? parseInt(e.target.value) : undefined,
                page: 1,
              },
            })
          }}
          placeholder="9999"
          className="w-full px-2 py-1 border rounded"
        />
      </div>
    </div>
  )
}

function StockFilter({ inStock }: { inStock?: boolean }) {
  const navigate = useNavigate()
  const searchParams = useSearch({ from: '/products' })

  return (
    <label className="flex items-center gap-2">
      <input
        type="checkbox"
        checked={inStock || false}
        onChange={(e) => {
          navigate({
            to: '/products',
            search: {
              ...searchParams,
              inStock: e.target.checked ? true : undefined,
              page: 1,
            },
          })
        }}
      />
      <span>En stock uniquement</span>
    </label>
  )
}

function SearchBar({ currentSearch }: { currentSearch?: string }) {
  const [value, setValue] = useState(currentSearch || '')
  const navigate = useNavigate()
  const searchParams = useSearch({ from: '/products' })

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    navigate({
      to: '/products',
      search: {
        ...searchParams,
        search: value || undefined,
        page: 1,
      },
    })
  }

  return (
    <form onSubmit={handleSubmit} className="flex gap-2">
      <input
        type="text"
        value={value}
        onChange={(e) => setValue(e.target.value)}
        placeholder="Rechercher des produits..."
        className="flex-1 px-4 py-2 border rounded"
      />
      <button
        type="submit"
        className="bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700"
      >
        Rechercher
      </button>
    </form>
  )
}

function ProductCard({ id }: { id: string }) {
  return (
    <Link
      to="/products/$id"
      params={{ id }}
      className="border rounded overflow-hidden hover:shadow-lg transition"
    >
      <div className="bg-gray-200 h-48 flex items-center justify-center">
        <span className="text-gray-400">Image</span>
      </div>
      <div className="p-3">
        <h3 className="font-bold text-blue-600">Produit {id}</h3>
        <p className="text-gray-600 text-sm">$99.99</p>
      </div>
    </Link>
  )
}

function Pagination({
  currentPage,
  totalPages,
  searchParams,
}: {
  currentPage: number
  totalPages: number
  searchParams: ProductSearchParams
}) {
  const navigate = useNavigate()

  return (
    <div className="flex justify-center gap-2 mt-8">
      {currentPage > 1 && (
        <button
          onClick={() =>
            navigate({
              to: '/products',
              search: { ...searchParams, page: currentPage - 1 },
            })
          }
          className="px-3 py-1 border rounded hover:bg-gray-100"
        >
          Précédent
        </button>
      )}

      {Array.from({ length: totalPages }).map((_, i) => {
        const pageNum = i + 1
        return (
          <button
            key={pageNum}
            onClick={() =>
              navigate({
                to: '/products',
                search: { ...searchParams, page: pageNum },
              })
            }
            className={`px-3 py-1 rounded ${
              pageNum === currentPage
                ? 'bg-blue-600 text-white'
                : 'border hover:bg-gray-100'
            }`}
          >
            {pageNum}
          </button>
        )
      })}

      {currentPage < totalPages && (
        <button
          onClick={() =>
            navigate({
              to: '/products',
              search: { ...searchParams, page: currentPage + 1 },
            })
          }
          className="px-3 py-1 border rounded hover:bg-gray-100"
        >
          Suivant
        </button>
      )}
    </div>
  )
}

function FilterSection({
  title,
  children,
}: {
  title: string
  children: React.ReactNode
}) {
  return (
    <div className="border rounded p-4">
      <h3 className="font-bold mb-3">{title}</h3>
      {children}
    </div>
  )
}
```

### 2. Enums et Types Strict

**`src/routes/blog.tsx`** (avec enums de tri et vue)

```typescript
import { createFileRoute, useSearch, useNavigate } from '@tanstack/react-router'

type SortOrder = 'recent' | 'popular' | 'trending'
type ViewType = 'grid' | 'list' | 'timeline'

type BlogSearchParams = {
  query?: string
  sort: SortOrder
  view: ViewType
  author?: string
  tags?: string[]
  year?: number
};

export const Route = createFileRoute('/blog')({
  validateSearch: (search: Record<string, unknown>): BlogSearchParams => {
    const validSorts: SortOrder[] = ['recent', 'popular', 'trending']
    const validViews: ViewType[] = ['grid', 'list', 'timeline']

    // Valider sort - utiliser une valeur par défaut
    const sort = validSorts.includes(search.sort as any)
      ? (search.sort as SortOrder)
      : 'recent'

    // Valider view - utiliser une valeur par défaut
    const view = validViews.includes(search.view as any)
      ? (search.view as ViewType)
      : 'grid'

    // Gérer les tableaux (tags)
    let tags: string[] | undefined
    if (search.tags) {
      tags = Array.isArray(search.tags)
        ? search.tags
        : [search.tags as string]
    }

    return {
      query: search.query as string | undefined,
      sort,
      view,
      author: search.author as string | undefined,
      tags,
      year: search.year ? parseInt(search.year as string) : undefined,
    }
  },

  component: BlogPage,
})

function BlogPage() {
  const searchParams = useSearch({ from: '/blog' })
  const navigate = useNavigate()

  return (
    <div className="space-y-6">
      <header className="flex justify-between items-center">
        <h1 className="text-4xl font-bold">Blog</h1>
        <div className="flex gap-2">
          {/* Switcher de Vue */}
          {(['grid', 'list', 'timeline'] as const).map((view) => (
            <button
              key={view}
              onClick={() =>
                navigate({
                  to: '/blog',
                  search: { ...searchParams, view },
                })
              }
              className={`px-3 py-1 rounded text-sm ${
                searchParams.view === view
                  ? 'bg-blue-600 text-white'
                  : 'border hover:bg-gray-100'
              }`}
            >
              {view === 'grid' && 'Grille'}
              {view === 'list' && 'Liste'}
              {view === 'timeline' && 'Timeline'}
            </button>
          ))}
        </div>
      </header>

      <div className="space-y-4">
        {/* Filtres Actifs */}
        {(searchParams.query || searchParams.author || searchParams.tags) && (
          <div className="flex gap-2 flex-wrap">
            {searchParams.query && (
              <FilterTag
                label={`Recherche: "${searchParams.query}"`}
                onRemove={() =>
                  navigate({
                    to: '/blog',
                    search: { ...searchParams, query: undefined },
                  })
                }
              />
            )}
            {searchParams.author && (
              <FilterTag
                label={`Auteur: ${searchParams.author}`}
                onRemove={() =>
                  navigate({
                    to: '/blog',
                    search: { ...searchParams, author: undefined },
                  })
                }
              />
            )}
            {searchParams.tags?.map((tag) => (
              <FilterTag
                key={tag}
                label={tag}
                onRemove={() =>
                  navigate({
                    to: '/blog',
                    search: {
                      ...searchParams,
                      tags: searchParams.tags?.filter((t) => t !== tag),
                    },
                  })
                }
              />
            ))}
          </div>
        )}

        {/* Conteneur Résultats */}
        {searchParams.view === 'grid' && <GridView />}
        {searchParams.view === 'list' && <ListView />}
        {searchParams.view === 'timeline' && <TimelineView />}
      </div>

      {/* Options de Tri */}
      <div className="text-sm text-gray-600">
        Trier par:{' '}
        <select
          value={searchParams.sort}
          onChange={(e) =>
            navigate({
              to: '/blog',
              search: { ...searchParams, sort: e.target.value as SortOrder },
            })
          }
          className="border rounded px-2 py-1"
        >
          <option value="recent">Plus récent</option>
          <option value="popular">Plus populaire</option>
          <option value="trending">Tendance</option>
        </select>
      </div>
    </div>
  )
}

function FilterTag({
  label,
  onRemove,
}: {
  label: string
  onRemove: () => void
}) {
  return (
    <span className="inline-flex items-center gap-2 bg-blue-100 text-blue-800 px-3 py-1 rounded-full text-sm">
      {label}
      <button
        onClick={onRemove}
        className="text-blue-600 hover:text-blue-900 font-bold"
      >
        ×
      </button>
    </span>
  )
}

function GridView() {
  return (
    <div className="grid grid-cols-3 gap-6">
      {[1, 2, 3, 4, 5, 6].map((i) => (
        <article key={i} className="border rounded overflow-hidden hover:shadow-lg">
          <div className="bg-gray-200 h-40"></div>
          <div className="p-4">
            <h3 className="font-bold mb-2">Article {i}</h3>
            <p className="text-gray-600 text-sm line-clamp-2">Description</p>
          </div>
        </article>
      ))}
    </div>
  )
}

function ListView() {
  return (
    <div className="space-y-4">
      {[1, 2, 3].map((i) => (
        <article key={i} className="border rounded p-4 hover:shadow-lg">
          <h3 className="font-bold text-lg mb-2">Article {i}</h3>
          <p className="text-gray-600 mb-3">Description longue du contenu</p>
          <div className="flex gap-4 text-sm text-gray-500">
            <span>par Auteur</span>
            <span>2024-01-{String(i).padStart(2, '0')}</span>
          </div>
        </article>
      ))}
    </div>
  )
}

function TimelineView() {
  return (
    <div className="space-y-6">
      {[1, 2, 3].map((i) => (
        <div key={i} className="flex gap-4">
          <div className="w-24 text-right font-bold text-gray-600">
            2024-01-{String(i * 5).padStart(2, '0')}
          </div>
          <div className="flex-1 border-l-2 border-blue-400 pl-4 pb-4">
            <h3 className="font-bold">Article {i}</h3>
            <p className="text-gray-600 text-sm">Description</p>
          </div>
        </div>
      ))}
    </div>
  )
}
```

### 3. Paramètres Array/Multi-Valeurs

**`src/routes/filter.tsx`** (Filtres multiples sélectionnables)

```typescript
import { createFileRoute, useSearch, useNavigate } from '@tanstack/react-router'

type FilterSearchParams = {
  colors?: string[]
  sizes?: string[]
  brands?: string[]
  priceRange?: [number, number]
};

export const Route = createFileRoute('/filter')({
  validateSearch: (search: Record<string, unknown>): FilterSearchParams => {
    const toArray = (value: unknown): string[] => {
      if (Array.isArray(value)) return value
      if (typeof value === 'string') return [value]
      return []
    }

    const priceRange: [number, number] = [0, 1000]
    if (search.minPrice && search.maxPrice) {
      priceRange[0] = parseInt(search.minPrice as string)
      priceRange[1] = parseInt(search.maxPrice as string)
    }

    return {
      colors: toArray(search.colors),
      sizes: toArray(search.sizes),
      brands: toArray(search.brands),
      priceRange:
        priceRange[0] > 0 || priceRange[1] < 1000 ? priceRange : undefined,
    }
  },

  component: FilterPage,
})

function FilterPage() {
  const searchParams = useSearch({ from: '/filter' })
  const navigate = useNavigate()

  const toggleFilter = (
    type: 'colors' | 'sizes' | 'brands',
    value: string
  ) => {
    const currentArray = searchParams[type] || []
    const newArray = currentArray.includes(value)
      ? currentArray.filter((v) => v !== value)
      : [...currentArray, value]

    navigate({
      to: '/filter',
      search: {
        ...searchParams,
        [type]: newArray.length > 0 ? newArray : undefined,
      },
    })
  }

  const colors = ['Red', 'Blue', 'Green', 'Black', 'White']
  const sizes = ['XS', 'S', 'M', 'L', 'XL', 'XXL']
  const brands = ['Nike', 'Adidas', 'Puma', 'Reebok']

  return (
    <div className="grid grid-cols-4 gap-6">
      <aside className="space-y-6">
        {/* Couleurs */}
        <div>
          <h3 className="font-bold mb-3">Couleurs</h3>
          <div className="space-y-2">
            {colors.map((color) => (
              <label key={color} className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={searchParams.colors?.includes(color) || false}
                  onChange={() => toggleFilter('colors', color)}
                />
                {color}
              </label>
            ))}
          </div>
        </div>

        {/* Tailles */}
        <div>
          <h3 className="font-bold mb-3">Tailles</h3>
          <div className="space-y-2">
            {sizes.map((size) => (
              <label key={size} className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={searchParams.sizes?.includes(size) || false}
                  onChange={() => toggleFilter('sizes', size)}
                />
                {size}
              </label>
            ))}
          </div>
        </div>

        {/* Marques */}
        <div>
          <h3 className="font-bold mb-3">Marques</h3>
          <div className="space-y-2">
            {brands.map((brand) => (
              <label key={brand} className="flex items-center gap-2">
                <input
                  type="checkbox"
                  checked={searchParams.brands?.includes(brand) || false}
                  onChange={() => toggleFilter('brands', brand)}
                />
                {brand}
              </label>
            ))}
          </div>
        </div>
      </aside>

      <main className="col-span-3">
        <div className="space-y-4">
          <h2 className="text-2xl font-bold">
            Produits filtrés
            {searchParams.colors?.length || searchParams.sizes?.length
              ? ` (${[...(searchParams.colors || []), ...(searchParams.sizes || [])].length} filtres)`
              : ''}
          </h2>

          {/* Affichage des filtres actifs */}
          {(searchParams.colors ||
            searchParams.sizes ||
            searchParams.brands) && (
            <div className="bg-blue-50 p-4 rounded">
              <div className="flex gap-2 flex-wrap">
                {searchParams.colors?.map((color) => (
                  <span key={color} className="bg-blue-200 px-2 py-1 rounded text-sm">
                    {color}
                  </span>
                ))}
                {searchParams.sizes?.map((size) => (
                  <span key={size} className="bg-blue-200 px-2 py-1 rounded text-sm">
                    {size}
                  </span>
                ))}
                {searchParams.brands?.map((brand) => (
                  <span key={brand} className="bg-blue-200 px-2 py-1 rounded text-sm">
                    {brand}
                  </span>
                ))}
              </div>
            </div>
          )}

          {/* Résultats */}
          <div className="grid grid-cols-3 gap-4">
            {[1, 2, 3, 4, 5, 6].map((i) => (
              <div key={i} className="border rounded p-4">
                <p className="font-bold">Produit {i}</p>
              </div>
            ))}
          </div>
        </div>
      </main>
    </div>
  )
}
```

### 4. Sérialisation Personnalisée

**`src/routes/advanced-search.tsx`** (avec sérialisation custom)

```typescript
import { createFileRoute, useSearch, useNavigate } from '@tanstack/react-router'

type DateRange = {
  from: Date
  to: Date
};

type AdvancedSearchParams = {
  query?: string
  dateRange?: DateRange
  excludeWords?: string[]
  language?: string
};

export const Route = createFileRoute('/advanced-search')({
  validateSearch: (search: Record<string, unknown>): AdvancedSearchParams => {
    // Parser personnalisé pour les dates
    let dateRange: DateRange | undefined
    if (search.from && search.to) {
      try {
        dateRange = {
          from: new Date(search.from as string),
          to: new Date(search.to as string),
        }
      } catch {
        // Dates invalides, ignorer
      }
    }

    // Parser les mots exclus
    let excludeWords: string[] | undefined
    if (search.exclude) {
      const exclude = search.exclude as string | string[]
      excludeWords = Array.isArray(exclude) ? exclude : exclude.split(',')
    }

    return {
      query: (search.query as string) || undefined,
      dateRange,
      excludeWords,
      language: (search.language as string) || 'fr',
    }
  },

  component: AdvancedSearchPage,
})

function AdvancedSearchPage() {
  const searchParams = useSearch({ from: '/advanced-search' })
  const navigate = useNavigate()

  const handleSearch = (params: Partial<AdvancedSearchParams>) => {
    navigate({
      to: '/advanced-search',
      search: {
        ...searchParams,
        ...params,
        // Sérialiser les dates
        from: params.dateRange?.from.toISOString(),
        to: params.dateRange?.to.toISOString(),
      },
    })
  }

  return (
    <div className="max-w-2xl mx-auto space-y-6">
      <h1 className="text-3xl font-bold">Recherche Avancée</h1>

      <form className="space-y-4 bg-white p-6 rounded border">
        <div>
          <label className="block font-bold mb-2">Requête</label>
          <input
            type="text"
            value={searchParams.query || ''}
            onChange={(e) =>
              handleSearch({ query: e.target.value || undefined })
            }
            placeholder="Entrer les mots-clés"
            className="w-full px-3 py-2 border rounded"
          />
        </div>

        <div>
          <label className="block font-bold mb-2">Exclure ces mots (séparés par des virgules)</label>
          <input
            type="text"
            value={searchParams.excludeWords?.join(', ') || ''}
            onChange={(e) =>
              handleSearch({
                excludeWords: e.target.value
                  ? e.target.value.split(',').map((w) => w.trim())
                  : undefined,
              })
            }
            placeholder="mot1, mot2, mot3"
            className="w-full px-3 py-2 border rounded"
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <label className="block font-bold mb-2">Date From</label>
            <input
              type="date"
              value={
                searchParams.dateRange?.from
                  ? searchParams.dateRange.from.toISOString().split('T')[0]
                  : ''
              }
              onChange={(e) => {
                const newFrom = e.target.value
                  ? new Date(e.target.value)
                  : undefined
                handleSearch({
                  dateRange: newFrom
                    ? {
                        from: newFrom,
                        to: searchParams.dateRange?.to || new Date(),
                      }
                    : undefined,
                })
              }}
              className="w-full px-3 py-2 border rounded"
            />
          </div>
          <div>
            <label className="block font-bold mb-2">Date To</label>
            <input
              type="date"
              value={
                searchParams.dateRange?.to
                  ? searchParams.dateRange.to.toISOString().split('T')[0]
                  : ''
              }
              onChange={(e) => {
                const newTo = e.target.value ? new Date(e.target.value) : undefined
                handleSearch({
                  dateRange: newTo
                    ? {
                        from: searchParams.dateRange?.from || new Date(),
                        to: newTo,
                      }
                    : undefined,
                })
              }}
              className="w-full px-3 py-2 border rounded"
            />
          </div>
        </div>

        <div>
          <label className="block font-bold mb-2">Langue</label>
          <select
            value={searchParams.language || 'fr'}
            onChange={(e) => handleSearch({ language: e.target.value })}
            className="w-full px-3 py-2 border rounded"
          >
            <option value="fr">Français</option>
            <option value="en">English</option>
            <option value="es">Español</option>
            <option value="de">Deutsch</option>
          </select>
        </div>

        <button
          type="submit"
          className="w-full bg-blue-600 text-white py-2 rounded font-bold hover:bg-blue-700"
        >
          Rechercher
        </button>
      </form>

      {/* Résultats */}
      {searchParams.query && (
        <div className="space-y-4">
          <h2 className="font-bold">Résultats pour: {searchParams.query}</h2>
          {[1, 2, 3].map((i) => (
            <div key={i} className="border rounded p-4">
              <h3 className="font-bold text-blue-600">Résultat {i}</h3>
              <p>Description du résultat de recherche</p>
            </div>
          ))}
        </div>
      )}
    </div>
  )
}
```

## Best Practices

### 1. Validation Centralisée avec Zod

```typescript
import { z } from 'zod'

const searchSchema = z.object({
  q: z.string().optional(),
  page: z.coerce.number().int().positive().default(1),
  sort: z.enum(['name', 'date', 'price']).default('name'),
})

export const Route = createFileRoute('/search')({
  validateSearch: (search) => searchSchema.parse(search),
})
```

### 2. Shareable URLs

```typescript
// ✅ Créer une fonction utilitaire pour générer les URLs
function getProductsUrl(filters: ProductSearchParams) {
  const url = new URL('/products', window.location.origin)
  if (filters.search) url.searchParams.set('search', filters.search)
  if (filters.category) url.searchParams.set('category', filters.category)
  if (filters.page) url.searchParams.set('page', filters.page.toString())
  return url.toString()
}
```

### 3. Persistent Filters (LocalStorage)

```typescript
export const Route = createFileRoute('/products')({
  beforeLoad: () => {
    const saved = localStorage.getItem('productFilters')
    return { savedFilters: saved ? JSON.parse(saved) : null }
  },

  component: ProductsPage,
})

function ProductsPage() {
  const { savedFilters } = useLoaderData({ from: '/products' })
  const searchParams = useSearch({ from: '/products' })

  // Combiner les filtres sauvegardés avec les params actuels
}
```

## Avantages

- **Type Safety**: Tous les paramètres de recherche sont validés et typés
- **Shareability**: URLs sérialisables et facilement partagées
- **Bookmarkability**: Les filtres sont conservés dans l'historique/signets
- **Replayability**: Recréer l'état de l'application depuis une URL
- **Validation**: Assurer que les données correspondent aux attentes
- **Transformation**: Convertir les strings en types typés (nombre, date, etc.)
