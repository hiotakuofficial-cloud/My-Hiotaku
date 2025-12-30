-- SQL function to automatically mark users offline after 5 minutes
-- Run this in Supabase SQL Editor

-- Create function to mark stale users as offline
CREATE OR REPLACE FUNCTION mark_stale_users_offline()
RETURNS void AS $$
BEGIN
  UPDATE user_presence 
  SET 
    is_online = false,
    status = 'offline'
  WHERE 
    is_online = true 
    AND last_seen < NOW() - INTERVAL '5 minutes';
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to run every minute
-- This will automatically mark users offline after 5 minutes of inactivity
SELECT cron.schedule(
  'mark-offline-users',
  '* * * * *', -- Every minute
  'SELECT mark_stale_users_offline();'
);

-- Enable real-time for user_presence table
ALTER PUBLICATION supabase_realtime ADD TABLE user_presence;

-- Create trigger to notify real-time subscribers when status changes
CREATE OR REPLACE FUNCTION notify_presence_change()
RETURNS trigger AS $$
BEGIN
  -- Notify real-time subscribers of the change
  PERFORM pg_notify('presence_change', row_to_json(NEW)::text);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on user_presence table
DROP TRIGGER IF EXISTS presence_change_trigger ON user_presence;
CREATE TRIGGER presence_change_trigger
  AFTER UPDATE ON user_presence
  FOR EACH ROW
  EXECUTE FUNCTION notify_presence_change();
