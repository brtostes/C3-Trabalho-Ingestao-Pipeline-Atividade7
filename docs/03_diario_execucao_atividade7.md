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
