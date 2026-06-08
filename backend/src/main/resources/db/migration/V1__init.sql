-- Classrooms from EduPage
CREATE TABLE classrooms (
  id          BIGSERIAL PRIMARY KEY,
  edupage_id  VARCHAR(20) UNIQUE NOT NULL,
  name        VARCHAR(200) NOT NULL,
  short_name  VARCHAR(100)
);

-- Subjects from EduPage
CREATE TABLE subjects (
  id          BIGSERIAL PRIMARY KEY,
  edupage_id  VARCHAR(20) UNIQUE NOT NULL,
  full_name   VARCHAR(300) NOT NULL,
  base_name   VARCHAR(300) NOT NULL,
  lesson_type VARCHAR(20)  NOT NULL
    CHECK (lesson_type IN ('LECTURE','LAB','EXERCISE','COMBINED'))
);

-- Study classes (year + programme groups) from EduPage
CREATE TABLE study_classes (
  id              BIGSERIAL PRIMARY KEY,
  edupage_id      VARCHAR(20) UNIQUE NOT NULL,
  name            VARCHAR(100) NOT NULL,
  year            SMALLINT,
  programme_code  VARCHAR(30),
  colour          VARCHAR(10)
);

-- Canonical teacher entity — populated from both EduPage and consultations
CREATE TABLE teachers (
  id                     BIGSERIAL PRIMARY KEY,
  edupage_id             VARCHAR(20) UNIQUE,
  cyrillic_name          VARCHAR(200),
  canonical_name         VARCHAR(200),
  consultation_username  VARCHAR(100) UNIQUE,
  match_confidence       DECIMAL(4,3),
  manual_override        BOOLEAN NOT NULL DEFAULT FALSE,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Manual match overrides: admin can bind an EduPage teacher to a consultation username
CREATE TABLE teacher_match_overrides (
  id                    BIGSERIAL PRIMARY KEY,
  edupage_id            VARCHAR(20) NOT NULL,
  consultation_username VARCHAR(100) NOT NULL,
  notes                 TEXT,
  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Schedule slots: one row per card from EduPage
CREATE TABLE schedule_slots (
  id               BIGSERIAL PRIMARY KEY,
  edupage_card_id  VARCHAR(20) UNIQUE NOT NULL,
  subject_id       BIGINT NOT NULL REFERENCES subjects(id),
  classroom_id     BIGINT REFERENCES classrooms(id),
  day_of_week      SMALLINT NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
  start_time       TIME NOT NULL,
  end_time         TIME NOT NULL,
  edition_number   VARCHAR(10) NOT NULL,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Junction: a card can have multiple teachers
CREATE TABLE schedule_slot_teachers (
  slot_id    BIGINT NOT NULL REFERENCES schedule_slots(id) ON DELETE CASCADE,
  teacher_id BIGINT NOT NULL REFERENCES teachers(id),
  PRIMARY KEY (slot_id, teacher_id)
);

-- Junction: a card can span multiple study classes
CREATE TABLE schedule_slot_classes (
  slot_id  BIGINT NOT NULL REFERENCES schedule_slots(id) ON DELETE CASCADE,
  class_id BIGINT NOT NULL REFERENCES study_classes(id),
  PRIMARY KEY (slot_id, class_id)
);

-- Consultation slots — concrete dated entries, NOT recurring weekly
CREATE TABLE consultation_slots (
  id           BIGSERIAL PRIMARY KEY,
  teacher_id   BIGINT NOT NULL REFERENCES teachers(id) ON DELETE CASCADE,
  date         DATE NOT NULL,
  start_time   TIME NOT NULL,
  end_time     TIME NOT NULL,
  room         VARCHAR(100),
  instructions TEXT,
  scraped_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_consultation_slots_teacher ON consultation_slots(teacher_id);
CREATE INDEX idx_consultation_slots_date    ON consultation_slots(date);

-- Users for personal schedules
CREATE TABLE users (
  id            BIGSERIAL PRIMARY KEY,
  email         VARCHAR(255) UNIQUE NOT NULL,
  password_hash VARCHAR(255) NOT NULL,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Personal schedule entries
CREATE TABLE user_schedule_slots (
  id       BIGSERIAL PRIMARY KEY,
  user_id  BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  slot_id  BIGINT NOT NULL REFERENCES schedule_slots(id) ON DELETE CASCADE,
  added_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, slot_id)
);

-- Ingestion audit log
CREATE TABLE ingestion_logs (
  id             BIGSERIAL PRIMARY KEY,
  source         VARCHAR(20) NOT NULL CHECK (source IN ('TIMETABLE','CONSULTATIONS')),
  edition_number VARCHAR(10),
  status         VARCHAR(10) NOT NULL CHECK (status IN ('RUNNING','SUCCESS','FAILURE')),
  record_count   INT,
  error_message  TEXT,
  started_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  completed_at   TIMESTAMPTZ
);
