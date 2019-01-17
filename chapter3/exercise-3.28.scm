#lang sicp

(#%require "common.scm")

;   Exercise 3.28
;   =============
;   
;   Define an or-gate as a primitive function box.  Your or-gate constructor
;   should be similar to and-gate.
;   
;   ------------------------------------------------------------------------
;   [Exercise 3.28]: http://sicp-book.com/book-Z-H-22.html#%_thm_3.28
;   3.3.4 A Simulator for Digital Circuits - p277
;   ------------------------------------------------------------------------

(-start- "3.28")

(prn "Non running code:

(define (or-gate a1 a2 output)
  (define (or-action-procedure)
    (let ((new-value
           (logical-or (get-signal a1) (get-signal a2))))
      (after-delay or-gate-delay
                   (lambda ()
                     (set-signal! output new-value)))))
  (add-action! a1 or-action-procedure)
  (add-action! a2 or-action-procedure)
  'ok)
")

(--end-- "3.28")
