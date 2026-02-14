# Usa uma imagem Nginx super leve (Alpine Linux)
FROM nginx:alpine

# Remove a página padrão do Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia seus arquivos (HTML e o Vídeo) para a pasta do servidor
COPY . /usr/share/nginx/html

# O Nginx já expõe a porta 80 por padrão, então não precisa do EXPOSE manual