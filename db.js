const fs = require("node:fs");
const path = require("node:path");
const { Pool } = require("pg");
const {
  SecretsManagerClient,
  GetSecretValueCommand,
} = require("@aws-sdk/client-secrets-manager");

let poolPromise;

async function createPool() {
  let config;

  if (process.env.DB_SECRET_ARN) {
    const client = new SecretsManagerClient({
      region: process.env.AWS_REGION,
    });

    const response = await client.send(
      new GetSecretValueCommand({
        SecretId: process.env.DB_SECRET_ARN,
      })
    );

    if (!response.SecretString) {
      throw new Error("Database secret has no SecretString");
    }

    const secret = JSON.parse(response.SecretString);

    config = {
      host: process.env.DB_HOST || secret.host,
      port: Number(secret.port || 5432),
      database: process.env.DB_NAME || "fitai",
      user: secret.username,
      password: secret.password,
      ssl: {
        ca: fs.readFileSync(
          path.join(__dirname, "certs", "us-east-2-bundle.pem"),
          "utf8"
        ),
        rejectUnauthorized: true,
      },
    };
  } else {
    // Your existing local PostgreSQL connection.
    config = {
      host: process.env.PGHOST || "localhost",
      port: Number(process.env.PGPORT || 5432),
      database: process.env.PGDATABASE || "fitai_local",
      user: process.env.PGUSER,
      password: process.env.PGPASSWORD,
    };
  }

  const pool = new Pool({
    ...config,
    max: 5,
    connectionTimeoutMillis: 5000,
  });

  pool.on("error", (error) => {
    console.error("Idle PostgreSQL connection error:", error);
  });

  return pool;
}

async function getPool() {
  if (!poolPromise) {
    poolPromise = createPool().catch((error) => {
      poolPromise = undefined;
      throw error;
    });
  }

  return poolPromise;
}

async function query(sql, parameters) {
  const pool = await getPool();
  return pool.query(sql, parameters);
}

module.exports = { query };