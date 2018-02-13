#include "lsh.h"

#include "fmgr.h"
#include "access/genam.h"
#include "access/heapam.h"
#include "access/htup_details.h"
#include "access/nbtree.h"
#include "catalog/indexing.h"
#include "catalog/pg_am.h"
#include "catalog/pg_amproc.h"
#include "catalog/pg_cast.h"
#include "catalog/pg_opclass.h"
#include "catalog/pg_type.h"
#include "executor/spi.h"
#include "utils/catcache.h"
#include "utils/fmgroids.h"
#include "utils/lsyscache.h"
#include "utils/memutils.h"
#include "utils/tqual.h"
#include "utils/syscache.h"
#include "utils/typcache.h"
#include "utils/builtins.h"

// FIXME: some of this imports are useless. Remove they

PG_MODULE_MAGIC;

static ProcTypeInfoData
getInfo(Oid typid) {
  ProcTypeInfoData	info;

  info.typid = typid;
  info.typtype = get_typtype(typid);
  get_typlenbyvalalign(typid, &info.typlen, &info.typbyval, &info.typalign);

  return info;
}

SimpleArray *
ConvertToSimpleArray(Datum d) {
  ArrayType *a = DatumGetArrayTypeP(d);
  SimpleArray *s = palloc(sizeof(SimpleArray));

  ProcTypeInfoData info = getInfo(ARR_ELEMTYPE(a));
  s->info = info;
  deconstruct_array(a, info.typid,
						info.typlen, info.typbyval, info.typalign,
						&s->elems, NULL, &s->nelems);

  return s;
}


PG_FUNCTION_INFO_V1(array_sum);
Datum array_sum(PG_FUNCTION_ARGS);
Datum
array_sum(PG_FUNCTION_ARGS) {
  SimpleArray *s = ConvertToSimpleArray(PG_GETARG_DATUM(0));

  float4 result = 0;
  for(Datum *it = s->elems; (it - s->elems) < s->nelems; it++) {
    float4 item = DatumGetFloat4(*it);
    result += item;
  }

  PG_RETURN_FLOAT4(result);
}


PG_FUNCTION_INFO_V1(lsh);
Datum
lsh(PG_FUNCTION_ARGS) {
    char text[7] = "bip-bup";
    elog(NOTICE, "Work in progress. It's robot.");

    PG_RETURN_TEXT_P(cstring_to_text(text));
}
