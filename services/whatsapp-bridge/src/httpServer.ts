import http from "node:http";
import QRCode from "qrcode";
import { config } from "./config.js";
import { createLogger } from "./logger.js";
import * as baileys from "./baileysService.js";

const log = createLogger("http-server");

function tokenFromRequest(req: http.IncomingMessage): string | null {
  const header = req.headers["x-bridge-token"];
  if (typeof header === "string") return header;
  const url = new URL(req.url ?? "/", "http://internal");
  return url.searchParams.get("token");
}

/** Full admin access — required for /send, the only route that can act on WhatsApp on our behalf. */
function checkAuth(req: http.IncomingMessage): boolean {
  return tokenFromRequest(req) === config.bridgeAuthToken;
}

/** Pairing-only access — accepts the scoped pairToken (what we hand to the client) or the admin token. */
function checkPairAuth(req: http.IncomingMessage): boolean {
  const token = tokenFromRequest(req);
  return token === config.pairToken || token === config.bridgeAuthToken;
}

function readBody(req: http.IncomingMessage): Promise<string> {
  return new Promise((resolve, reject) => {
    let body = "";
    req.on("data", (chunk) => (body += chunk));
    req.on("end", () => resolve(body));
    req.on("error", reject);
  });
}

export function startHttpServer(): void {
  const server = http.createServer(async (req, res) => {
    try {
      const pathname = new URL(req.url ?? "/", "http://internal").pathname;

      if (pathname === "/health" && req.method === "GET") {
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true }));
        return;
      }

      if (pathname === "/status" && req.method === "GET") {
        if (!checkPairAuth(req)) return unauthorized(res);
        const status = await baileys.getConnectionStatus();
        const qrExpiresAt = baileys.getLatestQrExpiresAt();
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ...(status ?? { status: "unknown" }), qr_expires_at: qrExpiresAt }));
        return;
      }

      if (pathname === "/debug/business-profile" && req.method === "GET") {
        if (!checkAuth(req)) return unauthorized(res);
        const profile = await baileys.getBusinessProfile();
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ is_business: profile != null, profile }));
        return;
      }

      if (pathname === "/qr" && req.method === "GET") {
        if (!checkPairAuth(req)) return unauthorized(res);
        const qr = baileys.getLatestQr();
        if (!qr) {
          res.writeHead(404, { "Content-Type": "application/json" });
          res.end(JSON.stringify({ error: "No QR pending — already paired or not yet generated" }));
          return;
        }
        const png = await QRCode.toBuffer(qr, { width: 400 });
        res.writeHead(200, { "Content-Type": "image/png", "Cache-Control": "no-store" });
        res.end(png);
        return;
      }

      if (pathname === "/pair" && req.method === "GET") {
        if (!checkPairAuth(req)) return unauthorized(res);
        const url = new URL(req.url ?? "/", "http://internal");
        const token = url.searchParams.get("token") ?? "";
        res.writeHead(200, { "Content-Type": "text/html; charset=utf-8" });
        res.end(renderPairPage(token));
        return;
      }

      if (pathname === "/reset" && req.method === "POST") {
        if (!checkPairAuth(req)) return unauthorized(res);
        await baileys.resetSession();
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true, status: "resetting" }));
        return;
      }

      if (pathname === "/pair" && req.method === "POST") {
        if (!checkPairAuth(req)) return unauthorized(res);
        const body = JSON.parse(await readBody(req)) as { phone?: string };
        if (!body.phone) return badRequest(res, "Missing phone");
        const code = await baileys.requestPairingCode(body.phone);
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ code }));
        return;
      }

      if (pathname === "/send" && req.method === "POST") {
        if (!checkAuth(req)) return unauthorized(res);
        const body = JSON.parse(await readBody(req)) as { phone?: string; text?: string };
        if (!body.phone || !body.text) return badRequest(res, "Missing phone or text");
        await baileys.sendText(body.phone, body.text);
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true }));
        return;
      }

      if (pathname === "/send-document" && req.method === "POST") {
        if (!checkAuth(req)) return unauthorized(res);
        const body = JSON.parse(await readBody(req)) as {
          phone?: string;
          url?: string;
          filename?: string;
          mimetype?: string;
        };
        if (!body.phone || !body.url || !body.filename) {
          return badRequest(res, "Missing phone, url, or filename");
        }
        await baileys.sendDocument(body.phone, body.url, body.filename, body.mimetype ?? "application/pdf");
        res.writeHead(200, { "Content-Type": "application/json" });
        res.end(JSON.stringify({ ok: true }));
        return;
      }

      res.writeHead(404, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Not found" }));
    } catch (err) {
      log.error({ err }, "Request failed");
      res.writeHead(500, { "Content-Type": "application/json" });
      res.end(JSON.stringify({ error: "Internal error" }));
    }
  });

  server.listen(config.port, () => log.info({ port: config.port }, "HTTP server listening"));
}

function renderPairPage(token: string): string {
  const safeToken = JSON.stringify(token);
  return `<!doctype html>
<html lang="es">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>OpenCaller — Vincular Gateway WhatsApp Baileys</title>
<style>
  :root { color-scheme: dark; }
  * { box-sizing: border-box; }
  body {
    font-family: -apple-system, system-ui, "Segoe UI", sans-serif;
    background: radial-gradient(circle at 20% -10%, #16212c 0%, #0b0f14 55%);
    color: #e6edf3; margin: 0; min-height: 100vh;
    display: flex; align-items: center; justify-content: center; padding: 32px 16px;
  }
  .page { width: 100%; max-width: 760px; display: flex; flex-direction: column; gap: 20px;
          animation: fadeUp .5s ease both; }
  header { text-align: center; }
  .brand { font-size: 1.4rem; font-weight: 700; letter-spacing: -0.01em; }
  .brand span { font-size: 1.4rem; margin-right: 6px; }
  .subtitle { color: #9fb3c8; font-size: 0.95rem; margin: 4px 0 0; }
  main.grid { display: grid; grid-template-columns: 1fr 1fr; gap: 20px; }
  @media (max-width: 640px) { main.grid { grid-template-columns: 1fr; } }
  .card {
    background: #111925; border: 1px solid #223042; border-radius: 16px; padding: 24px;
    display: flex; flex-direction: column; align-items: center; gap: 14px;
    box-shadow: 0 10px 30px -12px rgba(0,0,0,.5);
  }
  #status { font-size: 0.8rem; font-weight: 600; padding: 5px 12px; border-radius: 999px;
             background: #1c2733; color: #9fb3c8; transition: background .3s, color .3s; }
  #status.connected { background: #113a24; color: #4ade80; }
  #status.pairing { background: #3a2f11; color: #facc15; }
  #status.connecting { background: #142338; color: #60a5fa; }
  .connecting-msg { display: flex; flex-direction: column; align-items: center; gap: 14px; padding: 0 12px; animation: fadeIn .3s ease; }
  .spinner { width: 42px; height: 42px; border: 3px solid #1c2733; border-top-color: #60a5fa;
             border-radius: 50%; animation: spin 0.9s linear infinite; }
  .qr-wrap { position: relative; width: 260px; height: 260px; }
  .qr-glow { position: absolute; inset: -10px; border-radius: 20px;
             background: conic-gradient(from 0deg, #facc15, #4ade80, #facc15);
             filter: blur(18px); opacity: .35; animation: spin 4s linear infinite; }
  #status.connected ~ .qr-wrap .qr-glow, .qr-wrap.connected .qr-glow { animation: none; background: #4ade80; opacity: .3; }
  #qr-box { position: relative; background: #fff; border-radius: 14px; width: 260px; height: 260px;
            display: flex; align-items: center; justify-content: center; overflow: hidden; }
  #qr-box img { width: 100%; height: 100%; display: block; animation: fadeIn .25s ease; }
  #msg { color: #55627a; font-size: 0.85rem; text-align: center; max-width: 200px; }
  .success { display: flex; flex-direction: column; align-items: center; gap: 8px; animation: popIn .4s ease; }
  .checkmark { width: 56px; height: 56px; border-radius: 50%; background: #113a24;
               display: flex; align-items: center; justify-content: center; }
  .checkmark svg { width: 28px; height: 28px; }
  .hint { color: #55627a; font-size: 0.8rem; text-align: center; margin: 0; }
  .countdown { color: #55627a; font-size: 0.78rem; font-variant-numeric: tabular-nums; min-height: 1.1em; }
  .countdown b { color: #9fb3c8; }
  .toggle { position: relative; display: flex; width: 100%; background: #1c2733; border-radius: 999px;
            padding: 4px; }
  .toggle-btn { flex: 1; border: none; background: transparent; color: #9fb3c8; font-size: 0.85rem;
                font-weight: 600; padding: 9px 0; border-radius: 999px; cursor: pointer; position: relative;
                z-index: 1; transition: color .25s; font-family: inherit; }
  .toggle-btn.active { color: #0b0f14; }
  .toggle-thumb { position: absolute; top: 4px; left: 4px; width: calc(50% - 4px); height: calc(100% - 8px);
                  background: #e6edf3; border-radius: 999px; transition: transform .25s ease; }
  .toggle[data-platform="android"] .toggle-thumb { transform: translateX(100%); }
  .steps-list { list-style: none; margin: 4px 0 0; padding: 0; width: 100%; display: flex;
                flex-direction: column; gap: 10px; }
  .steps-list li { display: flex; align-items: flex-start; gap: 12px; opacity: 0; transform: translateY(6px);
                    animation: fadeUp .35s ease forwards; }
  .steps-list li:nth-child(1) { animation-delay: .03s; }
  .steps-list li:nth-child(2) { animation-delay: .08s; }
  .steps-list li:nth-child(3) { animation-delay: .13s; }
  .steps-list li:nth-child(4) { animation-delay: .18s; }
  .steps-list li:nth-child(5) { animation-delay: .23s; }
  .steps-list li:nth-child(6) { animation-delay: .28s; }
  .step-icon { flex: none; width: 30px; height: 30px; border-radius: 9px; background: #1c2733;
               display: flex; align-items: center; justify-content: center; }
  .step-icon svg { width: 16px; height: 16px; stroke: #facc15; }
  .step-text { font-size: 0.88rem; color: #cdd9e5; line-height: 1.35; padding-top: 5px; }
  .step-text b { color: #e6edf3; }
  footer { text-align: center; color: #384252; font-size: 0.75rem; }
  @keyframes fadeUp { from { opacity: 0; transform: translateY(10px); } to { opacity: 1; transform: translateY(0); } }
  @keyframes fadeIn { from { opacity: 0; } to { opacity: 1; } }
  @keyframes spin { to { transform: rotate(360deg); } }
  @keyframes popIn { from { opacity: 0; transform: scale(.85); } to { opacity: 1; transform: scale(1); } }
</style>
</head>
<body>
  <div class="page">
    <header>
      <div class="brand"><span>🛡️</span>OpenCaller</div>
      <p class="subtitle">Gateway de Verificación WhatsApp (Baileys)</p>
    </header>
    <main class="grid">
      <section class="card">
        <span id="status">conectando…</span>
        <div class="qr-wrap">
          <div class="qr-glow"></div>
          <div id="qr-box"><span id="msg">Cargando código QR…</span></div>
        </div>
        <span id="qr-countdown" class="countdown"></span>
        <p class="hint">El código se actualiza solo.<br>No hace falta recargar la página.</p>
        <div style="margin-top: 10px; width: 100%; border-top: 1px solid #223042; padding-top: 14px; text-align: center;">
          <p style="font-size: 0.82rem; color: #9fb3c8; margin: 0 0 8px;">¿Preferís vincular con código de 8 dígitos?</p>
          <div style="display: flex; gap: 6px; justify-content: center;">
            <input type="tel" id="phone-input" placeholder="+50688888888" value="" style="background: #1c2733; border: 1px solid #303e50; border-radius: 8px; color: #fff; padding: 6px 10px; font-size: 0.85rem; width: 140px; text-align: center;">
            <button type="button" id="btn-pair-code" style="background: #38bdf8; color: #0b0f14; border: none; border-radius: 8px; padding: 6px 12px; font-weight: 600; font-size: 0.8rem; cursor: pointer;">Generar Código</button>
          </div>
          <div id="code-result" style="margin-top: 10px; display: none; background: #16212c; border-radius: 8px; padding: 8px;">
            <span style="font-size: 0.75rem; color: #9fb3c8;">Ingresá este código en WhatsApp:</span>
            <div id="display-code" style="font-size: 1.35rem; font-weight: 700; letter-spacing: 3px; color: #4ade80; margin: 4px 0;"></div>
          </div>
        </div>
        <button type="button" id="btn-reset-session" style="background: transparent; border: 1px solid #374151; color: #9ca3af; border-radius: 6px; padding: 4px 10px; font-size: 0.72rem; cursor: pointer; margin-top: 6px;">Forzar Reinicio de Sesión</button>
      </section>
      <section class="card" style="align-items: stretch;">
        <div class="toggle" id="toggle" data-platform="ios">
          <button type="button" class="toggle-btn active" data-platform="ios">iPhone</button>
          <button type="button" class="toggle-btn" data-platform="android">Android</button>
          <span class="toggle-thumb"></span>
        </div>
        <ol class="steps-list" id="steps-list"></ol>
      </section>
    </main>
    <footer>OpenCaller · Infraestructura Comunitaria Soberana</footer>
  </div>
  <script>
    var token = ${safeToken};
    var qrBox = document.getElementById("qr-box");
    var statusEl = document.getElementById("status");
    var qrWrap = document.querySelector(".qr-wrap");
    var toggle = document.getElementById("toggle");
    var stepsList = document.getElementById("steps-list");
    var countdownEl = document.getElementById("qr-countdown");
    var lastObjectUrl = null;
    var polling = true;
    var connected = false;
    var qrExpiresAt = null;
    var lastQrExpiresAt = null;
    var connectingShown = false;

    function updateCountdown() {
      if (!qrExpiresAt || connected) {
        countdownEl.textContent = "";
        return;
      }
      var remaining = Math.max(0, Math.ceil((qrExpiresAt - Date.now()) / 1000));
      countdownEl.innerHTML = remaining > 0
        ? "Se renueva en <b>" + remaining + "s</b>"
        : "Renovando código…";
    }
    setInterval(updateCountdown, 500);

    var ICON_GEAR = "<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='12' r='3'></circle><path d='M19.4 15a1.65 1.65 0 0 0 .33 1.82l.06.06a2 2 0 1 1-2.83 2.83l-.06-.06a1.65 1.65 0 0 0-1.82-.33 1.65 1.65 0 0 0-1 1.51V21a2 2 0 0 1-4 0v-.09A1.65 1.65 0 0 0 9 19.4a1.65 1.65 0 0 0-1.82.33l-.06.06a2 2 0 1 1-2.83-2.83l.06-.06a1.65 1.65 0 0 0 .33-1.82 1.65 1.65 0 0 0-1.51-1H3a2 2 0 0 1 0-4h.09A1.65 1.65 0 0 0 4.6 9a1.65 1.65 0 0 0-.33-1.82l-.06-.06a2 2 0 1 1 2.83-2.83l.06.06a1.65 1.65 0 0 0 1.82.33H9a1.65 1.65 0 0 0 1-1.51V3a2 2 0 0 1 4 0v.09a1.65 1.65 0 0 0 1 1.51 1.65 1.65 0 0 0 1.82-.33l.06-.06a2 2 0 1 1 2.83 2.83l-.06.06a1.65 1.65 0 0 0-.33 1.82V9a1.65 1.65 0 0 0 1.51 1H21a2 2 0 0 1 0 4h-.09a1.65 1.65 0 0 0-1.51 1z'></path></svg>";
    var ICON_DOTS = "<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><circle cx='12' cy='5' r='1.4' fill='#facc15'></circle><circle cx='12' cy='12' r='1.4' fill='#facc15'></circle><circle cx='12' cy='19' r='1.4' fill='#facc15'></circle></svg>";
    var ICON_LINK = "<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M10 13a5 5 0 0 0 7.54.54l3-3a5 5 0 0 0-7.07-7.07l-1.72 1.71'></path><path d='M14 11a5 5 0 0 0-7.54-.54l-3 3a5 5 0 0 0 7.07 7.07l1.71-1.71'></path></svg>";
    var ICON_FACEID = "<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M4 7V5a2 2 0 0 1 2-2h2'></path><path d='M4 17v2a2 2 0 0 0 2 2h2'></path><path d='M20 7V5a2 2 0 0 0-2-2h-2'></path><path d='M20 17v2a2 2 0 0 1-2 2h-2'></path><circle cx='9' cy='10' r='.6' fill='#facc15'></circle><circle cx='15' cy='10' r='.6' fill='#facc15'></circle><path d='M9 15c.8.6 1.9 1 3 1s2.2-.4 3-1'></path></svg>";
    var ICON_CAMERA = "<svg viewBox='0 0 24 24' fill='none' stroke-width='2' stroke-linecap='round' stroke-linejoin='round'><path d='M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2z'></path><circle cx='12' cy='13' r='4'></circle></svg>";

    var STEPS = {
      ios: [
        ["ICON_GEAR", "Abrí WhatsApp y tocá <b>Configuración</b> (abajo a la derecha)."],
        ["ICON_LINK", "Tocá <b>Dispositivos vinculados</b> y luego <b>Vincular un dispositivo</b>."],
        ["ICON_FACEID", "Confirmá con Face ID, Touch ID o tu código de acceso."],
        ["ICON_CAMERA", "Apuntá la cámara hacia el código QR de esta pantalla."]
      ],
      android: [
        ["ICON_DOTS", "Abrí WhatsApp y tocá los <b>tres puntos</b> (arriba a la derecha)."],
        ["ICON_LINK", "Tocá <b>Dispositivos vinculados</b> y luego <b>Vincular un dispositivo</b>."],
        ["ICON_FACEID", "Confirmá tu identidad si el teléfono te lo pide."],
        ["ICON_CAMERA", "Apuntá la cámara hacia el código QR de esta pantalla."]
      ]
    };
    var ICONS = { ICON_GEAR: ICON_GEAR, ICON_DOTS: ICON_DOTS, ICON_LINK: ICON_LINK, ICON_FACEID: ICON_FACEID, ICON_CAMERA: ICON_CAMERA };

    function renderSteps(platform) {
      var items = STEPS[platform];
      var html = "";
      for (var i = 0; i < items.length; i++) {
        html += "<li><span class='step-icon'>" + ICONS[items[i][0]] + "</span><span class='step-text'>" + items[i][1] + "</span></li>";
      }
      stepsList.innerHTML = html;
    }

    toggle.addEventListener("click", function (ev) {
      var btn = ev.target.closest(".toggle-btn");
      if (!btn) return;
      var platform = btn.getAttribute("data-platform");
      toggle.setAttribute("data-platform", platform);
      var btns = toggle.querySelectorAll(".toggle-btn");
      for (var i = 0; i < btns.length; i++) btns[i].classList.remove("active");
      btn.classList.add("active");
      renderSteps(platform);
    });

    renderSteps("ios");

    async function tick() {
      if (!polling) return;
      try {
        var statusResp = await fetch("/status", { headers: { "X-Bridge-Token": token } });
        var status = await statusResp.json();

        if (status.status === "connected") {
          statusEl.textContent = "conectado" + (status.phone_number ? " (" + status.phone_number + ")" : "");
          statusEl.className = "connected";
          qrWrap.classList.add("connected");
          qrExpiresAt = null;
          updateCountdown();
          if (!connected) {
            connected = true;
            qrBox.innerHTML = "<div class='success'><div class='checkmark'><svg viewBox='0 0 24 24' fill='none' stroke='#4ade80' stroke-width='3' stroke-linecap='round' stroke-linejoin='round'><path d='M4 12l5 5L20 6'></path></svg></div><span id='msg'>WhatsApp emparejado.<br>Ya podés cerrar esta pestaña.</span></div>";
          }
          polling = false;
          return;
        }

        if (status.status === "connecting") {
          statusEl.textContent = "emparejando…";
          statusEl.className = "connecting";
          qrExpiresAt = null;
          lastQrExpiresAt = null;
          updateCountdown();
          if (!connectingShown) {
            connectingShown = true;
            qrBox.innerHTML = "<div class='connecting-msg'><span class='spinner'></span><span id='msg'>Emparejando…<br>No cierres esta pestaña<br>y mantené WhatsApp abierto.</span></div>";
          }
          return;
        }
        connectingShown = false;

        statusEl.textContent = status.status === "pairing" ? "escaneá el código" : "esperando código…";
        statusEl.className = "pairing";
        qrExpiresAt = status.qr_expires_at || null;
        updateCountdown();

        // Baileys only actually generates a new QR every 20-60s (see FIRST_QR_TTL_MS /
        // SUBSEQUENT_QR_TTL_MS in baileysService.ts) — qr_expires_at changes exactly
        // when that happens. Re-fetching/redrawing the <img> every 4s poll regardless
        // caused a visible flicker even though the picture was pixel-identical; only
        // swap it when the expiry timestamp actually moves (or on first load).
        if (status.qr_expires_at && status.qr_expires_at !== lastQrExpiresAt) {
          var qrResp = await fetch("/qr?_=" + Date.now(), { headers: { "X-Bridge-Token": token } });
          if (qrResp.ok) {
            var blob = await qrResp.blob();
            var url = URL.createObjectURL(blob);
            qrBox.innerHTML = "<img alt='QR de WhatsApp' src='" + url + "'>";
            if (lastObjectUrl) URL.revokeObjectURL(lastObjectUrl);
            lastObjectUrl = url;
            lastQrExpiresAt = status.qr_expires_at;
          } else {
            qrBox.innerHTML = "<span id='msg'>Generando código QR…</span>";
          }
        }
      } catch (err) {
        statusEl.textContent = "error de conexión, reintentando…";
      } finally {
        if (polling) setTimeout(tick, 4000);
      }
    }

    document.getElementById("btn-pair-code").addEventListener("click", async function() {
      var phone = document.getElementById("phone-input").value.trim();
      if (!phone) return alert("Ingresá un número de teléfono");
      var btn = document.getElementById("btn-pair-code");
      btn.textContent = "Generando…";
      btn.disabled = true;
      try {
        var resp = await fetch("/pair", {
          method: "POST",
          headers: { "Content-Type": "application/json", "X-Bridge-Token": token },
          body: JSON.stringify({ phone: phone })
        });
        var data = await resp.json();
        if (data.code) {
          document.getElementById("display-code").textContent = data.code;
          document.getElementById("code-result").style.display = "block";
        } else {
          alert(data.error || "No se pudo generar el código. Asegurate de que el bridge esté listo.");
        }
      } catch (err) {
        alert("Error al solicitar código: " + err.message);
      } finally {
        btn.textContent = "Generar Código";
        btn.disabled = false;
      }
    });

    document.getElementById("btn-reset-session").addEventListener("click", async function() {
      if (!confirm("¿Reiniciar sesión? Esto borrará las credenciales anteriores y generará un nuevo QR/código.")) return;
      var btn = document.getElementById("btn-reset-session");
      btn.textContent = "Reiniciando…";
      btn.disabled = true;
      try {
        var resp = await fetch("/reset", {
          method: "POST",
          headers: { "X-Bridge-Token": token }
        });
        var data = await resp.json();
        alert("Sesión reiniciada. Recargando...");
        location.reload();
      } catch (err) {
        alert("Error al reiniciar: " + err.message);
        btn.textContent = "Forzar Reinicio de Sesión";
        btn.disabled = false;
      }
    });

    tick();
  </script>
</body>
</html>`;
}

function unauthorized(res: http.ServerResponse): void {
  res.writeHead(401, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: "Unauthorized" }));
}

function badRequest(res: http.ServerResponse, message: string): void {
  res.writeHead(400, { "Content-Type": "application/json" });
  res.end(JSON.stringify({ error: message }));
}
