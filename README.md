# About

Image that include s3cmd and postgres client, can back and restore databases
from within k8s directly to and from storage buckets.

# Usage

```
FROM ghcr.io/belaysoftware/belay-db-backup
```

Set the following environment variables:

- `DB_SERVICE_HOST` (defaults to "db")
- `DB_NAME`
- `DB_USERNAME` (defaults to value of _DB_NAME_)
- `DB_PASSWORD` (defaults to value of _DB_PASSWORD_)
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`

Bucket host and region are setup for Linode's us-southeast-1 (Atlanta).
