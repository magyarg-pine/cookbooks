# React App Generator (`create-react-project.sh`)

A fast, non-interactive, idempotent script to scaffold a React + TypeScript app with Vite, Tailwind, Router, Axios, React Hook Form, Zod, ESLint/Prettier, Vitest, and a production-ready Dockerfile.

## Prerequisites

- Node.js 18+ (Node 20 recommended)
- npm
- Bash (macOS/Linux)

## Usage

```bash
# From this directory
chmod +x client/create-react-project.sh
./client/create-react-project.sh my-app

cd my-app
npm install
npm run dev
```

### Run directly via curl (GitHub Raw)

```bash
curl -fsSL https://raw.githubusercontent.com/magyarg-pine/cookbooks/refs/heads/main/client/create-react-project.sh | bash -s -- my-app
```

### Download locally via curl, then run

```bash
curl -fsSLo create-react-project.sh https://raw.githubusercontent.com/magyarg-pine/cookbooks/refs/heads/main/client/create-react-project.sh
chmod +x create-react-project.sh
./create-react-project.sh my-app
```

- The script is non-interactive. It uses `vite --template react-ts` and proceeds without prompts.
- Re-running the script with the same `my-app` name is supported; it only adds missing scripts and files where safe.

## What it scaffolds

- Vite + React + TypeScript project
- Tailwind via `@tailwindcss/vite` and `src/index.css`
- React Router with `src/routes/app-router.tsx`
- Simple auth demo: `src/hooks/useAuth.ts`, `ProtectedRoute`, and auth pages
- API helper: `src/services/api.ts` with type-only Axios imports (TS5/Vite-safe)
- ESLint + Prettier
- Vitest + Testing Library
- Environment files: `.env`, `.env.development`, `.env.production`
- Dockerfile (multi-stage build) + `.dockerignore`
- Project `README.md` inside the generated app

## Idempotency and non-interactive behavior

- Script removes Vite’s default `src/App.css` and its import to keep the template minimal.
- Package `scripts` are merged via a Node snippet — existing commands are not overwritten.
- Safe to run multiple times; it won’t error on existing script entries.

## Scripts added (if missing)

- `dev`: `vite`
- `build`: `vite build`
- `preview`: `vite preview`
- `lint`: `eslint 'src/**/*.{ts,tsx}'`
- `format`: `prettier --write 'src/**/*.{ts,tsx,css,md}'`
- `test`: `vitest`

## Environment variables

- `VITE_API_URL` — API base URL
- `VITE_FEATURE_NEW_DASHBOARD` — example feature flag

The script creates `.env`, `.env.development`, and `.env.production` with sensible defaults. Adjust as needed.

## Docker

A production Dockerfile is included in each generated project.

```bash
# Build & run
docker build -t my-app:latest .
docker run --rm -p 8080:80 my-app:latest
# Visit http://localhost:8080
```

## Customization

- Edit `client/create-react-project.sh` to tweak dependencies, pages, or generated files.
- Add additional pages/components or env variables in the respective sections.

## License

MIT
