#lang racket

(require racket/exn
         "../config.rkt"
         "../env/main.rkt"
         "safe.rkt"
         "request-scope.rkt")

(provide init eval-request)

(define (init)
  (init-sandbox-global-env sandbox-global-env)
  (add-env "global" sandbox-global-env))

(define (eval-request req-data)
  (define expr-string (hash-ref req-data 'expr))

  (define eval-env
    (cond
      [(hash-has-key? req-data 'env_id)
       (define env-id (hash-ref req-data 'env_id))
       (define env (get-env env-id))
       (if env
           env
           (error (format "找不到id为~A的环境" env-id)))]
      [else (error "未指定环境id")]))
  
  (set-request-scope-variables req-data eval-env)
  (update-safe-env eval-env (admin-sender? req-data))
  (eval-result expr-string eval-env (admin-sender? req-data)))

(define (eval-result expr-string env admin?)
  (define output (open-output-string))

  (env-update-variable! '__default-output output env)
  (eval '(begin
           (current-output-port __default-output)
           (__reset-output-handler))
        env)
  (define output-handler (eval '__output-handler env))
  (let ([expr-in (open-input-string expr-string)])
    (let loop ([expr-read (read expr-in)])
      (when (not (eof-object? expr-read))
        (define next-expr-read (read expr-in))
        (define expr (if admin?
                         expr-read
                         (transform-safe-expr-for-eval expr-read)))
        (env-update-variable! '__eval-expr-read expr-read env)
        (env-update-variable! '__eval-expr expr env)
        (define value (eval expr env))
        (when (not (void? value))
          (output-handler value output)
          (output-handler "\n" output))
        (loop next-expr-read))))
  
  (define result (make-hash))
  (hash-set! result 'output (eval '(__get-eval-output-objects) env))
  result)
