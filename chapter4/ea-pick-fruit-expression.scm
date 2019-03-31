#lang sicp

;; basic expression for testing an evaluator.  Once derived expressions are
;; expanded it's the I think all special forms are covered.

;; The 'trace' is used to check that applicative evaluation is used by the
;; 'if' expressions.

(#%require "ea-eval-apply.scm")

(define pick-fruit
  '(lambda ()
     (define trace '())
     (define (get-apple)
       (set! trace (cons "'getting apple'" trace))
       "apple")
     (define (get-cherry)
       (set! trace (cons "'getting cherry'" trace))
       "cherry")
     (define (first-or-second first second which)
       (cond ((equal? which 'first) (first))
             (else (second))))
     (list
      (first-or-second get-apple get-cherry 'first)
      (first-or-second get-apple get-cherry 'not-first)
      trace)))
   

(define (check-fruit result)
  (display "  Got expected fruit: ")
  (display (and 
            (equal? "apple" (car result))
            (equal? "cherry" (cadr result))))
  (newline)
  (display "  Got expected trace: ")
  (display (equal?
            '("'getting cherry'" "'getting apple'")
            (caddr result)))
  (newline))

(display
 "Checking expression with eval from text:")(newline)
(check-fruit
 (apply (eval
         pick-fruit
         the-global-environment)
        '()))

(#%provide
 pick-fruit
 check-fruit)
