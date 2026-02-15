from flask import Flask, render_template, request, redirect, url_for, session
import psycopg2
from psycopg2.extras import RealDictCursor
import os

app = Flask(__name__)
app.secret_key = 'healthflow-secret-key' # Necessário para usar session

# Configurações de conexão via variáveis de ambiente (EKS)
DB_HOST = os.getenv('DB_HOST')
DB_NAME = os.getenv('DB_NAME', 'healthflowdb')
DB_USER = os.getenv('DB_USER', 'dbadmin')
DB_PASS = os.getenv('DB_PASS', 'Password123!')

def get_db_connection():
    return psycopg2.connect(
        host=DB_HOST,
        database=DB_NAME,
        user=DB_USER,
        password=DB_PASS
    )

@app.route('/')
def login_page():
    return render_template('login.html')

@app.route('/auth', methods=['POST'])
def auth():
    usuario = request.form.get('usuario')
    senha = request.form.get('senha')
    # Autenticação simples para o bootcamp
    if usuario == "admin" and senha == "Password123!":
        session['logado'] = True
        return redirect(url_for('dashboard'))
    return redirect(url_for('login_page', erro="1"))

@app.route('/cadastrar', methods=['POST'])
def cadastrar():
    nome = request.form.get('nome')
    especialidade = request.form.get('especialidade')
    horario = request.form.get('horario')
    
    conn = get_db_connection()
    cur = conn.cursor()
    cur.execute(
        "INSERT INTO consultas (nome, especialidade, horario, status) VALUES (%s, %s, %s, %s)",
        (nome, especialidade, horario, 'Pendente')
    )
    conn.commit()
    cur.close()
    conn.close()
    return redirect(url_for('login_page', msg="sucesso"))

@app.route('/dashboard')
def dashboard():
    if not session.get('logado'):
        return redirect(url_for('login_page'))
    
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    cur.execute("SELECT * FROM consultas ORDER BY horario ASC")
    consultas = cur.fetchall()
    cur.close()
    conn.close()
    
    return render_template('dashboard.html', consultas=consultas)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)