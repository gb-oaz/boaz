#!/usr/bin/env bash
# ============================================================
#  boaz.sh — Monorepo Structure Manager
#  Uso: chmod +x boaz.sh && ./boaz.sh [comando]
# ============================================================

set -euo pipefail

CONFIG_FILE=".boaz"
ICONS_DIR="0_Assets/diagramas/icones"
ASSETS_TARBALL="https://codeload.github.com/gb-oaz/boaz/tar.gz/refs/heads/main"
DIAGRAM_DIRS="2_Diagramas 3_Arquitetura"
REQ_DIR="1_Requisitos"
REQ_THEME="0_Assets/requisitos/tema.html"
LEAF_DIRS="0_Assets/projeto 0_Assets/diagramas 0_Assets/requisitos 1_Requisitos 2_Diagramas 3_Arquitetura 4_CI_CD
           5_DEV/backend 5_DEV/frontend 5_DEV/qa/backend 5_DEV/qa/frontend"

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
fail()    { echo "  ${R}✖${NC}  $1" >&2; exit 1; }
title()   { echo ""; echo "${B}▶ $1${NC}"; echo ""; }

mkd() {
  if [ ! -d "$1" ]; then
    mkdir -p "$1"
    success "Criado: ${D}$1/${NC}"
  fi
}

# Escreve stdin em $1 somente se o arquivo ainda não existir
write_once() {
  if [ -f "$1" ]; then
    cat > /dev/null
  else
    mkdir -p "$(dirname "$1")"
    cat > "$1"
    success "Criado: ${D}$1${NC}"
  fi
}

# Escreve stdin em $1 sempre (arquivos gerenciados pelo boaz)
write_always() {
  mkdir -p "$(dirname "$1")"
  cat > "$1"
  success "Atualizado: ${D}$1${NC}"
}

# "Fluxo de Cadastro" → fluxo-de-cadastro
slugify() {
  echo "$1" \
    | LC_ALL=en_US.UTF-8 sed 'y/áàâãäéèêëíìîïóòôõöúùûüçñÁÀÂÃÄÉÈÊËÍÌÎÏÓÒÔÕÖÚÙÛÜÇÑ/aaaaaeeeeiiiiooooouuuucnAAAAAEEEEIIIIOOOOOUUUUCN/' \
    | tr '[:upper:]' '[:lower:]' \
    | sed -E 's/[^a-z0-9]+/-/g; s/^-+//; s/-+$//'
}

# ── CONFIG ───────────────────────────────────────────────────
load_config() {
  PROJECT_NAME=""
  if [ -f "$CONFIG_FILE" ]; then
    PROJECT_NAME=$(sed -n 's/^PROJECT_NAME="\(.*\)"$/\1/p' "$CONFIG_FILE")
  fi
}

save_config() {
  printf 'PROJECT_NAME="%s"\n' "$PROJECT_NAME" > "$CONFIG_FILE"
}

# ── INIT ─────────────────────────────────────────────────────
cmd_init() {
  load_config
  if [ -n "${1:-}" ]; then
    PROJECT_NAME="$1"
  fi
  while [ -z "$PROJECT_NAME" ]; do
    read -rp "  Nome do projeto: " PROJECT_NAME
  done
  save_config

  title "Montando estrutura [${PROJECT_NAME}]"

  local leaf
  for leaf in $LEAF_DIRS; do
    mkd "$leaf"
  done

  create_readmes
  install_assets
  create_requirements_template
  create_diagram_skills
  create_requirements_skills

  # Mantém no git as pastas que ainda estão vazias
  for leaf in $LEAF_DIRS; do
    [ -n "$(ls -A "$leaf")" ] || touch "$leaf/.gitkeep"
  done

  echo ""
  success "Projeto ${C}${PROJECT_NAME}${NC} pronto."
  info "Requisitos: no Claude Code use ${W}/requisito${NC} (conteúdo) ou ${W}/requisito-estilo${NC} (visual, migração e PDF)."
  info "Diagramas: no Claude Code use ${W}/diagrama-dev${NC} ou ${W}/diagrama-arquitetura${NC}."
}

create_readmes() {
  write_once "CLAUDE.md" << EOF
# ${PROJECT_NAME}

Monorepo organizado pelo boaz. Cada pasta tem uma única responsabilidade:

| Pasta | Conteúdo | Formato |
|---|---|---|
| \`0_Assets/\` | Recursos reutilizáveis: \`projeto/\` (marca, imagens, fontes), \`requisitos/\` (tema.html) e \`diagramas/\` (tema, ícones, logos) | livre |
| \`1_Requisitos/\` | O produto desejado — sem backend, frontend ou tecnologia | \`.html\` versionado (+ \`pdf/\`) |
| \`2_Diagramas/\` | Diagramas de desenvolvimento (backend e frontend) | \`.svg\` versionado |
| \`3_Arquitetura/\` | Diagramas de alto nível: cloud, tecnologias, integrações | \`.svg\` versionado |
| \`4_CI_CD/\` | Estruturas de entrega (pipelines, deploy) | livre |
| \`5_DEV/\` | Código: \`backend/\`, \`frontend/\`, \`qa/backend/\`, \`qa/frontend/\` | livre |

- Requisitos são documentos \`.html\` autocontidos, criados/alterados pela skill \`requisito\` no padrão de \`0_Assets/requisitos/tema.html\` (marca d'água de topo com projeto, documento, versão, data/hora e status; histórico no rodapé; temas claro/sistema/escuro; botão de PDF). A skill \`requisito-estilo\` cuida do visual, da migração de \`.md\` antigos e do PDF. \`./boaz.sh requisitos\` lista os documentos; \`./boaz.sh pdf <documento>\` exporta o PDF versionado para \`1_Requisitos/pdf/\`.
- Diagramas são criados/alterados somente pelas skills \`diagrama-dev\` (2_) e \`diagrama-arquitetura\` (3_).
- Todo diagrama segue o tema dark de \`0_Assets/diagramas/tema.svg\` e embute (inline) os assets que usar de \`0_Assets/\`.
- Nome do diagrama: \`<legenda>_v<NN>_<AAAAMMDD-HHMM>.svg\`. Versões nunca são sobrescritas; cada alteração gera um novo arquivo.
- \`./boaz.sh svg <pasta> <legenda>\` devolve o próximo nome; \`./boaz.sh diagramas\` lista a versão mais recente de cada um.
EOF

  write_once "0_Assets/README.md" << 'EOF'
# 0_Assets

Recursos reutilizáveis do projeto e dos diagramas.

```
0_Assets/
├── projeto/      # marca, logos, imagens, fontes, mockups — usados no produto e nos documentos
├── requisitos/   # tema.html: marca d'água, estilo, formato e componentes dos documentos de requisito
└── diagramas/    # tema.svg (estilo padrão), ícones de cloud/tecnologias, logos de integrações
```

- Prefira `.svg`; raster (`.png`, `.jpg`, `.webp`) só quando não houver vetor.
- Nomes em kebab-case, sem acentos: `funcao-serverless.svg`, `logo-principal.svg`.
- `diagramas/icones/` traz os ícones oficiais de AWS, GCP e Azure (instalados pelo
  `./boaz.sh init`, veja o README da pasta). Use-os só quando a arquitetura for
  de um provedor específico; por padrão ela é neutra e vale para Azure, AWS e GCP.
- As skills de diagrama procuram aqui antes de desenhar e **embutem** o asset no SVG
  gerado (o diagrama continua autocontido e renderiza em qualquer lugar).
- `diagramas/tema.svg` define o visual de todos os diagramas: edite-o para mudar
  cores e tipografia dos próximos diagramas (os antigos não mudam).
- `requisitos/tema.html` define o padrão dos documentos de `1_Requisitos/` (marca
  d'água, estilo, formato e componentes). Abra-o no navegador para ver o catálogo;
  para mudar o visual use a skill `/requisito-estilo` — cada documento adota o
  tema novo quando for atualizado por ela.
EOF

  write_once "1_Requisitos/README.md" << 'EOF'
# 1_Requisitos

Requisitos do **produto**: o que ele faz, para quem e com quais regras.
Aqui não se fala de backend, frontend ou tecnologia.

- Arquivos `<NN>_<nome>.html`, autocontidos, criados e alterados pela skill `/requisito`.
  Abra no navegador: temas claro, sistema e escuro, e botão **PDF**.
- Padrão (marca d'água, estilo, formato, componentes): `0_Assets/requisitos/tema.html`.
- Cada documento abre com a marca de topo (projeto, documento, versão, data/hora, status)
  e fecha com o histórico. Toda alteração soma 1 na versão.
- `./boaz.sh requisitos` lista os documentos com versão, data e status.
- `./boaz.sh pdf <documento>` gera `pdf/<documento>_v<NN>_<AAAAMMDD-HHMM>.pdf`.
- Para ilustrar, referencie um diagrama **com a versão explícita**:
  `<figure class="diagrama"><img src="../2_Diagramas/fluxo-cadastro_v02_20261010-1430.svg" alt="…">…</figure>`
EOF

  write_once "2_Diagramas/README.md" << 'EOF'
# 2_Diagramas

Diagramas de desenvolvimento (backend e frontend): sequência, classes, ER,
fluxos, estados, componentes, navegação de telas, contratos de API.

- Somente `.svg`, gerados pela skill `/diagrama-dev`.
- Nome: `<legenda>_v<NN>_<AAAAMMDD-HHMM>.svg` — versões antigas são mantidas.
EOF

  write_once "3_Arquitetura/README.md" << 'EOF'
# 3_Arquitetura

Diagramas de alto nível: contexto do sistema, contêineres, cloud, rede,
ambientes, tecnologias escolhidas e integrações externas.

- Somente `.svg`, gerados pela skill `/diagrama-arquitetura`.
- Nome: `<legenda>_v<NN>_<AAAAMMDD-HHMM>.svg` — versões antigas são mantidas.
EOF

  write_once "4_CI_CD/README.md" << 'EOF'
# 4_CI_CD

Estruturas de entrega: pipelines de build/teste/deploy, manifests e scripts
de release. A ferramenta é escolhida pelo projeto.
EOF

  write_once "5_DEV/README.md" << 'EOF'
# 5_DEV

Ambiente de desenvolvimento.

```
5_DEV/
├── backend/
├── frontend/
└── qa/
    ├── backend/
    └── frontend/
```
EOF
}

# Escapa texto para HTML (nome do projeto em atributos e conteúdo)
html_escape() {
  printf '%s' "$1" | sed 's/&/\&amp;/g; s/</\&lt;/g; s/>/\&gt;/g; s/"/\&quot;/g'
}

# Visão do produto no padrão de 0_Assets/requisitos/tema.html — só se a pasta ainda não tiver documentos
create_requirements_template() {
  local now p casca
  ls "$REQ_DIR"/*.html "$REQ_DIR"/*.md 2>/dev/null | grep -qv '/README\.md$' && return
  if [ ! -f "$REQ_THEME" ]; then
    warn "Sem ${REQ_THEME}: modelo da visão do produto não criado — rode ./boaz.sh init de novo depois."
    return
  fi
  now=$(date '+%Y-%m-%d %H:%M')
  p=$(html_escape "$PROJECT_NAME")
  # A casca (fontes, estilo e script) vem do tema do projeto, sem alterar
  casca=$(awk '/<!-- boaz:casca:inicio/,/<!-- boaz:casca:fim/' "$REQ_THEME")
  write_once "$REQ_DIR/00_visao-produto.html" << EOF
<!doctype html>
<html lang="pt-BR">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Visão do produto · ${p} · v01</title>
<!-- boaz:marca — metadados lidos pelo ./boaz.sh (um por linha, nesta ordem) -->
<meta name="boaz:projeto" content="${p}">
<meta name="boaz:documento" content="00_visao-produto">
<meta name="boaz:caminho" content="${REQ_DIR}/00_visao-produto.html">
<meta name="boaz:tipo" content="Visão do produto">
<meta name="boaz:versao" content="v01">
<meta name="boaz:data" content="${now}">
<meta name="boaz:status" content="Rascunho">
${casca}
</head>
<body>

<header class="boaz-marca-topo">
  <p class="boaz-eyebrow">${p} · Visão do produto</p>
  <h1>Visão do produto</h1>
  <p class="boaz-objetivo"><span>Objetivo</span>definir o problema que ${p} resolve, para quem, e como saberemos que deu certo.</p>
  <dl class="boaz-carimbo">
    <div><dt>Documento</dt><dd>00_visao-produto</dd></div>
    <div><dt>Versão</dt><dd><span class="boaz-versao">v01</span></dd></div>
    <div><dt>Data</dt><dd class="boaz-data">${now%% *} · ${now##* }</dd></div>
    <div><dt>Status</dt><dd><span class="status status-rascunho">Rascunho</span></dd></div>
  </dl>
</header>

<main>
  <section id="problema">
    <h2>Problema</h2>
    <!-- até 2 parágrafos curtos: a dor, quem a sente e o que acontece hoje -->
    <p>…</p>
  </section>

  <section id="objetivos-e-metricas">
    <h2>Objetivos e métricas</h2>
    <div class="metricas">
      <article class="metrica">
        <h3>Objetivo</h3>
        <p>métrica</p>
        <p class="meta">meta</p>
        <p>prazo</p>
      </article>
    </div>
  </section>

  <section id="personas">
    <h2>Personas</h2>
    <div class="personas">
      <article class="persona" data-inicial="P">
        <h3>Persona</h3>
        <p><span>Quem é</span>…</p>
        <p><span>Precisa de</span>…</p>
      </article>
    </div>
  </section>

  <section id="escopo">
    <h2>Escopo</h2>
    <ul class="escopo">
      <li>…</li>
    </ul>
  </section>

  <section id="fora-de-escopo">
    <h2>Fora de escopo</h2>
    <ul class="fora">
      <li>…</li>
    </ul>
  </section>

  <section id="em-aberto">
    <h2>Em aberto</h2>
    <ul class="pendencias">
      <li>… <span class="tag dono">Produto</span></li>
    </ul>
  </section>
</main>

<footer class="boaz-marca-rodape">
  <p class="boaz-eyebrow">Histórico</p>
  <table class="boaz-historico">
    <thead><tr><th>Versão</th><th>Data</th><th>Mudança</th></tr></thead>
    <tbody>
      <tr><td><span class="boaz-versao">v01</span></td><td>${now}</td><td>Criação (modelo do boaz)</td></tr>
    </tbody>
  </table>
  <div class="boaz-rodape-linha">
    <span>${p} · v01 · ${now}</span>
    <span class="boaz-arquivo">${REQ_DIR}/00_visao-produto.html</span>
  </div>
</footer>

</body>
</html>
EOF
}

# ── ASSETS ───────────────────────────────────────────────────
# Copia de assets/ do boaz, sem sobrescrever (o projeto pode customizar os temas e adicionar ícones):
#   tema.html → 0_Assets/requisitos/tema.html (padrão, estilo e catálogo dos documentos de requisito)
#   tema.svg  → 0_Assets/diagramas/tema.svg   (estilo + catálogo de formas e notação)
#   icones/   → 0_Assets/diagramas/icones/
# Usa a cópia local (clone do boaz) se existir; senão baixa do GitHub.
install_assets() {
  local src tmp="" n
  src="$(cd "$(dirname "$0")" && pwd)/assets"
  if [ ! -f "$src/tema.svg" ]; then
    tmp=$(mktemp -d)
    if command -v curl &>/dev/null; then
      curl -fsSL "$ASSETS_TARBALL" | tar -xzf - -C "$tmp" boaz-main/assets 2>/dev/null || true
    elif command -v wget &>/dev/null; then
      wget -qO- "$ASSETS_TARBALL" | tar -xzf - -C "$tmp" boaz-main/assets 2>/dev/null || true
    fi
    src="$tmp/boaz-main/assets"
  fi
  if [ ! -f "$src/tema.svg" ]; then
    warn "Temas e ícones não baixados (sem rede?) — rode ./boaz.sh init de novo depois."
    [ -z "$tmp" ] || rm -rf "$tmp"
    return
  fi
  [ ! -f "$src/tema.html" ] || write_once "$REQ_THEME" < "$src/tema.html"
  write_once "0_Assets/diagramas/tema.svg" < "$src/tema.svg"
  # cp -Rn: copia a árvore de uma vez, sem sobrescrever (|| true: alguns cp saem com 1 ao pular arquivos)
  mkdir -p "$ICONS_DIR"
  n=$(find "$ICONS_DIR" -type f -name '*.svg' | wc -l)
  cp -Rn "$src/icones/." "$ICONS_DIR/" 2>/dev/null || true
  n=$(( $(find "$ICONS_DIR" -type f -name '*.svg' | wc -l) - n ))
  [ -z "$tmp" ] || rm -rf "$tmp"
  [ "$n" -eq 0 ] || success "Ícones de cloud: ${n} novos em ${D}${ICONS_DIR}/${NC}"

  write_always "$ICONS_DIR/README.md" << 'EOF'
# Ícones de cloud

Gerenciado pelo `./boaz.sh init` (copia só o que falta; ícones que você adicionar aqui são mantidos).
Todos em `.svg`, nomes em kebab-case.

```
icones/
├── aws/                       # AWS Architecture Icons (pacote oficial 07/2025)
│   ├── servicos/<categoria>/  # um por serviço (64px) — amazon-ec2.svg, aws-lambda.svg
│   ├── recursos/<categoria>/  # recursos de um serviço (48px) — amazon-s3-bucket.svg
│   ├── grupos/                # fronteiras: region, aws-cloud, virtual-private-cloud-vpc, subnets
│   └── categorias/            # ícone por categoria — compute.svg, database.svg
└── gcp/                       # Google Cloud icons
    ├── produtos/              # ícones atuais dos produtos principais — bigquery.svg, gke.svg
    ├── categorias/            # ícone por categoria — compute.svg, databases.svg
    └── legado/                # conjunto completo antigo — cloud-functions.svg, pubsub.svg
└── azure/                     # Azure Public Service Icons (V24)
    └── <categoria>/           # compute/, databases/, networking/, general/… — virtual-machine.svg, kubernetes-services.svg
```

Procure por nome em vez de listar tudo: `find 0_Assets/diagramas/icones -iname '*lambda*'`.
EOF
}

# ── SKILLS DE DIAGRAMA ───────────────────────────────────────
# Regras comuns às duas skills; __PASTA__ é substituído pela pasta de saída
diagram_skill_common() {
  sed "s|__PASTA__|$1|g" << 'EOF'

## Versionamento (obrigatório)

Nome do arquivo: `<legenda>_v<NN>_<AAAAMMDD-HHMM>.svg`

- **legenda**: kebab-case, sem acentos, curta. Identifica o diagrama e **não muda** entre versões (ex.: `fluxo-cadastro`).
- **NN**: versão com 2 dígitos, começa em `01` e soma 1 a cada alteração.
- **timestamp**: data/hora local em que aquela versão foi gerada.

Obtenha o caminho exato com:

```bash
./boaz.sh svg __PASTA__ <legenda>
```

Se o `boaz.sh` não estiver disponível, calcule pela regra acima.
**Nunca** sobrescreva, renomeie ou apague uma versão existente — cada alteração é um arquivo novo.

## Fluxo

**Diagrama novo**
1. Leia os documentos relevantes de `1_Requisitos/` (`.html`) e rode `./boaz.sh diagramas` para reaproveitar nomes e evitar duplicatas.
2. Se a ambiguidade mudar o desenho, faça no máximo 1–2 perguntas; caso contrário, assuma e declare as premissas na resposta.
3. Escolha a legenda, gere o caminho e escreva o SVG.

**Alteração** ("muda", "adiciona", "corrige" num diagrama existente)
1. Identifique a legenda e abra a **maior versão** (`ls __PASTA__/<legenda>_v*`).
2. Aplique só a mudança pedida, preservando layout, ids e o restante do desenho.
3. Salve como a próxima versão (`./boaz.sh svg __PASTA__ <legenda>`).
4. Rode `grep -rn "<legenda>_v" 1_Requisitos` e, se houver referências à versão anterior, pergunte se devem apontar para a nova. Não altere sem confirmação; confirmado, troque o caminho no `src`/`href` e na legenda da `<figure class="diagrama">`, e cada documento alterado ganha uma versão nova (marca d'água e histórico, como na skill `requisito`).

## Assets (`0_Assets/`)

Antes de desenhar, rode `ls 0_Assets/projeto 0_Assets/diagramas` e reaproveite o que existir: ícones de tecnologias, logos de integrações e da marca.
Ícones de cloud ficam em `0_Assets/diagramas/icones/{aws,gcp,azure}/` (centenas de arquivos — leia o `README.md` da pasta e busque por nome: `find 0_Assets/diagramas/icones -iname '*lambda*'`, nunca `ls -R`).

- **Embuta sempre** — nunca referencie o arquivo por caminho (`href="../0_Assets/..."` quebra no GitHub e em visualizadores de imagem).
  - `.svg`: copie o conteúdo gráfico para um `<symbol id="asset-<nome>" viewBox="...">` em `<defs>` (com o `viewBox` do original) e desenhe com `<use href="#asset-<nome>" x=".." y=".." width=".." height=".."/>`. Remova `<script>`, `<foreignObject>`, handlers `on*` e metadados de editor; prefixe ids internos com `<nome>-` para não colidirem. Se o ícone tiver `<style>` próprio (os do GCP trazem `.cls-1`, `.st0`…), converta cada regra em atributo (`fill="#4285f4"`) nos elementos e apague o `<style>` — senão as classes vazam e colidem com outros ícones. O `tema.svg` traz exemplos prontos em `#prov-*`.
  - `.png`/`.jpg`/`.webp`: `<image href="data:image/png;base64,..."/>` gerado com `base64 < arquivo | tr -d '\n'`. Evite arquivos acima de ~200 KB.
- Ícone é apoio, não substitui o texto: a caixa continua com nome e tecnologia escritos. Tamanho uniforme (24–32px), sempre no mesmo lugar da caixa (padrão do tema: à esquerda, nome e tecnologia alinhados depois dele).
- Faltou um ícone? Use a forma neutra `#ic-*` do tema que mais se aproxima (ou a forma simples da notação) e mencione na resposta qual asset poderia ser adicionado em `0_Assets/diagramas/`.

## Visual (obrigatório)

O diagrama precisa ser **bonito**, não só correto — algo que daria orgulho de colocar numa apresentação.

**Tema padrão (modo dark).** `0_Assets/diagramas/tema.svg` é o estilo e o catálogo visual: cores por papel, tipografia, tipos de comunicação, formas neutras de arquitetura, exemplo de arquitetura, ícones por provedor, um cartão por tipo de diagrama UML com os elementos que ele usa e o exemplo da marca d'água de topo e rodapé. Abra-o (`grep -n 'id="' 0_Assets/diagramas/tema.svg` lista seções e símbolos) e:
- copie **sem alterar** o bloco `<style>` e, de `<defs>`, todos os `<marker>`, o filtro `sombra` e o gradiente `marca-acento`;
- dos `<symbol>`, copie **só os que usar**: `#ic-*` (formas neutras de arquitetura — banco, fila, função, gateway…), `#uml-*` (ator, ícone de componente, artefato), `#prov-*` (ícones oficiais de exemplo);
- use o cartão do tipo de diagrama (seção 6, `<g id="uml-...">`, `er`, `c4`) como referência de composição e o exemplo da seção 7 (`<g id="exemplo-marca">`) para a marca d'água.
Se o arquivo não existir, rode `./boaz.sh init` para recriá-lo.
- Estilize **apenas por classe** do tema (`node-blue`, `edge`, `label-strong`, `muted`...). Nada de `fill`/`stroke`/`font-*` inline nem cores fora do tema.
- Fundo: primeiro elemento `<rect class="bg">` cobrindo todo o `viewBox`.
- Cor = papel: no máximo 4 classes `node-*` coloridas por diagrama, cada uma explicada na legenda; `node-external` para o que não é do projeto, `node-red` só para erro/risco. Destaque o fluxo principal com `edge-accent` + `seta-destaque`; o resto com `edge`. Assíncrono/retorno: adicione `edge-async`.
- Comunicação (seção 2 do tema): síncrono principal `edge-accent` + `seta-destaque`; síncrono `edge` + `seta`; resposta `edge edge-async` + `seta-aberta`; evento/mensagem `edge edge-async` + `seta`; stream bidirecional `seta` nas duas pontas; dados/lote `edge edge-data`. Protocolo no rótulo da aresta ou como `chip` + `chip-text`.
- Notação UML com os elementos do tema: markers `seta-aberta`, `heranca`, `extensao`, `composicao`, `agregacao`, `er-um`, `er-muitos` e classes `ink`, `ink-ring`, `node-note`, `node-face`, `uml-keyword`, `label-underline`, `activation`, `frame-tag`, `frame-op`. Se o tema do projeto for antigo e não tiver algum deles, declare-o no diagrama com as mesmas cores do tema (ou recrie o tema: apague `0_Assets/diagramas/tema.svg` e rode `./boaz.sh init`).

**Composição.**
- Grade de 8px: coordenadas e tamanhos múltiplos de 8; margem externa de 40px; espaço mínimo de 48px entre caixas.
- Leitura em uma direção (esquerda→direita ou cima→baixo); alinhe caixas em linhas e colunas e dê o mesmo tamanho a elementos do mesmo tipo.
- Caixas com `rx="10"`, padding interno ≥ 16px, `filter="url(#sombra)"` no `<g>` do nó. Texto centralizado: título em `label-strong`, tecnologia/detalhe em `mono` ou `muted` logo abaixo.
- Tamanho pelo texto: estime ~7,5px por caractere em 13–14px (~8px em `mono`) e dimensione a caixa para caber com folga. Nenhum texto pode sobrepor formas, linhas ou outro texto.
- Setas ortogonais (`<path>` com segmentos H/V, cantos retos) ou retas; terminam na borda da caixa, sem atravessá-la. Rótulos acima da linha, em `muted`; se encostarem em algo, ponha um `<rect class="edge-label-bg">` atrás. Minimize cruzamentos.
- Fronteiras: `<rect class="boundary" rx="14">` com rótulo `boundary-label` em MAIÚSCULAS no canto superior esquerdo.

**Estrutura do arquivo.**
- Um único arquivo autocontido: sem fontes, imagens ou CSS externos; sem `<script>` nem `<foreignObject>`.
- `xmlns="http://www.w3.org/2000/svg"`, `viewBox`, `width` e `height` definidos.
- `<title>` com o título do diagrama; `<desc>` com o que ele mostra e o histórico curto (`v01: criação`, `v02: adicionado ...`).
- Agrupe cada elemento lógico em `<g id="...">` com id kebab-case — facilita alterações futuras.
- Numa alteração, mantenha o tema da versão anterior, a menos que pedirem para atualizar o visual.

**Marca d'água (obrigatória).** Todo diagrama faz parte da documentação: abre com uma faixa de topo e fecha com uma de rodapé, ambas de largura total do `viewBox`, encostadas nas bordas (sem margem). Copie a estrutura do exemplo da seção 7 do tema trocando só os textos.
- **Topo** — `<g id="marca-topo">` em `y=0`, altura 112:
  - `<rect class="wm-band">` de `0,0` até a largura total, e `<rect class="wm-accent">` de 2px em `y=110` (gradiente);
  - à esquerda, em `x=40`: sobretítulo `wm-eyebrow` em `y=40` com `<PROJETO> · <TIPO DE DIAGRAMA>` em MAIÚSCULAS (projeto = `PROJECT_NAME` de `.boaz`), o nome do diagrama em `title` em `y=72` e uma linha de contexto em `subtitle` em `y=94`;
  - à direita, o carimbo: `DATA` em `x = largura − 192` (`wm-meta-label` em `y=44`; valor `wm-meta-value` em `y=72`: `AAAA-MM-DD · HH:MM`, o mesmo instante do nome do arquivo); um `wm-sep` vertical 24px antes; `VERSÃO` 96px antes da data (`wm-meta-label` + selo `<rect class="wm-badge" width="48" height="22" rx="11">` com `wm-badge-text` centralizado: `v<NN>`);
  - o título não pode invadir os ~300px do carimbo; se não couber, encurte o subtítulo ou alargue o `viewBox`.
- **Rodapé** — `<g id="marca-rodape">` encostado no fim do `viewBox`, altura 116 (+26 por linha extra de legenda):
  - `<rect class="wm-band">` com `wm-sep` de 1px na borda de cima;
  - `LEGENDA` em `wm-eyebrow` e, numa linha, **todos** os elementos com significado que aparecem no desenho e só eles: cada classe `node-*` (amostra 14×14 `rx="3"` com a classe + papel em `label`) e cada tipo de aresta (linha de 28px com a mesma classe e o mesmo marker + significado). 28px entre itens; se não couber, quebre em outra linha;
  - um `divider` interno e, abaixo, à esquerda em `footer`: `v<NN> · <o que o diagrama mostra>` (numa alteração, o que mudou); à direita, `text-anchor="end"` em `wm-file`, o nome do arquivo `.svg`.
- O desenho fica entre as faixas: começa 40px abaixo da marca de topo e termina 40px acima da de rodapé. A legenda vive só no rodapé — nada de caixa de legenda solta no desenho.
- Numa alteração, atualize versão, data, nota e nome do arquivo nas marcas, e a legenda se os elementos mudaram.

**Revisão antes de entregar.**
- Se houver `xmllint`, valide com `xmllint --noout <arquivo>` e corrija os erros.
- Se houver `rsvg-convert` (ou `qlmanage` no macOS), renderize um PNG temporário no scratchpad, **olhe a imagem** e corrija sobreposições, textos cortados, desalinhamentos e espaços vazios desequilibrados antes de responder. Confira também as marcas d'água: versão e data iguais às do nome do arquivo e legenda batendo com o desenho.

## Resposta

Responda curto: caminho do arquivo criado, premissas assumidas (se houver) e o trecho para referenciar no requisito (`.html`, componente **Diagramas** de `0_Assets/requisitos/tema.html`):

```html
<figure class="diagrama">
  <a href="../__PASTA__/<arquivo>.svg"><img src="../__PASTA__/<arquivo>.svg" alt="<o que o diagrama mostra>"></a>
  <figcaption><strong><Título></strong><code>__PASTA__/<arquivo>.svg</code></figcaption>
</figure>
```
EOF
}

create_diagram_skills() {
  {
    cat << 'EOF'
---
name: diagrama-dev
description: Cria ou altera diagramas de desenvolvimento (backend e frontend) como SVG versionado em 2_Diagramas/. Use para diagramas UML — classes, objetos, pacotes, componentes internos, estrutura composta, perfil, casos de uso, atividades, sequência, comunicação, visão geral de interação, estados e tempo — além de entidade-relacionamento, navegação de telas e contratos de API, ou quando pedirem para alterar um diagrama existente dessa pasta.
---

# Diagrama de desenvolvimento → `2_Diagramas/`

Você é especialista em modelagem de software e UML 2.5. A saída é **sempre um novo arquivo `.svg`** em `2_Diagramas/` — nunca apenas texto, Mermaid ou PlantUML.

## Escopo

Pertence aqui o que mostra **como o software funciona por dentro**: a estrutura do código e do domínio e o comportamento entre seus elementos.

Não pertence: cloud, rede, provedores, ambientes e deploy (diagrama de implantação, C4) → skill `diagrama-arquitetura` (`3_Arquitetura/`).

## Escolha do tipo

Se o pedido nomear o tipo, use-o. Senão, escolha pela pergunta que o diagrama responde e diga na resposta qual tipo usou e por quê:

| Pergunta | Tipo |
|---|---|
| O que o sistema oferece e para quem? | Casos de uso |
| Quais conceitos existem e como se relacionam? | Classes (ou ER, se o foco for persistência) |
| Como fica um cenário concreto em memória? | Objetos |
| Como o código se organiza em módulos e quem depende de quem? | Pacotes |
| Quais blocos de software existem e quais interfaces trocam? | Componentes |
| Como um componente é montado por dentro? | Estrutura composta |
| Que extensões de UML/estereótipos o projeto adota? | Perfil |
| Qual é o passo a passo de um processo/regra? | Atividades |
| Em que ordem os participantes trocam mensagens? | Sequência |
| Quem fala com quem num cenário (foco nos vínculos)? | Comunicação |
| Como vários cenários se encadeiam? | Visão geral de interação |
| Quais estados um objeto atravessa? | Estados |
| Quanto tempo cada estado/mensagem pode levar? | Tempo |
| Como o usuário navega entre telas? / Qual o contrato de um endpoint? | Navegação de telas / Contrato de API |

Prefira **um tipo por arquivo**. Se o pedido cobrir duas perguntas, gere dois diagramas (legendas distintas) e avise.

## Notação UML

Siga a UML 2.5 com os elementos do tema; não invente símbolos. Multiplicidades, guardas e rótulos em `muted`; estereótipos `«...»` em `uml-keyword` acima do nome.

**Estruturais**
- **Classes**: caixa em 3 compartimentos separados por linha (nome em `label-strong` · atributos · operações em `mono`, com visibilidade `+ - # ~` e tipos `nome: Tipo`). Abstrata: `«abstract»`; interface: `«interface»`. Relações: associação (linha, `seta-aberta` se navegável, papéis e multiplicidade `1`, `0..*` nas pontas), herança (`heranca`), realização (`edge-async` + `heranca`), dependência (`edge-async` + `seta-aberta`), composição (`composicao` no lado do todo), agregação (`agregacao` no lado do todo).
- **Objetos**: caixas com nome sublinhado `pedido1 : Pedido` (classes `label-strong label-underline`) e valores `campo = valor` em `mono`; vínculos sem multiplicidade. Mostra um instante concreto do diagrama de classes.
- **Pacotes**: pasta com aba (retângulo pequeno sobre o retângulo principal) e nome; elementos dentro ou listados. Dependências `edge-async` + `seta-aberta` rotuladas `«import»`/`«access»`. Evite ciclos — se existirem, destaque com `node-red`.
- **Componentes**: retângulo com `«component»` e o ícone `#uml-componente` no canto superior direito. Interface fornecida = pirulito (linha + círculo `ink-ring`); requerida = soquete (meio-círculo aberto). Conecte soquete ao pirulito; portas como quadrados pequenos (`node-face`) sobre a borda.
- **Estrutura composta**: um classificador grande cujo interior mostra as partes `nome : Tipo [mult]`, portas na borda e conectores entre partes. Colaborações em elipse tracejada.
- **Perfil**: pacote `«profile»` com estereótipos `«stereotype» Nome` estendendo metaclasses `«metaclass» Class` por seta de extensão (linha contínua + marker `extensao`, triângulo **preenchido**). Liste as tagged values em `mono`.
- **Entidade-relacionamento** (não UML, mas útil): tabelas com chave (`PK`, `FK` em `mono`), cardinalidade nas pontas com os markers `er-um` e `er-muitos` (pé de galinha).

**Comportamentais**
- **Casos de uso**: fronteira do sistema (`boundary`, nome no topo), atores como bonecos de palito fora dela (`#uml-ator`, nome abaixo), casos de uso em elipses com verbo + objeto (`Cadastrar usuário`). `«include»`/`«extend»` com `edge-async` + `seta-aberta`; generalização com `heranca`. Se `1_Requisitos/` tiver IDs (`RF-01`), cite-os em `muted` dentro/abaixo da elipse.
- **Atividades**: início `ink` (círculo cheio), fim `ink-ring` + `ink` (alvo), ações em retângulos arredondados, decisão/merge em losango com guardas `[sim]`/`[não]`, fork/join em barra `ink`. Raias (swimlanes) como colunas `boundary` rotuladas no topo quando houver mais de um responsável.
- **Sequência**: participantes no topo (`:Classe` ou ator), linha de vida `lifeline`, barras de ativação estreitas (`activation`) sobre ela. Mensagem síncrona: linha + `seta`; assíncrona: linha + `seta-aberta`; retorno: `edge-async` + `seta-aberta`. Numere as mensagens. Fragmentos combinados (`alt`, `opt`, `loop`, `par`) como retângulos `boundary` com o operador num pentágono no canto (`frame-tag` + `frame-op`) e guardas `[condição]`.
- **Comunicação**: objetos em caixas ligados por linhas simples (vínculos); ao longo de cada vínculo, mensagens numeradas `1: criar()`, `1.1: validar()` com uma pequena seta indicando a direção.
- **Visão geral de interação**: estrutura de atividades (início, decisões, fork, fim) onde cada nó é um quadro `ref` (retângulo com `ref` num pentágono `frame-tag` + `frame-op` no canto) apontando para outro diagrama de sequência — cite a legenda/versão do diagrama referenciado — ou uma interação inline pequena.
- **Estados**: estado inicial `ink`, estados em retângulos bem arredondados (`rx="16"`) com nome e, se houver, `entry/`, `do/`, `exit/` em `mono`; transições `evento [guarda] / ação`; estado final `ink-ring` + `ink`. Estados compostos como um estado grande contendo os subestados.
- **Tempo**: eixo de tempo horizontal com marcas e unidade; uma faixa por participante (nome à esquerda) com a linha de estado em degraus (`edge-accent`) mudando de nível a cada transição; restrições de duração `{≤ 200 ms}` entre marcas com `edge-async`.

**Específicos do projeto**
- **Navegação de telas**: retângulos representando telas (nome + rota em `mono`), setas rotuladas com a ação do usuário.
- **Contrato de API**: caixa por endpoint (`MÉTODO /rota` em `mono`), com request e responses (`200`, `4xx`) em compartimentos.
EOF
    diagram_skill_common "2_Diagramas"
  } | write_always ".claude/skills/diagrama-dev/SKILL.md"

  {
    cat << 'EOF'
---
name: diagrama-arquitetura
description: Cria ou altera diagramas de arquitetura de alto nível como SVG versionado em 3_Arquitetura/. Use para contexto do sistema, contêineres (C4), diagrama de implantação UML, componentes no nível de serviços/sistemas, cloud, rede, ambientes, deploy, tecnologias escolhidas e integrações externas, ou quando pedirem para alterar um diagrama existente dessa pasta.
---

# Diagrama de arquitetura → `3_Arquitetura/`

Você é arquiteto de soluções. A saída é **sempre um novo arquivo `.svg`** em `3_Arquitetura/` — nunca apenas texto, Mermaid ou PlantUML.

## Escopo

Pertence aqui a **visão de alto nível**: contexto do sistema e atores, contêineres/serviços e suas tecnologias, provedores de cloud e serviços gerenciados, rede (região, rede privada, sub-redes), ambientes, topologia de deploy, filas e integrações externas.

Não pertence: detalhe interno de código (classes, objetos, pacotes, sequência entre métodos, estados, telas e demais UML de código) → skill `diagrama-dev` (`2_Diagramas/`).

## Escolha do tipo

Se o pedido nomear o tipo, use-o. Senão, escolha pela pergunta e diga na resposta qual tipo usou:

| Pergunta | Tipo |
|---|---|
| Quem usa o sistema e com quais sistemas externos ele conversa? | C4 nível 1 — contexto |
| Quais aplicações, serviços e bancos compõem o sistema e com que tecnologia? | C4 nível 2 — contêiner |
| Quais serviços/sistemas existem e quais interfaces expõem e consomem? | Componentes UML (nível de serviço) |
| Onde cada artefato roda — nós, ambientes, rede? | Implantação UML |

## Neutralidade de provedor

A arquitetura deve valer para **Azure, AWS e GCP**. Nunca use nome de produto de um único provedor (`Lambda`, `EKS`, `S3`, `Cosmos DB`, `BigQuery`…): nomeie pela **categoria** do serviço gerenciado. Tecnologias abertas e portáveis (PostgreSQL, Kubernetes, Kafka, Redis, Docker) podem ser citadas. Só use o nome de um provedor se o pedido o exigir explicitamente — e então diga isso na resposta.

| Termo neutro | AWS | Azure | GCP |
|---|---|---|---|
| Rede privada / sub-rede | VPC / Subnet | VNet / Subnet | VPC / Subnet |
| Conta / assinatura / projeto | Account | Subscription | Project |
| Máquina virtual | EC2 | Virtual Machines | Compute Engine |
| Função serverless | Lambda | Functions | Cloud Functions / Cloud Run functions |
| Contêiner serverless | Fargate / App Runner | Container Apps | Cloud Run |
| Cluster Kubernetes gerenciado | EKS | AKS | GKE |
| Armazenamento de objetos | S3 | Blob Storage | Cloud Storage |
| Banco relacional gerenciado | RDS / Aurora | Azure Database / SQL Database | Cloud SQL / AlloyDB |
| Banco NoSQL gerenciado | DynamoDB | Cosmos DB | Firestore / Bigtable |
| Cache gerenciado | ElastiCache | Azure Cache for Redis | Memorystore |
| Fila de mensagens | SQS | Service Bus / Storage Queues | Pub/Sub / Cloud Tasks |
| Barramento / tópico de eventos | SNS / EventBridge | Event Grid / Event Hubs | Pub/Sub / Eventarc |
| API gateway | API Gateway | API Management | API Gateway / Apigee |
| Balanceador de carga | ELB / ALB | Load Balancer / Application Gateway | Cloud Load Balancing |
| CDN | CloudFront | Front Door / CDN | Cloud CDN |
| DNS gerenciado | Route 53 | Azure DNS | Cloud DNS |
| Identidade de usuários | Cognito | Entra ID / Entra External ID | Identity Platform |
| Identidade e acesso (IAM) | IAM | Entra ID + RBAC | IAM |
| Cofre de segredos | Secrets Manager | Key Vault | Secret Manager |
| Observabilidade (logs/métricas) | CloudWatch | Azure Monitor | Cloud Logging / Monitoring |
| Data warehouse | Redshift | Synapse / Fabric | BigQuery |
| Registro de contêineres | ECR | Container Registry | Artifact Registry |

Se o termo não estiver na tabela, crie um equivalente neutro no mesmo estilo (categoria + "gerenciado", quando couber).

## Notação

- **C4 contexto/contêiner**: como descrito abaixo nas regras gerais.
- **Componentes (nível de serviço)**: cada serviço ou sistema em retângulo com `«component»` (ou `«system»`) e o ícone `#uml-componente` no canto; interface fornecida = pirulito (linha + círculo `ink-ring`) rotulada com o contrato (`REST /pedidos`, `tópico pedido.criado`); requerida = soquete (meio-círculo). Conecte soquete ao pirulito.
- **Implantação UML**: nós como caixas 3D (retângulo `node` com face superior e lateral em paralelogramos `node-face`) com `«device»` ou `«executionEnvironment»` e o nome (`Cluster Kubernetes gerenciado`, `Máquina virtual`, `Navegador`); nós podem conter nós. Artefatos dentro dos nós como retângulos com `«artifact»`, o ícone `#uml-artefato` e nome do arquivo/imagem (`api:1.4.2` em `mono`). Caminhos de comunicação como linhas entre nós rotuladas com protocolo; dependência artefato→componente com `edge-async` + `seta-aberta` `«manifest»`.
- Cada caixa: nome em negrito, tecnologia entre colchetes (`[PostgreSQL 16]`, `[Função serverless]`) e uma linha de responsabilidade.
- Ícones: no diagrama neutro, use as formas neutras `#ic-*` do tema (seção 3 — `ic-banco-sql`, `ic-fila`, `ic-funcao`, `ic-gateway`, `ic-cdn`, `ic-objetos`, `ic-identidade`…) com 24px à esquerda do nome, como no exemplo da seção 4; nada de logo de produto. Ícones de tecnologias abertas e logos de integrações vêm de `0_Assets/diagramas/` (embutidos, ver **Assets**).
- Ícones de provedor (`icones/aws/`, `icones/gcp/`, `icones/azure/`) só quando o pedido fixar o provedor: substituem a forma neutra da mesma categoria (seção 5 do tema mostra a correspondência). Com provedor fixado, use `icones/aws/grupos/` para as fronteiras (região, VPC, sub-redes).
- Fronteiras (conta/assinatura/projeto, região, rede privada, cluster, ambiente) como retângulos tracejados rotulados no canto superior esquerdo.
- Setas rotuladas com o que trafega e o protocolo (`pedidos · HTTPS/JSON`, `eventos · AMQP`).
- Sistemas externos com `node-external`, para separar do que é do projeto.
EOF
    diagram_skill_common "3_Arquitetura"
  } | write_always ".claude/skills/diagrama-arquitetura/SKILL.md"
}

# ── SKILLS DE REQUISITOS ─────────────────────────────────────
create_requirements_skills() {
  write_always ".claude/skills/requisito/SKILL.md" << 'EOF'
---
name: requisito
description: Cria, altera, revisa ou exporta em PDF documentos de requisito do produto (.html) em 1_Requisitos/ — visão do produto, funcionalidades, requisitos transversais e glossário — no padrão de 0_Assets/requisitos/tema.html, com marca d'água de topo (projeto, documento, versão, data/hora, status) e histórico no rodapé. Use para escrever requisitos funcionais, não funcionais, regras de negócio, critérios de aceite, personas ou glossário, para alterar, revisar ou mudar o status de um documento dessa pasta, ou para gerar o PDF de um requisito.
---

# Documento de requisito → `1_Requisitos/`

Você é analista de produto. A saída é **sempre um `.html` autocontido em `1_Requisitos/`**, curto e claro, no padrão de `0_Assets/requisitos/tema.html`.

## Escopo

Pertence aqui **o produto**: o que ele faz, para quem, com quais regras e limites mensuráveis.

Não pertence: backend, frontend, banco, API, framework, provedor ou qualquer decisão de solução. Se o pedido trouxer tecnologia, reescreva como comportamento e avise. Diagramas são das skills `diagrama-dev` (`2_Diagramas/`) e `diagrama-arquitetura` (`3_Arquitetura/`); sugira-as quando um fluxo ficar mais claro desenhado. Mudar o **visual** (cores, fontes, componentes), migrar documentos `.md` antigos ou trocar a casca de documentos é da skill `requisito-estilo`.

## O padrão

`0_Assets/requisitos/tema.html` é a fonte da verdade: marca d'água, casca, visual, formato, escrita, catálogo de componentes, tipos de documento e versionamento. **Leia-o inteiro antes de escrever** (é a regra e, no código-fonte, o HTML pronto de cada componente) e siga-o mesmo quando divergir deste resumo — o projeto pode tê-lo customizado. Se não existir, rode `./boaz.sh init`.

Resumo do que não pode faltar:
- `<head>`: `charset`, `viewport`, `<title>Título · Projeto · vNN</title>`, o comentário `<!-- boaz:marca -->` e os 7 `<meta name="boaz:…">` (projeto = `PROJECT_NAME` de `.boaz`; data = `date '+%Y-%m-%d %H:%M'`), um por linha, na ordem do tema; depois a **casca** copiada sem alterar: `awk '/<!-- boaz:casca:inicio/,/<!-- boaz:casca:fim/' 0_Assets/requisitos/tema.html`.
- `<body>`: `<header class="boaz-marca-topo">` (sobretítulo `Projeto · Tipo`, `<h1>`, objetivo de uma frase, carimbo com documento, versão, data `AAAA-MM-DD · HH:MM` e status) → `<main>` com um `<section id="…"><h2>` por seção do tipo, na ordem do tema (opcional vazia é removida) → `<footer class="boaz-marca-rodape">` (histórico `Versão | Data | Mudança`, mais nova no topo, até 10 linhas, e a linha `Projeto · vNN · data` + caminho).
- Só componentes do catálogo, estilizados **só por classe**: nada de `style=""` (exceto o recorte de diagrama), `<style>`/`<script>` próprios, cores, fontes ou CDN fora da casca.
- Requisitos em tabela, linha com `id` igual ao ID (`<tr id="RF-01">`), ID em `<code class="id">`, uma obrigação por frase, "O sistema deve …", prioridade em `<span class="prio prio-deve">`, critério de aceite em `<article class="criterio">` + `<pre class="gherkin">` para cada `Deve`.
- Texto escapado: `&` → `&amp;`, `<` → `&lt;`, `>` → `&gt;` (também dentro do Gherkin).
- Curto: ≤ 12 requisitos funcionais, ≤ 4 páginas A4 impressas, uma funcionalidade por documento — passou, divida.
- HTML indentado com 2 espaços, um bloco por linha: o diff do git precisa ser legível.

## Diagramas e outros documentos

- Diagrama: `<figure class="diagrama">` apontando para o `.svg` **com a versão explícita**, por caminho relativo (`../2_Diagramas/<legenda>_vNN_<AAAAMMDD-HHMM>.svg`), com `alt` descritivo e o caminho na `<figcaption>`. Use a versão mais recente (`./boaz.sh diagramas`) e confira que o arquivo existe.
- Outro documento: `<a class="ref" href="02_cadastro-usuario.html#RF-01">Cadastro de usuário <code class="id">RF-01</code></a>`; termo do glossário: `99_glossario.html#<termo>`.

## Fluxo

**Antes de escrever**
1. Leia o tema, rode `./boaz.sh requisitos` e leia `00_visao-produto.html` e `99_glossario.html` se existirem — reaproveite nomes de personas e termos.
2. Próximos IDs (únicos no projeto inteiro, nunca reaproveitados):
   `for p in RF RNF RN; do grep -rhoE --include='*.html' --include='*.md' "\b$p-[0-9]+" 1_Requisitos | sort -t- -k2,2n | tail -1; done`

**Documento novo**
1. Escolha o tipo pelo tema (visão, funcionalidade, transversal, glossário) e o arquivo `<NN>_<nome>.html`: `NN` = próximo livre da faixa do tipo (`ls 1_Requisitos`), `nome` em kebab-case sem acentos.
2. Se uma ambiguidade mudar o escopo, faça no máximo 1–2 perguntas. O resto **não invente**: regra, limite ou número que o pedido não deu vira item de **Em aberto**.
3. Escreva com `v01`, status `Rascunho` e histórico `v01 · Criação`.

**Alteração** ("muda", "adiciona", "remove", "aprova" num documento existente)
1. Abra o documento e aplique só o que foi pedido; não reescreva o resto, não troque a casca e não renomeie o arquivo. Documento `.md` antigo? Peça a migração pela skill `requisito-estilo` antes (ou faça-a seguindo aquela skill).
2. Nova versão: `vNN` + 1 e data/hora atuais nos 5 lugares — `<title>`, `<meta boaz:versao/data>`, carimbo, linha nova no topo do histórico (o que mudou, citando os IDs) e linha do rodapé. Status muda no `<meta boaz:status>` e no carimbo (classe `status-…` junto). Mudança de status também é versão.
3. Requisito removido sai da tabela (e dos critérios); o ID não é reutilizado. Pendência respondida sai de Em aberto e vira requisito/regra.
4. Se o documento estava `Aprovado`, volte-o para `Em revisão`, a menos que o pedido diga outra coisa.
5. Termo novo do domínio? Proponha incluí-lo em `99_glossario.html` (que também ganha versão).

**PDF** ("exporta", "gera o PDF", "manda o pdf do …")
1. Rode `./boaz.sh pdf <documento>` (ex.: `./boaz.sh pdf 02_cadastro-usuario`): gera `1_Requisitos/pdf/<documento>_v<NN>_<AAAAMMDD-HHMM>.pdf` com a versão e a data do documento, tema claro, A4, marca de topo, histórico e cabeçalho/rodapé paginados.
2. Gere o PDF **depois** de salvar a versão pedida; não crie versão só para exportar.
3. Sem navegador Chromium instalado, o comando avisa: oriente a abrir o `.html` e usar o botão **PDF** (nome sugerido já versionado).

**Revisão** (sempre, antes de entregar)
- Marca d'água: `grep -nE 'boaz:(versao|data|status)"|<title>|boaz-versao|boaz-data|<td>[0-9]{4}-|boaz-rodape-linha' -A1 <arquivo>` — mesma versão e data/hora em todos. No navegador, o botão PDF fica vermelho se divergirem.
- Casca intacta: `diff <(awk '/<!-- boaz:casca:inicio/,/<!-- boaz:casca:fim/' 0_Assets/requisitos/tema.html) <(awk '/<!-- boaz:casca:inicio/,/<!-- boaz:casca:fim/' <arquivo>)` — vazio num documento novo; num existente, só pode diferir se ele usa um tema anterior (não atualize sem pedirem).
- HTML válido: `xmllint --html --noout <arquivo>` se houver (avisos de tags HTML5 podem ser ignorados; erros de tag não fechada, não).
- Seções na ordem do tema, nenhuma vazia, um `<h1>`, `<h3>` só em critérios e cartões.
- IDs duplicados: `grep -rhoE --include='*.html' '<tr id="(RF|RNF|RN)-[0-9]+"' 1_Requisitos | sort | uniq -d` (deve sair vazio).
- Palavras vagas: `sed -n '/<body>/,$p' <arquivo> | grep -niE 'rápid|fácil|intuitiv|amigável|simples|adequad|eficiente|robust|flexível|etc\.|e/ou|entre outros|se possível|geralmente|normalmente|TBD|a definir'` — troque cada uma por critério verificável.
- Tecnologia: `sed -n '/<body>/,$p' <arquivo> | grep -niE 'backend|frontend|banco de dados|\bAPI\b|endpoint|framework|servidor|\bSQL\b|cloud'` — reescreva como comportamento.
- Diagramas e links referenciados existem (`ls`).
- Se houver Chrome/Chromium, tire um `--screenshot` headless do documento (comando na skill `requisito-estilo`) e **olhe** antes de responder.

## Resposta

Responda curto: caminho do arquivo, versão e status, o que mudou (IDs), as pendências de **Em aberto** que precisam de alguém para responder e, se pedido, o caminho do PDF.
EOF

  write_always ".claude/skills/requisito-estilo/SKILL.md" << 'EOF'
---
name: requisito-estilo
description: Cuida da estilização dos documentos de requisito (.html) de 1_Requisitos/ — personaliza o tema 0_Assets/requisitos/tema.html (cores, tipografia, componentes, marca d'água, temas claro/sistema/escuro, impressão), aplica o tema atualizado a documentos existentes, migra documentos .md antigos para .html e exporta PDF versionado. Use quando pedirem para mudar o visual dos requisitos, criar um componente novo, atualizar a casca de documentos, converter requisitos .md ou gerar PDFs.
---

# Estilização dos requisitos → `0_Assets/requisitos/tema.html`

Você é designer de documentação técnica. O conteúdo dos requisitos é da skill `requisito`; aqui se cuida de **como eles aparecem**: o tema, a casca embutida em cada documento, a migração de `.md` e o PDF.

## Como o tema funciona

`0_Assets/requisitos/tema.html` é ao mesmo tempo **regra**, **catálogo renderizado** e **fonte da casca**. Leia-o inteiro antes de mexer.

- **Casca**: o bloco entre `<!-- boaz:casca:inicio -->` e `<!-- boaz:casca:fim -->` no `<head>` — fontes (Google Fonts: Inter e JetBrains Mono), `<style id="boaz-tema">` e `<script id="boaz-tema-js">`. Todo documento embute uma cópia idêntica: é autocontido, e o PDF de uma versão nunca muda por causa de outra.
- **Versão da casca**: a primeira linha do CSS e do script diz `boaz · tema dos documentos de requisito · vNN` — é por ela que `./boaz.sh requisitos` mostra quais documentos usam um tema anterior.
- **Tokens**: cores só por variáveis CSS (`--accent`, `--surface`, `--green`…), definidas **quatro vezes** — `:root` (claro), `@media (prefers-color-scheme: dark) { :root:not([data-theme="light"]) }` (sistema escuro), `:root[data-theme="dark"]` (escuro forçado) e `@media print { :root:root:root }` (impressão, sempre clara). O escuro é a paleta do `0_Assets/diagramas/tema.svg`; mantenha os dois alinhados.
- **Script**: tema (claro / sistema / escuro, salvo no navegador), botão PDF (força o claro e sugere `<documento>_vNN_<AAAAMMDD-HHMM>`), cabeçalho e rodapé de cada página via `@page` margin boxes, marca diagonal por status, conferência da marca d'água, sumário, destaque de Gherkin e rolagem lateral das tabelas (envolve cada `<table>` em `.boaz-tabela`; não escreva esse wrapper à mão). Ele lê os `<meta name="boaz:…">`. Nada no tema pode cortar conteúdo: o que for mais largo que a página rola dentro do próprio bloco (`pre`, `.boaz-tabela`).
- O que só serve ao catálogo (`.boaz-exemplo`, `details.boaz-snippet`, `.paleta`, `.amostra` e o script "Ver HTML") fica **fora** da casca.

## Personalizar o tema

1. Mude só o pedido. Para cor, altere o token nos quatro blocos (claro e impressão com a mesma cor; escuro e sistema escuro com a mesma cor). Contraste mínimo de 4,5:1 para texto e 3:1 para bordas de componentes, nos dois temas.
2. Componente novo: classe com nome em português, kebab-case, construída só com tokens; funciona nos dois temas e na impressão (`break-inside: avoid` se não puder quebrar entre páginas). Acrescente-o ao **Catálogo de componentes** do tema com um `.boaz-exemplo` e uma linha explicando quando usar.
3. **Nunca** renomeie nem remova uma classe usada por documentos (`grep -rl 'class="…' 1_Requisitos`): marque-a como obsoleta no catálogo e mantenha o estilo.
4. A casca continua autocontida: nada de CSS, script ou imagem externos além das fontes; sem bibliotecas.
5. É uma nova versão do tema: `vNN` + 1 nas duas linhas de versão da casca e na marca d'água do próprio `tema.html` (metadados, carimbo, histórico e rodapé, como qualquer documento).
6. Os documentos existentes **não** mudam sozinhos. Ao terminar, rode `./boaz.sh requisitos` e pergunte se a casca nova deve ser aplicada a eles.

## Aplicar o tema a documentos

Só com pedido ou confirmação. Para cada documento:
1. Troque o bloco da casca pelo do tema (de `boaz:casca:inicio` a `boaz:casca:fim`, inclusive), sem tocar no resto do `<head>` nem no `<body>`. Um script ajuda:
   ```bash
   awk 'NR==FNR { c = c $0 "\n"; next } /<!-- boaz:casca:inicio/ { printf "%s", c; s = 1 } !s { print } /<!-- boaz:casca:fim/ { s = 0 }' \
     <(awk '/<!-- boaz:casca:inicio/,/<!-- boaz:casca:fim/' 0_Assets/requisitos/tema.html) <doc>.html > /tmp/doc && mv /tmp/doc <doc>.html
   ```
2. Se o tema novo trouxe mudança de marcação (componente que mudou de estrutura), ajuste o `<body>` desse componente.
3. É versão nova do documento: `vNN` + 1, data/hora, histórico `Visual atualizado para o tema vNN`. Status não muda.

## Migrar `.md` para `.html`

1. `git mv 1_Requisitos/<doc>.md 1_Requisitos/<doc>.html` (preserva o histórico do git) e reescreva o conteúdo com os componentes do catálogo, sem mudar o texto dos requisitos:
   | Markdown | HTML do tema |
   |---|---|
   | tabela de cabeçalho `<!-- boaz:marca -->` | `<meta boaz:*>` + `<header class="boaz-marca-topo">` |
   | `# Título` + `> Objetivo:` | `<h1>` + `.boaz-objetivo` |
   | `## Seção` | `<section id="kebab"><h2>` |
   | tabelas RF / RN / RNF | `<table>` com `<tr id="ID">`, `code.id`, `.prio-*`, `.tag` |
   | `### \`RF-02\` …` + ` ```gherkin ` | `<article class="criterio" id="ca-RF-02">` + `<pre class="gherkin">` |
   | `- Como **x**, quero …, para …` | `<p class="historia">` |
   | `- [ ] pergunta — dono` | `<ul class="pendencias">` com `<span class="tag dono">` |
   | `> [!NOTE]` / `[!IMPORTANT]` / `[!WARNING]` | `<aside class="destaque nota|importante|aviso">` |
   | `![t](../2_Diagramas/x.svg)` | `<figure class="diagrama">` |
   | `[t](02_x.md)` | `<a class="ref" href="02_x.html">` |
   | `<!-- boaz:historico -->` + `<sub>` | `<footer class="boaz-marca-rodape">` |
2. A versão continua a sequência (`v04` em `.md` → `v05` em `.html`), histórico preservado (até 10 linhas) com a linha nova `Migrado para .html`.
3. Atualize links de outros documentos: `grep -rln '<doc>\.md' 1_Requisitos` (cada documento alterado ganha versão, com confirmação).
4. Ao final, `./boaz.sh requisitos` não deve listar nenhum `.md` legado.

## PDF

`./boaz.sh pdf <documento>` gera `1_Requisitos/pdf/<documento>_v<NN>_<AAAAMMDD-HHMM>.pdf` (versão e data do documento, A4, tema claro). Precisa de Chrome, Chromium, Edge ou Brave (ou `BOAZ_CHROME=/caminho/do/navegador`); sem eles, o botão **PDF** do documento abre a impressão com o nome já versionado. `./boaz.sh pdf todos` exporta todos os documentos.

## Revisão (sempre, antes de entregar)

- Renderize com o Chrome headless e **olhe**: tema claro (`--blink-settings=preferredColorScheme=1`), escuro (`preferredColorScheme=0`), largura de celular (`--window-size=390,2400`) e o PDF (`./boaz.sh pdf`). Sem sobreposição, texto cortado, rolagem horizontal da página ou contraste baixo.
  ```bash
  "<chrome>" --headless --disable-gpu --hide-scrollbars --window-size=1200,3000 --virtual-time-budget=5000 \
    --blink-settings=preferredColorScheme=1 --screenshot=<scratchpad>/claro.png "file://$PWD/0_Assets/requisitos/tema.html"
  ```
- Abra o `tema.html` e confira se cada componente do catálogo continua igual nos dois temas.
- Casca idêntica entre tema e documentos atualizados (`diff` dos blocos `awk`).

## Resposta

Responda curto: o que mudou no tema (e a nova versão), quais documentos foram atualizados ou migrados (com a versão nova de cada um), quais ficaram no tema anterior e, se gerados, os caminhos dos PDFs.
EOF
}

# ── DIAGRAMAS ────────────────────────────────────────────────
check_diagram_dir() {
  case " $DIAGRAM_DIRS " in
    *" $1 "*) ;;
    *) fail "Pasta inválida: $1 (use: ${DIAGRAM_DIRS// / ou })" ;;
  esac
}

# Imprime "<legenda> <versão> <arquivo>" de cada SVG versionado em $1
list_versions() {
  local f base
  for f in "$1"/*_v[0-9]*_*.svg; do
    [ -e "$f" ] || continue
    base=$(basename "$f" .svg)
    echo "$base" | sed -nE "s|^(.+)_v0*([0-9]+)_[0-9]{8}-[0-9]{4}$|\1 \2 $f|p"
  done
}

# Próximo caminho livre para a legenda: <pasta>/<legenda>_v<NN>_<AAAAMMDD-HHMM>.svg
cmd_svg() {
  [ $# -eq 2 ] || fail "Uso: ./boaz.sh svg <2_Diagramas|3_Arquitetura> <legenda>"
  local dir=${1%/} slug last
  check_diagram_dir "$dir"
  slug=$(slugify "$2")
  [ -n "$slug" ] || fail "Legenda vazia."
  last=$(list_versions "$dir" | awk -v s="$slug" '$1 == s && $2 > m { m = $2 } END { print m + 0 }')
  printf '%s/%s_v%02d_%s.svg\n' "$dir" "$slug" $((last + 1)) "$(date +%Y%m%d-%H%M)"
}

cmd_diagramas() {
  local dir
  for dir in $DIAGRAM_DIRS; do
    title "$dir"
    if [ ! -d "$dir" ]; then
      warn "Pasta não existe — rode ./boaz.sh init"
      continue
    fi
    list_versions "$dir" \
      | sort -k1,1 -k2,2n \
      | awk '{ last[$1] = $3; count[$1]++ } END { for (s in last) printf "%s\t%d\n", last[s], count[s] }' \
      | sort \
      | while IFS="$(printf '\t')" read -r file n; do
          echo "  ${G}●${NC} ${file}  ${D}(${n} versão(ões))${NC}"
        done
    [ -n "$(list_versions "$dir")" ] || info "Nenhum diagrama ainda."
  done
}

# ── REQUISITOS ───────────────────────────────────────────────
# Valor de <meta name="boaz:$2" content="..."> no documento $1
req_meta() {
  sed -n "s/.*<meta name=\"boaz:$2\" content=\"\([^\"]*\)\".*/\1/p" "$1" | head -1 \
    | sed 's/&quot;/"/g; s/&lt;/</g; s/&gt;/>/g; s/&amp;/\&/g'
}

# Versão da casca embutida no documento (ou no tema)
req_theme_version() {
  grep -m1 -oE 'tema dos documentos de requisito · v[0-9]+' "$1" 2>/dev/null | sed 's/.* · //'
}

# Lista os documentos de 1_Requisitos com versão, data e status lidos da marca d'água
cmd_requisitos() {
  title "$REQ_DIR"
  [ -d "$REQ_DIR" ] || fail "Pasta não existe — rode ./boaz.sh init"
  local f n=0 tema ver extra
  tema=$(req_theme_version "$REQ_THEME")
  for f in "$REQ_DIR"/*.html; do
    [ -e "$f" ] || continue
    n=$((n + 1))
    if [ -z "$(req_meta "$f" versao)" ]; then
      echo "  ${Y}●${NC} $(basename "$f")  ${D}(sem marca d'água boaz)${NC}"
      continue
    fi
    ver=$(req_theme_version "$f")
    extra=""
    [ -z "$tema" ] || [ "$ver" = "$tema" ] || extra="  ${Y}tema ${ver:-?} → ${tema}${NC}"
    printf "  %s●%s %-38s %-5s %s%s · %s%s%s\n" "$G" "$NC" "$(basename "$f")" \
      "$(req_meta "$f" versao)" "$D" "$(req_meta "$f" data)" "$(req_meta "$f" status)" "$NC" "$extra"
  done
  # Documentos .md da versão anterior do boaz
  for f in "$REQ_DIR"/*.md; do
    [ -e "$f" ] || continue
    [ "$(basename "$f")" != "README.md" ] || continue
    n=$((n + 1))
    echo "  ${Y}●${NC} $(basename "$f")  ${D}(.md legado — migre com /requisito-estilo)${NC}"
  done
  [ "$n" -gt 0 ] || info "Nenhum documento ainda."
}

# Primeiro navegador Chromium encontrado (Chrome, Chromium, Edge, Brave), ou $BOAZ_CHROME
find_chrome() {
  local c
  for c in "${BOAZ_CHROME:-}" google-chrome google-chrome-stable chromium chromium-browser microsoft-edge brave-browser \
           "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
           "/Applications/Chromium.app/Contents/MacOS/Chromium" \
           "/Applications/Microsoft Edge.app/Contents/MacOS/Microsoft Edge" \
           "/Applications/Brave Browser.app/Contents/MacOS/Brave Browser"; do
    [ -n "$c" ] || continue
    if [ -x "$c" ]; then echo "$c"; return; fi
    if command -v "$c" &>/dev/null; then command -v "$c"; return; fi
  done
}

# Exporta um documento para 1_Requisitos/pdf/<documento>_v<NN>_<AAAAMMDD-HHMM>.pdf
pdf_one() {
  local f=$1 chrome=$2 doc ver data out
  doc=$(basename "$f" .html)
  ver=$(req_meta "$f" versao)
  data=$(req_meta "$f" data)
  [ -n "$ver" ] && [ -n "$data" ] || { warn "$(basename "$f"): sem marca d'água boaz (meta versao/data) — ignorado"; return 1; }
  out="$REQ_DIR/pdf/${doc}_${ver}_$(echo "$data" | tr -d ':-' | tr ' ' '-').pdf"
  mkdir -p "$REQ_DIR/pdf"
  rm -f "$out"
  "$chrome" --headless --disable-gpu --no-pdf-header-footer --virtual-time-budget=8000 \
    --print-to-pdf="$PWD/$out" "file://$PWD/$f" &>/dev/null || true
  if [ -s "$out" ]; then
    success "PDF: ${D}${out}${NC}"
  else
    warn "Falha ao gerar o PDF de $(basename "$f")"
    return 1
  fi
}

cmd_pdf() {
  [ $# -eq 1 ] || fail "Uso: ./boaz.sh pdf <documento|todos>   ex.: ./boaz.sh pdf 02_cadastro-usuario"
  local chrome f arg=${1%.html} falhas=0
  chrome=$(find_chrome)
  [ -n "$chrome" ] || fail "Chrome, Chromium, Edge ou Brave não encontrado (defina BOAZ_CHROME). Alternativa: abra o .html e use o botão PDF."
  title "PDF → $REQ_DIR/pdf"
  if [ "$arg" = "todos" ]; then
    for f in "$REQ_DIR"/*.html; do
      [ -e "$f" ] || continue
      pdf_one "$f" "$chrome" || falhas=$((falhas + 1))
    done
  else
    arg=${arg#"$REQ_DIR"/}
    if [ -f "$REQ_DIR/$arg.html" ]; then
      f="$REQ_DIR/$arg.html"
    else
      # aceita só o número (02) ou só o nome (cadastro-usuario)
      f=$(ls "$REQ_DIR"/*.html 2>/dev/null | grep -E "/(${arg}_[^/]*|[0-9]{2}_${arg})\.html$" | head -1 || true)
    fi
    [ -n "$f" ] && [ -f "$f" ] || fail "Documento não encontrado: $1 (veja ./boaz.sh requisitos)"
    pdf_one "$f" "$chrome" || falhas=1
  fi
  [ "$falhas" -eq 0 ] || exit 1
}

# ── STATUS ───────────────────────────────────────────────────
cmd_status() {
  load_config
  title "Projeto [${PROJECT_NAME:-sem nome}]"
  local d
  for d in 0_Assets 1_Requisitos 2_Diagramas 3_Arquitetura 4_CI_CD 5_DEV; do
    if [ -d "$d" ]; then
      local n
      n=$(find "$d" -type f ! -name .gitkeep ! -name README.md | wc -l | tr -d ' ')
      echo "  ${G}✔${NC}  ${W}${d}/${NC}  ${D}(${n} arquivos)${NC}"
    else
      echo "  ${R}✖${NC}  ${W}${d}/${NC}  ${R}não encontrado${NC}"
    fi
  done
}

cmd_help() {
  cat << EOF

  ${W}Uso:${NC} ./boaz.sh [comando]

  ${C}init [nome]${NC}               Monta/completa a estrutura e (re)gera as skills
  ${C}status${NC}                    Mostra as pastas do projeto
  ${C}requisitos${NC}                Lista os documentos de requisito com versão, data e status
  ${C}pdf <documento|todos>${NC}     Exporta o requisito para 1_Requisitos/pdf/<documento>_v<NN>_<data>.pdf
  ${C}diagramas${NC}                 Lista a versão mais recente de cada diagrama
  ${C}svg <pasta> <legenda>${NC}     Imprime o próximo nome versionado de um diagrama
                            ex.: ./boaz.sh svg 2_Diagramas "Fluxo de cadastro"
  ${C}help${NC}                      Esta ajuda

  Sem comando: ${W}init${NC} na primeira execução, ${W}status${NC} nas seguintes.

EOF
}

# ── ENTRY POINT ──────────────────────────────────────────────
cmd=${1:-}
[ $# -gt 0 ] && shift

case "$cmd" in
  "")
    banner
    if [ -f "$CONFIG_FILE" ]; then cmd_status; cmd_help; else cmd_init; fi
    ;;
  init)      banner; cmd_init "$@" ;;
  status)    cmd_status ;;
  requisitos) cmd_requisitos ;;
  pdf)       cmd_pdf "$@" ;;
  diagramas) cmd_diagramas ;;
  svg)       cmd_svg "$@" ;;
  help|-h|--help) cmd_help ;;
  *)         warn "Comando desconhecido: $cmd"; cmd_help; exit 1 ;;
esac
