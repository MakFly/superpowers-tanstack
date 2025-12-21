---
name: tanstack:isomorphic-fns
description: Build isomorphic functions that run correctly on both server and client
---

# Isomorphic Functions

## Concept

Les Isomorphic Functions sont des fonctions qui s'exécutent correctement sur BOTH serveur ET client. Elles contiennent la logique métier partagée qui n'a pas besoin des APIs spécifiques au serveur ou au client.

## Architecture

```
Shared Logic (Server & Client)
├── Validation
├── Calculations
├── Transformations
├── Type Utilities
└── Constants

Used By:
├── Server Functions ('use server')
├── Client Components ('use client')
└── Route Handlers (API routes)
```

## Implémentation Détaillée

### 1. Validation et Schemas

**`src/lib/isomorphic/validation.ts`**

```typescript
// ✅ Ce fichier s'exécute PARTOUT (serveur et client)
// ✅ Pas de 'use server' ni 'use client'
// ✅ Pas d'imports de APIs serveur ou client

export type ValidationResult<T> = {
  valid: boolean;
  data?: T;
  errors: Record<string, string>;
};

export type ValidationSchema<T> = {
  validate(data: unknown): ValidationResult<T>;
};

// ✅ Validateur email isomorphe
export const emailValidator = {
  validate(email: unknown): ValidationResult<string> {
    const errors: Record<string, string> = {}

    if (typeof email !== 'string') {
      errors.email = 'Email doit être une chaîne'
      return { valid: false, errors }
    }

    if (email.length === 0) {
      errors.email = 'Email est requis'
      return { valid: false, errors }
    }

    if (email.length > 255) {
      errors.email = 'Email doit contenir moins de 255 caractères'
      return { valid: false, errors }
    }

    // Regex simple pour la validation email
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/

    if (!emailRegex.test(email)) {
      errors.email = 'Email invalide'
      return { valid: false, errors }
    }

    return {
      valid: true,
      data: email,
      errors: {},
    }
  },
}

// ✅ Validateur de mot de passe isomorphe
export const passwordValidator = {
  validate(password: unknown): ValidationResult<string> {
    const errors: Record<string, string> = {}

    if (typeof password !== 'string') {
      errors.password = 'Le mot de passe doit être une chaîne'
      return { valid: false, errors }
    }

    if (password.length < 8) {
      errors.password = 'Le mot de passe doit contenir au moins 8 caractères'
      return { valid: false, errors }
    }

    if (!/[A-Z]/.test(password)) {
      errors.password =
        'Le mot de passe doit contenir au moins une majuscule'
      return { valid: false, errors }
    }

    if (!/[0-9]/.test(password)) {
      errors.password = 'Le mot de passe doit contenir au moins un chiffre'
      return { valid: false, errors }
    }

    if (!/[!@#$%^&*]/.test(password)) {
      errors.password =
        'Le mot de passe doit contenir au moins un caractère spécial'
      return { valid: false, errors }
    }

    return {
      valid: true,
      data: password,
      errors: {},
    }
  },
}

// ✅ Validateur de profil isomorphe
export type UserProfile = {
  name: string;
  email: string;
  bio: string;
};

export const userProfileValidator: ValidationSchema<UserProfile> = {
  validate(data: unknown): ValidationResult<UserProfile> {
    const errors: Record<string, string> = {}

    if (typeof data !== 'object' || data === null) {
      errors.root = 'Data doit être un objet'
      return { valid: false, errors }
    }

    const obj = data as Record<string, unknown>

    // Valider le nom
    if (typeof obj.name !== 'string') {
      errors.name = 'Le nom doit être une chaîne'
    } else if (obj.name.length < 2) {
      errors.name = 'Le nom doit contenir au moins 2 caractères'
    } else if (obj.name.length > 100) {
      errors.name = 'Le nom ne peut pas dépasser 100 caractères'
    }

    // Valider l'email
    const emailValidation = emailValidator.validate(obj.email)
    if (!emailValidation.valid) {
      errors.email = emailValidation.errors.email || 'Email invalide'
    }

    // Valider la bio
    if (obj.bio) {
      if (typeof obj.bio !== 'string') {
        errors.bio = 'La bio doit être une chaîne'
      } else if (obj.bio.length > 500) {
        errors.bio = 'La bio ne peut pas dépasser 500 caractères'
      }
    }

    if (Object.keys(errors).length > 0) {
      return { valid: false, errors }
    }

    return {
      valid: true,
      data: {
        name: obj.name as string,
        email: obj.email as string,
        bio: (obj.bio as string) || '',
      },
      errors: {},
    }
  },
}
```

### 2. Types et Interfaces Partagés

**`src/lib/isomorphic/types.ts`**

```typescript
// ✅ Types et interfaces partagés entre serveur et client

export type User = {
  id: string;
  name: string;
  email: string;
  role: 'admin' | 'user' | 'moderator';
  createdAt: Date;
};

export type Post = {
  id: string;
  title: string;
  content: string;
  authorId: string;
  publishedAt: Date;
  viewCount: number;
  likeCount: number;
};

export type Comment = {
  id: string;
  postId: string;
  authorId: string;
  content: string;
  createdAt: Date;
};

export type ApiResponse<T> = {
  success: boolean;
  data?: T;
  error?: string;
  timestamp: number;
};

export type PaginatedResponse<T> = {
  items: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
};

export type SortOrder = 'asc' | 'desc';

export type SortOptions = {
  field: string;
  order: SortOrder;
};

export type FilterOptions = {
  search?: string;
  category?: string;
  status?: string;
  dateFrom?: Date;
  dateTo?: Date;
};

export type QueryOptions = {
  page: number;
  pageSize: number;
  sort?: SortOptions;
  filters?: FilterOptions;
};

export enum RequestStatus {
  Idle = 'idle',
  Loading = 'loading',
  Success = 'success',
  Error = 'error',
}
```

### 3. Utilitaires Mathématiques et Transformations

**`src/lib/isomorphic/utils.ts`**

```typescript
// ✅ Utilitaires isomorphes pour calculs et transformations

export function formatDate(date: Date, locale: string = 'fr-FR'): string {
  return new Intl.DateTimeFormat(locale, {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
  }).format(date)
}

export function formatCurrency(
  amount: number,
  currency: string = 'EUR',
  locale: string = 'fr-FR'
): string {
  return new Intl.NumberFormat(locale, {
    style: 'currency',
    currency,
  }).format(amount)
}

export function truncate(text: string, maxLength: number): string {
  if (text.length <= maxLength) {
    return text
  }
  return text.slice(0, maxLength) + '...'
}

export function slug(text: string): string {
  // ✅ Générer un slug isomorphe

  return text
    .toLowerCase()
    .trim()
    .replace(/[^\w\s-]/g, '') // Supprimer les caractères spéciaux
    .replace(/[\s_-]+/g, '-') // Remplacer les espaces par des tirets
    .replace(/^-+|-+$/g, '') // Supprimer les tirets au début/fin
}

export function capitalize(text: string): string {
  if (!text) return text
  return text.charAt(0).toUpperCase() + text.slice(1).toLowerCase()
}

export function groupBy<T, K extends string | number | symbol>(
  array: T[],
  keyFn: (item: T) => K
): Record<K, T[]> {
  // ✅ Grouper un tableau par clé isomorphe

  return array.reduce(
    (acc, item) => {
      const key = keyFn(item)
      if (!acc[key]) {
        acc[key] = []
      }
      acc[key].push(item)
      return acc
    },
    {} as Record<K, T[]>
  )
}

export function chunk<T>(array: T[], size: number): T[][] {
  // ✅ Diviser un tableau en chunks

  const result: T[][] = []
  for (let i = 0; i < array.length; i += size) {
    result.push(array.slice(i, i + size))
  }
  return result
}

export function flatten<T>(
  array: (T | T[])[]
): T[] {
  // ✅ Aplatir un tableau

  return array.reduce((acc, item) => {
    if (Array.isArray(item)) {
      acc.push(...item)
    } else {
      acc.push(item)
    }
    return acc
  }, [] as T[])
}

export function unique<T>(
  array: T[],
  keyFn?: (item: T) => any
): T[] {
  // ✅ Obtenir les éléments uniques

  if (!keyFn) {
    return Array.from(new Set(array))
  }

  const seen = new Set()
  return array.filter((item) => {
    const key = keyFn(item)
    if (seen.has(key)) {
      return false
    }
    seen.add(key)
    return true
  })
}

export function sum(array: number[]): number {
  // ✅ Calculer la somme

  return array.reduce((acc, num) => acc + num, 0)
}

export function average(array: number[]): number {
  // ✅ Calculer la moyenne

  if (array.length === 0) return 0
  return sum(array) / array.length
}

export function calculateDiscount(
  price: number,
  discountPercent: number
): number {
  // ✅ Calculer le prix après réduction

  return price * (1 - discountPercent / 100)
}

export function calculateTax(
  amount: number,
  taxRate: number
): number {
  // ✅ Calculer les taxes

  return amount * (taxRate / 100)
}

export function calculateShippingCost(
  distance: number,
  baseRate: number = 5
): number {
  // ✅ Calculer les frais d'expédition

  const perKm = 0.5
  return baseRate + distance * perKm
}
```

### 4. Parsers et Formatters

**`src/lib/isomorphic/parsers.ts`**

```typescript
// ✅ Parsers isomorphes pour différents formats

export function parseJSON<T = unknown>(
  json: string,
  defaultValue?: T
): T | undefined {
  // ✅ Parser JSON avec fallback

  try {
    return JSON.parse(json)
  } catch {
    return defaultValue
  }
}

export function parseQueryString(
  queryString: string
): Record<string, string | string[]> {
  // ✅ Parser une query string

  const params = new URLSearchParams(queryString)
  const result: Record<string, string | string[]> = {}

  params.forEach((value, key) => {
    if (result[key]) {
      // Clé déjà existante
      if (Array.isArray(result[key])) {
        (result[key] as string[]).push(value)
      } else {
        result[key] = [result[key] as string, value]
      }
    } else {
      result[key] = value
    }
  })

  return result
}

export function stringifyQueryString(
  params: Record<string, string | number | boolean | undefined>
): string {
  // ✅ Créer une query string

  const searchParams = new URLSearchParams()

  Object.entries(params).forEach(([key, value]) => {
    if (value !== undefined && value !== null && value !== '') {
      searchParams.append(key, String(value))
    }
  })

  return searchParams.toString()
}

export function parseCSV(csvContent: string): Record<string, string>[] {
  // ✅ Parser du CSV simple

  const lines = csvContent.trim().split('\n')

  if (lines.length === 0) return []

  const headers = lines[0].split(',').map((h) => h.trim())

  return lines.slice(1).map((line) => {
    const values = line.split(',').map((v) => v.trim())
    return headers.reduce(
      (acc, header, index) => {
        acc[header] = values[index] || ''
        return acc
      },
      {} as Record<string, string>
    )
  })
}

export function formatCSV(
  data: Record<string, string | number>[],
  headers?: string[]
): string {
  // ✅ Formater en CSV

  if (data.length === 0) return ''

  const keys = headers || Object.keys(data[0])

  const csv = [
    keys.join(','),
    ...data.map((row) =>
      keys
        .map((key) => {
          const value = row[key]
          // Échapper les guillemets et espaces
          if (typeof value === 'string' && (value.includes(',') || value.includes('"'))) {
            return `"${value.replace(/"/g, '""')}"`
          }
          return value
        })
        .join(',')
    ),
  ]

  return csv.join('\n')
}
```

### 5. Enums et Constants Partagés

**`src/lib/isomorphic/constants.ts`**

```typescript
// ✅ Constantes partagées entre serveur et client

export const PAGINATION_DEFAULTS = {
  PAGE_SIZE: 20,
  MAX_PAGE_SIZE: 100,
  MIN_PAGE_SIZE: 1,
} as const

export const VALIDATION_RULES = {
  USERNAME_MIN_LENGTH: 3,
  USERNAME_MAX_LENGTH: 20,
  PASSWORD_MIN_LENGTH: 8,
  BIO_MAX_LENGTH: 500,
  TITLE_MAX_LENGTH: 200,
  CONTENT_MAX_LENGTH: 10000,
} as const

export const HTTP_STATUS = {
  OK: 200,
  CREATED: 201,
  BAD_REQUEST: 400,
  UNAUTHORIZED: 401,
  FORBIDDEN: 403,
  NOT_FOUND: 404,
  CONFLICT: 409,
  INTERNAL_SERVER_ERROR: 500,
} as const

export const ERROR_MESSAGES = {
  AUTHENTICATION_REQUIRED: 'Vous devez être authentifié',
  AUTHORIZATION_REQUIRED: 'Vous n\'avez pas la permission',
  RESOURCE_NOT_FOUND: 'Ressource non trouvée',
  INVALID_INPUT: 'Données invalides',
  INTERNAL_ERROR: 'Erreur interne du serveur',
  NETWORK_ERROR: 'Erreur réseau',
} as const

export const ROUTES = {
  HOME: '/',
  LOGIN: '/login',
  SIGNUP: '/signup',
  DASHBOARD: '/dashboard',
  PROFILE: '/profile',
  SETTINGS: '/settings',
} as const

export const CURRENCY_CODES = ['USD', 'EUR', 'GBP', 'JPY'] as const

export const LANGUAGES = {
  FR: 'fr',
  EN: 'en',
  ES: 'es',
  DE: 'de',
} as const
```

### 6. Classe Isomorphe: Result Type

**`src/lib/isomorphic/result.ts`**

```typescript
// ✅ Classe Result isomorphe pour meilleure gestion des erreurs

export class Result<T, E = Error> {
  private constructor(
    private readonly _value?: T,
    private readonly _error?: E
  ) {}

  static ok<T>(value: T): Result<T> {
    return new Result(value, undefined)
  }

  static err<E>(error: E): Result<never, E> {
    return new Result(undefined, error)
  }

  isOk(): this is Result<T> {
    return this._error === undefined
  }

  isErr(): this is Result<never, E> {
    return this._error !== undefined
  }

  unwrap(): T {
    if (this.isErr()) {
      throw new Error(`Called unwrap on an error value: ${this._error}`)
    }
    return this._value!
  }

  unwrapOr(defaultValue: T): T {
    return this.isOk() ? this._value! : defaultValue
  }

  map<U>(fn: (value: T) => U): Result<U, E> {
    if (this.isErr()) {
      return Result.err(this._error)
    }
    return Result.ok(fn(this._value!))
  }

  mapErr<F>(fn: (error: E) => F): Result<T, F> {
    if (this.isOk()) {
      return Result.ok(this._value!)
    }
    return Result.err(fn(this._error))
  }

  flatMap<U>(fn: (value: T) => Result<U, E>): Result<U, E> {
    if (this.isErr()) {
      return Result.err(this._error)
    }
    return fn(this._value!)
  }

  getOrNull(): T | null {
    return this.isOk() ? this._value! : null
  }

  getErrorOrNull(): E | null {
    return this.isErr() ? this._error : null
  }
}

// ✅ Exemple d'utilisation isomorphe
export function parseUserInput(input: string): Result<number, string> {
  try {
    const num = parseInt(input, 10)
    if (isNaN(num)) {
      return Result.err('Input is not a valid number')
    }
    return Result.ok(num)
  } catch (error) {
    return Result.err('Failed to parse input')
  }
}
```

### 7. Utilisation dans Server Actions et Client

**`src/app/actions.ts`**

```typescript
'use server'

import {
  userProfileValidator,
  emailValidator,
} from '@/lib/isomorphic/validation'
import { slug } from '@/lib/isomorphic/utils'
import { formatDate } from '@/lib/isomorphic/utils'
import { VALIDATION_RULES } from '@/lib/isomorphic/constants'
import { parseUserInput, Result } from '@/lib/isomorphic/result'

// ✅ Utiliser la validation isomorphe côté serveur

export async function createUserAction(data: unknown) {
  // Valider avec la validation isomorphe
  const validation = userProfileValidator.validate(data)

  if (!validation.valid) {
    throw new Error(JSON.stringify(validation.errors))
  }

  const validData = validation.data!

  // Créer le slug
  const slug_ = slug(validData.name)

  // Formater la date
  const created = formatDate(new Date())

  return {
    success: true,
    user: {
      ...validData,
      slug: slug_,
      created,
    },
  }
}

export async function validateEmailAction(email: string) {
  // ✅ Validation isomorphe côté serveur
  const result = emailValidator.validate(email)

  if (!result.valid) {
    return { valid: false, errors: result.errors }
  }

  return { valid: true, email: result.data }
}
```

**`src/components/ProfileForm.tsx`**

```typescript
'use client'

import { useState } from 'react'
import {
  userProfileValidator,
  emailValidator,
} from '@/lib/isomorphic/validation'
import { VALIDATION_RULES } from '@/lib/isomorphic/constants'
import { createUserAction } from '@/app/actions'

// ✅ Utiliser la validation isomorphe côté client

export function ProfileForm() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    bio: '',
  })
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [isLoading, setIsLoading] = useState(false)

  function handleChange(field: string, value: string) {
    setFormData((prev) => ({ ...prev, [field]: value }))

    // ✅ Validation isomorphe en temps réel côté client
    if (field === 'email') {
      const validation = emailValidator.validate(value)
      setErrors((prev) => ({
        ...prev,
        email: validation.valid ? '' : validation.errors.email || '',
      }))
    }
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()

    // ✅ Validation isomorphe avant d'envoyer au serveur
    const validation = userProfileValidator.validate(formData)

    if (!validation.valid) {
      setErrors(validation.errors)
      return
    }

    setIsLoading(true)

    try {
      const result = await createUserAction(formData)
      alert('Profil créé avec succès!')
      setFormData({ name: '', email: '', bio: '' })
      setErrors({})
    } catch (error) {
      const err =
        error instanceof Error ? JSON.parse(error.message) : {}
      setErrors(err)
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6 max-w-2xl">
      <div>
        <label className="block text-sm font-bold mb-2">Nom</label>
        <input
          type="text"
          value={formData.name}
          onChange={(e) => handleChange('name', e.target.value)}
          maxLength={VALIDATION_RULES.USERNAME_MAX_LENGTH}
          className="w-full border rounded px-3 py-2"
          disabled={isLoading}
        />
        {errors.name && (
          <p className="text-red-600 text-sm mt-1">{errors.name}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-bold mb-2">Email</label>
        <input
          type="email"
          value={formData.email}
          onChange={(e) => handleChange('email', e.target.value)}
          className="w-full border rounded px-3 py-2"
          disabled={isLoading}
        />
        {errors.email && (
          <p className="text-red-600 text-sm mt-1">{errors.email}</p>
        )}
      </div>

      <div>
        <label className="block text-sm font-bold mb-2">Bio</label>
        <textarea
          value={formData.bio}
          onChange={(e) => handleChange('bio', e.target.value)}
          maxLength={VALIDATION_RULES.BIO_MAX_LENGTH}
          className="w-full border rounded px-3 py-2 h-32"
          disabled={isLoading}
        />
        <p className="text-xs text-gray-500 mt-1">
          {formData.bio.length}/{VALIDATION_RULES.BIO_MAX_LENGTH}
        </p>
        {errors.bio && (
          <p className="text-red-600 text-sm mt-1">{errors.bio}</p>
        )}
      </div>

      <button
        type="submit"
        disabled={isLoading}
        className="bg-blue-600 text-white px-6 py-2 rounded font-bold hover:bg-blue-700 disabled:opacity-50"
      >
        {isLoading ? 'Création...' : 'Créer le profil'}
      </button>
    </form>
  )
}
```

## Patterns Isomorphes Avancés

### 1. Validation Schema Partagée

```typescript
// ✅ Schema validé PARTOUT avec les mêmes règles
const userSchema = userProfileValidator

// Côté serveur
export async function updateUser(data: unknown) {
  const result = userSchema.validate(data)
  if (!result.valid) throw new Error('Invalid')
  // ...
}

// Côté client
function validateInput(data: unknown) {
  const result = userSchema.validate(data)
  // ...
}
```

### 2. Types Partagés avec Runtime Safety

```typescript
// ✅ Types TypeScript ET validation runtime
import { User } from '@/lib/isomorphic/types'

export function isUser(data: unknown): data is User {
  // Vérifier que data correspond au type User
  return (
    typeof data === 'object' &&
    data !== null &&
    'id' in data &&
    'email' in data
  )
}
```

## Best Practices

### 1. Aucune Dépendance Plateforme

```typescript
// ✅ Bon: Pure isomorphe
export function calculateTotal(items: number[]): number {
  return items.reduce((a, b) => a + b, 0)
}

// ✅ Mauvais: Dépend du navigateur
export function getLocalStorage(key: string): string {
  return localStorage.getItem(key) || ''
}
```

### 2. Type Safety Complète

```typescript
// ✅ Exporter les types aussi
export type UserInput = {
  name: string;
  email: string;
};

// ✅ Valider les types
export function validateUser(data: unknown): data is UserInput {
  // ...
}
```

### 3. Pas de Side Effects

```typescript
// ✅ Bon: Pure function
export function formatPrice(price: number): string {
  return `$${price.toFixed(2)}`
}

// ✅ Mauvais: Side effect
export function formatAndLog(price: number): string {
  console.log(price) // Side effect!
  return `$${price.toFixed(2)}`
}
```

## Avantages

- **DRY Code**: Pas de duplication entre serveur et client
- **Type Safety**: Une source unique de vérité
- **Performance**: Validation côté client avant envoi
- **Cohérence**: Mêmes règles partout
- **Testabilité**: Facile à tester en isolation
