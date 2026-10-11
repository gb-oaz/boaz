<!-- boaz:marca -->
| Projeto | Documento | Versão | Data | Status |
|:---|:---|:---:|:---|:---|
| boaz | `tema` | **v01** | 2026-10-11 15:00 | Aprovado |

# Tema dos documentos de requisito

> Objetivo: padronizar marca d'água, tipografia e formato de todo `.md` de `1_Requisitos/` e mostrar, pronto para copiar, cada bloco que um documento pode usar.

A skill `/requisito` segue este arquivo. Edite-o para mudar o padrão do projeto; os documentos existentes mudam só na próxima versão de cada um.

| Seção | O que define |
|:---|:---|
| Marca d'água | cabeçalho e rodapé obrigatórios |
| Tipografia | o que cada marcação significa |
| Formato | nome do arquivo, esqueleto e tamanho |
| Escrita | como redigir um requisito claro |
| Catálogo de blocos | cada bloco disponível, renderizado |
| Tipos de documento | quais seções cada tipo usa |
| Versionamento | versão, data, histórico e IDs |

## Marca d'água

Todo documento abre com o **cabeçalho** e fecha com o **rodapé**. Nada vem antes do cabeçalho.

```markdown
<!-- boaz:marca -->
| Projeto | Documento | Versão | Data | Status |
|:---|:---|:---:|:---|:---|
| Loja X | `02_cadastro-usuario` | **v03** | 2026-10-11 14:30 | Em revisão |

# Cadastro de usuário

> Objetivo: definir como uma pessoa cria a conta e prova que o e-mail é dela.
```

| Coluna | Conteúdo |
|:---|:---|
| Projeto | `PROJECT_NAME` de `.boaz` |
| Documento | nome do arquivo sem `.md`, em código |
| Versão | `vNN` em negrito, começa em `v01` |
| Data | `AAAA-MM-DD HH:MM`, hora local em que a versão foi gerada |
| Status | `Rascunho` → `Em revisão` → `Aprovado`; `Obsoleto` quando substituído |

O comentário `<!-- boaz:marca -->` identifica o cabeçalho para o `./boaz.sh requisitos`; as colunas não mudam de ordem.

```markdown
---

<!-- boaz:historico -->
| Versão | Data | Mudança |
|:---:|:---|:---|
| v03 | 2026-10-11 14:30 | `RF-04` incluído: limite de tentativas |
| v02 | 2026-10-10 17:05 | Status → Em revisão |
| v01 | 2026-10-10 09:00 | Criação |

<sub>Loja X · 1_Requisitos/02_cadastro-usuario.md · v03 · 2026-10-11 14:30</sub>
```

- Histórico com a versão mais nova no topo e no máximo 10 linhas; o restante fica no git
- A linha `<sub>` repete projeto, caminho, versão e data: identifica a última página quando o documento é impresso ou exportado
- Versão e data são as mesmas no cabeçalho, na primeira linha do histórico e no `<sub>`

## Tipografia

| Elemento | Markdown | Regra |
|:---|:---|:---|
| Título | `# Texto` | um por documento, logo após o cabeçalho; só a primeira letra maiúscula (e nomes próprios); sem ID nem ponto final |
| Objetivo | `> Objetivo: …` | uma frase, logo abaixo do título |
| Seção | `## Texto` | só os nomes do esqueleto do tipo, na ordem dele |
| Subseção | `### Texto` | só em Critérios de aceite, uma por requisito; nunca `####` |
| Identificador | `` `RF-01` `` | sempre em código: IDs, nomes de arquivo, campos e valores literais |
| Termo definido | `**termo**` | primeira ocorrência de um termo do glossário; no máximo um negrito por frase |
| Texto exibido ao usuário | `"Senha inválida"` | entre aspas duplas, exatamente como aparece |
| Palavra estrangeira | `*checkout*` | itálico; não use itálico para mais nada |
| Lista | `- item` | `1.` só quando a ordem importa; itens e células sem ponto final |
| Pendência | `- [ ] pergunta` | só em Em aberto |
| Destaque | `> [!IMPORTANT]` | no máximo 2 por documento (veja o catálogo) |
| Separador | `---` | só antes do rodapé |

- Datas `AAAA-MM-DD`, horas `HH:MM` (24 h)
- Número com unidade e espaço: `2 s`, `10 MB`, `R$ 1.500,00`; decimal com vírgula
- Limites com símbolo: `≤ 2 s`, `≥ 99,5 %`
- Sem emojis, cores, HTML ou imagens fora de Diagramas (exceto os comentários `<!-- boaz:… -->` e o `<sub>` do rodapé)

## Formato

**Arquivo:** `1_Requisitos/<NN>_<nome>.md`

- `NN`: dois dígitos, ordem de leitura (`00` visão, `01`–`89` funcionalidades, `90`–`98` transversais, `99` glossário)
- `nome`: kebab-case, sem acentos; não muda entre versões (os links continuam válidos)

**Esqueleto** (funcionalidade; os outros tipos estão em Tipos de documento):

```markdown
<!-- boaz:marca -->
| cabeçalho |

# Título

> Objetivo: uma frase.

## Contexto
## Requisitos funcionais
## Regras de negócio
## Requisitos não funcionais
## Critérios de aceite
## Fora de escopo
## Em aberto
## Diagramas

---

<!-- boaz:historico -->
| rodapé |
```

- Seções sempre nesta ordem; seção opcional sem conteúdo é **removida** (nunca fica vazia nem com "N/A")
- Sem numeração nas seções: o nome já é a referência

**Tamanho**

| Limite | Valor | Passou? |
|:---|:---|:---|
| Documento (sem o rodapé) | ≤ 150 linhas | divida em dois documentos |
| Contexto / Problema | ≤ 5 linhas | o detalhe vai para os requisitos |
| Requisitos funcionais | ≤ 12 por documento | divida a funcionalidade |
| Cenários por requisito | ≤ 2 | o resto é regra de negócio |
| Assunto | 1 funcionalidade por documento | crie outro documento |

## Escrita

| Bloco | Forma | Exemplo |
|:---|:---|:---|
| Requisito funcional | `O sistema deve <verbo> <objeto> [quando <condição>].` | O sistema deve bloquear o login após 5 tentativas erradas seguidas. |
| Regra de negócio | política do negócio, vale mesmo sem sistema | Um pedido só pode ser cancelado antes do envio. |
| Requisito não funcional | métrica + limite + condição | 95 % das buscas respondem em ≤ 2 s com 1.000 usuários simultâneos. |

- Uma obrigação por frase: "e" unindo duas ações são dois requisitos
- Sempre "deve"; a força vem da coluna Prioridade, nunca de "pode" ou "deveria" no texto
- Diga **o quê**, não **como**: nada de backend, frontend, banco, API, framework, provedor ou tela específica
- Voz ativa, tempo presente, um nome por coisa (o do glossário)
- Dúvida não vira requisito: vai para Em aberto
- Palavras vagas são proibidas; troque por um critério verificável:

| Evite | Troque por |
|:---|:---|
| rápido, eficiente, performático | tempo com limite: `≤ 2 s` |
| fácil, intuitivo, amigável, simples | tarefa + medida: concluir o cadastro em ≤ 3 passos |
| seguro, robusto, confiável | ameaça + controle, ou disponibilidade: `≥ 99,5 %` ao mês |
| adequado, flexível, moderno | o critério que torna "adequado" verdadeiro |
| etc., entre outros, e/ou | a lista completa, ou "e" / "ou" |
| geralmente, normalmente, se possível | a condição exata, ou mova para Em aberto |
| TBD, a definir | uma pendência em Em aberto |

## Catálogo de blocos

**Requisitos funcionais**

| ID | Requisito | Prioridade |
|:---|:---|:---|
| `RF-01` | O sistema deve criar a conta com nome, e-mail e senha | Deve |
| `RF-02` | O sistema deve enviar um código de confirmação ao e-mail informado | Deve |
| `RF-03` | O sistema deve permitir entrar com uma conta Google | Poderia |

**Prioridade** (MoSCoW)

| Valor | Significado |
|:---|:---|
| Deve | sem ele a entrega não vale; exige critério de aceite |
| Deveria | importante, mas a entrega sai sem ele |
| Poderia | desejável, entra se sobrar tempo |
| Não agora | combinado que fica para depois; prefira Fora de escopo |

**Regras de negócio**

| ID | Regra |
|:---|:---|
| `RN-01` | Um e-mail pertence a uma única conta |
| `RN-02` | O código de confirmação vale por 15 min |

**Requisitos não funcionais**

| ID | Categoria | Requisito |
|:---|:---|:---|
| `RNF-01` | Desempenho | A confirmação do código responde em ≤ 1 s para 95 % das tentativas |
| `RNF-02` | Privacidade | A senha nunca é exibida nem enviada por e-mail |

Categorias: Desempenho, Disponibilidade, Segurança, Privacidade, Acessibilidade, Usabilidade, Compatibilidade, Conformidade.

**Critérios de aceite** (um `###` por requisito `Deve`, em Gherkin)

````markdown
### `RF-02` Código de confirmação

```gherkin
Cenário: código correto
  Dado uma conta criada com "ana@exemplo.com"
  Quando a pessoa informa o código recebido em até 15 min
  Então a conta fica confirmada

Cenário: código expirado
  Dado um código enviado há mais de 15 min
  Quando a pessoa o informa
  Então o sistema exibe "Código expirado" e oferece reenviar
```
````

**Contexto** (prosa curta, opcionalmente com histórias de usuário)

```markdown
Hoje a compra exige preencher os dados a cada pedido. Clientes recorrentes abandonam o carrinho.

- Como **cliente**, quero ter uma conta, para comprar sem redigitar meus dados
```

**Personas** (visão do produto)

| Persona | Quem é | Precisa de |
|:---|:---|:---|
| Cliente | compra pela loja, pelo celular | finalizar a compra em poucos passos |
| Atendente | responde dúvidas de pedidos | ver o histórico do cliente |

**Objetivos e métricas** (visão do produto)

| Objetivo | Métrica | Meta |
|:---|:---|:---|
| Reduzir abandono | carrinhos abandonados / iniciados | ≤ 40 % em 6 meses |

**Fora de escopo**

```markdown
- Login por telefone (avaliar após a v1)
- Exclusão de conta pelo próprio cliente
```

**Em aberto**

```markdown
- [ ] Clientes de outros países precisam de cadastro? — Produto
- [ ] Quantos reenvios de código por hora? — Segurança
```

Formato: `- [ ] pergunta — quem responde`. Respondida, vira requisito ou regra e sai da lista (o histórico registra).

**Diagramas** (sempre com a versão explícita)

```markdown
![Fluxo de cadastro](../2_Diagramas/fluxo-cadastro_v02_20261011-0915.svg)
```

**Referência a outro documento**

```markdown
Usa a conta de [Cadastro de usuário](02_cadastro-usuario.md) (`RF-01`).
```

**Glossário**

| Termo | Definição |
|:---|:---|
| Conta confirmada | conta cujo e-mail foi validado pelo código |
| Pedido | conjunto de itens pagos numa mesma compra |

Termos em ordem alfabética, definição sem ponto final.

**Destaques** (no máximo 2 por documento)

> [!NOTE]
> Contexto que ajuda a entender, mas não é requisito.

> [!IMPORTANT]
> Decisão tomada que restringe o produto, com quem decidiu.

> [!WARNING]
> Risco conhecido ou dependência externa.

## Tipos de documento

| Tipo | Arquivo | Seções, na ordem (**obrigatórias** em negrito) |
|:---|:---|:---|
| Visão do produto | `00_visao-produto.md` | **Problema**, **Objetivos e métricas**, **Personas**, **Escopo**, Fora de escopo, Em aberto |
| Funcionalidade | `01`–`89` | **Contexto**, **Requisitos funcionais**, Regras de negócio, Requisitos não funcionais, **Critérios de aceite**, Fora de escopo, Em aberto, Diagramas |
| Transversal | `90`–`98` | **Contexto**, Regras de negócio, **Requisitos não funcionais**, Em aberto |
| Glossário | `99_glossario.md` | **Termos** |

Todos começam com cabeçalho, título e Objetivo e terminam com o rodapé. Escopo, na visão, é uma lista curta das capacidades do produto, não dos arquivos (`./boaz.sh requisitos` lista os arquivos).

## Versionamento

- Um arquivo por documento, editado no lugar; o git guarda o conteúdo antigo (diferente dos diagramas, que geram um arquivo por versão)
- Toda alteração, inclusive de status, é uma versão nova: `vNN` + 1, data e hora atuais no cabeçalho, linha nova no topo do histórico e `<sub>` atualizado
- IDs são únicos no projeto inteiro, não por documento: o próximo é o maior existente + 1
- IDs nunca são reaproveitados nem renumerados; requisito removido sai da tabela e o histórico registra (`RF-07` removido)
- Ao trocar a versão de um diagrama referenciado, o documento também ganha versão

---

<!-- boaz:historico -->
| Versão | Data | Mudança |
|:---:|:---|:---|
| v01 | 2026-10-11 15:00 | Criação |

<sub>boaz · 0_Assets/requisitos/tema.md · v01 · 2026-10-11 15:00</sub>
