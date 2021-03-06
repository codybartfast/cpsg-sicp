#lang sicp

;; analysing-24 with amb support added for Ex 4.50

;; 'Logging' for debug use ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define debug false)

(define (log . parts)
  (if debug
      (underlying-apply writeln parts)))

(define (writeln . parts)
  (for-each display parts)
  (newline))

;; Data-Directed Analyzis ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(#%require "ea-underlying-apply.scm")
(#%require "ea-analyzers.scm")

(define expression-type car)

(define (analyze exp)
  (log "analyzing: " exp)
  (cond
    ((self-evaluating? exp) 
     (analyze-self-evaluating exp))
    ((quoted? exp) (analyze-quoted exp))
    ((variable? exp) (analyze-variable exp))
    (else
     (if (pair? exp)
         (let ((analyzer (get 'analyze (expression-type exp))))
           (log exp)
           (if analyzer
               (analyzer exp)
               (analyze-application exp)))
         ((error "Unknown expression type -- ANALYSE" exp))))))

(define (put-analyzers)
  (define (analyze-begin exp)
    (analyze-sequence (begin-actions exp)))
  (define (analyze-cond exp)
    (analyze (cond->if exp)))

  (put 'analyze 'set! analyze-assignment)
  (put 'analyze 'permanent-set! analyze-permanent-assignment)
  (put 'analyze 'define analyze-definition)
  (put 'analyze 'if analyze-if)
  (put 'analyze 'lambda analyze-lambda)
  (put 'analyze 'begin analyze-begin)
  (put 'analyze 'cond analyze-cond)
  
  (put 'analyze 'and analyze-and)
  (put 'analyze 'or analyze-or)
  (put 'analyze 'let analyze-let)
  (put 'analyze 'let* analyze-let*)
  (put 'analyze 'letrec analyze-letrec)
  (put 'analyze 'unbind! analyze-unbind!)
  (put 'analyze 'delay analyze-delay)
  (put 'analyze 'force analyze-force)
  (put 'analyze 'cons-stream analyze-cons-stream)
  (put 'analyze 'stream-null? analyze-stream-null?)
  (put 'analyze 'stream-car analyze-stream-car)
  (put 'analyze 'stream-cdr analyze-stream-cdr)
  (put 'analyze 'amb analyze-amb)
  (put 'analyze 'ramb analyze-ramb)
  (put 'analyze 'if-fail analyze-if-fail)
  (put 'analyze 'require analyze-require)
  )

;; Added for amb

(define (amb-choices exp) (cdr exp))

(define (ambeval exp env succeed fail)
  ((analyze exp) env succeed fail))

;; convenience wrapper for ambeval
(define (eval exp)
  (ambeval
   exp
   the-global-environment
   (lambda (exp fail) exp)
   (lambda () 'eval-fail)))

;; Ex 4.54 require ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (require-predicate exp) (cadr exp))
      
(define (analyze-require exp)
  (let ((pproc (analyze (require-predicate exp))))
    (lambda (env succeed fail)
      (pproc env
             (lambda (pred-value fail2)
               (if (not pred-value)
                   (fail2)
                   (succeed 'ok fail2)))
             fail))))


;; Ex 4.50 ramb ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (make-amb choices)
  (cons 'amb choices))

(define (randomize-list list)
  (define (remove item list)
    (define (iter source target)
      (if (null? source)
          target
          (let ((head (car source)))
            (if (equal? head item)
                (iter (cdr source) target)
                (iter (cdr source) (cons head target))))))
    (iter list '()))
  (define (iter source target)
    (if (null? source)
        target
        (let ((chosen (list-ref source (random (length source)))))
          (iter (remove chosen source) (cons chosen target)))))
  (iter list '()))

(define (analyze-ramb exp)
  (analyze
   (make-amb (randomize-list (amb-choices exp)))))


;; Ex 4.51 if-fail ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define try-expr cadr)
(define fail-expr caddr)
(define (analyze-if-fail exp)
  (let ((tproc (analyze (try-expr exp)))
        (fproc (analyze (fail-expr exp))))
    (lambda (env succeed fail)
      (tproc env succeed (lambda () (fproc env succeed fail))))))

;; Add 'apply' as an alias for 'execute-application' so that previous
;; exercises don't neeed to be modified to be used with this implementation.
;; This may be the first use of a misleading alias for the sake of
;; convenience and backward compatibility in the history of computing.

(define (apply proc args) (execute-application proc args))
(define (put-evaluators) (put-analyzers))

;; Support for analyzing from book ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(define (analyze-self-evaluating exp)
  (lambda (env succeed fail)
    (succeed exp fail)))

(define (analyze-quoted exp)
  (let ((qval (text-of-quotation exp)))
    (lambda (env succeed fail)
      (succeed qval fail))))

(define (analyze-variable exp)
  (lambda (env succeed fail)
    (succeed (lookup-variable-value exp env)
             fail)))

(define (analyze-definition exp)
  (let ((var (definition-variable exp))
        (vproc (analyze (definition-value exp))))
    (lambda (env succeed fail)
      (vproc env
             (lambda (val fail2)
               (define-variable! var val env)
               (succeed 'ok fail2))
             fail))))

(define (analyze-assignment exp)
  (let ((var (assignment-variable exp))
        (vproc (analyze (assignment-value exp))))
    (lambda (env succeed fail)
      (vproc env
             (lambda (val fail2)        ; *1*
               (let ((old-value
                      (lookup-variable-value var env)))
                 (set-variable-value! var val env)
                 (succeed 'ok
                          (lambda ()    ; *2*
                            (set-variable-value! var
                                                 old-value
                                                 env)
                            (fail2)))))
             fail))))

(define (analyze-permanent-assignment exp)
  (let ((var (assignment-variable exp))
        (vproc (analyze (assignment-value exp))))
    (lambda (env succeed fail)
      (vproc env
             (lambda (val fail2)        ; *1*
               (set-variable-value! var val env)
               (succeed 'ok fail2))
             fail))))

(define (analyze-application exp)
  (let ((fproc (analyze (operator exp)))
        (aprocs (map analyze (operands exp))))
    (lambda (env succeed fail)
      (fproc env
             (lambda (proc fail2)
               (get-args aprocs
                         env
                         (lambda (args fail3)
                           (execute-application
                            proc args succeed fail3))
                         fail2))
             fail))))

(define (get-args aprocs env succeed fail)
  (if (null? aprocs)
      (succeed '() fail)
      ((car aprocs) env
                    ;; success continuation for this aproc
                    (lambda (arg fail2)
                      (get-args (cdr aprocs)
                                env
                                ;; success continuation for recursive
                                ;; call to get-args
                                (lambda (args fail3)
                                  (succeed (cons arg args)
                                           fail3))
                                fail2))
                    fail)))

(define (execute-application proc args succeed fail)
  (cond ((primitive-procedure? proc)
         (succeed (apply-primitive-procedure proc args)
                  fail))
        ((compound-procedure? proc)
         ((procedure-body proc)
          (extend-environment (procedure-parameters proc)
                              args
                              (procedure-environment proc))
          succeed
          fail))
        (else
         (error
          "Unknown procedure type -- EXECUTE-APPLICATION"
          proc))))

(define (analyze-amb exp)
  (let ((cprocs (map analyze (amb-choices exp))))
    (lambda (env succeed fail)
      (define (try-next choices)
        (if (null? choices)
            (fail)
            ((car choices) env
                           succeed
                           (lambda ()
                             (try-next (cdr choices))))))
      (try-next cprocs))))

(define (analyze-lambda exp)
  (let ((vars (lambda-parameters exp))
        (bproc (analyze-sequence (lambda-body exp))))
    (lambda (env succeed fail)
      (succeed (make-procedure vars bproc env)
               fail))))

(define (analyze-if exp)
  (let ((pproc (analyze (if-predicate exp)))
        (cproc (analyze (if-consequent exp)))
        (aproc (analyze (if-alternative exp))))
    (lambda (env succeed fail)
      (pproc env
             ;; success continuation for evaluating the predicate
             ;; to obtain pred-value
             (lambda (pred-value fail2)
               (if (true? pred-value)
                   (cproc env succeed fail2)
                   (aproc env succeed fail2)))
             ;; failure continuation for evaluating the predicate
             fail))))

(define (analyze-sequence exps)
  (define (sequentially a b)
    (lambda (env succeed fail)
      (a env
         ;; success continuation for calling a
         (lambda (a-value fail2)
           (b env succeed fail2))
         ;; failure continuation for calling a
         fail)))
  (define (loop first-proc rest-procs)
    (if (null? rest-procs)
        first-proc
        (loop (sequentially first-proc (car rest-procs))
              (cdr rest-procs))))
  (let ((procs (map analyze exps)))
    (if (null? procs)
        (error "Empty sequence -- ANALYZE"))
    (loop (car procs) (cdr procs))))

;; Shared by exercise extensions ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define make-call cons)
(define (make-definition name params body)
  (cons 'define
        (cons (cons name params)
              body)))

;; Ex 4.04 and, or ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define first-predicate cadr)
(define second-predicate caddr)

(define (analyze-and exp)
  (analyze 
   (make-if (first-predicate exp)
            (make-if (second-predicate exp)
                     true
                     false)
            false)))

(define (analyze-or exp)
  (analyze
   (make-if (first-predicate exp)
            true
            (make-if (second-predicate exp)
                     true
                     false))))

;; Ex 4.05 calling-cond ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (calling-cond? exp)
  (eq? (cadr exp) '=>))
(define calling-cond-actions cddr)

(define (clause->exp clause predicate-value)
  (if (calling-cond? clause)
      (make-call (sequence->exp (calling-cond-actions clause))
                 ;; ... with predicate value
                 (list predicate-value))
      (sequence->exp (cond-actions clause))))

;; Ex 4.06-4.08 let, let*, named-let, letrec;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; let helpers
(define let-name cadr)
(define (named-let? exp)
  (symbol? (let-name exp)))
(define (let-body exp)
  (if (named-let? exp)
      (cdddr exp)
      (cddr exp)))
(define (let-pairs exp)
  (if (named-let? exp)
      (caddr exp)
      (cadr exp)))

(define let-pair-id car)
(define let-pair-value cadr)
(define (let-params exp)
  (map let-pair-id
       (let-pairs exp)))
(define (let-values exp)
  (map let-pair-value
       (let-pairs exp)))

;; let, named-let
(define (let->combination exp )
  (if (named-let? exp)
      (make-begin
       (list
        (make-definition (let-name exp)
                         (let-params exp)
                         (let-body exp))
        (make-call (let-name exp)
                   (let-values exp))))
      (make-call
       (make-lambda (let-params exp)
                    (let-body exp))
       (let-values exp))))

(define (analyze-let exp)
  (analyze (let->combination exp)))

;; let*
(define (make-let pairs body)
  (cons 'let (cons pairs body)))

(define (let*->nested-lets exp)
  (define (wrap-lets pairs body)
    (make-let (list (car pairs))
              (if (pair? (cdr pairs))
                  (list (wrap-lets (cdr pairs) body))
                  body)))
  (let ((pairs (let-pairs exp)))
    (if (pair? pairs)
        (wrap-lets pairs (let-body exp))
        (make-let pairs (let-body exp)))))
        
(define (analyze-let* exp)
  (analyze (let*->nested-lets exp)))

;; letrec
(define (letrec->let exp)
  (make-let
   (map (lambda (pair) (list (let-pair-id pair) '*unassigned*))
        (let-pairs exp))
   (append (map (lambda (pair)
                  (list 'set! (let-pair-id pair) (let-pair-value pair)))
                (let-pairs exp))
           (let-body exp))))

(define (analyze-letrec exp)
  (analyze (letrec->let exp)))

;; Unbind! ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (remove-frame-var var frame)
  (define (scan frame-pairs)
    (let ((rest (cdr frame-pairs)))
      (cond ((null? rest)
             #f)
            ((eq? var (car (car rest)))
             (set-cdr! frame-pairs (cddr frame-pairs))
             #t)
            (else (scan (cdr frame-pairs))))))
  (scan frame))
              
(define (make-unbound! var env)
  (let ((frame (first-frame env)))
    (if (not (remove-frame-var var frame))
        (error "Unbound variable -- UNBIND!" var))))

(define (analyze-unbind! exp)
  (lambda (env)
    (make-unbound! (cadr exp) env)))

;; Stream primitives ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; delay
(define (delay->lambda exp)
  (make-lambda '() (cdr exp)))
(define (analyze-delay exp)
  (analyze (delay->lambda exp)))

;; force
(define (analyze-force exp)
  (analyze (cdr exp)))

;; cons-stream
(define (cons-stream->cons exp)
  (list 'cons (cadr exp) (list 'delay (caddr exp))))
(define (analyze-cons-stream exp)
  (analyze (cons-stream->cons exp)))

;; stream-null?
(define (stream-null?->null? exp)
  (cons 'null? (cdr exp)))
(define (analyze-stream-null? exp)
  (analyze (stream-null?->null? exp)))

;; stream-car
(define (analyze-stream-car exp)
  (analyze (cons 'car (cdr exp))))
  
;; stream-cdr
(define (analyze-stream-cdr exp)
  (analyze (list 'force (list 'cdr (cadr exp)))))

;; Mainly unchanged from ea-text ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(define (self-evaluating? exp)
  (cond ((number? exp) true)
        ((string? exp) true)
        ((equal? exp 'undefined) true)  ;; extra
        ((equal? exp '*unassigned*) true)  ;; extra
        ((boolean? exp) true)
        (else false)))

(define (variable? exp) (symbol? exp))

(define (quoted? exp)
  (tagged-list? exp 'quote))

(define (text-of-quotation exp) (cadr exp))

(define (tagged-list? exp tag)
  (if (pair? exp)
      (eq? (car exp) tag)
      false))

(define (assignment-variable exp) (cadr exp))
(define (assignment-value exp) (caddr exp))

(define (definition-variable exp)
  (if (symbol? (cadr exp))
      (cadr exp)
      (caadr exp)))
(define (definition-value exp)
  (if (symbol? (cadr exp))
      (caddr exp)
      (make-lambda (cdadr exp)   ; formal parameters
                   (cddr exp)))) ; body

(define (lambda-parameters exp) (cadr exp))
(define (lambda-body exp) (cddr exp))

(define (make-lambda parameters body)
  (cons 'lambda (cons parameters body)))

(define (if-predicate exp) (cadr exp))
(define (if-consequent exp) (caddr exp))
(define (if-alternative exp)
  (if (not (null? (cdddr exp)))
      (cadddr exp)
      'false))

(define (make-if predicate consequent alternative)
  (list 'if predicate consequent alternative))

(define (begin-actions exp) (cdr exp))
(define (last-exp? seq) (null? (cdr seq)))
(define (first-exp seq) (car seq))
(define (rest-exps seq) (cdr seq))

(define (sequence->exp seq)
  (cond ((null? seq) seq)
        ((last-exp? seq) (first-exp seq))
        (else (make-begin seq))))
(define (make-begin seq) (cons 'begin seq))

(define (operator exp) (car exp))
(define (operands exp) (cdr exp))

(define (cond-clauses exp) (cdr exp))
(define (cond-else-clause? clause)
  (eq? (cond-predicate clause) 'else))
(define (cond-predicate clause) (car clause))
(define (cond-actions clause) (cdr clause))
(define (cond->if exp)
  (expand-clauses (cond-clauses exp)))

;; Modified for Ex 4.05
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
            (let ((predicate-value (cond-predicate first)))
              (make-if predicate-value
                       (clause->exp first predicate-value)
                       (expand-clauses rest)))))))

(define (true? x)
  (not (eq? x false)))
(define (false? x)
  (eq? x false))

;(define (scan-out-defines exp)
;  (define (definition? exp)
;    (tagged-list? exp 'define))
;  (define (scan exp new-members vars)
;    (if (null? exp)
;        (cons new-members vars)
;        (let ((member (car exp)))
;          (if (definition? member)
;              (scan (cdr exp)
;                    (cons
;                     (list 'set!
;                           (definition-variable member)
;                           (definition-value member))
;                     new-members)
;                    (cons (definition-variable member) vars))
;              (scan (cdr exp)
;                    (cons member new-members)
;                    vars)))))
;  (let* ((scan-rslt (scan exp '() '()))
;         (new-body (reverse (car scan-rslt)))
;         (vars (reverse (cdr scan-rslt)))
;         (let-pairs (map (lambda (var) (list var '*unassigned*)) vars)))
;    (if (null? vars)
;        exp
;        (list (make-let let-pairs new-body)))))

(define (make-procedure parameters body env)
  (list 'procedure parameters body env))
  ;(list 'procedure parameters (scan-out-defines body) env))
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

;; shared proc for iterating over the separate frames
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
        (let ((val (car rslt)))
          (if (eq? val '*unassigned*)
              (error "Unassigned variable:" var)
              val))
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
   (cons 'println writeln)
   (cons '= =)
   (cons 'not not)
   (cons 'remainder remainder)
   (cons 'memq memq)
   (cons 'list-ref list-ref)
   (cons 'random random)
   (cons 'length length)
   ))

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
    (define-variable! 'the-empty-stream '() initial-env)
    initial-env))
(define the-global-environment (setup-environment))

(define (apply-primitive-procedure proc args)
  (if (primitive-procedure? proc)
      (underlying-apply proc args)
      (error "APPLY PRIMITIVE - unknown procedure" proc)))

(define input-prompt ";;; Amb-Eval input:")
(define output-prompt ";;; Amb-Eval value:")
(define (driver-loop)
  (define (internal-loop try-again)
    (prompt-for-input input-prompt)
    (let ((input (read)))
      (if (eq? input 'try-again)
          (try-again)
          (begin
            (newline)
            (display ";;; Starting a new problem ")
            (ambeval input
                     the-global-environment
                     ;; ambeval success
                     (lambda (val next-alternative)
                       (announce-output output-prompt)
                       (user-print val)
                       (internal-loop next-alternative))
                     ;; ambeval failure
                     (lambda ()
                       (announce-output
                        ";;; There are no more values of")
                       (user-print input)
                       (driver-loop)))))))
  (internal-loop
   (lambda ()
     (newline)
     (display ";;; There is no current problem")
     (driver-loop))))

(define (prompt-for-input string)
  (newline) (newline) (display string) (newline))

(define (announce-output string)
  (newline) (display string) (newline))

(define (user-print object)
  (if (compound-procedure? object)
      (display (list 'compound-procedure
                     (procedure-parameters object)
                     (procedure-body object)
                     '<procedure-env>))
      (display object)))

(#%provide (all-defined)
           put)


