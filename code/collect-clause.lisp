(cl:in-package #:sicl-loop)

(defclass collect-clause (list-accumulation-clause) ())

(defclass collect-it-clause (collect-clause it-mixin)
  ())

(defclass collect-form-clause (collect-clause form-mixin)
  ())

(defclass collect-it-into-clause (into-mixin collect-clause it-mixin)
  ())

(defclass collect-form-into-clause (into-mixin collect-clause form-mixin)
  ())

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Parsers.

(define-parser collect-it-into-clause-parser
  (consecutive (lambda (collect it into var)
                 (declare (ignore collect it into))
                 (make-instance 'collect-it-into-clause
                   :into-var var))
               (alternative (keyword-parser 'collect)
                            (keyword-parser 'collecting))
               (keyword-parser 'it)
               (keyword-parser 'into)
               (singleton #'identity
                          (lambda (x)
                            (and (symbolp x) (not (constantp x)))))))

(define-parser collect-it-clause-parser
  (consecutive (lambda (collect it)
                 (declare (ignore collect it))
                 (make-instance 'collect-it-clause))
               (alternative (keyword-parser 'collect)
                            (keyword-parser 'collecting))
               (keyword-parser 'it)))

(define-parser collect-form-into-clause-parser
  (consecutive (lambda (collect form into var)
                 (declare (ignore collect into))
                 (make-instance 'collect-form-into-clause
                   :form form
                   :into-var var))
               (alternative (keyword-parser 'collect)
                            (keyword-parser 'collecting))
               'anything-parser
               (keyword-parser 'into)
               (singleton #'identity
                          (lambda (x)
                            (and (symbolp x) (not (constantp x)))))))

(define-parser collect-form-clause-parser
  (consecutive (lambda (collect form)
                 (declare (ignore collect))
                 (make-instance 'collect-form-clause
                   :form form))
               (alternative (keyword-parser 'collect)
                            (keyword-parser 'collecting))
               'anything-parser))

(define-parser collect-clause-parser
  (alternative 'collect-it-into-clause-parser
               'collect-it-clause-parser
               'collect-form-into-clause-parser
               'collect-form-clause-parser))

(add-clause-parser 'collect-clause-parser)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; Compute body-form.

(defmethod body-form ((clause collect-form-clause) end-tag)
  (declare (ignore end-tag))
  `(if (null ,*accumulation-variable*)
       ;; If the accumulation variable is NIL, then so is the tail
       ;; variable.  Then just allocate a new CONS cell containing the
       ;; value of the form, and set bot the accumulation variable and
       ;; the tail variable to point to it.
       (progn (setq ,*list-tail-accumulation-variable*
                    (cons ,(form clause) nil))
              (setq ,*accumulation-variable*
                    ,*list-tail-accumulation-variable*))
       ;; If the accumulation variable is not NIL, then the tail
       ;; variable may or may not be NIL.
       (progn
         ;; If the tail variable is NIL, then every CONS cell in the
         ;; list starting at the accumulation variable must be copied,
         ;; and we know that there is at least one.  So we can
         ;; eliminate this special case by copying the first CONS
         ;; cell, and setting the tail variable to point to it.  We
         ;; could call COPY-LIST and then LAST, but then we would
         ;; traverse the list twice, so we do it with a loop instead.
         (when (null ,*list-tail-accumulation-variable*)
           (setf ,*accumulation-variable*
                 (cons (car ,*accumulation-variable*)
                       (cdr ,*accumulation-variable*)))
           (setf ,*list-tail-accumulation-variable*
                 ,*accumulation-variable*))
         ;; Now, whether the tail variable was initially NIL or not,
         ;; now it no longer is.  And every CONS cell after the one
         ;; that the tail variable points to must be copied.
         (tagbody
          again
            (if (atom (cdr ,*list-tail-accumulation-variable*))
                ;; We have copied all the CONS cells that had to be
                ;; copied.
                (go out)
                ;; Otherwise, we copy the CONS cell pointed to by the
                ;; CDR of the tail variable and advance the tail
                ;; variable by one position.
                (progn (setf (cdr ,*list-tail-accumulation-variable*)
                             (cons (cadr ,*list-tail-accumulation-variable*)
                                   (cddr ,*list-tail-accumulation-variable*)))
                       (setf ,*list-tail-accumulation-variable*
                             (cdr ,*list-tail-accumulation-variable*))
                       (go again)))
          out)
         ;; When we come here, every CONS cell after the one that the
         ;; tail variable points to has been copied, and the tail
         ;; variable points to the last CONS cell in the list.  It
         ;; remains to attach a new CONS cell containing the value of
         ;; the form and to advance the tail variable to point to that
         ;; new CONS cell.
         (if (null (cdr ,*list-tail-accumulation-variable*))
             (progn (setf (cdr ,*list-tail-accumulation-variable*)
                          (cons ,(form clause) nil))
                    (setf ,*list-tail-accumulation-variable*
                          (cdr ,*list-tail-accumulation-variable*)))
             (error 'type-error
                    :datum (cdr ,*list-tail-accumulation-variable*)
                    :expected-type 'null)))))

(defmethod body-form ((clause collect-form-into-clause) end-tag)
  (declare (ignore end-tag))
  `(if (null ,(tail-variable (into-var clause)))
       (progn (setq ,(tail-variable (into-var clause))
                    (list ,(form clause)))
              (setq ,(into-var clause)
                    ,(tail-variable (into-var clause))))
       (progn (rplacd ,(tail-variable (into-var clause))
                      (list ,(form clause)))
              (setq ,(tail-variable (into-var clause))
                    (cdr ,(tail-variable (into-var clause)))))))

(defmethod body-form ((clause collect-it-clause) end-tag)
  (declare (ignore end-tag))
  `(if (null ,*list-tail-accumulation-variable*)
       (progn (setq ,*list-tail-accumulation-variable*
                    (list ,*it-var*))
              (setq ,*accumulation-variable*
                    ,*list-tail-accumulation-variable*))
       (progn (rplacd ,*list-tail-accumulation-variable*
                      (list ,*it-var*))
              (setq ,*list-tail-accumulation-variable*
                    (cdr ,*list-tail-accumulation-variable*)))))

(defmethod body-form ((clause collect-it-into-clause) end-tag)
  (declare (ignore end-tag))
  `(if (null ,(tail-variable (into-var clause)))
       (progn (setq ,(tail-variable (into-var clause))
                    (list ,*it-var*))
              (setq ,(into-var clause)
                    ,(tail-variable (into-var clause))))
       (progn (rplacd ,(tail-variable (into-var clause))
                      (list ,*it-var*))
              (setq ,(tail-variable (into-var clause))
                    (cdr ,(tail-variable (into-var clause)))))))
