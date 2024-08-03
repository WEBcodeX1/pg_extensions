# PostgreSQL Extension *prep-queries*

PostgreSQL is able to *prepare* queries.

In detail: you are able to mark (prepare) a Parametrized SQL-Query. If done so, the client pq_lib only will
send query parameter data, not the whole query string to the database backend.

> Less network traffic! Better performance!

## Scaling Problem

```
SELECT
*
FROM
table1
WHERE
search_param1 = 'hello' AND search_param2 = 'world';
```

If not prepared, the **whole SQL string** will be sent to the backend, **for each** client request.

```
'hello', 'world'
```

With a *Prepared Query* only the **Parameter Values** will be transmitted.

## Preparing

To prepare a SQL Query manually, the following syntax is used:

```
PREPARE
"Test_Query_1" (integer,varchar)
AS
  SELECT
  *
  FROM
  "SQLPrepare"."Test1"
  WHERE
  "Column1" = $1 AND "Column2" = $2;
```

## Extension Module

The Extension Module will manage your Prepared Queries by storing them into internal System Tables.

**"SQLPrepare"."PrepareQueries"** Stored Procedure will handle all *Query Prepare*.<br>
**"SQLPrepare"."ExecuteQuery"** Stored Procedure will handle single *Query Execute / Result Processing*.

## Install

Unpack the extension .tar.bz2 and run Makefile / Tests.

```
make install && make installcheck
```

Connect to System Database and create your database,

```
psql -U postgres
CREATE DATABASE test;
```

Connect to your database and install the extension. Done.

```
psql -U postgres -d test
CREATE EXTENSION prep_queries;
```

## Example

The following demonstrates a working example.

- Generate Test Table
- Insert Test Data
- Insert Query into System Table "Query"
- Insert 2 Params into System Table "Param"
- Prepare Queries by calling "SQLPrepare"."PrepareQueries"() Procedure
- Execute Query and get JSON Result

### Test Table

```
CREATE TABLE "Test1" (
    "ID" bigserial NOT NULL,
    "Column1" integer NOT NULL DEFAULT 10,
    "Column2" varchar NOT NULL,
    "Column3" varchar NULL
);

ALTER TABLE ONLY "Test1"
    ADD CONSTRAINT "Test1_pkey" PRIMARY KEY ("ID");
```

### Test Table Data

```
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (12, 'Col2-Data1',  'Col3-Data1');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (20, 'Col2-Data2',  'Col3-Data2');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (30, 'Col2-Data3',  'Col3-Data3');
```

### Insert Query

```
INSERT INTO
"SQLPrepare"."Query" (
	"ID",
	"QueryID",
	"SQL"
)
VALUES (
	1,
	'Test_Query_1',
	'SELECT * FROM "SQLPrepare"."Test1" WHERE "Column1" = $1 AND "Column2" = $2'
);
```

### Insert Parameters

```
INSERT INTO
"SQLPrepare"."Param" (
	"QueryID",
	"Index",
	"Type"
)
VALUES (
	1,
	1,
	'integer'
);

INSERT INTO
"SQLPrepare"."Param" (
	"QueryID",
	"Index",
	"Type"
)
VALUES (
	1,
	2,
	'varchar'
);
```

### Update / Prepare Queries

```
SELECT * FROM "SQLPrepare"."PrepareQueries"();
```

### Execute Query

```
SELECT * FROM "SQLPrepare"."ExecuteQuery"('S', 'Test_Query_1', '{ "val1": 20, "val2": "Col2-Data2" }', '{"val1", "val2"}');
```
