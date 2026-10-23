#!/usr/bin/env bash

DB_ENV=${1:-postgres}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export GOTRUE_DB_DRIVER="${GOTRUE_DB_DRIVER:-postgres}"

ENV_FILE="$DIR/test.env"
if [ "$GOTRUE_DB_DRIVER" = "mysql" ]; then
    ENV_FILE="$DIR/test.mysql.env"
    export DATABASE_URL="${DATABASE_URL:-mysql://supabase_auth_admin:root@127.0.0.1:3306/$DB_ENV?parseTime=true&multiStatements=true}"
elif [ "$GOTRUE_DB_DRIVER" = "tidb" ]; then
    ENV_FILE="$DIR/test.tidb.env"
    export DATABASE_URL="${DATABASE_URL:-mysql://root:@127.0.0.1:4000/$DB_ENV?parseTime=true&multiStatements=true}"
else
    export DATABASE_URL="${DATABASE_URL:-postgres://supabase_auth_admin:root@localhost:5432/$DB_ENV}"
fi

export GOTRUE_DB_DATABASE_URL="$DATABASE_URL"
export GOTRUE_DB_MIGRATIONS_PATH=$DIR/../migrations

go run main.go migrate -c "$ENV_FILE" "${@:2}"
