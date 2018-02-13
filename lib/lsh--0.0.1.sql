-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION lsh_index" to load this file. \quit

CREATE OR REPLACE FUNCTION lsh()
    RETURNS text
    AS '$libdir/lsh', 'lsh'
    LANGUAGE C IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION array_sum(anyarray)
    RETURNS float4
    AS '$libdir/lsh', 'array_sum'
    LANGUAGE C STRICT IMMUTABLE;