-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION lsh;" to load this file. \quit

CREATE OR REPLACE FUNCTION lsh_dot(anyarray, anyarray)
    RETURNS float4
    AS '$libdir/lsh', 'dot'
    LANGUAGE C STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION lsh_gauss_vector(integer)
    RETURNS float4[]
    AS '$libdir/lsh', 'gauss_vector'
    LANGUAGE C STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION lsh_uniform_number(float4)
    RETURNS float4
    AS '$libdir/lsh', 'uniform_number'
    LANGUAGE C STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION lsh_hash_i(x float4[], w float4[], b float4, r float4)
    RETURNS integer
    LANGUAGE plpgsql IMMUTABLE STRICT
      AS $$
        DECLARE
          product float4;
          result integer;
        BEGIN
          product := lsh_dot(x, w);
          result := floor( (product + b) / r );
          RETURN(result);
        END;
      $$;

CREATE OR REPLACE FUNCTION lsh_hash(x float4[], table_name text, column_name text, outer_index integer)
    RETURNS integer[]
    LANGUAGE plpgsql IMMUTABLE STRICT
      AS $$
        DECLARE
          result_hash integer[] := '{}';
          select_params_template text := 'SELECT w, b, r FROM lsh_%s_%s
          WHERE outer_index = $1 ORDER BY inner_index';

          params RECORD;

          i integer := 1; -- for iterating
        BEGIN

          FOR params IN EXECUTE format(select_params_template, table_name, column_name)
          USING outer_index LOOP
            result_hash[i] := lsh_hash_i(x, params.w, params.b, params.r);
            i := i + 1;
          END LOOP;
          RETURN result_hash;
        END;
      $$;

CREATE OR REPLACE FUNCTION create_lsh_index(table_name text, column_name text, r float4)
    RETURNS text
    LANGUAGE plpgsql VOLATILE STRICT
      AS $$
        DECLARE
          index_table_template text := 'CREATE TABLE IF NOT EXISTS lsh_%s_%s (
            w float4[],
            b float4,
            r float4,
            inner_index integer,
            outer_index integer
          )';
          count_size_template text := 'SELECT count(*) FROM %s';
          insert_hash_template text := 'INSERT INTO lsh_%s_%s VALUES (
            $1, $2, $3, $4, $5
          )';
          range_template text := 'SELECT generate_series(1, %d)';
          vector_dim_template text := 'SELECT array_length(%s, 1) FROM %s LIMIT 1';

          create_index_template text := 'CREATE INDEX IF NOT EXISTS lsh_%s_%s_%s ON %s (lsh_hash(
            $1::float4[], ''$2''::text, ''$3''::text, $4
          ))';

          hash_dimention integer;
          hash_size integer;

          alpha_probability float4 := 0.9; -- FIXME hard code. Transform into parameters
          beta_probability float4 := 0.1;
          rho_constant float4;

          data_size float4;
          vector_length integer;

          w float4[];
          b float4;

          i integer := 0; -- for iterating
          j integer := 0;
        BEGIN
          EXECUTE format(count_size_template, table_name) INTO data_size;
          EXECUTE format(vector_dim_template, column_name, table_name) INTO vector_length;

          rho_constant := ln(1/alpha_probability) / ln(1/beta_probability);
          hash_dimention := ceil( ln(data_size) / ln( 1/beta_probability ) );
          hash_size := ceil( 2 * power(data_size, rho_constant) );

          EXECUTE format(index_table_template, table_name, column_name);

          WHILE i < hash_size LOOP
            j := 0;
            WHILE j < hash_dimention LOOP
              w := lsh_gauss_vector(vector_length);
              b := lsh_uniform_number(r);
              EXECUTE format(insert_hash_template, table_name, column_name)
              USING w, b, r, j, i;

              j := j + 1;
            END LOOP;

            EXECUTE format(create_index_template, table_name, column_name, i, table_name)
            USING column_name, table_name, column_name, i;
            i := i + 1;
          END LOOP;

          RETURN True;
        END;
      $$;

CREATE OR REPLACE FUNCTION lsh_nearest(x float4[], table_name text, column_name text)
    RETURNS integer[]
    LANGUAGE plpgsql IMMUTABLE STRICT
      AS $$
        DECLARE
          select_outer_indexes text := 'SELECT distinct outer_index FROM lsh_%s_%s';
          select_inner_filter text := ' SELECT * FROM %s where lsh_hash(
            %s::float4[], ''%s''::text, ''%s''::text, %s::integer
          ) = lsh_hash(
            %s::float4[], ''%s''::text, ''%s''::text, %s::integer
          ) ';
          result_query text := '';

          params RECORD;

          i integer := 0; -- for iterating
        BEGIN

          FOR params IN EXECUTE format(select_outer_indexes, table_name, column_name) LOOP
            if (i > 0) then
              result_query := result_query || ' UNION ';
            end if;
              result_query := result_query || format(select_inner_filter, table_name, x, table_name, 
                column_name, i, column_name, table_name, column_name, i);
            i := i + 1;
          END LOOP;
          RETURN result_query;
        END;
      $$;
