FROM node:18-bullseye AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y python3 python3-setuptools make g++ curl unzip && ln -sf python3 /usr/bin/python

RUN curl -L -o claat-linux-amd64 https://github.com/googlecodelabs/tools/releases/latest/download/claat-linux-amd64 && \
    chmod +x claat-linux-amd64 && \
    mv claat-linux-amd64 /usr/local/bin/claat

COPY site/package*.json ./site/
RUN cd site && npm install

COPY . .

RUN cd site/codelabs && \
    find . -name "*.md" ! -name "how-to-write-a-codelab.md" | while read md; do \
      echo "Exportando $md"; \
      claat export "$md"; \
    done && \
    echo "Conteúdo de site/codelabs após claat export:" && \
    ls -la .

WORKDIR /app/site
RUN npx gulp dist --codelabs-dir=codelabs

# Adicionar CSS para ocultar o link "Report a mistake"
RUN find dist -name "*.html" -type f -exec sed -i 's|</head>|<style>.feedback-link, [href*="mistake"], [href*="report"] { display: none !important; }</style></head>|g' {} \;

FROM nginx:alpine

ENV TZ=America/Sao_Paulo

# Verificar se o arquivo nginx.conf existe antes de copiar
COPY nginx/nginx.conf /etc/nginx/conf.d/default.conf

COPY --from=builder /app/site/dist /usr/share/nginx/html

RUN chmod -R 755 /usr/share/nginx/html && \
    apk add --no-cache bash tzdata && \
    cp /usr/share/zoneinfo/${TZ} /etc/localtime && \
    echo "${TZ}" > /etc/timezone

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]