# Reference

# Bootstrap Check - TanStack Start Project Verification

This skill provides a comprehensive checklist to verify that your TanStack Start project is properly configured and ready for development. Run this after initial setup to ensure all critical components are in place.

## Quick Health Check Command

```bash
# Run all checks at once
npm run type-check && npm run build && npm run preview
```

If all commands succeed without errors, your bootstrap is complete.

## Configuration Files Checklist

### Essential Files Required

Use this checklist to verify all critical configuration files exist:

```
superpowers-tanstack/
├── ✓ package.json          # Project dependencies and scripts
├── ✓ tsconfig.json         # TypeScript configuration
├── ✓ vite.config.ts        # Vite bundler configuration
├── ✓ router.config.ts      # TanStack Router configuration
├── ✓ .gitignore            # Git exclusions
├── ✓ src/
│   ├── ✓ routes/
│   │   └── ✓ __root.tsx    # Root layout and setup
│   ├── ✓ components/       # React components
│   ├── ✓ lib/             # Utilities and helpers
│   └── ✓ types/           # TypeScript definitions
├── ✓ public/               # Static assets
└── ✓ .env.example         # Environment variable template
```

### File Verification Commands

```bash
# Check all critical files exist
test -f package.json && echo "✓ package.json" || echo "✗ package.json MISSING"
test -f tsconfig.json && echo "✓ tsconfig.json" || echo "✗ tsconfig.json MISSING"
test -f vite.config.ts && echo "✓ vite.config.ts" || echo "✗ vite.config.ts MISSING"
test -f router.config.ts && echo "✓ router.config.ts" || echo "✗ router.config.ts MISSING"
test -d src && echo "✓ src/" || echo "✗ src/ MISSING"
test -d src/routes && echo "✓ src/routes/" || echo "✗ src/routes/ MISSING"
test -f src/routes/__root.tsx && echo "✓ src/routes/__root.tsx" || echo "✗ src/routes/__root.tsx MISSING"
```

## package.json Verification

### Required Fields

Your `package.json` must include:

```json
{
  "name": "superpowers-tanstack",
  "version": "1.0.0",
  "type": "module",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "vite build",
    "preview": "vite preview",
    "type-check": "tsc --noEmit",
    "lint": "eslint src --ext ts,tsx",
    "format": "prettier --write src"
  },
  "dependencies": {
    "@tanstack/react-router": "^1.30.0",
    "@tanstack/start": "^1.0.0",
    "react": "^18.0.0",
    "react-dom": "^18.0.0"
  },
  "devDependencies": {
    "@types/react": "^18.0.0",
    "@types/react-dom": "^18.0.0",
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0",
    "vite": "^5.0.0"
  }
}
```

### Verification Script

```bash
# Check package.json structure
node -e "
const pkg = require('./package.json');
const checks = [
  { name: 'name', value: pkg.name },
  { name: 'type', value: pkg.type, expected: 'module' },
  { name: 'scripts.dev', value: pkg.scripts.dev },
  { name: 'scripts.build', value: pkg.scripts.build },
  { name: 'dependencies.react', value: pkg.dependencies.react },
  { name: 'devDependencies.typescript', value: pkg.devDependencies.typescript },
];
checks.forEach(check => {
  const status = check.value ? '✓' : '✗';
  console.log(\`\${status} \${check.name}\`);
});
"
```

## TypeScript Configuration Verification

### Required tsconfig.json Settings

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "useDefineForClassFields": true,
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "esModuleInterop": true,
    "allowSyntheticDefaultImports": true,
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noFallthroughCasesInSwitch": true,
    "resolveJsonModule": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"],
      "@/components/*": ["./src/components/*"],
      "@/lib/*": ["./src/lib/*"],
      "@/types/*": ["./src/types/*"]
    }
  },
  "include": ["src"],
  "exclude": ["node_modules", "dist"]
}
```

### TypeScript Health Check

```bash
# Run TypeScript compiler
npm run type-check

# Check for any type errors
npx tsc --noEmit --listFiles

# Verify all imports resolve correctly
npx tsc --noEmit --traceResolution | head -50
```

### Expected Output

```
✓ No errors (clean compilation)
✓ All imports resolve
✓ No unused variables or parameters
```

## Vite Configuration Verification

### Essential vite.config.ts Setup

```typescript
import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react-swc'
import path from 'path'

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    open: true,
    cors: true,
  },
  build: {
    target: 'ES2020',
    minify: 'terser',
    sourcemap: false,
    rollupOptions: {
      output: {
        manualChunks: {
          vendor: ['react', 'react-dom'],
        },
      },
    },
  },
})
```

### Vite Health Check

```bash
# Start Vite dev server (test only)
npm run dev &
DEV_PID=$!

# Wait for server to start
sleep 3

# Check if server is running
curl -s http://localhost:5173/ > /dev/null && echo "✓ Vite server running" || echo "✗ Vite server failed"

# Kill server
kill $DEV_PID 2>/dev/null

# Check build process
npm run build

# Check preview server
npm run preview &
PREVIEW_PID=$!
sleep 2
curl -s http://localhost:4173/ > /dev/null && echo "✓ Preview server running" || echo "✗ Preview server failed"
kill $PREVIEW_PID 2>/dev/null
```

## TanStack Router Configuration

### router.config.ts Setup

```typescript
import { createRootRoute, createRoute, createRouter } from '@tanstack/react-router'
import Root from './routes/__root'
import Home from './routes/index'

const rootRoute = createRootRoute({
  component: Root,
})

const indexRoute = createRoute({
  getParentRoute: () => rootRoute,
  path: '/',
  component: Home,
})

const routeTree = rootRoute.addChildren([indexRoute])

const router = createRouter({ routeTree })

declare module '@tanstack/react-router' {
  interface Register {
    router: typeof router
  }
}

export default router
```

### Router Verification

```bash
# Check for missing routes
find src/routes -name "*.tsx" -type f | grep -v __

# Verify __root.tsx exists
test -f src/routes/__root.tsx && echo "✓ Root route exists" || echo "✗ Root route missing"

# Check for TypeScript errors in routes
npx tsc --noEmit src/routes/
```

## File-Based Routing Structure

### Standard Route Directory Layout

```
src/routes/
├── __root.tsx                 # Root layout
│
├── index.tsx                  # Home page (/)
│
├── about.tsx                  # About page (/about)
│
├── products/
│   ├── __layout.tsx           # Products layout
│   ├── index.tsx              # Products page (/products)
│   ├── $productId.tsx         # Dynamic route (/products/:productId)
│   └── [search].tsx           # Optional param (/products/search or /products)
│
├── dashboard/
│   ├── __layout.tsx           # Dashboard layout
│   ├── index.tsx              # Dashboard home (/dashboard)
│   ├── $userId.tsx            # User page (/dashboard/:userId)
│   └── settings/
│       ├── __layout.tsx       # Settings layout
│       ├── index.tsx          # Settings home (/dashboard/settings)
│       ├── profile.tsx        # Profile settings (/dashboard/settings/profile)
│       └── notifications.tsx  # Notifications (/dashboard/settings/notifications)
│
├── (auth)/                    # Route group (no URL impact)
│   ├── login.tsx              # Login page (/login)
│   ├── register.tsx           # Register page (/register)
│   └── forgot-password.tsx    # Forgot password (/forgot-password)
│
└── _offline.tsx               # Offline fallback
```

### Verify Routing Structure

```bash
# List all route files
find src/routes -name "*.tsx" -type f | sort

# Check route file syntax
npx tsc --noEmit src/routes/*.tsx

# Count total routes
find src/routes -name "*.tsx" -type f | wc -l

# Check for invalid naming patterns
find src/routes -name "*.ts" -type f  # Should be empty (only .tsx)
```

## Dependencies Health Check

### Critical Dependency Versions

```bash
# Check installed versions
npm list react @tanstack/react-router @tanstack/start typescript

# Verify version compatibility
npx npm-check-updates

# List outdated packages
npm outdated

# Check for security vulnerabilities
npm audit
```

### Dependency Verification Matrix

```bash
# Run this script to verify all critical dependencies
npm list | grep -E "(react|@tanstack|typescript|vite)"
```

**Expected Output:**
```
├── react@18.x.x
├── react-dom@18.x.x
├── @tanstack/react-router@1.30.x
├── @tanstack/start@1.0.x
├── typescript@5.x.x
└── vite@5.x.x
```

## Environment Setup

### .env Configuration

Create `.env.local` for local development (never commit):

```bash
# API Configuration
VITE_API_URL=http://localhost:3000
VITE_API_TIMEOUT=30000

# Feature Flags
VITE_ENABLE_ANALYTICS=true
VITE_ENABLE_DEBUG=false

# External Services
VITE_STRIPE_PUBLIC_KEY=your_key_here
VITE_GOOGLE_ANALYTICS_ID=your_id_here
```

### Environment File Verification

```bash
# Check if .env.example exists
test -f .env.example && echo "✓ .env.example exists" || echo "✗ .env.example missing"

# Check if .env.local exists (should be .gitignored)
test -f .env.local && echo "✓ .env.local exists" || echo "✗ .env.local missing"

# Verify .gitignore includes .env
grep -q "\.env\.local" .gitignore && echo "✓ .env.local in .gitignore" || echo "✗ .env.local not gitignored"
```

## IDE and Editor Setup

### VS Code Configuration

Create `.vscode/settings.json`:

```json
{
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "esbenp.prettier-vscode",
  "[typescript]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "[typescriptreact]": {
    "editor.defaultFormatter": "esbenp.prettier-vscode"
  },
  "typescript.tsdk": "node_modules/typescript/lib",
  "typescript.enablePromptUseWorkspaceTsdk": true,
  "eslint.validate": [
    "javascript",
    "javascriptreact",
    "typescript",
    "typescriptreact"
  ]
}
```

Create `.vscode/extensions.json`:

```json
{
  "recommendations": [
    "dbaeumer.vscode-eslint",
    "esbenp.prettier-vscode",
    "bradlc.vscode-tailwindcss",
    "WallabyJs.wallaby-vscode"
  ]
}
```

## Build and Deployment Verification

### Production Build Test

```bash
# Create production build
npm run build

# Check build output
test -d dist && echo "✓ dist/ directory created" || echo "✗ dist/ not found"

# Check bundle size
du -sh dist

# Preview production build
npm run preview

# Test preview server
curl -s http://localhost:4173/ | head -20
```

### Build Output Checklist

```
dist/
├── ✓ index.html           # Entry point
├── ✓ assets/              # Bundled assets
│   ├── ✓ *.js            # JavaScript chunks
│   └── ✓ *.css           # Compiled styles
└── ✓ manifest.json       # Asset manifest (if configured)
```

## Complete Bootstrap Verification Script

Save this as `verify-bootstrap.sh`:

```bash
#!/bin/bash

echo "═══════════════════════════════════════════════"
echo "TanStack Start Bootstrap Verification"
echo "═══════════════════════════════════════════════"

errors=0

# Check Node version
node_version=$(node --version)
echo "✓ Node.js: $node_version"

# Check npm version
npm_version=$(npm --version)
echo "✓ npm: $npm_version"

# Check critical files
for file in package.json tsconfig.json vite.config.ts router.config.ts; do
  if [ -f "$file" ]; then
    echo "✓ $file"
  else
    echo "✗ $file MISSING"
    ((errors++))
  fi
done

# Check src directory structure
for dir in src src/routes src/components; do
  if [ -d "$dir" ]; then
    echo "✓ $dir/"
  else
    echo "✗ $dir/ MISSING"
    ((errors++))
  fi
done

# TypeScript check
echo ""
echo "Running TypeScript check..."
if npm run type-check > /dev/null 2>&1; then
  echo "✓ TypeScript compilation successful"
else
  echo "✗ TypeScript errors found"
  ((errors++))
fi

# Summary
echo ""
echo "═══════════════════════════════════════════════"
if [ $errors -eq 0 ]; then
  echo "✓ Bootstrap verification PASSED"
  exit 0
else
  echo "✗ Bootstrap verification FAILED ($errors issues)"
  exit 1
fi
```

### Run the Script

```bash
chmod +x verify-bootstrap.sh
./verify-bootstrap.sh
```

## Common Bootstrap Issues and Solutions

### Issue: "Cannot find module '@tanstack/start'"

**Solution:**
```bash
npm install @tanstack/start
npm run type-check
```

### Issue: "TypeScript error: Cannot find type definition"

**Solution:**
```bash
npm install -D @types/react @types/react-dom @types/node
npm run type-check
```

### Issue: "Vite dev server won't start"

**Solution:**
```bash
# Clear node_modules and reinstall
rm -rf node_modules package-lock.json
npm install

# Clear Vite cache
rm -rf .vite

npm run dev
```

### Issue: "Port 5173 already in use"

**Solution:**
```bash
# Find process using port 5173
lsof -i :5173

# Kill the process
kill -9 <PID>

# Or use different port
npm run dev -- --port 3000
```

### Issue: "ESM syntax not supported"

**Solution - Check package.json:**
```json
{
  "type": "module",  // This is required
  "scripts": {
    "dev": "vite",
    "build": "vite build"
  }
}
```

## Next Steps After Bootstrap

1. ✓ All checks pass? You're ready to develop!
2. Start building your first route
3. Create server functions for backend logic
4. Implement authentication if needed
5. Set up database connections
6. Configure deployment pipeline

## Debugging Tips

```bash
# Enable detailed logging
DEBUG=* npm run dev

# Check Vite config
npx vite config

# Analyze bundle size
npm run build -- --analyze

# View source maps
npm run build -- --sourcemap

# TypeScript verbose mode
npx tsc --noEmit --listFilesOnly
```

## Quick Command Reference

| Command | Purpose |
|---------|---------|
| `npm run dev` | Start development server |
| `npm run build` | Create production build |
| `npm run preview` | Test production build locally |
| `npm run type-check` | Find TypeScript errors |
| `npm run lint` | Check code quality |
| `npm run format` | Auto-format code |
| `npm audit` | Check for security issues |
| `npm update` | Update dependencies |

Your TanStack Start project is now verified and ready for development!
