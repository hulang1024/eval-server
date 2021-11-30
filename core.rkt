#lang racket

(require racket/exn
         racket/date)
(require "user-lib.rkt")
(require "config.rkt")

(provide init eval-request)

; 全局环境
(define sandbox-global-env (make-base-namespace))
(define sandbox-admin-rights-symbols
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
(define sandbox-admin-rights-saves (make-hash))

(define (init)
  (eval '(custodian-limit-memory (current-custodian) 65011324 (current-custodian)) sandbox-global-env)
  
  (namespace-set-variable-value! '__env-init-date (current-date) #t sandbox-global-env #t)

  (init-user-lib sandbox-global-env)

  (for ([sym sandbox-admin-rights-symbols])
    (hash-set! sandbox-admin-rights-saves sym (eval sym sandbox-global-env)))
  (hash-set! sandbox-admin-rights-saves 'exit-handler-proc (eval '(exit-handler) sandbox-global-env)))

(define (eval-request req-data)
  ; 获得表达式源码字符串
  (define expr-string (hash-ref req-data 'expr))
  
  (set-variables-from-request-scope req-data sandbox-global-env)
  (make-safe-env sandbox-global-env req-data)
  ; 求值
  (eval-result expr-string sandbox-global-env req-data))

; 执行表达式
(define (eval-result expr-string env req-data)
  ; 为求值设置一个新的output-port
  (define output (open-output-string))
  ; 设置到全局环境
  (namespace-set-variable-value! 'default-output output #f env #f)

  (define result (make-hash))

  (define value
    (with-handlers ([(lambda (v) #t) (lambda (v) v)])
      (let* ([expr-raw (read (open-input-string (string-append "(begin " expr-string "\n)")))]
             [expr (if (is-admin-sender req-data) expr-raw (filter-eval-expr expr-raw))])
        (namespace-set-variable-value! '__eval-expr-raw expr-raw #f env #f)
        (namespace-set-variable-value! '__eval-expr expr #f env #f)
        (eval '(current-output-port default-output) env)
        (eval expr env))))

  (if (exn:fail? value)
      (hash-set! result 'error (exn-message value))
      (let ([out (open-output-string)])
        (write value out)
        (hash-set! result 'value (get-output-string out))))

  (hash-set! result 'output (get-output-string output))
  result)

(define (make-safe-env env req-data)
  (define (nop-false . x) #f)

  (if (is-admin-sender req-data)
      (begin
        (for ([sym sandbox-admin-rights-symbols])
          (namespace-set-variable-value! sym (hash-ref sandbox-admin-rights-saves sym) #t env #f))
        (namespace-set-variable-value! 'exit-handler-proc
                                       (hash-ref sandbox-admin-rights-saves 'exit-handler-proc) #f env #f))
      (begin
        (for ([sym sandbox-admin-rights-symbols])
          (namespace-set-variable-value! sym nop-false #t env #f))
        (namespace-set-variable-value! 'exit-handler-proc (lambda (n) #f) #f env #f)))
    (eval '(exit-handler exit-handler-proc) env))

(define (filter-eval-expr expr-raw)
  (define unsafe-module-syms
    '(racket
      racket/system
      racket/sandbox
      racket/gui
      racket/file
      racket/dirs
      racket/link
      racket/config
      racket/path
      racket/command-line
      racket/tcp
      racket/udp
      net/ftp
      compatibility/package))
  
  (if (list? expr-raw)
      (let* ([pred (lambda (e)
                     (and (list? e)
                          (equal? 'require (car e))
                          (pair? (cdr e))
                          (let ([require-spec (cdr e)])
                            (findf (λ (spec-item)
                                     (findf (λ (unsafe-sym)
                                              (or (equal? unsafe-sym spec-item)
                                                  (cond
                                                    [(symbol? spec-item)
                                                     (let ([m-name (symbol->string spec-item)])
                                                       (or (string-prefix? m-name "rnrs") (string-prefix? m-name "ffi")))]
                                                    [else #f])))
                                            unsafe-module-syms))
                                   require-spec))))]
             [expr-removed (repalce-top-level-form-expr pred expr-raw)])
        expr-removed)
      expr-raw))

(define (repalce-top-level-form-expr pred expr)
  (define top-level-form-ops
    '(begin
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
  
  (if (list? expr)
      (let ([op (car expr)])
        (if (is-top-level-form? op)
            (cons op
                  (map
                   (lambda (e)
                     (if (pred e)
                         (void)
                         (repalce-top-level-form-expr pred e)))
                   (cdr expr)))
            expr))
      expr))
  

(define (set-variables-from-request-scope req-data env)
  ; 发送者
  (when (hash-has-key? req-data 'sender)
    (let ([sender (hash-ref req-data 'sender)])
      (namespace-set-variable-value! '__sender sender #f env #f)
      (namespace-set-variable-value! '__sender-id (hash-ref sender 'id) #f env #f))))

(define (is-admin-sender req-data)
  (and (hash-has-key? req-data 'sender)
       (let* ([sender (hash-ref req-data 'sender)]
              [sender-id (hash-ref sender 'id)])
         (findf (lambda (id) (= id sender-id)) admin-ids))))
