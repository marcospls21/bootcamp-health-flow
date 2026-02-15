FROM nginx:alpine

# Copia o HTML para a pasta padrão do Nginx
COPY index.html /usr/share/nginx/html/index.html

# Expõe a porta 80
EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]