-- CREATE SCHEMA FOR SQLPrepare METADATA

CREATE SCHEMA "SQLPrepare";
ALTER SCHEMA "SQLPrepare" OWNER TO postgres;

-- CREATE TABLES FOR QUERY and QUERY_PARAM

CREATE TABLE "SQLPrepare"."Param" (
    "ID" bigint NOT NULL,
    "QueryID" bigint NOT NULL,
    "Index" smallint NOT NULL,
    "Type" text NOT NULL
);

ALTER TABLE "SQLPrepare"."Param" OWNER TO postgres;

CREATE SEQUENCE "SQLPrepare"."Param_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "SQLPrepare"."Param_ID_seq" OWNER TO postgres;

ALTER SEQUENCE "SQLPrepare"."Param_ID_seq" OWNED BY "SQLPrepare"."Param"."ID";

CREATE TABLE "SQLPrepare"."Query" (
    "ID" bigint NOT NULL,
    "QueryID" character varying NOT NULL,
    "SQL" text NOT NULL
);

ALTER TABLE ONLY "SQLPrepare"."Query"
    ADD CONSTRAINT "Query_pkey" PRIMARY KEY ("ID");

ALTER TABLE "SQLPrepare"."Query" OWNER TO postgres;

CREATE SEQUENCE "SQLPrepare"."Query_ID_seq"
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;

ALTER TABLE "SQLPrepare"."Query_ID_seq" OWNER TO postgres;

ALTER SEQUENCE "SQLPrepare"."Query_ID_seq" OWNED BY "SQLPrepare"."Query"."ID";

ALTER TABLE ONLY "SQLPrepare"."Param"
    ADD CONSTRAINT "Param_pkey" PRIMARY KEY ("ID");

ALTER TABLE ONLY "SQLPrepare"."Param"
    ADD CONSTRAINT "SQLPrepareQueryFK" FOREIGN KEY ("QueryID") REFERENCES "SQLPrepare"."Query"("ID") ON UPDATE CASCADE ON DELETE CASCADE;

CREATE UNIQUE INDEX "SQLPrepareParamUniqueIndex" ON "SQLPrepare"."Param" USING btree ("QueryID", "Index");
CREATE UNIQUE INDEX "SQLPrepareQueryUniqueIndex" ON "SQLPrepare"."Query" USING btree ("QueryID");

ALTER TABLE ONLY "SQLPrepare"."Param" ALTER COLUMN "ID" SET DEFAULT nextval('"SQLPrepare"."Param_ID_seq"'::regclass);
ALTER TABLE ONLY "SQLPrepare"."Query" ALTER COLUMN "ID" SET DEFAULT nextval('"SQLPrepare"."Query_ID_seq"'::regclass);


-- CREATE PROCESSING FUNCTIONS

CREATE FUNCTION "SQLPrepare"."ExecuteQuery"(character, character varying, json, character varying[]) RETURNS json
    LANGUAGE plpgsql
    AS $_$

DECLARE

P_Type					ALIAS FOR $1;
P_QueryID				ALIAS FOR $2;
P_JSON_RequestData			ALIAS FOR $3;
P_JSON_Params				ALIAS FOR $4;

SQLStatementJSON			text;
SQLStatementParams 			text;
SQLStatementTMPTable 			text;

Params					text;
ParamValue				text;

Element					varchar;
TmpTableName				varchar;

R_JSON					json;

BEGIN

	SQLStatementParams := 'EXECUTE "' || P_QueryID || '"';

	Params := '(';

	FOREACH Element IN ARRAY P_JSON_Params
	LOOP

		Element = trim(both '''' FROM Element);
		ParamValue := P_JSON_RequestData::json->>Element;

		IF char_length(ParamValue) = 0 OR ParamValue IS NULL THEN
			Params := Params || 'NULL';
		ELSE
			Params := Params || '''' || ParamValue || '''';
		END IF;

		Params := Params || ',';

	END LOOP;

	Params = trim(trailing ',' FROM Params);
	Params = Params || ')';

	SQLStatementParams := SQLStatementParams || Params;
	RAISE NOTICE 'SQLStatementParams:%', SQLStatementParams;

	TmpTableName = '"' || P_QueryID || '__Result"';

	IF P_Type = 'S' THEN

		SQLStatementTMPTable := '
		CREATE TEMPORARY TABLE ' || TmpTableName || ' ON COMMIT DROP ' || '
		AS ' || SQLStatementParams;

		EXECUTE SQLStatementTMPTable;

	END IF;

	IF P_Type = 'I' THEN

		EXECUTE SQLStatementParams;

		SQLStatementTMPTable := '
		CREATE TEMPORARY TABLE ' || TmpTableName || ' ON COMMIT DROP ' || '
		AS SELECT lastval() AS "ID"';

		EXECUTE SQLStatementTMPTable;
	END IF;

	IF P_Type = 'U' OR P_Type = 'D' THEN

		EXECUTE SQLStatementParams;

		SQLStatementTMPTable := '
		CREATE TEMPORARY TABLE ' || TmpTableName || ' ON COMMIT DROP ' || '
		AS SELECT ''None''::varchar AS "Result"';

		EXECUTE SQLStatementTMPTable;
	END IF;

	SQLStatementJSON = '
	SELECT
	array_to_json(array_agg(row_to_json(t)))
	FROM
	(
		SELECT * FROM ' || TmpTableName || '
	) t';

	EXECUTE SQLStatementJSON INTO R_JSON;

	IF R_JSON IS NULL THEN
		R_JSON := '{}';
	END IF;

	RAISE NOTICE 'Return JSON:%', R_JSON;

RETURN R_JSON;
END;
$_$;

ALTER FUNCTION "SQLPrepare"."ExecuteQuery"(character, character varying, json, character varying[]) OWNER TO postgres;


CREATE FUNCTION "SQLPrepare"."PrepareQueries"() RETURNS boolean
    LANGUAGE plpgsql
    AS $$

DECLARE

QueryRecord record;
QueryParamRecord record;
SQLStatement text;
ParamString text;

BEGIN
	FOR QueryRecord IN
		SELECT
		*
		FROM
		"SQLPrepare"."Query"
		LOOP

			SQLStatement := 'PREPARE "' || QueryRecord."QueryID"  || '" (';

			ParamString := '';

			FOR QueryParamRecord IN
				SELECT
				*
				FROM
				"SQLPrepare"."Param"
				WHERE
				"QueryID" = QueryRecord."ID"
				ORDER BY
				"Index" ASC
				LOOP
					ParamString := ParamString || QueryParamRecord."Type" || ',';
				END LOOP;

			ParamString := trim(trailing ',' FROM ParamString);

			SQLStatement := SQLStatement || ParamString || ') AS ' || QueryRecord."SQL" || ';';

			RAISE NOTICE 'PrepareQuery:%', SQLStatement;

			EXECUTE SQLStatement;
		END LOOP;
	RETURN true;
END;
$$;


ALTER FUNCTION "SQLPrepare"."PrepareQueries"() OWNER TO postgres;
