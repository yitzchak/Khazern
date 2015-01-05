;;;; Copyright (c) 2014
;;;;
;;;;     Robert Strandh (robert.strandh@gmail.com)
;;;;
;;;; all rights reserved. 
;;;;
;;;; Permission is hereby granted to use this software for any 
;;;; purpose, including using, modifying, and redistributing it.
;;;;
;;;; The software is provided "as-is" with no warranty.  The user of
;;;; this software assumes any responsibility of the consequences. 

(cl:in-package #:sicl-loop)

;;;; Clause INITIAL-CLAUSE.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class INITIAL-CLAUSE.
;;;
;;; An INITIAL clause does not exist as a separate grammar item in
;;; the HyperSpec, but we define it here anyway.  The syntax is:
;;;
;;;    initial-clause ::= initially compound-form+

(defclass initial-clause (clause)
  ((%form :initarg :form :reader form)))

;;; The initial clause does not bind any variables.
(defmethod bound-variables ((clause initial-clause))
  '())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Parser

(define-parser initial-clause-parser
  (consecutive (lambda (initially compound+)
		 (declare (ignore initially))
		 (make-instance 'initial-clause
		   :form compound+))
	       (keyword-parser 'initially)
	       'compound+))

(add-clause-parser 'initial-clause-parser)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute prologue-form.

(defmethod prologue-form ((clause initial-clause) end-tag)
  (declare (ignore end-tag))
  (form clause))
