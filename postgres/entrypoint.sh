#!/bin/bash

set -e

# Source environment variables
set -a
source /.env
set +a

# Create the $DB_TEMPLATE database
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "CREATE DATABASE $DB_TEMPLATE WITH TEMPLATE = template0;"
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "\\c $DB_TEMPLATE;"
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $DB_TEMPLATE -c "CREATE EXTENSION IF NOT EXISTS unaccent;"
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $DB_TEMPLATE -c "ALTER FUNCTION unaccent(text) IMMUTABLE;"

# Create Odoo user and give proper privileges
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "CREATE USER $DB_USER WITH PASSWORD '$DB_PASSWORD';"
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "ALTER USER $DB_USER CREATEDB;"
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "ALTER ROLE $DB_USER WITH SUPERUSER;"

# Give Odoo user access to copy $DB_TEMPLATE
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $DB_TEMPLATE TO $DB_USER;"
psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $DB_TEMPLATE -c "ALTER DATABASE $DB_TEMPLATE OWNER TO $DB_USER;"

# Check the USE_REDIS to add sentry to LOAD variable
if [[ $USE_PGADMIN == "true" ]]; then
    # Create PgAdmin user and give proper privileges
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "CREATE DATABASE $PGADMING_DB_NAME;"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "CREATE USER $PGADMING_DB_USER WITH PASSWORD '$PGADMIN_DB_PASSWORD';"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $PGADMING_DB_NAME TO $PGADMING_DB_USER;"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $PGADMING_DB_NAME -c "GRANT ALL PRIVILEGES ON SCHEMA public TO $PGADMING_DB_USER;"
    # Revoke Odoo user's access to pgadmin database
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "REVOKE CONNECT ON DATABASE $PGADMING_DB_NAME FROM $DB_USER;"
fi

# Function to clone and copy modules based on conditions
create_user_odoo() {
    local odoo_user=$1

    # Create Odoo user and give proper privileges
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "CREATE USER $odoo_user WITH PASSWORD '$DB_PASSWORD';"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "ALTER USER $odoo_user CREATEDB;"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "ALTER ROLE $odoo_user WITH SUPERUSER;"

    # Give Odoo user access to copy $DB_TEMPLATE
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "GRANT ALL PRIVILEGES ON DATABASE $DB_TEMPLATE TO $odoo_user;"
    psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $DB_TEMPLATE -c "ALTER DATABASE $DB_TEMPLATE OWNER TO $odoo_user;"

    echo -e "\e[32mCREATE USER ${odoo_user}\e[0m"

    # Check the USE_REDIS to add sentry to LOAD variable
    if [[ $USE_PGADMIN == "true" ]]; then
        # Revoke Odoo user's access to pgadmin database
        psql -p $POSTGRES_PORT -U $POSTGRES_MAIN_USER -d $POSTGRES_DB -c "REVOKE CONNECT ON DATABASE $PGADMING_DB_NAME FROM $odoo_user;"
    fi
}

for i in {12..20}; do
    create_user_odoo "$DB_USER"_"$i"
done

echo "Setup completed."
