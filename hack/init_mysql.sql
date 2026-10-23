CREATE DATABASE IF NOT EXISTS auth;
CREATE DATABASE IF NOT EXISTS postgres;

CREATE USER IF NOT EXISTS 'supabase_auth_admin'@'%' IDENTIFIED BY 'root';
GRANT ALL PRIVILEGES ON auth.* TO 'supabase_auth_admin'@'%';
GRANT ALL PRIVILEGES ON postgres.* TO 'supabase_auth_admin'@'%';
FLUSH PRIVILEGES;
