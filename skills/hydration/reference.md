# Reference

# Hydration avec TanStack Start

## Concept

Hydration est le processus où React prend le contrôle du DOM côté client qui a été rendu côté serveur. C'est crucial de synchroniser l'état correctement.

## Architecture Hydration

```
Server Renders Component
    ├─ Generate HTML
    └─ Embed State in Window
    ↓
Browser Receives HTML
    ├─ Affiche le contenu
    └─ Load JavaScript
    ↓
React Hydrate
    ├─ Attacher event listeners
    ├─ Synchroniser l'état
    └─ Valider DOM match
```

## Patterns Hydration

### 1. State Management côté Serveur

**`src/lib/serverState.ts`**

```typescript
// ✅ Gérér l'état pour l'hydration
type ServerState = {
  user: any | null
  theme: 'light' | 'dark'
  locale: string
};

// Créer un contexte pour le state
export let serverState: ServerState = {
  user: null,
  theme: 'light',
  locale: 'en',
}

export function setServerState(newState: Partial<ServerState>) {
  serverState = { ...serverState, ...newState }
}

export function getServerState(): ServerState {
  return { ...serverState }
}

// Sérialiser pour le client
export function serializeState(state: ServerState): string {
  return JSON.stringify({
    ...state,
    // Exclure les données sensibles
    user: state.user
      ? {
          id: state.user.id,
          name: state.user.name,
          email: state.user.email,
        }
      : null,
  })
}
```

### 2. Entry Server avec Hydration State

**`src/entry-server.tsx`**

```typescript
import React from 'react'
import { renderToReadableStream } from 'react-dom/server'
import { createMemoryHistory, createRouter } from '@tanstack/react-router'
import { RootRoute } from './root'
import { setServerState, getServerState, serializeState } from '@/lib/serverState'

export default async function render(
  url: string,
  context?: {
    user?: any
    theme?: string
    locale?: string
  }
) {
  // ✅ Initialiser l'état côté serveur
  if (context?.user) {
    setServerState({
      user: context.user,
      theme: context.theme as 'light' | 'dark',
      locale: context.locale,
    })
  }

  // Créer le router
  const memoryHistory = createMemoryHistory({
    initialEntries: [url],
  })

  const router = createRouter({
    routeTree: RootRoute,
    history: memoryHistory,
  })

  // Charger les données de la route
  await router.load()

  // ✅ Sérialiser l'état pour le client
  const hydrateState = getServerState()

  // Créer le stream
  const readableStream = await renderToReadableStream(
    React.createElement(RootRoute.component, {
      router,
      initialState: hydrateState,
    }),
    {
      // ✅ Bootstrap le state dans le HTML
      bootstrapScriptContent: `
        window.__HYDRATION_STATE__ = ${serializeState(hydrateState)};
        window.__ROUTER_STATE__ = ${JSON.stringify(router.dehydrate())};
      `,

      onShellReady() {
        // Le shell est prêt à être envoyé
      },

      onError(error) {
        console.error('Render error:', error)
      },
    }
  )

  return readableStream
}
```

### 3. App Root avec Hydration

**`src/root.tsx`**

```typescript
import React, { createContext, useContext } from 'react'
import { Outlet } from '@tanstack/react-router'

type ServerState = {
  user: any | null
  theme: 'light' | 'dark'
  locale: string
};

// Context pour l'état partagé
const HydrationContext = createContext<ServerState | null>(null)

export function useHydrationState() {
  return useContext(HydrationContext)
}

type RootProps = {
  router: any
  initialState?: ServerState
};

export function RootComponent({ initialState }: RootProps) {
  // ✅ État initial depuis la fenêtre
  const [state] = React.useState<ServerState>(() => {
    if (typeof window !== 'undefined' && (window as any).__HYDRATION_STATE__) {
      return (window as any).__HYDRATION_STATE__
    }
    return initialState || {
      user: null,
      theme: 'light',
      locale: 'en',
    }
  })

  return (
    <HydrationContext.Provider value={state}>
      <html lang={state.locale}>
        <head>
          <meta charSet="UTF-8" />
          <meta
            name="viewport"
            content="width=device-width, initial-scale=1"
          />

          {/* Theme color pour le mode sombre */}
          {state.theme === 'dark' && (
            <meta name="theme-color" content="#000000" />
          )}

          <title>My App</title>
          <link rel="stylesheet" href="/styles.css" />
        </head>

        <body className={state.theme === 'dark' ? 'dark' : ''}>
          <div id="root">
            <Outlet />
          </div>

          {/* Client hydration */}
          <script type="module" src="/entry-client.js"></script>
        </body>
      </html>
    </HydrationContext.Provider>
  )
}
```

### 4. Entry Client avec Validation Hydration

**`src/entry-client.tsx`**

```typescript
import React from 'react'
import ReactDOM from 'react-dom/client'
import { createBrowserHistory, createRouter } from '@tanstack/react-router'
import { RootRoute } from './root'

async function hydrateApp() {
  // Validation du DOM
  const root = document.getElementById('root')
  if (!root) {
    console.error('Root element not found')
    return
  }

  // ✅ Récupérer l'état du serveur
  const hydratedState = (window as any).__HYDRATION_STATE__ || {
    user: null,
    theme: 'light',
    locale: 'en',
  }

  const routerState = (window as any).__ROUTER_STATE__

  // Créer le router avec l'état du serveur
  const router = createRouter({
    routeTree: RootRoute,
    history: createBrowserHistory(),
    // ✅ Hydrate le routeur avec l'état du serveur
    dehydrate: () => routerState,
  })

  // ✅ Validation stricte en développement
  const legacyRoot = (window as any).__REACT_ROOT__
  if (legacyRoot) {
    legacyRoot.unmount()
  }

  // Hydrater le DOM
  const reactRoot = ReactDOM.hydrateRoot(
    root,
    React.createElement(RootRoute.component, {
      router,
      initialState: hydratedState,
    })
  )

  // ✅ Invalider l'état du serveur après hydration
  delete (window as any).__HYDRATION_STATE__
  delete (window as any).__ROUTER_STATE__

  return reactRoot
}

// Attendre que le document soit complètement chargé
if (document.readyState === 'loading') {
  document.addEventListener('DOMContentLoaded', hydrateApp)
} else {
  hydrateApp().catch((error) => {
    console.error('Hydration failed:', error)
    // Fallback: hard refresh
    window.location.reload()
  })
}
```

### 5. Route avec Hydration Control

**`src/routes/profile.tsx`**

```typescript
import { createFileRoute, useLoaderData } from '@tanstack/react-router'
import { useHydrationState } from '@/root'
import { useEffect, useState } from 'react'

type ProfileData = {
  user: {
    id: string
    name: string
    email: string
  }
};

export const Route = createFileRoute('/profile')({
  // ✅ Loader exécuté sur serveur (SSR) ET client (navigation)
  loader: async () => {
    // Sur le serveur: API locale
    // Sur le client: API distante
    const baseUrl = typeof window === 'undefined'
      ? 'http://localhost:3000'
      : ''

    const response = await fetch(`${baseUrl}/api/me`)
    if (!response.ok) throw new Error('Failed to load profile')

    return response.json() as Promise<ProfileData>
  },

  component: ProfilePage,
})

function ProfilePage() {
  const { user } = useLoaderData({ from: '/profile' })
  const hydrationState = useHydrationState()

  // ✅ Utiliser l'état hydraté si dispo
  const [isHydrated, setIsHydrated] = useState(false)

  useEffect(() => {
    setIsHydrated(true)
  }, [])

  // Empêcher le mismatch d'hydration
  if (!isHydrated) {
    return <ProfileSkeleton />
  }

  return (
    <div className="max-w-2xl mx-auto py-8">
      <div className="bg-white border rounded p-8">
        <h1 className="text-4xl font-bold mb-2">{user.name}</h1>
        <p className="text-gray-600 mb-6">{user.email}</p>

        {/* Le user vient du loader, déjà hydraté */}
        <div className="space-y-4">
          <div>
            <label className="text-sm text-gray-600">ID</label>
            <p className="font-bold">{user.id}</p>
          </div>

          {/* Theme peut venir de l'hydrationState */}
          <div>
            <label className="text-sm text-gray-600">Thème</label>
            <p className="font-bold">{hydrationState?.theme || 'light'}</p>
          </div>
        </div>
      </div>
    </div>
  )
}

function ProfileSkeleton() {
  return (
    <div className="max-w-2xl mx-auto py-8">
      <div className="bg-white border rounded p-8 space-y-4 animate-pulse">
        <div className="h-8 bg-gray-200 rounded w-2/3"></div>
        <div className="h-4 bg-gray-200 rounded w-1/2"></div>
      </div>
    </div>
  )
}
```

### 6. Anti-Patterns et Solutions

**`src/components/HydrationAwareness.tsx`**

```typescript
import { useEffect, useState } from 'react'

// ❌ MAUVAIS: Mismatch d'hydration
function BadComponent() {
  // Timestamp random: différent sur serveur et client
  return <div>{new Date().getTime()}</div>
}

// ✅ BON: Attendre l'hydration
function GoodComponent() {
  const [isHydrated, setIsHydrated] = useState(false)

  useEffect(() => {
    setIsHydrated(true)
  }, [])

  if (!isHydrated) {
    return <div>Placeholder</div>
  }

  return <div>{new Date().getTime()}</div>
}

// ✅ BON: Utiliser des données du serveur
function ServerDataComponent() {
  const timestamp = (window as any).__SERVER_TIMESTAMP__ || null

  return <div>{timestamp}</div>
}

// ✅ BON: useLayoutEffect après hydration
function ClientOnlyComponent() {
  const [mounted, setMounted] = useState(false)

  useLayoutEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) return null

  return <div>Client-only content</div>
}
```

### 7. Debugging Hydration Issues

**`src/lib/hydrationDebug.ts`**

```typescript
// ✅ Detecter les problèmes d'hydration
export function setupHydrationDebugging() {
  if (typeof window === 'undefined' || process.env.NODE_ENV !== 'development') {
    return
  }

  const originalError = console.error
  console.error = function (...args: any[]) {
    if (
      args[0]?.includes?.('Hydration failed') ||
      args[0]?.message?.includes?.('Hydration failed')
    ) {
      console.log('%c=== HYDRATION MISMATCH ===', 'color: red; font-weight: bold')
      console.log('Message:', args[0])

      // Suggérer solutions
      console.log('Solutions:')
      console.log('1. Utiliser useState avec valeur initiale')
      console.log('2. Attendre isHydrated dans useEffect')
      console.log('3. Partager l\'état via window ou Context')
    }

    originalError.apply(console, args)
  }

  // Monitorer les changements DOM post-hydration
  const observer = new MutationObserver((mutations) => {
    mutations.forEach((mutation) => {
      if (mutation.type === 'childList' || mutation.type === 'attributes') {
        console.debug('DOM modified after hydration')
      }
    })
  })

  observer.observe(document.documentElement, {
    childList: true,
    subtree: true,
    attributes: true,
  })
}

// Appeler au démarrage du client
if (typeof window !== 'undefined') {
  setupHydrationDebugging()
}
```

## Best Practices

### 1. Toujours Valider Hydration

```typescript
// ✅ Vérifier que tout est synchronisé
const [isHydrated, setIsHydrated] = useState(false)

useEffect(() => {
  setIsHydrated(true)
}, [])

if (!isHydrated) return <Skeleton />
```

### 2. Passer l'État dans Window

```typescript
// Côté serveur
window.__APP_STATE__ = JSON.stringify(state)

// Côté client
const state = JSON.parse(window.__APP_STATE__ || '{}')
```

### 3. Éviter les Timestamps et UUIDs

```typescript
// ❌ Mismatch garanti
const id = Math.random()

// ✅ Utiliser les données du serveur
const id = serverData.id
```

## Avantages

- **Zero Flash**: Pas de contenu blanc
- **Performance**: Hydration rapide
- **UX**: Interactivité immédiate
- **SEO**: HTML complet
- **Reliable**: Validation stricte
