-- Exams a user has pinned to their personal schedule (Мој Распоред).
CREATE TABLE user_saved_exams (
  id        BIGSERIAL PRIMARY KEY,
  user_id   BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  exam_id   BIGINT NOT NULL REFERENCES exams(id) ON DELETE CASCADE,
  added_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CONSTRAINT uq_user_saved_exam UNIQUE (user_id, exam_id)
);

CREATE INDEX idx_user_saved_exams_user ON user_saved_exams(user_id);
