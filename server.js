const http = require("node:http");
const db = require("./db");

const port = Number(process.env.PORT || 3000);

function sendJson(response, statusCode, data) {
  response.writeHead(statusCode, {
    "Content-Type": "application/json",
  });

  response.end(JSON.stringify(data));
}

async function readJson(request) {
  const chunks = [];
  let totalBytes = 0;

  for await (const chunk of request) {
    totalBytes += chunk.length;

    if (totalBytes > 8192) {
      const error = new Error("Request body is too large");
      error.statusCode = 413;
      throw error;
    }

    chunks.push(chunk);
  }

  try {
    return JSON.parse(Buffer.concat(chunks).toString("utf8"));
  } catch {
    const error = new Error("Request body must contain valid JSON");
    error.statusCode = 400;
    throw error;
  }
}

function isValidDate(value) {
  if (typeof value !== "string" || !/^\d{4}-\d{2}-\d{2}$/.test(value)) {
    return false;
  }

  const parsed = new Date(`${value}T00:00:00Z`);

  return (
    !Number.isNaN(parsed.getTime()) &&
    parsed.toISOString().slice(0, 10) === value
  );
}

function validateWorkout(input) {
  if (!input || typeof input !== "object" || Array.isArray(input)) {
    return "A workout must be a JSON object";
  }

  const { exercise, sets, reps, weight_kg, workout_date } = input;

  if (
    typeof exercise !== "string" ||
    exercise.trim().length < 1 ||
    exercise.trim().length > 100
  ) {
    return "exercise must contain 1 to 100 characters";
  }

  if (!Number.isInteger(sets) || sets < 1 || sets > 20) {
    return "sets must be an integer from 1 to 20";
  }

  if (!Number.isInteger(reps) || reps < 1 || reps > 100) {
    return "reps must be an integer from 1 to 100";
  }

  if (
    typeof weight_kg !== "number" ||
    !Number.isFinite(weight_kg) ||
    weight_kg < 0 ||
    weight_kg > 1000
  ) {
    return "weight_kg must be a number from 0 to 1000";
  }

  if (!isValidDate(workout_date)) {
    return "workout_date must be a real date in YYYY-MM-DD format";
  }

  return null;
}

const server = http.createServer(async (request, response) => {
  const path = new URL(
    request.url,
    `http://${request.headers.host || "localhost"}`
  ).pathname;

  if (request.method === "GET" && path === "/health") {
    sendJson(response, 200, {
      status: "ok",
      service: "fitai-api",
    });
    return;
  }

  try {
    if (request.method === "POST" && path === "/workouts") {
      const workout = await readJson(request);
      const validationError = validateWorkout(workout);

      if (validationError) {
        sendJson(response, 400, { error: validationError });
        return;
      }

      const result = await db.query(
        `
          INSERT INTO workouts
            (exercise, sets, reps, weight_kg, workout_date)
          VALUES ($1, $2, $3, $4, $5)
          RETURNING
            id,
            exercise,
            sets,
            reps,
            weight_kg::float8 AS weight_kg,
            workout_date::text AS workout_date,
            created_at
        `,
        [
          workout.exercise.trim(),
          workout.sets,
          workout.reps,
          workout.weight_kg,
          workout.workout_date,
        ]
      );

      sendJson(response, 201, { workout: result.rows[0] });
      return;
    }

    if (request.method === "GET" && path === "/workouts") {
      const result = await db.query(`
        SELECT
          id,
          exercise,
          sets,
          reps,
          weight_kg::float8 AS weight_kg,
          workout_date::text AS workout_date,
          created_at
        FROM workouts
        ORDER BY workout_date DESC, id DESC
        LIMIT 50
      `);

      sendJson(response, 200, { workouts: result.rows });
      return;
    }

    sendJson(response, 404, { error: "Not found" });
  } catch (error) {
    if (error.statusCode) {
      sendJson(response, error.statusCode, { error: error.message });
      return;
    }

    console.error("Request failed:", error);
    sendJson(response, 500, { error: "Internal server error" });
  }
});

const listenAddress = process.env.DB_SECRET_ARN
  ? "0.0.0.0"
  : "127.0.0.1";

server.listen(port, listenAddress, () => {
  console.log(`FitAI API listening on ${listenAddress}:${port}`);
});