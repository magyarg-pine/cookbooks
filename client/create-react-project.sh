#!/bin/bash
APP_NAME=$1

if [ -z "$APP_NAME" ]; then
  echo "❌ Please provide a project name! Example: ./create-project.sh my-app"
  exit 1
fi

echo "🚀 Creating project: $APP_NAME"

npm create vite@latest $APP_NAME -- --template react-ts
cd $APP_NAME

# Remove unused default styling file and its import to avoid noise
rm -f src/App.css || true
if [ -f src/App.tsx ]; then
  sed -i.bak '/App.css/d' src/App.tsx && rm -f src/App.tsx.bak || true
fi

npm install tailwindcss @tailwindcss/vite react-router-dom axios react-hook-form @hookform/resolvers zod
npm install -D eslint prettier eslint-config-prettier eslint-plugin-react eslint-plugin-react-hooks vitest @testing-library/react @testing-library/jest-dom @testing-library/user-event jsdom

# Vite config
cat > vite.config.ts <<EOL
import { defineConfig } from "vite";
import react from "@vitejs/plugin-react";
import tailwindcss from "@tailwindcss/vite";

export default defineConfig({
  plugins: [react(), tailwindcss()],
});
EOL

cat > src/index.css <<EOL
@import "tailwindcss";
EOL

# Folder structure
mkdir -p src/{pages,layouts,components/ui,services,routes,config,hooks,pages/auth,tests}

# .env files
echo "VITE_API_URL=https://dev.api.example.com" > .env.development
echo "VITE_API_URL=https://api.example.com" > .env.production
echo "VITE_FEATURE_NEW_DASHBOARD=true" >> .env.development
echo "VITE_FEATURE_NEW_DASHBOARD=false" >> .env.production
echo "VITE_API_URL=https://dev.api.example.com" > .env
echo "VITE_FEATURE_NEW_DASHBOARD=true" >> .env

# Config
cat > src/config/index.ts <<EOL
const API_URL = import.meta.env.VITE_API_URL || "https://api.example.com";

export const config = {
  apiUrl: API_URL,
  featureFlags: {
    newDashboard: import.meta.env.VITE_FEATURE_NEW_DASHBOARD === "true",
  },
};
EOL

# Hooks
cat > src/hooks/useAuth.ts <<EOL
import { useState, useEffect } from "react";

export function useAuth() {
  const [user, setUser] = useState<string | null>(null);

  useEffect(() => {
    const storedUser = localStorage.getItem("user");
    if (storedUser) setUser(storedUser);
  }, []);

  const login = (username: string) => {
    localStorage.setItem("user", username);
    setUser(username);
  };

  const logout = () => {
    localStorage.removeItem("user");
    setUser(null);
  };

  return { user, login, logout };
}
EOL

# Layout
cat > src/layouts/main-layout.tsx <<EOL
import { Outlet, Link } from "react-router-dom";

export default function MainLayout() {
  return (
    <div className="min-h-screen bg-gray-100">
      <nav className="bg-white shadow px-4 py-2">
        <ul className="flex gap-4">
          <li><Link to="/">Home</Link></li>
          <li><Link to="/dashboard">Dashboard</Link></li>
          <li><Link to="/login">Login</Link></li>
          <li><Link to="/register">Register</Link></li>
        </ul>
      </nav>
      <main className="p-4">
        <Outlet />
      </main>
    </div>
  );
}
EOL

# Pages
cat > src/pages/home.tsx <<EOL
export default function Home() {
  return <h1 className="text-2xl font-bold">Welcome Home!</h1>;
}
EOL

cat > src/pages/dashboard.tsx <<EOL
import ProtectedRoute from "../components/ui/protected-route";

export default function DashboardWrapper() {
  return (
    <ProtectedRoute>
      <Dashboard />
    </ProtectedRoute>
  );
}

function Dashboard() {
  return <h1 className="text-2xl font-bold">Dashboard</h1>;
}
EOL

# Auth pages with Zod
cat > src/pages/auth/login.tsx <<EOL
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { fetchData } from "../../services/api";
import Button from "../../components/ui/button";
import { useAuth } from "../../hooks/useAuth";

const loginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

type LoginForm = z.infer<typeof loginSchema>;

export default function Login() {
  const { register, handleSubmit, formState: { errors } } = useForm<LoginForm>({
    resolver: zodResolver(loginSchema)
  });
  const { login } = useAuth();

  const onSubmit = async (data: LoginForm) => {
    try {
      const response = await fetchData("POST", "auth/login", data);
      login(data.email);
      console.log("Login success:", response);
    } catch (err) {
      console.error("Login error:", err);
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-2 max-w-sm mx-auto">
      <input {...register("email")} placeholder="Email" className="border p-2 rounded" />
      {errors.email && <span className="text-red-500">{errors.email.message}</span>}
      <input type="password" {...register("password")} placeholder="Password" className="border p-2 rounded" />
      {errors.password && <span className="text-red-500">{errors.password.message}</span>}
      <Button type="submit">Login</Button>
    </form>
  );
}
EOL

cat > src/pages/auth/register.tsx <<EOL
import { useForm } from "react-hook-form";
import { zodResolver } from "@hookform/resolvers/zod";
import * as z from "zod";
import { fetchData } from "../../services/api";
import Button from "../../components/ui/button";

const registerSchema = z.object({
  email: z.string().email(),
  password: z.string().min(6),
});

type RegisterForm = z.infer<typeof registerSchema>;

export default function Register() {
  const { register, handleSubmit, formState: { errors } } = useForm<RegisterForm>({
    resolver: zodResolver(registerSchema)
  });

  const onSubmit = async (data: RegisterForm) => {
    try {
      const response = await fetchData("POST", "auth/register", data);
      console.log("Register success:", response);
    } catch (err) {
      console.error("Register error:", err);
    }
  };

  return (
    <form onSubmit={handleSubmit(onSubmit)} className="flex flex-col gap-2 max-w-sm mx-auto">
      <input {...register("email")} placeholder="Email" className="border p-2 rounded" />
      {errors.email && <span className="text-red-500">{errors.email.message}</span>}
      <input type="password" {...register("password")} placeholder="Password" className="border p-2 rounded" />
      {errors.password && <span className="text-red-500">{errors.password.message}</span>}
      <Button type="submit">Register</Button>
    </form>
  );
}
EOL

# Router
cat > src/routes/app-router.tsx <<EOL
import { createBrowserRouter } from "react-router-dom";
import MainLayout from "../layouts/main-layout";
import Home from "../pages/home";
import DashboardWrapper from "../pages/dashboard";
import Login from "../pages/auth/login";
import Register from "../pages/auth/register";

const router = createBrowserRouter([
  {
    path: "/",
    element: <MainLayout />,
    children: [
      { path: "/", element: <Home /> },
      { path: "/dashboard", element: <DashboardWrapper /> },
      { path: "/login", element: <Login /> },
      { path: "/register", element: <Register /> },
    ],
  },
]);

export default router;
EOL

# Main
cat > src/main.tsx <<EOL
import React from "react";
import ReactDOM from "react-dom/client";
import { RouterProvider } from "react-router-dom";
import "./index.css";
import router from "./routes/app-router";

ReactDOM.createRoot(document.getElementById("root")!).render(
  <React.StrictMode>
    <RouterProvider router={router} />
  </React.StrictMode>
);
EOL

# API service
cat > src/services/api.ts <<EOL
import axios, { type AxiosRequestConfig } from "axios";
import { config } from "../config";

export async function fetchData(
  method: "GET" | "POST" | "PUT" | "DELETE",
  endpoint: string,
  data?: any,
  token?: string
) {
  const axiosConfig: AxiosRequestConfig = {
    method,
    url: \`\${config.apiUrl}/\${endpoint}\`,
    headers: token ? { Authorization: \`Bearer \${token}\` } : {},
    data,
  };
  try {
    const response = await axios(axiosConfig);
    return response.data;
  } catch (err: any) {
    console.error("API Error:", err.response?.data || err.message);
    throw err;
  }
}
EOL

# UI Button
cat > src/components/ui/button.tsx <<EOL
type ButtonProps = {
  children: React.ReactNode;
  onClick?: () => void;
  type?: "button" | "submit" | "reset";
};

export default function Button({ children, onClick, type = "button" }: ButtonProps) {
  return (
    <button
      type={type}
      onClick={onClick}
      className="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700"
    >
      {children}
    </button>
  );
}
EOL

# ProtectedRoute in components/ui
cat > src/components/ui/protected-route.tsx <<EOL
import { Navigate } from "react-router-dom";
import { useAuth } from "../../hooks/useAuth";

type ProtectedRouteProps = { children: JSX.Element };

export default function ProtectedRoute({ children }: ProtectedRouteProps) {
  const { user } = useAuth();
  if (!user) return <Navigate to="/login" replace />;
  return children;
}
EOL

# .gitignore
cat > .gitignore <<EOL
node_modules
dist
.vite
.env
.DS_Store
coverage
EOL

# .dockerignore
cat > .dockerignore <<EOL
node_modules
dist
.vite
.env
EOL

# Dockerfile
cat > Dockerfile <<EOL
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=build /app/dist /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
EOL

# README
cat > README.md <<EOL
# \\${APP_NAME}

A React + TypeScript + Vite starter with Tailwind, Router, Axios, React Hook Form, Zod, ESLint, Prettier, and Vitest.

## Tech Stack
- React + TypeScript via Vite
- Tailwind CSS (via @tailwindcss/vite)
- React Router
- Axios
- React Hook Form + Zod
- ESLint + Prettier
- Vitest + Testing Library

## Getting Started
```bash
npm install
npm run dev
```

Open http://localhost:5173

## Scripts
- dev: start Vite dev server
- build: production build
- preview: preview production build
- lint: run ESLint
- format: run Prettier
- test: run Vitest

## Environment
Configure API base URL and feature flags via `.env*` files:
- VITE_API_URL
- VITE_FEATURE_NEW_DASHBOARD

Examples are created for development and production in `.env.development` and `.env.production`.

## API Helper
`src/services/api.ts` wraps Axios. It uses a type-only import for Axios types compatible with Vite/TS5.

## Routing / Auth
Routes are defined in `src/routes/app-router.tsx`. A simple `ProtectedRoute` is provided in `src/components/ui/protected-route.tsx` and a demo `useAuth` hook in `src/hooks/useAuth.ts`.

## Styling
Tailwind is configured via `src/index.css` using `@import "tailwindcss";`.

## Testing
```bash
npm run test
```

## Docker
A multi-stage Dockerfile is provided.
Build and run:
```bash
docker build -t \\${APP_NAME}:latest .
docker run --rm -p 8080:80 \\${APP_NAME}:latest
```
Open http://localhost:8080

## Project Structure
```
src/
  components/ui/
  config/
  hooks/
  layouts/
  pages/
    auth/
  routes/
  services/
  tests/
```

## Notes
- The generator removes `src/App.css` and its import to keep the template minimal.
- Scripts are added idempotently; re-running the generator won't duplicate entries.

EOL

# Update package.json scripts safely (idempotent, no prompts)
node - <<'NODE'
const fs = require('fs');
const pkgPath = 'package.json';
const pkg = JSON.parse(fs.readFileSync(pkgPath, 'utf8'));
pkg.scripts = pkg.scripts || {};
const desired = {
  lint: "eslint 'src/**/*.{ts,tsx}'",
  format: "prettier --write 'src/**/*.{ts,tsx,css,md}'",
  test: "vitest",
  dev: "vite",
  build: "vite build",
  preview: "vite preview",
};
for (const [k, v] of Object.entries(desired)) {
  if (!pkg.scripts[k]) pkg.scripts[k] = v;
}
fs.writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n');
NODE

echo "✅ Project ready!"
echo "cd $APP_NAME && npm install && npm run dev"
