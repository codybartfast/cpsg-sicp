#lang sicp

(#%require "common.scm")

;   Exercise 3.20
;   =============
;
;   Draw environment diagrams to illustrate the evaluation of the sequence
;   of expressions
;
;   (define x (cons 1 2))
;   (define z (cons x x))
;   (set-car! (cdr z) 17)
;   (car x)
;   17
;
;   using the procedural implementation of pairs given above.  (Compare
;   exercise [3.11].)
;
;   ------------------------------------------------------------------------
;   [Exercise 3.20]: http://sicp-book.com/book-Z-H-22.html#%_thm_3.20
;   [Exercise 3.11]: http://sicp-book.com/book-Z-H-22.html#%_thm_3.11
;   3.3.1 Mutable List Structure - p261
;   ------------------------------------------------------------------------

(-start- "3.20")

(prn "It's tempting to use different symbols in the question's code so that:
    (define x (cons 1 2))
    (define z (cons x x))
becomes:
    (define a (cons 1 2))
    (define b (cons a a))
to avoid potential (human) confusion between the x and z used in the
question and the x used in the definition of cons and the z used in the
definition of car, cdr and set-cdr!.  But I suspect the re-use of symbols is
intentional to emphasise that they are different identifiers because they
are defined in different environments.


            para: x                                        para: z
            para: y              para: z      para: z      para: new-value
          (define (set-x!...    (z 'car)     (z 'cdr)     ((z 'set-car!)...
                ^                  ^            ^               ^
                │                  │            │               │
                @ @ ─┐             @ @ ─┐       @ @ ─┐          @ @ ─┐
                 ^   │              ^   │        ^   │           ^   │
global env ──┐   │   │              │   │        │   │           │   │
             v   │   v              │   v        │   v           │   v
┌──────────────────────────────────────────────────────────────────────────┐
│cons:───────────┘                  │            │               │         │
│car:───────────────────────────────┘            │               │         │
│cdr:────────────────────────────────────────────┘               │         │
│set-car!:───────────────────────────────────────────────────────┘         │
│                                                                          │
│(after calls to cons)                                                     │
│x:┐                                  z:┐                                  │
└──────────────────────────────────────────────────────────────────────────┘
 ┌─┘                             ^      │                               ^
 │                               │      │                               │
 │ ,───────────────────────────────────────────────<──┐                 │
 │/                              │      │             │                 │
 │ ,────────────────────────────────────────────<──┐  │                 │
 │/                              │      │          │  │                 │
 │                               │      │          │  │                 │
 │              call to cons     │      │          │  │   call to cons  │
 v      ┌────────────────────────┴──┐   │      ┌────────────────────────┴──┐
 │      │x: 1 (17 after set-x!)     │   │      │x:─┘  │                    │
 │ E1 ->│y: 2                       │   │ E2 ->│y:────┘                    │
 │      │set-x!:────────────────┐   │   │      │set-x!:────────────────┐   │
 │      │set-y!:─────────┐      │   │   │      │set-y!:─────────┐      │   │
 │      │dispatch:┐      │      │   │   │      │dispatch:┐      │      │   │
 │      └───────────────────────────┘   │      └───────────────────────────┘
 │                │  ^   │  ^   │  ^    │                │  ^   │  ^   │  ^
 ├──>─────────────┤  │   │  │   │  │    └───┬──>─────────┤  │   │  │   │  │
 │                v  │   v  │   v  │        │            v  │   v  │   v  │
 │               @ @ │  @ @ │  @ @ │        │           @ @ │  @ @ │  @ @ │
 │               │ └─┘  │ └─┘  │ └─┘        │           │ └─┘  │ └─┘  │ └─┘
 │               │      │      │            │           │      │      │
 │               ├──────────────────────────────────────┘      │      │
 │               │      └───────────────────────────┬──────────┘      │
 │               │             └────────────────────│───────────────┬─┘
 │               │                          │       │               │
 │               v                          │       v               v
 │          parameter: m                    │  parameter: v    parameter: v
 │   (define (dispatch m)                   │   (set! x v)      (set! y v)
 │        (cond ((eq? m 'car) x)            │
 │              ((eq? m 'cdr) y)            ^
 │              ((eq? m 'set-car!) set-x!)  │
 │              ((eq? m 'set-cdr!) set-y!)  │
 │              (else ... )))               │
 ^                                          │
 │                                          └─────────┐
 ├─────────┐                                          │
 │         │   call set-car!                          │
 │      ┌───────────────────────────┐                 │
 │      │z:┘                        │                 ^
 │ E3 ─>│new-value: 17              ├─> global env    │
 │      │                           │                 │
 │      └───────────────────────────┘                 │
 │                                                    │
 │                                        ┌───────────┘
 │                         call to cdr    │
 │                ┌───────────────────────────┐
 │                │z:─────────────────────┘   │
 │           E4 ─>│                           ├─> global env
 │                │                           │
 │                └───────────────────────────┘
 │
 │
 │                               call to z (dispatch)
 │                          ┌───────────────────────────┐
 │                          │m: 'cdr                    │
 │                     E5 ─>│                           ├─> E2
 │                          │                           │
 │                          └───────────────────────────┘
 │                           (returns 'x' (E1 dispatch))
 │
 ^
 │
 │                    call to z (dispatch)
 │                ┌───────────────────────────┐
 │                │m: 'set-car                │
 │           E6 ─>│                           ├─> E1
 │                │                           │
 │                └───────────────────────────┘
 │
 │
 │                                 call to set-x!
 │                          ┌───────────────────────────┐
 │                          │v: 17                      │
 │                     E7 ─>│                           ├─> E1
 │                          │                           │
 │                          └───────────────────────────┘
 │                                 (E1 modified)
 ^
 │
 └─────────┐
           │     call to car
        ┌───────────────────────────┐
        │z:┘                        │
   E8 ─>│                           ├─> global env
        │                           │
        └───────────────────────────┘


                      call to z (dispatch)
                  ┌───────────────────────────┐
                  │m: 'car                    │
             E9 ─>│                           ├─> E1
                  │                           │
                  └───────────────────────────┘
                         (returns 17)
")

(--end-- "3.20")

