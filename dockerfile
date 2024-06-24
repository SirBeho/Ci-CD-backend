# Etapa base
FROM --platform=linux/amd64 node:21-alpine AS base

# Etapa de dependencias
FROM base AS deps

WORKDIR /app

COPY package.json package-lock.json* yarn.lock* ./

# Instalación de dependencias y Nest CLI
RUN npm install -g @nestjs/cli && \
    if [ -f yarn.lock ]; then \
      yarn install --frozen-lockfile; \
    elif [ -f package-lock.json ]; then \
      npm ci; \
    else \
      echo "Archivo de bloqueo no encontrado" && exit 1; \
    fi

# Etapa de construcción
FROM base AS builder

WORKDIR /app

COPY --from=deps /app/node_modules ./node_modules
COPY . .

# Compilación del código
RUN npm run build

# Etapa final
FROM base AS runner

WORKDIR /app

ENV NODE_ENV=production

# Creación de usuario y grupo para seguridad
RUN addgroup --system --gid 1001 aws-test \
    && adduser --system --uid 101 usuario

# Copia de los archivos necesarios desde la etapa de construcción
COPY --from=builder --chown=usuario:aws-test /app/node_modules ./node_modules
COPY --from=builder --chown=usuario:aws-test /app/dist ./dist

USER usuario

EXPOSE 3000

# Comando para ejecutar la aplicación
CMD ["node", "dist/main.js"]
