#lang sicp

(#%require "common.scm")

;   Exercise 4.48
;   =============
;   
;   Extend the grammar given above to handle more complex sentences.  For
;   example, you could extend noun phrases and verb phrases to include
;   adjectives and adverbs, or you could handle compound sentences.⁽⁵³⁾
;   
;   ------------------------------------------------------------------------
;   [Exercise 4.48]: http://sicp-book.com/book-Z-H-28.html#%_thm_4.48
;   [Footnote 53]:   http://sicp-book.com/book-Z-H-28.html#footnote_Temp_626
;   4.3.2 Examples of Nondeterministic Programs - p426
;   ------------------------------------------------------------------------

(-start- "4.48")

(println "
Adding adjectives
")

(define (require p)
  (if (not p) (amb)))

(define *unparsed* '())
(define (parse input)
  (set! *unparsed* input)
  (let ((sent (parse-sentence)))
    (require (null? *unparsed*))
    ;(println sent)
    ;(amb)
    sent))

(define nouns '(noun student professor cat class))
(define adjectives '(adjective distracted big fat sleepy wistful roomy))
(define verbs '(verb studies lectures eats sleeps))
(define articles '(article the a))
(define prepositions '(prep for to in by with))

(define (parse-word word-list)
  (require (not (null? *unparsed*)))
  (require (memq (car *unparsed*) (cdr word-list)))
  (let ((found-word (car *unparsed*)))
    (set! *unparsed* (cdr *unparsed*))
    (list (car word-list) found-word)))

(define (parse-sentence)
  (list 'sentence
         (parse-noun-phrase)
         (parse-verb-phrase)))

(define (parse-simple-noun-phrase)
  (list 'simple-noun-phrase
        (parse-word articles)                
        (parse-described-noun)))                        ;

(define (parse-described-noun)                          ;
  (amb (parse-word nouns)                               ;
       (list  'described-noun                           ;
              (parse-adjectives)                        ;
              (parse-word nouns))))                     ;

(define (parse-adjectives)                              ;
  (define (parse-adjective)                             ;
    (cdr (parse-word adjectives)))                      ;
  (define (maybe-extend adj-list)                       ;
    (amb adj-list                                       ;
         (maybe-extend (append adj-list                 ;
                               (parse-adjective)))))    ;
  (cons 'adjectives (maybe-extend (parse-adjective))))  ;
  
(define (parse-noun-phrase)
  (define (maybe-extend noun-phrase)
    (amb noun-phrase
         (maybe-extend (list 'noun-phrase
                             noun-phrase
                             (parse-prepositional-phrase)))))
  (maybe-extend (parse-simple-noun-phrase)))

(define (parse-verb-phrase)
  (define (maybe-extend verb-phrase)
    (amb verb-phrase
         (maybe-extend (list 'verb-phrase
                             verb-phrase
                             (parse-prepositional-phrase)))))
  (maybe-extend (parse-word verbs)))

(define (parse-prepositional-phrase)
  (list 'prep-phrase
        (parse-word prepositions)
        (parse-noun-phrase)))

(parse '(the wistful sleepy professor lectures to the sleepy distracted
             student in the roomy class with the big fat sleepy cat))

(--end-- "4.48")

