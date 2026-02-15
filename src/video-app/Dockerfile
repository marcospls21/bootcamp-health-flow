# Usa imagem leve do Nginx
FROM nginx:alpine

# Remove arquivos padrões
RUN rm -rf /usr/share/nginx/html/*

# Copia nosso HTML para a pasta pública
COPY index.html /usr/share/nginx/html/index.html

# Expõe a porta 80
EXPOSE 80

# Roda o servidor
CMD ["nginx", "-g", "daemon off;"]