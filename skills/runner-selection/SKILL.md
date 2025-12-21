---
name: tanstack:runner-selection
description: Select and configure the appropriate package manager based on project configuration
---

# Package Manager Runner Selection

This skill helps you identify the correct package manager for your TanStack Start project and provides all necessary commands for common development tasks.

## Automatic Runner Detection

TanStack Start works with multiple package managers. The skill automatically detects which one is configured in your project by checking:

### Detection Method

The detection system checks files in this order:

1. **`pnpm-lock.yaml`** → Uses **pnpm**
2. **`yarn.lock`** → Uses **yarn**
3. **`package-lock.json`** → Uses **npm**
4. **`bun.lockb`** → Uses **bun**
5. **No lock file** → Defaults to **npm**

### Check Your Current Runner

```bash
# View installed package managers
which npm
which yarn
which pnpm
which bun

# Check Node version compatibility
node --version

# View your lock file
ls -la | grep -E "(lock|bun\.lockb)"
```

## Package Manager Details

### npm (Default)

**Installation:**
```bash
# npm comes with Node.js
node --version
npm --version
```

**Common Commands:**
```bash
npm install                    # Install all dependencies
npm install <package>          # Add a package
npm install -D <package>       # Add dev dependency
npm uninstall <package>        # Remove a package
npm update                      # Update all packages
npm update <package>           # Update specific package
npm list                        # Show installed packages
npm outdated                    # Show outdated packages
npm run dev                     # Start development server
npm run build                   # Create production build
npm run preview                 # Preview production build
npm run type-check             # Type check with TypeScript
npm run lint                    # Run linter
npm run format                  # Format code
npm test                        # Run tests
npm ci                          # Clean install (CI/CD)
npm cache clean --force         # Clear npm cache
npm audit                       # Check for security issues
npm audit fix                   # Auto-fix security issues
```

**Configuration:**
```bash
# View npm config
npm config list

# Set npm registry
npm config set registry https://registry.npmjs.org/

# Set default package manager version
npm config set save-exact true

# View global installations
npm list -g --depth=0
```

**Use When:**
- You're starting a new project
- You need broad ecosystem support
- You prefer default tooling
- Your team standardizes on npm

---

### yarn (v1.x and v3.x+)

**Installation:**
```bash
# Using npm
npm install -g yarn

# Or using Homebrew (macOS)
brew install yarn

# Verify installation
yarn --version
```

**Common Commands:**
```bash
yarn install                    # Install dependencies from yarn.lock
yarn add <package>              # Add a package
yarn add -D <package>           # Add dev dependency
yarn remove <package>           # Remove a package
yarn upgrade                    # Update all packages
yarn upgrade <package>          # Update specific package
yarn list                        # Show installed packages
yarn outdated                    # Show outdated packages
yarn dev                         # Start development server
yarn build                       # Create production build
yarn preview                     # Preview production build
yarn type-check                  # Type check with TypeScript
yarn lint                        # Run linter
yarn format                      # Format code
yarn test                        # Run tests
yarn cache clean                 # Clear yarn cache
yarn audit                       # Check for security issues
yarn audit --fix                 # Auto-fix security issues
yarn why <package>               # Explain package dependency
```

**Workspace Commands (monorepo):**
```bash
yarn workspaces list             # List all workspaces
yarn workspace <name> add <pkg>  # Add to specific workspace
yarn workspaces run build        # Run script in all workspaces
```

**Use When:**
- Your team prefers yarn's UX
- You're working with monorepos (Yarn Workspaces)
- You need better dependency resolution
- You want deterministic installs

---

### pnpm (Fast, Disk Efficient)

**Installation:**
```bash
# Using npm
npm install -g pnpm

# Or using Homebrew (macOS)
brew install pnpm

# Verify installation
pnpm --version

# Check pnpm configuration
pnpm config list
```

**Common Commands:**
```bash
pnpm install                    # Install dependencies
pnpm add <package>              # Add a package
pnpm add -D <package>           # Add dev dependency
pnpm remove <package>           # Remove a package
pnpm update                      # Update all packages
pnpm update <package>           # Update specific package
pnpm list                        # Show installed packages
pnpm outdated                    # Show outdated packages
pnpm dev                         # Start development server
pnpm build                       # Create production build
pnpm preview                     # Preview production build
pnpm type-check                  # Type check with TypeScript
pnpm lint                        # Run linter
pnpm format                      # Format code
pnpm test                        # Run tests
pnpm store status                # Check store integrity
pnpm store prune                 # Clean unused packages
pnpm audit                       # Check for security issues
pnpm why <package>               # Explain package dependency
```

**Workspace Commands (monorepo):**
```bash
pnpm list -r                     # List all packages recursively
pnpm add <pkg> -r               # Add to all workspaces
pnpm -r build                   # Run build in all workspaces
pnpm -r --filter=<name> build   # Run in specific workspace
```

**Features:**
- **Speed**: 3-4x faster than npm
- **Disk Space**: Uses content-addressable storage (70% less space)
- **Monorepo Support**: Native workspaces support
- **Strict Mode**: Prevents phantom dependencies

**Use When:**
- You need optimal disk space usage
- Your project has many dependencies
- You're building a monorepo
- You want the fastest install times

---

### bun (All-in-One Runtime)

**Installation:**
```bash
# Using curl (recommended)
curl -fsSL https://bun.sh/install | bash

# Using Homebrew (macOS)
brew install bun

# Verify installation
bun --version

# Check bun configuration
bun config
```

**Common Commands:**
```bash
bun install                     # Install dependencies
bun add <package>               # Add a package
bun add -d <package>            # Add dev dependency
bun remove <package>            # Remove a package
bun update                       # Update all packages
bun update <package>            # Update specific package
bun pm list                      # Show installed packages
bun outdated                     # Show outdated packages
bun dev                          # Start development server
bun run build                    # Create production build
bun run preview                  # Preview production build
bun run type-check               # Type check with TypeScript
bun run lint                     # Run linter
bun run format                   # Format code
bun test                         # Run tests
bun cache clean                  # Clear bun cache
bun audit                        # Check for security issues
bun why <package>                # Explain package dependency
```

**Special Features:**
```bash
bun bunfig.toml                  # Configure bun settings
bun create <template>            # Create new project from template
bun run --watch <file>          # Watch and run file
bun --hot dev                    # Start with hot reload
```

**Benefits:**
- **Speed**: Fastest package installation
- **Built-in Tooling**: No need for separate bundler
- **TypeScript Native**: Built-in TypeScript support
- **All-in-One**: Runtime + Package manager + Test runner + Bundler

**Use When:**
- You need maximum performance
- You want a unified toolchain
- You're starting a new modern project
- Your team is comfortable with cutting-edge tools

---

## Decision Tree

```
Does your project have a lock file?
│
├─ pnpm-lock.yaml ──────────────────→ USE: pnpm
│
├─ yarn.lock ──────────────────────→ USE: yarn
│
├─ package-lock.json ──────────────→ USE: npm
│
├─ bun.lockb ──────────────────────→ USE: bun
│
└─ No lock file?
   │
   ├─ Team preference for pnpm? ──→ USE: pnpm
   ├─ Monorepo setup? ────────────→ USE: pnpm or yarn
   ├─ Prefer built-in tooling? ──→ USE: bun
   └─ Standard/safe choice? ─────→ USE: npm
```

## Switching Package Managers

### From npm to pnpm

```bash
# Delete npm lock file
rm package-lock.json

# Delete node_modules
rm -rf node_modules

# Install with pnpm
pnpm install
```

### From npm to yarn

```bash
# Delete npm lock file
rm package-lock.json

# Install yarn globally
npm install -g yarn

# Install with yarn
yarn install
```

### From any to bun

```bash
# Install bun
curl -fsSL https://bun.sh/install | bash

# Delete old lock files
rm -f package-lock.json yarn.lock pnpm-lock.yaml

# Install with bun
bun install
```

**WARNING**: After switching managers, commit the new lock file and inform your team.

## Monorepo Considerations

### npm Workspaces
```bash
# In package.json
{
  "workspaces": ["packages/*"]
}

npm install
npm -w packages/ui run build
```

### yarn Workspaces
```bash
# In package.json
{
  "workspaces": ["packages/*"]
}

yarn install
yarn workspace ui build
```

### pnpm Workspaces (Recommended)
```bash
# In pnpm-workspace.yaml
packages:
  - 'packages/*'

pnpm install
pnpm -r --filter ui build
```

### bun Workspaces
```bash
# In bunfig.toml
[workspaces]
root = "packages/*"

bun install
bun --filter ui run build
```

## Performance Comparison

| Metric | npm | yarn | pnpm | bun |
|--------|-----|------|------|-----|
| Install Speed | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| Disk Usage | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| Lock File Size | Medium | Small | Medium | Medium |
| Workspace Support | Basic | Good | Excellent | Good |
| Community Size | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | Growing |
| Stability | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ |

## Environment Variables

Most package managers support environment variables for configuration:

```bash
# npm
npm_config_registry=https://registry.npmjs.org/
npm_config_fetch_timeout=60000

# yarn
YARN_REGISTRY=https://registry.npmjs.org/

# pnpm
PNPM_HOME=/path/to/pnpm

# bun
BUN_REGISTRY=https://registry.npmjs.org/
```

Set in `.env` or shell profile for persistence.

## Troubleshooting

### "Command not found"

```bash
# Check if installed
which <package-manager>

# Check npm global packages
npm list -g --depth=0

# Reinstall globally
npm install -g <package-manager>

# Add to PATH (if necessary)
export PATH="$PATH:~/.local/bin"
```

### Conflicting Versions

```bash
# Completely clear caches
npm cache clean --force
yarn cache clean
pnpm store prune
bun cache clean

# Reinstall from scratch
rm -rf node_modules
rm -f package-lock.json yarn.lock pnpm-lock.yaml

# Fresh install
npm install  # or yarn install, pnpm install, bun install
```

### Lock File Issues

```bash
# Generate new lock file
rm <lock-file>
npm install  # generates package-lock.json

# Update existing lock file without changing dependencies
npm ci
```

## Next Steps

After selecting your runner:
1. Run `tanstack:bootstrap-check` to verify full project setup
2. Execute development commands with your chosen runner
3. Configure CI/CD with the appropriate runner commands
4. Document your choice in project README
