#lang sicp

(#%require "common.scm")

;   Exercise 3.45
;   =============
;   
;   Louis Reasoner thinks our bank-account system is unnecessarily complex
;   and error-prone now that deposits and withdrawals aren't automatically
;   serialized. He suggests that make-account-and-serializer should have
;   exported the serializer (for use by such procedures as
;   serialized-exchange) in addition to (rather than instead of) using it to
;   serialize accounts and deposits as make-account did. He proposes to
;   redefine accounts as follows:
;   
;   (define (make-account-and-serializer balance)
;     (define (withdraw amount)
;       (if (>= balance amount)
;           (begin (set! balance (- balance amount))
;                  balance)
;           "Insufficient funds"))
;     (define (deposit amount)
;       (set! balance (+ balance amount))
;       balance)
;     (let ((balance-serializer (make-serializer)))
;       (define (dispatch m)
;         (cond ((eq? m 'withdraw) (balance-serializer withdraw))
;               ((eq? m 'deposit) (balance-serializer deposit))
;               ((eq? m 'balance) balance)
;               ((eq? m 'serializer) balance-serializer)
;               (else (error "Unknown request -- MAKE-ACCOUNT"
;                            m))))
;       dispatch))
;   
;   Then deposits are handled as with the original make-account:
;   
;   (define (deposit account amount)
;    ((account 'deposit) amount))
;   
;   Explain what is wrong with Louis's reasoning.  In particular, consider
;   what happens when serialized-exchange is called.
;   
;   ------------------------------------------------------------------------
;   [Exercise 3.45]: http://sicp-book.com/book-Z-H-23.html#%_thm_3.45
;   3.4.2 Mechanisms for Controlling Concurrency - p310
;   ------------------------------------------------------------------------

(-start- "3.45")

(prn "
We will get a deadlock.

When the protected exchange function is called it ultimately make a call to
a protected withdrawl method which will wait until for the exchange function
to complete - so the withdrawl can't happen until the exchange is complete
AND exchange can't complete until withdrawl is complete.

")

(--end-- "3.45")

