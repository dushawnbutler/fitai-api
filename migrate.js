const fs = require("node:fs");
const path = require("node:path");
const db = require("./db");

async function main() {
  const sql = fs.readFileSync(
    path.join(__dirname, "schema.sql"),
    "utf8"
  );

  await db.query(sql);
  console.log("Workout schema applied");
}

main().catch((error) => {
  console.error("Schema migration failed:", error);
  process.exitCode = 1;
}); 