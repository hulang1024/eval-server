#lang racket

(require "base.rkt"
         "env-manager.rkt")

(provide sandbox-global-env
         (all-from-out "base.rkt")
         (all-from-out "env-manager.rkt"))

; 全局环境
(define sandbox-global-env (make-sandbox-env))