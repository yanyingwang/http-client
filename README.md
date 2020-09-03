http-client
===========

~~~racket
(require http-client)

(http-get "https://httpbin.org"
          #:path "anything/fruits"
          #:data (hasheq 'color "red" 'made-in "China" 'price 10)
          #:headers (hasheq 'Accept "application/json" 'Token "temp-token-abcef"))
~~~

check more doc at: https://yanyingwang.github.io/http-client/ or https://docs.racket-lang.org/http-client/index.html

