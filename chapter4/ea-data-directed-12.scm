#lang sicp

;; This is the Ex 4.11 evaluator modified with the frame implementation
;; abstracted via frame specific procedures for exercise 4.12.

;; 'Logging' for debug use ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define debug false)
(define (log . parts)
  (cond (debug
         (for-each display parts)
         (newline))))

;; Data-Directed Eval ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(#%require "ea-underlying-apply.scm")
(#%require "ea-evaluators.scm")

(define expression-type car)

(define (eval exp env)
  (log "evaluating: " exp)
  (cond
    ((self-evaluating? exp) exp)
    ((variable? exp) (lookup-variable-value exp env))
    ((quoted? exp) (text-of-quotation exp))
    (else
     (if (pair? exp)
         (let ((evaluator (get 'eval (expression-type exp))))
           (if evaluator
               (evaluator exp env)
               (begin
                 (log "about to apply: " exp)
                 (apply (eval (operator exp) env)
                        (list-of-values (operands exp) env)))))
         ((error "Unknown expression type -- EVAL" exp))))))

(define (put-evaluators)
  (define (eval-lambda exp env)
    (make-procedure (lambda-parameters exp)
                    (lambda-body exp)
                    env))
  (define (eval-begin exp env)
    (eval-sequence (begin-actions exp) env))
  (define (eval-cond exp env)
    (eval (cond->if exp) env))

  (put 'eval 'set! eval-assignment)
  (put 'eval 'define eval-definition)
  (put 'eval 'if eval-if)
  (put 'eval 'lambda eval-lambda)
  (put 'eval 'begin eval-begin)
  (put 'eval 'cond eval-cond))
                 
;; Unchanged from ea-text ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (apply procedure arguments)
  (cond ((primitive-procedure? procedure)
         (apply-primitive-procedure procedure arguments))
        ((compound-procedure? procedure)
         (eval-sequence
          (procedure-body procedure)
          (extend-environment
           (procedure-parameters procedure)
           arguments
           (procedure-environment procedure))))
        (else
         (error
          "Unknown procedure type -- APPLY" procedure))))

(define (list-of-values exps env)
  (if (no-operands? exps)
      '()
      (cons (eval (first-operand exps) env)
            (list-of-values (rest-operands exps) env))))

(define (eval-if exp env)
  (if (true? (eval (if-predicate exp) env))
      (eval (if-consequent exp) env)
      (eval (if-alternative exp) env)))

(define (eval-sequence exps env)
  (cond ((last-exp? exps) (eval (first-exp exps) env))
        (else (eval (first-exp exps) env)
              (eval-sequence (rest-exps exps) env))))

(define (eval-assignment exp env)
  (set-variable-value! (assignment-variable exp)
                       (eval (assignment-value exp) env)
                       env)
  'ok)

(define (eval-definition exp env)
  (define-variable! (definition-variable exp)
                    (eval (definition-value exp) env)
                    env))

(define (self-evaluating? exp)
  (cond ((number? exp) true)
        ((string? exp) true)
        ((equal? exp 'undefined) true)  ;; extra
        ((boolean? exp) true)
        (else false)))

(define (variable? exp) (symbol? exp))

(define (quoted? exp)
  (tagged-list? exp 'quote))

(define (text-of-quotation exp) (cadr exp))

(define (tex-of-quotation exp) (cadr exp))

(define (tagged-list? exp tag)
  (if (pair? exp)
      (eq? (car exp) tag)
      false))

(define (assignment? exp)
  (tagged-list? exp 'set!))
(define (assignment-variable exp) (cadr exp))
(define (assignment-value exp) (caddr exp))

(define (definition? exp)
  (tagged-list? exp 'define))
(define (definition-variable exp)
  (if (symbol? (cadr exp))
      (cadr exp)
      (caadr exp)))
(define (definition-value exp)
  (if (symbol? (cadr exp))
      (caddr exp)
      (make-lambda (cdadr exp)   ; formal parameters
                   (cddr exp)))) ; body

(define (lambda? exp) (tagged-list? exp 'lambda))
(define (lambda-parameters exp) (cadr exp))
(define (lambda-body exp) (cddr exp))

(define (make-lambda parameters body)
  (cons 'lambda (cons parameters body)))

(define (if? exp) (tagged-list? exp 'if))
(define (if-predicate exp) (cadr exp))
(define (if-consequent exp) (caddr exp))
(define (if-alternative exp)
  (if (not (null? (cdddr exp)))
      (cadddr exp)
      'false))

(define (make-if predicate consequent alternative)
  (list 'if predicate consequent alternative))

(define (begin? exp) (tagged-list? exp 'begin))
(define (begin-actions exp) (cdr exp))
(define (last-exp? seq) (null? (cdr seq)))
(define (first-exp seq) (car seq))
(define (rest-exps seq) (cdr seq))

(define (sequence->exp seq)
  (cond ((null? seq) seq)
        ((last-exp? seq) (first-exp seq))
        (else (make-begin seq))))
(define (make-begin seq) (cons 'begin seq))

(define (application? exp) (pair? exp))
(define (operator exp) (car exp))
(define (operands exp) (cdr exp))
(define (no-operands? ops) (null? ops))
(define (first-operand ops) (car ops))
(define (rest-operands ops) (cdr ops))

(define (cond? exp) (tagged-list? exp 'cond))
(define (cond-clauses exp) (cdr exp))
(define (cond-else-clause? clause)
  (eq? (cond-predicate clause) 'else))
(define (cond-predicate clause) (car clause))
(define (cond-actions clause) (cdr clause))
(define (cond->if exp)
  (expand-clauses (cond-clauses exp)))

(define (expand-clauses clauses)
  (if (null? clauses)
      'false
      (let ((first (car clauses))
            (rest (cdr clauses)))
        (if (cond-else-clause? first)
            (if (null? rest)
                (sequence->exp (cond-actions first))
                (error "ELSE clause isn't last -- COND-IF"
                       clauses))
            (make-if (cond-predicate first)
                     (sequence->exp (cond-actions first))
                     (expand-clauses rest))))))

(define (true? x)
  (not (eq? x false)))
(define (false? x)
  (eq? x false))

(define (make-procedure parameters body env)
  (list 'procedure parameters body env))
(define (compound-procedure? p)
  (tagged-list? p 'procedure))
(define (procedure-parameters p) (cadr  p))
(define (procedure-body p) (caddr p))
(define (procedure-environment p) (cadddr p))

(define (enclosing-environment env) (cdr env))
(define the-empty-environment '())
(define (first-frame env) (car env))

;; Frame stuff - these should be the only procs with knowledge of the frame
;; structure

(define (make-frame variables values)
  (define frame (list '*frame*))
  (define (iter vars vals)
    (cond ((pair? vars)
           (add-binding-to-frame! (car vars) (car vals) frame)
           (iter (cdr vars) (cdr vals)))
          (else frame)))
  (iter variables values))

(define (add-binding-to-frame! var val frame)
  (set-cdr! frame (cons (cons var val) (cdr frame))))

(define (get-frame-val var frame)
  (define (scan frame-pairs)
    (cond ((null? frame-pairs) #f)
          ((eq? var (car (car frame-pairs)))
           ;; value put in a list becuase value could
           ;; be #f (or whatever else we return in the
           ;; case we don't find the var).
           (list (cdr (car frame-pairs))))
          (else (scan (cdr frame-pairs)))))
  (scan (cdr frame)))

(define (set-frame-val! var val frame)
  (define (scan frame-pairs)
    (cond ((null? frame-pairs) #f)
          ((eq? var (car (car frame-pairs)))
           (set-cdr! (car frame-pairs) val)
           #t)
          (else (scan (cdr frame-pairs)))))
  (scan (cdr frame)))

;; end frame interface

;; convenience method for iterating over the separate frames
(define (scan-env env f)
  (define (env-loop env)
    (if (eq? env the-empty-environment)
        #f
        (let ((rslt (f (first-frame env))))        
          (if  rslt
               rslt
               (env-loop (enclosing-environment env))))))
  (env-loop env))

(define (extend-environment vars vals base-env)
  (if (= (length vars) (length vals))
      (cons (make-frame vars vals) base-env)
      (if (< (length vars) (length vals))
          (error "Too many arguments supplied" vars vals)
          (error "Too few arguments supplied" vars vals))))

(define (lookup-variable-value var env)
  (let ((rslt (scan-env env
                        (lambda (frame)
                          (get-frame-val var frame)))))
    (if rslt
        (car rslt)
        (error "Unbound variable:" var))))
 
(define (set-variable-value! var val env)
  (if (not (scan-env env
                     (lambda (frame)
                       (set-frame-val! var val frame))))
      (error "Unbound variable -- SET!:" var)))        

(define (define-variable! var val env)
  (let ((frame (first-frame env)))
    (if (not (set-frame-val! var val frame))
        (add-binding-to-frame! var val frame))))


;;list of primitives directly mapped to underlying apply
(define primitive-procedures
  (list
   (cons '* *)
   (cons '+ +)
   (cons '- -) ;;
   (cons '> >) ;;
   (cons 'car car)
   (cons 'cdr cdr)
   (cons 'cons cons)
   (cons 'equal? equal?)
   (cons 'list list)
   (cons 'null? null?)
   (cons 'square (lambda (x) (* x x)))
   (cons 'println (lambda (msg) (display msg)(newline)))))

(define primitive-procedure-names
  (map car primitive-procedures))

(define primitive-procedure-objects
  (map cdr primitive-procedures))

(define (primitive-procedure? proc)
  (define (iter procs)
    (if (null? procs)
        false
        (if (eq? (car procs) proc)
            true
            (iter (cdr procs)))))
  (iter primitive-procedure-objects))


(define (setup-environment)
  (let ((initial-env
         (extend-environment primitive-procedure-names
                             primitive-procedure-objects
                             the-empty-environment)))
    (define-variable! 'true true initial-env)
    (define-variable! 'false false initial-env)
    initial-env))
(define the-global-environment (setup-environment))

(define (apply-primitive-procedure proc args)
  (if (primitive-procedure? proc)
      (underlying-apply proc args)
      (error "APPLY PRIMITIVE - unknown procedure" proc)))

(#%provide (all-defined)
           put)


