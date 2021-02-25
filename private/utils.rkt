#lang at-exp racket/base

(require debug/repl)
(require racket/pretty
         racket/format
         (file "./params.rkt"))

(provide (all-defined-out))


(define (http-client-pp-kv k v)
  ;; @~a{@|k|: @(pretty-format v 'infinity)}
  @~a{@|k|: @v})

(define (http-client-display data port)
  (parameterize ([pretty-print-depth (current-http-client/pretty-print-depth)])
    (pretty-display data port)))


;; (pretty-print-size-hook (lambda (a b c) 1))



;; (define (format-kv k v)
;;   (define length (string-length (~a v)))
;;   (define marker @~a{......[@length]})
;;   @~a{@|k|: @(~v @v #:max-width 128 #:limit-marker @marker)})
