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

(http-get "https://httpbin.org"
          #:path "anything/fruits"
          #:data (hasheq 'color "red" 'made-in "China" 'price 10)
          #:headers (hasheq 'Accept "application/json" 'Token "temp-token-abcef"))

(define httpbin-org
    (http-connection "https://httpbin.org/anything"
                     (hasheq 'Accept "application/json")
                     (hasheq 'made-in "China" 'price 10)))

(http-bin-org 'get
              #:path "/fruits"
              #:data (hasheq 'color "red")
              #:headers (hasheq 'Token "temp-token-abcef"))

(http-post httpbin-org
           #:data (hasheq 'color "red")
           #:path "/fruits"
           #:headers (hasheq 'Token "temp-token-abcef"))

(http-post httpbin-org  ;; change the headers to do the post using html form format.
           #:headers (hasheq 'Accept "application/x-www-form-urlencoded"))

(code:line
(define new-conn
  (struct-copy http-connection httpbin-org ;;  copying and changing a predefined conn and headers to do a post using html form.
               [headers (hasheq 'Accept "application/x-www-form-urlencoded")]))
(http-post new-conn)
)

(code:line
(define res (http-post "https://httpbin.org/anything"
                       #:data (hasheq 'color "red")))
(http-response-body res) ;; the body of a response is auto converted to the racket type data unless you set @racket[current-http-response-auto].
)

(parameterize ([current-http-response-auto #f]) ;; set @racket[current-http-response-auto] to #f to get a raw format http response body.
  (define res (http-post "https://httpbin.org/anything"
                         #:data (hasheq 'color "red")))
  (http-response-body res))

)

@section{Reference}
...
...
...

@section{Bug Report}
Please go to github and create an issue for this repo.

@section{TODO}
@itemlist[
@item{global param of debug mode to show request and response log msg just like the ruby faraday.}
@item{define a global param for pretty-print-depth for write-proc to show customized depth.}
@item{make param of hasheq can also be alist and dict data.}
]
