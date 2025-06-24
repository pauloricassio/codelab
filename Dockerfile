FROM node:18-bullseye AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y python3 python3-setuptools make g++ curl unzip && ln -sf python3 /usr/bin/python

RUN curl -L -o claat-linux-amd64 https://github.com/googlecodelabs/tools/releases/latest/download/claat-linux-amd64 && \
    chmod +x claat-linux-amd64 && \
    mv claat-linux-amd64 /usr/local/bin/claat

COPY site/package*.json ./site/
RUN cd site && npm install

COPY . .

# Aqui está o ajuste!
RUN cd site/codelabs && \
    find . -name "*.md" | while read md; do \
      dir="${md%.md}"; \
      echo "Verificando $md -> $dir"; \
      if [ ! -d "$dir" ]; then \
        echo "Exportando $md"; \
        claat export "$md"; \
      else \
        echo "Diretório $dir já existe, pulando"; \
      fi; \
    done && \
    echo "Conteúdo de site/codelabs após claat export:" && \
    ls -la .

WORKDIR /app/site
RUN npx gulp dist --codelabs-dir=codelabs

FROM nginx:alpine

ENV TZ=America/Sao_Paulo

RUN rm /etc/nginx/conf.d/default.conf
COPY nginx/nginx.conf /etc/nginx/conf.d/
COPY --from=builder /app/site/dist /usr/share/nginx/html

RUN chmod -R 755 /usr/share/nginx/html && \
    apk add --no-cache bash \
    --allow-untrusted \
    --no-check-certificate \
    tzdata && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone && \
    rm -rf /var/cache/apk/*

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]