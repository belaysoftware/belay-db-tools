#!/bin/sh
set -euo pipefail

TASK=${TASK:-backup}

while getopts "br:d:mp" option; do
    case $option in
        b)
            TASK=backup
            ;;
        r)
            TASK=restore
            FN=$OPTARG
            ;;
        d)
            DB_NAME=$OPTARG
            ;;
        m)
            TASK=mysql
            ;;
        p)
            TASK=psql
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
   esac
done

export PGHOST=${DB_SERVICE_HOST:-db}
export PGPORT=${DB_SERVICE_PORT:-5432}
export MYSQL_PORT=${DB_SERVICE_PORT:-3306}
export PGDATABASE=$DB_NAME
export PGUSER=${DB_USERNAME:-$DB_NAME}
export PGPASSWORD=${DB_PASSWORD:-$PGUSER}

export ROOT_USER=${ROOT_USER:-root}
export ROOT_PASSWORD=${ROOT_PASSWORD:-unknown}


backup() {
    D=`date +%Y-%m-%d`
    FN=$DB_NAME-$D.dump
    echo "Backing up pg://$PGHOST/$DB_NAME to $FN"
    pg_dump --format=c > "$FN" || mysqldump --host=$PGHOST --port=$MYSQL_PORT --user=$PGUSER --password=$PGPASSWORD $DB_NAME > "$FN"
    s3cmd --access_key=$AWS_S3_ACCESS_KEY_ID --secret_key=$AWS_S3_SECRET_ACCESS_KEY put "$FN" s3://$AWS_STORAGE_BUCKET_NAME/
}

restore() {
    s3cmd --access_key=$AWS_S3_ACCESS_KEY_ID --secret_key=$AWS_S3_SECRET_ACCESS_KEY --force get s3://$AWS_STORAGE_BUCKET_NAME/$FN
    pg_restore --clean --no-owner --no-privileges -vvv -d $PGDATABASE "$FN" || mysql --host=$PGHOST --port=$MYSQL_PORT --user=$PGUSER --password=$PGPASSWORD $DB_NAME < "$FN"
}

provision_mysql() {
    mysql --host=$PGHOST --port=$MYSQL_PORT --user=$ROOT_USER --password=$ROOT_PASSWORD <<- EOF
    create database if not exists \`$PGDATABASE\`;
    create user if not exists \`$PGUSER\` identified by '$PGPASSWORD';
    grant all on \`$PGDATABASE\`.* to \`$PGUSER\`;
EOF
}

provision_postgres() {
    export NEW_USER=${PGUSER}
    export NEW_PASSWORD=${PGPASSWORD}
    export PGPASSWORD=${ROOT_PASSWORD}
    export PGUSER=${ROOT_USER}
    export PGDATABASE=
    psql -tc "SELECT 1 FROM pg_user WHERE usename = '$NEW_USER'" | grep -q 1 || psql -c "create role \"$NEW_USER\" login password '$NEW_PASSWORD';"
    psql -tc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" | grep -q 1 || psql -c "create database \"$DB_NAME\" with owner '$NEW_USER';"
}

case $TASK in
    backup)
        backup
        ;;
    restore)
        restore
        ;;
    mysql)
        mysql --host=$PGHOST --port=$MYSQL_PORT --user=$PGUSER --password=$PGPASSWORD $DB_NAME
        ;;
    psql)
        psql
        ;;
    provision_mysql)
        provision_mysql
        ;;
    provision_postgres)
        provision_postgres
        ;;
    *)
        echo "Usage: $0 {-b|-r file_name} [-d db_name]"
        exit 1
        ;;
esac