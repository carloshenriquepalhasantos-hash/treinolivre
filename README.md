## 📱 Demonstração Visual do Aplicativo

| **Tela de Login / Autenticação** | **Acesso via E-mail** |
| :---: | :---: |
| <img width="720" height="1600" alt="1" src="https://github.com/user-attachments/assets/97b93034-6762-4e5f-aa3f-27be4bd2e2b1" />  |
 <img width="720" height="1600" alt="2" src="https://github.com/user-attachments/assets/1e7d0cb7-f022-4bdd-ad89-05031ce869fd" />  |
| *Tela de boas-vindas com suporte a múltiplos provedores de autenticação social (Google, Facebook, Instagram) e E-mail.* | *Interface de login por credenciais com validação e segurança integradas ao Firebase Auth.* |

| **Cadastro de Atleta** | **Dashboard Principal** |
| :---: | :---: |
| <img width="720" height="1600" alt="3" src="https://github.com/user-attachments/assets/6716dd95-4c47-4463-9a20-f1dee42646e1" /> |
 <img width="720" height="1600" alt="4" src="https://github.com/user-attachments/assets/e6a4fabc-7e9d-4f5d-86d2-7405a2e510c8" />  |
| *Formulário de registo detalhado recolhendo dados antropométricos, objetivos e informações de contato do utilizador.* | *Painel principal com indicadores em tempo real, monitorização de hidratação, peso, treinos e acesso rápido à dieta.* |

| **Fichas de Treino** | **Plano Nutricional (Dieta)** |
| :---: | :---: |
| <img width="720" height="1600" alt="5" src="https://github.com/user-attachments/assets/098776fd-b387-4f97-9c37-d5157ed0166d" />  |
 |<img width="720" height="1600" alt="6" src="https://github.com/user-attachments/assets/6b2371a2-c9eb-472d-89f6-32ac523731d3" />  |
| *Gestão diária de exercícios com controle de séries, repetições, carga, cronómetro de descanso e links integrados para vídeos.* | *Planeamento alimentar estruturado por horários, controlo de suplementação (hormónios/remédios) e substituições.* |

| **Configurações & Progresso** | **Gerador de Treino com IA** |
| :---: | :---: |
|<img width="720" height="1600" alt="7" src="https://github.com/user-attachments/assets/232eaf05-af86-4549-bad5-4ca3ccc5d8ec" /> |
|<img width="720" height="1600" alt="8" src="https://github.com/user-attachments/assets/84187c63-008b-42e7-9d08-1654b8247651" /> |
| *Painel de preferências, lembretes de treino com alarmes e gráfico de evolução de peso integrado ao SQLite local.* | *Modal inteligente onde o utilizador escolhe a modalidade (Academia, Casa, Crossfit) e os grupos musculares para gerar o treino via IA.* |
# 🏋️ TreinoLivre - Aplicação Fitness & Saúde

O **TreinoLivre** é uma aplicação mobile desenvolvida em Flutter focada no acompanhamento de treinos, nutrição, hidratação e diagnóstico de saúde para utilizadores.

---

## 📌 Funcionalidades Principais

* **Autenticação Flexível:** Login social via Google Sign-In (Firebase) e acesso por E-mail.
* **Persistência Local:** Armazenamento off-line eficiente via SQLite para dados de treino e rotina.
* **Diagnóstico 360°:** Questionário inicial para personalização de fichas de treino e nutrição.
* **Interface Moderna:** Suporte a Dark Mode com estética neon/escura.
* **Termos & Privacidade:** Modais de conformidade e aceitação dos termos de uso.

---

## 🛠️ Tecnologias Utilizadas

* **Framework:** Flutter (Dart)
* **Autenticação & Nuvem:** Firebase Auth / Google Sign-In
* **Banco de Dados Local:** `sqflite`
