-- Display name, collected at registration and used for the greeting on Дома.
-- Nullable: accounts created before this migration have no name on file.
ALTER TABLE users ADD COLUMN name VARCHAR(120);
