-- Role-based access control and a dedicated calendar-feed token per user.
ALTER TABLE users ADD COLUMN role VARCHAR(20) NOT NULL DEFAULT 'USER';

-- Opaque token used to subscribe to a user's personal .ics feed without
-- exposing their JWT in the URL. Generated lazily on first request.
ALTER TABLE users ADD COLUMN calendar_token VARCHAR(64);
ALTER TABLE users ADD CONSTRAINT uq_users_calendar_token UNIQUE (calendar_token);
