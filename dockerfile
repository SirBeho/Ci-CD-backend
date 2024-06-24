# Define la imagen base
FROM --platform=linux/amd64 node:21-alpine AS base

# Etapa para instalación de dependencias
FROM base AS deps

WORKDIR /app

# Copia los archivos de configuración de dependencias
COPY package.json yarn.lock* package-lock.json*  ./

# Instalación de dependencias utilizando yarn o npm, dependiendo del tipo de lockfile presente
RUN \
    if [ -f yarn.lock ]; then yarn --frozen-lockfile; \
    elif [ -f package-lock.json ]; then npm ci; \
    else echo "Lockfile not found." && exit 1; \
    fi

# Etapa para construcción de la aplicación
FROM base AS builder

WORKDIR /app

# Copia los módulos de node_modules desde la etapa de dependencias
COPY --from=deps /app/node_modules ./node_modules

# Copia todo el código fuente del proyecto
COPY . .

# Compila la aplicación Nest.js
RUN yarn build

# Etapa para correr la aplicación
FROM base AS runner

WORKDIR /app

# Configura el entorno de ejecución para producción
ENV NODE_ENV production

# Crea un grupo y un usuario para ejecutar la aplicación
RUN addgroup --system --gid 1001 aws-test \
    && adduser --system --uid 101 user

# Copia los módulos de node_modules y el código compilado desde la etapa de construcción
COPY --from=builder --chown=user:aws-test /app/node_modules/ ./node_modules/
COPY --from=builder --chown=user:aws-test /app/dist/ ./dist/

# Establece el usuario para ejecutar la aplicación
USER user

# Expone el puerto 3000 (el puerto en el que se ejecutará la aplicación)
EXPOSE 3000

# Comando para ejecutar la aplicación
CMD ["node", "dist/main.js"]
