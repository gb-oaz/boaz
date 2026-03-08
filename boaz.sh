#!/usr/bin/env bash
# ============================================================
#  boaz.sh — Monorepo Structure Manager
#  Uso: chmod +x boaz.sh && ./boaz.sh
# ============================================================

set -euo pipefail

# ── TERMINAL ─────────────────────────────────────────────────
# Garante cores apenas quando o terminal suporta
if [ -t 1 ] && command -v tput &>/dev/null && tput colors &>/dev/null; then
  R=$(tput setaf 1)
  G=$(tput setaf 2)
  Y=$(tput setaf 3)
  B=$(tput setaf 4)
  C=$(tput setaf 6)
  W=$(tput bold)
  D=$(tput dim 2>/dev/null || echo "")
  NC=$(tput sgr0)
else
  R="" G="" Y="" B="" C="" W="" D="" NC=""
fi

# ── UTILITÁRIOS ──────────────────────────────────────────────
banner() {
  echo ""
  echo "${Y}╔══════════════════════════════╗${NC}"
  echo "${Y}║${NC}  🏗️  BOAZ — Monorepo Manager  ${Y}║${NC}"
  echo "${Y}╚══════════════════════════════╝${NC}"
  echo ""
}

info()    { echo "  ${C}ℹ${NC}  $1"; }
success() { echo "  ${G}✔${NC}  $1"; }
warn()    { echo "  ${Y}⚠${NC}  $1"; }
title()   { echo ""; echo "${B}▶ $1${NC}"; echo ""; }
sep()     { echo "${D}  ────────────────────────────────────────────────${NC}"; }

mkd() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    success "Criado: ${D}$1${NC}"
  fi
}

pick() {
  local __var=$1; local __prompt=$2; shift 2
  local opts=("$@")
  echo ""
  echo "  ${W}${__prompt}${NC}"
  for i in "${!opts[@]}"; do
    echo "  $((i+1)). ${opts[$i]}"
  done
  echo ""
  while true; do
    read -rp "  Escolha [1-${#opts[@]}]: " __choice
    if [[ "$__choice" =~ ^[0-9]+$ ]] && (( __choice >= 1 && __choice <= ${#opts[@]} )); then
      printf -v "$__var" '%s' "${opts[$((--__choice))]}"
      break
    fi
    warn "Opção inválida, tente novamente."
  done
}

ask() {
  local __var=$1; local __prompt=$2
  local __val
  read -rp "  ${__prompt}: " __val
  printf -v "$__var" '%s' "$__val"
}

ROOT_DIR="$(pwd)"
CONFIG_FILE="$ROOT_DIR/.boaz"

# ── LER / SALVAR CONFIGURAÇÃO ────────────────────────────────
load_config() {
  CLIENT_NAME=""
  CLIENT_SIGLA=""
  if [ -f "$CONFIG_FILE" ]; then
    # shellcheck source=/dev/null
    source "$CONFIG_FILE"
  fi
}

save_config() {
  cat > "$CONFIG_FILE" << EOF
CLIENT_NAME="${CLIENT_NAME}"
CLIENT_SIGLA="${CLIENT_SIGLA}"
EOF
}

# ── SOLICITAR CLIENTE (primeira execução) ────────────────────
setup_client() {
  title "Configuração inicial do Monorepo"

  echo "  ${W}Bem-vindo ao BOAZ — Monorepo Manager!${NC}"
  echo "  Este monorepo será dedicado a um cliente ou produto específico."
  echo ""
  echo "  A sigla será usada como prefixo de todas as pastas."
  echo "  Exemplo: cliente ${W}Nova Tech Solutions${NC} → sigla ${C}nts${NC}"
  echo "           produto ${W}Orbit Pay${NC}           → sigla ${C}obp${NC}"
  echo ""

  while true; do
    ask CLIENT_SIGLA "Informe a sigla (2–5 letras, ex: nts, obp, flux)"
    CLIENT_SIGLA=$(echo "$CLIENT_SIGLA" | tr '[:upper:]' '[:lower:]' | tr -d ' ' | tr -d '_')
    if [ -z "$CLIENT_SIGLA" ]; then
      warn "Sigla não pode ser vazia."
      continue
    fi
    if (( ${#CLIENT_SIGLA} < 2 || ${#CLIENT_SIGLA} > 5 )); then
      warn "A sigla deve ter entre 2 e 5 caracteres."
      continue
    fi
    break
  done

  # Deriva um nome de exibição a partir da sigla (pode ser sobrescrito)
  CLIENT_NAME=$(echo "$CLIENT_SIGLA" | tr '[:lower:]' '[:upper:]')

  save_config
  echo ""
  success "Monorepo configurado com prefixo: ${C}${CLIENT_SIGLA}${NC}"
  echo ""
  read -rp "  Pressione ENTER para continuar..." _
}

# ── ESTRUTURA BASE ───────────────────────────────────────────
create_base_structure() {
  title "Verificando estrutura base [${CLIENT_SIGLA}]"

  # Ordem: arc → backend → frontend → qa → infra
  mkd "${ROOT_DIR}/${CLIENT_SIGLA}_arc"
  mkd "${ROOT_DIR}/${CLIENT_SIGLA}_backend"
  mkd "${ROOT_DIR}/${CLIENT_SIGLA}_frontend"
  mkd "${ROOT_DIR}/${CLIENT_SIGLA}_qa"
  mkd "${ROOT_DIR}/${CLIENT_SIGLA}_infra"

  # Infra interna
  mkd "${ROOT_DIR}/${CLIENT_SIGLA}_infra/docker/backend"
  mkd "${ROOT_DIR}/${CLIENT_SIGLA}_infra/docker/frontend"
  mkd "${ROOT_DIR}/${CLIENT_SIGLA}_infra/terraform/environments/uat"
  mkd "${ROOT_DIR}/${CLIENT_SIGLA}_infra/terraform/environments/prd"


  create_root_gitignore
  create_docker_compose_base
  create_root_readme

  success "Estrutura base verificada."
}

# ── HELPERS DE CAMINHO ───────────────────────────────────────
arc_dir()     { echo "${ROOT_DIR}/${CLIENT_SIGLA}_arc"; }
backend_dir() { echo "${ROOT_DIR}/${CLIENT_SIGLA}_backend"; }
frontend_dir(){ echo "${ROOT_DIR}/${CLIENT_SIGLA}_frontend"; }
qa_dir() { echo "${ROOT_DIR}/${CLIENT_SIGLA}_qa"; }
infra_dir()   { echo "${ROOT_DIR}/${CLIENT_SIGLA}_infra"; }

# ── .GITIGNORE ───────────────────────────────────────────────
create_root_gitignore() {
  [ -f "$ROOT_DIR/.gitignore" ] && return
  cat > "$ROOT_DIR/.gitignore" << 'EOF'
# ── Java / Gradle ─────────────────────────────────────────
.gradle/
build/
*.class
*.jar
*.war
*.ear
out/
.idea/
*.iml

# ── Node / Frontend ───────────────────────────────────────
node_modules/
dist/
.nuxt/
.next/
.vite/
*.local

# ── Python ────────────────────────────────────────────────
__pycache__/
*.pyc
*.pyo
.venv/
venv/
*.egg-info/
.pytest_cache/

# ── Go ────────────────────────────────────────────────────
vendor/
*.exe
*.test

# ── Rust ──────────────────────────────────────────────────
target/

# ── Infra ─────────────────────────────────────────────────
.terraform/
*.tfstate
*.tfstate.backup
.terraform.lock.hcl
*.tfvars
!*.tfvars.example

# ── Docker ────────────────────────────────────────────────
.env
!.env.example

# ── Mobile ────────────────────────────────────────────────
*.apk
*.ipa
*.dSYM.zip
*.dSYM
Pods/
.build/

# ── OS ────────────────────────────────────────────────────
.DS_Store
Thumbs.db
*.swp
*.swo
EOF
  success "Criado: .gitignore"
}

# ── DOCKER-COMPOSE BASE ──────────────────────────────────────
create_docker_compose_base() {
  local infra
  infra=$(infra_dir)
  local dc="${infra}/docker/docker-compose.yml"
  local dco="${infra}/docker/docker-compose.override.yml"
  local env="${infra}/docker/.env.example"

  if [ ! -f "$dc" ]; then
    cat > "$dc" << 'EOF'
version: "3.9"

# ── Monorepo Docker Compose ──────────────────────────────────
# Gerado por boaz.sh
# Novos serviços são adicionados automaticamente ao criar projetos.

services:

  # ── SHARED — Banco Relacional ──────────────────────────────
  mysql:
    image: mysql:8
    ports:
      - "3306:3306"
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD:-root}
      MYSQL_DATABASE: ${MYSQL_DATABASE:-boaz}
      MYSQL_USER: ${MYSQL_USER:-admin}
      MYSQL_PASSWORD: ${MYSQL_PASSWORD:-secret}
    volumes:
      - mysql_data:/var/lib/mysql
    networks:
      - boaz-net

  # ── SHARED — Banco NoSQL ───────────────────────────────────
  mongo:
    image: mongo:7
    ports:
      - "27017:27017"
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER:-admin}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASSWORD:-secret}
      MONGO_INITDB_DATABASE: ${MONGO_DB:-boaz}
    volumes:
      - mongo_data:/data/db
    networks:
      - boaz-net

  # ── SHARED — Cache ─────────────────────────────────────────
  redis:
    image: redis:7-alpine
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    networks:
      - boaz-net

  # ── SHARED — Mensageria ────────────────────────────────────
  rabbitmq:
    image: rabbitmq:3-management-alpine
    ports:
      - "5672:5672"    # AMQP
      - "15672:15672"  # Management UI → http://localhost:15672
    environment:
      RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER:-admin}
      RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD:-secret}
    volumes:
      - rabbitmq_data:/var/lib/rabbitmq
    networks:
      - boaz-net

volumes:
  mysql_data:
  mongo_data:
  redis_data:
  rabbitmq_data:

networks:
  boaz-net:
    driver: bridge
EOF
    success "Criado: ${CLIENT_SIGLA}_infra/docker/docker-compose.yml"
  fi

  if [ ! -f "$dco" ]; then
    cat > "$dco" << 'EOF'
version: "3.9"

# ── Override para desenvolvimento local ─────────────────────
# Configurações que NÃO vão para produção.

services:

  mysql:
    ports:
      - "3306:3306"

  mongo:
    ports:
      - "27017:27017"

  redis:
    ports:
      - "6379:6379"

  rabbitmq:
    ports:
      - "5672:5672"
      - "15672:15672"

# Adicione aqui os overrides dos seus serviços:
#
#  meu-backend:
#    volumes:
#      - ../../backend/java/meu-backend:/app
#    environment:
#      APP_ENV: dev
EOF
    success "Criado: ${CLIENT_SIGLA}_infra/docker/docker-compose.override.yml"
  fi

  if [ ! -f "$env" ]; then
    cat > "$env" << 'EOF'
# Copie para .env: cp .env.example .env

MYSQL_ROOT_PASSWORD=root
MYSQL_DATABASE=boaz
MYSQL_USER=admin
MYSQL_PASSWORD=secret

MONGO_USER=admin
MONGO_PASSWORD=secret
MONGO_DB=boaz

REDIS_HOST=redis
REDIS_PORT=6379

RABBITMQ_USER=admin
RABBITMQ_PASSWORD=secret
RABBITMQ_HOST=rabbitmq
RABBITMQ_PORT=5672
EOF
    success "Criado: ${CLIENT_SIGLA}_infra/docker/.env.example"
  fi
}

# ── README RAIZ ──────────────────────────────────────────────
create_root_readme() {
  [ -f "$ROOT_DIR/README.md" ] && return
  local s="$CLIENT_SIGLA"
  cat > "$ROOT_DIR/README.md" << EOF
# 🏗️ Monorepo — $(echo "$s" | tr '[:lower:]' '[:upper:]')

> Estrutura gerada e gerenciada por \`boaz.sh\`.

---

## 🚀 Como usar o boaz.sh

\`\`\`bash
chmod +x boaz.sh
./boaz.sh
\`\`\`

O script verifica a estrutura existente a cada execução. Na primeira execução
solicita a sigla do projeto, que será usada como prefixo de todas as pastas.
Em seguidas execuções detecta a configuração existente e vai direto ao menu.

---

## 📁 Estrutura de Pastas

\`\`\`
monorepo/
├── ${s}_arc/        # Documentação e diagramas de cada projeto
├── ${s}_backend/    # Serviços de backend por linguagem
├── ${s}_frontend/   # Aplicações web e mobile por framework
├── ${s}_qa/         # Testes — espelha backend e frontend
└── ${s}_infra/      # Toda a infraestrutura
    ├── docker/      # docker-compose para ambiente local
    ├── terraform/   # Infraestrutura como código (environments/uat, environments/prd)

\`\`\`

> Os workflows de CI/CD (ex: .github/workflows/) são criados conforme sua documentação

---

## 🗂️ Padrão de hierarquia

Todo projeto segue o padrão:

\`\`\`
<área>/<tecnologia>/<nome-do-projeto>/
\`\`\`

Exemplos:

\`\`\`
${s}_backend/java/auth-service/
${s}_backend/python/notifications-worker/
${s}_frontend/web/vue/portal/
${s}_frontend/web/react/dashboard/
${s}_frontend/mobile/flutter/mobile-app/
\`\`\`

---

## 📐 Arc — documentação por projeto

Ao criar qualquer projeto, o boaz.sh cria automaticamente sua pasta de
documentação em \`${s}_arc/\`, espelhando a mesma hierarquia:

\`\`\`
${s}_arc/backend/java/auth-service/
├── README.md                  ← visão geral do projeto
├── architecture/
│   ├── diagrams/              ← arquivos .drawio editáveis
│   └── images/                ← exports .png / .svg
├── ferramentas-stack.md
├── processo-desenvolvimento.md
└── pacote-qualidade.md
\`\`\`

---

## 🧪 QA — testes por projeto

Ao criar qualquer projeto, o boaz.sh cria automaticamente sua pasta de testes
em \`${s}_qa/\`, espelhando a mesma hierarquia:

\`\`\`
${s}_qa/backend/java/auth-service/
├── integration/
├── performance/
└── contracts/

${s}_qa/frontend/web/vue/portal/
└── e2e/
\`\`\`

A stack de testes é livre — nenhuma ferramenta é imposta.

---

## ➕ Como adicionar um novo projeto

Execute \`./boaz.sh\` e escolha a opção desejada. O script:

1. Cria a pasta do projeto
2. Cria o espelho em \`${s}_qa/\`
3. Cria o espelho em \`${s}_arc/\`
4. Cria o Dockerfile base em \`${s}_infra/docker/\`
5. Adiciona o serviço ao \`docker-compose.yml\`

---

## 🐳 Ambiente local

\`\`\`bash
cd ${s}_infra/docker
cp .env.example .env
docker compose up
\`\`\`

Serviços compartilhados disponíveis por padrão:

| Serviço   | Porta  | Descrição              |
|-----------|--------|------------------------|
| MySQL     | 3306   | Banco relacional       |
| MongoDB   | 27017  | Banco NoSQL            |
| Redis     | 6379   | Cache                  |
| RabbitMQ  | 5672   | Mensageria (AMQP)      |
| RabbitMQ  | 15672  | Management UI          |

---

## 🔄 CI/CD

Configure pelo menu do boaz.sh (opções 4 e 5).
Os arquivos de pipeline são criados na raiz do repositório,
que é onde cada ferramenta (GitHub Actions, GitLab, Jenkins, etc.) espera encontrá-los.

---

*Gerado por boaz.sh — use sempre o script para adicionar novos projetos.*
EOF
  success "Criado: README.md"
}

# ── CRIAR ARC DE PROJETO ─────────────────────────────────────
create_project_arc() {
  local area=$1 tech_path=$2 proj_name=$3
  local arc_base
  arc_base="$(arc_dir)/${area}/${tech_path}/${proj_name}"

  mkd "${arc_base}"
  mkd "${arc_base}/architecture/diagrams"
  mkd "${arc_base}/architecture/images"

  cat > "${arc_base}/README.md" << EOF
# 📐 Arc — ${proj_name}

Documentação do projeto \`${area}/${tech_path}/${proj_name}\`.

## Estrutura sugerida

- \`architecture/diagrams/\` — diagramas \`.drawio\` editáveis
- \`architecture/images/\` — exports \`.png\` / \`.svg\`
- \`ferramentas-stack.md\` — tecnologias e decisões técnicas
- \`processo-desenvolvimento.md\` — guia para novos devs
- \`pacote-qualidade.md\` — estratégia de testes
EOF
}

# ── CRIAR QUALITY DE PROJETO ─────────────────────────────────
create_project_qa() {
  local area=$1 tech_path=$2 proj_name=$3
  local q_base
  q_base="$(qa_dir)/${area}/${tech_path}/${proj_name}"

  case "$area" in
    backend)
      mkd "${q_base}/integration"
      mkd "${q_base}/performance"
      mkd "${q_base}/contracts"
      ;;
    frontend/web | frontend/mobile)
      mkd "${q_base}/e2e"
      ;;
  esac

  cat > "${q_base}/README.md" << EOF
# 🧪 Quality — ${proj_name}

Testes do projeto \`${area}/${tech_path}/${proj_name}\`.

A stack de testes é livre — escolha a ferramenta mais adequada.
EOF
}

# ── ADICIONAR BACKEND ────────────────────────────────────────
add_backend() {
  title "Adicionar projeto Backend"

  local LANGS=(
    "Java" "Kotlin" "Python" "Go" "Node.js"
    "Rust" "Ruby" "PHP" "C#" "Scala" "Elixir"
  )
  local lang_folders=(
    "java" "kotlin" "python" "go" "nodejs"
    "rust" "ruby" "php" "csharp" "scala" "elixir"
  )

  local lang_choice
  pick lang_choice "Escolha a linguagem:" "${LANGS[@]}"

  local idx
  for i in "${!LANGS[@]}"; do
    [[ "${LANGS[$i]}" == "$lang_choice" ]] && idx=$i && break
  done
  local lang_dir="${lang_folders[$idx]}"

  local proj_name
  while true; do
    read -rp "  Nome do projeto (ex: auth-service, payments-api): " proj_name
    proj_name=$(echo "$proj_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')
    if [ -z "$proj_name" ]; then
      warn "Nome não pode ser vazio."
      continue
    fi
    if [ -d "$(backend_dir)/${lang_dir}/${proj_name}" ]; then
      warn "Projeto '${proj_name}' já existe em ${CLIENT_SIGLA}_backend/${lang_dir}/. Escolha outro nome."
    else
      break
    fi
  done

  mkd "$(backend_dir)/${lang_dir}/${proj_name}"

  create_backend_dockerfile "$lang_dir" "$proj_name"
  create_project_qa "backend" "$lang_dir" "$proj_name"
  create_project_arc "backend" "$lang_dir" "$proj_name"
  append_docker_compose_service "backend" "$proj_name" "$lang_dir"

  echo ""
  success "Backend '${proj_name}' criado em ${CLIENT_SIGLA}_backend/${lang_dir}/${proj_name}/"
  info "Configure o build (${lang_choice}) diretamente na pasta do projeto."
  sep
}

# ── DOCKERFILE BACKEND ───────────────────────────────────────
create_backend_dockerfile() {
  local lang=$1 name=$2
  local df
  df="$(infra_dir)/docker/backend/${name}.Dockerfile"
  [ -f "$df" ] && return

  cat > "$df" << EOF
# Dockerfile — ${name} (${lang})
# TODO: configure according to your build tool and runtime

FROM alpine:latest
WORKDIR /app
COPY . .
EXPOSE 8080
# CMD ["./start.sh"]
EOF
  success "Dockerfile: ${CLIENT_SIGLA}_infra/docker/backend/${name}.Dockerfile"
}

# ── ADICIONAR WEB ────────────────────────────────────────────
add_frontend_web() {
  title "Adicionar projeto Web"

  local FRAMEWORKS=(
    "Vue 3" "React" "Angular" "Nuxt 3" "Next.js"
    "Svelte" "Astro" "Solid.js" "Qwik"
  )
  local fw_folders=(
    "vue" "react" "angular" "nuxt" "nextjs"
    "svelte" "astro" "solidjs" "qwik"
  )

  local fw_choice
  pick fw_choice "Escolha o framework:" "${FRAMEWORKS[@]}"

  local idx
  for i in "${!FRAMEWORKS[@]}"; do
    [[ "${FRAMEWORKS[$i]}" == "$fw_choice" ]] && idx=$i && break
  done
  local fw_dir="${fw_folders[$idx]}"

  local proj_name
  while true; do
    read -rp "  Nome do projeto (ex: portal, dashboard, landing): " proj_name
    proj_name=$(echo "$proj_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')
    if [ -z "$proj_name" ]; then
      warn "Nome não pode ser vazio."
      continue
    fi
    if [ -d "$(frontend_dir)/web/${fw_dir}/${proj_name}" ]; then
      warn "Projeto '${proj_name}' já existe em ${CLIENT_SIGLA}_frontend/web/${fw_dir}/. Escolha outro nome."
    else
      break
    fi
  done

  mkd "$(frontend_dir)/web/${fw_dir}/${proj_name}"

  create_frontend_web_dockerfile "$fw_dir" "$proj_name"
  create_project_qa "frontend/web" "$fw_dir" "$proj_name"
  create_project_arc "frontend/web" "$fw_dir" "$proj_name"
  append_docker_compose_service "frontend-web" "$proj_name" "$fw_dir"

  echo ""
  success "Web '${proj_name}' criado em ${CLIENT_SIGLA}_frontend/web/${fw_dir}/${proj_name}/"
  info "Inicialize o projeto com o CLI do framework dentro da pasta."

  case "$fw_dir" in
    vue)     info "Sugestão: npm create vue@latest ." ;;
    react)   info "Sugestão: npm create vite@latest . -- --template react-ts" ;;
    angular) info "Sugestão: ng new ${proj_name} --directory ." ;;
    nuxt)    info "Sugestão: npx nuxi@latest init ." ;;
    nextjs)  info "Sugestão: npx create-next-app@latest ." ;;
    svelte)  info "Sugestão: npm create svelte@latest ." ;;
    astro)   info "Sugestão: npm create astro@latest ." ;;
  esac
  sep
}

# ── DOCKERFILE FRONTEND WEB ──────────────────────────────────
create_frontend_web_dockerfile() {
  local fw=$1 name=$2
  local df
  df="$(infra_dir)/docker/frontend/${name}-web.Dockerfile"
  [ -f "$df" ] && return

  cat > "$df" << EOF
# Dockerfile — ${name} (${fw})
# TODO: configure according to your framework and build tool

FROM node:20-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM nginx:alpine
COPY --from=builder /app/dist /usr/share/nginx/html
EXPOSE 80
EOF
  success "Dockerfile: ${CLIENT_SIGLA}_infra/docker/frontend/${name}-web.Dockerfile"
}

# ── ADICIONAR MOBILE ─────────────────────────────────────────
add_mobile() {
  title "Adicionar projeto Mobile"

  local PLATFORMS=(
    "Android (Kotlin + Jetpack Compose)"
    "iOS (Swift + SwiftUI)"
    "React Native — híbrido JS/TS"
    "Flutter — híbrido Dart"
    "Ionic — híbrido Web"
    "KMP — Kotlin Multiplatform (Android + iOS)"
    "Capacitor — híbrido Web"
    "Xamarin — híbrido C#"
  )
  local plat_folders=(
    "android" "ios" "react-native" "flutter"
    "ionic" "kmp" "capacitor" "xamarin"
  )

  local plat_choice
  pick plat_choice "Escolha a plataforma:" "${PLATFORMS[@]}"

  local idx
  for i in "${!PLATFORMS[@]}"; do
    [[ "${PLATFORMS[$i]}" == "$plat_choice" ]] && idx=$i && break
  done
  local plat_dir="${plat_folders[$idx]}"

  local proj_name
  while true; do
    read -rp "  Nome do projeto (ex: mobile-app, client-app): " proj_name
    proj_name=$(echo "$proj_name" | tr '[:upper:]' '[:lower:]' | tr ' ' '-' | tr '_' '-')
    if [ -z "$proj_name" ]; then
      warn "Nome não pode ser vazio."
      continue
    fi
    if [ -d "$(frontend_dir)/mobile/${plat_dir}/${proj_name}" ]; then
      warn "Projeto '${proj_name}' já existe em ${CLIENT_SIGLA}_frontend/mobile/${plat_dir}/. Escolha outro nome."
    else
      break
    fi
  done

  mkd "$(frontend_dir)/mobile/${plat_dir}/${proj_name}"

  create_project_qa "frontend/mobile" "$plat_dir" "$proj_name"
  create_project_arc "frontend/mobile" "$plat_dir" "$proj_name"

  echo ""
  success "Mobile '${proj_name}' criado em ${CLIENT_SIGLA}_frontend/mobile/${plat_dir}/${proj_name}/"

  case "$plat_dir" in
    android)      info "Inicialize com Android Studio ou: gradle init dentro da pasta." ;;
    ios)          info "Inicialize com Xcode ou: swift package init dentro da pasta." ;;
    react-native) info "Sugestão: npx react-native init NomeProjeto e mova para a pasta." ;;
    flutter)      info "Sugestão: flutter create nome_projeto e mova para a pasta." ;;
    ionic)        info "Sugestão: ionic start nome-projeto e mova para a pasta." ;;
    kmp)          info "Inicialize com Android Studio → New Project → Kotlin Multiplatform." ;;
    capacitor)    info "Sugestão: npm create @capacitor/app e mova para a pasta." ;;
    xamarin)      info "Inicialize com Visual Studio → Xamarin.Forms Project." ;;
  esac
  sep
}

# ── CONFIGURAR CI ────────────────────────────────────────────
configure_ci() {
  title "Configurar CI"

  local TOOLS=(
    "GitHub Actions"
    "Azure Pipelines"
    "GitLab CI"
    "Jenkins"
    "Bitbucket Pipelines"
    "CircleCI"
    "Travis CI"
    "TeamCity"
    "Buildkite"
  )

  local tool_choice
  pick tool_choice "Escolha a ferramenta de CI:" "${TOOLS[@]}"

  case "$tool_choice" in
    "GitHub Actions")
      mkd "$ROOT_DIR/.github/workflows"
      cat > "$ROOT_DIR/.github/workflows/ci.yml" << 'EOF'
name: CI
# TODO: configure your CI pipeline
on:
  push:
    branches: ["**"]
  pull_request:
    branches: [main, develop]
jobs:
  ci:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # TODO: add your build and test steps here
EOF
      success "GitHub Actions → .github/workflows/ci.yml"
      ;;

    "Azure Pipelines")
      cat > "$ROOT_DIR/azure-pipelines.yml" << 'EOF'
# TODO: configure your CI pipeline
trigger:
  branches:
    include: ["*"]
pool:
  vmImage: ubuntu-latest
steps:
  - script: echo "TODO: add your build and test steps here"
EOF
      success "Azure Pipelines → azure-pipelines.yml"
      ;;

    "GitLab CI")
      cat > "$ROOT_DIR/.gitlab-ci.yml" << 'EOF'
# TODO: configure your CI pipeline
stages:
  - test
  - build
test:
  stage: test
  script:
    - echo "TODO: add your test steps here"
EOF
      success "GitLab CI → .gitlab-ci.yml"
      ;;

    "Jenkins")
      cat > "$ROOT_DIR/Jenkinsfile" << 'EOF'
// TODO: configure your CI pipeline
pipeline {
  agent any
  stages {
    stage('Build & Test') {
      steps {
        echo 'TODO: add your build and test steps here'
      }
    }
  }
}
EOF
      success "Jenkins → Jenkinsfile"
      ;;

    "Bitbucket Pipelines")
      cat > "$ROOT_DIR/bitbucket-pipelines.yml" << 'EOF'
# TODO: configure your CI pipeline
pipelines:
  default:
    - step:
        name: Build & Test
        script:
          - echo "TODO: add your build and test steps here"
EOF
      success "Bitbucket Pipelines → bitbucket-pipelines.yml"
      ;;

    "CircleCI")
      mkd "$ROOT_DIR/.circleci"
      cat > "$ROOT_DIR/.circleci/config.yml" << 'EOF'
# TODO: configure your CI pipeline
version: 2.1
jobs:
  build:
    docker:
      - image: cimg/base:stable
    steps:
      - checkout
      - run: echo "TODO: add your build and test steps here"
workflows:
  ci:
    jobs:
      - build
EOF
      success "CircleCI → .circleci/config.yml"
      ;;

    "Travis CI")
      cat > "$ROOT_DIR/.travis.yml" << 'EOF'
# TODO: configure your CI pipeline
language: minimal
script:
  - echo "TODO: add your build and test steps here"
EOF
      success "Travis CI → .travis.yml"
      ;;

    *)
      cat > "$ROOT_DIR/ci-${tool_choice// /-}.yml" << EOF
# CI — ${tool_choice}
# TODO: configure your CI pipeline
EOF
      success "${tool_choice} → ci-${tool_choice// /-}.yml"
      ;;
  esac
}

# ── CONFIGURAR CD ────────────────────────────────────────────
configure_cd() {
  title "Configurar CD"

  local TOOLS=(
    "GitHub Actions"
    "Azure DevOps"
    "GitLab CI/CD"
    "ArgoCD"
    "Flux CD"
    "Jenkins"
    "Spinnaker"
    "Harness"
  )

  local tool_choice
  pick tool_choice "Escolha a ferramenta de CD:" "${TOOLS[@]}"

  case "$tool_choice" in
    "GitHub Actions")
      mkd "$ROOT_DIR/.github/workflows"
      cat > "$ROOT_DIR/.github/workflows/cd.yml" << 'EOF'
name: CD
# TODO: configure your CD pipeline
on:
  push:
    branches: [main, develop]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      # TODO: add your deploy steps here
EOF
      success "GitHub Actions → .github/workflows/cd.yml"
      ;;

    "Azure DevOps")
      cat > "$ROOT_DIR/azure-pipelines-cd.yml" << 'EOF'
# TODO: configure your CD pipeline
trigger:
  branches:
    include: [main, develop]
pool:
  vmImage: ubuntu-latest
steps:
  - script: echo "TODO: add your deploy steps here"
EOF
      success "Azure DevOps → azure-pipelines-cd.yml"
      ;;

    "GitLab CI/CD")
      cat > "$ROOT_DIR/.gitlab-cd.yml" << 'EOF'
# TODO: configure your CD pipeline
stages:
  - deploy
deploy:
  stage: deploy
  script:
    - echo "TODO: add your deploy steps here"
  only:
    - main
    - develop
EOF
      success "GitLab CI/CD → .gitlab-cd.yml"
      ;;

    "Jenkins")
      cat > "$ROOT_DIR/Jenkinsfile-cd" << 'EOF'
// TODO: configure your CD pipeline
pipeline {
  agent any
  stages {
    stage('Deploy') {
      steps {
        echo 'TODO: add your deploy steps here'
      }
    }
  }
}
EOF
      success "Jenkins → Jenkinsfile-cd"
      ;;

    *)
      cat > "$ROOT_DIR/cd-${tool_choice// /-}.yml" << EOF
# CD — ${tool_choice}
# TODO: configure your CD pipeline
EOF
      success "${tool_choice} → cd-${tool_choice// /-}.yml"
      ;;
  esac
}

# ── APPEND DOCKER-COMPOSE ────────────────────────────────────
append_docker_compose_service() {
  local area=$1 name=$2 tech=$3
  local dc
  dc="$(infra_dir)/docker/docker-compose.yml"

  grep -q "  ${name}:" "$dc" 2>/dev/null && return

  local dockerfile
  case "$area" in
    backend)      dockerfile="backend/${name}.Dockerfile" ;;
    frontend-web) dockerfile="frontend/${name}-web.Dockerfile" ;;
    *)            dockerfile="backend/${name}.Dockerfile" ;;
  esac

  cat >> "$dc" << EOF

  # ── ${name} (${area}/${tech}) ─────────────────────────────
  ${name}:
    build:
      context: ../../${CLIENT_SIGLA}_${area/frontend-web/frontend\/web}/${tech}/${name}
      dockerfile: ../../../${CLIENT_SIGLA}_infra/docker/${dockerfile}
    environment:
      - REDIS_HOST=redis
      - MYSQL_HOST=mysql
      - MONGO_URI=mongodb://\${MONGO_USER:-admin}:\${MONGO_PASSWORD:-secret}@mongo:27017/\${MONGO_DB:-boaz}
      - RABBITMQ_HOST=rabbitmq
    depends_on:
      - mysql
      - mongo
      - redis
      - rabbitmq
    networks:
      - boaz-net
    # ports:
    #   - "8080:8080"
EOF
  success "Serviço '${name}' adicionado ao docker-compose.yml"
}

# ── MOSTRAR ÁRVORE ───────────────────────────────────────────
show_tree() {
  title "Estrutura atual [${CLIENT_SIGLA}]"
  if command -v tree &>/dev/null; then
    tree -L 5 --dirsfirst \
      -I 'node_modules|.gradle|build|dist|.git|__pycache__|vendor|target|Pods' \
      "$ROOT_DIR"
  else
    find "$ROOT_DIR" -maxdepth 5 \
      -not -path "*/node_modules/*" \
      -not -path "*/.gradle/*" \
      -not -path "*/build/*" \
      -not -path "*/.git/*" \
      -not -path "*/__pycache__/*" \
      -not -path "*/target/*" \
      | sort \
      | sed -e "s|$ROOT_DIR/||" \
            -e "s|$ROOT_DIR||" \
            -e '/^$/d' \
            -e 's|[^/]*/|  │  |g' \
            -e 's|  │  \([^│]*\)$|  └─ \1|'
  fi
}

# ── STATUS ───────────────────────────────────────────────────
show_status() {
  title "Projeto [${CLIENT_SIGLA}]"

  local areas=(
    "${CLIENT_SIGLA}_arc"
    "${CLIENT_SIGLA}_backend"
    "${CLIENT_SIGLA}_frontend"
    "${CLIENT_SIGLA}_qa"
    "${CLIENT_SIGLA}_infra"
  )

  for area in "${areas[@]}"; do
    if [ -d "$ROOT_DIR/$area" ]; then
      local count
      count=$(find "$ROOT_DIR/$area" -mindepth 1 -maxdepth 1 -type d | wc -l | tr -d ' ')
      echo "  ${G}✔${NC}  ${W}${area}/${NC}  ${D}(${count} subpastas)${NC}"
    else
      echo "  ${R}✖${NC}  ${W}${area}/${NC}  ${R}não encontrado${NC}"
    fi
  done

  sep

  local proj_count
  proj_count=$(find "${ROOT_DIR}/${CLIENT_SIGLA}_backend" \
    "${ROOT_DIR}/${CLIENT_SIGLA}_frontend" \
    -maxdepth 5 -mindepth 3 -type d 2>/dev/null | wc -l | tr -d ' ')
  echo "  ${C}📦  Projetos criados: ${W}${proj_count}${NC}"

  local docker_count
  docker_count=$(find "${ROOT_DIR}/${CLIENT_SIGLA}_infra/docker" \
    -name "*.Dockerfile" 2>/dev/null | wc -l | tr -d ' ')
  echo "  ${C}🐳  Dockerfiles: ${W}${docker_count}${NC}"
}

# ── MENU PRINCIPAL ───────────────────────────────────────────
main_menu() {
  while true; do
    clear
    banner
    show_status
    echo ""
    echo "  ${W}O que deseja fazer?${NC}"
    echo ""
    echo "  ${C}1.${NC} Adicionar projeto Backend"
    echo "  ${C}2.${NC} Adicionar projeto Web"
    echo "  ${C}3.${NC} Adicionar projeto Mobile"
    echo "  ${C}4.${NC} Configurar CI"
    echo "  ${C}5.${NC} Configurar CD"
    echo "  ${C}6.${NC} Ver árvore de pastas"
    echo "  ${C}7.${NC} Recriar estrutura base"
    echo "  ${D}0.  Sair${NC}"
    echo ""

    read -rp "  Escolha [0-7]: " opt
    echo ""

    case "$opt" in
      1) add_backend ;;
      2) add_frontend_web ;;
      3) add_mobile ;;
      4) configure_ci ;;
      5) configure_cd ;;
      6) show_tree ;;
      7) create_base_structure ;;
      0)
        echo ""
        echo "  ${Y}Até logo! 👋${NC}"
        echo ""
        exit 0
        ;;
      *)
        warn "Opção inválida."
        ;;
    esac

    echo ""
    read -rp "  Pressione ENTER para continuar..." _
  done
}

# ── ENTRY POINT ──────────────────────────────────────────────
clear
load_config

if [ -z "$CLIENT_NAME" ] || [ -z "$CLIENT_SIGLA" ]; then
  banner
  setup_client
fi

clear
create_base_structure
main_menu
