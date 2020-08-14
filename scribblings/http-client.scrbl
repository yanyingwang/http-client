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

Still under contruction....

@[table-of-contents]



@section{Example}
@#reader scribble/comment-reader
(examples
#:eval (sanbox-eval)

(define conn
    (http-connection "https://httpbin.org/anything"
                     (hasheq 'Accept "application/json")
                     (hasheq 'made-in "China" 'price 10)))
(define res
  (http-post conn (hasheq 'color "red")
             #:path "/fruits"
             #:headers (hasheq 'Token "temp-token-abcef")))


(http-response-code res)
(http-response-headers res)
(http-response-body res)
;; http response body is auto converted to the racket types.


(define res1
  (http-post conn (hasheq 'color "red")
             #:path "/fruits"
             #:headers (hasheq 'Accept "application/x-www-form-urlencoded")))
(http-response-code res1)
(http-response-headers res1)
(http-response-headers res1)


(parameterize ([current-http-response-auto #f])
  (http-response-body (http-get conn))))
;; set current-http-response-auto to #f to get a raw format http response body.

@section{Reference}

@section{Bug Report}
Please create an issue for this repo on the Github.


@section{TODO}
@itemlist[@item{optimize the shown of struct in terminal, missing double quotation marks when content is too long}
          @item{add contracts to provide funcs}
          @item{fix TODOs comments of code}]
