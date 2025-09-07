-- Initialize NagAgent database
-- This file runs when the PostgreSQL container starts for the first time

-- Create extensions if needed
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Additional database setup can be added here
SELECT 'Database initialization complete!' as message;