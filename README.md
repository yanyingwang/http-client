http-client
===========

~~~racket
(require http-client)

(http-get "https://httpbin.org"
          #:path "anything/fruits"
          #:data (hasheq 'color "red" 'made-in "China" 'price 10)
          #:headers (hasheq 'Accept "application/json" 'Token "temp-token-abcef"))
~~~

check more doc at: https://yanying.wang/http-client/

https://developer.mozilla.org/en-US/docs/Web/HTTP
