from flask import Flask, render_template, request, redirect, url_for
import os

app = Flask(__name__)

# Simulação de Banco de Dados
agendamentos = []

@app.route('/')
def index():
    return render_template('login.html')

@app.route('/login', methods=['POST'])
def login():
    # Login Fake para demo
    return redirect(url_for('dashboard'))

@app.route('/dashboard')
def dashboard():
    return render_template('dashboard.html', agendamentos=agendamentos)

@app.route('/agendar', methods=['POST'])
def agendar():
    especialidade = request.form.get('especialidade')
    data = request.form.get('data')
    agendamentos.append({'especialidade': especialidade, 'data': data})
    return redirect(url_for('dashboard'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)