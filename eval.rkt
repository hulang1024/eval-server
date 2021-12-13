#lang racket

(require web-server/private/timer
         "eval/main.rkt"
         "exn.rkt")

(provide eval-api
         eval-config-api
         eval-enable-api)

(define eval-timeout-ms 3000)

(define timer-manager (start-timer-manager))

(define enable #t)

(define (eval-api req-data)
  (if enable
      (let ([result #f]
            [eval-thread #f])
        (start-timer timer-manager (/ eval-timeout-ms 1000)
                     (λ ()
                       (when (not (thread-dead? eval-thread))
                         (kill-thread eval-thread)
                         (set! result (hash 'error (format "程序执行超时(>~Ams)" eval-timeout-ms))))))
  
        (set! eval-thread
              (thread
               (λ ()
                 (let ([handled-value
                        (with-handlers ([(const #t) (lambda (v) v)])
                          (eval-request req-data))])
                   (if (exn:fail? handled-value)
                       (set! result
                             (hash 'code 1
                                   'error (exn-message handled-value)
                                   'data (exn->response-data handled-value)))
                       (begin
                         (set! result handled-value)
                         (hash-set! result 'code 0)))))))
  
        (thread-wait eval-thread)
        result)
      (hash 'code 2 'error "eval已禁用")))

(define (eval-config-api req-data)
  (define timeout (hash-ref req-data 'timeout))
  (set! eval-timeout-ms timeout)
  (hash 'code 0))

(define (eval-enable-api req-data)
  (set! enable (equal? (hash-ref req-data 'enable) 1))
  (hash 'code 0))