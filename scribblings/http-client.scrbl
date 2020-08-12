#lang scribble/manual
@require[@for-label[http-client
                    racket/base]
          scribble/eval]

@(define sanbox-eval
   (make-eval-factory '(http-client)))

@title{http-client}
@author[(author+email "Yanying Wang" "yanyingwang1@gmail.com")]

@defmodule[http-client]

A practical http client library for sending data to http servers.

@[table-of-contents]



@section{Example}
@#reader scribble/comment-reader
(examples
#:eval (sanbox-eval)

;; check default value
(current-http-response-autoc)

(define conn1
(http-connection "https://example.com" (hasheq) (hasheq)))

(define res (http-get conn1))

(http-response-code res)
(http-response-headers res)
;; auto converted to racket type values.
(car (http-response-body res))

(parameterize ([current-http-response-autoc #f])
(substring (http-response-body (http-get conn1)) 0 50))

;; globally change to show the raw http response body.
(current-http-response-autoc #f)
(substring (http-response-body (http-get conn1)) 0 50)
)

@section{Reference}

@section{Bug Report}
Please create an issue for this repo on the Github.


@section{TODO}
@itemlist[@item{item1}
          @item{item2}]
