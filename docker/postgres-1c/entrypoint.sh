#!/bin/bash
set -e

PGDATA="/var/lib/postgresql/data"

if [ ! -f "$PGDATA/postgresql.conf" ]; then
    echo "Initializing PostgreSQL database..."
    
    su - postgres -c "/usr/lib/postgresql/18/bin/initdb -D $PGDATA"
    
    cat >> $PGDATA/postgresql.conf <<EOF
shared_buffers = 256MB
max_connections = 100
listen_addresses = '*'
port = 5432
EOF
    
    cat >> $PGDATA/pg_hba.conf <<EOF
host all all 0.0.0.0/0 md5
host all all ::0/0 md5
EOF
    
    echo "PostgreSQL initialized successfully!"
fi

exec su - postgres -c "/usr/lib/postgresql/18/bin/postgres -D $PGDATA"