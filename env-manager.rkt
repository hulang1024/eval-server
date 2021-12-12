#lang racket

(require "env/env-manager.rkt")

(provide create-env-api
         remove-env-api
         rename-env-api
         reset-env-api
         get-env-ids-api)

(define (create-env-api req-data)
  (define env-id (hash-ref req-data 'env_id))

  (cond
    [(has-env? env-id)
     (hash 'code 2 'error "该环境已存在")]
    [(can-make-new-env?)
     (make-env env-id)
     (hash 'code 0)]
    [else (hash 'code 1 'error "不能创建新的环境")]))

(define (remove-env-api req-data)
  (define env-id (hash-ref req-data 'env_id))

  (remove-env env-id)
  (hash 'code 0))

(define (rename-env-api req-data)
  (define old-env-id (hash-ref req-data 'old_env_id))
  (define new-env-id (hash-ref req-data 'new_env_id))

  (let ([ok (rename-env old-env-id new-env-id)])
    (hash 'code (if ok 0 1))))

(define (reset-env-api req-data)
  (define env-id (hash-ref req-data 'env_id))

  (let ([ok (reset-env env-id)])
    (hash 'code (if ok 0 1))))

(define (get-env-ids-api req-data)
  (hash 'code 0 'data (get-env-ids)))