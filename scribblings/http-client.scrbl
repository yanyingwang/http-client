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


@section[#:tag "common-usage-example"]{Common Usage Example}
@subsection{Explicitly request URLs}
Request @litchar{https://httpbin.org/anything/fruits?color=red&made-in=China&price=10} with setting request headers @litchar{Token: your-token} in Racket would be like below:
@codeblock|{
(http-get "https://httpbin.org"
          #:path "anything/fruits"
          #:data (hasheq 'color "red" 'made-in "China" 'price 10)
          #:headers (hasheq 'Token "your-token"))
}|

@subsection[#:tag "request-nuance-urls"]{Request nuance URLs}
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
@subsection{Parameters}
@defparam[current-http-client/user-agent v string? #:value "http-client[your-system-name/your-vm-sytem-type-name/your-racket-version]"]{
The user agent name used by requesting the HTTP servers.
}

@defparam[current-http-client/response-auto v boolean? #:value #t]{
Set this parameter to @racket[#f] to disable the auto convertion of the response's body data.
In another word, @racket[http-response-body] of a @racket[http-response] will be a raw string if set this parameter to @racket[#f].
}

@defparam[current-http-client/pretty-print-depth v integer? #:value 1]{
This parameter is used by displaying structs of @racket[http-connection]/@racket[http-request]/@racket[http-response], check @racket[pretty-print-depth] for implement details.
@examples[#:eval (the-eval)
(current-http-client/pretty-print-depth)
(define conn1
(http-connection "https://httpbin.org/anything"
(hasheq 'Content-Type "application/json" 'Accept "application/json")
(hasheq 'made-in "China" 'price 10)))
conn1
(current-http-client/pretty-print-depth 2)
conn1
]
}

@subsection{Structs}
The displaying of HTTP client strcuts is controlled by @racket[current-http-client/pretty-print-depth].

@defstruct*[http-connection ([url string?]
                             [headers hasheq]
                             [data hasheq])]{
Construct a @racket[http-connection] instance and use it later by such as @racket[http-get] when you're requesting same website with nuance path/data/headers, check @secref["request-nuance-urls"] for usage examples.
}

@defstruct*[http-response ([request http-request?]
                           [code number?]
                           [headers hasheq]
                           [body hasheq])]{
You will get a @racket[http-response] struct instance if you're doing a request such as using @racket[http-get].
}

@defstruct*[http-request ([url string?]
                          [method symbol?]
                          [headers hasheq]
                          [data hasheq])]{
Mostly, @racket[http-request] is included in the @racket[http-response] instance.
}

@subsection{Requests}
@deftogether[(
@defproc[(http-get [conn (or/c string? http-connection?)]
                   [#:path path string? ""]
                   [#:data data hasheq (hasheq)]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-post [conn (or/c string? http-connection?)]
                   [#:path path string? ""]
                   [#:data data hasheq (hasheq)]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-head [conn (or/c string? http-connection?)]
                   [#:path path string? ""]
                   [#:data data hasheq (hasheq)]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-options [conn (or/c string? http-connection?)]
                   [#:path path string? ""]
                   [#:data data hasheq (hasheq)]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-put [conn (or/c string? http-connection?)]
                   [#:path path string? ""]
                   [#:data data hasheq (hasheq)]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-delete [conn (or/c string? http-connection?)]
                   [#:path path string? ""]
                   [#:data data hasheq (hasheq)]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
@defproc[(http-patch [conn (or/c string? http-connection?)]
                   [#:path path string? ""]
                   [#:data data hasheq (hasheq)]
                   [#:headers headers hasheq (hasheq)])
         http-resonse?]
)]{
Procedures to do the http requests.
}

@defproc[(http-do [method symbol?] [conn http-connection?]
                  [#:data data hasheq (hasheq)]
                  [#:path path string? ""]
                  [#:headers headers hasheq (hasheq)])
http-response?]{
The low level function to do the http requests.
}



@section{Others}
@subsection{Bug Report}
Please go to github and create an issue for this repo.

@subsection{TODOs}
@itemlist[
@item{global param of debug mode to show request and response log msg just like the ruby faraday.}
@item{define a global param for pretty-print-depth for write-proc to show customized depth.}
@item{make param of hasheq can also be alist and dict data.}
]

@subsection{Change Logs}
@itemlist[
@item{fix get urls with params will raise error and enhance docs --2021/02/26}
]
