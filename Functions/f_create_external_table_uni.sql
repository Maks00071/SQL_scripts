/*
* Универсальная функция закачки данных из внешнего источника в Greenplum:
*/

DROP FUNCTION IF EXISTS <schema_name>.f_create_external_table_uni(text, text, text, text, text, text);

CREATE OR REPLACE FUNCTION <schema_name>.f_create_external_table_uni(
        , p_schema_name text
        , p_table_name  text
        , p_hive_schema text
        , p_hive_table  text
        , p_wf_load_id  text
        , p_wf_id       text
    )
    RETURNS int4
    LANGUAGE plpgsql
    VOLATILE

AS $func$
    DECLARE
        v_drop_ext_table text;
        v_sql           text;
        column_record   record;
        var             integer default 1;
        attr_string     text default '';
    BEGIN
        -- удаляем внешнюю таблицу, если она существует
        v_drop_ext_table := 'DROP EXTERNAL TABLE IF EXISTS ' ||p_schema_name||'.'||p_table_name||'_pxf;';
        EXECUTE v_drop_ext_table;

        -- создаем набор атрибутов с размерностью по DDL таблицы-приемника
        FOR column_record IN
            SELECT
                , pg_attribute.attname AS column_name
                , pg_catalog.format_type(pg_attribute.atttypid, pg_attribute.atttypmod) AS data_type
            FROM pg_catalog.pg_attribute
            INNER JOIN pg_catalog.pg_class
                ON pg_class.oid = pg_attribute.attrelid
            INNER JOIN pg_catalog.pg_namespace
                ON pg_namespace.oid = pg_class.relnamespace
            WHERE pg_attribute.attnum > 0
                AND NOT pg_attribute.attisdropped
                AND pg_namespace.nspname = p_schema_name
                AND pg_class.relname = p_table_name
            ORDER BY attnum ASC
        LOOP
            IF var = 1 THEN
                var := var + 1;
                attr_string := attr_string || column_record.column_name || ' ' || column_record.data_type;
            ELSE
                var := var + 1;
                attr_string := attr_string || ',' || column_record.column_name || ' ' || column_record.data_type;
            END IF;
        END LOOP;

        -- создаем внешнюю таблицу
        v_sql := 'CREATE EXTERNAL TABLE ' ||p_schema_name||'.'||p_table_name||'_pxf ('||attr_string||')
                    LOCATION (''pxf://'||p_hive_schema||'.'||p_hive_table|| '?profile=hive&server='||<pxf_server_host>||'
                    ) ON ALL
                    FORMAT ''CUSTOM'' ( FORMATTER=''pxfwritable_import'' )
                    ENCODING ''UTF8'';';
        EXECUTE v_sql;

        -- можно добавить блок обработки ошибок

        -- возвращаем 1 - флаг, что таблица создалась
        return 1;

    END;
$func$
EXECUTE ON ANY;

























