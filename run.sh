#!/bin/bash
set -euo pipefail

TASK=${TASK:-backup}

while getopts "brd:" option; do
    case $option in
        b)
            TASK=backup
            ;;
        r)
            TASK=restore
            ;;
        d)
            DB_NAME=$OPTARG
            ;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
   esac
done

DB_SERVICE_HOST=${DB_SERVICE_HOST:-db}
DB_NAME=$DB_NAME
DB_USERNAME=${DB_USERNAME:-$DB_NAME}
DB_PASSWORD=${DB_PASSWORD:-$DB_USERNAME}

echo "$DB_PASSWORD"

backup() {
    echo "backup"
}

restore() {
    echo "restore"
}

case $TASK in
    backup)
        backup
        ;;
    restore)
        restore
        ;;
    *)
        echo "Usage: $0 {-b|-r} [-d db_name]"
        exit 1
        ;;
esac