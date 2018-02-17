#ifndef _SMLAR_H_
#define _SMLAR_H_

#include "postgres.h"
#include "utils/array.h"
#include "access/tupdesc.h"
#include "catalog/pg_collation.h"

typedef struct ProcTypeInfoData {
	Oid				typid;
	int16			typlen;
	bool			typbyval;
	char			typalign;

	// TODO: for support of composite type. Now, it does not work
	char			typtype;
	TupleDesc		tupDesc;
} ProcTypeInfoData;

typedef struct SimpleArray {
	Datum		   *elems;
	int				nelems;
  ProcTypeInfoData info;
} SimpleArray;


static float4 uniformNumber(double scale);
static float4 gaussNumber();

static SimpleArray	* ConvertToSimpleArray(Datum d);


#endif
