flowchart TD
    pessoa["Pessoa usuária"] --> inicializacao

    subgraph app["Aplicativo Flutter"]
        inicializacao["lib/main.dart<br/>Inicializa Flutter, Firebase<br/>e SQLite FFI em Windows/Linux"]
        sessao{"Firebase Auth<br/>tem sessão ativa?"}
        login["LoginScreen<br/>Google / Facebook"]
        loginEmail["EmailLoginScreen"]
        cadastro["RegisterScreen"]
        painel["HomeDashboardScreen"]
        diagnostico["Diagnosis360Screen<br/>Questionário 360°"]
        treinos["WorkoutsScreen"]
        dieta["DietScreen"]
        configuracoes["SettingsScreen"]
        hidratacao["WaterReminderScreen"]
        lembretes["WorkoutReminderScreen"]
        navegacao["MainNavigationScreen<br/>Fluxo alternativo por status"]

        inicializacao --> sessao
        sessao -->|Sim| painel
        sessao -->|Não| login
        login -->|Google / Facebook| sessao
        login -->|Acesso por e-mail| loginEmail
        loginEmail -->|Acesso local| painel
        loginEmail --> cadastro
        cadastro -->|Cadastro concluído| painel

        painel -->|Diagnóstico ausente| diagnostico
        diagnostico -->|Envia respostas| painel
        painel --> treinos
        painel --> dieta
        painel --> configuracoes
        painel --> hidratacao
        configuracoes --> lembretes
        navegacao --> diagnostico
    end

    subgraph dados["Modelos e persistência"]
        studentModel["Student"]
        workoutModel["WorkoutProtocol<br/>ExerciseModel / Cardio"]
        sqlite["DatabaseHelper<br/>SQLite: students, workouts,<br/>exercises"]
        repos["Repositories<br/>StudentRepository<br/>WorkoutRepository (mock)"]

        studentModel --> sqlite
        workoutModel --> sqlite
        repos --> studentModel
        repos --> workoutModel
    end

    subgraph cloud["Serviços e integrações"]
        auth["Firebase Authentication"]
        firestore["Cloud Firestore<br/>students, diagnosticos_360,<br/>treinos_gerados"]
        firebaseService["FirebaseService"]
        gemini["Google Generative AI<br/>Geração de plano de treino"]
        notificacoes["Notificações locais"]
        youtube["YouTube<br/>Vídeos de exercícios"]
    end

    login --> auth
    sessao -.-> auth
    cadastro --> sqlite
    cadastro --> firebaseService
    firebaseService --> firestore
    diagnostico --> firestore
    painel --> firestore
    loginEmail --> repos
    treinos --> firestore
    treinos --> gemini
    treinos --> sqlite
    treinos --> youtube
    dieta --> firestore
    hidratacao --> firestore
    lembretes --> notificacoes
    configuracoes --> auth

    subgraph componentes["Componentes compartilhados"]
        exerciseCard["ExerciseCard"]
        restTimer["RestTimerModal"]
        studentCard["StudentCard"]
        cores["AdminColors"]
    end

    treinos --> exerciseCard
    exerciseCard --> restTimer
    studentCard --> studentModel
    studentCard --> cores

    subgraph plataformas["Alvos e recursos do projeto"]
        targets["Android · iOS · Web<br/>Linux · macOS · Windows"]
        assets["assets/imagem<br/>Imagens, ícones e ilustrações"]
        deps["pubspec.yaml<br/>Dependências e configuração Flutter"]
    end

    inicializacao -.-> targets
    app -.-> assets
    app -.-> deps