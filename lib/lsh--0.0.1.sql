-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION lsh_index" to load this file. \quit

CREATE OR REPLACE FUNCTION lsh()
    RETURNS text
    AS '$libdir/lsh', 'lsh'
    LANGUAGE C STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION array_sum(anyarray)
    RETURNS float4
    AS '$libdir/lsh', 'array_sum'
    LANGUAGE C STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION dot(anyarray, anyarray)
    RETURNS float4
    AS '$libdir/lsh', 'dot'
    LANGUAGE C STRICT IMMUTABLE;

CREATE OR REPLACE FUNCTION gauss_vector(integer)
    RETURNS float4[]
    AS '$libdir/lsh', 'gauss_vector'
    LANGUAGE C STRICT IMMUTABLE;
