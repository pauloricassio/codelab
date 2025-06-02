FROM node:18-bullseye AS builder

WORKDIR /app

# Instale dependências de build (python3, make, g++)
RUN apt-get update && apt-get install -y python3 python3-setuptools make g++ && ln -sf python3 /usr/bin/python

# Copiar arquivos de dependências do site
COPY site/package*.json ./site/

# Instalar dependências do site
RUN cd site && npm install

# Copiar código fonte
COPY . .

# Build da aplicação usando Gulp
WORKDIR /app/site
RUN npx gulp dist --codelabs-dir=codelabs

# Estágio 2: Servidor nginx
FROM nginx:alpine

RUN rm /etc/nginx/conf.d/default.conf

COPY nginx.conf /etc/nginx/conf.d/
COPY --from=builder /app/site/dist /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]