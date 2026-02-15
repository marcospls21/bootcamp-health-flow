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
    # Correção dos erros F841 e F821: Garantindo que as variáveis são usadas
    usuario_input = request.form.get('usuario') 
    senha_input = request.form.get('senha')

    # 1. Backdoor para Admin (Hardcoded para testes)
    # Aqui usamos as variáveis definidas acima
    if usuario_input == "admin" and senha_input == "Password123!":
        return redirect(url_for('dashboard'))
    
    # 2. Verifica na tabela de usuários reais
    try:
        conn = get_db_connection()
        # Correção do erro F401: Usando o RealDictCursor importado
        cur = conn.cursor(cursor_factory=RealDictCursor)
        
        cur.execute("SELECT * FROM usuarios WHERE email = %s AND senha = %s", (usuario_input, senha_input))
        user = cur.fetchone()
        
        cur.close()
        conn.close()

        if user:
            # Correção do erro F401: Usando redirect e url_for importados
            return redirect(url_for('dashboard'))
        else:
            return redirect(url_for('index'))
    except Exception as e:
        print(f"Erro no login: {e}")
        return redirect(url_for('index'))

# --- ROTAS DO DASHBOARD (COM ESTATÍSTICAS) ---

@app.route('/dashboard')
def dashboard():
    """Exibe o Dashboard com gráficos e dados do banco"""
    conn = get_db_connection()
    cur = conn.cursor(cursor_factory=RealDictCursor)
    
    # 1. Busca a lista de consultas
    cur.execute("SELECT * FROM consultas ORDER BY horario ASC")
    consultas = cur.fetchall()
    
    # 2. Conta o total de pacientes cadastrados
    cur.execute("SELECT COUNT(*) as total FROM usuarios")
    resultado_pacientes = cur.fetchone()
    total_pacientes = resultado_pacientes['total'] if resultado_pacientes else 0
    
    cur.close()
    conn.close()
    
    return render_template('dashboard.html', 
                           consultas=consultas, 
                           total_pacientes=total_pacientes, 
                           total_hoje=len(consultas))

@app.route('/cadastrar', methods=['POST'])
def cadastrar():
    """Cadastra uma nova consulta médica (Modal do Dashboard)"""
    nome = request.form.get('nome')
    especialidade = request.form.get('especialidade')
    horario = request.form.get('horario')
    
    try:
        conn = get_db_connection()
        cur = conn.cursor()
        cur.execute("INSERT INTO consultas (nome, especialidade, horario) VALUES (%s, %s, %s)",
                    (nome, especialidade, horario))
        conn.commit()
        cur.close()
        conn.close()
    except Exception as e:
        print(f"Erro ao agendar: {e}")
        
    return redirect(url_for('dashboard'))

# --- ROTAS DE CADASTRO DE USUÁRIO (PACIENTE) ---

@app.route('/cadastro_usuario')
def cadastro_usuario():
    """Exibe a tela de cadastro"""
    return render_template('cadastro_usuario.html')

@app.route('/salvar_usuario', methods=['POST'])
def salvar_usuario():
    """Recebe os dados do formulário completo e salva no banco"""
    nome = request.form.get('nome_completo')
    email = request.form.get('email')
    cpf = request.form.get('cpf')
    telefone = request.form.get('telefone')
    cep = request.form.get('cep')
    rua = request.form.get('rua')
    numero = request.form.get('numero')
    complemento = request.form.get('complemento')
    senha = request.form.get('senha')

    try:
        conn = get_db_connection()
        cur = conn.cursor()
        
        cur.execute("""
            INSERT INTO usuarios (nome_completo, email, cpf, telefone, cep, rua, numero, complemento, senha)
            VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
        """, (nome, email, cpf, telefone, cep, rua, numero, complemento, senha))
        
        conn.commit()
        cur.close()
        conn.close()
        print(f"Novo usuário cadastrado: {nome}")
        return redirect(url_for('index'))
    except Exception as e:
        print(f"Erro ao cadastrar usuário: {e}")
        return f"Erro ao salvar no banco (Verifique logs): {e}"

# --- INICIALIZAÇÃO ---
if __name__ == '__main__':
    init_db()
    app.run(host='0.0.0.0', port=5000)