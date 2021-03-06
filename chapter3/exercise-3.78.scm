#lang sicp

(#%require "common.scm")

;   Exercise 3.78
;   =============
;   
;   Figure:
;   
;                       dy₀                 y₀
;                        |                  |  
;                        |                  |  
;                        v                  v  
;                  ┌────────────┐     ┌────────────┐  
;        ddy       │            │  dy │            │    y
;   ┌─────────────>│  integral  ├───┬─┤  integral  ├───┬──>
;   │              │            │   │ │            │   │
;   │              └────────────┘   │ └────────────┘   │
;   │                               │                  │
;   │                               │                  │
;   │              ┌────────────┐   │                  │
;   │              │            │   │                  │
;   │              │  scale: a  │<──┘                  │
;   │      ,-`│<───┤            │                      │
;   │   ,-`   │    └────────────┘                      │
;   └─<|  add │                                        │
;       `-,   │    ┌────────────┐                      │
;          `-,│<───┤            │                      │
;                  │  scale: b  │<─────────────────────┘
;                  │            │                     
;                  └────────────┘                     
;   
;   Figure 3.35: Signal-flow diagram for the solution to a second-order
;   linear differential equation.
;   
;   Consider the problem of designing a signal-processing system to study
;   the homogeneous second-order linear differential equation
;   
;   d²y     dy
;   ─── - a ── - by = 0
;   dt²     dt
;   
;   The output stream, modeling y, is generated by a network that contains a
;   loop. This is because the value of d²y/dt² depends upon the values of y
;   and dy/dt and both of these are determined by integrating d²y/dt².  The
;   diagram we would like to encode is shown in figure [3.35].  Write a
;   procedure solve-2nd that takes as arguments the constants a, b, and dt
;   and the initial values y₀ and dy₀ for y and dy/dt and generates the
;   stream of successive values of y.
;   
;   ------------------------------------------------------------------------
;   [Exercise 3.78]: http://sicp-book.com/book-Z-H-24.html#%_thm_3.78
;   [Figure 3.35]:   http://sicp-book.com/book-Z-H-24.html#%_fig_3.35
;   3.5.4 Streams and Delayed Evaluation - p348
;   ------------------------------------------------------------------------

(-start- "3.78")

(prn
 "
We're given:

   d²y     dy
   ─── - a ── - by = 0
   dt²     dt

This can be rearranged to tell us:
  ddy = b.y + a.dy

Also, by definition of differentials and integrals we know:
   y = (integral of dy) + (y initial)
  dy = (integral of ddy) + (dy initial)

Putting these circular definitions together:

(define (solve-2nd a b dt y0 dy0)
  (define y (integral (delay dy) y0 dt))
  (define dy (integral (delay ddy) dy0 dt))
  (define ddy
    (stream-add
     (stream-scale y b)
     (stream-scale dy a)))
  y)
")
(--end-- "3.78")

