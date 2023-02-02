(cl:in-package #:khazern)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Clause FOR-AS-EQUALS-THEN.

(defclass for-as-equals-then (for-as-subclause)
  ((%initial-form :initarg :initial-form :reader initial-form)
   (%subsequent-form :initarg :subsequent-form :reader subsequent-form)
   (%temp-tree :accessor temp-tree)
   (%directory :accessor %directory)))

(defmethod initialize-instance :after
    ((clause for-as-equals-then) &rest initargs &key)
  (declare (ignore initargs))
  (with-accessors ((temp-tree temp-tree)
                   (%directory %directory))
                  clause
    (multiple-value-setq (temp-tree %directory)
                         (fresh-variables (var-spec clause)))))
                         
(defmethod bound-variables ((subclause for-as-equals-then))
  (mapcar #'car
          (extract-variables (var-spec subclause) nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Parsers.

(define-parser for-as-equals-then-parser-1
  (consecutive (lambda (var-spec type-spec = form1 then form2)
                 (declare (ignore = then))
                 (make-instance 'for-as-equals-then
                   :var-spec var-spec
                   :type-spec type-spec
                   :initial-form form1
                   :subsequent-form form2))
               ;; Accept anything for now.  Analyze later.
               'anything-parser
               'optional-type-spec-parser
               (keyword-parser '=)
               'anything-parser
               (keyword-parser 'then)
               'anything-parser))

(define-parser for-as-equals-then-parser-2
  (consecutive (lambda (var-spec type-spec = form1)
                 (declare (ignore =))
                 (make-instance 'for-as-equals-then
                   :var-spec var-spec
                   :type-spec type-spec
                   :initial-form form1
                   :subsequent-form form1))
               ;; Accept anything for now.  Analyze later.
               'anything-parser
               'optional-type-spec-parser
               (keyword-parser '=)
               'anything-parser))

;;; Make sure parser 1 is tried first.  For that, it must be added
;;; last.
(add-for-as-subclause-parser 'for-as-equals-then-parser-2)
(add-for-as-subclause-parser 'for-as-equals-then-parser-1)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute the bindings.

(defmethod initial-bindings ((clause for-as-equals-then))
  (loop with d-var-spec = (var-spec clause)
        with d-type-spec = (type-spec clause)
        for (variable) in (extract-variables d-var-spec d-type-spec)
        collect `(,variable nil)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute the declarations.

(defmethod declarations ((clause for-as-equals-then))
  (loop with d-var-spec = (var-spec clause)
        with d-type-spec = (type-spec clause)
        for (variable type) in (extract-variables d-var-spec d-type-spec)
        collect `(cl:type (or null ,type) ,variable)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute the prologue-form-bindings.

(defmethod prologue-form-bindings ((clause for-as-equals-then))
  (destructure-variables (temp-tree clause) (initial-form clause)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute the prologue-form.

(defmethod prologue-form ((clause for-as-equals-then) end-tag)
  (declare (ignore end-tag))
  `(setq ,@(loop for (original . temp) in (%directory clause)
                 collect original
                 collect temp)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute the step-form-bindings.

(defmethod step-form-bindings ((clause for-as-equals-then))
  (destructure-variables (temp-tree clause) (subsequent-form clause)))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute the step-form.

(defmethod step-form ((clause for-as-equals-then))
  `(setq ,@(loop for (original . temp) in (%directory clause)
                 collect original
                 collect temp)))
