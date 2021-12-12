#lang racket

(require "../env/main.rkt"
         "../config.rkt")

(provide set-request-scope-variables
         is-admin-sender)

(define (set-request-scope-variables req-data env)
  ; 发送者
  (when (hash-has-key? req-data 'sender)
    (let ([sender (hash-ref req-data 'sender)])
      (env-update-variable! '__sender sender env)
      (env-update-variable! '__sender-id (hash-ref sender 'id) env))))

(define (is-admin-sender req-data)
  (and (hash-has-key? req-data 'sender)
       (let* ([sender (hash-ref req-data 'sender)]
              [sender-id (hash-ref sender 'id)])
         (findf (lambda (id) (= id sender-id)) admin-ids))))