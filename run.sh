#!/bin/bash
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

PGHOST=${DB_SERVICE_HOST:-db}
PGPORT=${DB_SERVICE_PORT:-5432}
PGDATABASE=$DB_NAME
PGUSER=${DB_USERNAME:-$DB_NAME}
PGPASSWORD=${DB_PASSWORD:-$DB_USERNAME}

backup() {
    D=`date +%Y-%m-%d`
    FN=$DB_NAME-$D.dump
    pg_dump --format=c > "$FN"
    s3cmd --access-key=$AWS_S3_ACCESS_KEY_ID --secret-key=$AWS_S3_SECRET_ACCESS_KEY put "$FN" s3://$AWS_STORAGE_BUCKET_NAME/
}

restore() {
    s3cmd --access-key=$AWS_S3_ACCESS_KEY_ID --secret-key=$AWS_S3_SECRET_ACCESS_KEY get s3://$AWS_STORAGE_BUCKET_NAME/$FN
    pg_restore --clean --create "$FN"
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