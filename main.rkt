#lang racket

(require web-server/servlet
         web-server/servlet-env
         web-server/private/timer
         json)
(require "core.rkt")
(require "config.rkt")

(define eval-timeout-ms 300)

(define timer-manager (start-timer-manager))

(define (main-server req)
  (define req-data (bytes->jsexpr (request-post-data/raw req)))

  (define eval-thread #f)
  (define result #f)
  
  (start-timer timer-manager (/ eval-timeout-ms 1000)
               (λ ()
                 (when (not (thread-dead? eval-thread))
                   (kill-thread eval-thread)
                   (set! result (hash 'error (format "程序执行超时(>~Ams)" eval-timeout-ms))))))
  
  (set! eval-thread
        (thread
         (λ ()
           (set! result (eval-request req-data)))))
  
  (thread-wait eval-thread)
  (response
            200 #"OK"
            (current-seconds)
            APPLICATION/JSON-MIME-TYPE
            empty
            (λ (out) (write-string (jsexpr->string result) out))))

(displayln "\nStarting...\n")
(init)
(define server-ip "127.0.0.1")
(displayln "\nStartup success.\n")
(displayln (format "Server running at: http://~A:~A" server-ip server-port))
(serve/servlet main-server
               #:port server-port
               #:listen-ip server-ip
               #:command-line? #t
               #:servlet-path "/")