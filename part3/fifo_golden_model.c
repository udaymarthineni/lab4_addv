/*
 * Golden reference model - asynchronous FIFO (Part 1)
 *
 * Mirrors the RTL parameters:  DSIZE = 8 bits, ASIZE = 4  -> DEPTH = 16.
 * This is an IDEAL (untimed) model: no clocks, no synchronizer latency.
 * Flags reflect true occupancy. The testbench/scoreboard must allow the
 * RTL's flags to lag by the synchronizer delay (see FR-13 in the spec).
 *
 * Build & run:  gcc -Wall -o fifo_model fifo_golden_model.c && ./fifo_model
 */
#include <stdio.h>
#include <stdint.h>
#include <string.h>

#define ASIZE        4
#define DEPTH        (1 << ASIZE)          /* 16 words                    */
#define DATA_BYTES   1                     /* DSIZE = 8 bits = 1 byte     */
#define PTR_MASK     ((1 << (ASIZE + 1)) - 1)  /* 5-bit pointers (wrap bit) */
#define ADDR_MASK    (DEPTH - 1)

#define ALMOST_FULL_LEVEL   ((DEPTH * 3) / 4)  /* 12, same as RTL */
#define ALMOST_EMPTY_LEVEL  (DEPTH / 4)        /* 4,  same as RTL */

typedef struct {
    uint8_t  mem[DEPTH][DATA_BYTES];  /* 2D storage: [address][byte]      */
    unsigned wptr;                    /* 5-bit write pointer (binary)     */
    unsigned rptr;                    /* 5-bit read pointer  (binary)     */
} fifo_t;

/* ---------- status ---------- */
static unsigned fifo_count(const fifo_t *f)
{
    return (f->wptr - f->rptr) & PTR_MASK;      /* occupancy 0..16 */
}
static int is_empty(const fifo_t *f)        { return fifo_count(f) == 0; }
static int is_full(const fifo_t *f)         { return fifo_count(f) == DEPTH; }
static int is_almost_full(const fifo_t *f)  { return fifo_count(f) == ALMOST_FULL_LEVEL; }
static int is_almost_empty(const fifo_t *f) { return fifo_count(f) == ALMOST_EMPTY_LEVEL; }

/* ---------- operations ---------- */
/* Reset: both pointers to 0 (joint reset). Memory is dead, so clear it. */
static void fifo_reset(fifo_t *f)
{
    memset(f, 0, sizeof(*f));
}

/* Write: ignored when full (like RTL). Returns 1 if accepted, 0 if dropped. */
static int push(fifo_t *f, uint8_t data)
{
    if (is_full(f)) return 0;
    f->mem[f->wptr & ADDR_MASK][0] = data;
    f->wptr = (f->wptr + 1) & PTR_MASK;
    return 1;
}

/* Peek: what rdata shows now (word at read pointer, not consumed). */
static uint8_t peek(const fifo_t *f)
{
    return f->mem[f->rptr & ADDR_MASK][0];
}

/* Read: ignored when empty. Returns 1 if accepted and fills *data. */
static int pop(fifo_t *f, uint8_t *data)
{
    if (is_empty(f)) return 0;
    *data = f->mem[f->rptr & ADDR_MASK][0];
    f->rptr = (f->rptr + 1) & PTR_MASK;
    return 1;
}

/* ---------- self-test ---------- */
static int errors = 0;
#define CHECK(cond, msg) do { if (!(cond)) { printf("FAIL: %s\n", msg); errors++; } } while (0)

int main(void)
{
    fifo_t f;
    uint8_t d;
    int i;

    fifo_reset(&f);
    CHECK(is_empty(&f) && !is_full(&f), "reset state");

    /* fill to full, check almost flags on the way */
    for (i = 0; i < DEPTH; i++) {
        CHECK(push(&f, (uint8_t)(0xA0 + i)), "push accepted");
        if (fifo_count(&f) == ALMOST_EMPTY_LEVEL) CHECK(is_almost_empty(&f), "almost_empty at 4");
        if (fifo_count(&f) == ALMOST_FULL_LEVEL)  CHECK(is_almost_full(&f),  "almost_full at 12");
    }
    CHECK(is_full(&f), "full at 16");
    CHECK(!push(&f, 0xFF), "push dropped when full");
    CHECK(fifo_count(&f) == DEPTH, "count unchanged after dropped push");

    /* drain, check order */
    for (i = 0; i < DEPTH; i++) {
        CHECK(peek(&f) == (uint8_t)(0xA0 + i), "peek matches next word");
        CHECK(pop(&f, &d) && d == (uint8_t)(0xA0 + i), "pop order");
    }
    CHECK(is_empty(&f), "empty after drain");
    CHECK(!pop(&f, &d), "pop dropped when empty");

    /* pointer wrap: many laps with mixed push/pop */
    for (i = 0; i < 1000; i++) {
        push(&f, (uint8_t)i);
        push(&f, (uint8_t)(i + 1));
        CHECK(pop(&f, &d), "pop in wrap test");
        CHECK(pop(&f, &d) && d == (uint8_t)(i + 1), "data order across wrap");
    }

    printf(errors ? "SELF-TEST FAILED (%d errors)\n" : "SELF-TEST PASSED\n", errors);
    return errors != 0;
}
