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
    (if (hash-has-key? req-data 'env_id)
        (let* ([env-id (hash-ref req-data 'env_id)]
               [env (get-env env-id)])
          (if env
              env
              (error (format "找不到id为~A的环境" env-id))))
        (error "未指定环境id")))
  
  (set-request-scope-variables req-data eval-env)
  (update-safe-env eval-env (is-admin-sender req-data))
  (eval-result expr-string eval-env req-data))

(define (eval-result expr-string env req-data)
  (define output (open-output-string))
  
  (env-update-variable! '__default-output output env)

  (define result (make-hash))

  (define value
    (let* ([expr-wrap (string-append "(begin " expr-string "\n)")]
           [expr-raw (read (open-input-string expr-wrap))]
           [expr (if (is-admin-sender req-data) expr-raw (transform-safe-expr-for-eval expr-raw))])
      (env-update-variable! '__eval-expr-raw expr-raw env)
      (env-update-variable! '__eval-expr expr env)
      (eval '(begin
               (current-output-port __default-output)
               (__reset-output-handler))
            env)
      (eval expr env)))
  
  (hash-set! result 'output (eval '__eval-output env))
  
  (eval '(__reset-output-handler) env)
  ((eval '__output-handler env) value (eval '__default-output env))
  (hash-set! result 'value (eval '__eval-output env))

  result)
