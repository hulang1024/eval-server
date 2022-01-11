#lang racket

(require web-server/servlet
         web-server/servlet-env
         json
         "eval/main.rkt"
         "config.rkt"

         "eval.rkt"
         "env-manager.rkt")


(define path-api-map
  (hash
   "eval" eval-api
   "eval/config" eval-config-api
   "eval/enable" eval-enable-api
   "env/create" create-env-api
   "env/rename" rename-env-api
   "env/reset" reset-env-api
   "env/remove" remove-env-api
   "env/ids" get-env-ids-api))
                      
(define (route-api path req-data)
  (let ([api (hash-ref path-api-map path)])
    (api req-data)))

(define (main-server req)
  (define req-data (bytes->jsexpr (request-post-data/raw req)))

  (define path (hash-ref req-data 'path))

  (define result (route-api path req-data))
  
  (response 200 #"OK"
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