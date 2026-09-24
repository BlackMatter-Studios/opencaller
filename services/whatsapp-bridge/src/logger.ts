import pino from "pino";

const isDev = process.env.NODE_ENV !== "production";

export function createLogger(name: string) {
  return pino({
    name,
    level: process.env.LOG_LEVEL ?? "info",
    transport: isDev ? { target: "pino-pretty", options: { colorize: true } } : undefined,
  });
}
