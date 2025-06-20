# Open Location Code PL/SQL

This is the pl/sql implementation of the Open Location Code.

The library file is in `pluscode_functions.sql`.

All functions are installed in the public Schema.

## Tests

Unit tests require [Docker](https://www.docker.com/) to be installed.

Download the `pluscode_functions.sql` and `tests_script_l.sql` files.

Start a [PostgreSQL Docker](https://hub.docker.com/_/postgres) image and copy the Open Location Code files to it:

1. Download and run a PostgreSQL image. Call it `pgtest` and run on port 5433:

    ```shell
    docker run --name pgtest -e POSTGRES_PASSWORD=postgres -d -p 5433:5432 postgres
    ```

1. Re-generate the encoding SQL test script using the current CSV data:

   ```shell
   ./update_encoding_tests.sh ../test_data/encoding.csv
   ```

1. Copy the Open Location Code files to the container and change the permissions to allow the `postgres` user to read them:

    ```shell
    docker cp pluscode_functions.sql pgtest:/pluscode_functions.sql
    docker cp tests_script_l.sql pgtest:/tests_script_l.sql
    docker cp test_encoding.sql pgtest:/tests_script_l.sql
    sudo docker exec pgtest chmod a+r *.sql
    ```

1. Execute the SQL that defines the functions in the db:

    ```shell
    docker exec -u postgres pgtest psql postgres postgres -f ./pluscode_functions.sql
    ```

1. Execute the test SQL scripts:

    ```shell
    docker exec -u postgres pgtest psql postgres postgres -f ./tests_script_l.sql
    docker exec -u postgres pgtest psql postgres postgres -f ./test_encoding.sql
    ```

    Test failures (in the encoding functions) will result in exceptions.

## Functions

### pluscode_encode()

```sql
pluscode_encode(latitude, longitude, codeLength) → {string}
```

Encode a location into an Open Location Code.

**Parameters:**

| Name | Type |
|------|------|
| `latitude` | `number` |
| `longitude` | `number` |
| `codeLength` | `number` |

### pluscode_decode()

```sql
pluscode_decode(code) → {codearea record}
```

Decodes an Open Location Code into its location coordinates.

**Parameters:**

| Name | Type |
|------|------|
| `code` | `string` |

**Returns:**

The `CodeArea` record.

### pluscode_shorten()

```sql
pluscode_shorten(code, latitude, longitude) → {string}
```

Remove characters from the start of an OLC code.

**Parameters:**

| Name | Type |
|------|------|
| `code` | `string` |
| `latitude` | `number` |
| `longitude` | `number` |

**Returns:**

The code, shortened as much as possible that it is still the closest matching
code to the reference location.

### pluscode_recoverNearest()

```sql
pluscode_recoverNearest(shortCode, referenceLatitude, referenceLongitude) → {string}
```

Recover the nearest matching code to a specified location.

**Parameters:**

| Name | Type |
|------|------|
| `shortCode` | `string` |
| `referenceLatitude` | `number` |
| `referenceLongitude` | `number` |

**Returns:**

The nearest matching full code to the reference location.
