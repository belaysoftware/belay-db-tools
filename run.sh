#!/bin/sh
set -euo pipefail

TASK=${TASK:-backup}

while getopts "br:d:" option; do
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

backup() {
    D=`date +%Y-%m-%d`
    FN=$DB_NAME-$D.dump
    echo "Backing up pg://$PGHOST/$DB_NAME to $FN"
    pg_dump --format=c > "$FN" || mysqldump --host=$PGHOST --port=$MYSQL_PORT --user=$PGUSER --password=$PGPASSWORD $DB_NAME > "$FN"
    s3cmd --access_key=$AWS_S3_ACCESS_KEY_ID --secret_key=$AWS_S3_SECRET_ACCESS_KEY put "$FN" s3://$AWS_STORAGE_BUCKET_NAME/
}

restore() {
    s3cmd --access_key=$AWS_S3_ACCESS_KEY_ID --secret_key=$AWS_S3_SECRET_ACCESS_KEY --force get s3://$AWS_STORAGE_BUCKET_NAME/$FN
    pg_restore --create --clean --no-owner --no-privileges -vvv -d $PGDATABASE "$FN"
}

case $TASK in
    backup)
        backup
        ;;
    restore)
        restore
        ;;
    *)
        echo "Usage: $0 {-b|-r file_name} [-d db_name]"
        exit 1
        ;;
esac