#lang sicp

(#%require "common.scm")

;   Exercise 3.46
;   =============
;   
;   Suppose that we implement test-and-set! using an ordinary procedure as
;   shown in the text, without attempting to make the operation atomic. 
;   Draw a timing diagram like the one in figure [3.29] to demonstrate how
;   the mutex implementation can fail by allowing two processes to acquire
;   the mutex at the same time.
;   
;   ------------------------------------------------------------------------
;   [Exercise 3.46]: http://sicp-book.com/book-Z-H-23.html#%_thm_3.46
;   [Figure 3.29]:   http://sicp-book.com/book-Z-H-23.html#%_fig_3.29
;   3.4.2 Mechanisms for Controlling Concurrency - p313
;   ------------------------------------------------------------------------

(-start- "3.46")

(prn "Both calls could read 'false' from the cell and continue to return
'false' to the calling method resulting in methods running cuncurrently

(test-and-set! cell)   cell   (test-and-set! cell)
====================          ====================

(if(car cell))        false
                      false   (if (car cell))

(begin...
false                 true
                              (begin ...
                      true    false        
")



(--end-- "3.46")

