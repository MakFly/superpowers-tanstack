---
name: tanstack:client-only-fns
description: Create client-only functions for browser APIs, localStorage, and client state
---

# Client-Only Functions

## Concept

Les Client-Only Functions sont des fonctions qui s'exécutent UNIQUEMENT côté client et utilisent les APIs du navigateur (DOM, localStorage, sessionStorage, IndexedDB, Web Workers, etc.). Elles ne peuvent jamais être exécutées côté serveur, et TypeScript le garantit.

## Architecture

```
Server (Node.js)
├── Cannot access DOM
├── Cannot access localStorage
└── Cannot use browser APIs

Client Barrier (Browser Runtime)
↓

Client Layer (Browser Runtime)
├── DOM Manipulation
├── localStorage/sessionStorage
├── IndexedDB
├── Web Crypto API
├── ServiceWorkers
└── Browser Storage APIs
```

## Implémentation Détaillée

### 1. Pattern Basique: DOM et LocalStorage

**`src/lib/client-only/storage.ts`**

```typescript
import 'client-only'

// ✅ Ce fichier NE PEUT PAS être importé côté serveur
// ✅ TypeScript lancera une erreur si on essaie

export type StorageOptions = {
  serialize?: (value: any) => string
  deserialize?: (value: string) => any
  ttl?: number // Time to live en millisecondes
};

const DEFAULT_OPTIONS: StorageOptions = {
  serialize: JSON.stringify,
  deserialize: JSON.parse,
}

export class LocalStorageManager {
  // ✅ Gestion typée du localStorage

  static set<T>(
    key: string,
    value: T,
    options: StorageOptions = {}
  ): void {
    const opts = { ...DEFAULT_OPTIONS, ...options }

    try {
      const serialized = opts.serialize!(value)
      const item = {
        value: serialized,
        timestamp: Date.now(),
        ttl: options.ttl,
      }

      localStorage.setItem(key, JSON.stringify(item))
    } catch (error) {
      console.error(`Failed to set ${key}:`, error)
    }
  }

  static get<T>(
    key: string,
    options: StorageOptions = {}
  ): T | null {
    const opts = { ...DEFAULT_OPTIONS, ...options }

    try {
      const item = localStorage.getItem(key)

      if (!item) return null

      const { value, timestamp, ttl } = JSON.parse(item)

      // ✅ Vérifier la TTL
      if (ttl && Date.now() - timestamp > ttl) {
        localStorage.removeItem(key)
        return null
      }

      return opts.deserialize!(value)
    } catch (error) {
      console.error(`Failed to get ${key}:`, error)
      return null
    }
  }

  static remove(key: string): void {
    try {
      localStorage.removeItem(key)
    } catch (error) {
      console.error(`Failed to remove ${key}:`, error)
    }
  }

  static clear(): void {
    try {
      localStorage.clear()
    } catch (error) {
      console.error('Failed to clear localStorage:', error)
    }
  }

  static keys(): string[] {
    try {
      return Object.keys(localStorage)
    } catch {
      return []
    }
  }
}

export class SessionStorageManager {
  // ✅ Gestion typée du sessionStorage

  static set<T>(key: string, value: T): void {
    try {
      sessionStorage.setItem(key, JSON.stringify(value))
    } catch (error) {
      console.error(`Failed to set ${key}:`, error)
    }
  }

  static get<T>(key: string): T | null {
    try {
      const item = sessionStorage.getItem(key)
      return item ? JSON.parse(item) : null
    } catch (error) {
      console.error(`Failed to get ${key}:`, error)
      return null
    }
  }

  static remove(key: string): void {
    try {
      sessionStorage.removeItem(key)
    } catch (error) {
      console.error(`Failed to remove ${key}:`, error)
    }
  }
}
```

### 2. Gestion du DOM et Des Événements

**`src/lib/client-only/dom.ts`**

```typescript
import 'client-only'

// ✅ Manipulation du DOM côté client

export function getElementOrThrow<T extends Element>(
  selector: string
): T {
  const element = document.querySelector<T>(selector)

  if (!element) {
    throw new Error(`Element not found: ${selector}`)
  }

  return element
}

export function addEventListenerOnce<K extends keyof DocumentEventMap>(
  element: Element | Window,
  event: K,
  handler: (ev: DocumentEventMap[K]) => void
): void {
  element.addEventListener(event as string, handler as EventListener, {
    once: true,
  })
}

export function observeElement(
  element: Element,
  callback: (isVisible: boolean) => void
): () => void {
  // ✅ Utiliser l'Intersection Observer API

  const observer = new IntersectionObserver(([entry]) => {
    callback(entry.isIntersecting)
  })

  observer.observe(element)

  // ✅ Retourner une fonction de cleanup
  return () => observer.disconnect()
}

export function watchMediaQuery(
  query: string,
  callback: (matches: boolean) => void
): () => void {
  // ✅ Écouter les changements de media queries

  const mediaQuery = window.matchMedia(query)

  const handler = (e: MediaQueryListEvent) => {
    callback(e.matches)
  }

  mediaQuery.addEventListener('change', handler)

  // Appeler immédiatement avec la valeur actuelle
  callback(mediaQuery.matches)

  return () => mediaQuery.removeEventListener('change', handler)
}

export function copyToClipboard(text: string): Promise<boolean> {
  // ✅ Copier dans le presse-papiers

  if (navigator.clipboard?.writeText) {
    return navigator.clipboard
      .writeText(text)
      .then(() => true)
      .catch(() => false)
  }

  // Fallback pour navigateurs anciens
  const textarea = document.createElement('textarea')
  textarea.value = text
  textarea.style.position = 'fixed'
  textarea.style.opacity = '0'
  document.body.appendChild(textarea)
  textarea.select()

  try {
    const success = document.execCommand('copy')
    document.body.removeChild(textarea)
    return Promise.resolve(success)
  } catch {
    document.body.removeChild(textarea)
    return Promise.resolve(false)
  }
}

export function downloadFile(
  content: string,
  filename: string,
  mimeType: string = 'text/plain'
): void {
  // ✅ Télécharger un fichier côté client

  const blob = new Blob([content], { type: mimeType })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')

  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)

  URL.revokeObjectURL(url)
}

export function downloadBlob(blob: Blob, filename: string): void {
  // ✅ Télécharger un Blob côté client

  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')

  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)

  URL.revokeObjectURL(url)
}
```

### 3. IndexedDB pour Stockage Persistent

**`src/lib/client-only/indexeddb.ts`**

```typescript
import 'client-only'

// ✅ Stockage IndexedDB côté client

export type DbOptions = {
  dbName: string;
  version: number;
  stores: {
    [storeName: string]: {
      keyPath?: string;
      autoIncrement?: boolean;
      indexes?: Array<{
        name: string;
        keyPath: string | string[];
        unique?: boolean;
      }>;
    };
  };
};

export class IndexedDBManager {
  private db: IDBDatabase | null = null
  private dbName: string
  private version: number
  private stores: DbOptions['stores']

  constructor(options: DbOptions) {
    this.dbName = options.dbName
    this.version = options.version
    this.stores = options.stores
  }

  async initialize(): Promise<void> {
    // ✅ Initialiser la base de données IndexedDB

    return new Promise((resolve, reject) => {
      const request = indexedDB.open(this.dbName, this.version)

      request.onerror = () => reject(request.error)
      request.onsuccess = () => {
        this.db = request.result
        resolve()
      }

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result

        for (const [storeName, storeConfig] of Object.entries(
          this.stores
        )) {
          if (!db.objectStoreNames.contains(storeName)) {
            const store = db.createObjectStore(storeName, {
              keyPath: storeConfig.keyPath,
              autoIncrement: storeConfig.autoIncrement,
            })

            // Créer les indexes
            storeConfig.indexes?.forEach((index) => {
              store.createIndex(index.name, index.keyPath, {
                unique: index.unique,
              })
            })
          }
        }
      }
    })
  }

  async add<T>(
    storeName: string,
    value: T
  ): Promise<IDBValidKey> {
    // ✅ Ajouter un élément

    const store = this.getObjectStore(storeName, 'readwrite')
    return this.promisify(store.add(value))
  }

  async put<T>(
    storeName: string,
    value: T
  ): Promise<IDBValidKey> {
    // ✅ Mettre à jour ou créer un élément

    const store = this.getObjectStore(storeName, 'readwrite')
    return this.promisify(store.put(value))
  }

  async get<T>(
    storeName: string,
    key: IDBValidKey
  ): Promise<T | undefined> {
    // ✅ Récupérer un élément par clé

    const store = this.getObjectStore(storeName, 'readonly')
    return this.promisify(store.get(key))
  }

  async getAll<T>(storeName: string): Promise<T[]> {
    // ✅ Récupérer tous les éléments

    const store = this.getObjectStore(storeName, 'readonly')
    return this.promisify(store.getAll())
  }

  async delete(
    storeName: string,
    key: IDBValidKey
  ): Promise<void> {
    // ✅ Supprimer un élément

    const store = this.getObjectStore(storeName, 'readwrite')
    return this.promisify(store.delete(key))
  }

  async clear(storeName: string): Promise<void> {
    // ✅ Vider un store

    const store = this.getObjectStore(storeName, 'readwrite')
    return this.promisify(store.clear())
  }

  private getObjectStore(
    storeName: string,
    mode: IDBTransactionMode
  ): IDBObjectStore {
    if (!this.db) throw new Error('Database not initialized')

    const transaction = this.db.transaction(storeName, mode)
    return transaction.objectStore(storeName)
  }

  private promisify<T>(
    request: IDBRequest<T>
  ): Promise<T> {
    return new Promise((resolve, reject) => {
      request.onerror = () => reject(request.error)
      request.onsuccess = () => resolve(request.result)
    })
  }
}
```

### 4. Web Crypto API pour Chiffrement Client

**`src/lib/client-only/crypto.ts`**

```typescript
import 'client-only'

// ✅ Chiffrement côté client avec Web Crypto API

export async function generateKey(): Promise<CryptoKey> {
  // ✅ Générer une clé de chiffrement

  return await window.crypto.subtle.generateKey(
    {
      name: 'AES-GCM',
      length: 256,
    },
    true, // extractable
    ['encrypt', 'decrypt']
  )
}

export async function encryptData(
  data: string,
  key: CryptoKey
): Promise<string> {
  // ✅ Chiffrer des données côté client

  const iv = window.crypto.getRandomValues(new Uint8Array(12))
  const encoder = new TextEncoder()

  const encrypted = await window.crypto.subtle.encrypt(
    {
      name: 'AES-GCM',
      iv,
    },
    key,
    encoder.encode(data)
  )

  // Combiner IV + données chiffrées
  const combined = new Uint8Array(iv.length + encrypted.byteLength)
  combined.set(iv)
  combined.set(new Uint8Array(encrypted), iv.length)

  return btoa(String.fromCharCode.apply(null, Array.from(combined)))
}

export async function decryptData(
  encryptedData: string,
  key: CryptoKey
): Promise<string> {
  // ✅ Déchiffrer des données côté client

  const combined = new Uint8Array(
    atob(encryptedData).split('').map((c) => c.charCodeAt(0))
  )

  const iv = combined.slice(0, 12)
  const encrypted = combined.slice(12)

  const decrypted = await window.crypto.subtle.decrypt(
    {
      name: 'AES-GCM',
      iv,
    },
    key,
    encrypted
  )

  return new TextDecoder().decode(decrypted)
}

export async function hashPassword(password: string): Promise<string> {
  // ✅ Hasher un mot de passe côté client

  const encoder = new TextEncoder()
  const data = encoder.encode(password)
  const hashBuffer = await window.crypto.subtle.digest('SHA-256', data)

  const hashArray = Array.from(new Uint8Array(hashBuffer))
  return hashArray.map((b) => b.toString(16).padStart(2, '0')).join('')
}
```

### 5. Analytics et Tracking Client

**`src/lib/client-only/analytics.ts`**

```typescript
import 'client-only'

// ✅ Analytics côté client

export type AnalyticsEvent = {
  name: string;
  properties?: Record<string, any>;
  timestamp?: number;
};

export class AnalyticsManager {
  private events: AnalyticsEvent[] = []
  private batchSize: number = 10
  private flushInterval: NodeJS.Timeout | null = null

  constructor(options?: { batchSize?: number; flushInterval?: number }) {
    this.batchSize = options?.batchSize ?? 10

    // ✅ Envoyer les événements périodiquement
    if (options?.flushInterval) {
      this.flushInterval = setInterval(
        () => this.flush(),
        options.flushInterval
      )
    }

    // ✅ Envoyer les événements avant de quitter la page
    window.addEventListener('beforeunload', () => this.flush())
  }

  track(event: AnalyticsEvent): void {
    // ✅ Tracker un événement côté client

    const enriched: AnalyticsEvent = {
      ...event,
      timestamp: event.timestamp ?? Date.now(),
      properties: {
        ...event.properties,
        url: window.location.href,
        userAgent: navigator.userAgent,
      },
    }

    this.events.push(enriched)

    if (this.events.length >= this.batchSize) {
      this.flush()
    }
  }

  private flush(): void {
    // ✅ Envoyer les événements au serveur

    if (this.events.length === 0) return

    const batch = this.events.splice(0, this.batchSize)

    // Utiliser sendBeacon pour garantir que les données sont envoyées
    if (navigator.sendBeacon) {
      navigator.sendBeacon(
        '/api/analytics',
        JSON.stringify({ events: batch })
      )
    } else {
      // Fallback: fetch
      fetch('/api/analytics', {
        method: 'POST',
        body: JSON.stringify({ events: batch }),
        keepalive: true,
      }).catch(() => {
        // Ajouter les événements non envoyés back à la queue
        this.events.unshift(...batch)
      })
    }
  }

  destroy(): void {
    // ✅ Cleanup

    if (this.flushInterval) {
      clearInterval(this.flushInterval)
    }

    this.flush()
  }
}
```

### 6. Notification et Geolocation

**`src/lib/client-only/browser-features.ts`**

```typescript
import 'client-only'

// ✅ Features du navigateur côté client

export function requestNotificationPermission(): Promise<NotificationPermission> {
  // ✅ Demander la permission pour les notifications

  if (!('Notification' in window)) {
    return Promise.resolve('denied')
  }

  return Notification.requestPermission()
}

export function showNotification(
  title: string,
  options?: NotificationOptions
): void {
  // ✅ Afficher une notification côté client

  if ('Notification' in window && Notification.permission === 'granted') {
    new Notification(title, options)
  }
}

export function getCurrentPosition(): Promise<GeolocationCoordinates> {
  // ✅ Obtenir la position géographique de l'utilisateur

  return new Promise((resolve, reject) => {
    if (!navigator.geolocation) {
      reject(new Error('Geolocation not supported'))
      return
    }

    navigator.geolocation.getCurrentPosition(
      (position) => {
        resolve(position.coords)
      },
      (error) => {
        reject(error)
      }
    )
  })
}

export function watchPosition(
  callback: (coords: GeolocationCoordinates) => void,
  onError?: (error: GeolocationPositionError) => void
): number {
  // ✅ Suivre la position en temps réel

  if (!navigator.geolocation) {
    throw new Error('Geolocation not supported')
  }

  return navigator.geolocation.watchPosition(
    (position) => callback(position.coords),
    onError
  )
}

export function stopWatchingPosition(watchId: number): void {
  // ✅ Arrêter le suivi de la position

  navigator.geolocation.clearWatch(watchId)
}

export async function getNetworkInfo(): Promise<{
  online: boolean
  effectiveType: string
  downlink: number
}> {
  // ✅ Obtenir les infos de connexion réseau

  const connection = (navigator as any).connection

  if (!connection) {
    return {
      online: navigator.onLine,
      effectiveType: 'unknown',
      downlink: 0,
    }
  }

  return {
    online: navigator.onLine,
    effectiveType: connection.effectiveType,
    downlink: connection.downlink,
  }
}

export function onNetworkChange(callback: (online: boolean) => void): void {
  // ✅ Écouter les changements de connexion

  window.addEventListener('online', () => callback(true))
  window.addEventListener('offline', () => callback(false))
}
```

### 7. Utilisation dans les Composants Client

**`src/components/LocalStorageExample.tsx`**

```typescript
'use client'

import { useEffect, useState } from 'react'
import { LocalStorageManager } from '@/lib/client-only/storage'
import { copyToClipboard } from '@/lib/client-only/dom'

// ✅ Utiliser les client-only functions dans les composants

type UserPreferences = {
  theme: 'light' | 'dark'
  language: string
  notifications: boolean
};

export function PreferencesPanel() {
  const [prefs, setPrefs] = useState<UserPreferences>({
    theme: 'light',
    language: 'fr',
    notifications: true,
  })

  // ✅ Charger les préférences du localStorage au montage
  useEffect(() => {
    const saved = LocalStorageManager.get<UserPreferences>(
      'user-preferences'
    )

    if (saved) {
      setPrefs(saved)
    }
  }, [])

  // ✅ Sauvegarder au changement
  function handleThemeChange(theme: 'light' | 'dark') {
    const updated = { ...prefs, theme }
    setPrefs(updated)

    LocalStorageManager.set('user-preferences', updated, {
      ttl: 30 * 24 * 60 * 60 * 1000, // 30 jours
    })

    // Appliquer le thème
    document.documentElement.className = theme
  }

  async function handleCopyToken() {
    const token = LocalStorageManager.get<string>('auth-token')

    if (token) {
      const success = await copyToClipboard(token)

      if (success) {
        alert('Token copié!')
      }
    }
  }

  return (
    <div className="space-y-6">
      <div>
        <label className="block font-bold mb-2">Thème</label>
        <select
          value={prefs.theme}
          onChange={(e) =>
            handleThemeChange(e.target.value as 'light' | 'dark')
          }
          className="border rounded px-3 py-2"
        >
          <option value="light">Clair</option>
          <option value="dark">Sombre</option>
        </select>
      </div>

      <div>
        <label className="block font-bold mb-2">Langue</label>
        <select
          value={prefs.language}
          onChange={(e) => {
            const updated = { ...prefs, language: e.target.value }
            setPrefs(updated)
            LocalStorageManager.set('user-preferences', updated)
          }}
          className="border rounded px-3 py-2"
        >
          <option value="fr">Français</option>
          <option value="en">English</option>
        </select>
      </div>

      <button
        onClick={handleCopyToken}
        className="bg-blue-600 text-white px-4 py-2 rounded"
      >
        Copier le token
      </button>
    </div>
  )
}
```

**`src/components/NotificationManager.tsx`**

```typescript
'use client'

import { useEffect, useState } from 'react'
import {
  requestNotificationPermission,
  showNotification,
  onNetworkChange,
} from '@/lib/client-only/browser-features'

export function NotificationManager() {
  const [isOnline, setIsOnline] = useState(true)

  useEffect(() => {
    // ✅ Écouter les changements de connexion
    onNetworkChange((online) => {
      setIsOnline(online)

      if (online) {
        showNotification('Vous êtes en ligne')
      } else {
        showNotification('Vous êtes hors ligne')
      }
    })
  }, [])

  async function handleEnableNotifications() {
    const permission = await requestNotificationPermission()

    if (permission === 'granted') {
      showNotification('Notifications activées!', {
        body: 'Vous recevrez les notifications',
        badge: '/badge.png',
      })
    }
  }

  return (
    <div className="p-4 border rounded space-y-3">
      <div className="flex items-center gap-2">
        <div
          className={`w-3 h-3 rounded-full ${
            isOnline ? 'bg-green-500' : 'bg-red-500'
          }`}
        />
        <span>{isOnline ? 'En ligne' : 'Hors ligne'}</span>
      </div>

      <button
        onClick={handleEnableNotifications}
        className="bg-blue-600 text-white px-4 py-2 rounded"
      >
        Activer les notifications
      </button>
    </div>
  )
}
```

## Best Practices

### 1. Isolation Stricte

```typescript
// ✅ Bon: Marqué comme client-only
// src/lib/client-only/dom.ts
import 'client-only'

export function manipulateDOM() {
  document.body.innerHTML = '...'
}

// ✅ Mauvais: Pas de protection
export function riskyDOM() {
  // Peut être appelé côté serveur par erreur
  document.body.innerHTML = '...'
}
```

### 2. Gestion des Erreurs Browser

```typescript
// ✅ Bon: Vérifier la support du navigateur
if ('Notification' in window) {
  // Utiliser Notification API
}

// ✅ Mauvais: Assumer le support
Notification.requestPermission()
```

### 3. Cleanup et Mémoire

```typescript
useEffect(() => {
  // ✅ Bon: Cleanup les listeners
  const unsubscribe = watchMediaQuery('(prefers-dark-mode)', (isDark) => {
    // ...
  })

  return () => unsubscribe()
}, [])
```

## Avantages

- **Performance Optimale**: Opérations côté client rapides
- **APIs Natives**: Accès complet aux APIs du navigateur
- **Sécurité Garantie**: Impossible d'être exécuté côté serveur
- **User Experience**: Interactions fluides et responsives
- **Offline Ready**: Support du stockage persistant
