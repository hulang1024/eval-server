#lang racket

(provide init-safe-env
         update-safe-env
         transform-safe-expr-for-eval)

; 危险的，存在racket库里的
(define unsafe-variables
  '(
    shell-execute
    subprocess
    subprocess-kill
    current-subprocess-custodian-mode
    getenv
    current-custodian
    custodian-limit-memory
    custodian-require-memory	
    custodian-shutdown-all
    load
    open-input-file
    open-output-file
    open-input-output-file
    call-with-input-file
    call-with-output-file
    with-input-from-file
    with-output-to-file
    directory-list
    rename-file-or-directory
    delete-file
    copy-file
    delete-directory
    make-directory))

(define unsafe-variable-value-saves (make-hash))

(define (init-safe-env env)
  (for ([sym unsafe-variables])
    (hash-set! unsafe-variable-value-saves sym (eval sym env)))
  (hash-set! unsafe-variable-value-saves 'exit-handler-proc (eval '(exit-handler) env)))

(define (update-safe-env env unsafe)
  (if unsafe
      (begin
        (for ([sym unsafe-variables])
          (namespace-set-variable-value! sym (hash-ref unsafe-variable-value-saves sym) #t env #f))
        (namespace-set-variable-value! 'exit-handler-proc
                                       (hash-ref unsafe-variable-value-saves 'exit-handler-proc) #f env #f))
      (begin
        (for ([sym unsafe-variables])
          (namespace-set-variable-value! sym nop-false #t env #f))
        (namespace-set-variable-value! 'exit-handler-proc (lambda (n) #f) #f env #f)))
    (eval '(exit-handler exit-handler-proc) env))

(define (nop-false . x) #f)

(define (transform-safe-expr-for-eval expr-raw)
  (if (list? expr-raw)
      (let* ([pred (lambda (e)
                     (and (list? e)
                          (pair? e)
                          (let ([op (car e)])
                            (or (equal? 'require op)
                                (equal? 'local-require op)
                                (equal? 'module op)
                                (equal? 'planet op)
                                (equal? 'lib op)))))]
             [expr-removed (repalce-top-level-form-expr pred `(begin ,expr-raw))])
        (cadr expr-removed))
      expr-raw))

(define (repalce-top-level-form-expr pred expr)  
  (if (and (list? expr) (pair? expr))
      (let ([op (car expr)])
        (cons op
              (map
                (lambda (e)
                  (if (pred e)
                      (error (format "不支持的表达式：~A" e))
                      (repalce-top-level-form-expr pred e)))
                (cdr expr))))
      expr))
