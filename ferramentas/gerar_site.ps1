# Gera o site (index.html na raiz do repositório) a partir de fonte\financas.html.
# Insere: login e banco do Firebase (projeto sem-serasa), manifest/ícone de app, service worker, downloads normais e importação de backup.
# Uso:  powershell -ExecutionPolicy Bypass -File ferramentas\gerar_site.ps1
param([string]$Src="$PSScriptRoot\..\fonte\financas.html",[string]$Dst="$PSScriptRoot\..\index.html",[string]$ConfigJs='{ apiKey: "AIzaSyA3VNRO4nNVElKchBcO4Hxy_2Q3oWN7x0s", authDomain: "sem-serasa.firebaseapp.com", projectId: "sem-serasa", storageBucket: "sem-serasa.firebasestorage.app", messagingSenderId: "324163751701", appId: "1:324163751701:web:d195fe4aa0e0d0bc3c631c" }')
$g = [IO.File]::ReadAllText($Src, [Text.Encoding]::UTF8).Replace("`r`n","`n")
function Rep([string]$a,[string]$b){ if(-not $script:g.Contains($a)){ throw "não achei: $($a.Substring(0,[math]::Min(90,$a.Length)))" }; $script:g=$script:g.Replace($a,$b) }

# head: documento completo (site próprio), manifest, Firebase
$head = @"
<!doctype html>
<html lang="pt-BR"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="theme-color" content="#d1336a">
<link rel="manifest" href="manifest.webmanifest">
<link rel="icon" href="icon-192.png">
<link rel="apple-touch-icon" href="icon-192.png">
<meta name="apple-mobile-web-app-capable" content="yes">
"@
Rep '<title>Só Se Vive Uma Vez: Sem Parar no Serasa</title>' ($head + '<title>Só Se Vive Uma Vez: Sem Parar no Serasa</title>')
Rep '<meta name="claude:viewport-fit-sides" content="cover">' ''
Rep "<style>`n/* Layout:" "<style>`n:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)} body{margin:0} [hidden]{display:none!important}`n/* Layout:"
Rep '</style>' "</style>`n</head><body>"
Rep '<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>' @'
<script src="https://cdnjs.cloudflare.com/ajax/libs/Chart.js/4.4.1/chart.umd.min.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-auth-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/10.12.2/firebase-firestore-compat.js"></script>
'@

# botão Sair no topo
Rep '<span id="status" class="note">carregando…</span>' '<span id="status" class="note">carregando…</span><button id="btnSair" class="link" hidden>Sair</button>'
Rep '.termo{display:inline-flex' '.login{max-width:380px;margin:40px auto;display:flex;flex-direction:column;gap:12px}
.login label{display:flex;flex-direction:column;gap:4px;font-size:12px;font-weight:600;color:var(--muted)}
.termo{display:inline-flex'

# início: Firebase + login (substitui o banco do claude.ai)
$old1 = @'
async function start(){
  let realDb=null;
  try{ realDb=await window.claude?.use?.('db') }catch(e){ realDb=null }
  if(!realDb && /^(localhost|127\.0\.0\.1)$/.test(location.hostname)){
    try{ const seed=await (await fetch('seed.json')).json(); db=memDb(seed); setStatus('modo de teste local') }catch(e){}
  } else db=realDb;
  if(!db){ document.getElementById('main').innerHTML='<div class="panel empty">Não foi possível abrir o banco de dados do painel. Abra o painel pelo claude.ai, com a sua conta.</div>'; setStatus('sem conexão'); return }
  try{ const user=await window.claude?.use?.('user'); if(user&&user.can){ const w=await user.can('data.write'); if(w===false) S.readOnly=true } }catch(e){}
'@
$new1 = @"
/* ===== CONFIGURAÇÃO DO FIREBASE (Configurações do projeto → Seus apps → firebaseConfig) ===== */
const FIREBASE_CONFIG = $ConfigJs;
let unsubs=[];
const track=ref=>({onSnapshot:(a,b)=>{ const u=ref.onSnapshot(a,b); unsubs.push(u); return u }});
function resetState(){ unsubs.forEach(f=>{ try{f()}catch(e){} }); unsubs=[]; Object.assign(S,{config:null,compras:[],fixos:[],entradas:[],metas:[],deps:[],viagens:[],anos:{}}); P=null }
function loginErro(c){ return ({'auth/invalid-credential':'E-mail ou senha incorretos.','auth/wrong-password':'E-mail ou senha incorretos.','auth/user-not-found':'E-mail ou senha incorretos.','auth/invalid-email':'E-mail inválido.','auth/too-many-requests':'Muitas tentativas. Espere alguns minutos e tente de novo.','auth/network-request-failed':'Sem internet. Confira a conexão.'})[c]||'Não foi possível entrar ('+c+').' }
function showLogin(auth){
  `$('#btnSair').hidden=true; `$('#termo').hidden=true; `$('#tabs').hidden=true; `$('.topbar .sel').hidden=true; setStatus('');
  `$('#main').innerHTML=``<form class="panel login" id="lf"><h2>Entrar</h2>
    <label>E-mail<input type="email" id="lEmail" autocomplete="username" required></label>
    <label>Senha<input type="password" id="lSenha" autocomplete="current-password" required></label>
    <div class="err note" id="lErr" style="color:var(--bad)"></div>
    <button class="primary" type="submit">Entrar</button>
    <button class="link" type="button" id="lReset">Esqueci minha senha</button>
    <p class="note">Seu login é o usuário criado no Firebase (Authentication → Users).</p></form>``;
  `$('#lf').addEventListener('submit',async e=>{ e.preventDefault(); `$('#lErr').textContent='';
    try{ await auth.signInWithEmailAndPassword(`$('#lEmail').value.trim(),`$('#lSenha').value) }catch(err){ `$('#lErr').textContent=loginErro(err.code) } });
  `$('#lReset').onclick=async()=>{ const em=`$('#lEmail').value.trim(); if(!em){ `$('#lErr').textContent='Digite o e-mail acima primeiro.'; return }
    try{ await auth.sendPasswordResetEmail(em); `$('#lErr').textContent='Enviamos um link para redefinir a senha para '+em+'.' }catch(err){ `$('#lErr').textContent=loginErro(err.code) } };
}
async function start(){
  if(FIREBASE_CONFIG && window.firebase){
    firebase.initializeApp(FIREBASE_CONFIG);
    const auth=firebase.auth(), fs=firebase.firestore();
    try{ await fs.enablePersistence({synchronizeTabs:true}) }catch(e){}
    `$('#btnSair').onclick=()=>auth.signOut();
    auth.onAuthStateChanged(u=>{ resetState();
      if(!u){ showLogin(auth); return }
      `$('#btnSair').hidden=false; `$('#termo').hidden=false; `$('#tabs').hidden=false; `$('.topbar .sel').hidden=false;
      const base='users/'+u.uid+'/';
      db={collection:c=>fs.collection(base+c), doc:p=>fs.doc(base+p),
          async importar(lista){ for(let i=0;i<lista.length;i+=400){ const b=fs.batch(); lista.slice(i,i+400).forEach(x=>b.set(fs.doc(base+x.col+'/'+x.id),x.data)); await b.commit() } }};
      `$('#main').innerHTML='<div class="empty">Carregando seus lançamentos…</div>';
      subscribeAll();
    });
    return;
  }
  if(/^(localhost|127\.0\.0\.1)`$/.test(location.hostname)){
    try{ const seed=await (await fetch('seed.json')).json(); db=memDb(seed); setStatus('modo de teste local'); subscribeAll(); return }catch(e){}
  }
  `$('#main').innerHTML='<div class="panel empty">Falta a configuração do Firebase neste arquivo (FIREBASE_CONFIG). Veja o passo a passo em COMO PUBLICAR.txt.</div>'; setStatus('sem configuração');
}
function subscribeAll(){
"@
Rep $old1 $new1
Rep 'Object.entries(COLS).forEach(([k,col])=>{ let first=true;
    db.collection(col).onSnapshot(' 'Object.entries(COLS).forEach(([k,col])=>{ let first=true;
    track(db.collection(col)).onSnapshot('
Rep "let f1=true; db.collection('anos').onSnapshot(" "let f1=true; track(db.collection('anos')).onSnapshot("
Rep "let f2=true; db.doc('config/geral').onSnapshot(" "let f2=true; track(db.doc('config/geral')).onSnapshot("
Rep "setStatus(S.readOnly?'somente leitura':'salvo na nuvem')" "setStatus('salvo na nuvem')"
Rep 'catch(e){ toast(''Não salvou: ''+(e&&e.code===''quota_exceeded''?''o banco está cheio'':''tente de novo'')); return false }' 'catch(e){ toast(''Não salvou: ''+(e&&e.code===''permission-denied''?''sem permissão (confira as regras do Firestore)'':''tente de novo'')); return false }'

# downloads normais (site próprio)
Rep "async function baixar(nome,txt,tipo){
  try{ const dl=await window.claude?.use?.('downloads'); if(!dl){ toast('Download indisponível nesta visualização'); return } await dl.save({filename:nome,data:txt instanceof Blob?txt:new Blob([txt],{type:tipo})}); }catch(e){ toast('Download cancelado') }
}" "async function baixar(nome,txt,tipo){
  const blob=txt instanceof Blob?txt:new Blob([txt],{type:tipo}); const url=URL.createObjectURL(blob);
  const a=document.createElement('a'); a.href=url; a.download=nome; document.body.appendChild(a); a.click(); a.remove(); setTimeout(()=>URL.revokeObjectURL(url),10000);
}"

# importar backup
Rep '    <div class="actions" style="justify-content:flex-start"><button class="primary" id="bkXlsx">Baixar planilha (.xlsx)</button>' '    <div class="actions" style="justify-content:flex-start"><label class="note" style="display:flex;flex-direction:column;gap:4px">Importar backup (.json)<input type="file" id="bkImp" accept=".json,application/json"></label></div>
    <p class="note">Importar grava os lançamentos do arquivo por cima dos que têm o mesmo código; os outros continuam.</p>
    <div class="actions" style="justify-content:flex-start"><button class="primary" id="bkXlsx">Baixar planilha (.xlsx)</button>'
Rep '  $(''#bkXlsx'').onclick=async()=>{' @'
  $('#bkImp').onchange=async e=>{ const f=e.target.files[0]; if(!f) return;
    try{ const j=JSON.parse(await f.text()); const lista=[]; const lst=v=>Array.isArray(v)?v:(v&&typeof v==='object'?(('id' in v)?[v]:Object.entries(v).map(([id,d])=>({id,...d}))):[]); const arr=(k,col)=>lst(j[k]).forEach(r=>{ const {id,...d}=r; lista.push({col,id:id||newId(col[0]),data:JSON.parse(JSON.stringify(d))}) });
      arr('compras','compras'); arr('fixos','fixos'); arr('entradas','entradas'); arr('metas','cofrinho_metas'); arr('depositos','cofrinho_dep'); arr('viagens','viagens');
      Object.entries(j.anos||{}).forEach(([y,d])=>lista.push({col:'anos',id:String(y),data:d})); if(j.config) lista.push({col:'config',id:'geral',data:j.config});
      if(!lista.length){ toast('Esse arquivo não tem lançamentos'); return }
      setStatus('importando '+lista.length+' registros…');
      if(db.importar) await db.importar(lista); else for(const x of lista) await put(x.col,x.id,x.data);
      toast('Importado: '+lista.length+' registros'); setStatus('salvo na nuvem') }catch(err){ toast('Não consegui importar: '+(err&&err.message||'arquivo inválido')) } };
  $('#bkXlsx').onclick=async()=>{
'@
Rep "toast('Não consegui montar a planilha: '+(e&&e.message||'tente de novo')) }" "toast('Não consegui montar a planilha: '+(e&&e.message||'tente de novo')) }"

# rodapé: fecha o documento e registra o app
$g = $g.TrimEnd() + "`n<script>if('serviceWorker' in navigator&&location.protocol==='https:'){navigator.serviceWorker.register('sw.js').catch(()=>{})}</script>`n</body></html>`n"
[IO.File]::WriteAllText($Dst, $g, (New-Object Text.UTF8Encoding($false)))
'site ok'
