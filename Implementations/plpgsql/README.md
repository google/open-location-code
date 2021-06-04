# Open Location Code PL/SQL
This is the pl/sql implementation of the Open Location Code.

The library file is in `pluscode_functions.sql`.

All functions are installed in the public Schema.

# Tests

Unit tests require docker,
[DockerDesktop](https://www.docker.com/)

Download the pluscode_functions.sql file.

Download the tests_script_l.sql file.

Before run the tests :

A - Upload and run postgresql image name : pgtest port 5433
`docker run --name pgtest -e POSTGRES_PASSWORD=postgres -d -p 5433:5432 postgres`

B - COPY file with olc functions in the container
`docker cp c:/path/to/file/pluscode_functions.sql pgtest:/pluscode_functions.sql`

C - COPY file with Tests in the container
`docker cp c:/path/to/file/tests_script_l.sql pgtest:/tests_script_l.sql`

D - Execute openlocation.sql in db
`docker exec -u postgres pgtest psql postgres postgres -f ./pluscode_functions.sql`

Then Execute tests script
`docker exec -u postgres pgtest psql postgres postgres -f ./tests_script_l.sql`


## pluscode_encode()

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

## pluscode_decode()

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


## pluscode_shorten()

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


## pluscode_recoverNearest()

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
