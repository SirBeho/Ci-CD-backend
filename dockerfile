# Etapa base
FROM node:14-alpine AS base

# Etapa de construcción
FROM base AS build

WORKDIR /app

# Copiar archivos necesarios para la instalación de dependencias
COPY package.json yarn.lock ./

# Instalación de dependencias
RUN yarn install --frozen-lockfile

# Copiar el resto de los archivos del proyecto
COPY . .

# Compilar la aplicación React
RUN yarn build

# Etapa final
FROM nginx:alpine

# Copiar los archivos compilados desde la etapa de construcción a NGINX
COPY --from=build /app/build /usr/share/nginx/html

# Configuración opcional de NGINX (si se necesita)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Exponer el puerto 80 para que sea accesible desde el exterior
EXPOSE 80

# Comando para iniciar NGINX en primer plano
CMD ["nginx", "-g", "daemon off;"]
