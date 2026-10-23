#!/usr/bin/env bash

DB_ENV=${1:-postgres}

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

export GOTRUE_DB_DRIVER="${GOTRUE_DB_DRIVER:-postgres}"
if [ -z "$GOTRUE_DB_DATABASE_URL" ]; then
    if [ "$GOTRUE_DB_DRIVER" = "mysql" ]; then
        export GOTRUE_DB_DATABASE_URL="mysql://supabase_auth_admin:root@tcp(localhost:3306)/$DB_ENV?parseTime=true&multiStatements=true"
    elif [ "$GOTRUE_DB_DRIVER" = "tidb" ]; then
        export GOTRUE_DB_DATABASE_URL="mysql://root:@tcp(localhost:4000)/$DB_ENV?parseTime=true&multiStatements=true"
    else
        export GOTRUE_DB_DATABASE_URL="postgres://supabase_auth_admin:root@localhost:5432/$DB_ENV"
    fi
fi
export GOTRUE_DB_MIGRATIONS_PATH=$DIR/../migrations

go run main.go migrate -c "$DIR/test.env" "${@:2}"
