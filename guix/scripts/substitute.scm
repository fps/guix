;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2014, 2015 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2014 Nikita Karetnikov <nikita@karetnikov.org>
;;;
;;; This file is part of GNU Guix.
;;;
;;; GNU Guix is free software; you can redistribute it and/or modify it
;;; under the terms of the GNU General Public License as published by
;;; the Free Software Foundation; either version 3 of the License, or (at
;;; your option) any later version.
;;;
;;; GNU Guix is distributed in the hope that it will be useful, but
;;; WITHOUT ANY WARRANTY; without even the implied warranty of
;;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;; GNU General Public License for more details.
;;;
;;; You should have received a copy of the GNU General Public License
;;; along with GNU Guix.  If not, see <http://www.gnu.org/licenses/>.

(define-module (guix scripts substitute)
  #:use-module (guix ui)
  #:use-module (guix store)
  #:use-module (guix utils)
  #:use-module (guix config)
  #:use-module (guix records)
  #:use-module (guix serialization)
  #:use-module (guix hash)
  #:use-module (guix base32)
  #:use-module (guix base64)
  #:use-module (guix pk-crypto)
  #:use-module (guix pki)
  #:use-module ((guix build utils) #:select (mkdir-p dump-port))
  #:use-module ((guix build download)
                #:select (progress-proc uri-abbreviation
                          store-path-abbreviation byte-count->string))
  #:use-module (ice-9 rdelim)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 match)
  #:use-module (ice-9 format)
  #:use-module (ice-9 ftw)
  #:use-module (ice-9 binary-ports)
  #:use-module (rnrs io ports)
  #:use-module (rnrs bytevectors)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-9)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-19)
  #:use-module (srfi srfi-26)
  #:use-module (srfi srfi-34)
  #:use-module (srfi srfi-35)
  #:use-module (web uri)
  #:use-module (web request)
  #:use-module (web response)
  #:use-module (guix http-client)
  #:export (narinfo-signature->canonical-sexp

            narinfo?
            narinfo-path
            narinfo-uri
            narinfo-uri-base
            narinfo-compression
            narinfo-file-hash
            narinfo-file-size
            narinfo-hash
            narinfo-size
            narinfo-references
            narinfo-deriver
            narinfo-system
            narinfo-signature

            narinfo-hash->sha256
            assert-valid-narinfo

            lookup-narinfos
            lookup-narinfos/diverse
            read-narinfo
            write-narinfo
            guix-substitute))

;;; Comment:
;;;
;;; This is the "binary substituter".  It is invoked by the daemon do check
;;; for the existence of available "substitutes" (pre-built binaries), and to
;;; actually use them as a substitute to building things locally.
;;;
;;; If possible, substitute a binary for the requested store path, using a Nix
;;; "binary cache".  This program implements the Nix "substituter" protocol.
;;;
;;; Code:

(define %narinfo-cache-directory
  ;; A local cache of narinfos, to avoid going to the network.
  (or (and=> (getenv "XDG_CACHE_HOME")
             (cut string-append <> "/guix/substitute"))
      (string-append %state-directory "/substitute/cache")))

(define %allow-unauthenticated-substitutes?
  ;; Whether to allow unchecked substitutes.  This is useful for testing
  ;; purposes, and should be avoided otherwise.
  (and (and=> (getenv "GUIX_ALLOW_UNAUTHENTICATED_SUBSTITUTES")
              (cut string-ci=? <> "yes"))
       (begin
         (warning (_ "authentication and authorization of substitutes \
disabled!~%"))
         #t)))

(define %narinfo-ttl
  ;; Number of seconds during which cached narinfo lookups are considered
  ;; valid.  This is a reasonable default value (corresponds to the TTL for
  ;; nginx's .nar cache on hydra.gnu.org) but we'd rather want publishers to
  ;; state what their TTL is in /nix-cache-info.  (XXX)
  (* 36 3600))

(define %narinfo-negative-ttl
  ;; Likewise, but for negative lookups---i.e., cached lookup failures.
  (* 3 3600))

(define %narinfo-expired-cache-entry-removal-delay
  ;; How often we want to remove files corresponding to expired cache entries.
  (* 7 24 3600))

(define fields->alist
  ;; The narinfo format is really just like recutils.
  recutils->alist)

(define %fetch-timeout
  ;; Number of seconds after which networking is considered "slow".
  5)

(define %random-state
  (seed->random-state (+ (ash (cdr (gettimeofday)) 32) (getpid))))

(define-syntax-rule (with-timeout duration handler body ...)
  "Run BODY; when DURATION seconds have expired, call HANDLER, and run BODY
again."
  (begin
    (sigaction SIGALRM
      (lambda (signum)
        (sigaction SIGALRM SIG_DFL)
        handler))
    (alarm duration)
    (call-with-values
        (lambda ()
          (let try ()
            (catch 'system-error
              (lambda ()
                body ...)
              (lambda args
                ;; Before Guile v2.0.9-39-gfe51c7b, the SIGALRM triggers EINTR
                ;; because of the bug at
                ;; <http://lists.gnu.org/archive/html/guile-devel/2013-06/msg00050.html>.
                ;; When that happens, try again.  Note: SA_RESTART cannot be
                ;; used because of <http://bugs.gnu.org/14640>.
                (if (= EINTR (system-error-errno args))
                    (begin
                      ;; Wait a little to avoid bursts.
                      (usleep (random 3000000 %random-state))
                      (try))
                    (apply throw args))))))
      (lambda result
        (alarm 0)
        (sigaction SIGALRM SIG_DFL)
        (apply values result)))))

(define* (fetch uri #:key (buffered? #t) (timeout? #t) (quiet-404? #f))
  "Return a binary input port to URI and the number of bytes it's expected to
provide.  If QUIET-404? is true, HTTP 404 error conditions are passed through
to the caller without emitting an error message."
  (case (uri-scheme uri)
    ((file)
     (let ((port (open-file (uri-path uri)
                            (if buffered? "rb" "r0b"))))
       (values port (stat:size (stat port)))))
    ((http)
     (guard (c ((http-get-error? c)
                (let ((code (http-get-error-code c)))
                  (if (and (= code 404) quiet-404?)
                      (raise c)
                      (leave (_ "download from '~a' failed: ~a, ~s~%")
                             (uri->string (http-get-error-uri c))
                             code (http-get-error-reason c))))))
       ;; Test this with:
       ;;   sudo tc qdisc add dev eth0 root netem delay 1500ms
       ;; and then cancel with:
       ;;   sudo tc qdisc del dev eth0 root
       (let ((port #f))
         (with-timeout (if timeout?
                           %fetch-timeout
                           0)
           (begin
             (warning (_ "while fetching ~a: server is somewhat slow~%")
                      (uri->string uri))
             (warning (_ "try `--no-substitutes' if the problem persists~%"))

             ;; Before Guile v2.0.9-39-gfe51c7b, EINTR was reported to the user,
             ;; and thus PORT had to be closed and re-opened.  This is not the
             ;; case afterward.
             (unless (or (guile-version>? "2.0.9")
                         (version>? (version) "2.0.9.39"))
               (when port
                 (close-port port))))
           (begin
             (when (or (not port) (port-closed? port))
               (set! port (open-socket-for-uri uri))
               (unless buffered?
                 (setvbuf port _IONBF)))
             (http-fetch uri #:text? #f #:port port))))))))

(define-record-type <cache-info>
  (%make-cache-info url store-directory wants-mass-query?)
  cache-info?
  (url               cache-info-url)
  (store-directory   cache-info-store-directory)
  (wants-mass-query? cache-info-wants-mass-query?))

(define (download-cache-info url)
  "Download the information for the cache at URL.  Return a <cache-info>
object on success, or #f on failure."
  (define (download url)
    ;; Download the `nix-cache-info' from URL, and return its contents as an
    ;; list of key/value pairs.
    (and=> (false-if-exception (fetch (string->uri url)))
           fields->alist))

  (and=> (download (string-append url "/nix-cache-info"))
         (lambda (properties)
           (alist->record properties
                          (cut %make-cache-info url <...>)
                          '("StoreDir" "WantMassQuery")))))


(define-record-type <narinfo>
  (%make-narinfo path uri uri-base compression file-hash file-size nar-hash nar-size
                 references deriver system signature contents)
  narinfo?
  (path         narinfo-path)
  (uri          narinfo-uri)
  (uri-base     narinfo-uri-base)        ; URI of the cache it originates from
  (compression  narinfo-compression)
  (file-hash    narinfo-file-hash)
  (file-size    narinfo-file-size)
  (nar-hash     narinfo-hash)
  (nar-size     narinfo-size)
  (references   narinfo-references)
  (deriver      narinfo-deriver)
  (system       narinfo-system)
  (signature    narinfo-signature)      ; canonical sexp
  ;; The original contents of a narinfo file.  This field is needed because we
  ;; want to preserve the exact textual representation for verification purposes.
  ;; See <https://lists.gnu.org/archive/html/guix-devel/2014-02/msg00340.html>
  ;; for more information.
  (contents     narinfo-contents))

(define (narinfo-hash->sha256 hash)
  "If the string HASH denotes a sha256 hash, return it as a bytevector.
Otherwise return #f."
  (and (string-prefix? "sha256:" hash)
       (nix-base32-string->bytevector (string-drop hash 7))))

(define (narinfo-signature->canonical-sexp str)
  "Return the value of a narinfo's 'Signature' field as a canonical sexp."
  (match (string-split str #\;)
    ((version _ sig)
     (let ((maybe-number (string->number version)))
       (cond ((not (number? maybe-number))
              (leave (_ "signature version must be a number: ~s~%")
                     version))
             ;; Currently, there are no other versions.
             ((not (= 1 maybe-number))
              (leave (_ "unsupported signature version: ~a~%")
                     maybe-number))
             (else
              (let ((signature (utf8->string (base64-decode sig))))
                (catch 'gcry-error
                  (lambda ()
                    (string->canonical-sexp signature))
                  (lambda (key proc err)
                    (leave (_ "signature is not a valid \
s-expression: ~s~%")
                           signature))))))))
    (x
     (leave (_ "invalid format of the signature field: ~a~%") x))))

(define (narinfo-maker str cache-url)
  "Return a narinfo constructor for narinfos originating from CACHE-URL.  STR
must contain the original contents of a narinfo file."
  (lambda (path url compression file-hash file-size nar-hash nar-size
                references deriver system signature)
    "Return a new <narinfo> object."
    (%make-narinfo path
                   ;; Handle the case where URL is a relative URL.
                   (or (string->uri url)
                       (string->uri (string-append cache-url "/" url)))
                   cache-url

                   compression file-hash
                   (and=> file-size string->number)
                   nar-hash
                   (and=> nar-size string->number)
                   (string-tokenize references)
                   (match deriver
                     ((or #f "") #f)
                     (_ deriver))
                   system
                   (false-if-exception
                    (and=> signature narinfo-signature->canonical-sexp))
                   str)))

(define* (assert-valid-signature narinfo signature hash
                                 #:optional (acl (current-acl)))
  "Bail out if SIGNATURE, a canonical sexp representing the signature of
NARINFO, doesn't match HASH, a bytevector containing the hash of NARINFO."
  (let ((uri (uri->string (narinfo-uri narinfo))))
    (signature-case (signature hash acl)
      (valid-signature #t)
      (invalid-signature
       (leave (_ "invalid signature for '~a'~%") uri))
      (hash-mismatch
       (leave (_ "hash mismatch for '~a'~%") uri))
      (unauthorized-key
       (leave (_ "'~a' is signed with an unauthorized key~%") uri))
      (corrupt-signature
       (leave (_ "signature on '~a' is corrupt~%") uri)))))

(define* (read-narinfo port #:optional url
                       #:key size)
  "Read a narinfo from PORT.  If URL is true, it must be a string used to
build full URIs from relative URIs found while reading PORT.  When SIZE is
true, read at most SIZE bytes from PORT; otherwise, read as much as possible.

No authentication and authorization checks are performed here!"
  (let ((str (utf8->string (if size
                               (get-bytevector-n port size)
                               (get-bytevector-all port)))))
    (alist->record (call-with-input-string str fields->alist)
                   (narinfo-maker str url)
                   '("StorePath" "URL" "Compression"
                     "FileHash" "FileSize" "NarHash" "NarSize"
                     "References" "Deriver" "System"
                     "Signature"))))

(define (narinfo-sha256 narinfo)
  "Return the sha256 hash of NARINFO as a bytevector, or #f if NARINFO lacks a
'Signature' field."
  (let ((contents (narinfo-contents narinfo)))
    (match (string-contains contents "Signature:")
      (#f #f)
      (index
       (let ((above-signature (string-take contents index)))
         (sha256 (string->utf8 above-signature)))))))

(define* (assert-valid-narinfo narinfo
                               #:optional (acl (current-acl))
                               #:key (verbose? #t))
  "Raise an exception if NARINFO lacks a signature, has an invalid signature,
or is signed by an unauthorized key."
  (let ((hash (narinfo-sha256 narinfo)))
    (if (not hash)
        (if %allow-unauthenticated-substitutes?
            narinfo
            (leave (_ "substitute at '~a' lacks a signature~%")
                   (uri->string (narinfo-uri narinfo))))
        (let ((signature (narinfo-signature narinfo)))
          (unless %allow-unauthenticated-substitutes?
            (assert-valid-signature narinfo signature hash acl)
            (when verbose?
              ;; Visually separate substitutions with a newline.
              (format (current-error-port)
                      "~%Found valid signature for ~a~%From ~a~%"
                      (narinfo-path narinfo)
                      (uri->string (narinfo-uri narinfo)))))
          narinfo))))

(define* (valid-narinfo? narinfo #:optional (acl (current-acl)))
  "Return #t if NARINFO's signature is not valid."
  (or %allow-unauthenticated-substitutes?
      (let ((hash      (narinfo-sha256 narinfo))
            (signature (narinfo-signature narinfo)))
        (and hash signature
             (signature-case (signature hash acl)
               (valid-signature #t)
               (else #f))))))

(define (write-narinfo narinfo port)
  "Write NARINFO to PORT."
  (put-bytevector port (string->utf8 (narinfo-contents narinfo))))

(define (narinfo->string narinfo)
  "Return the external representation of NARINFO."
  (call-with-output-string (cut write-narinfo narinfo <>)))

(define (string->narinfo str cache-uri)
  "Return the narinfo represented by STR.  Assume CACHE-URI as the base URI of
the cache STR originates form."
  (call-with-input-string str (cut read-narinfo <> cache-uri)))

(define (obsolete? date now ttl)
  "Return #t if DATE is obsolete compared to NOW + TTL seconds."
  (time>? (subtract-duration now (make-time time-duration 0 ttl))
          (make-time time-monotonic 0 date)))


(define (narinfo-cache-file cache-url path)
  "Return the name of the local file that contains an entry for PATH.  The
entry is stored in a sub-directory specific to CACHE-URL."
  (string-append %narinfo-cache-directory "/"
                 (bytevector->base32-string (sha256 (string->utf8 cache-url)))
                 "/" (store-path-hash-part path)))

(define (cached-narinfo cache-url path)
  "Check locally if we have valid info about PATH coming from CACHE-URL.
Return two values: a Boolean indicating whether we have valid cached info, and
that info, which may be either #f (when PATH is unavailable) or the narinfo
for PATH."
  (define now
    (current-time time-monotonic))

  (define cache-file
    (narinfo-cache-file cache-url path))

  (catch 'system-error
    (lambda ()
      (call-with-input-file cache-file
        (lambda (p)
          (match (read p)
            (('narinfo ('version 1)
                       ('cache-uri cache-uri)
                       ('date date) ('value #f))
             ;; A cached negative lookup.
             (if (obsolete? date now %narinfo-negative-ttl)
                 (values #f #f)
                 (values #t #f)))
            (('narinfo ('version 1)
                       ('cache-uri cache-uri)
                       ('date date) ('value value))
             ;; A cached positive lookup
             (if (obsolete? date now %narinfo-ttl)
                 (values #f #f)
                 (values #t (string->narinfo value cache-uri))))
            (('narinfo ('version v) _ ...)
             (values #f #f))))))
    (lambda _
      (values #f #f))))

(define (cache-narinfo! cache-url path narinfo)
  "Cache locally NARNIFO for PATH, which originates from CACHE-URL.  NARINFO
may be #f, in which case it indicates that PATH is unavailable at CACHE-URL."
  (define now
    (current-time time-monotonic))

  (define (cache-entry cache-uri narinfo)
    `(narinfo (version 1)
              (cache-uri ,cache-uri)
              (date ,(time-second now))
              (value ,(and=> narinfo narinfo->string))))

  (let ((file (narinfo-cache-file cache-url path)))
    (catch 'system-error
      (lambda ()
        (mkdir-p (dirname file))
        (with-atomic-file-output file
          (lambda (out)
            (write (cache-entry cache-url narinfo) out))))
      (lambda args
        ;; We may not have write access to the local cache when called from an
        ;; unprivileged process such as 'guix challenge'.
        (unless (= EACCES (system-error-errno args))
          (apply throw args)))))

  narinfo)

(define (narinfo-request cache-url path)
  "Return an HTTP request for the narinfo of PATH at CACHE-URL."
  (let ((url (string-append cache-url "/" (store-path-hash-part path)
                            ".narinfo")))
    (build-request (string->uri url) #:method 'GET)))

(define (http-multiple-get base-url proc seed requests)
  "Send all of REQUESTS to the server at BASE-URL.  Call PROC for each
response, passing it the request object, the response, a port from which to
read the response body, and the previous result, starting with SEED, à la
'fold'.  Return the final result."
  (let connect ((requests requests)
                (result   seed))
    ;; (format (current-error-port) "connecting (~a requests left)..."
    ;;         (length requests))
    (let ((p (open-socket-for-uri base-url)))
      ;; Send all of REQUESTS in a row.
      (setvbuf p _IOFBF (expt 2 16))
      (for-each (cut write-request <> p) requests)
      (force-output p)

      ;; Now start processing responses.
      (let loop ((requests requests)
                 (result   result))
        (match requests
          (()
           (reverse result))
          ((head tail ...)
           (let* ((resp   (read-response p))
                  (body   (response-body-port resp))
                  (result (proc head resp body result)))
             ;; The server can choose to stop responding at any time, in which
             ;; case we have to try again.  Check whether that is the case.
             ;; Note that even upon "Connection: close", we can read from BODY.
             (match (assq 'connection (response-headers resp))
               (('connection 'close)
                (close-port p)
                (connect tail result))            ;try again
               (_
                (loop tail result))))))))))       ;keep going

(define (read-to-eof port)
  "Read from PORT until EOF is reached.  The data are discarded."
  (dump-port port (%make-void-port "w")))

(define (narinfo-from-file file url)
  "Attempt to read a narinfo from FILE, using URL as the cache URL.  Return #f
if file doesn't exist, and the narinfo otherwise."
  (catch 'system-error
    (lambda ()
      (call-with-input-file file
        (cut read-narinfo <> url)))
    (lambda args
      (if (= ENOENT (system-error-errno args))
          #f
          (apply throw args)))))

(define (fetch-narinfos url paths)
  "Retrieve all the narinfos for PATHS from the cache at URL and return them."
  (define update-progress!
    (let ((done 0))
      (lambda ()
        (display #\cr (current-error-port))
        (force-output (current-error-port))
        (format (current-error-port)
                (_ "updating list of substitutes from '~a'... ~5,1f%")
                url (* 100. (/ done (length paths))))
        (set! done (+ 1 done)))))

  (define (handle-narinfo-response request response port result)
    (let ((len (response-content-length response)))
      ;; Make sure to read no more than LEN bytes since subsequent bytes may
      ;; belong to the next response.
      (case (response-code response)
        ((200)                                     ; hit
         (let ((narinfo (read-narinfo port url #:size len)))
           (cache-narinfo! url (narinfo-path narinfo) narinfo)
           (update-progress!)
           (cons narinfo result)))
        ((404)                                     ; failure
         (let* ((path      (uri-path (request-uri request)))
                (hash-part (string-drop-right path 8))) ; drop ".narinfo"
           (if len
               (get-bytevector-n port len)
               (read-to-eof port))
           (cache-narinfo! url
                           (find (cut string-contains <> hash-part) paths)
                           #f)
           (update-progress!)
           result))
        (else                                      ; transient failure
         (if len
             (get-bytevector-n port len)
             (read-to-eof port))
         result))))

  (define (do-fetch uri)
    (case (and=> uri uri-scheme)
      ((http)
       (let ((requests (map (cut narinfo-request url <>) paths)))
         (update-progress!)
         (let ((result (http-multiple-get url
                                          handle-narinfo-response '()
                                          requests)))
           (newline (current-error-port))
           result)))
      ((file #f)
       (let* ((base  (string-append (uri-path uri) "/"))
              (files (map (compose (cut string-append base <> ".narinfo")
                                   store-path-hash-part)
                          paths)))
         (filter-map (cut narinfo-from-file <> url) files)))
      (else
       (leave (_ "~s: unsupported server URI scheme~%")
              (if uri (uri-scheme uri) url)))))

  (define cache-info
    (download-cache-info url))

  (and cache-info
       (if (string=? (cache-info-store-directory cache-info)
                     (%store-prefix))
           (do-fetch (string->uri url))
           (begin
             (warning (_ "'~a' uses different store '~a'; ignoring it~%")
                      url (cache-info-store-directory cache-info))
             #f))))

(define (lookup-narinfos cache paths)
  "Return the narinfos for PATHS, invoking the server at CACHE when no
information is available locally."
  (let-values (((cached missing)
                (fold2 (lambda (path cached missing)
                         (let-values (((valid? value)
                                       (cached-narinfo cache path)))
                           (if valid?
                               (if value
                                   (values (cons value cached) missing)
                                   (values cached missing))
                               (values cached (cons path missing)))))
                       '()
                       '()
                       paths)))
    (if (null? missing)
        cached
        (let ((missing (fetch-narinfos cache missing)))
          (append cached (or missing '()))))))

(define (lookup-narinfos/diverse caches paths)
  "Look up narinfos for PATHS on all of CACHES, a list of URLS, in that order.
That is, when a cache lacks a narinfo, look it up in the next cache, and so
on.  Return a list of narinfos for PATHS or a subset thereof."
  (let loop ((caches caches)
             (paths  paths)
             (result '()))
    (match paths
      (()                                         ;we're done
       result)
      (_
       (match caches
         ((cache rest ...)
          (let* ((narinfos (lookup-narinfos cache paths))
                 (hits     (map narinfo-path narinfos))
                 (missing  (lset-difference string=? paths hits))) ;XXX: perf
            (loop rest missing (append narinfos result))))
         (()                                      ;that's it
          result))))))

(define (lookup-narinfo caches path)
  "Return the narinfo for PATH in CACHES, or #f when no substitute for PATH
was found."
  (match (lookup-narinfos/diverse caches (list path))
    ((answer) answer)
    (_        #f)))

(define (remove-expired-cached-narinfos directory)
  "Remove expired narinfo entries from DIRECTORY.  The sole purpose of this
function is to make sure `%narinfo-cache-directory' doesn't grow
indefinitely."
  (define now
    (current-time time-monotonic))

  (define (expired? file)
    (catch 'system-error
      (lambda ()
        (call-with-input-file file
          (lambda (port)
            (match (read port)
              (('narinfo ('version 1) ('cache-uri _) ('date date)
                         ('value #f))
               (obsolete? date now %narinfo-negative-ttl))
              (('narinfo ('version 1) ('cache-uri _) ('date date)
                         ('value _))
               (obsolete? date now %narinfo-ttl))
              (_ #t)))))
      (lambda args
        ;; FILE may have been deleted.
        #t)))

  (for-each (lambda (file)
              (let ((file (string-append directory "/" file)))
                (when (expired? file)
                  ;; Wrap in `false-if-exception' because FILE might have been
                  ;; deleted in the meantime (TOCTTOU).
                  (false-if-exception (delete-file file)))))
            (scandir directory
                     (lambda (file)
                       (= (string-length file) 32)))))

(define (narinfo-cache-directories)
  "Return the list of narinfo cache directories (one per cache URL.)"
  (map (cut string-append %narinfo-cache-directory "/" <>)
       (scandir %narinfo-cache-directory
                (lambda (item)
                  (and (not (member item '("." "..")))
                       (file-is-directory?
                        (string-append %narinfo-cache-directory
                                       "/" item)))))))

(define (maybe-remove-expired-cached-narinfo)
  "Remove expired narinfo entries from the cache if deemed necessary."
  (define now
    (current-time time-monotonic))

  (define expiry-file
    (string-append %narinfo-cache-directory "/last-expiry-cleanup"))

  (define last-expiry-date
    (or (false-if-exception
         (call-with-input-file expiry-file read))
        0))

  (when (obsolete? last-expiry-date now
                   %narinfo-expired-cache-entry-removal-delay)
    (for-each remove-expired-cached-narinfos
              (narinfo-cache-directories))
    (call-with-output-file expiry-file
      (cute write (time-second now) <>))))

(define (progress-report-port report-progress port)
  "Return a port that calls REPORT-PROGRESS every time something is read from
PORT.  REPORT-PROGRESS is a two-argument procedure such as that returned by
`progress-proc'."
  (define total 0)
  (define (read! bv start count)
    (let ((n (match (get-bytevector-n! port bv start count)
               ((? eof-object?) 0)
               (x x))))
      (set! total (+ total n))
      (report-progress total (const n))
      ;; XXX: We're not in control, so we always return anyway.
      n))

  (make-custom-binary-input-port "progress-port-proc"
                                 read! #f #f
                                 (cut close-port port)))

(define-syntax with-networking
  (syntax-rules ()
    "Catch DNS lookup errors and gracefully exit."
    ;; Note: no attempt is made to catch other networking errors, because DNS
    ;; lookup errors are typically the first one, and because other errors are
    ;; a subset of `system-error', which is harder to filter.
    ((_ exp ...)
     (catch 'getaddrinfo-error
       (lambda () exp ...)
       (lambda (key error)
         (leave (_ "host name lookup error: ~a~%")
                (gai-strerror error)))))))


;;;
;;; Help.
;;;

(define (show-help)
  (display (_ "Usage: guix substitute [OPTION]...
Internal tool to substitute a pre-built binary to a local build.\n"))
  (display (_ "
      --query            report on the availability of substitutes for the
                         store file names passed on the standard input"))
  (display (_ "
      --substitute STORE-FILE DESTINATION
                         download STORE-FILE and store it as a Nar in file
                         DESTINATION"))
  (newline)
  (display (_ "
  -h, --help             display this help and exit"))
  (display (_ "
  -V, --version          display version information and exit"))
  (newline)
  (show-bug-report-information))



;;;
;;; Daemon/substituter protocol.
;;;

(define (display-narinfo-data narinfo)
  "Write to the current output port the contents of NARINFO in the format
expected by the daemon."
  (format #t "~a\n~a\n~a\n"
          (narinfo-path narinfo)
          (or (and=> (narinfo-deriver narinfo)
                     (cute string-append (%store-prefix) "/" <>))
              "")
          (length (narinfo-references narinfo)))
  (for-each (cute format #t "~a/~a~%" (%store-prefix) <>)
            (narinfo-references narinfo))
  (format #t "~a\n~a\n"
          (or (narinfo-file-size narinfo) 0)
          (or (narinfo-size narinfo) 0)))

(define* (process-query command
                        #:key cache-urls acl)
  "Reply to COMMAND, a query as written by the daemon to this process's
standard input.  Use ACL as the access-control list against which to check
authorized substitutes."
  (define (valid? obj)
    (valid-narinfo? obj acl))

  (match (string-tokenize command)
    (("have" paths ..1)
     ;; Return the subset of PATHS available in CACHE-URLS.
     (let ((substitutable (lookup-narinfos/diverse cache-urls paths)))
       (for-each (lambda (narinfo)
                   (format #t "~a~%" (narinfo-path narinfo)))
                 (filter valid? substitutable))
       (newline)))
    (("info" paths ..1)
     ;; Reply info about PATHS if it's in CACHE-URLS.
     (let ((substitutable (lookup-narinfos/diverse cache-urls paths)))
       (for-each display-narinfo-data (filter valid? substitutable))
       (newline)))
    (wtf
     (error "unknown `--query' command" wtf))))

(define* (process-substitution store-item destination
                               #:key cache-urls acl)
  "Substitute STORE-ITEM (a store file name) from CACHE-URLS, and write it to
DESTINATION as a nar file.  Verify the substitute against ACL."
  (let* ((narinfo (lookup-narinfo cache-urls store-item))
         (uri     (narinfo-uri narinfo)))
    ;; Make sure it is signed and everything.
    (assert-valid-narinfo narinfo acl)

    ;; Tell the daemon what the expected hash of the Nar itself is.
    (format #t "~a~%" (narinfo-hash narinfo))

    (format (current-error-port) "Downloading ~a~:[~*~; (~a installed)~]...~%"
            (store-path-abbreviation store-item)
            ;; Use the Nar size as an estimate of the installed size.
            (narinfo-size narinfo)
            (and=> (narinfo-size narinfo)
                   (cute byte-count->string <>)))
    (let*-values (((raw download-size)
                   ;; Note that Hydra currently generates Nars on the fly
                   ;; and doesn't specify a Content-Length, so
                   ;; DOWNLOAD-SIZE is #f in practice.
                   (fetch uri #:buffered? #f #:timeout? #f))
                  ((progress)
                   (let* ((comp     (narinfo-compression narinfo))
                          (dl-size  (or download-size
                                        (and (equal? comp "none")
                                             (narinfo-size narinfo))))
                          (progress (progress-proc (uri-abbreviation uri)
                                                   dl-size
                                                   (current-error-port)
                                                   #:abbreviation
                                                   store-path-abbreviation)))
                     (progress-report-port progress raw)))
                  ((input pids)
                   (decompressed-port (and=> (narinfo-compression narinfo)
                                             string->symbol)
                                      progress)))
      ;; Unpack the Nar at INPUT into DESTINATION.
      (restore-file input destination)

      ;; Skip a line after what 'progress-proc' printed.
      (newline (current-error-port))

      (every (compose zero? cdr waitpid) pids))))


;;;
;;; Entry point.
;;;

(define (check-acl-initialized)
  "Warn if the ACL is uninitialized."
  (define (singleton? acl)
    ;; True if ACL contains just the user's public key.
    (and (file-exists? %public-key-file)
         (let ((key (call-with-input-file %public-key-file
                      (compose string->canonical-sexp
                               get-string-all))))
           (match acl
             ((thing)
              (equal? (canonical-sexp->string thing)
                      (canonical-sexp->string key)))
             (_
              #f)))))

  (let ((acl (acl->public-keys (current-acl))))
    (when (or (null? acl) (singleton? acl))
      (warning (_ "ACL for archive imports seems to be uninitialized, \
substitutes may be unavailable\n")))))

(define (daemon-options)
  "Return a list of name/value pairs denoting build daemon options."
  (define %not-newline
    (char-set-complement (char-set #\newline)))

  (match (getenv "_NIX_OPTIONS")
    (#f                           ;should not happen when called by the daemon
     '())
    (newline-separated
     ;; Here we get something of the form "OPTION1=VALUE1\nOPTION2=VALUE2\n".
     (filter-map (lambda (option=value)
                   (match (string-index option=value #\=)
                     (#f                          ;invalid option setting
                      #f)
                     (equal-sign
                      (cons (string-take option=value equal-sign)
                            (string-drop option=value (+ 1 equal-sign))))))
                 (string-tokenize newline-separated %not-newline)))))

(define (find-daemon-option option)
  "Return the value of build daemon option OPTION, or #f if it could not be
found."
  (assoc-ref (daemon-options) option))

(define-syntax-rule (or* a b)
  (let ((first a))
    (if (or (not first) (string-null? first))
        b
        first)))

(define %cache-urls
  (match (and=> (or* (find-daemon-option "untrusted-substitute-urls") ;client
                     (find-daemon-option "substitute-urls"))          ;admin
                string-tokenize)
    ((urls ...)
     urls)
    (#f
     ;; This can only happen when this script is not invoked by the
     ;; daemon.
     '("http://hydra.gnu.org"))))

(define (guix-substitute . args)
  "Implement the build daemon's substituter protocol."
  (mkdir-p %narinfo-cache-directory)
  (maybe-remove-expired-cached-narinfo)
  (check-acl-initialized)

  ;; Starting from commit 22144afa in Nix, we are allowed to bail out directly
  ;; when we know we cannot substitute, but we must emit a newline on stdout
  ;; when everything is alright.
  (when (null? %cache-urls)
    (exit 0))

  ;; Say hello (see above.)
  (newline)
  (force-output (current-output-port))

  (with-networking
   (with-error-handling                           ; for signature errors
     (match args
       (("--query")
        (let ((acl (current-acl)))
          (let loop ((command (read-line)))
            (or (eof-object? command)
                (begin
                  (process-query command
                                 #:cache-urls %cache-urls
                                 #:acl acl)
                  (loop (read-line)))))))
       (("--substitute" store-path destination)
        ;; Download STORE-PATH and add store it as a Nar in file DESTINATION.
        (process-substitution store-path destination
                              #:cache-urls %cache-urls
                              #:acl (current-acl)))
       (("--version")
        (show-version-and-exit "guix substitute"))
       (("--help")
        (show-help))
       (opts
        (leave (_ "~a: unrecognized options~%") opts))))))

;;; Local Variables:
;;; eval: (put 'with-timeout 'scheme-indent-function 1)
;;; End:

;;; substitute.scm ends here
