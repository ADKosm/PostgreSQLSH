#include "postgres.h"
#include "fmgr.h"
#include "utils/builtins.h"

PG_MODULE_MAGIC;

PG_FUNCTION_INFO_V1(lsh);
Datum
lsh(PG_FUNCTION_ARGS)
{
    char text[7] = "bip-bup";
    elog(NOTICE, "Work in progress. It's robot.");

    PG_RETURN_TEXT_P(cstring_to_text(text));
}