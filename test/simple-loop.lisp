;-*- Mode:     Lisp -*-
;;;; Author:   Paul Dietz
;;;; Created:  Fri Oct 25 18:48:59 2002
;;;; Contains: Tests of LOOP

(cl:in-package :khazern/test)

;;; Simple loops
(deftest sloop.1
  (khazern:loop (return 'a))
  a)

(deftest sloop.2
  (khazern:loop (return (cl:values))))

(deftest sloop.3
  (khazern:loop (return (cl:values 'a 'b 'c 'd)))
  a b c d)

(deftest sloop.4
  (block nil
    (khazern:loop (return 'a))
    'b)
  b)

(deftest sloop.5
  (let ((i 0) (x nil))
    (khazern:loop
     (when (>= i 4) (return x))
     (incf i)
     (push 'a x)))
  (a a a a))

(deftest sloop.6
  (let ((i 0) (x nil))
    (block foo
      (tagbody
       (khazern:loop
        (when (>= i 4) (go a))
        (incf i)
        (push 'a x))
       a
       (return-from foo x))))
  (a a a a))

(deftest sloop.7
  (catch 'foo
    (let ((i 0) (x nil))
    (khazern:loop
     (when (>= i 4) (throw 'foo x))
     (incf i)
     (push 'a x))))
  (a a a a))
