FROM nginx:1.25-alpine

# Remove a página padrão do Nginx
RUN rm -rf /usr/share/nginx/html/*

# Copia o index.html
COPY index.html /usr/share/nginx/html/index.html

# --- ADICIONE ESTA LINHA ---
# Copia o arquivo de vídeo para a mesma pasta pública do Nginx
COPY arquitetura.mp4 /usr/share/nginx/html/arquitetura.mp4
# ---------------------------

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]