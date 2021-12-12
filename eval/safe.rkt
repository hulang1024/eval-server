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

; 包含不安全过程的模块
(define unsafe-modules
  '(racket
    net/ftp
    compatibility/package))

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
                          (let ([op (car e)])
                            (or (equal? 'require op)
                                (equal? 'module op)
                                (equal? 'planet op)
                                (equal? 'lib op)))
                          (pair? (cdr e))
                          (let ([require-spec (cdr e)])
                            (findf (λ (spec-item)
                                     (findf (λ (unsafe-sym)
                                              (or (equal? unsafe-sym spec-item)
                                                  (cond
                                                    [(symbol? spec-item)
                                                     (let ([m-name (symbol->string spec-item)])
                                                       (or (string-prefix? m-name "racket")
                                                           (string-prefix? m-name "rnrs")
                                                           (string-prefix? m-name "ffi")))]
                                                    [else #f])))
                                            unsafe-modules))
                                   require-spec))))]
             [expr-removed (repalce-top-level-form-expr pred expr-raw)])
        expr-removed)
      expr-raw))

(define (repalce-top-level-form-expr pred expr)  
  (if (list? expr)
      (let ([op (car expr)])
        (if (is-top-level-form? op)
            (cons op
                  (map
                   (lambda (e)
                     (if (pred e)
                         (error (format "不支持的表达式：~A" e))
                         (repalce-top-level-form-expr pred e)))
                   (cdr expr)))
            expr))
      expr))

(define top-level-form-ops
  '(begin
     module
     ; 自己定义的宏
     define-name-command
     ; 内置
     define-syntax
     define-syntax-rule
     define-syntax-set
     define-syntaxes
     define-syntax-class
     define-for-syntax))

(define (is-top-level-form? op)
  (and (symbol? op) (member op top-level-form-ops)))
