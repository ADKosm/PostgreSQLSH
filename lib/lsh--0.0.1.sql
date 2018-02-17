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

          hash_dimention integer;
          hash_size integer;

          alpha_probability float4 := 0.9; -- FIXME hard code. Transform into parameters
          betta_probability float4 := 0.1;
          rho_constant float4;

          data_size float4;
          vector_length integer;

          i integer := 0; -- for iterating
          j integer := 0;
        BEGIN
          EXECUTE format(count_size_template, table_name) INTO data_size;
          EXECUTE format(vector_dim_template, column_name, table_name) INTO vector_length;

          rho_constant := ln(1/alpha_probability) / ln(1/betta_probability);
          hash_dimention := ceil( ln(data_size) / ln( 1/betta_probability ) ) + 1;
          hash_size := ceil( 2 * power(data_size, rho_constant) );

          EXECUTE format(index_table_template, table_name, column_name);

          WHILE i < hash_size LOOP
            j := 0;
            WHILE j < hash_dimention LOOP
              EXECUTE format(insert_hash_template, table_name, column_name)
              USING lsh_gauss_vector(vector_length), lsh_uniform_number(r), r, j, i;

              j := j + 1;
            END LOOP;
            i := i + 1;
          END LOOP;

          RETURN True;
        END;
      $$;
