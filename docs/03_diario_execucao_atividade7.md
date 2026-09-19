# Diário de execução — Atividade 7

## 19/09/2026 — Etapa 1: sincronização do repositório local

### Situação observada
Ao executar `git status` na pasta local `D:\\GitHub\\C3-Trabalho-Ingestao-Pipeline-Atividade7`, o Git informou diversos arquivos rastreados como `deleted`, incluindo README, documentação, evidências, infraestrutura Terraform, Lambdas, amostras e scripts.

O comando `git fetch origin` seguido de `git pull --ff-only origin main` atualizou corretamente a branch local de `7855288` para `f26bbcb` e trouxe as alterações mais recentes do GitHub, inclusive:

- atualização do `README.md`;
- criação de `docs/00_plano_atividade7_passo_a_passo.md`.

Entretanto, as exclusões locais permaneceram como alterações não commitadas do diretório de trabalho.

### Diagnóstico
O repositório remoto está íntegro. O problema está apenas na cópia local: arquivos rastreados foram removidos fisicamente do diretório, mas essas remoções ainda não foram commitadas.

### Ação corretiva planejada
Restaurar todos os arquivos rastreados para o estado atual da branch `main`:

```powershell
git restore .
git status
```

Depois, conferir a estrutura:

```powershell
Get-ChildItem
Get-ChildItem -Directory
```

### Critério de conclusão da Etapa 1
A etapa será considerada concluída quando `git status` retornar:

```text
nothing to commit, working tree clean
```

e as pastas principais (`docs`, `evidencias`, `infra`, `lambdas`, `sample`, `scripts`) estiverem novamente presentes.


## 19/09/2026 — Etapa 1 concluída

Após executar `git restore .`, a cópia local foi restaurada com sucesso.

Resultado confirmado:

```text
On branch main
Your branch is up to date with 'origin/main'.

nothing to commit, working tree clean
```

Estrutura local confirmada:

- `docs/`
- `evidencias/`
- `infra/`
- `lambdas/`
- `sample/`
- `scripts/`
- `.gitignore`
- `README.md`

Conclusão: a Etapa 1 foi concluída e o repositório local está sincronizado e íntegro. Próxima etapa: inventário dos recursos AWS do pipeline.


## 19/09/2026 — Etapa 2: primeiro teste do inventário AWS

### Ocorrência
O primeiro bloco de comandos AWS foi executado no **Windows PowerShell**, mas utilizava `\` como caractere de continuação de linha. Esse formato é próprio de shells Unix/Linux (como Bash) e não é válido no PowerShell.

O PowerShell interpretou as linhas iniciadas por `--query` e `--output` como expressões independentes, gerando erros como:

```text
Expressão ausente após operador unário '--'.
Token 'query' inesperado na expressão ou instrução.
```

### Diagnóstico
Não há evidência de erro da AWS CLI ou das credenciais nesta execução. O problema ocorreu **antes da chamada à AWS**, durante a interpretação do comando pelo PowerShell.

### Correção
Executar os comandos em uma única linha ou utilizar a crase/backtick (`) como continuação de linha no PowerShell.


## 19/09/2026 — Etapa 2: falha de autenticação da AWS CLI

### Resultado observado
A AWS CLI respondeu com erros de autenticação em todos os serviços consultados:

```text
InvalidClientTokenId
InvalidToken
UnrecognizedClientException
```

O comando `aws configure get region` retornou:

```text
us-east-1
```

### Diagnóstico
A AWS CLI está instalada e executando, porém as credenciais atualmente carregadas no Windows são inválidas, expiradas ou estão sendo sobrescritas por credenciais temporárias antigas. Como o erro ocorre já em `aws sts get-caller-identity`, o problema antecede S3, Lambda, SQS e RDS.

A região configurada como `us-east-1` também difere da região usada anteriormente no pipeline (`us-east-2`), mas essa divergência não explica o erro de token. A autenticação deve ser corrigida primeiro.

### Próxima ação
Identificar, sem expor segredos, de onde a AWS CLI está obtendo as credenciais (`aws configure list`, perfis existentes e nomes das variáveis `AWS_*`) e então renovar a sessão/credenciais temporárias do ambiente AWS Try Catch Finally.
