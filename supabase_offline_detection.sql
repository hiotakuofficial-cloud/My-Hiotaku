-- SQL function to automatically mark users offline after 5 minutes
-- Run this in Supabase SQL Editor
-- Uses existing user_presence table from chat system
-- ALL TIMESTAMPS USE SERVER TIME ZONE (UTC) - NO DEVICE TIME ISSUES

-- Drop existing function first to change return type
DROP FUNCTION IF EXISTS mark_stale_users_offline();

-- Create function to check user online status (server-side time comparison)
CREATE OR REPLACE FUNCTION check_user_online_status(user_firebase_uid TEXT)
RETURNS BOOLEAN AS $$
DECLARE
    user_record RECORD;
    is_stale BOOLEAN;
BEGIN
    -- Get user presence record
    SELECT is_online, last_seen INTO user_record
    FROM user_presence 
    WHERE firebase_uid = user_firebase_uid;
    
    -- If no record found, return false
    IF NOT FOUND THEN
        RETURN FALSE;
    END IF;
    
    -- If marked offline, return false
    IF NOT user_record.is_online THEN
        RETURN FALSE;
    END IF;
    
    -- Check if last_seen is more than 5 minutes ago (SERVER TIME)
    SELECT (NOW() - user_record.last_seen) > INTERVAL '5 minutes' INTO is_stale;
    
    -- If stale, mark offline and return false
    IF is_stale THEN
        UPDATE user_presence 
        SET is_online = false, status = 'offline', updated_at = NOW()
        WHERE firebase_uid = user_firebase_uid;
        RETURN FALSE;
    END IF;
    
    -- User is online and not stale
    RETURN TRUE;
END;
$$ LANGUAGE plpgsql;

-- Create function to mark stale users as offline (with return count)
CREATE FUNCTION mark_stale_users_offline()
RETURNS INTEGER AS $$
DECLARE
    affected_count INTEGER;
BEGIN
    -- Mark users offline who haven't been seen for 5+ minutes (SERVER TIME ONLY)
    UPDATE user_presence 
    SET 
        is_online = false,
        status = 'offline',
        updated_at = NOW()
    WHERE 
        is_online = true 
        AND (NOW() - last_seen) > INTERVAL '5 minutes';
    
    GET DIAGNOSTICS affected_count = ROW_COUNT;
    RETURN affected_count;
END;
$$ LANGUAGE plpgsql;

-- Create a scheduled job to run every minute (if pg_cron is available)
-- This will automatically mark users offline after 5 minutes of inactivity
SELECT cron.schedule(
    'mark-offline-users',
    '* * * * *', -- Every minute
    'SELECT mark_stale_users_offline();'
);

-- Enable real-time for user_presence table (if not already enabled)
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

-- Create function to update last_seen with server time (for manual calls)
CREATE OR REPLACE FUNCTION update_user_heartbeat(user_firebase_uid TEXT)
RETURNS VOID AS $$
BEGIN
    UPDATE user_presence 
    SET last_seen = NOW(), updated_at = NOW()
    WHERE firebase_uid = user_firebase_uid;
END;
$$ LANGUAGE plpgsql;
