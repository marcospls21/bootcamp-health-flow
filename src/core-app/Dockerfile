FROM python:3.9-slim

WORKDIR /app

# Instala o Flask
RUN pip install flask

# Copia o código da aplicação
COPY app.py .

# Copia a pasta de templates (HTMLs) para dentro da imagem
COPY templates ./templates

# Expõe a porta 80
EXPOSE 80

CMD ["python", "app.py"]