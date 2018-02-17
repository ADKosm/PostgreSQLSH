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

#include "math.h"
#include "stdlib.h"
#include "time.h"
#include "stdio.h"

// FIXME: some of this imports are useless. Remove they

// ----------------------------

PG_MODULE_MAGIC;

static Oid FLOAT_ARRAY_ID = 700;
static bool isRandInit = false;

// ----------------------------

static ProcTypeInfoData
getInfo(Oid typid) {
  ProcTypeInfoData	info;

  info.typid = typid;
  info.typtype = get_typtype(typid);
  get_typlenbyvalalign(typid, &info.typlen, &info.typbyval, &info.typalign);

  return info;
}

static float4 gaussNumber() {
  double u, v, r, c;

  if(!isRandInit) {
    srand(time(NULL));
    isRandInit = true;
  }

  u = ((double) rand() / (RAND_MAX)) * 2 - 1;
  v = ((double) rand() / (RAND_MAX)) * 2 - 1;
  r = u * u + v * v;
  if (r == 0 || r > 1) return gaussNumber();
  c = sqrt(-2 * log(r) / r);

  return (float4) (u * c);
}

static float4 uniformNumber(double scale) {
  double u;

  u = ((double) rand() / (RAND_MAX)) * scale;

  return (float4) u;
}

static SimpleArray *
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

// --------------------------------

/*
Calculate dot product between two vectors
Needed for combute <x, w>
*/
PG_FUNCTION_INFO_V1(dot);
Datum dot(PG_FUNCTION_ARGS);
Datum
dot(PG_FUNCTION_ARGS) {
  SimpleArray *a = ConvertToSimpleArray(PG_GETARG_DATUM(0));
  SimpleArray *b = ConvertToSimpleArray(PG_GETARG_DATUM(1));

  // FIXME: validate arrays before computing (at least compare lenght)

  float4 result = 0;
  for(Datum *it_a = a->elems, *it_b = b->elems; (it_a - a->elems) < a->nelems; it_a++, it_b++) {
    float4 item_a = DatumGetFloat4(*it_a);
    float4 item_b = DatumGetFloat4(*it_b);

    result += item_a * item_b;
  }

  pfree(a);
  pfree(b);
  PG_RETURN_FLOAT4(result);
}

/*
Generate random vector with normal distribution N(0, 1)
Needed for generate parameter `w`
*/
PG_FUNCTION_INFO_V1(gauss_vector);
Datum gauss_vector(PG_FUNCTION_ARGS);
Datum
gauss_vector(PG_FUNCTION_ARGS) {
  int32 size = DatumGetInt32(PG_GETARG_DATUM(0));
  ProcTypeInfoData info = getInfo(FLOAT_ARRAY_ID);
  ArrayType* result;

  Datum* data = palloc(sizeof(Datum) * size);

  for(int32 i = 0; i < size; i++) {
    data[i] = Float4GetDatum(gaussNumber());
  }

  result = construct_array(data, size, info.typid, info.typlen,
    info.typbyval, info.typalign);

  PG_RETURN_ARRAYTYPE_P(result);
}

/*
Generate random number with uniform dictribution between 0 and scale
Needed for to generate parameter `b`
*/
PG_FUNCTION_INFO_V1(uniform_number);
Datum uniform_number(PG_FUNCTION_ARGS);
Datum
uniform_number(PG_FUNCTION_ARGS) {
  float4 limit = DatumGetFloat4(PG_GETARG_DATUM(0));
  float4 result = uniformNumber(limit);

  PG_RETURN_FLOAT4(result);
}
