# Reference

# Server-Only Functions

## Concept

Les Server-Only Functions sont des fonctions qui s'exécutent UNIQUEMENT côté serveur et ne peuvent JAMAIS être importées côté client. Elles protègent les opérations sensibles (accès base de données, secrets, clés API) en les rendant littéralement inaccessibles au code client.

## Architecture

```
Server Layer (s'exécute TOUJOURS)
├── Database Operations
├── External APIs (sécurisées)
├── Secrets & Credentials
└── Business Logic Sensitive

Client Barrier (Next.js Protection)
↓

Client Layer (JAMAIS accès au serveur-only)
├── UI Components
├── Client State
└── User Interactions
```

## Implémentation Détaillée

### 1. Pattern Basique: Database Operations

**`src/lib/server-only/db.ts`**

```typescript
import 'server-only'

import { db } from '@prisma/client'

// ✅ Ce fichier NE PEUT PAS être importé côté client
// ✅ TypeScript lancera une erreur à la compilation si on essaie

const prisma = new db()

// ✅ Tous les types ici restent côté serveur
export async function getUserWithSecrets(userId: string) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      apiKeys: true, // Secrets sensibles
      paymentMethods: true, // Données sensibles
      suspiciousActivityLogs: true,
    },
  })

  return user
}

export async function createAdminUser(email: string, password: string) {
  // ✅ Hashage des mots de passe côté serveur
  const hashedPassword = await hashPassword(password)

  const user = await prisma.user.create({
    data: {
      email,
      password: hashedPassword,
      role: 'admin',
      createdAt: new Date(),
    },
  })

  return {
    id: user.id,
    email: user.email,
    role: user.role,
    // ✅ Ne JAMAIS retourner le mot de passe hashé
  }
}

export async function updateUserPasswordSecurely(
  userId: string,
  oldPassword: string,
  newPassword: string
) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
  })

  if (!user) {
    throw new Error('Utilisateur non trouvé')
  }

  // ✅ Vérification du mot de passe côté serveur
  const isValid = await verifyPassword(oldPassword, user.password)

  if (!isValid) {
    throw new Error('Ancien mot de passe incorrect')
  }

  const newHashedPassword = await hashPassword(newPassword)

  await prisma.user.update({
    where: { id: userId },
    data: {
      password: newHashedPassword,
      updatedAt: new Date(),
    },
  })

  return { success: true }
}

async function hashPassword(password: string): Promise<string> {
  // Utiliser bcrypt, argon2, etc.
  return password // Pseudo-code
}

async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  // Comparer les hashes
  return password === hash // Pseudo-code
}
```

### 2. Gestion des Secrets et Variables d'Environnement

**`src/lib/server-only/secrets.ts`**

```typescript
import 'server-only'

// ✅ Les secrets d'environnement ne sortent JAMAIS du serveur
export function getStripeSecretKey(): string {
  const key = process.env.STRIPE_SECRET_KEY

  if (!key) {
    throw new Error('STRIPE_SECRET_KEY not configured')
  }

  return key
}

export function getDatabaseUrl(): string {
  const url = process.env.DATABASE_URL

  if (!url) {
    throw new Error('DATABASE_URL not configured')
  }

  return url
}

export function getGitHubToken(): string {
  const token = process.env.GITHUB_TOKEN

  if (!token) {
    throw new Error('GITHUB_TOKEN not configured')
  }

  return token
}

// ✅ Configuration sensible
export const SECRETS = {
  STRIPE_KEY: process.env.STRIPE_SECRET_KEY || '',
  TWILIO_AUTH: process.env.TWILIO_AUTH_TOKEN || '',
  OPENAI_KEY: process.env.OPENAI_API_KEY || '',
  AWS_SECRET: process.env.AWS_SECRET_ACCESS_KEY || '',
  JWT_SECRET: process.env.JWT_SECRET || '',
  ENCRYPTION_KEY: process.env.ENCRYPTION_KEY || '',
} as const

// ✅ Fonction pour accéder aux secrets en toute sécurité
export function getSecret(key: keyof typeof SECRETS): string {
  const value = SECRETS[key]

  if (!value) {
    throw new Error(`Secret not configured: ${key}`)
  }

  return value
}
```

### 3. Intégrations d'APIs Sensibles

**`src/lib/server-only/external-apis.ts`**

```typescript
import 'server-only'

import Stripe from 'stripe'
import { getSecret } from './secrets'

// ✅ Client Stripe - exécution côté serveur
const stripe = new Stripe(getSecret('STRIPE_KEY'), {
  apiVersion: '2024-04-10',
})

export async function createStripeCustomer(
  userId: string,
  email: string,
  name: string
) {
  // ✅ Appel API sécurisé - la clé secrète ne sort JAMAIS du serveur
  const customer = await stripe.customers.create({
    email,
    name,
    metadata: { userId },
  })

  return {
    id: customer.id,
    email: customer.email,
  }
}

export async function createPaymentIntent(
  amount: number,
  currency: 'usd' | 'eur' = 'usd'
) {
  const intent = await stripe.paymentIntents.create({
    amount,
    currency,
    automatic_payment_methods: { enabled: true },
  })

  return {
    clientSecret: intent.client_secret,
    id: intent.id,
  }
}

export async function confirmPayment(paymentIntentId: string) {
  const intent = await stripe.paymentIntents.retrieve(paymentIntentId)

  if (intent.status === 'succeeded') {
    return {
      success: true,
      amount: intent.amount,
      currency: intent.currency,
    }
  }

  throw new Error(`Payment failed: ${intent.status}`)
}

export async function createStripeSubscription(
  customerId: string,
  priceId: string
) {
  const subscription = await stripe.subscriptions.create({
    customer: customerId,
    items: [{ price: priceId }],
    payment_behavior: 'default_incomplete',
    expand: ['latest_invoice.payment_intent'],
  })

  return {
    id: subscription.id,
    status: subscription.status,
    currentPeriodEnd: subscription.current_period_end,
  }
}
```

### 4. Opérations Batch et Sensibles

**`src/lib/server-only/batch-operations.ts`**

```typescript
import 'server-only'

import { db } from '@prisma/client'
import { sendEmail } from './email'

const prisma = new db()

export async function generateAndSendInvoices(date: Date) {
  // ✅ Opération batch sensible - côté serveur
  const orders = await prisma.order.findMany({
    where: {
      createdAt: {
        gte: new Date(date.getFullYear(), date.getMonth(), 1),
        lt: new Date(date.getFullYear(), date.getMonth() + 1, 1),
      },
      status: 'paid',
      invoiceSent: false,
    },
    include: {
      user: true,
      items: true,
    },
  })

  const results = await Promise.allSettled(
    orders.map(async (order) => {
      // ✅ Générer PDF côté serveur
      const pdf = await generateInvoicePdf(order)

      // ✅ Envoyer email avec le PDF
      await sendEmail({
        to: order.user.email,
        subject: `Invoice ${order.id}`,
        html: renderInvoiceTemplate(order),
        attachments: [
          {
            filename: `invoice-${order.id}.pdf`,
            content: pdf,
          },
        ],
      })

      // ✅ Mettre à jour la base de données
      return await prisma.order.update({
        where: { id: order.id },
        data: {
          invoiceSent: true,
          invoiceSentAt: new Date(),
        },
      })
    })
  )

  return {
    total: orders.length,
    successful: results.filter((r) => r.status === 'fulfilled').length,
    failed: results.filter((r) => r.status === 'rejected').length,
  }
}

export async function deleteUserAndData(userId: string) {
  // ✅ Opération sensible - suppression complète côté serveur
  const result = await prisma.$transaction(async (tx) => {
    // Supprimer les données associées en cascade
    await tx.order.deleteMany({ where: { userId } })
    await tx.review.deleteMany({ where: { userId } })
    await tx.apiKey.deleteMany({ where: { userId } })
    await tx.session.deleteMany({ where: { userId } })

    // Enfin, supprimer l'utilisateur
    const deleted = await tx.user.delete({
      where: { id: userId },
    })

    return deleted
  })

  return {
    success: true,
    deletedUserId: result.id,
  }
}

export async function expireOldSessions() {
  // ✅ Tâche de nettoyage côté serveur
  const result = await prisma.session.deleteMany({
    where: {
      expiresAt: {
        lt: new Date(),
      },
    },
  })

  return {
    deletedCount: result.count,
  }
}

async function generateInvoicePdf(order: any): Promise<Buffer> {
  // Utiliser une librairie comme pdfkit
  return Buffer.from('PDF content')
}

function renderInvoiceTemplate(order: any): string {
  return '<html>Invoice</html>'
}
```

### 5. Authentification et Autorisation Sensibles

**`src/lib/server-only/auth.ts`**

```typescript
import 'server-only'

import { cookies } from 'next/headers'
import { db } from '@prisma/client'
import { getSecret } from './secrets'
import jwt from 'jsonwebtoken'

const prisma = new db()

export async function createAuthSession(userId: string) {
  // ✅ Créer un JWT côté serveur avec la clé secrète
  const token = jwt.sign({ userId }, getSecret('JWT_SECRET'), {
    expiresIn: '7d',
  })

  // ✅ Stocker la session en base de données
  const session = await prisma.session.create({
    data: {
      userId,
      token,
      expiresAt: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
    },
  })

  // ✅ Écrire le cookie sécurisé côté serveur
  const cookieStore = await cookies()
  cookieStore.set('auth-token', token, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: 7 * 24 * 60 * 60,
  })

  return {
    sessionId: session.id,
    expiresAt: session.expiresAt,
  }
}

export async function verifySession(): Promise<{ userId: string } | null> {
  // ✅ Vérifier la session depuis le serveur
  const cookieStore = await cookies()
  const token = cookieStore.get('auth-token')?.value

  if (!token) return null

  try {
    const decoded = jwt.verify(token, getSecret('JWT_SECRET')) as {
      userId: string
    }

    // Vérifier que la session existe encore en base de données
    const session = await prisma.session.findUnique({
      where: { token },
    })

    if (!session || session.expiresAt < new Date()) {
      return null
    }

    return { userId: decoded.userId }
  } catch {
    return null
  }
}

export async function checkPermission(
  userId: string,
  resource: string,
  action: string
): Promise<boolean> {
  // ✅ Vérification des permissions côté serveur
  const user = await prisma.user.findUnique({
    where: { id: userId },
    include: {
      role: {
        include: {
          permissions: {
            where: {
              resource,
              action,
            },
          },
        },
      },
    },
  })

  return (user?.role?.permissions?.length ?? 0) > 0
}

export async function logSecurityEvent(
  userId: string,
  event: string,
  details: Record<string, any>
) {
  // ✅ Logger les événements sensibles côté serveur
  await prisma.auditLog.create({
    data: {
      userId,
      event,
      details,
      timestamp: new Date(),
      ipAddress: '' // À récupérer du contexte
    },
  })
}
```

### 6. Encryption et Hashing

**`src/lib/server-only/crypto.ts`**

```typescript
import 'server-only'

import crypto from 'crypto'
import bcrypt from 'bcrypt'
import { getSecret } from './secrets'

export async function hashPassword(password: string): Promise<string> {
  // ✅ Hashing côté serveur avec salt
  const salt = await bcrypt.genSalt(12)
  return bcrypt.hash(password, salt)
}

export async function verifyPassword(
  password: string,
  hash: string
): Promise<boolean> {
  // ✅ Vérification côté serveur
  return bcrypt.compare(password, hash)
}

export function encryptSensitiveData(data: string): string {
  // ✅ Chiffrement avec clé secrète
  const cipher = crypto.createCipher('aes-256-cbc', getSecret('ENCRYPTION_KEY'))
  let encrypted = cipher.update(data, 'utf8', 'hex')
  encrypted += cipher.final('hex')
  return encrypted
}

export function decryptSensitiveData(encrypted: string): string {
  // ✅ Déchiffrement côté serveur
  const decipher = crypto.createDecipher(
    'aes-256-cbc',
    getSecret('ENCRYPTION_KEY')
  )
  let decrypted = decipher.update(encrypted, 'hex', 'utf8')
  decrypted += decipher.final('utf8')
  return decrypted
}

export function generateSecureToken(length: number = 32): string {
  // ✅ Génération de tokens côté serveur
  return crypto.randomBytes(length).toString('hex')
}

export function generateOTP(): { code: string; expiresAt: Date } {
  // ✅ Génération d'OTP côté serveur
  const code = Math.floor(100000 + Math.random() * 900000).toString()
  const expiresAt = new Date(Date.now() + 10 * 60 * 1000) // 10 minutes

  return { code, expiresAt }
}
```

### 7. Email et Notifications Sensibles

**`src/lib/server-only/email.ts`**

```typescript
import 'server-only'

import nodemailer from 'nodemailer'
import { getSecret } from './secrets'

// ✅ Configuration du serveur email côté serveur
const transporter = nodemailer.createTransport({
  host: process.env.EMAIL_HOST,
  port: process.env.EMAIL_PORT,
  secure: true,
  auth: {
    user: process.env.EMAIL_USER,
    pass: process.env.EMAIL_PASSWORD, // ✅ Clé secrète côté serveur
  },
})

export async function sendEmail(options: {
  to: string
  subject: string
  html: string
  attachments?: any[]
}): Promise<{ success: boolean; messageId?: string }> {
  // ✅ Envoi d'email côté serveur
  try {
    const result = await transporter.sendMail({
      from: process.env.EMAIL_FROM,
      ...options,
    })

    return {
      success: true,
      messageId: result.messageId,
    }
  } catch (error) {
    console.error('Email send error:', error)
    return { success: false }
  }
}

export async function sendWelcomeEmail(email: string, name: string) {
  // ✅ Email transactionnel côté serveur
  return sendEmail({
    to: email,
    subject: 'Bienvenue',
    html: `<h1>Bienvenue ${name}</h1>`,
  })
}

export async function sendPasswordResetEmail(
  email: string,
  resetToken: string
) {
  // ✅ Email sensible avec token côté serveur
  const resetLink = `${process.env.NEXT_PUBLIC_URL}/reset-password?token=${resetToken}`

  return sendEmail({
    to: email,
    subject: 'Réinitialisez votre mot de passe',
    html: `
      <h2>Réinitialiser votre mot de passe</h2>
      <p>Cliquez sur le lien ci-dessous pour réinitialiser votre mot de passe:</p>
      <a href="${resetLink}">Réinitialiser le mot de passe</a>
      <p>Ce lien expire dans 1 heure.</p>
    `,
  })
}
```

### 8. Utilisation dans les Server Actions

**`src/app/actions.ts`**

```typescript
'use server'

import {
  getUserWithSecrets,
  updateUserPasswordSecurely,
} from '@/lib/server-only/db'
import {
  createAuthSession,
  verifySession,
  logSecurityEvent,
} from '@/lib/server-only/auth'
import { sendPasswordResetEmail } from '@/lib/server-only/email'
import { generateSecureToken } from '@/lib/server-only/crypto'

export async function handleLogin(email: string, password: string) {
  // ✅ Utiliser les fonctions server-only
  const user = await getUserWithSecrets(email)

  if (!user) {
    throw new Error('Utilisateur non trouvé')
  }

  // Vérification du mot de passe (utilise bcrypt côté serveur)
  const isValid = await updateUserPasswordSecurely(
    user.id,
    password,
    password
  ) // Pseudo-code

  if (!isValid) {
    await logSecurityEvent(user.id, 'FAILED_LOGIN', { email })
    throw new Error('Mot de passe incorrect')
  }

  // Créer la session
  const session = await createAuthSession(user.id)

  await logSecurityEvent(user.id, 'SUCCESSFUL_LOGIN', {
    sessionId: session.sessionId,
  })

  return { success: true }
}

export async function handleForgotPassword(email: string) {
  // ✅ Générateur de token côté serveur
  const resetToken = generateSecureToken()

  // Sauvegarder le token en base de données...

  // ✅ Envoyer l'email avec le token côté serveur
  await sendPasswordResetEmail(email, resetToken)

  return { success: true }
}

export async function protectedAction() {
  // ✅ Vérifier la session côté serveur
  const session = await verifySession()

  if (!session) {
    throw new Error('Non authentifié')
  }

  // Effectuer l'action protégée
  return { userId: session.userId }
}
```

## Best Practices

### 1. Isolation Totale

```typescript
// ✅ Bon: Fichier entièrement côté serveur
// src/lib/server-only/db.ts
import 'server-only'

export async function sensitiveOperation() {
  // Code sensible
}
```

```typescript
// ✅ Mauvais: Exposition accidentelle
export async function getUser(id: string) {
  // Accessible au client
  return await db.users.findUnique({...})
}
```

### 2. Pas d'Exports de Secrets

```typescript
// ✅ Bon: Secrets jamais exportés
const apiKey = process.env.API_KEY
await apiProvider.call(apiKey) // Utilisé localement

// ✅ Mauvais: Exposition
export const API_KEY = process.env.API_KEY
```

### 3. Validation Multi-Niveaux

```typescript
'use server'

import { sensitiveDbFunction } from '@/lib/server-only/db'

export async function userAction(input: unknown) {
  // ✅ Validation côté serveur
  if (typeof input !== 'string') throw new Error('Invalid')

  // ✅ Utiliser les fonctions server-only
  return await sensitiveDbFunction(input)
}
```

## Avantages

- **Sécurité Absolue**: Impossible d'importer côté client
- **Secrets Protégés**: Clés API jamais exposées
- **Opérations Sensibles**: DB access, transactions, encryption
- **Erreurs Détectées**: TypeScript révèle les violations
- **Performances**: Code sensible optimisé côté serveur
