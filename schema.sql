CREATE TABLE IF NOT EXISTS workouts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    exercise TEXT NOT NULL CHECK (length(exercise) BETWEEN 1 AND 100),
    sets INTEGER NOT NULL CHECK (sets BETWEEN 1 AND 20),
    reps INTEGER NOT NULL CHECK (reps BETWEEN 1 AND 100),
    weight_kg NUMERIC(7, 2) NOT NULL CHECK (weight_kg BETWEEN 0 AND 1000),
    workout_date DATE NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS workouts_date_id_idx
    ON workouts (workout_date DESC, id DESC);