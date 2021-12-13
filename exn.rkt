#lang racket

(provide exn->response-data)

(define (exn->response-data exn)
  (cond
    [(exn:fail:contract:variable? exn)
     (hash 'type "variable"
           'id (symbol->string (exn:fail:contract:variable-id exn)))]
    [(exn:fail:read? exn)
     (hash 'type "read")]
    [(exn:fail:syntax? exn)
     (hash 'type "syntax")]
    [(exn:fail:out-of-memory? exn)
     (hash 'type "out-of-memory")]
    [else 0]))