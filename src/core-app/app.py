import os
import psycopg2
from flask import Flask, render_template, request, redirect, url_for
from psycopg2.extras import RealDictCursor

app = Flask(__name__)

# --- CONFIGURAÇÃO DO BANCO DE DADOS ---
def get_db_connection():
    """Estabelece a conexão com o banco RDS usando variáveis de ambiente."""
    conn = psycopg2.connect(
        host=os.environ.get('DB_HOST'),
        database=os.environ.get('DB_NAME'),
        user=os.environ.get('DB_USER'),
        password=os.environ.get('DB_PASS'),
        port=5432
    )
    return conn

def init_db():
    """Inicializa as tabelas necessárias no banco de dados se não existirem."""
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        # 1. Tabela de Consultas (Para o Dashboard)
        # Mantemos simples para o lab: apenas horário (sem data específica)
        cur.execute("""
            CREATE TABLE IF NOT EXISTS consultas (
                id SERIAL PRIMARY KEY,
                nome VARCHAR(100) NOT NULL,
                especialidade VARCHAR(100) NOT NULL,
                horario VARCHAR(20) NOT NULL,
                status VARCHAR(20) DEFAULT 'Pendente'
            );
        """)
        
        # 2. Tabela de Usuários (Para Login e Cadastro Completo)
        # Contém todos os campos do formulário novo
        cur.execute("""
            CREATE TABLE IF NOT EXISTS usuarios (
                id SERIAL PRIMARY KEY,
                nome_completo VARCHAR(150) NOT NULL,
                email VARCHAR(100) UNIQUE NOT NULL,
                cpf VARCHAR(20) UNIQUE NOT NULL,
                telefone VARCHAR(20),
                cep VARCHAR(15),
                rua VARCHAR(150),
                numero VARCHAR(20),
                complemento VARCHAR(100),
                senha VARCHAR(100) NOT NULL
            );
        """)
        
        conn.commit()
        cur.close()
        conn.close()
        print("✅ Banco de dados inicializado com sucesso!")
    except Exception as e:
        print(f"❌ Erro ao inicializar banco: {e}")

# --- ROTAS DE NAVEGAÇÃO E LOGIN ---

@app.route('/')
def index():
    return render_template('login.html')

@app.route('/auth', methods=['POST'])
def auth():
    """Verifica o login do usuário (Admin ou Usuário do Banco)"""
    usuario_input = request.form.get('usuario') 
    senha_input