;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2010, 2011, 2012, 2013, 2014, 2015 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2012, 2013 Nikita Karetnikov <nikita@karetnikov.org>
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

(define-module (guix gnu-maintenance)
  #:use-module (web uri)
  #:use-module (web client)
  #:use-module (web response)
  #:use-module (ice-9 regex)
  #:use-module (ice-9 match)
  #:use-module (srfi srfi-1)
  #:use-module (srfi srfi-11)
  #:use-module (srfi srfi-26)
  #:use-module (system foreign)
  #:use-module (guix http-client)
  #:use-module (guix ftp-client)
  #:use-module (guix utils)
  #:use-module (guix records)
  #:use-module (guix upstream)
  #:use-module (guix packages)
  #:export (gnu-package-name
            gnu-package-mundane-name
            gnu-package-copyright-holder
            gnu-package-savannah
            gnu-package-fsd
            gnu-package-language
            gnu-package-logo
            gnu-package-doc-category
            gnu-package-doc-summary
            gnu-package-doc-description
            gnu-package-doc-urls
            gnu-package-download-url

            official-gnu-packages
            find-packages
            gnu-package?

            release-file?
            releases
            latest-release
            gnu-release-archive-types
            gnu-package-name->name+version

            %gnu-updater
            %gnome-updater))

;;; Commentary:
;;;
;;; Code for dealing with the maintenance of GNU packages, such as
;;; auto-updates.
;;;
;;; Code:


;;;
;;; List of GNU packages.
;;;

(define %gnumaint-base-url
  "http://cvs.savannah.gnu.org/viewvc/*checkout*/gnumaint/")

(define %package-list-url
  (string->uri
   (string-append %gnumaint-base-url "gnupackages.txt?root=womb")))

(define %package-description-url
  ;; This file contains package descriptions in recutils format.
  ;; See <https://lists.gnu.org/archive/html/guix-devel/2013-10/msg00071.html>.
  (string->uri
   (string-append %gnumaint-base-url "pkgblurbs.txt?root=womb")))

(define-record-type* <gnu-package-descriptor>
  gnu-package-descriptor
  make-gnu-package-descriptor

  gnu-package-descriptor?

  (name             gnu-package-name)
  (mundane-name     gnu-package-mundane-name)
  (copyright-holder gnu-package-copyright-holder)
  (savannah         gnu-package-savannah)
  (fsd              gnu-package-fsd)
  (language         gnu-package-language)         ; list of strings
  (logo             gnu-package-logo)
  (doc-category     gnu-package-doc-category)
  (doc-summary      gnu-package-doc-summary)
  (doc-description  gnu-package-doc-description)  ; taken from 'pkgdescr.txt'
  (doc-urls         gnu-package-doc-urls)         ; list of strings
  (download-url     gnu-package-download-url))

(define* (official-gnu-packages
          #:optional (fetch http-fetch/cached))
  "Return a list of records, which are GNU packages.  Use FETCH,
to fetch the list of GNU packages over HTTP."
  (define (read-records port)
    ;; Return a list of alists.  Each alist contains fields of a GNU
    ;; package.
    (let loop ((alist  (recutils->alist port))
               (result '()))
      (if (null? alist)
          (reverse result)
          (loop (recutils->alist port)
                (cons alist result)))))

  (define official-description
    (let ((db (read-records (fetch %package-description-url #:text? #t))))
      (lambda (name)
        ;; Return the description found upstream for package NAME, or #f.
        (and=> (find (lambda (alist)
                       (equal? name (assoc-ref alist "package")))
                     db)
               (lambda (record)
                 (let ((field (assoc-ref record "blurb")))
                   ;; The upstream description file uses "redirect PACKAGE" as
                   ;; a blurb in cases where the description of the two
                   ;; packages should be considered the same (e.g., GTK+ has
                   ;; "redirect gnome".)  This is usually not acceptable for
                   ;; us because we prefer to have distinct descriptions in
                   ;; such cases.  Thus, ignore the 'blurb' field when that
                   ;; happens.
                   (and field
                        (not (string-prefix? "redirect " field))
                        field)))))))

  (map (lambda (alist)
         (let ((name (assoc-ref alist "package")))
           (alist->record `(("description" . ,(official-description name))
                            ,@alist)
                          make-gnu-package-descriptor
                          (list "package" "mundane-name" "copyright-holder"
                                "savannah" "fsd" "language" "logo"
                                "doc-category" "doc-summary" "description"
                                "doc-url"
                                "download-url")
                          '("doc-url" "language"))))
       (let* ((port (fetch %package-list-url #:text? #t))
              (lst  (read-records port)))
         (close-port port)
         lst)))

(define (find-packages regexp)
  "Find GNU packages which satisfy REGEXP."
  (let ((name-rx (make-regexp regexp)))
    (filter (lambda (package)
              (false-if-exception
               (regexp-exec name-rx (gnu-package-name package))))
            (official-gnu-packages))))

(define gnu-package?
  (memoize
   (let ((official-gnu-packages (memoize official-gnu-packages)))
     (lambda (package)
       "Return true if PACKAGE is a GNU package.  This procedure may access the
network to check in GNU's database."
       (define (mirror-type url)
         (let ((uri (string->uri url)))
           (and (eq? (uri-scheme uri) 'mirror)
                (cond
                 ((member (uri-host uri)
                          '("gnu" "gnupg" "gcc" "gnome"))
                  ;; Definitely GNU.
                  'gnu)
                 ((equal? (uri-host uri) "cran")
                  ;; Possibly GNU: mirror://cran could be either GNU R itself
                  ;; or a non-GNU package.
                  #f)
                 (else
                  ;; Definitely non-GNU.
                  'non-gnu)))))

       (define (gnu-home-page? package)
         (and=> (package-home-page package)
                (lambda (url)
                  (and=> (uri-host (string->uri url))
                         (lambda (host)
                           (member host '("www.gnu.org" "gnu.org")))))))

       (or (gnu-home-page? package)
           (let ((url  (and=> (package-source package) origin-uri))
                 (name (package-name package)))
             (case (and (string? url) (mirror-type url))
               ((gnu) #t)
               ((non-gnu) #f)
               (else
                (and (member name (map gnu-package-name (official-gnu-packages)))
                     #t)))))))))


;;;
;;; Latest release.
;;;

(define (ftp-server/directory project)
  "Return the FTP server and directory where PROJECT's tarball are
stored."
  (define quirks
    '(("commoncpp2"   "ftp.gnu.org"   "/gnu/commoncpp")
      ("ucommon"      "ftp.gnu.org"   "/gnu/commoncpp")
      ("libzrtpcpp"   "ftp.gnu.org"   "/gnu/ccrtp")
      ("libosip2"     "ftp.gnu.org"   "/gnu/osip")
      ("libgcrypt"    "ftp.gnupg.org" "/gcrypt/libgcrypt")
      ("libgpg-error" "ftp.gnupg.org" "/gcrypt/libgpg-error")
      ("libassuan"    "ftp.gnupg.org" "/gcrypt/libassuan")
      ("gnupg"        "ftp.gnupg.org" "/gcrypt/gnupg")
      ("freefont-ttf" "ftp.gnu.org"   "/gnu/freefont")
      ("gnu-ghostscript" "ftp.gnu.org"  "/gnu/ghostscript")
      ("mit-scheme"   "ftp.gnu.org" "/gnu/mit-scheme/stable.pkg")
      ("icecat"       "ftp.gnu.org" "/gnu/gnuzilla")
      ("source-highlight" "ftp.gnu.org" "/gnu/src-highlite")
      ("gnutls"       "ftp.gnutls.org" "/gcrypt/gnutls")

      ;; FIXME: ftp.texmacs.org is currently outdated; texmacs.org refers to
      ;; its own http URL instead.
      ("TeXmacs"      "ftp.texmacs.org" "/TeXmacs/targz")))

  (match (assoc project quirks)
    ((_ server directory)
     (values server directory))
    (_
     (values "ftp.gnu.org" (string-append "/gnu/" project)))))

(define (sans-extension tarball)
  "Return TARBALL without its .tar.* or .zip extension."
  (let ((end (or (string-contains tarball ".tar")
                 (string-contains tarball ".zip"))))
    (substring tarball 0 end)))

(define %tarball-rx
  ;; The .zip extensions is notably used for freefont-ttf.
  ;; The "-src" pattern is for "TeXmacs-1.0.7.9-src.tar.gz".
  ;; The "-gnu[0-9]" pattern is for "icecat-38.4.0-gnu1.tar.bz2".
  (make-regexp "^([^.]+)-([0-9]|[^-])+(-(src|gnu[0-9]))?\\.(tar\\.|zip$)"))

(define %alpha-tarball-rx
  (make-regexp "^.*-.*[0-9](-|~)?(alpha|beta|rc|cvs|svn|git)-?[0-9\\.]*\\.tar\\."))

(define (release-file? project file)
  "Return #f if FILE is not a release tarball of PROJECT, otherwise return
true."
  (and (not (string-suffix? ".sig" file))
       (and=> (regexp-exec %tarball-rx file)
              (lambda (match)
                ;; Filter out unrelated files, like `guile-www-1.1.1'.
                ;; Case-insensitive for things like "TeXmacs" vs. "texmacs".
                (and=> (match:substring match 1)
                       (lambda (name)
                         (string-ci=? name project)))))
       (not (regexp-exec %alpha-tarball-rx file))
       (let ((s (sans-extension file)))
         (regexp-exec %package-name-rx s))))

(define (tarball->version tarball)
  "Return the version TARBALL corresponds to.  TARBALL is a file name like
\"coreutils-8.23.tar.xz\"."
  (let-values (((name version)
                (gnu-package-name->name+version (sans-extension tarball))))
    version))

(define (releases project)
  "Return the list of releases of PROJECT as a list of release name/directory
pairs.  Example: (\"mit-scheme-9.0.1\" . \"/gnu/mit-scheme/stable.pkg/9.0.1\"). "
  ;; TODO: Parse something like fencepost.gnu.org:/gd/gnuorg/packages-ftp.
  (let-values (((server directory) (ftp-server/directory project)))
    (define conn (ftp-open server))

    (let loop ((directories (list directory))
               (result      '()))
      (match directories
        (()
         (ftp-close conn)
         (coalesce-sources result))
        ((directory rest ...)
         (let* ((files   (ftp-list conn directory))
                (subdirs (filter-map (match-lambda
                                       ((name 'directory . _) name)
                                       (_ #f))
                                     files)))
           (define (file->url file)
             (string-append "ftp://" server directory "/" file))

           (define (file->source file)
             (let ((url (file->url file)))
               (upstream-source
                (package project)
                (version (tarball->version file))
                (urls (list url))
                (signature-urls (list (string-append url ".sig"))))))

           (loop (append (map (cut string-append directory "/" <>)
                              subdirs)
                         rest)
                 (append
                  ;; Filter out signatures, deltas, and files which
                  ;; are potentially not releases of PROJECT--e.g.,
                  ;; in /gnu/guile, filter out guile-oops and
                  ;; guile-www; in mit-scheme, filter out binaries.
                  (filter-map (match-lambda
                                ((file 'file . _)
                                 (and (release-file? project file)
                                      (file->source file)))
                                (_ #f))
                              files)
                  result))))))))

(define* (latest-ftp-release project
                             #:key
                             (server "ftp.gnu.org")
                             (directory (string-append "/gnu/" project))
                             (keep-file? (const #t))
                             (file->signature (cut string-append <> ".sig"))
                             (ftp-open ftp-open) (ftp-close ftp-close))
  "Return an <upstream-source> for the latest release of PROJECT on SERVER
under DIRECTORY, or #f.  Use FTP-OPEN and FTP-CLOSE to open (resp. close) FTP
connections; this can be useful to reuse connections.

KEEP-FILE? is a predicate to decide whether to consider a given file (source
tarball) as a valid candidate based on its name.

FILE->SIGNATURE must be a procedure; it is passed a source file URL and must
return the corresponding signature URL, or #f it signatures are unavailable."
  (define (latest a b)
    (if (version>? a b) a b))

  (define (latest-release a b)
    (if (version>? (upstream-source-version a) (upstream-source-version b))
        a b))

  (define contains-digit?
    (cut string-any char-set:digit <>))

  (define patch-directory-name?
    ;; Return #t for patch directory names such as 'bash-4.2-patches'.
    (cut string-suffix? "patches" <>))

  (define conn (ftp-open server))

  (define (file->url directory file)
    (string-append "ftp://" server directory "/" file))

  (define (file->source directory file)
    (let ((url (file->url directory file)))
      (upstream-source
       (package project)
       (version (tarball->version file))
       (urls (list url))
       (signature-urls (match (file->signature url)
                         (#f #f)
                         (sig (list sig)))))))

  (let loop ((directory directory)
             (result    #f))
    (let* ((entries (ftp-list conn directory))

           ;; Filter out sub-directories that do not contain digits---e.g.,
           ;; /gnuzilla/lang and /gnupg/patches.  Filter out "w32"
           ;; directories as found on ftp.gnutls.org.
           (subdirs (filter-map (match-lambda
                                  (((? patch-directory-name? dir)
                                    'directory . _)
                                   #f)
                                  (("w32" 'directory . _)
                                   #f)
                                  (((? contains-digit? dir) 'directory . _)
                                   dir)
                                  (_ #f))
                                entries))

           ;; Whether or not SUBDIRS is empty, compute the latest releases
           ;; for the current directory.  This is necessary for packages
           ;; such as 'sharutils' that have a sub-directory that contains
           ;; only an older release.
           (releases (filter-map (match-lambda
                                   ((file 'file . _)
                                    (and (release-file? project file)
                                         (keep-file? file)
                                         (file->source directory file)))
                                   (_ #f))
                                 entries)))

      ;; Assume that SUBDIRS correspond to versions, and jump into the
      ;; one with the highest version number.
      (let* ((release  (reduce latest-release #f
                               (coalesce-sources releases)))
             (result   (if (and result release)
                           (latest-release release result)
                           (or release result)))
             (target   (reduce latest #f subdirs)))
        (if target
            (loop (string-append directory "/" target)
                  result)
            (begin
              (ftp-close conn)
              result))))))

(define (latest-release package . rest)
  "Return the <upstream-source> for the latest version of PACKAGE or #f.
PACKAGE is the name of a GNU package.  This procedure automatically uses the
right FTP server and directory for PACKAGE."
  (let-values (((server directory) (ftp-server/directory package)))
    (apply latest-ftp-release package
           #:server server
           #:directory directory
           rest)))

(define-syntax-rule (false-if-ftp-error exp)
  "Return #f if an FTP error is raise while evaluating EXP; return the result
of EXP otherwise."
  (catch 'ftp-error
    (lambda ()
      exp)
    (lambda (key port . rest)
      (if (ftp-connection? port)
          (ftp-close port)
          (close-port port))
      #f)))

(define (latest-release* package)
  "Like 'latest-release', but ignore FTP errors that might occur when PACKAGE
is not actually a GNU package, or not hosted on ftp.gnu.org, or not under that
name (this is the case for \"emacs-auctex\", for instance.)"
  (false-if-ftp-error (latest-release package)))

(define %package-name-rx
  ;; Regexp for a package name, e.g., "foo-X.Y".  Since TeXmacs uses
  ;; "TeXmacs-X.Y-src", the `-src' suffix is allowed.
  (make-regexp "^(.*)-(([0-9]|\\.)+)(-src)?"))

(define (gnu-package-name->name+version name+version)
  "Return the package name and version number extracted from NAME+VERSION."
  (let ((match (regexp-exec %package-name-rx name+version)))
    (if (not match)
        (values name+version #f)
        (values (match:substring match 1) (match:substring match 2)))))

(define (pure-gnu-package? package)
  "Return true if PACKAGE is a non-Emacs and non-GNOME GNU package.  This
excludes AucTeX, for instance, whose releases are now uploaded to
elpa.gnu.org, and all the GNOME packages."
  (and (not (string-prefix? "emacs-" (package-name package)))
       (not (gnome-package? package))
       (gnu-package? package)))

(define (gnome-package? package)
  "Return true if PACKAGE is a GNOME package, hosted on gnome.org."
  (define gnome-uri?
    (match-lambda
      ((? string? uri)
       (string-prefix? "mirror://gnome/" uri))
      (_
       #f)))

  (match (package-source package)
    ((? origin? origin)
     (match (origin-uri origin)
       ((? gnome-uri?) #t)
       (_              #f)))
    (_ #f)))

(define (latest-gnome-release package)
  "Return the latest release of PACKAGE, the name of a GNOME package."
  (define %not-dot
    (char-set-complement (char-set #\.)))

  (define (even-minor-version? version)
    (match (string-tokenize (version-major+minor version)
                            %not-dot)
      (((= string->number major) (= string->number minor))
       (even? minor))
      (_
       #t)))                                      ;cross fingers

  (define (even-numbered-tarball? file)
    (let-values (((name version) (gnu-package-name->name+version file)))
      (and version
           (even-minor-version? version))))

  (false-if-ftp-error
   (latest-ftp-release package
                       #:server "ftp.gnome.org"
                       #:directory (string-append "/pub/gnome/sources/"
                                                  (match package
                                                    ("gconf" "GConf")
                                                    (x       x)))


                       ;; <https://www.gnome.org/gnome-3/source/> explains
                       ;; that odd minor version numbers represent development
                       ;; releases, which we are usually not interested in.
                       #:keep-file? even-numbered-tarball?

                       ;; ftp.gnome.org provides no signatures, only
                       ;; checksums.
                       #:file->signature (const #f))))

(define %gnu-updater
  (upstream-updater
   (name 'gnu)
   (description "Updater for GNU packages")
   (pred pure-gnu-package?)
   (latest latest-release*)))

(define %gnome-updater
  (upstream-updater
   (name 'gnome)
   (description "Updater for GNOME packages")
   (pred gnome-package?)
   (latest latest-gnome-release)))

;;; gnu-maintenance.scm ends here
