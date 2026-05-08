-- Enable pg_net extension required by notify_push() for async HTTP calls
CREATE EXTENSION IF NOT EXISTS pg_net WITH SCHEMA extensions;

-- Grant usage so SECURITY DEFINER functions can call net.http_post
GRANT USAGE ON SCHEMA net TO postgres, service_role;
