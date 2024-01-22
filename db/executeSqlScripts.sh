#!/bin/bash

# Define the directory to search in
DIRECTORY="db/sql/autoload"
# Name of docker container
CONTAINER="maincargoitem_backend-db-1"
# Name of database
DB_NAME="mci"
# Db user
DB_USER="postgres"


# Find all autoload files and loop through them
find "$DIRECTORY" -type f | while read file; do
    echo "File ${file} :"
    # Execute the file
    docker exec -i "${CONTAINER}" psql -U "${DB_USER}" -d "${DB_NAME}" < "${file}"
    echo "Done"
    echo ""
done
