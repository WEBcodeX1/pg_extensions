-- PREPARE TEST DATA

DROP TABLE "SQLPrepare"."Test1";

CREATE TABLE "SQLPrepare"."Test1" (
    "ID" bigserial NOT NULL,
    "Column1" integer NOT NULL DEFAULT 10,
    "Column2" varchar NOT NULL,
    "Column3" varchar NULL
);

ALTER TABLE ONLY "SQLPrepare"."Test1"
    ADD CONSTRAINT "Test1_pkey" PRIMARY KEY ("ID");

-- INSERT TEST DATA

INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (12, 'Col2-Data1',  'Col3-Data1');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (20, 'Col2-Data2',  'Col3-Data2');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (30, 'Col2-Data3',  'Col3-Data3');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (45, 'Col2-Data4',  'Col3-Data4');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (60, 'Col2-Data5',  'Col3-Data5');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (61, 'Col2-Data6',  'Col3-Data6');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (62, 'Col2-Data7',  'Col3-Data7');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (70, 'Col2-Data8',  'Col3-Data8');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (72, 'Col2-Data9',  'Col3-Data9');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (74, 'Col2-Data10', 'Col3-Data10');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (75, 'Col2-Data11', 'Col3-Data11');
INSERT INTO "SQLPrepare"."Test1" ("Column1", "Column2", "Column3") VALUES (76, 'Col2-Data12', 'Col3-Data12');

-- INSERT INTO Param AND Query TABLE

DELETE FROM "SQLPrepare"."Param";
DELETE FROM "SQLPrepare"."Query";

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

-- PREPARE QUERIES (1 TEST QUERY)

SELECT * FROM "SQLPrepare"."PrepareQueries"();

-- CHECK CALLING PREPARED QUERY

SELECT * FROM "SQLPrepare"."ExecuteQuery"('S', 'Test_Query_1', '{ "val1": 70, "val2": "Col2-Data8" }', '{"val1", "val2"}');

-- CLEANUP

DROP TABLE "SQLPrepare"."Test1";
