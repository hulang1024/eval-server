#lang racket
(require "config.rkt")
         
(provide resource-api)


(define (resource-api file-path)
  (define in (open-input-file (build-path data-dir-path file-path)))
  (define file-bytes (port->bytes in))

  (response 200 #"OK"
            (current-seconds)
            #"image/png"
            empty
            (λ (out) (write-bytes file-bytes out))))