-- book_track role bootstrap
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'book_track') THEN
    CREATE ROLE book_track LOGIN;
  END IF;
END
$$;

ALTER ROLE book_track WITH REPLICATION;
