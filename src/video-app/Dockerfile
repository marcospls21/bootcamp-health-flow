# Base ultra-leve
FROM nginx:alpine

# Metadados
LABEL maintainer="Equipe SRE HealthFlow"
LABEL description="Frontend de Telemedicina WebRTC"

# Remove a página padrão do Nginx para evitar confusão
RUN rm -rf /usr/share/nginx/html/*

# Copia nosso HTML para a pasta pública do servidor
COPY index.html /usr/share/nginx/html/index.html

# Ajuste de permissões (opcional, boa prática de segurança)
RUN chmod 644 /usr/share/nginx/html/index.html

# Expõe a porta padrão HTTP
EXPOSE 80

# Inicia o Nginx em primeiro plano
CMD ["nginx", "-g", "daemon off;"]