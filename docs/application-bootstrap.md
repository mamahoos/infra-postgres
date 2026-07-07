# Application Bootstrap

`infra-postgres` runs a PostgreSQL **instance**. Each application owns its databases, roles, and secrets.

## What infra-postgres does on first start

```
postgres/init/00-extensions.sql   → core extensions only
```

No application users, passwords, or databases are created automatically.

## What your application repo should do

After `infra-postgres` is running, bootstrap from the **application** side:

```
shop-api/
├── docker-compose.yaml      # joins infra_db_net
└── database/
    └── bootstrap.sql        # CREATE USER shop; CREATE DATABASE shop OWNER shop;
```

Or use a migration tool (Flyway, Liquibase, Alembic, Prisma migrate) owned by the app.

## Recommended pattern (small projects)

1. Start infra-postgres:

   ```bash
   cd infra-postgres && docker compose up -d
   ```

2. From the app repo, apply bootstrap (secrets from `.env`, never committed):

   ```bash
   # Secrets from app .env — never committed
   docker compose exec -T postgres psql -U postgres -v ON_ERROR_STOP=1 <<EOSQL
   DO \$\$
   BEGIN
     IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '${APP_DB_USER}') THEN
       EXECUTE format('CREATE ROLE %I WITH LOGIN PASSWORD %L', '${APP_DB_USER}', '${APP_DB_PASSWORD}');
     END IF;
     IF NOT EXISTS (SELECT FROM pg_database WHERE datname = '${APP_DB_NAME}') THEN
       EXECUTE format('CREATE DATABASE %I OWNER %I', '${APP_DB_NAME}', '${APP_DB_USER}');
     END IF;
   END
   \$\$;
   EOSQL
   ```

   Or keep bootstrap logic in `database/bootstrap.sql` and pass credentials via env at runtime.

## Generic infra helper

`scripts/create-db.sh` creates an empty database by name (idempotent). It does **not** manage roles or passwords — use application bootstrap for that.

## Production / enterprise

For larger environments, manage roles and grants with Terraform, Ansible, Vault, or a Kubernetes operator — not init SQL in this repo.

## Anti-patterns

| Do not | Why |
|--------|-----|
| Put passwords in `postgres/init/*.sql` | Secrets belong in env / vault, not git |
| Bake `app_readonly`, `shop_user`, etc. into infra | Couples infra to one application |
| Rely on init scripts for role changes | Init runs only once on empty `PGDATA` |
