#lang at-exp racket/base

(require (for-syntax racket/base racket/syntax)
         (file "./private/params.rkt")
         (file "./private/core.rkt"))
(provide (except-out (all-defined-out) define-http-methods) ;; TODO: add contracts to http-get/post...
         (all-from-out (file "./private/params.rkt"))
         (all-from-out (file "./private/core.rkt")))

(define-syntax (define-http-methods stx)
  (define (define-fun name)
    (with-syntax
        ([n name])
      #`(define (#,(format-id #'n "http-~a" (syntax-e #'n)) url
                 #:data [data (hasheq)]
                 #:path [path ""]
                 #:headers [headers (hasheq)])
          (define conn
            (if (string? url)
                (http-connection url (hasheq) (hasheq))
                url))
          (http-do 'n conn #:data data #:path path #:headers headers))))
  (syntax-case stx ()
    [(_ names ...)
     (with-syntax
         ([(define-funs ...)
           (map define-fun
                (syntax->list #'(names ...)))])
       #'(begin
           define-funs ...))]))
(define-http-methods get head post put delete options patch)


;;;;  =========> test :::
(module+ test
  (require rackunit)

  (define conn
    (http-connection "https://httpbin.org" (hasheq) (hasheq)))
  (define conn1
    (http-connection "https://httpbin.org/anything" (hasheq 'Content-Type "application/json" 'Accept "application/json") (hasheq 'made-in "China" 'price 10)))


  (check-true (current-http-client/response-auto))

  (let* ([res (http-get conn)]
         [res-headers (http-response-headers res)]
         [res-body (http-response-body res)])
    (check-equal? (http-response-code res) 200)
    (check-equal? (hash-ref res-headers 'Content-Type)
                  "text/html; charset=utf-8")
    (check-true (list? (http-response-body res))))

  (parameterize ([current-http-client/response-auto #f])
    (check-false (current-http-client/response-auto))
    (define res (http-get conn))
    (define res-headers (http-response-headers res))
    (define res-body (http-response-body res))
    (check-true (string? (http-response-body res))))

  (let* ([res (http-get conn #:path "/status/309")]
         [req (http-response-request res)])
    (check-equal? (http-request-url req) "https://httpbin.org/status/309")
    (check-equal? (http-request-method req) 'get)
    (check-equal? (http-response-code res) 309))


  (let* ([res (http-post conn1
                         #:path "/fruits"
                         #:data (hasheq 'color "red")
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

  (let* ([res (http-get (http-connection "https://httpbin.org/anything?fruit=apple" (hasheq) (hasheq)))]
         [req (http-response-request res)]
         [res-code (http-response-code res)]
         [res-body (http-response-body res)])
    (check-equal? res-code 200)
    (check-equal? (hash-ref res-body 'data)
                  "fruit=apple"))

  (let* ([res (conn 'get #:path "/anything" #:data (hasheq 'fruit "apple"))]
         [req (http-response-request res)]
         [res-code (http-response-code res)]
         [res-body (http-response-body res)])
    (check-equal? res-code 200)
    (check-equal? (hash-ref res-body 'data)
                  "fruit=apple"))

  ;; TODO: test body of the chinese web page like www.qq.com gb2312
  )
