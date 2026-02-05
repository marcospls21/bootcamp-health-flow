from flask import Flask, render_template

# Define que a pasta de templates está no diretório local
app = Flask(__name__, template_folder='templates')

@app.route('/')
def home():
    # Renderiza a página inicial (index.html)
    return render_template('index.html')

@app.route('/index.html')
def index_redirect():
    return render_template('index.html')

@app.route('/login.html')
def login():
    # Renderiza a página de login
    return render_template('login.html')

# Rota de verificação de saúde (Health Check) para o Kubernetes
@app.route('/health')
def health():
    return "OK", 200

if __name__ == "__main__":
    app.run(host='0.0.0.0', port=80)