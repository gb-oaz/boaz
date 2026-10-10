#!/usr/bin/env bash
# ============================================================
#  boaz.sh — Monorepo Structure Manager
#  Uso: chmod +x boaz.sh && ./boaz.sh [comando]
# ============================================================

set -euo pipefail

CONFIG_FILE=".boaz"
DIAGRAM_DIRS="2_Diagramas 3_Arquitetura"
LEAF_DIRS="0_Assets/projeto 0_Assets/diagramas 1_Requisitos 2_Diagramas 3_Arquitetura 4_CI_CD
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
  create_requirements_template
  create_diagram_theme
  create_diagram_skills

  # Mantém no git as pastas que ainda estão vazias
  for leaf in $LEAF_DIRS; do
    [ -n "$(ls -A "$leaf")" ] || touch "$leaf/.gitkeep"
  done

  echo ""
  success "Projeto ${C}${PROJECT_NAME}${NC} pronto."
  info "Diagramas: no Claude Code use ${W}/diagrama-dev${NC} ou ${W}/diagrama-arquitetura${NC}."
}

create_readmes() {
  write_once "CLAUDE.md" << EOF
# ${PROJECT_NAME}

Monorepo organizado pelo boaz. Cada pasta tem uma única responsabilidade:

| Pasta | Conteúdo | Formato |
|---|---|---|
| \`0_Assets/\` | Recursos reutilizáveis: \`projeto/\` (marca, imagens, fontes) e \`diagramas/\` (tema, ícones, logos) | livre |
| \`1_Requisitos/\` | O produto desejado — sem backend, frontend ou tecnologia | \`.md\` |
| \`2_Diagramas/\` | Diagramas de desenvolvimento (backend e frontend) | \`.svg\` versionado |
| \`3_Arquitetura/\` | Diagramas de alto nível: cloud, tecnologias, integrações | \`.svg\` versionado |
| \`4_CI_CD/\` | Estruturas de entrega (pipelines, deploy) | livre |
| \`5_DEV/\` | Código: \`backend/\`, \`frontend/\`, \`qa/backend/\`, \`qa/frontend/\` | livre |

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
└── diagramas/    # tema.svg (estilo padrão), ícones de cloud/tecnologias, logos de integrações
```

- Prefira `.svg`; raster (`.png`, `.jpg`, `.webp`) só quando não houver vetor.
- Nomes em kebab-case, sem acentos: `aws-lambda.svg`, `logo-principal.svg`.
- As skills de diagrama procuram aqui antes de desenhar e **embutem** o asset no SVG
  gerado (o diagrama continua autocontido e renderiza em qualquer lugar).
- `diagramas/tema.svg` define o visual de todos os diagramas: edite-o para mudar
  cores e tipografia dos próximos diagramas (os antigos não mudam).
EOF

  write_once "1_Requisitos/README.md" << 'EOF'
# 1_Requisitos

Requisitos do **produto**: o que ele faz, para quem e com quais regras.
Aqui não se fala de backend, frontend ou tecnologia.

- Arquivos em `.md`.
- Para ilustrar, referencie um diagrama **com a versão explícita**:
  `![Fluxo de cadastro](../2_Diagramas/fluxo-cadastro_v02_20261010-1430.svg)`
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

create_requirements_template() {
  write_once "1_Requisitos/requisitos.md" << EOF
# Requisitos — ${PROJECT_NAME}

> Documento de produto: o que deve existir e por quê. Sem decisões de tecnologia.

## 1. Visão

## 2. Usuários / Personas

## 3. Requisitos funcionais

| ID | Requisito | Prioridade |
|---|---|---|
| RF-01 | | |

## 4. Requisitos não funcionais

| ID | Requisito |
|---|---|
| RNF-01 | |

## 5. Regras de negócio

## 6. Fora de escopo

## 7. Diagramas

<!-- Referencie sempre com a versão explícita, ex.:
![Fluxo de cadastro](../2_Diagramas/fluxo-cadastro_v01_20261010-1430.svg)
-->
EOF
}

# ── TEMA DOS DIAGRAMAS ───────────────────────────────────────
# Referência visual + fonte única do <style>/<defs> copiados para cada diagrama.
# write_once: o projeto pode customizar o tema sem perder ao rodar init de novo.
create_diagram_theme() {
  write_once "0_Assets/diagramas/tema.svg" << 'EOF'
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 960 736" width="960" height="736">
  <title>Tema dos diagramas</title>
  <desc>Tema dark padrão do boaz. As skills de diagrama copiam o bloco style e o bloco defs deste arquivo, sem alterações, para cada SVG gerado. v01: criação.</desc>
  <style>
    /* ── base ─────────────────────────────────────────── */
    .bg            { fill: #0d1117; }
    text           { font-family: Inter, "Segoe UI", Roboto, "Helvetica Neue", Helvetica, Arial, sans-serif; font-size: 13px; fill: #e6edf3; }
    .title         { font-size: 22px; font-weight: 700; fill: #f0f6fc; }
    .subtitle      { font-size: 13px; fill: #8b949e; }
    .label         { font-size: 13px; fill: #e6edf3; }
    .label-strong  { font-size: 14px; font-weight: 600; fill: #f0f6fc; }
    .muted         { font-size: 12px; fill: #8b949e; }
    .mono          { font-family: "JetBrains Mono", "SF Mono", Menlo, Consolas, monospace; font-size: 12px; fill: #8b949e; }
    .divider       { stroke: #21262d; stroke-width: 1; }

    /* ── nós: uma cor por papel, no máximo 4 por diagrama ── */
    .node          { fill: #161b22; stroke: #30363d; stroke-width: 1.5; }
    .node-blue     { fill: #0c2d4a; stroke: #58a6ff; stroke-width: 1.5; }
    .node-green    { fill: #0f2e1b; stroke: #3fb950; stroke-width: 1.5; }
    .node-purple   { fill: #271a45; stroke: #bc8cff; stroke-width: 1.5; }
    .node-orange   { fill: #3a2410; stroke: #f0883e; stroke-width: 1.5; }
    .node-red      { fill: #3b1219; stroke: #f85149; stroke-width: 1.5; }
    .node-external { fill: #1c2128; stroke: #6e7681; stroke-width: 1.5; }

    /* ── fronteiras (conta, região, VPC, módulo) ───────── */
    .boundary       { fill: #161b22; fill-opacity: 0.35; stroke: #484f58; stroke-width: 1.2; stroke-dasharray: 6 4; }
    .boundary-label { font-size: 11px; font-weight: 600; letter-spacing: 0.08em; fill: #8b949e; }

    /* ── arestas ──────────────────────────────────────── */
    .edge          { fill: none; stroke: #8b949e; stroke-width: 1.5; }
    .edge-accent   { fill: none; stroke: #58a6ff; stroke-width: 1.8; }
    .edge-async    { stroke-dasharray: 6 4; }
    .edge-label-bg { fill: #0d1117; }
    .arrow-head    { fill: #8b949e; }
    .arrow-accent  { fill: #58a6ff; }
    .lifeline      { stroke: #30363d; stroke-width: 1.2; stroke-dasharray: 4 4; }

    /* ── notação UML ───────────────────────────────────── */
    .ink           { fill: #e6edf3; }
    .ink-ring      { fill: none; stroke: #e6edf3; stroke-width: 1.5; }
    .node-note     { fill: #2b2311; stroke: #d29922; stroke-width: 1.2; }
    .uml-keyword   { font-size: 11px; font-style: italic; fill: #8b949e; }
    .arrow-open    { fill: none; stroke: #8b949e; stroke-width: 1.4; stroke-linejoin: round; }
    .arrow-hollow  { fill: #0d1117; stroke: #8b949e; stroke-width: 1.2; stroke-linejoin: round; }

    /* ── legenda e rodapé ─────────────────────────────── */
    .legend-box    { fill: #161b22; stroke: #30363d; stroke-width: 1; }
    .footer        { font-size: 12px; fill: #6e7681; }
  </style>
  <defs>
    <marker id="seta" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" class="arrow-head"/>
    </marker>
    <marker id="seta-destaque" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="7" markerHeight="7" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10 z" class="arrow-accent"/>
    </marker>
    <marker id="seta-aberta" viewBox="-1 -1 12 12" refX="10" refY="5" markerWidth="8" markerHeight="8" orient="auto-start-reverse">
      <path d="M0,0 L10,5 L0,10" class="arrow-open"/>
    </marker>
    <marker id="heranca" viewBox="-1 -1 14 14" refX="12" refY="6" markerWidth="10" markerHeight="10" orient="auto-start-reverse">
      <path d="M0,0 L12,6 L0,12 z" class="arrow-hollow"/>
    </marker>
    <marker id="composicao" viewBox="-1 -1 16 10" refX="14" refY="4" markerWidth="16" markerHeight="11" orient="auto-start-reverse">
      <path d="M0,4 L7,0 L14,4 L7,8 z" class="arrow-head"/>
    </marker>
    <marker id="agregacao" viewBox="-1 -1 16 10" refX="14" refY="4" markerWidth="16" markerHeight="11" orient="auto-start-reverse">
      <path d="M0,4 L7,0 L14,4 L7,8 z" class="arrow-hollow"/>
    </marker>
    <filter id="sombra" x="-10%" y="-10%" width="120%" height="140%">
      <feDropShadow dx="0" dy="3" stdDeviation="4" flood-color="#000000" flood-opacity="0.45"/>
    </filter>
  </defs>

  <rect class="bg" x="0" y="0" width="960" height="736"/>

  <g id="cabecalho">
    <text class="title" x="40" y="56">Tema dos diagramas</text>
    <text class="subtitle" x="40" y="80">Referência visual do boaz — copie os blocos style e defs para cada novo SVG</text>
    <line class="divider" x1="40" y1="100" x2="920" y2="100"/>
  </g>

  <g id="fronteira">
    <rect class="boundary" x="40" y="130" width="600" height="320" rx="14"/>
    <text class="boundary-label" x="58" y="154">FRONTEIRA · CONTEXTO / VPC</text>
  </g>

  <g id="servico-principal" filter="url(#sombra)">
    <rect class="node-blue" x="72" y="180" width="200" height="84" rx="10"/>
    <text class="label-strong" x="172" y="216" text-anchor="middle">Serviço principal</text>
    <text class="mono" x="172" y="240" text-anchor="middle">[tecnologia]</text>
  </g>

  <g id="banco-de-dados" filter="url(#sombra)">
    <rect class="node-green" x="400" y="180" width="200" height="84" rx="10"/>
    <text class="label-strong" x="500" y="216" text-anchor="middle">Dados</text>
    <text class="mono" x="500" y="240" text-anchor="middle">[PostgreSQL]</text>
  </g>

  <g id="fila" filter="url(#sombra)">
    <rect class="node-purple" x="72" y="340" width="200" height="84" rx="10"/>
    <text class="label-strong" x="172" y="376" text-anchor="middle">Mensageria</text>
    <text class="mono" x="172" y="400" text-anchor="middle">[fila · AMQP]</text>
  </g>

  <g id="regra" filter="url(#sombra)">
    <rect class="node-orange" x="400" y="340" width="200" height="84" rx="10"/>
    <text class="label-strong" x="500" y="376" text-anchor="middle">Atenção / regra</text>
    <text class="mono" x="500" y="400" text-anchor="middle">[validação]</text>
  </g>

  <g id="sistema-externo" filter="url(#sombra)">
    <rect class="node-external" x="700" y="180" width="220" height="84" rx="10"/>
    <text class="label-strong" x="810" y="216" text-anchor="middle">Sistema externo</text>
    <text class="mono" x="810" y="240" text-anchor="middle">[API de terceiros]</text>
  </g>

  <g id="arestas">
    <line class="edge-accent" x1="272" y1="222" x2="398" y2="222" marker-end="url(#seta-destaque)"/>
    <text class="muted" x="335" y="210" text-anchor="middle">consulta · SQL</text>

    <line class="edge edge-async" x1="172" y1="264" x2="172" y2="338" marker-end="url(#seta)"/>
    <text class="muted" x="184" y="306">evento</text>

    <line class="edge" x1="272" y1="382" x2="398" y2="382" marker-end="url(#seta)"/>
    <text class="muted" x="335" y="370" text-anchor="middle">valida</text>

    <line class="edge" x1="600" y1="222" x2="698" y2="222" marker-end="url(#seta)"/>
    <text class="muted" x="649" y="210" text-anchor="middle">HTTPS</text>
  </g>

  <g id="legenda">
    <rect class="legend-box" x="700" y="300" width="220" height="150" rx="10"/>
    <text class="label-strong" x="716" y="326">Legenda</text>
    <rect class="node-blue" x="716" y="340" width="14" height="14" rx="3"/>
    <text class="label" x="740" y="352">Componente do projeto</text>
    <rect class="node-green" x="716" y="362" width="14" height="14" rx="3"/>
    <text class="label" x="740" y="374">Dados</text>
    <rect class="node-purple" x="716" y="384" width="14" height="14" rx="3"/>
    <text class="label" x="740" y="396">Mensageria</text>
    <rect class="node-orange" x="716" y="406" width="14" height="14" rx="3"/>
    <text class="label" x="740" y="418">Atenção / regra</text>
    <rect class="node-external" x="716" y="428" width="14" height="14" rx="3"/>
    <text class="label" x="740" y="440">Externo</text>
  </g>

  <g id="notacao-uml">
    <text class="boundary-label" x="40" y="490">NOTAÇÃO UML</text>

    <line class="edge" x1="40" y1="520" x2="152" y2="520" marker-end="url(#seta-aberta)"/>
    <text class="muted" x="40" y="546">associação</text>
    <line class="edge" x1="188" y1="520" x2="300" y2="520" marker-end="url(#heranca)"/>
    <text class="muted" x="188" y="546">herança</text>
    <line class="edge edge-async" x1="336" y1="520" x2="448" y2="520" marker-end="url(#heranca)"/>
    <text class="muted" x="336" y="546">realização</text>
    <line class="edge edge-async" x1="484" y1="520" x2="596" y2="520" marker-end="url(#seta-aberta)"/>
    <text class="muted" x="484" y="546">dependência «use»</text>
    <line class="edge" x1="632" y1="520" x2="744" y2="520" marker-start="url(#composicao)"/>
    <text class="muted" x="632" y="546">composição</text>
    <line class="edge" x1="780" y1="520" x2="892" y2="520" marker-start="url(#agregacao)"/>
    <text class="muted" x="780" y="546">agregação</text>

    <circle class="ink" cx="56" cy="590" r="8"/>
    <text class="muted" x="40" y="634">início</text>
    <circle class="ink-ring" cx="206" cy="590" r="10"/>
    <circle class="ink" cx="206" cy="590" r="6"/>
    <text class="muted" x="188" y="634">fim</text>
    <rect class="ink" x="336" y="587" width="96" height="6" rx="2"/>
    <text class="muted" x="336" y="634">fork / join</text>
    <path class="node" d="M500,574 L516,590 L500,606 L484,590 z"/>
    <text class="muted" x="484" y="634">decisão</text>
    <path class="node-note" d="M632,570 H736 L748,582 V610 H632 z"/>
    <path class="node-note" d="M736,570 V582 H748"/>
    <text class="muted" x="644" y="595">nota</text>
    <text class="muted" x="632" y="634">nota / restrição</text>
    <rect class="node" x="780" y="566" width="140" height="48" rx="6"/>
    <text class="uml-keyword" x="850" y="584" text-anchor="middle">«interface»</text>
    <text class="label-strong" x="850" y="604" text-anchor="middle">Repositorio</text>
    <text class="muted" x="780" y="634">estereótipo</text>
  </g>

  <g id="rodape">
    <line class="divider" x1="40" y1="656" x2="920" y2="656"/>
    <text class="footer" x="40" y="684">tema · v01 · referência de estilo</text>
    <text class="footer" x="40" y="704">Fundo #0d1117 · fonte sans do sistema · cantos 10px · grade de 8px · no máximo 4 cores de papel por diagrama</text>
  </g>
</svg>
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
1. Leia os `.md` relevantes de `1_Requisitos/` e rode `./boaz.sh diagramas` para reaproveitar nomes e evitar duplicatas.
2. Se a ambiguidade mudar o desenho, faça no máximo 1–2 perguntas; caso contrário, assuma e declare as premissas na resposta.
3. Escolha a legenda, gere o caminho e escreva o SVG.

**Alteração** ("muda", "adiciona", "corrige" num diagrama existente)
1. Identifique a legenda e abra a **maior versão** (`ls __PASTA__/<legenda>_v*`).
2. Aplique só a mudança pedida, preservando layout, ids e o restante do desenho.
3. Salve como a próxima versão (`./boaz.sh svg __PASTA__ <legenda>`).
4. Rode `grep -rn "<legenda>_v" 1_Requisitos` e, se houver referências à versão anterior, pergunte se devem apontar para a nova. Não altere sem confirmação.

## Assets (`0_Assets/`)

Antes de desenhar, rode `ls -R 0_Assets` e reaproveite o que existir: ícones de cloud e tecnologias, logos de integrações e da marca.

- **Embuta sempre** — nunca referencie o arquivo por caminho (`href="../0_Assets/..."` quebra no GitHub e em visualizadores de imagem).
  - `.svg`: copie o conteúdo gráfico para um `<symbol id="asset-<nome>" viewBox="...">` em `<defs>` (com o `viewBox` do original) e desenhe com `<use href="#asset-<nome>" x=".." y=".." width=".." height=".."/>`. Remova `<script>`, `<foreignObject>`, handlers `on*` e metadados de editor; prefixe ids internos com `<nome>-` para não colidirem.
  - `.png`/`.jpg`/`.webp`: `<image href="data:image/png;base64,..."/>` gerado com `base64 < arquivo | tr -d '\n'`. Evite arquivos acima de ~200 KB.
- Ícone é apoio, não substitui o texto: a caixa continua com nome e tecnologia escritos. Tamanho uniforme (24–32px), sempre no mesmo canto da caixa.
- Faltou um ícone? Use a forma simples da notação e mencione na resposta qual asset poderia ser adicionado em `0_Assets/diagramas/`.

## Visual (obrigatório)

O diagrama precisa ser **bonito**, não só correto — algo que daria orgulho de colocar numa apresentação.

**Tema padrão (modo dark).** Abra `0_Assets/diagramas/tema.svg` e copie **sem alterar** os blocos `<style>` e `<defs>` (markers `seta`/`seta-destaque`, filtro `sombra`) para o novo SVG; acrescente em `<defs>` só os `<symbol>` de assets. Se o arquivo não existir, rode `./boaz.sh init` para recriá-lo.
- Estilize **apenas por classe** do tema (`node-blue`, `edge`, `label-strong`, `muted`...). Nada de `fill`/`stroke`/`font-*` inline nem cores fora do tema.
- Fundo: primeiro elemento `<rect class="bg">` cobrindo todo o `viewBox`.
- Cor = papel: no máximo 4 classes `node-*` coloridas por diagrama, cada uma explicada na legenda; `node-external` para o que não é do projeto, `node-red` só para erro/risco. Destaque o fluxo principal com `edge-accent` + `seta-destaque`; o resto com `edge`. Assíncrono/retorno: adicione `edge-async`.
- Notação UML com os elementos do tema: markers `seta-aberta`, `heranca`, `composicao`, `agregacao` e classes `ink`, `ink-ring`, `node-note`, `uml-keyword` (a vitrine "NOTAÇÃO UML" do `tema.svg` mostra cada um). Se o tema do projeto for antigo e não tiver algum deles, declare-o no diagrama com as mesmas cores do tema.

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
- Topo: `title` + `subtitle` (uma linha de contexto) e uma `divider`. Legenda num `legend-box` à direita ou embaixo. Rodapé após uma `divider`, em `footer`: `<legenda> · v<NN> · <AAAA-MM-DD HH:MM>` e uma linha com o que o diagrama mostra (numa alteração, o que mudou).
- Numa alteração, mantenha o tema da versão anterior, a menos que pedirem para atualizar o visual.

**Revisão antes de entregar.**
- Se houver `xmllint`, valide com `xmllint --noout <arquivo>` e corrija os erros.
- Se houver `rsvg-convert` (ou `qlmanage` no macOS), renderize um PNG temporário no scratchpad, **olhe a imagem** e corrija sobreposições, textos cortados, desalinhamentos e espaços vazios desequilibrados antes de responder.

## Resposta

Responda curto: caminho do arquivo criado, premissas assumidas (se houver) e o trecho para referenciar no requisito:

```markdown
![<Título>](../__PASTA__/<arquivo>.svg)
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
- **Objetos**: caixas com nome sublinhado `pedido1 : Pedido` (`text-decoration: underline`) e valores `campo = valor` em `mono`; vínculos sem multiplicidade. Mostra um instante concreto do diagrama de classes.
- **Pacotes**: pasta com aba (retângulo pequeno sobre o retângulo principal) e nome; elementos dentro ou listados. Dependências `edge-async` + `seta-aberta` rotuladas `«import»`/`«access»`. Evite ciclos — se existirem, destaque com `node-red`.
- **Componentes**: retângulo com `«component»` e o ícone de componente no canto superior direito (retângulo com dois pequenos retângulos na borda esquerda). Interface fornecida = pirulito (linha + círculo `ink-ring`); requerida = soquete (meio-círculo aberto). Conecte soquete ao pirulito; portas como quadrados pequenos na borda.
- **Estrutura composta**: um classificador grande cujo interior mostra as partes `nome : Tipo [mult]`, portas na borda e conectores entre partes. Colaborações em elipse tracejada.
- **Perfil**: pacote `«profile»` com estereótipos `«stereotype» Nome` estendendo metaclasses `«metaclass» Class` por seta de extensão (linha contínua + triângulo **preenchido** — declare um marker `extensao` com `arrow-head`). Liste as tagged values em `mono`.
- **Entidade-relacionamento** (não UML, mas útil): tabelas com chave (`PK`, `FK` em `mono`), cardinalidade nas pontas.

**Comportamentais**
- **Casos de uso**: fronteira do sistema (`boundary`, nome no topo), atores como bonecos de palito fora dela (cabeça `ink-ring`, corpo em `edge`, nome abaixo), casos de uso em elipses com verbo + objeto (`Cadastrar usuário`). `«include»`/`«extend»` com `edge-async` + `seta-aberta`; generalização com `heranca`. Se `1_Requisitos/` tiver IDs (`RF-01`), cite-os em `muted` dentro/abaixo da elipse.
- **Atividades**: início `ink` (círculo cheio), fim `ink-ring` + `ink` (alvo), ações em retângulos arredondados, decisão/merge em losango com guardas `[sim]`/`[não]`, fork/join em barra `ink`. Raias (swimlanes) como colunas `boundary` rotuladas no topo quando houver mais de um responsável.
- **Sequência**: participantes no topo (`:Classe` ou ator), linha de vida `lifeline`, barras de ativação estreitas sobre ela. Mensagem síncrona: linha + `seta`; assíncrona: linha + `seta-aberta`; retorno: `edge-async` + `seta-aberta`. Numere as mensagens. Fragmentos combinados (`alt`, `opt`, `loop`, `par`) como retângulos `boundary` com o operador num pentágono no canto e guardas `[condição]`.
- **Comunicação**: objetos em caixas ligados por linhas simples (vínculos); ao longo de cada vínculo, mensagens numeradas `1: criar()`, `1.1: validar()` com uma pequena seta indicando a direção.
- **Visão geral de interação**: estrutura de atividades (início, decisões, fork, fim) onde cada nó é um quadro `ref` (retângulo com rótulo `ref` no canto) apontando para outro diagrama de sequência — cite a legenda/versão do diagrama referenciado — ou uma interação inline pequena.
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

Pertence aqui a **visão de alto nível**: contexto do sistema e atores, contêineres/serviços e suas tecnologias, provedores de cloud e serviços gerenciados, rede (região, VPC, sub-redes), ambientes, topologia de deploy, filas e integrações externas.

Não pertence: detalhe interno de código (classes, objetos, pacotes, sequência entre métodos, estados, telas e demais UML de código) → skill `diagrama-dev` (`2_Diagramas/`).

## Escolha do tipo

Se o pedido nomear o tipo, use-o. Senão, escolha pela pergunta e diga na resposta qual tipo usou:

| Pergunta | Tipo |
|---|---|
| Quem usa o sistema e com quais sistemas externos ele conversa? | C4 nível 1 — contexto |
| Quais aplicações, serviços e bancos compõem o sistema e com que tecnologia? | C4 nível 2 — contêiner |
| Quais serviços/sistemas existem e quais interfaces expõem e consomem? | Componentes UML (nível de serviço) |
| Onde cada artefato roda — nós, ambientes, rede? | Implantação UML |

## Notação

- **C4 contexto/contêiner**: como descrito abaixo nas regras gerais.
- **Componentes (nível de serviço)**: cada serviço ou sistema em retângulo com `«component»` (ou `«system»`) e o ícone de componente no canto; interface fornecida = pirulito (linha + círculo `ink-ring`) rotulada com o contrato (`REST /pedidos`, `tópico pedido.criado`); requerida = soquete (meio-círculo). Conecte soquete ao pirulito.
- **Implantação UML**: nós como caixas 3D (retângulo com face superior e lateral em paralelogramos, `node`) com `«device»` ou `«executionEnvironment»` e o nome (`Cluster EKS`, `VM`, `Navegador`); nós podem conter nós. Artefatos dentro dos nós como retângulos com `«artifact»` e nome do arquivo/imagem (`api:1.4.2` em `mono`). Caminhos de comunicação como linhas entre nós rotuladas com protocolo; dependência artefato→componente com `edge-async` + `seta-aberta` `«manifest»`.
- Cada caixa: nome em negrito, tecnologia entre colchetes (`[PostgreSQL 16]`, `[AWS Lambda]`) e uma linha de responsabilidade.
- Ícones de provedores/tecnologias vêm de `0_Assets/diagramas/` (embutidos, ver **Assets**). Sem ícone, use formas simples — pessoa para ator, cilindro para banco, retângulo para serviço, retângulo com borda dupla para fila/mensageria.
- Fronteiras (conta, região, VPC, cluster, ambiente) como retângulos tracejados rotulados no canto superior esquerdo.
- Setas rotuladas com o que trafega e o protocolo (`pedidos · HTTPS/JSON`, `eventos · AMQP`).
- Sistemas externos com `node-external`, para separar do que é do projeto.
EOF
    diagram_skill_common "3_Arquitetura"
  } | write_always ".claude/skills/diagrama-arquitetura/SKILL.md"
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

  ${C}init [nome]${NC}               Monta/completa a estrutura e (re)gera as skills de diagrama
  ${C}status${NC}                    Mostra as pastas do projeto
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
  diagramas) cmd_diagramas ;;
  svg)       cmd_svg "$@" ;;
  help|-h|--help) cmd_help ;;
  *)         warn "Comando desconhecido: $cmd"; cmd_help; exit 1 ;;
esac
