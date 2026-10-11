# 🏗️ boaz

> Monorepo Structure Manager — da ideia ao código, uma pasta por etapa.

---

## Repositório

| | |
|---|---|
| 🌐 GitHub | [github.com/gb-oaz/boaz](https://github.com/gb-oaz/boaz) |
| 🔐 Clone SSH | `git@github.com:gb-oaz/boaz.git` |
| 🔗 Clone HTTPS | `https://github.com/gb-oaz/boaz.git` |

---

## O que é o boaz?

O `boaz` monta a estrutura de pastas de um projeto seguindo uma metodologia simples, **sem escolher tecnologia**: do requisito do produto até o código, cada etapa tem a sua pasta.

Também instala quatro prompts especializados (skills do Claude Code): dois cuidam dos **documentos de requisito** — conteúdo e estilização — em `.html` com tema claro, sistema e escuro e exportação para PDF, e dois desenham diagramas que **sempre** entregam um `.svg` versionado — pronto para ser referenciado nos requisitos.

---

## Como usar

```bash
curl -fsSL https://raw.githubusercontent.com/gb-oaz/boaz/main/boaz.sh -o boaz.sh
chmod +x boaz.sh
./boaz.sh init "Nome do Projeto"
```

O nome fica salvo em `.boaz`. Rodar `./boaz.sh init` de novo só cria o que estiver faltando (nunca sobrescreve seus arquivos) e atualiza as skills.

| Comando | O que faz |
|---|---|
| `./boaz.sh init [nome]` | Monta/completa a estrutura e (re)gera as skills |
| `./boaz.sh status` | Mostra as pastas e quantos arquivos cada uma tem |
| `./boaz.sh requisitos` | Lista os documentos de requisito com versão, data e status |
| `./boaz.sh pdf <documento\|todos>` | Exporta o requisito para `1_Requisitos/pdf/<documento>_v<NN>_<AAAAMMDD-HHMM>.pdf` |
| `./boaz.sh diagramas` | Lista a versão mais recente de cada diagrama |
| `./boaz.sh svg <pasta> <legenda>` | Imprime o próximo nome versionado de um diagrama |

---

## Estrutura

```
projeto/
├── 0_Assets/
│   ├── projeto/         # Marca, logos, imagens, fontes
│   ├── requisitos/      # tema.html (padrão, estilo e catálogo dos documentos de requisito)
│   └── diagramas/       # tema.svg (estilo + catálogo visual), ícones de tecnologias
│       └── icones/      # ícones oficiais AWS, GCP e Azure (.svg), instalados pelo init
├── 1_Requisitos/        # O produto desejado (.html) — sem backend, frontend ou tecnologia
│   └── pdf/             # PDFs exportados, um por versão
├── 2_Diagramas/         # Diagramas de desenvolvimento, backend e frontend (.svg)
├── 3_Arquitetura/       # Alto nível: cloud, tecnologias, integrações (.svg)
├── 4_CI_CD/             # Estruturas de entrega
├── 5_DEV/
│   ├── backend/
│   ├── frontend/
│   └── qa/
│       ├── backend/
│       └── frontend/
├── .claude/skills/
│   ├── requisito/             # prompt especializado → 1_Requisitos (conteúdo e PDF)
│   ├── requisito-estilo/      # prompt especializado → tema.html (visual, migração .md, PDF)
│   ├── diagrama-dev/          # prompt especializado → 2_Diagramas
│   └── diagrama-arquitetura/  # prompt especializado → 3_Arquitetura
├── CLAUDE.md            # Resumo da metodologia para o Claude Code
└── .boaz                # Nome do projeto
```

---

## Documentos de requisito

No Claude Code, peça o documento pela skill:

```
/requisito funcionalidade de cadastro de usuário com confirmação por e-mail
/requisito no 02_cadastro-usuario, adicione limite de 5 tentativas de login
/requisito aprove o 00_visao-produto e gere o pdf
/requisito-estilo troque o acento azul por verde-petróleo e aplique nos documentos
/requisito-estilo migre os requisitos .md para .html
```

Cada documento é um `.html` **autocontido** em `1_Requisitos/<NN>_<nome>.html`: abra no navegador e use os botões do canto para alternar entre os temas **claro**, **sistema** e **escuro** (o escuro é a paleta do `tema.svg`) ou gerar o **PDF**.

Todos seguem [`assets/tema.html`](assets/tema.html), instalado em `0_Assets/requisitos/tema.html`. Ele é, ao mesmo tempo, a regra, o **catálogo renderizado** de componentes (com o HTML de cada um em *Ver HTML*) e a fonte da **casca** — o bloco de fontes, CSS e script que cada documento embute:

1. **marca d'água** — `<meta boaz:*>` (projeto, documento, caminho, tipo, versão, data, status); faixa de topo com sobretítulo, título, objetivo e carimbo (documento, versão, data/hora, status); rodapé com o histórico de versões e a identificação do arquivo; marca diagonal para `Rascunho`, `Em revisão` e `Obsoleto`;
2. **visual** — tipografia Inter + JetBrains Mono, cores por papel, temas claro/sistema/escuro e impressão A4 sempre clara;
3. **formato** — nome `<NN>_<nome>.html`, esqueleto fixo de seções e limites de tamanho (≤ 12 requisitos, ≤ 4 páginas A4);
4. **escrita** — "O sistema deve…", uma obrigação por frase, requisito não funcional sempre mensurável, lista de palavras vagas proibidas;
5. **catálogo de componentes** — requisitos funcionais e não funcionais, regras de negócio, prioridade MoSCoW, critérios de aceite em Gherkin (coloridos automaticamente), história de usuário, personas, métricas, escopo, em aberto, destaques, glossário, referências entre documentos (`02_cadastro-usuario.html#RF-01`) e **diagramas** `.svg` de `2_Diagramas/` e `3_Arquitetura/` (inteiros ou recortados);
6. **tipos de documento** — visão do produto (`00`), funcionalidade (`01`–`89`), transversal (`90`–`98`) e glossário (`99`).

```html
<header class="boaz-marca-topo">
  <p class="boaz-eyebrow">Loja X · Funcionalidade</p>
  <h1>Cadastro de usuário</h1>
  <p class="boaz-objetivo"><span>Objetivo</span>definir como uma pessoa cria a conta e prova que o e-mail é dela.</p>
  <dl class="boaz-carimbo">
    <div><dt>Documento</dt><dd>02_cadastro-usuario</dd></div>
    <div><dt>Versão</dt><dd><span class="boaz-versao">v03</span></dd></div>
    <div><dt>Data</dt><dd class="boaz-data">2026-10-11 · 14:30</dd></div>
    <div><dt>Status</dt><dd><span class="status status-em-revisao">Em revisão</span></dd></div>
  </dl>
</header>
```

Diferente dos diagramas, o documento é **editado no lugar** (os links continuam válidos e o git guarda o conteúdo antigo): cada alteração soma 1 na versão, atualiza data/hora e ganha uma linha no histórico. Se versão e data divergirem entre `<meta>`, carimbo, histórico e rodapé, o botão de PDF fica vermelho. IDs (`RF-01`, `RNF-01`, `RN-01`) são únicos no projeto e nunca reaproveitados. O que o pedido não define não é inventado — vai para a seção **Em aberto**.

### PDF versionado

```bash
./boaz.sh pdf 02_cadastro-usuario   # → 1_Requisitos/pdf/02_cadastro-usuario_v03_20261011-1430.pdf
./boaz.sh pdf todos
```

Versão e data vêm da marca d'água do documento, então a mesma versão gera sempre o mesmo nome. O PDF sai em A4, tema claro, com a faixa de topo na primeira página, o histórico no fim e, em toda página, cabeçalho (`projeto · documento` / `versão · data · status`) e rodapé (caminho e `Página N de M`). Usa o Chrome, Chromium, Edge ou Brave instalado (ou `BOAZ_CHROME`); sem eles, o botão **PDF** do documento abre a impressão com o nome já versionado.

### Estilo

Para mudar o visual, use `/requisito-estilo`: ele edita o `tema.html` do projeto (tokens nos temas claro, escuro e de impressão; componentes novos entram no catálogo), sobe a versão do tema e, com sua confirmação, aplica a casca nova aos documentos — cada um ganha versão. `./boaz.sh requisitos` aponta documentos num tema anterior e `.md` antigos a migrar. Para receber uma versão nova do tema do boaz, apague `0_Assets/requisitos/tema.html` e rode `./boaz.sh init`.

---

## Diagramas versionados

No Claude Code, peça o diagrama pela skill:

```
/diagrama-dev diagrama de sequência do cadastro de usuário
/diagrama-arquitetura visão de contêineres em cloud com fila de pagamentos
/diagrama-dev no fluxo-cadastro, adicione a validação de e-mail
```

Cada pedido — criação ou alteração — gera um **arquivo novo**; nenhuma versão é sobrescrita:

```
<legenda>_v<NN>_<AAAAMMDD-HHMM>.svg

2_Diagramas/fluxo-cadastro_v01_20261010-1430.svg
2_Diagramas/fluxo-cadastro_v02_20261011-0915.svg
```

- **legenda** — identifica o diagrama, em kebab-case, e não muda entre versões
- **v\<NN\>** — versão, começa em `01`
- **timestamp** — quando aquela versão foi gerada

Todo SVG traz uma **marca d'água** que o identifica como parte da documentação:

- **topo** — projeto e tipo de diagrama, nome do diagrama, e um carimbo com a **versão** e a **data** daquela versão;
- **rodapé** — a **legenda** (as cores e os tipos de seta usados no desenho), o que mudou na versão e o nome do arquivo.

O histórico de mudanças fica também em `<desc>`.

Nos requisitos, referencie a versão exata:

```html
<figure class="diagrama">
  <a href="../2_Diagramas/fluxo-cadastro_v02_20261011-0915.svg"><img src="../2_Diagramas/fluxo-cadastro_v02_20261011-0915.svg" alt="Fluxo de cadastro"></a>
  <figcaption><strong>Fluxo de cadastro</strong><code>2_Diagramas/fluxo-cadastro_v02_20261011-0915.svg</code></figcaption>
</figure>
```

Ao gerar uma nova versão, a skill avisa quais documentos de `1_Requisitos/` apontam para a anterior e pergunta se deve atualizá-los.

### Tipos de diagrama

As skills conhecem os 14 diagramas da UML 2.5 e escolhem o tipo pela pergunta, quando o pedido não diz qual:

| Skill | Estruturais | Comportamentais | Outros |
|---|---|---|---|
| `/diagrama-dev` → `2_Diagramas/` | classes, objetos, pacotes, componentes, estrutura composta, perfil | casos de uso, atividades, sequência, comunicação, visão geral de interação, estados, tempo | ER, navegação de telas, contrato de API |
| `/diagrama-arquitetura` → `3_Arquitetura/` | implantação, componentes no nível de serviço | — | C4 contexto e contêiner |

### Visual e assets

- Todos os diagramas usam o mesmo **tema dark** de [`assets/tema.svg`](assets/tema.svg), instalado em `0_Assets/diagramas/tema.svg`. Além do estilo, ele é um **catálogo visual** do que os diagramas podem usar:
  1. cores por papel e tipografia;
  2. tipos de comunicação (síncrono, retorno, evento, stream, dados/lote) e chips de protocolo;
  3. 24 formas neutras de arquitetura (`#ic-*`: banco, fila, função, gateway, CDN, cofre…);
  4. um exemplo de arquitetura neutra com fronteiras conta → rede → sub-rede;
  5. a correspondência neutro → AWS / Azure / GCP com os ícones oficiais;
  6. um cartão por tipo de diagrama UML (os 14, mais ER e C4) com os elementos que ele usa.
  7. um exemplo da marca d'água de topo e rodapé, com cada parte anotada.

  As skills copiam o `<style>`, os markers, o gradiente da marca d'água e só os `<symbol>` que usarem, e estilizam por classes CSS. Edite o tema do projeto para mudar o visual dos próximos diagramas; para receber uma versão nova do boaz, apague `0_Assets/diagramas/tema.svg` e rode `./boaz.sh init`.

  No repositório do boaz, o tema é gerado por [`scripts/gerar-tema.py`](scripts/gerar-tema.py): edite o script e rode `python3 scripts/gerar-tema.py` para atualizar `assets/tema.svg`.
- O `init` instala em `0_Assets/diagramas/icones/` os ícones oficiais de **AWS** (pacote de 07/2025: serviços, recursos, grupos e categorias) **GCP** (produtos, categorias e o conjunto legado) e **Azure** (Public Service Icons V24, por categoria) — ~1.800 `.svg` versionados em [`assets/icones/`](assets/icones). Tema e ícones: só copia o que falta, então customizações suas nunca são sobrescritas. Sem rede, o init avisa e segue; rode de novo depois.
- Coloque em `0_Assets/diagramas/` outros ícones de tecnologias e logos de integrações (de preferência `.svg`). Os diagramas de arquitetura são **neutros de provedor** (valem para Azure, AWS e GCP): usam categorias como *função serverless* ou *armazenamento de objetos*, nunca nomes de produto de um só provedor — os ícones de AWS/GCP/Azure só entram quando o pedido fixa o provedor. No diagrama neutro, as caixas usam as formas `#ic-*` do tema. As skills procuram em `0_Assets/` antes de desenhar e **embutem** o asset no SVG, que continua autocontido e renderiza no GitHub.
- Antes de entregar, a skill valida o XML e, se houver `rsvg-convert`/`qlmanage`, renderiza uma prévia para corrigir sobreposições e desalinhamentos.

---

## Requisitos

- `bash` 3.2+
- `curl` ou `wget`
- [Claude Code](https://claude.com/claude-code) para as skills
- Chrome, Chromium, Edge ou Brave para `./boaz.sh pdf` (opcional)

---

## Licença

MIT