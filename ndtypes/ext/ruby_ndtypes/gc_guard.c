/* Functions useful for interfacing shared rbuf objects with the Ruby GC. */
/* Author: Sameer Deshmukh (@v0dro) */
#include "gc_guard.h"

#define GC_GUARD_TABLE_NAME "__gc_guard_table"

static ID id_gc_guard_table;
extern VALUE cNDTypes;

/* Unregister an NDT object from the GC guard. */
void
gc_guard_unregister(NdtObject *ndt)
{
  VALUE table = rb_ivar_get(cNDTypes, id_gc_guard_table);
  rb_hash_delete(table, PTR2NUM(ndt));
}

/* Register a NDT-rbuf pair in the GC guard.  */
void
gc_guard_register(NdtObject *ndt, VALUE rbuf)
{
  VALUE table = rb_ivar_get(cNDTypes, id_gc_guard_table);
  rb_hash_aset(table, PTR2NUM(ndt), rbuf);
}

/* Initialize the global GC guard table. klass is a VALUE reprensenting NDTypes class. */
void
init_gc_guard(VALUE klass);
{
  id_gc_guard_table = rb_intern(GC_GUARD_TABLE_NAME);
  rb_ivar_set(klass, id_gc_guard_table, rb_hash_new());
}

