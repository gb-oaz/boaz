# 🏗️ boaz

> Monorepo Structure Manager — configure a estrutura do seu monorepo em segundos.

---

## Repositório

| | |
|---|---|
| 🌐 GitHub | [github.com/gb-oaz/boaz](https://github.com/gb-oaz/boaz) |
| 🔐 Clone SSH | `git@github.com:gb-oaz/boaz.git` |
| 🔗 Clone HTTPS | `https://github.com/gb-oaz/boaz.git` |

---

## O que é o boaz?

O `boaz` é um script de linha de comando que monta e gerencia a estrutura de um monorepo de forma interativa. Ele cria as pastas, espelhos de documentação, QA, Dockerfiles e configurações de CI/CD — tudo com prefixo do cliente, sem amarrar a nenhuma tecnologia de build.

A cada execução ele verifica o que já existe e oferece apenas o que faz sentido adicionar.

---

## Como usar

Você pode usar o `boaz` da seguinte forma

### Baixar e manter no projeto

Ideal quando você quer versionar o script junto com o monorepo e rodá-lo sempre que precisar adicionar algo.

```bash
curl -fsSL https://raw.githubusercontent.com/gb-oaz/boaz/main/boaz.sh -o boaz.sh
chmod +x boaz.sh
./boaz.sh
```

O arquivo `boaz.sh` fica na raiz do seu projeto. Nas próximas vezes, basta rodar:

```bash
./boaz.sh
```

---

## O que o boaz cria

Na primeira execução ele pede a **sigla do projeto** (ex: `nts`, `obp`, `flux`) e monta a seguinte estrutura:

```
monorepo/
├── {sigla}_arc/         # Documentação e diagramas de cada projeto
├── {sigla}_backend/     # Serviços de backend por linguagem
├── {sigla}_frontend/    # Aplicações web e mobile por framework
├── {sigla}_qa/          # Testes — espelha backend e frontend
└── {sigla}_infra/       # Infraestrutura
    ├── docker/          # docker-compose com MySQL, MongoDB, Redis e RabbitMQ
    └── terraform/       # environments/uat e environments/prd
```

A sigla é salva em um arquivo `.boaz` na raiz — nas próximas execuções ele já reconhece o projeto e vai direto ao menu.

---

## Menu interativo

```
▶ Status [nts]
  ✔  nts_arc/        (0 subpastas)
  ✔  nts_backend/    (0 subpastas)
  ✔  nts_frontend/   (0 subpastas)
  ✔  nts_qa/         (0 subpastas)
  ✔  nts_infra/      (2 subpastas)

  O que deseja fazer?

  1. Adicionar projeto Backend
  2. Adicionar projeto Web
  3. Adicionar projeto Mobile
  4. Configurar CI
  5. Configurar CD
  6. Ver árvore de pastas
  7. Recriar estrutura base
  0. Sair
```

---

## O que cada opção faz

**Adicionar projeto Backend**
Pergunta a linguagem (Java, Kotlin, Python, Go, Node.js, Rust, PHP, C#, Scala, Elixir) e o nome. Cria a pasta do projeto e automaticamente:
- `{sigla}_qa/backend/{linguagem}/{nome}/` com `integration/`, `performance/` e `contracts/`
- `{sigla}_arc/backend/{linguagem}/{nome}/` com `architecture/diagrams/` e `architecture/images/`
- Dockerfile base em `{sigla}_infra/docker/backend/`
- Entrada no `docker-compose.yml`

**Adicionar projeto Web**
Pergunta o framework (Vue, React, Angular, Nuxt, Next.js, Svelte, Astro, Solid.js, Qwik) e o nome. Mesma estrutura de QA, Arc e Docker. Dá a sugestão do comando CLI do framework para inicializar o projeto.

**Adicionar projeto Mobile**
Pergunta a plataforma (Android, iOS, React Native, Flutter, Ionic, KMP, Capacitor, Xamarin) e o nome.

**Configurar CI**
Cria o arquivo de pipeline na raiz do repositório — que é onde cada ferramenta espera encontrá-lo. Suporta GitHub Actions, Azure Pipelines, GitLab CI, Jenkins, Bitbucket Pipelines, CircleCI e Travis CI. Os arquivos são criados sem implementação, prontos para o dev configurar.

**Configurar CD**
Cria o arquivo de CD na raiz do repositório. Suporta GitHub Actions, Azure DevOps, GitLab CI/CD, Jenkins, ArgoCD, Flux CD, Spinnaker e Harness.

---

## Ambiente local

O `docker-compose.yml` gerado já vem com os serviços compartilhados configurados:

| Serviço  | Porta | Descrição |
|----------|-------|-----------|
| MySQL    | 3306  | Banco relacional |
| MongoDB  | 27017 | Banco NoSQL |
| Redis    | 6379  | Cache |
| RabbitMQ | 5672  | Mensageria (AMQP) |
| RabbitMQ | 15672 | Management UI |

Para subir:

```bash
cd {sigla}_infra/docker
cp .env.example .env
docker compose up
```

---

## Padrão de hierarquia

Todo projeto segue o padrão:

```
{sigla}_backend/{linguagem}/{nome}/
{sigla}_frontend/web/{framework}/{nome}/
{sigla}_frontend/mobile/{plataforma}/{nome}/
```

Nomes de projeto não podem se repetir dentro da mesma linguagem/framework.

---

## Requisitos

- `bash` 3.2+
- `curl` ou `wget`
- `docker` e `docker compose` (para o ambiente local)

---

## Licença

MIT