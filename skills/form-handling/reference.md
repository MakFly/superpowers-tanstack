# Reference

# Form Handling avec TanStack Start

## Concept

Les formes avec TanStack Start intègrent la validation client et serveur, la gestion d'erreurs, et le chargement optimiste.

## Architecture Formes

```
User Input
    ↓
Client Validation
    ├─ Erreur → Afficher erreur
    └─ Valide → Submit
    ↓
Server Mutation
    ├─ Erreur serveur → Afficher erreur
    └─ Succès → Rediriger/Réafficher
```

## Patterns Complets

### 1. Native Form avec Server Functions

**`src/routes/contact.tsx`**

```typescript
import { createFileRoute } from '@tanstack/react-router'
import { createServerFn } from '@tanstack/start'
import { useState } from 'react'

// ✅ Server function pour gérer la soumission
const submitContactForm = createServerFn('POST', async (data: {
  name: string
  email: string
  message: string
}) => {
  // Valider côté serveur
  if (!data.name || !data.email || !data.message) {
    throw new Error('Tous les champs sont requis')
  }

  if (!data.email.includes('@')) {
    throw new Error('Email invalide')
  }

  // Envoyer l'email
  try {
    // Simulation d'envoi
    await new Promise((resolve) => setTimeout(resolve, 1000))

    return {
      success: true,
      message: 'Message reçu avec succès!',
    }
  } catch (error) {
    throw new Error('Erreur lors de l\'envoi du message')
  }
})

export const Route = createFileRoute('/contact')({
  component: ContactPage,
})

function ContactPage() {
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    message: '',
  })
  const [loading, setLoading] = useState(false)
  const [success, setSuccess] = useState(false)
  const [error, setError] = useState<string | null>(null)

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    setError(null)

    try {
      const result = await submitContactForm(formData)
      setSuccess(true)
      setFormData({ name: '', email: '', message: '' })
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto py-8">
      <h1 className="text-4xl font-bold mb-8">Nous Contacter</h1>

      {success && (
        <div className="mb-6 p-4 bg-green-50 border border-green-200 rounded">
          <p className="text-green-800">Message envoyé avec succès!</p>
        </div>
      )}

      {error && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded">
          <p className="text-red-800">{error}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <div>
          <label className="block text-sm font-bold mb-2">Nom</label>
          <input
            type="text"
            value={formData.name}
            onChange={(e) =>
              setFormData({ ...formData, name: e.target.value })
            }
            required
            className="w-full px-4 py-2 border rounded"
            disabled={loading}
          />
        </div>

        <div>
          <label className="block text-sm font-bold mb-2">Email</label>
          <input
            type="email"
            value={formData.email}
            onChange={(e) =>
              setFormData({ ...formData, email: e.target.value })
            }
            required
            className="w-full px-4 py-2 border rounded"
            disabled={loading}
          />
        </div>

        <div>
          <label className="block text-sm font-bold mb-2">Message</label>
          <textarea
            value={formData.message}
            onChange={(e) =>
              setFormData({ ...formData, message: e.target.value })
            }
            required
            rows={6}
            className="w-full px-4 py-2 border rounded"
            disabled={loading}
          />
        </div>

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-blue-600 text-white py-3 rounded font-bold hover:bg-blue-700 disabled:opacity-50"
        >
          {loading ? 'Envoi en cours...' : 'Envoyer'}
        </button>
      </form>
    </div>
  )
}
```

### 2. Form avec Validation Zod

**`src/routes/signup.tsx`**

```typescript
import { createFileRoute, useNavigate } from '@tanstack/react-router'
import { createServerFn } from '@tanstack/start'
import { z } from 'zod'
import { useState } from 'react'

// ✅ Schéma Zod partagé client/serveur
const SignupSchema = z.object({
  name: z.string().min(2, 'Minimum 2 caractères'),
  email: z.string().email('Email invalide'),
  password: z.string().min(8, 'Minimum 8 caractères'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: 'Les mots de passe ne correspondent pas',
  path: ['confirmPassword'],
})

type SignupData = z.infer<typeof SignupSchema>

const signupUser = createServerFn('POST', async (data: SignupData) => {
  // Valider avec Zod côté serveur
  const validated = SignupSchema.parse(data)

  // Vérifier email unique
  const existing = await checkEmailExists(validated.email)
  if (existing) {
    throw new Error('Cet email est déjà utilisé')
  }

  // Créer l'utilisateur
  const user = await createUser({
    name: validated.name,
    email: validated.email,
    password: validated.password,
  })

  return { userId: user.id }
})

async function checkEmailExists(email: string): Promise<boolean> {
  // Vérifier en base de données
  return false
}

async function createUser(data: any): Promise<{ id: string }> {
  // Créer en base de données
  return { id: '1' }
}

export const Route = createFileRoute('/signup')({
  component: SignupPage,
})

function SignupPage() {
  const navigate = useNavigate()
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    password: '',
    confirmPassword: '',
  })
  const [errors, setErrors] = useState<Record<string, string>>({})
  const [loading, setLoading] = useState(false)

  const validateField = (name: string, value: string) => {
    try {
      // Valider un champ spécifique
      const field = SignupSchema.shape[name as keyof typeof SignupSchema.shape]
      if (field) {
        field.parse(value)
        setErrors({ ...errors, [name]: '' })
      }
    } catch (error) {
      if (error instanceof z.ZodError) {
        setErrors({
          ...errors,
          [name]: error.errors[0]?.message || '',
        })
      }
    }
  }

  const handleChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target
    setFormData({ ...formData, [name]: value })
    validateField(name, value)
  }

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    try {
      // Valider tout le formulaire
      const validated = SignupSchema.parse(formData)
      setLoading(true)

      const result = await signupUser(validated)
      await navigate({ to: '/dashboard' })
    } catch (error) {
      if (error instanceof z.ZodError) {
        const newErrors: Record<string, string> = {}
        error.errors.forEach((err) => {
          const path = err.path[0] as string
          newErrors[path] = err.message
        })
        setErrors(newErrors)
      } else {
        setErrors({ form: error instanceof Error ? error.message : 'Erreur' })
      }
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-md mx-auto py-8">
      <h1 className="text-4xl font-bold mb-8 text-center">Créer un compte</h1>

      {errors.form && (
        <div className="mb-6 p-4 bg-red-50 border border-red-200 rounded">
          <p className="text-red-800">{errors.form}</p>
        </div>
      )}

      <form onSubmit={handleSubmit} className="space-y-6">
        <FormField
          label="Nom"
          name="name"
          value={formData.name}
          error={errors.name}
          onChange={handleChange}
          disabled={loading}
        />

        <FormField
          label="Email"
          name="email"
          type="email"
          value={formData.email}
          error={errors.email}
          onChange={handleChange}
          disabled={loading}
        />

        <FormField
          label="Mot de passe"
          name="password"
          type="password"
          value={formData.password}
          error={errors.password}
          onChange={handleChange}
          disabled={loading}
        />

        <FormField
          label="Confirmer mot de passe"
          name="confirmPassword"
          type="password"
          value={formData.confirmPassword}
          error={errors.confirmPassword}
          onChange={handleChange}
          disabled={loading}
        />

        <button
          type="submit"
          disabled={loading}
          className="w-full bg-blue-600 text-white py-3 rounded font-bold hover:bg-blue-700 disabled:opacity-50"
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

function FormField({
  label,
  name,
  type = 'text',
  value,
  error,
  onChange,
  disabled,
}: {
  label: string
  name: string
  type?: string
  value: string
  error?: string
  onChange: (e: React.ChangeEvent<HTMLInputElement>) => void
  disabled: boolean
}) {
  return (
    <div>
      <label className="block text-sm font-bold mb-2">{label}</label>
      <input
        type={type}
        name={name}
        value={value}
        onChange={onChange}
        disabled={disabled}
        className={`w-full px-4 py-2 border rounded ${
          error ? 'border-red-500 bg-red-50' : 'border-gray-300'
        }`}
      />
      {error && <p className="mt-1 text-sm text-red-600">{error}</p>}
    </div>
  )
}
```

### 3. Form Multi-Step avec État

**`src/routes/checkout.tsx`**

```typescript
import { createFileRoute } from '@tanstack/react-router'
import { createServerFn } from '@tanstack/start'
import { useState } from 'react'

type CheckoutStep = 'shipping' | 'payment' | 'review'

const processOrder = createServerFn('POST', async (data: {
  shipping: { address: string; city: string; zip: string }
  payment: { cardNumber: string; expiry: string; cvv: string }
}) => {
  // Traiter la commande
  return { orderId: 'ORD-123456' }
})

export const Route = createFileRoute('/checkout')({
  component: CheckoutPage,
})

function CheckoutPage() {
  const [step, setStep] = useState<CheckoutStep>('shipping')
  const [loading, setLoading] = useState(false)
  const [formData, setFormData] = useState({
    shipping: { address: '', city: '', zip: '' },
    payment: { cardNumber: '', expiry: '', cvv: '' },
  })

  const handleShippingSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    // Valider
    setStep('payment')
  }

  const handlePaymentSubmit = (e: React.FormEvent) => {
    e.preventDefault()
    // Valider
    setStep('review')
  }

  const handleOrderSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setLoading(true)
    try {
      await processOrder(formData)
      // Rediriger
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="max-w-2xl mx-auto py-8">
      <h1 className="text-4xl font-bold mb-8">Finaliser la commande</h1>

      {/* Progress Indicator */}
      <div className="mb-8 flex gap-4">
        {(['shipping', 'payment', 'review'] as CheckoutStep[]).map((s, i) => (
          <div key={s} className="flex-1">
            <div
              className={`p-4 rounded border text-center font-bold ${
                step === s
                  ? 'bg-blue-600 text-white border-blue-600'
                  : 'bg-white border-gray-300'
              }`}
            >
              {i + 1}. {s === 'shipping' ? 'Livraison' : s === 'payment' ? 'Paiement' : 'Confirmation'}
            </div>
          </div>
        ))}
      </div>

      {/* Forms */}
      {step === 'shipping' && (
        <form onSubmit={handleShippingSubmit} className="space-y-4">
          <input
            placeholder="Adresse"
            value={formData.shipping.address}
            onChange={(e) =>
              setFormData({
                ...formData,
                shipping: { ...formData.shipping, address: e.target.value },
              })
            }
            className="w-full px-4 py-2 border rounded"
          />
          <input
            placeholder="Ville"
            value={formData.shipping.city}
            onChange={(e) =>
              setFormData({
                ...formData,
                shipping: { ...formData.shipping, city: e.target.value },
              })
            }
            className="w-full px-4 py-2 border rounded"
          />
          <input
            placeholder="Code Postal"
            value={formData.shipping.zip}
            onChange={(e) =>
              setFormData({
                ...formData,
                shipping: { ...formData.shipping, zip: e.target.value },
              })
            }
            className="w-full px-4 py-2 border rounded"
          />
          <button
            type="submit"
            className="w-full bg-blue-600 text-white py-2 rounded"
          >
            Continuer
          </button>
        </form>
      )}

      {step === 'payment' && (
        <form onSubmit={handlePaymentSubmit} className="space-y-4">
          <input
            placeholder="Numéro de carte"
            value={formData.payment.cardNumber}
            onChange={(e) =>
              setFormData({
                ...formData,
                payment: { ...formData.payment, cardNumber: e.target.value },
              })
            }
            className="w-full px-4 py-2 border rounded"
          />
          <div className="grid grid-cols-2 gap-4">
            <input
              placeholder="MM/YY"
              value={formData.payment.expiry}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  payment: { ...formData.payment, expiry: e.target.value },
                })
              }
              className="w-full px-4 py-2 border rounded"
            />
            <input
              placeholder="CVV"
              value={formData.payment.cvv}
              onChange={(e) =>
                setFormData({
                  ...formData,
                  payment: { ...formData.payment, cvv: e.target.value },
                })
              }
              className="w-full px-4 py-2 border rounded"
            />
          </div>
          <div className="flex gap-4">
            <button
              type="button"
              onClick={() => setStep('shipping')}
              className="flex-1 border py-2 rounded"
            >
              Retour
            </button>
            <button
              type="submit"
              className="flex-1 bg-blue-600 text-white py-2 rounded"
            >
              Continuer
            </button>
          </div>
        </form>
      )}

      {step === 'review' && (
        <form onSubmit={handleOrderSubmit} className="space-y-6">
          <div className="bg-white border rounded p-6">
            <h2 className="font-bold text-lg mb-4">Livraison</h2>
            <p>{formData.shipping.address}</p>
            <p>
              {formData.shipping.city} {formData.shipping.zip}
            </p>
          </div>

          <div className="bg-white border rounded p-6">
            <h2 className="font-bold text-lg mb-4">Paiement</h2>
            <p>Carte: ***{formData.payment.cardNumber.slice(-4)}</p>
          </div>

          <div className="flex gap-4">
            <button
              type="button"
              onClick={() => setStep('payment')}
              className="flex-1 border py-2 rounded"
            >
              Retour
            </button>
            <button
              type="submit"
              disabled={loading}
              className="flex-1 bg-green-600 text-white py-2 rounded disabled:opacity-50"
            >
              {loading ? 'Traitement...' : 'Commander'}
            </button>
          </div>
        </form>
      )}
    </div>
  )
}
```

## Best Practices

### 1. Validation Partagée

```typescript
// ✅ Partager le schéma Zod entre client et serveur
export const UserSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
})

// Client
const errors = validateClient(formData, UserSchema)

// Serveur
const validated = UserSchema.parse(serverData)
```

### 2. Optimistic Updates

```typescript
// ✅ Mettre à jour l'UI avant la réponse serveur
const handleSubmit = async (e) => {
  e.preventDefault()

  // Mettre à jour immédiatement
  setFormData({ ...formData, submitted: true })

  // Traiter en arrière-plan
  try {
    await submitForm(formData)
  } catch {
    // Restaurer en cas d'erreur
    setFormData({ ...formData, submitted: false })
  }
}
```

### 3. État de Chargement Granulaire

```typescript
// ✅ Tracker l'état de chaque champ
const [fieldStates, setFieldStates] = useState({
  email: 'idle',
  password: 'idle',
})

const validateEmail = async (email) => {
  setFieldStates({ ...fieldStates, email: 'validating' })
  // Validation
  setFieldStates({ ...fieldStates, email: 'idle' })
}
```

## Avantages

- **Type Safe**: Validation Zod partagée
- **Server-Driven**: Validation et logique côté serveur
- **Progressive**: Fonctionne sans JavaScript
- **Accessible**: Forms standards HTML
- **Extensible**: Compatible avec TanStack Form
