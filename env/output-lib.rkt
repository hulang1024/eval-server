#lang racket
(require "../config.rkt")

(provide init-output-lib)


(define (init-output-lib env)
  (define in (open-input-file output-lib-path #:mode 'text))
  (define expr-string (string-append "(begin " (port->string in) "\n)"))
  (define expr (read (open-input-string expr-string)))
  (eval expr env))