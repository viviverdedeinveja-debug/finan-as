# Prepara um teste local do app SEM Firebase (banco simulado no navegador).
# Cria a pasta teste\ (ignorada pelo git) com:
#   index.html  -> fonte\financas.html dentro de uma página completa (no localhost o app usa o banco simulado)
#   seed.json   -> dados de teste: começa vazio ({}); para testar com dados reais, use no app
#                  "Cartões e ajustes → Importar backup (.json)" com um backup baixado do site.
# Depois sirva a pasta:  powershell -ExecutionPolicy Bypass -File ferramentas\servidor.ps1 -Port 8765 -Root <repo>\teste
# e abra http://localhost:8765
$repo = Split-Path $PSScriptRoot -Parent
$dst  = Join-Path $repo 'teste'
New-Item -ItemType Directory -Force $dst | Out-Null
$t = [IO.File]::ReadAllText((Join-Path $repo 'fonte\financas.html'), [Text.Encoding]::UTF8)
$page = "<!doctype html><html><head><meta charset=utf-8><meta name=viewport content=`"width=device-width,initial-scale=1,viewport-fit=cover`"></head><body>$t</body></html>"
[IO.File]::WriteAllText((Join-Path $dst 'index.html'), $page, (New-Object Text.UTF8Encoding($false)))
if(-not (Test-Path (Join-Path $dst 'seed.json'))){ [IO.File]::WriteAllText((Join-Path $dst 'seed.json'), '{}', (New-Object Text.UTF8Encoding($false))) }
"teste pronto em $dst"
