-- Shared database defaults applied on first initialization

ALTER DATABASE postgres SET timezone TO 'UTC';
ALTER DATABASE postgres SET statement_timeout TO '30s';
ALTER DATABASE postgres SET idle_in_transaction_session_timeout TO '60s';
