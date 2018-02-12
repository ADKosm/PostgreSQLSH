-- complain if script is sourced in psql, rather than via CREATE EXTENSION
\echo Use "CREATE EXTENSION lsh_index" to load this file. \quit

CREATE FUNCTION lsh()
    RETURNS text
    AS '$libdir/lsh'
    LANGUAGE C IMMUTABLE STRICT;