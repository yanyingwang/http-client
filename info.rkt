#lang info
(define collection "http-client")
(define deps '("base" "html-parsing" "at-exp-lib" "gregor"))
(define build-deps '("scribble-lib" "racket-doc" "rackunit-lib" "scribble-rainbow-delimiters"))
(define scribblings '(("scribblings/http-client.scrbl" ())))
(define pkg-desc "A practical http client library for sending data to http servers.")
(define version "0.2")
(define pkg-authors '("Yanying Wang"))
