#lang scribble/manual
@(require (for-label http-client
                     racket/base
                     racket/pretty)
           scribble/eval)

@(define the-eval
   (make-eval-factory '(http-client)))

@title{HTTP Client}
@author[(author+email "Yanying Wang" "yanyingwang1@gmail.com")]


@defmodule[http-client]
A practical Racket HTTP client for interacting data with HTTP servers.
@table-of-contents[]


@section{Common Usage Example}
@subsection{Explicitly request URLs}
Request @litchar{https://httpbin.org/anything/fruits?color=red&made-in=China&price=10} with setting request headers @litchar{Token: your-token} in Racket would be like below:
@codeblock|{
(http-get "https://httpbin.org"
          #:path "anything/fruits"
          #:data (hasheq 'color "red" 'made-in "China" 'price 10)
          #:headers (hasheq 'Token "your-token"))
}|

@subsection{Request nuance URLs}
You can define a @racket[http-connection], and use it to do requests with modifying some details of it.

@subsubsection{Define connections}
Predefine a @racket[http-connection] with presetted url/path/headers/data:
@codeblock|{
(define httpbin-org/anthing
    (http-connection "https://httpbin.org/anything"
                     (hasheq 'Content-Type "application/json")
                     (hasheq 'made-in "China" 'price 10)))
}|

@subsubsection{Do the requests}
Do a GET request with adding path/data/headers to the predefined @racket[http-connection]:

@itemlist[
@item{
get @litchar{https://httpbin.org/anything/fruits?made-in=China&price=10&color=red} with setting request headers @litchar{Token: your-token; Another-Token: your-another-token} in Racket:
@codeblock|{
(http-get http-bin-org/anthing
              #:path "/fruits"
              #:data (hasheq 'color "red")
              #:headers (hasheq 'Another-Token "your-another-token"))
}|

and previous code is supported to be written in another way:
@codeblock|{
(http-bin-org/anthing 'get
              #:path "/fruits"
              #:data (hasheq 'color "red")
              #:headers (hasheq 'Another-Token "your-another-token"))
}|
}

@item{
do a POST request like @litchar{curl https://httpbin.org/anything/fruits --header "Content-Type: application/application/x-www-form-urlencoded; Token: your-overwritten-token" -d '{"make-in": "China", "price": "10", "color": "red"}'} in Raket:
@codeblock|{
(http-post httpbin-org/anthing
           #:path "/fruits"
           #:data (hasheq 'color "red")
           #:headers (hasheq 'Content-Type "application/x-www-form-urlencoded" 'Token "your-overwritten-token"))
}|
}

@item{
do a POST request with copying and modifying the predefined @racket[http-connection]'s headers to @litchar{Content-Type: application/x-www-form-urlencoded}:
@codeblock|{
(define new-conn
  (struct-copy http-connection httpbin-org
               [headers (hasheq 'Content-Type "application/x-www-form-urlencoded")]))

(http-post new-conn)
}|
}
]



@; (code:line
@; (define res (http-post "https://httpbin.org/anything"
@;                        #:data (hasheq 'color "red")))
@; (http-response-body res) ;; the body of a response is auto converted to the racket type data unless you set @racket[current-http-response-auto].
@; )

@; (parameterize ([current-http-response-auto #f]) ;; set @racket[current-http-response-auto] to #f to get a raw format http response body.
@;   (define res (http-post "https://httpbin.org/anything"
@;                          #:data (hasheq 'color "red")))
@;   (http-response-body res))
@; ]



@section{Reference}

@deftogether[(
@defparam[current-http-client/user-agent v string? #:value "http-client[system-name/vm-name-racket-version]"]
@defparam[current-http-client/response-auto v boolean? #:value #t]
@defparam[current-http-client/pretty-print-depth v integer? #:value 1]

)]{
@racket[current-http-client/user-agent] is the user agent name used by requesting HTTP servers.   @(linebreak)
set @racket[current-http-client/response-auto] to false to disable the auto convertion of the response's body data.   @(linebreak)
@; @racket[current-http-client/pretty-print-depth] is used for http-client to display struct, check @[pretty-print-depth] for more.   @(linebreak)

@examples[#:eval (the-eval)
(current-http-client/pretty-print-depth)
(define conn1
   (http-connection "https://httpbin.org/anything"
                    (hasheq 'Content-Type "application/json" 'Accept "application/json")
                    (hasheq 'made-in "China" 'price 10)))
conn1

(current-http-client/pretty-print-depth 2)
conn1
]}







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





@deftogether[(
@defproc[(http-get [conn (or/c string? http-connection?)]
                   [#:data data hasheq (hasheq)]
                   [#:path path string? ""]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-post [conn (or/c string? http-connection?)]
                   [#:data data hasheq (hasheq)]
                   [#:path path string? ""]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-head [conn (or/c string? http-connection?)]
                   [#:data data hasheq (hasheq)]
                   [#:path path string? ""]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-options [conn (or/c string? http-connection?)]
                   [#:data data hasheq (hasheq)]
                   [#:path path string? ""]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-put [conn (or/c string? http-connection?)]
                   [#:data data hasheq (hasheq)]
                   [#:path path string? ""]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-delete [conn (or/c string? http-connection?)]
                   [#:data data hasheq (hasheq)]
                   [#:path path string? ""]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-patch [conn (or/c string? http-connection?)]
                   [#:data data hasheq (hasheq)]
                   [#:path path string? ""]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
)]{
Fucntions to do the http request.
}


@defproc[(http-do [method symbol?] [conn http-connection?]
                  [#:data data hasheq (hasheq)]
                  [#:path path string? ""]
                  [#:headers headers hasheq (hasheq)])
http-response?]{
The low level function to do the http request.
}



@section{Bug Report}
Please go to github and create an issue for this repo.

@section{TODOs}
@itemlist[
@item{global param of debug mode to show request and response log msg just like the ruby faraday.}
@item{define a global param for pretty-print-depth for write-proc to show customized depth.}
@item{make param of hasheq can also be alist and dict data.}
]
