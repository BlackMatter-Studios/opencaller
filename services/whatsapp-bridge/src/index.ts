import { config } from "./config.js";
import { createLogger } from "./logger.js";
import { initDb } from "./db.js";
import { startBaileys, shutdown as shutdownBaileys } from "./baileysService.js";
import { startHttpServer } from "./httpServer.js";

const log = createLogger("index");

async function main(): Promise<void> {
  initDb();
  startHttpServer();
  await startBaileys();
  log.info({ port: config.port }, "WhatsApp Baileys bridge started");
}

main().catch((err) => {
  log.error({ err }, "Fatal startup error");
  process.exit(1);
});

// Docker sends SIGTERM on `stop`/`restart`/redeploy. Without this, the
// process used to die with the Baileys WebSocket still open, leaving a stale
// session on WhatsApp's server that could collide with the next reconnect
// (see the long comment on shutdown() in baileysService.ts). The short delay
// gives the close frame time to actually reach WhatsApp before we exit.
async function shutdownGracefully(signal: string): Promise<void> {
  log.info({ signal }, "Received shutdown signal — closing WhatsApp socket cleanly");
  shutdownBaileys();
  await new Promise((resolve) => setTimeout(resolve, 300));
  process.exit(0);
}

process.on("SIGTERM", () => void shutdownGracefully("SIGTERM"));
process.on("SIGINT", () => void shutdownGracefully("SIGINT"));
