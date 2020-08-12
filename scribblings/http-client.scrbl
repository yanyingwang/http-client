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
@examples[
#:eval (sanbox-eval)
(define conn1
  (http-connection "https://example.com" (hasheq) (hasheq)))
conn1

(define res (http-get conn1))
res
]

@section{Reference}

@section{Bug Report}
Please create an issue for this repo on the Github.


@section{TODO}
@itemlist[@item{item1}
          @item{item1-content}]
