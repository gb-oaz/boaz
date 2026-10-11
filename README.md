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

Também instala dois prompts especializados (skills do Claude Code) que desenham diagramas e **sempre** entregam um `.svg` versionado — pronto para ser referenciado nos requisitos.

---

## Como usar

```bash
curl -fsSL https://raw.githubusercontent.com/gb-oaz/boaz/main/boaz.sh -o boaz.sh
chmod +x boaz.sh
./boaz.sh init "Nome do Projeto"
```

O nome fica salvo em `.boaz`. Rodar `./boaz.sh init` de novo só cria o que estiver faltando (nunca sobrescreve seus arquivos) e atualiza as skills de diagrama.

| Comando | O que faz |
|---|---|
| `./boaz.sh init [nome]` | Monta/completa a estrutura e (re)gera as skills |
| `./boaz.sh status` | Mostra as pastas e quantos arquivos cada uma tem |
| `./boaz.sh diagramas` | Lista a versão mais recente de cada diagrama |
| `./boaz.sh svg <pasta> <legenda>` | Imprime o próximo nome versionado de um diagrama |

---

## Estrutura

```
projeto/
├── 0_Assets/
│   ├── projeto/         # Marca, logos, imagens, fontes
│   └── diagramas/       # tema.svg (estilo padrão), ícones de cloud/tecnologias
├── 1_Requisitos/        # O produto desejado (.md) — sem backend, frontend ou tecnologia
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
│   ├── diagrama-dev/          # prompt especializado → 2_Diagramas
│   └── diagrama-arquitetura/  # prompt especializado → 3_Arquitetura
├── CLAUDE.md            # Resumo da metodologia para o Claude Code
└── .boaz                # Nome do projeto
```

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

O próprio SVG traz a legenda, versão e data no rodapé, e o histórico de mudanças em `<desc>`.

Nos requisitos, referencie a versão exata:

```markdown
![Fluxo de cadastro](../2_Diagramas/fluxo-cadastro_v02_20261011-0915.svg)
```

Ao gerar uma nova versão, a skill avisa quais documentos de `1_Requisitos/` apontam para a anterior e pergunta se deve atualizá-los.

### Tipos de diagrama

As skills conhecem os 14 diagramas da UML 2.5 e escolhem o tipo pela pergunta, quando o pedido não diz qual:

| Skill | Estruturais | Comportamentais | Outros |
|---|---|---|---|
| `/diagrama-dev` → `2_Diagramas/` | classes, objetos, pacotes, componentes, estrutura composta, perfil | casos de uso, atividades, sequência, comunicação, visão geral de interação, estados, tempo | ER, navegação de telas, contrato de API |
| `/diagrama-arquitetura` → `3_Arquitetura/` | implantação, componentes no nível de serviço | — | C4 contexto e contêiner |

### Visual e assets

- Todos os diagramas usam o mesmo **tema dark** definido em `0_Assets/diagramas/tema.svg` — abra o arquivo para ver a referência. As skills copiam o `<style>` e os `<defs>` dele e estilizam só por classes CSS; edite o tema para mudar o visual dos próximos diagramas.
- Coloque em `0_Assets/diagramas/` ícones de cloud, tecnologias e logos de integrações (de preferência `.svg`). Os diagramas de arquitetura são **neutros de provedor** (valem para Azure, AWS e GCP): usam categorias como *função serverless* ou *armazenamento de objetos*, nunca nomes de produto de um só provedor. As skills procuram ali antes de desenhar e **embutem** o asset no SVG, que continua autocontido e renderiza no GitHub.
- Antes de entregar, a skill valida o XML e, se houver `rsvg-convert`/`qlmanage`, renderiza uma prévia para corrigir sobreposições e desalinhamentos.

---

## Requisitos

- `bash` 3.2+
- `curl` ou `wget`
- [Claude Code](https://claude.com/claude-code) para as skills de diagrama

---

## Licença

MIT