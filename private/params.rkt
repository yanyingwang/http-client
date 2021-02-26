#lang at-exp  racket/base


(require racket/format)
(provide (all-defined-out))


(define current-http-client/pretty-print-depth
  (make-parameter 1))

(define current-http-client/response-auto
  (make-parameter #t))

(define current-http-client/user-agent
  (make-parameter @~a{http-client[@(system-type)/@(system-type 'vm)/@(version)]}))
