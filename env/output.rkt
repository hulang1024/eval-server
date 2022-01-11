; 此文件源码在沙盒环境内执行
(require racket/snip
         2htdp/image
         (only-in mrlib/image-core render-image)
         (only-in racket/draw make-bitmap bitmap-dc%))

(define __eval-output null)

(define (__output-handler value port)
  (define elem
    (cond
      [(image? value)
       (hash 'type "image"
             'path (get-image-url-path value))]
      [else
       (define out (open-output-string))
       (display value out)
       (hash 'type "text"
             'content (get-output-string out))]))
  (set! __eval-output (append __eval-output (cons elem null))))

(define (__reset-output-handler)
  (set! __eval-output null)
  (port-display-handler __default-output __output-handler)
  (port-write-handler __default-output __output-handler))
  
(define (get-image-url-path image)
  (define filename (string-append (number->string (current-milliseconds) 16) ".png"))
  (define path (build-path __data-dir-path "image" filename))
  (save-image image path)
  (path->string path))

(define (save-image image path)
  (define bm (make-bitmap (inexact->exact (ceiling (image-width image)))
                          (inexact->exact (ceiling (image-height image)))))
  (define bdc (make-object bitmap-dc% bm))
  (send bdc set-smoothing 'aligned)
  (send bdc erase)
  (render-image image bdc 0 0)
  (send bdc set-bitmap #f)
  (send bm save-file path 'png))