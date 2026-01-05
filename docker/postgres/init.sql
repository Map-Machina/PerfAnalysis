-- Initialize PostgreSQL for PerfAnalysis development

-- Create extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Create development schemas
CREATE SCHEMA IF NOT EXISTS public;
CREATE SCHEMA IF NOT EXISTS tenant1;
CREATE SCHEMA IF NOT EXISTS tenant2;

-- Grant permissions
GRANT ALL PRIVILEGES ON SCHEMA public TO perfadmin;
GRANT ALL PRIVILEGES ON SCHEMA tenant1 TO perfadmin;
GRANT ALL PRIVILEGES ON SCHEMA tenant2 TO perfadmin;

-- Create basic tables in public schema
CREATE TABLE IF NOT EXISTS public.django_migrations (
    id SERIAL PRIMARY KEY,
    app VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    applied TIMESTAMP WITH TIME ZONE NOT NULL
);

COMMENT ON DATABASE perfanalysis IS 'PerfAnalysis Development Database';
