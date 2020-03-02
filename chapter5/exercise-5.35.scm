#lang sicp

(#%require "common.scm")

;   Exercise 5.35
;   =============
;   
;   What expression was compiled to produce the code shown in figure [5.18]?
;   
;   Figure:
;   
;   (assign val (op make-compiled-procedure) (label entry16)
;                                              (reg env))
;     (goto (label after-lambda15))
;   entry16
;     (assign env (op compiled-procedure-env) (reg proc))
;     (assign env
;             (op extend-environment) (const (x)) (reg argl) (reg env))
;     (assign proc (op lookup-variable-value) (const +) (reg env))
;     (save continue)
;     (save proc)
;     (save env)
;     (assign proc (op lookup-variable-value) (const g) (reg env))
;     (save proc)
;     (assign proc (op lookup-variable-value) (const +) (reg env))
;     (assign val (const 2))
;     (assign argl (op list) (reg val))
;     (assign val (op lookup-variable-value) (const x) (reg env))
;     (assign argl (op cons) (reg val) (reg argl))
;     (test (op primitive-procedure?) (reg proc))
;     (branch (label primitive-branch19))
;   compiled-branch18
;     (assign continue (label after-call17))
;     (assign val (op compiled-procedure-entry) (reg proc))
;     (goto (reg val))
;   primitive-branch19
;     (assign val (op apply-primitive-procedure) (reg proc) (reg argl))
;   after-call17
;     (assign argl (op list) (reg val))
;     (restore proc)
;     (test (op primitive-procedure?) (reg proc))
;     (branch (label primitive-branch22))
;   compiled-branch21
;     (assign continue (label after-call20))
;     (assign val (op compiled-procedure-entry) (reg proc))
;     (goto (reg val))
;   primitive-branch22
;     (assign val (op apply-primitive-procedure) (reg proc) (reg argl))
;   
;   Figure 5.18: An example of compiler output (continued on next page). See
;   exercise [5.35].
;   
;   Figure:
;   
;   after-call20
;     (assign argl (op list) (reg val))
;     (restore env)
;     (assign val (op lookup-variable-value) (const x) (reg env))
;     (assign argl (op cons) (reg val) (reg argl))
;     (restore proc)
;     (restore continue)
;     (test (op primitive-procedure?) (reg proc))
;     (branch (label primitive-branch25))
;   compiled-branch24
;     (assign val (op compiled-procedure-entry) (reg proc))
;     (goto (reg val))
;   primitive-branch25
;     (assign val (op apply-primitive-procedure) (reg proc) (reg argl))
;     (goto (reg continue))
;   after-call23
;   after-lambda15
;     (perform (op define-variable!) (const f) (reg val) (reg env))
;     (assign val (const ok))
;   
;   Figure 5.18: (continued)
;   
;   ------------------------------------------------------------------------
;   [Exercise 5.35]: http://sicp-book.com/book-Z-H-35.html#%_thm_5.35
;   [Figure 5.18]:   http://sicp-book.com/book-Z-H-35.html#%_fig_5.18
;   5.5.5 An Example of Compiled Code - p595
;   ------------------------------------------------------------------------

(-start- "5.35")

(define expression
  '(define (f x)
    (+ x (g (+ x 2)))))

(println
 "
The orignal expression is:

  " expression "

Here's the working:

      (assign val (op make-compiled-procedure) (label entry16)
                                                 (reg env))
        (goto (label after-lambda15))
      entry16
        (assign env (op compiled-procedure-env) (reg proc))
        (assign env
                (op extend-environment) (const (x)) (reg argl) (reg env))
(define (<self> x)

        (assign proc (op lookup-variable-value) (const +) (reg env))
(+

        (save continue)
        (save proc)
        (save env)
        (assign proc (op lookup-variable-value) (const g) (reg env))
(g

        (save proc)
        (assign proc (op lookup-variable-value) (const +) (reg env))
(+

        (assign val (const 2))
        (assign argl (op list) (reg val))
2

        (assign val (op lookup-variable-value) (const x) (reg env))
        (assign argl (op cons) (reg val) (reg argl))
x
        (test (op primitive-procedure?) (reg proc))
        (branch (label primitive-branch19))
      compiled-branch18
        (assign continue (label after-call17))
        (assign val (op compiled-procedure-entry) (reg proc))
        (goto (reg val))
      primitive-branch19
        (assign val (op apply-primitive-procedure) (reg proc) (reg argl))
)

      after-call17
        (assign argl (op list) (reg val))
        (restore proc)
        (test (op primitive-procedure?) (reg proc))
        (branch (label primitive-branch22))
      compiled-branch21
        (assign continue (label after-call20))
        (assign val (op compiled-procedure-entry) (reg proc))
        (goto (reg val))
      primitive-branch22
        (assign val (op apply-primitive-procedure) (reg proc) (reg argl))
)

      after-call20
        (assign argl (op list) (reg val))
        (restore env)
        (assign val (op lookup-variable-value) (const x) (reg env))
        (assign argl (op cons) (reg val) (reg argl))
x

        (restore proc)
        (restore continue)
        (test (op primitive-procedure?) (reg proc))
        (branch (label primitive-branch25))
      compiled-branch24
        (assign val (op compiled-procedure-entry) (reg proc))
        (goto (reg val))
      primitive-branch25
        (assign val (op apply-primitive-procedure) (reg proc) (reg argl))
        (goto (reg continue))
)

      after-call23
      after-lambda15
        (perform (op define-variable!) (const f) (reg val) (reg env))
        (assign val (const ok))
<self> = f

So it looks like the original expression is:

  (define (f x)
   (+ (g (+ 2 x)) x))

But the arguments are evaluated in reverse order so the original expression
was:

  (define (f x)
   (+ x (g (+ x 2))))

To demonstrate we can compile this expression to recreate the given
code:
")

(#%require "compiler-33.scm")

(compile
 expression
 'val
 'next)

(--end-- "5.35")
