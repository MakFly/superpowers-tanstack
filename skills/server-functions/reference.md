# Reference

# Server Functions avec 'use server'

## Concept

Les Server Functions sont des fonctions exécutées UNIQUEMENT côté serveur, marquées avec la directive `'use server'`. Elles permettent d'exécuter du code sensible (accès à la base de données, secrets, etc.) de manière sécurisée depuis le client sans exposer le serveur.

## Architecture Générale

```
Client Component
    ↓
    Appel de Server Function
    ↓
    Serialisation des paramètres
    ↓
    Envoi au serveur (POST)
    ↓
    Exécution côté serveur ('use server')
    ↓
    Retour des résultats sérialisés
    ↓
    Mise à jour du composant client
```

## Implémentation Détaillée

### 1. Pattern Basique: Server Function Simple

**`src/server/users.ts`**

```typescript
'use server'

import { db } from '@/lib/db'

export async function getUserById(userId: string) {
  // ✅ Ce code s'exécute UNIQUEMENT sur le serveur
  // ✅ Les secrets (clés API, credentials) sont sûrs

  const user = await db.users.findUnique({
    where: { id: userId },
    select: {
      id: true,
      name: true,
      email: true,
      role: true,
    },
  })

  if (!user) {
    throw new Error('Utilisateur non trouvé')
  }

  return user
}

export async function updateUserProfile(
  userId: string,
  data: { name: string; bio: string }
) {
  // ✅ Validation côté serveur
  if (!data.name || data.name.length < 2) {
    throw new Error('Le nom doit contenir au moins 2 caractères')
  }

  if (data.bio && data.bio.length > 500) {
    throw new Error('La bio ne peut pas dépasser 500 caractères')
  }

  const updated = await db.users.update({
    where: { id: userId },
    data: {
      name: data.name,
      bio: data.bio,
      updatedAt: new Date(),
    },
  })

  return {
    success: true,
    user: updated,
  }
}

export async function deleteUser(userId: string) {
  // ✅ Opération sensible - exécutée côté serveur
  const deleted = await db.users.delete({
    where: { id: userId },
  })

  return {
    success: true,
    deletedId: deleted.id,
  }
}
```

**`src/components/ProfileEditor.tsx`**

```typescript
'use client'

import { useState } from 'react'
import { updateUserProfile } from '@/server/users'

type ProfileEditorProps = {
  userId: string
  initialName: string
  initialBio: string
};

export function ProfileEditor({
  userId,
  initialName,
  initialBio,
}: ProfileEditorProps) {
  const [name, setName] = useState(initialName)
  const [bio, setBio] = useState(initialBio)
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)
  const [success, setSuccess] = useState(false)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setIsLoading(true)
    setError(null)
    setSuccess(false)

    try {
      // ✅ Appel simple à la Server Function
      const result = await updateUserProfile(userId, {
        name,
        bio,
      })

      setSuccess(true)
      setTimeout(() => setSuccess(false), 3000)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Une erreur est survenue')
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
          value={name}
          onChange={(e) => setName(e.target.value)}
          className="w-full border rounded px-3 py-2"
          disabled={isLoading}
        />
      </div>

      <div>
        <label className="block text-sm font-bold mb-2">Bio</label>
        <textarea
          value={bio}
          onChange={(e) => setBio(e.target.value)}
          className="w-full border rounded px-3 py-2"
          rows={4}
          disabled={isLoading}
        />
        <p className="text-xs text-gray-500 mt-1">{bio.length}/500</p>
      </div>

      {error && (
        <div className="p-3 bg-red-50 border border-red-200 rounded text-red-700">
          {error}
        </div>
      )}

      {success && (
        <div className="p-3 bg-green-50 border border-green-200 rounded text-green-700">
          Profil mis à jour avec succès
        </div>
      )}

      <button
        type="submit"
        disabled={isLoading}
        className="bg-blue-600 text-white px-6 py-2 rounded font-bold hover:bg-blue-700 disabled:opacity-50"
      >
        {isLoading ? 'Mise à jour...' : 'Sauvegarder'}
      </button>
    </form>
  )
}
```

### 2. Server Functions avec Authentification

**`src/server/auth.ts`**

```typescript
'use server'

import { headers } from 'next/headers'
import { db } from '@/lib/db'

// ✅ Middleware pour vérifier l'authentification
async function getAuthenticatedUser() {
  const headersList = await headers()
  const userId = headersList.get('x-user-id')

  if (!userId) {
    throw new Error('Non authentifié')
  }

  const user = await db.users.findUnique({
    where: { id: userId },
  })

  if (!user) {
    throw new Error('Utilisateur non trouvé')
  }

  return user
}

export async function createPost(data: { title: string; content: string }) {
  // ✅ Vérifier l'authentification
  const user = await getAuthenticatedUser()

  // ✅ Validation
  if (!data.title || data.title.length < 5) {
    throw new Error('Le titre doit contenir au moins 5 caractères')
  }

  if (!data.content || data.content.length < 20) {
    throw new Error('Le contenu doit contenir au moins 20 caractères')
  }

  // ✅ Créer le post
  const post = await db.posts.create({
    data: {
      title: data.title,
      content: data.content,
      authorId: user.id,
      publishedAt: new Date(),
    },
  })

  return {
    success: true,
    post: {
      id: post.id,
      title: post.title,
      slug: post.slug,
      publishedAt: post.publishedAt,
    },
  }
}

export async function deletePost(postId: string) {
  const user = await getAuthenticatedUser()

  // ✅ Vérifier que l'utilisateur est propriétaire du post
  const post = await db.posts.findUnique({
    where: { id: postId },
  })

  if (!post) {
    throw new Error('Post non trouvé')
  }

  if (post.authorId !== user.id) {
    throw new Error('Vous n\'avez pas la permission de supprimer ce post')
  }

  await db.posts.delete({
    where: { id: postId },
  })

  return { success: true }
}

export async function getMyPosts() {
  const user = await getAuthenticatedUser()

  const posts = await db.posts.findMany({
    where: { authorId: user.id },
    select: {
      id: true,
      title: true,
      slug: true,
      content: true,
      publishedAt: true,
      viewCount: true,
    },
    orderBy: { publishedAt: 'desc' },
  })

  return posts
}
```

**`src/components/CreatePostForm.tsx`**

```typescript
'use client'

import { useState } from 'react'
import { createPost } from '@/server/auth'

export function CreatePostForm() {
  const [title, setTitle] = useState('')
  const [content, setContent] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [error, setError] = useState<string | null>(null)

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault()
    setIsLoading(true)
    setError(null)

    try {
      const result = await createPost({
        title,
        content,
      })

      // Succès
      setTitle('')
      setContent('')
      alert(`Post créé: ${result.post.slug}`)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'Erreur inconnue')
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6 max-w-2xl">
      <div>
        <label className="block text-sm font-bold mb-2">Titre</label>
        <input
          type="text"
          value={title}
          onChange={(e) => setTitle(e.target.value)}
          placeholder="Votre titre"
          className="w-full border rounded px-3 py-2"
          disabled={isLoading}
        />
      </div>

      <div>
        <label className="block text-sm font-bold mb-2">Contenu</label>
        <textarea
          value={content}
          onChange={(e) => setContent(e.target.value)}
          placeholder="Votre contenu"
          className="w-full border rounded px-3 py-2 h-32"
          disabled={isLoading}
        />
      </div>

      {error && (
        <div className="p-3 bg-red-50 border border-red-200 rounded text-red-700">
          {error}
        </div>
      )}

      <button
        type="submit"
        disabled={isLoading}
        className="bg-green-600 text-white px-6 py-2 rounded font-bold hover:bg-green-700 disabled:opacity-50"
      >
        {isLoading ? 'Publication...' : 'Publier'}
      </button>
    </form>
  )
}
```

### 3. Server Functions avec Réutilisation

**`src/server/products.ts`**

```typescript
'use server'

import { db } from '@/lib/db'

// ✅ Fonction utilitaire (interne)
async function validateProductOwnership(
  productId: string,
  userId: string
) {
  const product = await db.products.findUnique({
    where: { id: productId },
  })

  if (!product || product.ownerId !== userId) {
    throw new Error('Produit non trouvé ou accès refusé')
  }

  return product
}

export async function getProductStats(productId: string) {
  const product = await db.products.findUnique({
    where: { id: productId },
    include: {
      reviews: {
        select: { rating: true },
      },
      _count: {
        select: { views: true, reviews: true },
      },
    },
  })

  if (!product) {
    throw new Error('Produit non trouvé')
  }

  const averageRating =
    product.reviews.length > 0
      ? product.reviews.reduce((sum, r) => sum + r.rating, 0) /
        product.reviews.length
      : 0

  return {
    id: product.id,
    name: product.name,
    views: product._count.views,
    reviews: product._count.reviews,
    averageRating: Math.round(averageRating * 10) / 10,
  }
}

export async function updateProductPrice(
  productId: string,
  userId: string,
  newPrice: number
) {
  // ✅ Validation de propriété
  await validateProductOwnership(productId, userId)

  // ✅ Validation du prix
  if (newPrice <= 0) {
    throw new Error('Le prix doit être supérieur à 0')
  }

  const updated = await db.products.update({
    where: { id: productId },
    data: {
      price: newPrice,
      updatedAt: new Date(),
    },
  })

  return {
    success: true,
    newPrice: updated.price,
  }
}

export async function bulkUpdateProducts(
  userId: string,
  updates: Array<{ id: string; price: number }>
) {
  // ✅ Valider tous les produits en une requête
  const products = await db.products.findMany({
    where: {
      id: { in: updates.map((u) => u.id) },
      ownerId: userId,
    },
  })

  if (products.length !== updates.length) {
    throw new Error('Certains produits n\'existent pas ou ne vous appartiennent pas')
  }

  // ✅ Mise à jour en batch
  const updated = await Promise.all(
    updates.map((update) =>
      db.products.update({
        where: { id: update.id },
        data: { price: update.price },
      })
    )
  )

  return {
    success: true,
    count: updated.length,
  }
}
```

**`src/components/ProductManager.tsx`**

```typescript
'use client'

import { useState } from 'react'
import { updateProductPrice } from '@/server/products'

type Product = {
  id: string
  name: string
  price: number
};

type ProductManagerProps = {
  userId: string
  products: Product[]
};

export function ProductManager({ userId, products }: ProductManagerProps) {
  const [prices, setPrices] = useState(
    products.reduce((acc, p) => ({ ...acc, [p.id]: p.price }), {})
  )
  const [isLoading, setIsLoading] = useState(false)

  async function handlePriceChange(
    productId: string,
    newPrice: number
  ) {
    setIsLoading(true)

    try {
      await updateProductPrice(productId, userId, newPrice)
      setPrices((prev) => ({ ...prev, [productId]: newPrice }))
    } catch (error) {
      alert(
        error instanceof Error ? error.message : 'Erreur lors de la mise à jour'
      )
      // Réinitialiser le prix
      setPrices((prev) => ({
        ...prev,
        [productId]: products.find((p) => p.id === productId)!.price,
      }))
    } finally {
      setIsLoading(false)
    }
  }

  return (
    <table className="w-full border">
      <thead>
        <tr className="bg-gray-100">
          <th className="border p-3 text-left">Produit</th>
          <th className="border p-3 text-right">Prix</th>
          <th className="border p-3">Action</th>
        </tr>
      </thead>
      <tbody>
        {products.map((product) => (
          <tr key={product.id} className="border-b">
            <td className="border p-3">{product.name}</td>
            <td className="border p-3 text-right">
              <input
                type="number"
                value={prices[product.id]}
                onChange={(e) =>
                  setPrices((prev) => ({
                    ...prev,
                    [product.id]: parseFloat(e.target.value),
                  }))
                }
                className="w-20 border rounded px-2 py-1 text-right"
                disabled={isLoading}
              />
            </td>
            <td className="border p-3 text-center">
              <button
                onClick={() =>
                  handlePriceChange(product.id, prices[product.id])
                }
                disabled={isLoading || prices[product.id] === product.price}
                className="bg-blue-600 text-white px-3 py-1 rounded disabled:opacity-50"
              >
                Sauvegarder
              </button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  )
}
```

### 4. Server Functions avec Cache et Revalidation

**`src/server/cached.ts`**

```typescript
'use server'

import { revalidatePath } from 'next/cache'
import { db } from '@/lib/db'

export async function getCachedCategories() {
  // ✅ Cette requête sera mise en cache
  const categories = await db.categories.findMany({
    select: {
      id: true,
      name: true,
      slug: true,
      _count: { select: { products: true } },
    },
    // Imaginer qu'il y a un cache DB configuré
  })

  return categories
}

export async function createCategoryAndInvalidate(data: {
  name: string
  slug: string
}) {
  const category = await db.categories.create({
    data,
  })

  // ✅ Invalider le cache après la création
  revalidatePath('/categories')
  revalidatePath('/products') // Tous les pages qui dépendent des catégories

  return category
}

export async function updateCategoryAndRevalidate(
  categoryId: string,
  data: { name: string }
) {
  const updated = await db.categories.update({
    where: { id: categoryId },
    data,
  })

  // ✅ Revalider les pages affectées
  revalidatePath('/categories')
  revalidatePath(`/categories/${updated.slug}`)

  return updated
}

export async function incrementCategoryViewCount(categoryId: string) {
  // ✅ Incrémenter sans revalider (opération légère)
  const updated = await db.categories.update({
    where: { id: categoryId },
    data: {
      viewCount: { increment: 1 },
    },
  })

  // Ne pas revalider - c'est juste une statistique
  return { viewCount: updated.viewCount }
}
```

### 5. Server Functions avec Gestion d'Erreurs Avancée

**`src/server/transactions.ts`**

```typescript
'use server'

import { db } from '@/lib/db'

export async function transferFunds(
  fromUserId: string,
  toUserId: string,
  amount: number
) {
  // ✅ Validation complète
  if (amount <= 0) {
    throw new Error('Le montant doit être positif')
  }

  if (fromUserId === toUserId) {
    throw new Error('Vous ne pouvez pas transférer vers vous-même')
  }

  try {
    // ✅ Transaction atomique
    const result = await db.$transaction(async (tx) => {
      // Vérifier le solde
      const from = await tx.accounts.findUnique({
        where: { userId: fromUserId },
      })

      if (!from || from.balance < amount) {
        throw new Error('Solde insuffisant')
      }

      // Vérifier le destinataire
      const to = await tx.accounts.findUnique({
        where: { userId: toUserId },
      })

      if (!to) {
        throw new Error('Compte destinataire non trouvé')
      }

      // Débiter
      await tx.accounts.update({
        where: { userId: fromUserId },
        data: {
          balance: { decrement: amount },
        },
      })

      // Créditer
      await tx.accounts.update({
        where: { userId: toUserId },
        data: {
          balance: { increment: amount },
        },
      })

      // Enregistrer la transaction
      const transaction = await tx.transactions.create({
        data: {
          fromUserId,
          toUserId,
          amount,
          status: 'completed',
          completedAt: new Date(),
        },
      })

      return transaction
    })

    return {
      success: true,
      transactionId: result.id,
      completedAt: result.completedAt,
    }
  } catch (error) {
    // La transaction est automatiquement annulée en cas d'erreur
    const message =
      error instanceof Error ? error.message : 'Erreur de transaction'

    return {
      success: false,
      error: message,
    }
  }
}

export async function processPayment(
  orderId: string,
  userId: string,
  paymentMethod: 'card' | 'bank_transfer'
) {
  try {
    const order = await db.orders.findUnique({
      where: { id: orderId },
    })

    if (!order || order.userId !== userId) {
      throw new Error('Commande non trouvée')
    }

    if (order.status !== 'pending') {
      throw new Error('La commande ne peut pas être payée dans cet état')
    }

    // Appeler le provider de paiement
    const paymentResult = await processWithPaymentProvider(
      order.amount,
      paymentMethod
    )

    if (!paymentResult.success) {
      throw new Error(`Paiement échoué: ${paymentResult.error}`)
    }

    // Mettre à jour la commande
    const updated = await db.orders.update({
      where: { id: orderId },
      data: {
        status: 'paid',
        paidAt: new Date(),
        paymentReference: paymentResult.reference,
      },
    })

    return {
      success: true,
      order: {
        id: updated.id,
        status: updated.status,
        paidAt: updated.paidAt,
      },
    }
  } catch (error) {
    console.error('Payment error:', error)
    return {
      success: false,
      error:
        error instanceof Error
          ? error.message
          : 'Une erreur est survenue lors du paiement',
    }
  }
}

// Mock function
async function processWithPaymentProvider(
  amount: number,
  method: string
): Promise<{ success: boolean; reference?: string; error?: string }> {
  // Simule un appel API de paiement
  return { success: true, reference: `PAY-${Date.now()}` }
}
```

## Best Practices

### 1. Sécurité Maximale

```typescript
'use server'

// ✅ Vérifier TOUJOURS l'authentification
async function getAuthUser() {
  const user = getServerSession()
  if (!user) throw new Error('Non authentifié')
  return user
}

// ✅ Valider les entrées
export async function safeAction(input: unknown) {
  if (typeof input !== 'string') {
    throw new Error('Input invalide')
  }
  // ...
}
```

### 2. Type Safety

```typescript
'use server'

type CreateUserInput = {
  name: string
  email: string
};

export async function createUser(input: CreateUserInput) {
  // ✅ TypeScript valide les paramètres
  // ✅ Le client reçoit les bons types en retour
  return await db.users.create({ data: input })
}
```

### 3. Gestion d'Erreurs

```typescript
'use server'

export async function riskyAction() {
  try {
    return await performDangerousOperation()
  } catch (error) {
    // ✅ Logger l'erreur complète côté serveur
    console.error('Full error:', error)

    // ✅ Retourner un message sûr au client
    throw new Error('Une erreur est survenue')
  }
}
```

## Avantages

- **Sécurité**: Code sensible protégé du client
- **Simplicity**: Pas besoin de routes API
- **Type Safety**: Full TypeScript support
- **Streaming**: Intégré avec React Suspense
- **Revalidation**: Cache invalité automatiquement
- **Error Handling**: Gestion centralisée
