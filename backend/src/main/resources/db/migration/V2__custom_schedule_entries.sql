CREATE TABLE custom_schedule_entries (
  id          BIGSERIAL PRIMARY KEY,
  user_id     BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title       VARCHAR(300) NOT NULL,
  professor   VARCHAR(200),
  entry_type  VARCHAR(20) NOT NULL DEFAULT 'LECTURE'
              CHECK (entry_type IN ('LECTURE','LAB','EXERCISE','COMBINED')),
  day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time  TIME NOT NULL,
  end_time    TIME NOT NULL,
  room        VARCHAR(100),
  color       VARCHAR(20),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_custom_entries_user ON custom_schedule_entries(user_id);
