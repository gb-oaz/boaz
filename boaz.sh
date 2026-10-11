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
  install_diagram_assets
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
- Nomes em kebab-case, sem acentos: `funcao-serverless.svg`, `logo-principal.svg`.
- `diagramas/icones/` traz os ícones oficiais de AWS, GCP e Azure (instalados pelo
  `./boaz.sh init`, veja o README da pasta). Use-os só quando a arquitetura for
  de um provedor específico; por padrão ela é neutra e vale para Azure, AWS e GCP.
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

# ── ASSETS DOS DIAGRAMAS ─────────────────────────────────────
# Copia de assets/ do boaz, sem sobrescrever (o projeto pode customizar o tema e adicionar ícones):
#   tema.svg  → 0_Assets/diagramas/tema.svg   (estilo + catálogo de formas e notação)
#   icones/   → 0_Assets/diagramas/icones/
# Usa a cópia local (clone do boaz) se existir; senão baixa do GitHub.
install_diagram_assets() {
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
    warn "Tema e ícones dos diagramas não baixados (sem rede?) — rode ./boaz.sh init de novo depois."
    [ -z "$tmp" ] || rm -rf "$tmp"
    return
  fi
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
1. Leia os `.md` relevantes de `1_Requisitos/` e rode `./boaz.sh diagramas` para reaproveitar nomes e evitar duplicatas.
2. Se a ambiguidade mudar o desenho, faça no máximo 1–2 perguntas; caso contrário, assuma e declare as premissas na resposta.
3. Escolha a legenda, gere o caminho e escreva o SVG.

**Alteração** ("muda", "adiciona", "corrige" num diagrama existente)
1. Identifique a legenda e abra a **maior versão** (`ls __PASTA__/<legenda>_v*`).
2. Aplique só a mudança pedida, preservando layout, ids e o restante do desenho.
3. Salve como a próxima versão (`./boaz.sh svg __PASTA__ <legenda>`).
4. Rode `grep -rn "<legenda>_v" 1_Requisitos` e, se houver referências à versão anterior, pergunte se devem apontar para a nova. Não altere sem confirmação.

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

**Tema padrão (modo dark).** `0_Assets/diagramas/tema.svg` é o estilo e o catálogo visual: cores por papel, tipografia, tipos de comunicação, formas neutras de arquitetura, exemplo de arquitetura, ícones por provedor e um cartão por tipo de diagrama UML com os elementos que ele usa. Abra-o (`grep -n 'id="' 0_Assets/diagramas/tema.svg` lista seções e símbolos) e:
- copie **sem alterar** o bloco `<style>` e, de `<defs>`, todos os `<marker>` e o filtro `sombra`;
- dos `<symbol>`, copie **só os que usar**: `#ic-*` (formas neutras de arquitetura — banco, fila, função, gateway…), `#uml-*` (ator, ícone de componente, artefato), `#prov-*` (ícones oficiais de exemplo);
- use o cartão do tipo de diagrama (seção 6, `<g id="uml-...">`, `er`, `c4`) como referência de composição.
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
