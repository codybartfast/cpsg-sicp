#lang racket
; Flotsam and Jetsam from working through Chapter 2.
  

; A helper function for priting out the exercise title
; and some other bits for displaying comments.
;(define nl "\n")
(define (get-string item)
  (cond ((string? item) item)
        ((number? item) (number->string item))
        (else item)))
(define (str . parts)
  (define strParts (map get-string parts))
  (apply string-append  strParts ))
(define (prn . lines)
  (for-each
   (lambda (line) (display (str line "\n")))
   lines))
(define (ti title)
  (define long (make-string 60 #\_))
  (prn "" "" long    title    long ""))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(ti "Exercise 2.7")

(define (make-interval a b) (cons a b))

(define (upper-bound a)
  (let ((x (car a))
        (y (cdr a)))
    (if (> x y) x y)))

(define (lower-bound a)
  (let ((x (car a))
        (y (cdr a)))
    (if (< x y) x y)))

(define bound-test (make-interval 3 2))
"I'd like a simbple string concating display function"
(lower-bound bound-test)
(upper-bound bound-test)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(ti "Exercise 2.8")

(define (add-interval x y)
  (make-interval (+ (lower-bound x) (lower-bound y))
                 (+ (upper-bound x) (upper-bound y))))

(define (negate-interval x)
  (make-interval (- (lower-bound x))
                 (- (upper-bound x))))

(define (sub-interval x y)
  (add-interval x (negate-interval y)))

(let ((fortyish (make-interval 39 41))
      (tenish (make-interval 9 11)))
  (sub-interval fortyish tenish))


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
(ti "Exercise 2.9")

(prn 
 "Why we can combine widths in addition (& therefore subraction):"
 
 "Given x with a lower bound of lx and upper bound of ux"
 "  and y with a lower bound of ly and upper bound of uy"
 "  under addtion the new width will be: "
 "    ((ux + uy) - (lx + ly)) / 2"
 "    = ((ux - lx) + (uy - ly)) / 2"
 "    = (2wx + 2wy) / 2"
 "    = wx + wy"
 "and that's good enough for me.")

(define (mul-interval x y)
  (let ((p1 (* (lower-bound x) (lower-bound y)))
        (p2 (* (lower-bound x) (upper-bound y)))
        (p3 (* (upper-bound x) (lower-bound y)))
        (p4 (* (upper-bound x) (upper-bound y))))
    (make-interval (min p1 p2 p3 p4)
                   (max p1 p2 p3 p4))))

(define (interval-width x)
   (/ (- (upper-bound x) (lower-bound x))
      2))


(let ((x (make-interval 9 11))
      (y (make-interval 999999 1000001)))  
  (prn
   "" "Lets try 'wx * wy' as a guess for the width after multiplication:"
   (str "x: " (lower-bound x) "-" (upper-bound x))
   (str "y: " (lower-bound y) "-" (upper-bound y))
   (str "Estimate: " (* (interval-width x) (interval-width y)))
   (str "Actual: " (interval-width  (mul-interval x y)))))


(prn
 "" "why?"
 "Assuming everything is positive..."
 "  width / 2"
 "    = (ux * uy) - (lx * ly)"
 "    = (lx + wx)*(ly + wy) - (lx * ly)"
 " which cannot be reduced to a form that has just wx and wy,"
 " so final width is dependant on both origanl 'values'")
      