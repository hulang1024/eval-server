#lang racket

(require racket/date
         "../eval/safe.rkt"
         "user-lib.rkt"
         "base.rkt")

(provide get-env
         get-env-ids
         can-make-new-env?
         has-env?
         make-env
         add-env
         remove-env
         rename-env
         reset-env)

(define env-number-max (+ 12 1))
(define envs (make-hash))

(define (get-env id)
  (if (hash-has-key? envs id)
      (hash-ref envs id)
      #f))

(define (can-make-new-env?)
  (< (hash-count envs) env-number-max))

(define (get-env-ids)
  (hash-keys envs))

(define (has-env? id)
  (hash-has-key? envs id))

(define (make-env id)
  (if (and (can-make-new-env?)
           (not (hash-has-key? envs id)))
      (let ([env (make-sandbox-env)])
        (add-env id env)
        (init-sandbox-env env)
        env)
      #f))

(define (add-env id env)
  (hash-set! envs id env))

(define (remove-env id)
  (hash-remove! envs id))

(define (rename-env old-id new-id)
  (if (has-env? old-id)
    (begin
      (hash-set! envs new-id (hash-ref envs old-id))
      (hash-remove! envs old-id))
    #f))

(define (reset-env id)
  (remove-env id)
  (make-env id))