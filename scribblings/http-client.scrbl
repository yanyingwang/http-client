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
                     (hasheq 'Content-Type "application/json" 'Accept "application/json")
                     (hasheq 'made-in "China" 'price 10)))

(http-bin-org 'get
              #:path "/fruits"
              #:data (hasheq 'color "red")
              #:headers (hasheq 'Token "temp-token-abcef"))

(http-post httpbin-org
           #:data (hasheq 'color "red")
           #:path "/fruits"
           #:headers (hasheq 'Token "temp-token-abcef"))

(http-post httpbin-org  ;; modify the headers to do the post using html form format.
           #:headers (hasheq 'Content-Type "application/x-www-form-urlencoded"))

(code:line
(define new-conn
  (struct-copy http-connection httpbin-org ;;  copying and modifying a predefined conn and headers to do a post using html form.
               [headers (hasheq 'Content-Type "application/x-www-form-urlencoded")]))
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
@defparam[current-http-user-agent v string?
          #:value string]{
set the user agent which is used by the time of doing the request to http server.
}

@defparam[current-http-response-auto v boolean?
          #:value #t]{
set it to false to disable the auto convertion of the response's body data.
}

@defstruct*[http-connection ([url string?]
                             [headers hasheq]
                             [data hasheq])]{
  construct a http-connection instance and use it with such as @racket[http-get] when you want to request the same website with similar data.
}

@defstruct*[http-response ([request http-request?]
                           [code number?]
                           [headers hasheq]
                           [body hasheq])]{
  You will get a http-response struct instance if you're doing a request using this lib's function such as @racket[http-get].
}

@defstruct*[http-request ([url string?]
                          [method symbol?]
                          [headers hasheq]
                          [data hasheq])]{
  for the most common time, http-request is included in the @racket[http-response] instance.
}

@defproc[(http-get [conn (or/c string? http-connection?)]
                   [#:data data hasheq (hasheq)]
                   [#:path path string? ""]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]{
request a website with get method.
}

@defthing[http-post http-respone?]{
same as @racket[http-get] except of doing a not get method request.
}

@defthing[http-head http-respone?]{
same as @racket[http-get] except of doing a not get method request.
}

@defthing[http-options http-respone?]{
same as @racket[http-get] except of doing a not get method request.
}

@defthing[http-put http-respone?]{
same as @racket[http-get] except of doing a not get method request.
}

@defthing[http-delete http-respone?]{
same as @racket[http-get] except of doing a not get method request.
}

@defthing[http-patch http-respone?]{
same as @racket[http-get] except of doing a not get method request.
}



@defproc[(http-do [method symbol?] [conn http-connection?]
                  [#:data data hasheq (hasheq)]
                  [#:path path string? ""]
                  [#:headers headers hasheq (hasheq)])
http-response?]{
a low level function to do the http request.
}



@section{Bug Report}
Please go to github and create an issue for this repo.

@section{TODOs}
@itemlist[
@item{global param of debug mode to show request and response log msg just like the ruby faraday.}
@item{define a global param for pretty-print-depth for write-proc to show customized depth.}
@item{make param of hasheq can also be alist and dict data.}
]
