#lang at-exp racket/base


;; Notice
;; To install (from within the package directory):
;;   $ raco pkg install
;; To install (once uploaded to pkgs.racket-lang.org):
;;   $ raco pkg install <<name>>
;; To uninstall:
;;   $ raco pkg remove <<name>>
;; To view documentation:
;;   $ raco docs <<name>>
;;
;; For your convenience, we have included LICENSE-MIT and LICENSE-APACHE files.
;; If you would prefer to use a different license, replace those files with the
;; desired license.
;;
;; Some users like to add a `private/` directory, place auxiliary files there,
;; and require them in `main.rkt`.
;;
;; See the current version of the racket style guide here:
;; http://docs.racket-lang.org/style/index.html

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

;; https://lostisland.github.io/faraday/usage/
;;;;; need setup a new racket pkg for this file: http-client

;; (current-header-accept "")
;; (current-header-user-agent "")
;; (current-header-content-type "")
;; (current-header-cookie "")
(define current-http-user-agent (make-parameter "http-client[macosx/racket]"))
(define current-http-response-auto (make-parameter #t))


(struct http-connection (url headers data) ;; TODO: auto fill in different values for different fields.
  #:methods gen:custom-write
  [(define (write-proc conn port mode)
     (define (fmcl k v)
       (define length (string-length (~a v)))
       (define marker @~a{......[@length]})
       @~a{@|k|: @(~a @v #:max-width 128 #:limit-marker @marker)})
     (display @~a{#<http-connection
                  @(fmcl "url" @(http-connection-url conn))
                  @(fmcl "headers" @(http-connection-headers conn))
                  @(fmcl "data" @(http-connection-data conn))
                  >} port))])

(struct http-request (url method headers data)
  #:methods gen:custom-write
  [(define (write-proc rqt port mode)
     ;; TODO: seperated fmcl for every struct.
     (define (fmcl k v)
       (define length (string-length (~a v)))
       (define marker @~a{......[@length]})
       @~a{@|k|: @(~a @v #:max-width 128 #:limit-marker @marker)})

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
       @~a{@|k|: @(~a @v #:max-width 128 #:limit-marker @marker)})
     (display @~a{#<http-response
                  #<request
                  @(fmcl "url" @(http-request-url rqt))
                  @(fmcl "method" @(http-request-method rqt))
                  @(fmcl "headers" @(http-request-headers rqt))
                  @(fmcl "data" @(http-request-data rqt))
                  >
                  @(fmcl "code" @(http-response-code self))
                  @(fmcl "headers" @(http-response-headers self))
                  @(fmcl "body" @(http-response-body self))
                  >} port))])


(define (http-get conn [data (hasheq)]
                  #:path [path ""]
                  #:headers [headers (hasheq)])
  (http-do 'get conn data #:path path #:headers headers))


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
  (define req-headers (hash-union headers1 headers2
                                  #:combine/key (lambda (k v1 v2) v1)))
  (define req-data (hash-union data1 data2 data3
                               #:combine/key (lambda (k v1 v2) v1)))
  (define req (http-request (string-append req-host req-path)
                            method req-headers req-data))

  (define req-headers-raw
    (hash-map req-headers
              (lambda (k v) (~a k ": " v))))
  (define req-data-raw
    (match req-headers
      ;; [(? hash-empty?) ""]
      [(hash-table ('Accept "application/json")) (jsexpr->string req-data)]
      [_ (alist->form-urlencoded (hash->list req-data))]))

  (define-values (res-status-raw res-headers-raw res-in)
    (http-sendrecv req-host req-path
                   #:ssl? (match (url-scheme url) ["https" #t] [_ #f])
                   #:method (string->bytes/utf-8 (string-upcase (symbol->string method)))
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
      [ (hash-table 'Content-Type value)
        #:when (string-prefix? value "application/json;")
        (string->jsexpr res-body-raw)]
      [(regexp #rx"^text/html;.*")
       (html->xexp res-body-raw)]
      [(regexp #rx"^(application/xml|text/xml|application/xhtml+xml).*")
       (string->xexpr res-body-raw)]
      [_ res-body-raw]))

  (http-response req res-code res-headers res-body))




(module+ test
  (require rackunit)


  (define conn-basic (http-connection "https://example.com"
                                      (hasheq)
                                      (hasheq)))
  (define res-basic (http-get conn))
  (check-equal? 200
                (http-response-code res-basic))

  ;; TODO: test body of the chinese web page like www.qq.com

  (define conn-httpbin
    (http-connection "https://httpbin.org" (hasheq) (hasheq)))
  (define res-status (http-get conn-httpbin
                               #:path "/status/308"
                               #:headers (hash 'accept "text/plain")))
  (check-equal? 300
                (http-response-code res-status))


  )


;; (module+ main
;;   ;; (Optional) main submodule. Put code here if you need it to be executed when
;;   ;; this file is run using DrRacket or the `racket` executable.  The code here
;;   ;; does not run when this file is required by another module. Documentation:
;;   ;; http://docs.racket-lang.org/guide/Module_Syntax.html#%28part._main-and-test%29

;;   (require racket/cmdline)
;;   (define who (box "world"))
;;   (command-line
;;     #:program "my-program"
;;     #:once-each
;;     [("-n" "--name") name "Who to say hello to" (set-box! who name)]
;;     #:args ()
;;     (printf "hello ~a~n" (unbox who))))
