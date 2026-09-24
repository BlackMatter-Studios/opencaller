import "dotenv/config";

const TELEGRAM_TOKEN = process.env.TELEGRAM_BOT_TOKEN;
const OPENCALLER_API_URL = process.env.OPENCALLER_API_URL || "http://api:8080";
const POLL_TIMEOUT_SECONDS = 30;

if (!TELEGRAM_TOKEN) {
  console.error("FATAL: TELEGRAM_BOT_TOKEN is required. Set it in .env");
  process.exit(1);
}

const BASE_URL = `https://api.telegram.org/bot${TELEGRAM_TOKEN}`;
const pendingSessions = new Map(); // chatId -> sessionId

async function callTelegram(method, payload = {}) {
  const res = await fetch(`${BASE_URL}/${method}`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(payload),
  });
  return res.json();
}

async function handleMessage(msg) {
  const chatId = msg.chat?.id;
  const text = msg.text || "";
  const fromId = msg.from?.id;

  if (!chatId) return;

  // Handle /start <session_id>
  if (text.startsWith("/start")) {
    const parts = text.split(" ");
    const sessionId = parts[1]?.trim();

    if (sessionId) {
      pendingSessions.set(chatId, sessionId);
      await callTelegram("sendMessage", {
        chat_id: chatId,
        text: `🛡️ *Bienvenido al Gateway de Verificación de OpenCaller*\n\nPara certificar tu cuenta sin SMS pagos ni intermediarios, presiona el botón inferior para compartir tu número telefónico verificado de Telegram.`,
        parse_mode: "Markdown",
        reply_markup: {
          keyboard: [
            [{ text: "📱 Verificar mi número telefónico", request_contact: true }],
          ],
          resize_keyboard: true,
          one_time_keyboard: true,
        },
      });
      return;
    } else {
      await callTelegram("sendMessage", {
        chat_id: chatId,
        text: `🛡️ *OpenCaller Bot*\n\nEste bot verifica cuentas para la red descentralizada de OpenCaller.\nAbre la app de OpenCaller y selecciona *Verificar vía Telegram* para iniciar.`,
        parse_mode: "Markdown",
      });
      return;
    }
  }

  // Handle contact sharing
  if (msg.contact) {
    const contact = msg.contact;
    const sessionId = pendingSessions.get(chatId);

    // Cryptographic anti-spoof check: ensure the contact shared belongs to the sender
    if (contact.user_id !== fromId) {
      await callTelegram("sendMessage", {
        chat_id: chatId,
        text: `⚠️ *Error de seguridad*: Debes compartir tu propio número de contacto, no una tarjeta de un tercero.`,
        parse_mode: "Markdown",
      });
      return;
    }

    let phone = contact.phone_number.replace(/[^\d]/g, "");
    if (!phone.startsWith("+")) {
      phone = `+${phone}`;
    }

    try {
      // Notify OpenCaller backend
      const res = await fetch(`${OPENCALLER_API_URL}/v1/auth/verify/telegram-confirm`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          session_id: sessionId || null,
          telegram_user_id: fromId,
          telegram_username: msg.from?.username || null,
          phone_number: phone,
          first_name: contact.first_name || null,
        }),
      });

      if (res.ok) {
        pendingSessions.delete(chatId);
        await callTelegram("sendMessage", {
          chat_id: chatId,
          text: `✅ *¡Número ${phone} verificado con éxito!*\n\nTu identidad soberana ha sido certificada en el nodo de OpenCaller.\nPuedes regresar a la aplicación ahora.`,
          parse_mode: "Markdown",
          reply_markup: { remove_keyboard: true },
        });
      } else {
        const errData = await res.json().catch(() => ({}));
        await callTelegram("sendMessage", {
          chat_id: chatId,
          text: `⚠️ No se pudo vincular la sesión: ${errData.error || "Intenta nuevamente desde la app."}`,
        });
      }
    } catch (err) {
      console.error("Error communicating with OpenCaller backend:", err);
      await callTelegram("sendMessage", {
        chat_id: chatId,
        text: `❌ Error temporal comunicando con el servidor OpenCaller. Por favor reintenta en unos instantes.`,
      });
    }
  }
}

async function startPolling() {
  console.log("🚀 OpenCaller Telegram Verification Bot started (long-polling)...");
  let offset = 0;

  while (true) {
    try {
      const resp = await callTelegram("getUpdates", {
        offset,
        timeout: POLL_TIMEOUT_SECONDS,
        allowed_updates: ["message"],
      });

      if (resp.ok && Array.isArray(resp.result)) {
        for (const update of resp.result) {
          offset = update.update_id + 1;
          if (update.message) {
            await handleMessage(update.message);
          }
        }
      }
    } catch (err) {
      console.error("Polling error, retrying in 3s...", err);
      await new Promise((r) => setTimeout(r, 3000));
    }
  }
}

startPolling();
