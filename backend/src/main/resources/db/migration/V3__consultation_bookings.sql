-- Online/link field for consultation slots (e.g. Moodle, Teams, etc.)
ALTER TABLE consultation_slots ADD COLUMN link TEXT;

-- Student registrations for consultation slots
CREATE TABLE consultation_bookings (
    id            BIGSERIAL PRIMARY KEY,
    slot_id       BIGINT NOT NULL REFERENCES consultation_slots(id) ON DELETE CASCADE,
    user_id       BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    reason        TEXT,
    registered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    UNIQUE (slot_id, user_id)
);

CREATE INDEX idx_consultation_bookings_slot ON consultation_bookings(slot_id);
CREATE INDEX idx_consultation_bookings_user ON consultation_bookings(user_id);
