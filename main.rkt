#lang at-exp racket/base

(require racket/string
         racket/list
         racket/hash
         racket/port
         racket/match
         racket/format
         net/http-client
         net/uri-codec
         net/url-string
         json
         xml
         html-parsing)

(provide current-http-user-agent
         current-http-response-auto
         http-connection
         http-connection-url
         http-connection-headers
         http-connection-data

         http-request
         http-request-url
         http-request-headers
         http-request-data

         http-response
         http-response-request
         http-response-code
         http-response-headers
         http-response-body

         ;; TODO: add contracts
         http-get
         http-head
         http-post
         http-put
         http-delete
         http-options
         http-patch
         )


(define current-http-user-agent
  (make-parameter @~a{http-client[@(system-type)/@(system-type 'vm)-@(version)]}))
(define current-http-response-auto (make-parameter #t))


(struct http-connection (url headers data) ;; TODO: auto fill in different values for different fields.
  #:methods gen:custom-write
  [(define (write-proc conn port mode)
     (define (fmcl k v)
       (define length (string-length (~a v)))
       (define marker @~a{......[@length]})
       @~a{@|k|: @(~v @v #:max-width 128 #:limit-marker @marker)})
     (display @~a{#<http-connection
                  @(fmcl "url" @(http-connection-url conn))
                  @(fmcl "headers" @(http-connection-headers conn))
                  @(fmcl "data" @(http-connection-data conn))
                  >} port))])

;; TODO: http-request should be derived from http-connection
(struct http-request (url method headers data)
  #:methods gen:custom-write
  [(define (write-proc rqt port mode)
     ;; TODO: seperated fmcl for every struct.
     (define (fmcl k v)
       (define length (string-length (~a v)))
       (define marker @~a{......[@length]})
       @~a{@|k|: @(~v @v #:max-width 128 #:limit-marker @marker)})

     (display @~a{#<http-request
                  @(fmcl "url" @(http-request-url rqt))
                  @(fmcl "method" @(http-request-method rqt))
                  @(fmcl "headers" @(http-request-headers rqt))
                  @(fmcl "data" @(http-request-data rqt))
                  >} port))])

(struct http-response (request code headers body)
  #:methods gen:custom-write
  [(define (write-proc self port mode)
     (define rqt (http-response-request self))
     (define (fmcl k v)
       (define length (string-length (~a v)))
       (define marker @~a{......[@length]})
       @~a{@|k|: @(~v @v #:max-width 128 #:limit-marker @marker)})
     (display @~a{#<http-response
                  #<request @(~v @(http-request-method rqt) @(http-request-url rqt)) ...>
                  @(fmcl "code" @(http-response-code self))
                  @(fmcl "headers" @(http-response-headers self))
                  @(fmcl "body" @(http-response-body self))
                  >} port))])

;; TODO: make below be used.
;; (define-syntax define-http-method
;;   (syntax-rules ()
;;     [(_ method)
;;      (define abc method)]))
;; (define-http-method 'get)

(define (http-get conn [data (hasheq)]
                  #:path [path ""]
                  #:headers [headers (hasheq)])
  (http-do 'get conn data #:path path #:headers headers))

(define (http-head conn [data (hasheq)]
                   #:path [path ""]
                   #:headers [headers (hasheq)])
  (http-do 'head conn data #:path path #:headers headers))

(define (http-post conn [data (hasheq)]
                   #:path [path ""]
                   #:headers [headers (hasheq)])
  (http-do 'post conn data #:path path #:headers headers))

(define (http-put conn [data (hasheq)]
                   #:path [path ""]
                   #:headers [headers (hasheq)])
  (http-do 'put conn data #:path path #:headers headers))

(define (http-delete conn [data (hasheq)]
                   #:path [path ""]
                   #:headers [headers (hasheq)])
  (http-do 'delete conn data #:path path #:headers headers))

(define (http-options conn [data (hasheq)]
                   #:path [path ""]
                   #:headers [headers (hasheq)])
  (http-do 'options conn data #:path path #:headers headers))

(define (http-patch conn [data (hasheq)]
                   #:path [path ""]
                   #:headers [headers (hasheq)])
  (http-do 'patch conn data #:path path #:headers headers))



(define (http-do method conn [data1 (hasheq)]
                 #:path [path ""]
                 #:headers [headers1 (hasheq)])

  (define url (string->url (http-connection-url conn)))
  (define data2 (http-connection-data conn))
  (define data3 (make-hash (url-query url)))
  (define headers2 (http-connection-headers conn))
  (define req-path1
    (for/list ([e (url-path url)])
      (string-append "/" (path/param-path e))))
  (define req-path2
    (for/list ([e (string-split path "/")])
      (string-append "/" e)))
  (define req-path1&2 (append req-path1 req-path2))

  (define req-host (url-host url))
  (define req-path (if (empty? req-path1&2)
                       "/"
                       (string-join req-path1&2 "")))

  (define req-headers (hash-union headers1 headers2 (hasheq 'User-Agent (current-http-user-agent))
                                  #:combine/key (lambda (k v1 v2) v1)))
  (define req-data (hash-union data1 data2 data3
                               #:combine/key (lambda (k v1 v2) v1)))
  (define req (http-request (string-append (url-scheme url)
                                           "://"
                                           req-host
                                           (if (url-port url) (url-port url) "")
                                           req-path)
                            method req-headers req-data))

  (define req-headers-raw
    (hash-map req-headers
              (lambda (k v) (~a k ": " v))))
  (define req-data-raw
    (match req-headers
      ;; [(? hash-empty?) ""]
      [(hash-table ('Accept "application/json")) (jsexpr->string req-data)]
      ;; [(hash-table ('Accept "application/x-www-form-urlencoded")) (alist->form-urlencoded (hash->list req-data))]
      [_ (alist->form-urlencoded (hash-map req-data
                                           (lambda (k v)
                                             (cons k (if (number? v)
                                                         (number->string v)
                                                         v)))))]))

  (define-values (res-status-raw res-headers-raw res-in)
    (http-sendrecv req-host req-path
                   #:ssl? (match (url-scheme url) ["https" #t] [_ #f])
                   #:method (string-upcase (symbol->string method))
                   #:port (match (url-port url)
                            [(? integer? n) n]
                            [#f #:when (string=? (url-scheme url) "https")
                             443]
                            [_ 80])
                   #:headers req-headers-raw
                   #:data req-data-raw))
  (define res-body-raw (port->string res-in))

  (define res-code
    (string->number (second (string-split (bytes->string/utf-8 res-status-raw)))))
  (define res-headers
    (for/hasheq ([e res-headers-raw])
      (match (string-split (bytes->string/utf-8 e) ":")
        [(list-rest a b)
         (define k (string->symbol a))
         (define v (string-trim (string-join b)))
         (values k v)])))

  (define res-body
    (match res-headers
      [_ #:when (not (current-http-response-auto))
         res-body-raw]
      [(hash-table ('Content-Type (regexp #rx"^application/json.*")))
       (string->jsexpr res-body-raw)]
      [(hash-table ('Content-Type (regexp #rx"^text/html.*")))
       (html->xexp res-body-raw)]
      [(hash-table ('Content-Type (regexp #rx"^(application/xml|text/xml|application/xhtml+xml).*")))
       (string->xexpr res-body-raw)]
      [_ res-body-raw]))

  (http-response req res-code res-headers res-body))




(module+ test
  (require rackunit)

  (define conn
    (http-connection "https://httpbin.org" (hasheq) (hasheq)))
  (define conn1
    (http-connection "https://httpbin.org/anything" (hasheq 'Accept "application/json") (hasheq 'made-in "China" 'price 10)))


  (check-true (current-http-response-auto))

  (let* ([res (http-get conn)]
         [res-headers (http-response-headers res)]
         [res-body (http-response-body res)])
    (check-equal? (http-response-code res) 200)
    (check-equal? (hash-ref res-headers 'Content-Type)
                  "text/html; charset=utf-8")
    (check-true (list? (http-response-body res))))

  (parameterize ([current-http-response-auto #f])
    (check-false (current-http-response-auto))
    (define res (http-get conn))
    (define res-headers (http-response-headers res))
    (define res-body (http-response-body res))
    (check-true (string? (http-response-body res))))

  (let* ([res (http-get conn #:path "/status/309")]
         [req (http-response-request res)])
    (check-equal? (http-request-url req) "https://httpbin.org/status/309")
    (check-equal? (http-request-method req) 'get)
    (check-equal? (http-response-code res) 309))


  (let* ([res (http-post conn1 (hasheq 'color "red")
                         #:path "/fruits"
                         #:headers (hasheq 'Token "temp-token-abcef"))]
         [req (http-response-request res)]
         [res-code (http-response-code res)]
         [res-headers (http-response-headers res)]
         [res-body (http-response-body res)])

    (check-equal? (http-request-url req)
                  "https://httpbin.org/anything/fruits")
    (check-equal? (http-request-method req) 'post)
    (check-match (http-request-headers req)
                 (hash-table ('Accept "application/json") ('Token "temp-token-abcef")))
    (check-equal? (http-request-data req)
                  (hasheq 'color "red" 'made-in "China" 'price 10))

    (check-equal? res-code 200)
    (check-match res-headers
                 (hash-table ('Content-Type "application/json")))
    (check-pred hash? res-body)

    ;; check client's request headers and data, which was responsed by the httpbin.org in the response body.
    (check-equal? (hash-ref res-body 'url)
                  "https://httpbin.org/anything/fruits")
    (check-match (hash-ref res-body 'headers)
                 (hash-table ('Accept "application/json")
                             ('Token "temp-token-abcef")))
    (check-equal? (hash-ref res-body 'data)
                  "{\"price\":10,\"color\":\"red\",\"made-in\":\"China\"}"))

  (let* ([res (http-get conn1
                        #:headers (hasheq 'Accept "application/x-www-form-urlencoded"))]
         [req (http-response-request res)]
         [res-code (http-response-code res)]
         [res-body (http-response-body res)])
    (check-equal? res-code 200)
    (check-equal? (hash-ref res-body 'data)
                  "price=10&made-in=China"))

  ;; TODO: test body of the chinese web page like www.qq.com
  )
