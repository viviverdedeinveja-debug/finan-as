# Só Se Vive Uma Vez: Sem Parar no Serasa — app de finanças pessoais

App de finanças da Vitória (fala português; não é programadora: explique em linguagem simples, sem jargão).

- **Site (é o que ela usa):** https://viviverdedeinveja-debug.github.io/finan-as/ — GitHub Pages, branch `main`, raiz do repositório.
- **Dados e login:** Firebase, projeto `sem-serasa` (Authentication por e-mail/senha; Firestore em `users/<uid>/...`). Regras em `ferramentas/firestore.rules`. Os dados NÃO ficam neste repositório.
- **Cópia no claude.ai (secundária):** https://claude.ai/artifact/LMvJCtMz5GBGEidzx745J4 — mesmo código, banco de dados próprio do artifact.

## Arquivos

| Arquivo | O que é |
|---|---|
| `fonte/financas.html` | **Código-fonte. Edite aqui.** É o mesmo código do painel do claude.ai (usa o banco do claude.ai lá; no localhost usa um banco simulado). |
| `index.html` | **Gerado** a partir da fonte. Não edite à mão. |
| `ferramentas/gerar_site.ps1` | Gera `index.html`: troca o banco do claude.ai pelo Firebase, adiciona tela de login, botão Sair, importar backup, downloads normais, manifest e service worker. |
| `ferramentas/testar.ps1` | Monta `teste/` (ignorada pelo git) para testar a fonte no navegador com banco simulado. |
| `ferramentas/servidor.ps1` | Servidor local simples para a pasta de teste. |
| `manifest.webmanifest`, `sw.js`, `icon-192.png`, `icon-512.png`, `.nojekyll` | App instalável (PWA) e publicação no Pages. |

## Como fazer uma mudança (sempre nesta ordem)

1. Editar `fonte/financas.html`.
2. Gerar o site: `powershell -ExecutionPolicy Bypass -File ferramentas\gerar_site.ps1` (deve imprimir `site ok`; se disser "não achei: ...", um trecho que o gerador procura mudou na fonte: ajuste o gerador junto).
3. Testar: `powershell -ExecutionPolicy Bypass -File ferramentas\testar.ps1`, servir `teste/` com `ferramentas\servidor.ps1 -Port 8765 -Root <caminho>\teste` (ou pelo navegador do app) e abrir http://localhost:8765. Confira que as abas abrem sem erro no console. Para testar com dados, importe um backup .json em "Cartões e ajustes" (o backup fica só em `teste/`, nunca no repositório).
4. Publicar: `git add` dos arquivos mudados, `git commit`, `git push origin main`. O Git usa `C:\Program Files\Git\cmd\git.exe` e o Git Credential Manager já está autorizado nesta máquina. Se o push pedir login, rode o push num terminal visível do app (o shell da ferramenta não abre a janela do navegador). O site atualiza em 1–2 minutos.
5. (Opcional) Manter o painel do claude.ai igual: publicar `fonte/financas.html` no artifact acima (ler antes, com a ferramenta de Artifact, se esta conversa ainda não o leu).

## Regras

- **Este repositório é público.** Nunca coloque aqui backups, extratos, faturas, planilhas ou qualquer dado pessoal (o `.gitignore` já bloqueia os formatos comuns).
- A configuração do Firebase dentro do `index.html` é pública por natureza; a proteção vem do login e das regras do Firestore.
- Mudanças de lógica financeira devem manter os totais: compare Entrou/Saiu/Sobrou de alguns meses antes e depois.
- Lógica principal (em `Calc` dentro da fonte): mês da fatura pelo dia de fechamento do cartão; fixos/parcelas com DIVIDIR ENTRE, VOLTAM P/ VOCÊ e DE TERCEIRO; "Cartão de 3º" conta só a sua parte; Pix/Débito é forma de pagamento (conta no Saiu, não vira fatura); contas da casa = fixos do tipo "Conta fixa" com marcação de pago por mês.
