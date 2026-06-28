# System PDV PRO

Sistema de Frente de Loja (PDV) para lojas — vendas, produtos, estoque,
clientes, caixa, contas a pagar/receber, NFe de entrada, relatórios,
usuários/perfis e backup. Funciona como **aplicativo desktop Windows**
(instalador `.exe`) com **banco SQLite embutido** e operação **em rede**
(um Servidor + vários Caixas / computadores administrativos).

> O layout/front-end (`index.html` e `app.html`) é mantido exatamente como
> está. O que este repositório acrescenta é o **backend** (servidor de rede
> Node + SQLite) e o **empacotamento desktop** (Tauri 2) que fazem o sistema
> funcionar de ponta a ponta.

---

## Arquitetura

```
┌─────────────────────────── Máquina SERVIDOR ───────────────────────────┐
│  System PDV PRO.exe (Tauri)                                             │
│   ├─ WebView  ──► index.html / app.html  (front-end, inalterado)        │
│   └─ Servidor embutido (Node + better-sqlite3)  http://0.0.0.0:8765     │
│        ├─ /api/sql/exec, /api/sql/exec-batch  (banco SQLite)            │
│        ├─ /api/auth/login, /api/health, /api/identidade                 │
│        ├─ /api/backup/dump, /api/backup/restore                         │
│        ├─ /api/caixas-clientes/register                                 │
│        └─ WebSocket /ws  (sincroniza telas entre caixas)                │
│        Banco: %APPDATA%/com.systempdvpro.app/data/system_pdv_pro.db     │
└────────────────────────────────────────────────────────────────────────┘
            ▲                         ▲                         ▲
            │ LAN (http 8765 / ws)    │                         │
   ┌────────┴────────┐       ┌────────┴────────┐       ┌────────┴────────┐
   │ CAIXA 02        │       │ CAIXA 03        │       │ ADMINISTRATIVO  │
   │ System PDV PRO  │  ...  │ System PDV PRO  │  ...  │ System PDV PRO  │
   │ (Máquina add.)  │       │ (Máquina add.)  │       │ (Máquina add.)  │
   └─────────────────┘       └─────────────────┘       └─────────────────┘
```

- **Servidor:** hospeda o banco e atende toda a rede. Tem acesso a todos os módulos.
- **Máquina adicional (caixa/administrativo):** aponta para o IP do Servidor; usa o mesmo banco em tempo real.

---

## Componentes do repositório

| Pasta / arquivo | Descrição |
|---|---|
| `index.html`, `app.html` | Front-end do sistema (inalterados). |
| `server/` | Servidor de rede Node + `better-sqlite3` (API + WebSocket). |
| `server/schema.js` | Schema do banco + seeds (espelha `criarEstrutura()` do `app.html`). |
| `src-tauri/` | App desktop Tauri 2 (Rust): persiste config e inicia o servidor embutido. |
| `scripts/build-frontend.js` | Copia `index.html`/`app.html` para `dist/` (empacotado no app). |
| `.github/workflows/build-windows.yml` | CI que gera o instalador Windows `.exe`. |

---

## Instalador Windows (.exe)

O nome do instalador gerado é:

```
System PDV PRO_2.0.0_x64-setup.exe
```

### Como gerar o instalador (GitHub Actions — recomendado)

Não é preciso ter Windows à mão: o build roda na nuvem.

> **Antes do primeiro uso:** copie o arquivo `ci/build-windows.yml` para
> `.github/workflows/build-windows.yml` e faça commit. (O workflow vem em
> `ci/` porque a automação não tem permissão para criar arquivos em
> `.github/workflows/` por você — basta mover uma vez.)

1. Faça `push` para o GitHub (qualquer branch) **ou** dispare manualmente o
   workflow **Build Windows Installer** na aba *Actions*.
2. Ao terminar, baixe o artefato **`System-PDV-PRO-setup`** — ele contém o
   `System PDV PRO_2.0.0_x64-setup.exe`.
3. Para publicar uma versão (release com download direto), crie uma tag `vX.Y.Z`
   (ex.: `git tag v2.0.0 && git push origin v2.0.0`); o `.exe` é anexado à release.

O CI já cuida de: instalar o `better-sqlite3` compilado para Windows x64,
baixar o runtime `node.exe` (mesma versão/ABI) e embutir tudo no instalador.

### Build local no Windows (opcional)

Pré-requisitos: Node.js 20.x, Rust (stable) + MSVC build tools.

```powershell
npm install
npm --prefix server install --omit=dev
# montar recursos embutidos:
mkdir src-tauri\resources\server -Force
Invoke-WebRequest https://nodejs.org/dist/v20.18.1/win-x64/node.exe -OutFile src-tauri\resources\node.exe
Copy-Item server\server.js,server\schema.js,server\package.json src-tauri\resources\server\
Copy-Item server\node_modules src-tauri\resources\server\node_modules -Recurse
npm run build
# instalador em: src-tauri\target\release\bundle\nsis\System PDV PRO_2.0.0_x64-setup.exe
```

---

## Instalação e uso na loja

### 1) Máquina Servidor
1. Instale o `System PDV PRO_2.0.0_x64-setup.exe`.
2. Abra o app → escolha **Servidor** → **Continuar**. O servidor embutido sobe
   automaticamente e o banco é criado no primeiro boot.
3. Faça login (usuário inicial **`master`**, senha **`master`** — troque depois
   em *Usuários*).
4. Anote o IP da máquina na rede (ex.: `192.168.0.10`). Garanta que a porta
   **8765 (TCP)** esteja liberada no Firewall do Windows para a rede local.

### 2) Máquinas adicionais (caixas / administrativo)
1. Instale o mesmo `.exe`.
2. Abra o app → escolha **Máquina adicional** → informe
   `http://IP_DO_SERVIDOR:8765` (ex.: `http://192.168.0.10:8765`) → **Testar
   conexão** → **Continuar**.
3. Faça login normalmente. Todas as máquinas compartilham o mesmo banco.

---

## Rodar o servidor sem o desktop (dev / teste)

```bash
cd server
npm install
npm start            # sobe em http://0.0.0.0:8765 e serve index.html/app.html
# abra http://localhost:8765 no navegador
```

Variáveis de ambiente úteis:

| Variável | Padrão | Descrição |
|---|---|---|
| `PDV_PORT` | `8765` | Porta do servidor. |
| `PDV_HOST` | `0.0.0.0` | Interface de escuta (LAN). |
| `PDV_DATA_DIR` | `server/data` | Pasta do banco SQLite. |
| `PDV_STATIC_DIR` | raiz do repo | Pasta com `index.html`/`app.html`. |

### Rodar o desktop em modo dev

```bash
npm install
npm run dev          # Tauri dev; usa o `node` do PATH e ../server/server.js
```

---

## Usuários iniciais (seeds)

| Login | Senha | Nível |
|---|---|---|
| `master` | `master` | master |

> Há também um usuário administrativo interno do desenvolvedor. **Troque/relmova
> as credenciais padrão antes de comercializar.**

---

## Backup

- **Exportar:** módulo *Backup / Restaurar* → gera o `.db` via `/api/backup/dump`.
- **Restaurar:** envia o `.db` para `/api/backup/restore` (o servidor valida e reinicia).

---

## Notas técnicas

- O front-end envia **SQL puro** para `/api/sql/exec` (`{sql, params}` →
  `{rows}` ou `{lastID, changes}`). A finalização de venda usa
  `/api/sql/exec-batch` (transação atômica via `better-sqlite3.transaction`).
- O schema e os seeds são criados pelo servidor no boot e também pela
  `criarEstrutura()` do `app.html` (idempotente).
- Banco em modo **WAL** para melhor concorrência entre caixas.
