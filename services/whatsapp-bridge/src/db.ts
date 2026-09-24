import postgres from "postgres";
import { config } from "./config.js";

let sql: postgres.Sql | null = null;

export function initDb(): postgres.Sql {
  if (!sql) {
    sql = postgres(config.databaseUrl, { max: 5 });
  }
  return sql;
}

export function getDb(): postgres.Sql {
  if (!sql) throw new Error("DB not initialized — call initDb() first");
  return sql;
}
