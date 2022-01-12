#lang racket

(require racket/date
         "../eval/safe.rkt"
         "user-lib.rkt"
         "../config.rkt"
         "output-lib.rkt")

(provide make-sandbox-env
         init-sandbox-global-env
         init-sandbox-env
         set-limit-memory
         env-update-variable!
         env-set-constant!)

(define (make-sandbox-env)
  (make-base-namespace))

(define (init-sandbox-global-env env)
  (set-limit-memory 256 env)
  (env-set-constant! '__env-init-date (current-date) env)
  (env-set-constant! '__data-dir-path data-dir-path env)
  (init-user-lib env)
  (init-safe-env env)
  (init-output-lib env))

(define (init-sandbox-env env)
  (set-limit-memory 32 env)
  (env-set-constant! '__env-init-date (current-date) env)
  (init-user-lib env)
  (init-safe-env env))

(define (set-limit-memory mb env)
  (eval `(custodian-limit-memory (current-custodian)
                                 (* ,mb 1024 1024)
                                 (current-custodian))
        env))

(define (env-update-variable! sym value env)
  (namespace-set-variable-value! sym value #f env #f))

; 设置一个常量,注意设置后无法undefine重设
(define (env-set-constant! sym value env)
  (namespace-set-variable-value! sym value #t env #t))
