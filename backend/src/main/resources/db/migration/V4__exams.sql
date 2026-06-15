-- Exam / colloquium session timetables (loaded via admin CSV import)
CREATE TABLE exams (
    id           BIGSERIAL PRIMARY KEY,
    session      VARCHAR(120) NOT NULL,
    subject_name VARCHAR(300) NOT NULL,
    date         DATE NOT NULL,
    start_time   TIME,
    end_time     TIME,
    rooms        VARCHAR(200),
    note         TEXT,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_exams_session ON exams(session);
CREATE INDEX idx_exams_date    ON exams(date);
