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

(defclass nconc-clause (list-accumulation-clause) ())

(defclass nconc-it-clause (nconc-clause it-mixin)
  ())

(defclass nconc-form-clause (nconc-clause form-mixin)
  ())

(defclass nconc-it-into-clause (into-mixin nconc-clause it-mixin)
  ())

(defclass nconc-form-into-clause (into-mixin nconc-clause form-mixin)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Parsers.

(define-parser nconc-it-into-clause-parser
  (consecutive (lambda (nconc it into var)
		 (declare (ignore nconc it into))
		 (make-instance 'nconc-it-into-clause
		   :into-var var))
	       (alternative (keyword-parser 'nconc)
			    (keyword-parser 'nconcing))
	       (keyword-parser 'it)
	       (keyword-parser 'into)
	       (singleton #'identity
			  (lambda (x)
			    (and (symbolp x) (not (constantp x)))))))

(define-parser nconc-it-clause-parser
  (consecutive (lambda (nconc it)
		 (declare (ignore nconc it))
		 (make-instance 'nconc-it-clause))
	       (alternative (keyword-parser 'nconc)
			    (keyword-parser 'nconcing))
	       (keyword-parser 'it)))

(define-parser nconc-form-into-clause-parser
  (consecutive (lambda (nconc form into var)
		 (declare (ignore nconc into))
		 (make-instance 'nconc-form-into-clause
		   :form form
		   :into-var var))
	       (alternative (keyword-parser 'nconc)
			    (keyword-parser 'nconcing))
	       'anything-parser
	       (keyword-parser 'into)
	       (singleton #'identity
			  (lambda (x)
			    (and (symbolp x) (not (constantp x)))))))

(define-parser nconc-form-clause-parser
  (consecutive (lambda (nconc form)
		 (declare (ignore nconc))
		 (make-instance 'nconc-form-clause
		   :form form))
	       (alternative (keyword-parser 'nconc)
			    (keyword-parser 'nconcing))
	       'anything-parser))

(define-parser nconc-clause-parser
  (alternative 'nconc-it-into-clause-parser
	       'nconc-it-clause-parser
	       'nconc-form-into-clause-parser
	       'nconc-form-clause-parser))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute body-form.

(defmethod body-form ((clause nconc-form-clause) end-tag)
  (declare (ignore end-tag))
  `(if (null ,*list-tail-accumulation-variable*)
       (progn (setq ,*accumulation-variable*
		    ,(form clause))
	      (setq ,*list-tail-accumulation-variable*
		    (last ,*accumulation-variable*)))
       (progn (rplacd ,*list-tail-accumulation-variable*
		      ,(form clause))
	      (setq ,*list-tail-accumulation-variable*
		    (last ,*list-tail-accumulation-variable*)))))
