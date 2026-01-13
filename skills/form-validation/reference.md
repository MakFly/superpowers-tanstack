# Reference

# Form Validation avec TanStack Start

## Concept

La validation multi-niveaux assure la qualité et la sécurité des données. Elle combine validation client (UX) et serveur (sécurité).

## Architecture Validation

```
Input
    ↓
Client Validation (Temps réel)
    ├─ Invalide → Erreur immédiate
    └─ Valide → Submit
    ↓
Server Validation (Sécurité)
    ├─ Invalide → Erreur sécurisée
    └─ Valide → Traiter
```

## Patterns Complets

### 1. Validation Zod Complète

**`src/lib/validation.ts`**

```typescript
import { z } from 'zod'

// Validateurs réutilisables
const passwordValidator = z
  .string()
  .min(8, 'Minimum 8 caractères')
  .regex(/[A-Z]/, 'Une majuscule requise')
  .regex(/[0-9]/, 'Un chiffre requis')
  .regex(/[^a-zA-Z0-9]/, 'Un caractère spécial requis')

const emailValidator = z.string().email('Email invalide')

// Schémas pour différentes entités
export const LoginSchema = z.object({
  email: emailValidator,
  password: z.string().min(1, 'Mot de passe requis'),
  rememberMe: z.boolean().optional(),
})

export const SignupSchema = z
  .object({
    name: z
      .string()
      .min(2, 'Minimum 2 caractères')
      .max(100, 'Maximum 100 caractères'),
    email: emailValidator,
    password: passwordValidator,
    confirmPassword: z.string(),
    terms: z.boolean().refine((v) => v, {
      message: 'Vous devez accepter les conditions',
    }),
  })
  .refine((data) => data.password === data.confirmPassword, {
    message: 'Les mots de passe ne correspondent pas',
    path: ['confirmPassword'],
  })

export const ProfileSchema = z.object({
  name: z.string().min(1).max(100),
  bio: z.string().max(500).optional(),
  avatar: z.instanceof(File).optional(),
  website: z.string().url().optional().or(z.literal('')),
})

export const ProductSchema = z.object({
  name: z.string().min(1).max(200),
  description: z.string().min(10).max(2000),
  price: z.coerce.number().positive('Prix doit être positif'),
  stock: z.coerce.number().nonnegative(),
  category: z.enum(['electronics', 'books', 'clothing', 'other']),
  tags: z.array(z.string()).min(1, 'Au minimum un tag'),
})

export type LoginData = z.infer<typeof LoginSchema>
export type SignupData = z.infer<typeof SignupSchema>
export type ProfileData = z.infer<typeof ProfileSchema>
export type ProductData = z.infer<typeof ProductSchema>
```

### 2. Validation Client Temps Réel

**`src/routes/register.tsx`**

```typescript
import { createFileRoute } from '@tanstack/react-router'
import { SignupSchema, SignupData } from '@/lib/validation'
import { useState, useCallback } from 'react'
import { z } from 'zod'

export const Route = createFileRoute('/register')({
  component: RegisterPage,
})

function RegisterPage() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
    terms: false,
  })

  const [fieldErrors, setFieldErrors] = useState<Record<string, string>>({})
  const [touched, setTouched] = useState<Set<string>>(new Set())
  const [loading, setLoading] = useState(false)
  const [globalError, setGlobalError] = useState<string | null>(null)

  // ✅ Validation en temps réel avec debounce
  const validateField = useCallback(
    (fieldName: string, value: any) => {
      try {
        // Extraire le schéma du champ
        const fieldSchema = SignupSchema.pick({
          [fieldName]: true,
        })

        fieldSchema.parse({ [fieldName]: value })

        // Effacer l'erreur si valide
        setFieldErrors((prev) => {
          const newErrors = { ...prev }
          delete newErrors[fieldName]
          return newErrors
        })
      } catch (error) {
        if (error instanceof z.ZodError) {
          const message = error.errors[0]?.message || ''
          setFieldErrors((prev) => ({
            ...prev,
            [fieldName]: message,
          }))
        }
      }
    },
    []
  )

  const handleChange = (
    e: React.ChangeEvent<
      HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement
    >
  ) => {
    const { name, value, type } = e.currentTarget as HTMLInputElement

    const newValue = type === 'checkbox' ? (e.target as HTMLInputElement).checked : value

    setFormData((prev) => ({
      ...prev,
      [name]: newValue,
    }))

    // Valider après toucher le champ
    if (touched.has(name)) {
      validateField(name, newValue)
    }
  }

  const handleBlur = (e: React.FocusEvent<HTMLInputElement>) => {
    const { name } = e.target
    setTouched((prev) => new Set(prev).add(name))
    validateField(name, formData[name as keyof typeof formData])
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setGlobalError(null)

    try {
      // Validation complète
      const validated = SignupSchema.parse(formData)
      setLoading(true)

      // Soumettre au serveur
      const response = await fetch('/api/signup', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(validated),
      })

      if (!response.ok) {
        const error = await response.json()
        throw new Error(error.message)
      }

      // Succès
      window.location.href = '/dashboard'
    } catch (error) {
      if (error instanceof z.ZodError) {
        const newErrors: Record<string, string> = {}
        error.errors.forEach((err) => {
          const path = err.path[0] as string
          newErrors[path] = err.message
        })
        setFieldErrors(newErrors)
      } else {
        setGlobalError(
          error instanceof Error ? error.message : 'Erreur inconnue'
        )
      }
    } finally {
      setLoading(false)
    }
  }

  // Calculer si le formulaire est valide
  const isValid =
    Object.keys(fieldErrors).length === 0 &&
    formData.name &&
    formData.email &&
    formData.password &&
    formData.confirmPassword &&
    formData.terms

  return (
    <div className="max-w-md mx-auto py-8">
      <h1 className="text-4xl font-bold mb-8 text-center">Créer un compte</h1>

      {globalError && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded">
          <p className="text-red-800 font-bold">Erreur</p>
          <p className="text-red-700">{globalError}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6" noValidate>
        {/* Nom */}
        <div>
          <label className="block text-sm font-bold mb-2">Nom Complet</label>
          <input
            type="text"
            name="name"
            value={formData.name}
            onChange={handleChange}
            onBlur={handleBlur}
            disabled={loading}
            className={`w-full px-4 py-2 border rounded transition ${
              touched.has('name') && fieldErrors.name
                ? 'border-red-500 bg-red-50'
                : 'border-gray-300'
            }`}
          />
          {touched.has('name') && fieldErrors.name && (
            <p className="mt-1 text-sm text-red-600">{fieldErrors.name}</p>
          )}
        </div>

        {/* Email */}
        <div>
          <label className="block text-sm font-bold mb-2">Email</label>
          <input
            type="email"
            name="email"
            value={formData.email}
            onChange={handleChange}
            onBlur={handleBlur}
            disabled={loading}
            className={`w-full px-4 py-2 border rounded transition ${
              touched.has('email') && fieldErrors.email
                ? 'border-red-500 bg-red-50'
                : 'border-gray-300'
            }`}
          />
          {touched.has('email') && fieldErrors.email && (
            <p className="mt-1 text-sm text-red-600">{fieldErrors.email}</p>
          )}
        </div>

        {/* Mot de passe avec force indicator */}
        <div>
          <label className="block text-sm font-bold mb-2">Mot de passe</label>
          <input
            type="password"
            name="password"
            value={formData.password}
            onChange={handleChange}
            onBlur={handleBlur}
            disabled={loading}
            className={`w-full px-4 py-2 border rounded transition ${
              touched.has('password') && fieldErrors.password
                ? 'border-red-500 bg-red-50'
                : 'border-gray-300'
            }`}
          />

          {/* Indicateur de force */}
          {formData.password && (
            <PasswordStrengthMeter password={formData.password} />
          )}

          {touched.has('password') && fieldErrors.password && (
            <p className="mt-1 text-sm text-red-600">{fieldErrors.password}</p>
          )}
        </div>

        {/* Confirmer mot de passe */}
        <div>
          <label className="block text-sm font-bold mb-2">
            Confirmer mot de passe
          </label>
          <input
            type="password"
            name="confirmPassword"
            value={formData.confirmPassword}
            onChange={handleChange}
            onBlur={handleBlur}
            disabled={loading}
            className={`w-full px-4 py-2 border rounded transition ${
              touched.has('confirmPassword') && fieldErrors.confirmPassword
                ? 'border-red-500 bg-red-50'
                : 'border-gray-300'
            }`}
          />
          {touched.has('confirmPassword') && fieldErrors.confirmPassword && (
            <p className="mt-1 text-sm text-red-600">
              {fieldErrors.confirmPassword}
            </p>
          )}
        </div>

        {/* Terms */}
        <div>
          <label className="flex items-center gap-2">
            <input
              type="checkbox"
              name="terms"
              checked={formData.terms}
              onChange={handleChange}
              onBlur={handleBlur}
              disabled={loading}
            />
            <span className="text-sm">
              J'accepte les{' '}
              <a href="/terms" className="text-blue-600 hover:underline">
                conditions d'utilisation
              </a>
            </span>
          </label>
          {touched.has('terms') && fieldErrors.terms && (
            <p className="mt-1 text-sm text-red-600">{fieldErrors.terms}</p>
          )}
        </div>

        {/* Submit */}
        <button
          type="submit"
          disabled={!isValid || loading}
          className="w-full bg-blue-600 text-white py-3 rounded font-bold hover:bg-blue-700 disabled:opacity-50 disabled:cursor-not-allowed transition"
        >
          {loading ? 'Création...' : 'Créer un compte'}
        </button>
      </form>

      <p className="text-center mt-6 text-gray-600">
        Déjà un compte?{' '}
        <a href="/login" className="text-blue-600 hover:text-blue-800">
          Se connecter
        </a>
      </p>
    </div>
  )
}

function PasswordStrengthMeter({ password }: { password: string }) {
  const strength = calculatePasswordStrength(password)

  const colors = {
    weak: 'bg-red-500',
    medium: 'bg-yellow-500',
    strong: 'bg-green-500',
  }

  return (
    <div className="mt-2">
      <div className="flex gap-1 mb-2">
        {[1, 2, 3].map((i) => (
          <div
            key={i}
            className={`flex-1 h-2 rounded ${
              i <= strength ? colors[strength as keyof typeof colors] : 'bg-gray-200'
            }`}
          ></div>
        ))}
      </div>
      <p className="text-xs text-gray-600">
        Force du mot de passe:{' '}
        <span className="font-bold">
          {strength === 'weak'
            ? 'Faible'
            : strength === 'medium'
              ? 'Moyen'
              : 'Fort'}
        </span>
      </p>
    </div>
  )
}

function calculatePasswordStrength(
  password: string
): 'weak' | 'medium' | 'strong' {
  let score = 0

  if (password.length >= 8) score++
  if (password.length >= 12) score++
  if (/[A-Z]/.test(password)) score++
  if (/[a-z]/.test(password)) score++
  if (/[0-9]/.test(password)) score++
  if (/[^a-zA-Z0-9]/.test(password)) score++

  if (score <= 2) return 'weak'
  if (score <= 4) return 'medium'
  return 'strong'
}
```

### 3. Validation Serveur Sécurisée

**`src/lib/api.ts`**

```typescript
import { createServerFn } from '@tanstack/start'
import { SignupSchema, LoginSchema, ProfileSchema } from '@/lib/validation'
import { z } from 'zod'

// ✅ Validation au niveau serveur
export const validateSignup = createServerFn('POST', async (data: unknown) => {
  try {
    // Valider strictement côté serveur
    const validated = SignupSchema.parse(data)

    // Vérifications supplémentaires côté serveur
    const existingUser = await checkUserExists(validated.email)
    if (existingUser) {
      throw new Error('Cet email est déjà utilisé')
    }

    // Vérifier rate limiting
    const isRateLimited = await checkRateLimit(
      'signup',
      getClientIP(),
      5,
      3600
    )
    if (isRateLimited) {
      throw new Error('Trop de tentatives. Réessayez plus tard.')
    }

    // Créer l'utilisateur
    const user = await createUser(validated)

    return { success: true, userId: user.id }
  } catch (error) {
    if (error instanceof z.ZodError) {
      const message = error.errors
        .map((e) => `${e.path.join('.')}: ${e.message}`)
        .join('; ')
      throw new Error(`Validation failed: ${message}`)
    }
    throw error
  }
})

export const validateProfile = createServerFn('PUT', async (data: unknown) => {
  try {
    const validated = ProfileSchema.parse(data)

    // Vérifications supplémentaires
    if (validated.avatar && validated.avatar.size > 5 * 1024 * 1024) {
      throw new Error('Image doit être < 5MB')
    }

    const updated = await updateUserProfile(validated)
    return { success: true, user: updated }
  } catch (error) {
    if (error instanceof z.ZodError) {
      throw new Error('Validation failed')
    }
    throw error
  }
})

// Fonctions helper
async function checkUserExists(email: string): Promise<boolean> {
  // Vérifier en base de données
  return false
}

async function checkRateLimit(
  action: string,
  identifier: string,
  limit: number,
  window: number
): Promise<boolean> {
  // Vérifier rate limit
  return false
}

function getClientIP(): string {
  // Extraire IP du client
  return '127.0.0.1'
}

async function createUser(data: any) {
  // Créer en base de données
  return { id: '1', ...data }
}

async function updateUserProfile(data: any) {
  // Mettre à jour en base de données
  return data
}
```

### 4. Validateurs Personnalisés

**`src/lib/customValidators.ts`**

```typescript
import { z } from 'zod'

// ✅ Validateurs réutilisables personnalisés
export const validators = {
  // Téléphone français
  phoneNumber: z
    .string()
    .regex(/^(\+33|0)[0-9]{9}$/, 'Numéro français invalide'),

  // Code postal
  zipCode: z
    .string()
    .regex(/^[0-9]{5}$/, 'Code postal invalide (5 chiffres)'),

  // SIRET
  siret: z
    .string()
    .regex(/^[0-9]{14}$/, 'SIRET invalide (14 chiffres)'),

  // Slug (pour URLs)
  slug: z
    .string()
    .regex(/^[a-z0-9]+(?:-[a-z0-9]+)*$/, 'Slug invalide'),

  // URL de site web
  websiteUrl: z.string().url().refine((url) => {
    try {
      const urlObj = new URL(url)
      return !['localhost', '127.0.0.1'].includes(urlObj.hostname)
    } catch {
      return false
    }
  }, 'URL invalide'),

  // Fichier image
  imageFile: z.instanceof(File).refine(
    (file) => ['image/jpeg', 'image/png', 'image/webp'].includes(file.type),
    'Format image invalide (JPEG, PNG, WEBP)'
  ),

  // Pas de profanité (simple)
  noProfanity: z.string().refine(
    (text) => !['bad', 'words'].some((word) => text.toLowerCase().includes(word)),
    'Contenu non autorisé'
  ),
}

// Schémas utilisant les validateurs
export const CompanySchema = z.object({
  name: z.string().min(2),
  phone: validators.phoneNumber,
  zipCode: validators.zipCode,
  siret: validators.siret,
  website: validators.websiteUrl.optional(),
})

export const BlogPostSchema = z.object({
  title: z.string().min(5).max(200),
  slug: validators.slug,
  content: validators.noProfanity.pipe(z.string().min(100)),
  image: validators.imageFile.optional(),
})
```

## Best Practices

### 1. Validation Progressive

```typescript
// ✅ Valider progressivement
const handleChange = (field: string, value: any) => {
  setData({ ...data, [field]: value })

  if (touched.has(field)) {
    // Valider après touched
    validateField(field, value)
  }
}
```

### 2. Messages d'Erreur Clairs

```typescript
// ✅ Messages en français, contextualisés
const messages = {
  'email-invalid': 'Veuillez entrer une adresse email valide',
  'password-weak': 'Le mot de passe doit contenir au moins 8 caractères',
  'terms-required': 'Vous devez accepter les conditions',
}
```

### 3. Validation Asynchrone

```typescript
// ✅ Valider avec appel serveur
const emailSchema = z.string().email().refine(
  async (email) => {
    const exists = await checkEmailExists(email)
    return !exists
  },
  'Cet email est déjà utilisé'
)
```

## Avantages

- **Type Safe**: Partagé client/serveur
- **Granulaire**: Validation par champ et globale
- **Flexible**: Zod ou custom validators
- **Sécurisé**: Validation doublée côté serveur
- **UX Optimale**: Feedback temps réel
