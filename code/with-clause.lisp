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

;;; Clause WITH-CLAUSE.
;;;
;;; A WITH-CLAUSE allows the creation of local variables.  It is
;;; executed once.
;;;
;;; The syntax of a with-clause is:
;;;
;;;    with-clause ::= WITH var1 [type-spec] [= form1] 
;;;                    {AND var2 [type-spec] [= form2]}*
;;;
;;; where var1 and var2 are destructuring variable specifiers
;;; (d-var-spec) allowing multiple local variables to be created in a
;;; single with-clause by destructuring the value of the corresponding
;;; form.
;;;
;;; When there are several consecutive with-claues, the execution is
;;; done sequentially, so that variables created in one with-clause
;;; can be used in the forms of subsequent with-clauses.  If parallel
;;; creation of variables is wanted, then the with-clause can be
;;; followed by one or more and-clauses. 
;;;
;;; The (destructuring) type specifier is optional.  If no type
;;; specifier is given, it is as if t was given. 
;;;
;;; The initialization form is optional.  If there is a corresponding
;;; type specifier for a variable, but no initialization form, then
;;; the variable is initialized to a value that is appropriate for the
;;; type.  In particular, for the type t the value is nil, for the
;;; type number, the value is 0, and for the type float, the value is
;;; 0.0.  

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Class WITH-CLAUSE.
;;;

(defclass with-clause (clause subclauses-mixin variable-clause-mixin) ())

(defclass with-subclause ()
  ((%var-spec :initarg :var-spec :reader var-spec)
   (%type-spec :initarg :type-spec :reader type-spec)))

(defclass with-subclause-with-form (with-subclause)
  ((%form :initarg :form :reader form)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Parsers.

;;; Parser for var type-spec = form
;;; We try this parser first.
(define-parser with-subclause-type-1-parser
  (consecutive (lambda (var-spec type-spec = form)
		 (declare (ignore =))
		 (make-instance 'with-subclause-with-form
		   :var-spec var-spec
		   :type-spec type-spec
		   :form form))
	       ;; Accept anything for now.  Analyze later. 
	       (singleton #'identity (constantly t))
	       'type-spec-parser
	       (keyword-parser '=)
	       (singleton #'identity (constantly t))))

;;; Parser for var = form
(define-parser with-subclause-type-2-parser
  (consecutive (lambda (var-spec = form)
		 (declare (ignore =))
		 (make-instance 'with-subclause-with-form
		   :var-spec var-spec
		   :type-spec (make-instance 'simple-type-spec :type t)
		   :form form))
	       ;; Accept anything for now.  Analyze later. 
	       (singleton #'identity (constantly t))
	       (keyword-parser '=)
	       (singleton #'identity (constantly t))))

;;; Parser for var type-spec
(define-parser with-subclause-type-3-parser
  (consecutive (lambda (var-spec type-spec)
		 (make-instance 'with-subclause
		   :var-spec var-spec
		   :type-spec type-spec))
	       ;; Accept anything for now.  Analyze later. 
	       (singleton #'identity (constantly t))
	       'type-spec-parser))

;;; Parser for var
(define-parser with-subclause-type-4-parser
  (consecutive (lambda (var-spec)
		 (make-instance 'with-subclause
		   :var-spec var-spec
		   :type-spec (make-instance 'simple-type-spec :type t)))
	       ;; Accept anything for now.  Analyze later. 
	       (singleton #'identity (constantly t))))

;;; Parser for any type of with subclause without the leading keyword
(define-parser with-subclause-no-keyword-parser
  (alternative 'with-subclause-type-1-parser
	       'with-subclause-type-2-parser
	       'with-subclause-type-3-parser
	       'with-subclause-type-4-parser))

;;; Parser for the with subclause starting with the AND keyword.
(define-parser with-subclause-and-parser
  (consecutive (lambda (and subclause)
		 (declare (ignore and))
		 subclause)
	       (keyword-parser 'and)
	       'with-subclause-no-keyword-parser))

;;; Parser for a with clause
(define-parser with-clause-parser
  (consecutive (lambda (with first rest)
		 (declare (ignore with))
		 (make-instance 'with-clause
		   :subclauses (cons first rest)))
	       (keyword-parser 'with)
	       'with-subclause-no-keyword-parser
	       (repeat* #'list
			'with-subclause-and-parser)))

(add-clause-parser 'with-clause-parser)