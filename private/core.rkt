#lang at-exp racket/base

(require racket/string racket/list racket/hash racket/port
         racket/match racket/format
         net/http-client net/uri-codec net/url-string
         json xml html-parsing
         (file "./params.rkt") (file "./utils.rkt"))
(provide (all-defined-out))


(struct http-connection (url headers data)
  #:property prop:procedure
  (lambda (self method
           #:path [path ""]
           #:data [data (hasheq)]
           #:headers [headers (hasheq)])
    (http-do method self #:data data #:path path #:headers headers))
  #:methods gen:custom-write
  [(define (write-proc self port mode)
     (display @~a{#<http-connection @(~v (http-connection-url self)) @(http-client-pp-kv "headers" @(http-connection-headers self)) @(http-client-pp-kv "data" @(http-connection-data self))>} port))])

;; TODO: http-request should be derived from http-connection
(struct http-request (url method headers data)
  #:methods gen:custom-write
  [(define (write-proc rqt port mode)
     (display @~a{#<http-request @(string-upcase (~a (http-request-method rqt))) @(~v (http-request-url rqt)) @(http-client-pp-kv "headers" @(http-request-headers rqt)) @(http-client-pp-kv "data" @(http-request-data rqt))>} port)
     )])

(struct http-response (request code headers body)
  #:methods gen:custom-write
  [(define (write-proc self port mode)
     (define rqt (http-response-request self))
     (define rqt-txt @~a{@(string-upcase (~a (http-request-method rqt))) @(~v (http-request-url rqt))})
     (display @~a{#<http-response #<request @|rqt-txt|> @(http-client-pp-kv "code" @(http-response-code self)) @(http-client-pp-kv "headers" @(http-response-headers self)) @(http-client-pp-kv "body" @(http-response-body self))>} port))])


(define (http-do method conn
                 #:data [data1 (hasheq)]
                 #:path [path ""]
                 #:headers [headers1 (hasheq)])
  (define url (string->url (http-connection-url conn)))
  (define data2 (http-connection-data conn))
  (define data3 (make-hasheq (url-query url)))
  (define headers2 (http-connection-headers conn))
  (define req-path1
    (filter non-empty-string? (map path/param-path (url-path url))))
  (define req-path2
    (string-split path "/"))
  (define req-path1&2 (append req-path1 req-path2))
  (define req-path1&2/encode (map uri-encode req-path1&2))
  (define req-host (url-host url))
  (define req-path (string-join (map (lambda (e) (string-append "/" e))  req-path1&2/encode) ""))
  (define req-headers (hash-union headers1 headers2 (hasheq 'User-Agent (current-http-client/user-agent))
                                  #:combine/key (lambda (k v1 v2) v1)))
  (define req-data (hash-union data1 data2 data3
                               #:combine/key (lambda (k v1 v2) v1)))
  (define req-headers-raw
    (hash-map req-headers
              (lambda (k v) (~a k ": " v))))
  (define req-data-raw
    (match req-headers
      ;; [(? hash-empty?) ""]
      [(hash-table ('Content-Type "application/json")) (jsexpr->string req-data)]
      ;; [(hash-table ('Accept "application/x-www-form-urlencoded")) (alist->form-urlencoded (hash->list req-data))]
      [_ (alist->form-urlencoded (hash-map req-data
                                           (lambda (k v)
                                             (cons k (if (number? v)
                                                         (number->string v)
                                                         v)))))]))
  (when (and (eq? method 'get) (non-empty-string? req-data-raw))
    (set! req-path (string-append req-path "?" req-data-raw))
    (set! req-data-raw ""))
  (define req
    (http-request (string-append (url-scheme url)
                                 "://"
                                 req-host
                                 (if (url-port url) (number->string (url-port url)) "")
                                 req-path)
                  method req-headers req-data))

  (when (current-http-client/debug)
    (define (fmt h)
      (string-join (map (lambda (e) (~a (car e) ": " (cdr e))) (hash->list h)) "\n"))
    (printf "METHOD  ~a \n" (http-request-method req))
    (printf "URL  ~a \n" (http-request-url req))
    (printf "HEADERS  ~a \n" (fmt (http-request-headers req)))
    (printf "DATA  ~a \n\n" (fmt (http-request-data req)))
    )

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
      [_ #:when (not (current-http-client/response-auto))
         res-body-raw]
      [(hash-table ('Content-Type (regexp #rx"^application/json.*")))
       (string->jsexpr res-body-raw)]
      [(hash-table ('Content-Type (regexp #rx"^text/html.*")))
       (html->xexp res-body-raw)]
      [(hash-table ('Content-Type (regexp #rx"^(application/xml|text/xml|application/xhtml+xml).*")))
       (string->xexpr res-body-raw)]
      [_ res-body-raw]))

  (when (current-http-client/debug)
    (define (fmt h)
      (string-join (map (lambda (e) (~a (car e) ": " (cdr e))) (hash->list h)) "\n"))
    (printf "RESPONSE CODE  ~a \n" res-code)
    (printf "RESPONSE HEADERS  ~a \n" (fmt res-headers))
    (printf "RESPNOSE BODY  ~a \n\n\n\n" res-body-raw)
    )
  (http-response req res-code res-headers res-body))