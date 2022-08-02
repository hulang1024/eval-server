; 此文件源码在沙盒环境内执行
(require (only-in racket/list last)
         (only-in racket/class make-object send)
         (only-in racket/draw make-bitmap bitmap-dc%)
         (only-in rnrs/io/ports-6 port-position)
         (only-in 2htdp/image image? image-width image-height)
         (only-in mrlib/image-core render-image))

(define __eval-output-objects null)
(define __default-output-last-position 0)

(define (__get-eval-output-objects)
  (__eval-output-append-text __default-output)
  __eval-output-objects)


(define (__output-handler value port)
  (__eval-output-append-text port)
  (cond
    [(image? value)
     (__eval-output-add-image #:path (__get-image-path value))]
    [else
     (define out (open-output-string))
     (display value out)
     (__eval-output-add-text (get-output-string out))]))


(define (__eval-output-append-text port)
  (define end (port-position port))
  (when (> (- end __default-output-last-position) 0)
    (define s (get-output-string port))
    (define content (substring s __default-output-last-position (min (string-length s) end)))
    (__eval-output-add-text content))
  (set! __default-output-last-position end))


(define (__eval-output-add-text new-text)
  (define to-add?
    (cond
      [(null? __eval-output-objects) #t]
      [else
       (define last-el (last __eval-output-objects))
       (cond
         [(string=? (hash-ref last-el 'type) "text")
          ; 将新文本合并到上个文本里
          (define pre-text (hash-ref last-el 'content))
          (hash-set! last-el 'content (string-append pre-text new-text))
          #f]
         [else #t])]))
  (when to-add?
    (__eval-output-add (make-hash `((type . "text") (content . ,new-text))))))

(define (__eval-output-add-image #:path [path ""] #:url [url ""])
  (__eval-output-add (hash 'type "image" 'path path 'url url)))

(define (__eval-output-add-audio #:path [path ""] #:url [url ""])
  (__eval-output-add (hash 'type "audio" 'path path 'url url)))

(define (__eval-output-add elem)
  (set! __eval-output-objects (append __eval-output-objects (cons elem null))))


(define (__reset-output-handler)
  (set! __eval-output-objects null)
  (set! __default-output-last-position 0)
  (port-display-handler __default-output __output-handler)
  (port-write-handler __default-output __output-handler)
  (port-print-handler __default-output __output-handler))


(define (__get-image-path image)
  (define (save-image image path)
    (define padding 12)
    (define bm (make-bitmap (+ padding (inexact->exact (ceiling (image-width image))))
                            (+ padding (inexact->exact (ceiling (image-height image))))))
    (define bdc (make-object bitmap-dc% bm))
    (send bdc set-smoothing 'aligned)
    (send bdc erase)
    (render-image image bdc (/ padding 2) (/ padding 2))
    (send bdc set-bitmap #f)
    (send bm save-file path 'png 100))
  (define filename (string-append (number->string (current-milliseconds) 16) ".png"))
  (define path (build-path __data-dir-path filename))
  (save-image image path)
  (path->string path))