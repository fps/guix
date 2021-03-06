;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2015 Federico Beffa <beffa@fbengineering.ch>
;;; Copyright © 2015 Siniša Biđin <sinisa@bidin.eu>
;;; Copyright © 2015 Paul van der Walt <paul@denknerd.org>
;;; Copyright © 2015 Eric Bavier <bavier@member.fsf.org>
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

(define-module (gnu packages haskell)
  #:use-module (ice-9 regex)
  #:use-module ((guix licenses) #:select (bsd-3 lgpl2.1 lgpl2.1+ gpl3+ expat))
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system haskell)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages sdl)
  #:use-module (gnu packages bootstrap)
  #:use-module (gnu packages zip)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages libffi)
  #:use-module (gnu packages libedit)
  #:use-module (gnu packages multiprecision)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages python)
  #:use-module (gnu packages pcre)
  #:use-module ((gnu packages xml) #:select (libxml2))
  #:use-module (gnu packages xorg))

(define ghc-bootstrap-x86_64-7.8.4
  (origin
    (method url-fetch)
    (uri
     "https://www.haskell.org/ghc/dist/7.8.4/ghc-7.8.4-x86_64-unknown-linux-deb7.tar.xz")
    (sha256
     (base32
      "13azsl53xgj20mi1hj9x0xb32vvcvs6cpmvwx6znxhas7blh0bpn"))))

(define ghc-bootstrap-i686-7.8.4
  (origin
    (method url-fetch)
    (uri
     "https://www.haskell.org/ghc/dist/7.8.4/ghc-7.8.4-i386-unknown-linux-deb7.tar.xz")
    (sha256
     (base32
      "0wj5s435j0zgww70bj1d3f6wvnnpzlxwvwcyh2qv4qjq5z8j64kg"))))

;; 43 tests out of 3965 fail.
;;
;; Most of them do not appear to be serious:
;;
;; - some tests generate files referring to "/bin/sh" and "/bin/ls". I've not
;;   figured out how these references are generated.
;;
;; - Some tests allocate more memory than expected (ca. 3% above upper limit)
;;
;; - Some tests try to load unavailable libriries: Control.Concurrent.STM,
;;   Data.Vector, Control.Monad.State.
;;
;; - Test posix010 tries to check the existence of a user on the system:
;;   getUserEntryForName: does not exist (no such user)
(define-public ghc
  (package
    (name "ghc")
    (version "7.10.2")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://www.haskell.org/ghc/dist/"
                          version "/" name "-" version "-src.tar.xz"))
      (sha256
       (base32
        "1x8m4rp2v7ydnrz6z9g8x7z3x3d3pxhv2pixy7i7hkbqbdsp7kal"))))
    (build-system gnu-build-system)
    (supported-systems '("i686-linux" "x86_64-linux"))
    (outputs '("out" "doc"))
    (inputs
     `(("gmp" ,gmp)
       ("ncurses" ,ncurses)
       ("libffi" ,libffi)
       ("libedit" ,libedit)
       ("ghc-testsuite"
        ,(origin
           (method url-fetch)
           (uri (string-append
                 "https://www.haskell.org/ghc/dist/"
                 version "/" name "-" version "-testsuite.tar.xz"))
           (sha256
            (base32
             "0qp9da9ar87zbyn6wjgacd2ic1vgzbi3cklxnhsmjqyafv9qaj4b"))))))
    (native-inputs
     `(("perl" ,perl)
       ("python" ,python-2)                ; for tests (fails with python-3)
       ("ghostscript" ,ghostscript)        ; for tests
       ("patchelf" ,patchelf)
       ;; GHC is built with GHC. Therefore we need bootstrap binaries.
       ("ghc-binary"
        ,(if (string-match "x86_64" (or (%current-target-system) (%current-system)))
             ghc-bootstrap-x86_64-7.8.4
             ghc-bootstrap-i686-7.8.4))))
    (arguments
     `(#:test-target "test"
       ;; We get a smaller number of test failures by disabling parallel test
       ;; execution.
       #:parallel-tests? #f

       ;; The DSOs use $ORIGIN to refer to each other, but (guix build
       ;; gremlin) doesn't support it yet, so skip this phase.
       #:validate-runpath? #f

       ;; Don't pass --build=<triplet>, because the configure script
       ;; auto-detects slightly different triplets for --host and --target and
       ;; then complains that they don't match.
       #:build #f

       #:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (guix build rpath)
                  (srfi srfi-26)
                  (srfi srfi-1))
       #:imported-modules (,@%gnu-build-system-modules
                           (guix build rpath))
       #:configure-flags
       (list
        (string-append "--with-gmp-libraries="
                       (assoc-ref %build-inputs "gmp") "/lib")
        (string-append "--with-gmp-includes="
                       (assoc-ref %build-inputs "gmp") "/include")
        "--with-system-libffi"
        (string-append "--with-ffi-libraries="
                       (assoc-ref %build-inputs "libffi") "/lib")
        (string-append "--with-ffi-includes="
                       (assoc-ref %build-inputs "libffi") "/include"))
       ;; FIXME: The user-guide needs dblatex, docbook-xsl and docbook-utils.
       ;; Currently we do not have the last one.
       ;; #:make-flags
       ;; (list "BUILD_DOCBOOK_HTML = YES")
       #:phases
       (let* ((ghc-bootstrap-path
               (string-append (getcwd) "/" ,name "-" ,version "/ghc-bin"))
              (ghc-bootstrap-prefix
               (string-append ghc-bootstrap-path "/usr" )))
         (alist-cons-after
          'unpack-bin 'unpack-testsuite-and-fix-bins
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (with-directory-excursion ".."
              (copy-file (assoc-ref inputs "ghc-testsuite")
                         "ghc-testsuite.tar.xz")
              (system* "tar" "xvf" "ghc-testsuite.tar.xz"))
            (substitute*
                (list "testsuite/timeout/Makefile"
                      "testsuite/timeout/timeout.py"
                      "testsuite/timeout/timeout.hs"
                      "testsuite/tests/rename/prog006/Setup.lhs"
                      "testsuite/tests/programs/life_space_leak/life.test"
                      "libraries/process/System/Process/Internals.hs"
                      "libraries/unix/cbits/execvpe.c")
              (("/bin/sh") (which "sh"))
              (("/bin/rm") "rm"))
            #t)
          (alist-cons-after
           'unpack 'unpack-bin
           (lambda* (#:key inputs outputs #:allow-other-keys)
             (mkdir-p ghc-bootstrap-prefix)
             (with-directory-excursion ghc-bootstrap-path
               (copy-file (assoc-ref inputs "ghc-binary")
                          "ghc-bin.tar.xz")
               (zero? (system* "tar" "xvf" "ghc-bin.tar.xz"))))
           (alist-cons-before
            'install-bin 'configure-bin
            (lambda* (#:key inputs outputs #:allow-other-keys)
              (let* ((binaries
                      (list
                       "./utils/ghc-pwd/dist-install/build/tmp/ghc-pwd"
                       "./utils/hpc/dist-install/build/tmp/hpc"
                       "./utils/haddock/dist/build/tmp/haddock"
                       "./utils/hsc2hs/dist-install/build/tmp/hsc2hs"
                       "./utils/runghc/dist-install/build/tmp/runghc"
                       "./utils/ghc-cabal/dist-install/build/tmp/ghc-cabal"
                       "./utils/hp2ps/dist/build/tmp/hp2ps"
                       "./utils/ghc-pkg/dist-install/build/tmp/ghc-pkg"
                       "./utils/unlit/dist/build/tmp/unlit"
                       "./ghc/stage2/build/tmp/ghc-stage2"))
                     (gmp (assoc-ref inputs "gmp"))
                     (gmp-lib (string-append gmp "/lib"))
                     (gmp-include (string-append gmp "/include"))
                     (ncurses-lib
                      (string-append (assoc-ref inputs "ncurses") "/lib"))
                     (ld-so (string-append (assoc-ref inputs "libc")
                                           ,(glibc-dynamic-linker)))
                     (libtinfo-dir
                      (string-append ghc-bootstrap-prefix
                                     "/lib/ghc-7.8.4/terminfo-0.4.0.0")))
                (with-directory-excursion
                    (string-append ghc-bootstrap-path "/ghc-7.8.4")
                  (setenv "CONFIG_SHELL" (which "bash"))
                  (setenv "LD_LIBRARY_PATH" gmp-lib)
                  ;; The binaries have "/lib64/ld-linux-x86-64.so.2" hardcoded.
                  (for-each
                   (cut system* "patchelf" "--set-interpreter" ld-so <>)
                   binaries)
                  ;; The binaries include a reference to libtinfo.so.5 which
                  ;; is a subset of libncurses.so.5.  We create a symlink in a
                  ;; directory included in the bootstrap binaries rpath.
                  (mkdir-p libtinfo-dir)
                  (symlink
                   (string-append ncurses-lib "/libncursesw.so."
                                  ,(version-major+minor
                                    (package-version ncurses)))
                   (string-append libtinfo-dir "/libtinfo.so.5"))
                  (setenv "PATH"
                          (string-append (getenv "PATH") ":"
                                         ghc-bootstrap-prefix "/bin"))
                  (system*
                   (string-append (getcwd) "/configure")
                   (string-append "--prefix=" ghc-bootstrap-prefix)
                   (string-append "--with-gmp-libraries=" gmp-lib)
                   (string-append "--with-gmp-includes=" gmp-include)))))
            (alist-cons-before
             'configure 'install-bin
             (lambda* (#:key inputs outputs #:allow-other-keys)
               (with-directory-excursion
                   (string-append ghc-bootstrap-path "/ghc-7.8.4")
                 (zero? (system* "make" "install"))))
             %standard-phases)))))))
    (home-page "https://www.haskell.org/ghc")
    (synopsis "The Glasgow Haskell Compiler")
    (description
     "The Glasgow Haskell Compiler (GHC) is a state-of-the-art compiler and
interactive environment for the functional language Haskell.")
    (license bsd-3)))

(define-public ghc-hostname
  (package
    (name "ghc-hostname")
    (version "1.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://hackage.haskell.org/package/hostname/"
                           "hostname-" version ".tar.gz"))
       (sha256
        (base32
         "0p6gm4328946qxc295zb6vhwhf07l1fma82vd0siylnsnsqxlhwv"))))
    (build-system haskell-build-system)
    (home-page "https://hackage.haskell.org/package/hostname")
    (synopsis "Hostname in Haskell")
    (description "Network.HostName is a simple package providing a means to
determine the hostname.")
    (license bsd-3)))

(define-public ghc-libxml
  (package
    (name "ghc-libxml")
    (version "0.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://hackage.haskell.org/package/libxml/"
                           "libxml-" version ".tar.gz"))
       (sha256
        (base32
         "01zvk86kg726lf2vnlr7dxiz7g3xwi5a4ak9gcfbwyhynkzjmsfi"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-mtl" ,ghc-mtl)
       ("libxml2" ,libxml2)))
    (arguments
     `(#:configure-flags
       `(,(string-append "--extra-include-dirs="
                         (assoc-ref %build-inputs "libxml2")
                         "/include/libxml2"))))
    (home-page "http://hackage.haskell.org/package/libxml")
    (synopsis "Haskell bindings to libxml2")
    (description
     "This library provides minimal Haskell binding to libxml2.")
    (license bsd-3)))

(define-public ghc-prelude-extras
  (package
    (name "ghc-prelude-extras")
    (version "0.4.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/prelude-extras/prelude-extras-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1q7mj9hysy747vimnlyrwsk1wb2axymxixa76fwcbcnmz3fi4llp"))))
    (build-system haskell-build-system)
    (home-page "http://github.com/ekmett/prelude-extras")
    (synopsis "Higher order versions of Prelude classes")
    (description "This library provides higher order versions of
@code{Prelude} classes to ease programming with polymorphic recursion and
reduce @code{UndecidableInstances}.")
    (license bsd-3)))

(define-public ghc-data-default
  (package
    (name "ghc-data-default")
    (version "0.5.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/data-default/data-default-"
             version
             ".tar.gz"))
       (sha256
        (base32 "0d1hm0l9kim3kszshr4msmgzizrzha48gz2kb7b61p7n3gs70m7c"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-data-default-class"
        ,ghc-data-default-class)
       ("ghc-data-default-instances-base"
        ,ghc-data-default-instances-base)
       ("ghc-data-default-instances-containers"
        ,ghc-data-default-instances-containers)
       ("ghc-data-default-instances-dlist"
        ,ghc-data-default-instances-dlist)
       ("ghc-data-default-instances-old-locale"
        ,ghc-data-default-instances-old-locale)))
    (home-page "http://hackage.haskell.org/package/data-default")
    (synopsis "Types with default values")
    (description
     "This package defines a class for types with a default value, and
provides instances for types from the base, containers, dlist and old-locale
packages.")
    (license bsd-3)))

(define-public ghc-data-default-class
  (package
    (name "ghc-data-default-class")
    (version "0.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/data-default-class/"
             "data-default-class-" version ".tar.gz"))
       (sha256
        (base32 "0ccgr3jllinchqhw3lsn73ic6axk4196if5274rr1rghls0fxj5d"))))
    (build-system haskell-build-system)
    (home-page "http://hackage.haskell.org/package/data-default-class")
    (synopsis "Types with default values")
    (description
     "This package defines a class for types with default values.")
    (license bsd-3)))

(define-public ghc-data-default-instances-base
  (package
    (name "ghc-data-default-instances-base")
    (version "0.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/"
             "data-default-instances-base/"
             "data-default-instances-base-" version ".tar.gz"))
       (sha256
        (base32 "1832nq6by91f1iw73ycvkbgn8kpra83pvf2q61hy47xffh0zy4pb"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-data-default-class" ,ghc-data-default-class)))
    (home-page "http://hackage.haskell.org/package/data-default-instances-base")
    (synopsis "Default instances for types in base")
    (description
     "This package provides default instances for types from the base
package.")
    (license bsd-3)))

(define-public ghc-data-default-instances-containers
  (package
    (name "ghc-data-default-instances-containers")
    (version "0.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/"
             "data-default-instances-containers/"
             "data-default-instances-containers-" version ".tar.gz"))
       (sha256
        (base32 "06h8xka031w752a7cjlzghvr8adqbl95xj9z5zc1b62w02phfpm5"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-data-default-class" ,ghc-data-default-class)))
    (home-page "http://hackage.haskell.org/package/data-default-instances-containers")
    (synopsis "Default instances for types in containers")
    (description "Provides default instances for types from the containers
package.")
    (license bsd-3)))

(define-public ghc-data-default-instances-dlist
  (package
    (name "ghc-data-default-instances-dlist")
    (version "0.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/"
             "data-default-instances-dlist/"
             "data-default-instances-dlist-" version ".tar.gz"))
       (sha256
        (base32 "0narkdqiprhgayjiawrr4390h4rq4pl2pb6mvixbv2phrc8kfs3x"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-data-default-class" ,ghc-data-default-class)
       ("ghc-dlist" ,ghc-dlist)))
    (home-page "http://hackage.haskell.org/package/data-default-instances-dlist")
    (synopsis "Default instances for types in dlist")
    (description "Provides default instances for types from the dlist
package.")
    (license bsd-3)))

(define-public ghc-haddock-library
  (package
    (name "ghc-haddock-library")
    (version "1.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/haddock-library/haddock-library-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0mhh2ppfhrvvi9485ipwbkv2fbgj35jvz3la02y3jlvg5ffs1c8g"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-base-compat" ,ghc-base-compat)
       ("ghc-hspec" ,ghc-hspec)
       ("ghc-quickcheck" ,ghc-quickcheck)))
    (home-page "http://www.haskell.org/haddock/")
    (synopsis
     "Library exposing some functionality of Haddock")
    (description
     "Haddock is a documentation-generation tool for Haskell libraries.  These
modules expose some functionality of it without pulling in the GHC dependency.
Please note that the API is likely to change so specify upper bounds in your
project if you can't release often.  For interacting with Haddock itself, see
the ‘haddock’ package.")
    (license bsd-3)))

(define-public ghc-haddock-api
  (package
    (name "ghc-haddock-api")
    (version "2.16.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/haddock-api/haddock-api-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1spd5axg1pdjv4dkdb5gcwjsc8gg37qi4mr2k2db6ayywdkis1p2"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-paths" ,ghc-paths)
       ("ghc-haddock-library" ,ghc-haddock-library)))
    (home-page "http://www.haskell.org/haddock/")
    (synopsis "API for documentation-generation tool Haddock")
    (description "This package provides an API to Haddock, the
documentation-generation tool for Haskell libraries.")
    (license bsd-3)))

(define-public ghc-haddock
  (package
    (name "ghc-haddock")
    (version "2.16.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/haddock/haddock-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1mnnvc5jqp6n6rj7xw8wdm0z2xp9fndkz11c8p3vbljsrcqd3v26"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: Tests break with GHC 7.10.2, fixed
                               ; upstream.  See
                               ; <https://github.com/haskell/haddock/issues/427>
    (inputs `(("ghc-haddock-api" ,ghc-haddock-api)))
    (home-page "http://www.haskell.org/haddock/")
    (synopsis
     "Documentation-generation tool for Haskell libraries")
    (description
     "Haddock is a documentation-generation tool for Haskell libraries.")
    (license bsd-3)))

(define-public ghc-simple-reflect
  (package
    (name "ghc-simple-reflect")
    (version "0.3.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/simple-reflect/simple-reflect-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1dpcf6w3cf1sfl9bnlsx04x7aghw029glj5d05qzrsnms2rlw8iq"))))
    (build-system haskell-build-system)
    (home-page
     "http://twanvl.nl/blog/haskell/simple-reflection-of-expressions")
    (synopsis
     "Simple reflection of expressions containing variables")
    (description
     "This package allows simple reflection of expressions containing
variables.  Reflection here means that a Haskell expression is turned into a
string.  The primary aim of this package is teaching and understanding; there
are no options for manipulating the reflected expressions beyond showing
them.")
    (license bsd-3)))

(define-public ghc-multipart
  (package
    (name "ghc-multipart")
    (version "0.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/multipart/multipart-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0g04jhyw1ib1s7c9bcldyyn4n90qd9x7dmvic4vgq57bgcqgnhz5"))))
    (build-system haskell-build-system)
    (inputs `(("ghc-parsec" ,ghc-parsec)))
    (home-page
     "http://www.github.com/silkapp/multipart")
    (synopsis
     "HTTP multipart library")
    (description
     "HTTP multipart split out of the cgi package, for Haskell.")
    (license bsd-3)))

(define-public ghc-html
  (package
    (name "ghc-html")
    (version "1.0.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/html/html-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0q9hmfii62kc82ijlg238fxrzxhsivn42x5wd6ffcr9xldg4jd8c"))))
    (build-system haskell-build-system)
    (home-page
     "http://hackage.haskell.org/package/html")
    (synopsis "HTML combinator library")
    (description
     "This package contains a combinator library for constructing HTML
documents.")
    (license bsd-3)))

(define-public ghc-xhtml
  (package
    (name "ghc-xhtml")
    (version "3000.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/xhtml/xhtml-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1n6wgzxbj8xf0wf1il827qidphnffb5vzhwzqlxhh70c2y10f0ik"))))
    (build-system haskell-build-system)
    (home-page "https://github.com/haskell/xhtml")
    (synopsis "XHTML combinator library")
    (description
     "This package provides combinators for producing XHTML 1.0, including the
Strict, Transitional and Frameset variants.")
    (license bsd-3)))

(define-public ghc-haskell-src
  (package
    (name "ghc-haskell-src")
    (version "1.0.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/haskell-src/haskell-src-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "19lilhpwnjb7cks9fq1ipnc8f7dwxy0ri3dgjkdxs3i355byw99a"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-happy" ,ghc-happy)
       ("ghc-syb" ,ghc-syb)))
    (home-page
     "http://hackage.haskell.org/package/haskell-src")
    (synopsis
     "Support for manipulating Haskell source code")
    (description
     "The 'haskell-src' package provides support for manipulating Haskell
source code.  The package provides a lexer, parser and pretty-printer, and a
definition of a Haskell abstract syntax tree (AST).  Common uses of this
package are to parse or generate Haskell 98 code.")
    (license bsd-3)))

(define-public ghc-alex
  (package
    (name "ghc-alex")
    (version "3.1.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/alex/alex-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "17x13nbbr79xgdlzywjqw19vcl6iygjnssjnxnajgijkv764wknn"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: Tests broken for GHC 7.10.  Fixed
                               ; upstream, see
                               ; <https://github.com/simonmar/alex/issues/62>
    (inputs `(("ghc-quickcheck" ,ghc-quickcheck)))
    (home-page "http://www.haskell.org/alex/")
    (synopsis
     "Tool for generating lexical analysers in Haskell")
    (description
     "Alex is a tool for generating lexical analysers in Haskell.  It takes a
description of tokens based on regular expressions and generates a Haskell
module containing code for scanning text efficiently.  It is similar to the
tool lex or flex for C/C++.")
    (license bsd-3)))

(define-public ghc-cgi
  (package
    (name "ghc-cgi")
    (version "3001.2.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/cgi/cgi-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0q1pxpa8gi42c0hsidcdkhk5xr5anfrvhqsn3iksr9c0rllhz193"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-parsec" ,ghc-parsec)
       ("ghc-old-locale" ,ghc-old-locale)
       ("ghc-old-time" ,ghc-old-time)
       ("ghc-exceptions" ,ghc-exceptions)
       ("ghc-multipart" ,ghc-multipart)
       ("ghc-network-uri" ,ghc-network-uri)
       ("ghc-network" ,ghc-network)
       ("ghc-mtl" ,ghc-mtl)))
    (home-page
     "https://github.com/cheecheeo/haskell-cgi")
    (synopsis "Library for writing CGI programs")
    (description
     "This is a Haskell library for writing CGI programs.")
    (license bsd-3)))

(define-public ghc-cmdargs
  (package
    (name "ghc-cmdargs")
    (version "0.10.13")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/cmdargs/cmdargs-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0vmz7f0ssrqlp6wzmc0mjqj4qczfgk58g0lr0yz7jamamlgpq4b6"))))
    (build-system haskell-build-system)
    (home-page
     "http://community.haskell.org/~ndm/cmdargs/")
    (synopsis "Command line argument processing")
    (description
     "This library provides an easy way to define command line parsers.")
    (license bsd-3)))

(define-public ghc-happy
  (package
    (name "ghc-happy")
    (version "1.19.5")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/happy/happy-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1nj353q4z1g186fpjzf0dnsg71qhxqpamx8jy89rjjvv3p0kmw32"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ;; cannot satisfy -package mtl.  Possible Cabal
                               ;; issue.
    (propagated-inputs
     `(("ghc-mtl" ,ghc-mtl)))
    (home-page "https://hackage.haskell.org/package/happy")
    (synopsis "Parser generator for Haskell")
    (description "Happy is a parser generator for Haskell.  Given a grammar
specification in BNF, Happy generates Haskell code to parse the grammar.
Happy works in a similar way to the yacc tool for C.")
    (license bsd-3)))

(define-public ghc-haskell-src-exts
  (package
    (name "ghc-haskell-src-exts")
    (version "1.16.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/haskell-src-exts/haskell-src-exts-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1h8gjw5g92rvvzadqzpscg73x7ajvs1wlphrh27afim3scdd8frz"))))
    (build-system haskell-build-system)
    (inputs
     `(("cpphs" ,cpphs)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-smallcheck" ,ghc-smallcheck)
       ("ghc-tasty" ,ghc-tasty)
       ("ghc-happy" ,ghc-happy)
       ("ghc-tasty-smallcheck" ,ghc-tasty-smallcheck)
       ("ghc-tasty-golden" ,ghc-tasty-golden)
       ("ghc-syb" ,ghc-syb)))
    (home-page "https://github.com/haskell-suite/haskell-src-exts")
    (synopsis "Library for manipulating Haskell source")
    (description "Haskell-Source with Extensions (HSE, haskell-src-exts) is an
extension of the standard @code{haskell-src} package, and handles most
registered syntactic extensions to Haskell.  All extensions implemented in GHC
are supported.  Apart from these standard extensions, it also handles regular
patterns as per the HaRP extension as well as HSX-style embedded XML syntax.")
    (license bsd-3)))

(define-public hlint
  (package
    (name "hlint")
    (version "1.9.21")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/" name
             "/" name "-" version ".tar.gz"))
       (sha256
        (base32
         "14v3rdjjlml9nimdk7d5dvir2bw78ai49yylvms9lnzmw29s3546"))))
    (build-system haskell-build-system)
    (inputs
     `(("cpphs" ,cpphs)
       ("ghc-cmdargs" ,ghc-cmdargs)
       ("ghc-haskell-src-exts" ,ghc-haskell-src-exts)
       ("ghc-uniplate" ,ghc-uniplate)
       ("ghc-ansi-terminal" ,ghc-ansi-terminal)
       ("ghc-extra" ,ghc-extra)
       ("hscolour" ,hscolour)))
    (home-page "http://community.haskell.org/~ndm/hlint/")
    (synopsis "Suggest improvements for Haskell source code")
    (description "HLint reads Haskell programs and suggests changes that
hopefully make them easier to read.  HLint also makes it easy to disable
unwanted suggestions, and to add your own custom suggestions.")
    (license bsd-3)))

(define-public ghc-resourcet
  (package
    (name "ghc-resourcet")
    (version "1.1.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/resourcet/resourcet-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0zhsaaa4n8ry76vjih519a8npm2hrzk10d5asrgllcwpzmifl41y"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-transformers-base" ,ghc-transformers-base)
       ("ghc-monad-control" ,ghc-monad-control)
       ("ghc-transformers-compat" ,ghc-transformers-compat)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-mmorph" ,ghc-mmorph)
       ("ghc-exceptions" ,ghc-exceptions)))
    (inputs
     `(("ghc-lifted-base" ,ghc-lifted-base)
       ("ghc-hspec" ,ghc-hspec)))
    (home-page "http://github.com/snoyberg/conduit")
    (synopsis "Deterministic allocation and freeing of scarce resources")
    (description "ResourceT is a monad transformer which creates a region of
code where you can safely allocate resources.")
    (license bsd-3)))

(define-public ghc-xss-sanitize
  (package
    (name "ghc-xss-sanitize")
    (version "0.3.5.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/xss-sanitize/xss-sanitize-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1j2qrn2dbfx01m7zyk9ilgnp9zjwq9mk62b0rdal4zkg4vh212h0"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-tagsoup" ,ghc-tagsoup)
       ("ghc-utf8-string" ,ghc-utf8-string)
       ("ghc-css-text" ,ghc-css-text)
       ("ghc-network-uri" ,ghc-network-uri)))
    (inputs
     `(("ghc-text" ,ghc-text)
       ("ghc-attoparsec" ,ghc-attoparsec)
       ("ghc-hspec" ,ghc-hspec)
       ("ghc-hunit" ,ghc-hunit)))
    (home-page "http://github.com/yesodweb/haskell-xss-sanitize")
    (synopsis "Sanitize untrusted HTML to prevent XSS attacks")
    (description "This library provides @code{sanitizeXSS}.  Run untrusted
HTML through @code{Text.HTML.SanitizeXSS.sanitizeXSS} to prevent XSS
attacks.")
    (license bsd-3)))

(define-public ghc-objectname
  (package
    (name "ghc-objectname")
    (version "1.1.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/ObjectName/ObjectName-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0kh5fb9ykag6rfsm3f0bx3w323s18w2cyry34w5xgli5ncqimadg"))))
    (build-system haskell-build-system)
    (home-page "https://hackage.haskell.org/package/ObjectName")
    (synopsis "Helper library for Haskell OpenGL")
    (description "This tiny package contains the class ObjectName, which
corresponds to the general notion of explicitly handled identifiers for API
objects, e.g. a texture object name in OpenGL or a buffer object name in
OpenAL.")
    (license bsd-3)))

(define-public ghc-sdl
  (package
    (name "ghc-sdl")
    (version "0.6.5.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/SDL/SDL-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1sa3zx3vrs1gbinxx33zwq0x2bsf3i964bff7419p7vzidn36k46"))))
    (build-system haskell-build-system)
    (inputs
     `(("sdl" ,sdl)))
    (home-page "https://hackage.haskell.org/package/SDL")
    (synopsis "LibSDL for Haskell")
    (description "Simple DirectMedia Layer (libSDL) is a cross-platform
multimedia library designed to provide low level access to audio, keyboard,
mouse, joystick, 3D hardware via OpenGL, and 2D video framebuffer.  It is used
by MPEG playback software, emulators, and many popular games, including the
award winning Linux port of \"Civilization: Call To Power.\"")
    (license bsd-3)))

(define-public ghc-sdl-mixer
  (package
    (name "ghc-sdl-mixer")
    (version "0.6.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/SDL-mixer/SDL-mixer-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0md3238hx79mxb9a7l43kg3b3d28x4mqvj0hjsbsh15ajnvy9x2z"))))
    (build-system haskell-build-system)
    (arguments
     `(#:configure-flags
       (let* ((sdl-mixer (assoc-ref %build-inputs "sdl-mixer"))
              (sdl-mixer-include (string-append sdl-mixer "/include/SDL")))
         (list (string-append "--extra-include-dirs=" sdl-mixer-include)))))
    (propagated-inputs
     `(("ghc-sdl" ,ghc-sdl)))
    (inputs
     `(("sdl-mixer" ,sdl-mixer)))
    (home-page "http://hackage.haskell.org/package/SDL-mixer")
    (synopsis "Haskell bindings to libSDL_mixer")
    (description "SDL_mixer is a sample multi-channel audio mixer library.  It
supports any number of simultaneously playing channels of 16 bit stereo audio,
plus a single channel of music, mixed by the popular MikMod MOD, Timidity
MIDI, Ogg Vorbis, and SMPEG MP3 libraries.")
    (license bsd-3)))

(define-public ghc-sdl-image
  (package
    (name "ghc-sdl-image")
    (version "0.6.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/SDL-image/SDL-image-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1m02q2426qp8m8pzz2jkk4srk2vb3j3ickiaga5jx9rkkhz732zq"))))
    (build-system haskell-build-system)
    (arguments
     `(#:configure-flags
       (let* ((sdl-image (assoc-ref %build-inputs "sdl-image"))
              (sdl-image-include (string-append sdl-image "/include/SDL")))
         (list (string-append "--extra-include-dirs=" sdl-image-include)))))
    (propagated-inputs
     `(("ghc-sdl" ,ghc-sdl)))
    (inputs
     `(("sdl-image" ,sdl-image)))
    (home-page "http://hackage.haskell.org/package/SDL-image")
    (synopsis "Haskell bindings to libSDL_image")
    (description "SDL_image is an image file loading library.  It loads images
as SDL surfaces, and supports the following formats: BMP, GIF, JPEG, LBM, PCX,
PNG, PNM, TGA, TIFF, XCF, XPM, XV.")
    (license bsd-3)))

(define-public ghc-half
  (package
    (name "ghc-half")
    (version "0.2.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/half/half-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0zhwc6ps5w4ccnxl8sy623z4rjsafmnry69jpkw4hrbq11l402f1"))))
    (build-system haskell-build-system)
    (home-page "http://github.com/ekmett/half")
    (synopsis "Half-precision floating-point computations")
    (description "This library provides a half-precision floating-point
computation library for Haskell.")
    (license bsd-3)))

(define-public ghc-openglraw
  (package
    (name "ghc-openglraw")
    (version "2.5.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/OpenGLRaw/OpenGLRaw-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1kfq24mxg922ml3kkmym2qfpc56jbmrfbiix4rc2cxlwv05i191k"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-half" ,ghc-half)
       ("glu" ,glu)
       ("ghc-text" ,ghc-text)))
    (home-page "http://www.haskell.org/haskellwiki/Opengl")
    (synopsis "Raw Haskell bindings for the OpenGL graphics system")
    (description "OpenGLRaw is a raw Haskell binding for the OpenGL 4.5
graphics system and lots of OpenGL extensions.  It is basically a 1:1 mapping
of OpenGL's C API, intended as a basis for a nicer interface.  OpenGLRaw
offers access to all necessary functions, tokens and types plus a general
facility for loading extension entries.  The module hierarchy closely mirrors
the naming structure of the OpenGL extensions, making it easy to find the
right module to import.  All API entries are loaded dynamically, so no special
C header files are needed for building this package.  If an API entry is not
found at runtime, a userError is thrown.")
    (license bsd-3)))

(define-public ghc-glut
  (package
    (name "ghc-glut")
    (version "2.7.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/GLUT/GLUT-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1qfilpc10jm47anan44c20y8mh76f2dv09m5d22gk0f7am7hg4k2"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-statevar" ,ghc-statevar)
       ("ghc-openglraw" ,ghc-openglraw)
       ("freeglut" ,freeglut)))
    (inputs
     `(("ghc-opengl" ,ghc-opengl)))
    (home-page "http://www.haskell.org/haskellwiki/Opengl")
    (synopsis "Haskell bindings for the OpenGL Utility Toolkit")
    (description "This library provides Haskell bindings for the OpenGL
Utility Toolkit, a window system-independent toolkit for writing OpenGL
programs.")
    (license bsd-3)))

(define-public ghc-gluraw
  (package
    (name "ghc-gluraw")
    (version "1.5.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/GLURaw/GLURaw-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0gscd9lhp9mb10q8s716nx26m8qng9xbb4h6b3f48zzgkc1sy96x"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-openglraw" ,ghc-openglraw)))
    (home-page "http://www.haskell.org/haskellwiki/Opengl")
    (synopsis "Raw Haskell bindings GLU")
    (description "GLURaw is a raw Haskell binding for the GLU 1.3 OpenGL
utility library.  It is basically a 1:1 mapping of GLU's C API, intended as a
basis for a nicer interface.")
    (license bsd-3)))

(define-public ghc-opengl
  (package
    (name "ghc-opengl")
    (version "2.12.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/OpenGL/OpenGL-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1mcfb167jl75qc2hgylh83vf2jqizvyvkvhhb72adi2crc3zqz4b"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-text" ,ghc-text)
       ("ghc-objectname" ,ghc-objectname)
       ("ghc-gluraw" ,ghc-gluraw)
       ("ghc-statevar" ,ghc-statevar)
       ("ghc-openglraw" ,ghc-openglraw)))
    (home-page "http://www.haskell.org/haskellwiki/Opengl")
    (synopsis "Haskell bindings for the OpenGL graphics system")
    (description "This package provides Haskell bindings for the OpenGL
graphics system (GL, version 4.5) and its accompanying utility library (GLU,
version 1.3).")
    (license bsd-3)))

(define-public ghc-streaming-commons
  (package
    (name "ghc-streaming-commons")
    (version "0.1.14.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/streaming-commons/streaming-commons-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "12nw9bwvy6zrabkgvbp371klca3ds6qjlfncg1b8pbwx1y7m8c8h"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-random" ,ghc-random)))
    (inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-async" ,ghc-async)
       ("ghc-blaze-builder" ,ghc-blaze-builder)
       ("ghc-hspec" ,ghc-hspec)
       ("ghc-stm" ,ghc-stm)
       ("ghc-text" ,ghc-text)
       ("ghc-network" ,ghc-network)
       ("ghc-zlib" ,ghc-zlib)))
    (home-page "https://hackage.haskell.org/package/streaming-commons")
    (synopsis "Conduit and pipes needed by some streaming data libraries")
    (description "Provides low-dependency functionality commonly needed by
various Haskell streaming data libraries, such as @code{conduit} and
@code{pipe}s.")
    (license bsd-3)))

(define-public cpphs
  (package
    (name "cpphs")
    (version "1.19.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/" name "/"
             name "-" version ".tar.gz"))
       (sha256
        (base32
         "1njpmxgpah5pcqppcl1cxb5xicf6xlqrd162qm12khp9hainlm72"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-polyparse" ,ghc-polyparse)
       ("ghc-old-locale" ,ghc-old-locale)
       ("ghc-old-time" ,ghc-old-time)))
    (home-page "http://projects.haskell.org/cpphs/")
    (synopsis "Liberalised re-implementation of cpp, the C pre-processor")
    (description "Cpphs is a re-implementation of the C pre-processor that is
both more compatible with Haskell, and itself written in Haskell so that it
can be distributed with compilers.  This version of the C pre-processor is
pretty-much feature-complete and compatible with traditional (K&R)
pre-processors.  Additional features include: a plain-text mode; an option to
unlit literate code files; and an option to turn off macro-expansion.")
    (license (list lgpl2.1+ gpl3+))))

(define-public ghc-reflection
  (package
    (name "ghc-reflection")
    (version "2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/reflection/reflection-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "10w3m6v3g6am203wbrikdbp57x9vw6b4jsh7bxdzsss4nmpm81zg"))))
    (build-system haskell-build-system)
    (inputs `(("ghc-tagged" ,ghc-tagged)))
    (home-page "http://github.com/ekmett/reflection")
    (synopsis "Reify arbitrary terms into types that can be reflected back
into terms")
    (description "This package addresses the 'configuration problem' which is
propogating configurations that are available at run-time, allowing multiple
configurations to coexist without resorting to mutable global variables or
@code{System.IO.Unsafe.unsafePerformIO}.")
    (license bsd-3)))

(define-public ghc-old-locale
  (package
    (name "ghc-old-locale")
    (version "1.0.0.7")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/old-locale/old-locale-"
             version
             ".tar.gz"))
       (sha256
        (base32 "0l3viphiszvz5wqzg7a45zp40grwlab941q5ay29iyw8p3v8pbyv"))))
    (build-system haskell-build-system)
    (home-page "http://hackage.haskell.org/package/old-locale")
    (synopsis "Adapt to locale conventions")
    (description
     "This package provides the ability to adapt to locale conventions such as
date and time formats.")
    (license bsd-3)))

(define-public ghc-old-time
  (package
    (name "ghc-old-time")
    (version "1.1.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/old-time/old-time-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1h9b26s3kfh2k0ih4383w90ibji6n0iwamxp6rfp2lbq1y5ibjqw"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-old-locale" ,ghc-old-locale)))
    (home-page "http://hackage.haskell.org/package/old-time")
    (synopsis "Time compatibility library for Haskell")
    (description "Old-time is a package for backwards compatibility with the
old @code{time} library.  For new projects, the newer
@uref{http://hackage.haskell.org/package/time, time library} is recommended.")
    (license bsd-3)))

(define-public ghc-data-default-instances-old-locale
  (package
    (name "ghc-data-default-instances-old-locale")
    (version "0.0.1")
    (source
      (origin
        (method url-fetch)
        (uri (string-append
              "http://hackage.haskell.org/package/"
              "data-default-instances-old-locale/"
              "data-default-instances-old-locale-" version ".tar.gz"))
        (sha256
          (base32 "00h81i5phib741yj517p8mbnc48myvfj8axzsw44k34m48lv1lv0"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-data-default-class" ,ghc-data-default-class)
       ("ghc-old-locale" ,ghc-old-locale)))
    (home-page
      "http://hackage.haskell.org/package/data-default-instances-old-locale")
    (synopsis "Default instances for types in old-locale")
    (description "Provides Default instances for types from the old-locale
  package.")
    (license bsd-3)))

(define-public ghc-dlist
  (package
    (name "ghc-dlist")
    (version "0.7.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/dlist/dlist-"
             version
             ".tar.gz"))
       (sha256
        (base32 "10rp96rryij7d8gz5kv8ygc6chm1624ck5mbnqs2a3fkdzqj2b9k"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)))
    (home-page "https://github.com/spl/dlist")
    (synopsis "Difference lists")
    (description
     "Difference lists are a list-like type supporting O(1) append.  This is
particularly useful for efficient logging and pretty printing (e.g. with the
Writer monad), where list append quickly becomes too expensive.")
    (license bsd-3)))

(define-public ghc-extensible-exceptions
  (package
    (name "ghc-extensible-exceptions")
    (version "0.1.1.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://hackage.haskell.org/package/"
                           "extensible-exceptions/extensible-exceptions-"
                           version ".tar.gz"))
       (sha256
        (base32 "1273nqws9ij1rp1bsq5jc7k2jxpqa0svawdbim05lf302y0firbc"))))
    (build-system haskell-build-system)
    (home-page "http://hackage.haskell.org/package/extensible-exceptions")
    (synopsis "Extensible exceptions for Haskell")
    (description
     "This package provides extensible exceptions for both new and old
versions of GHC (i.e., < 6.10).")
    (license bsd-3)))

(define-public cabal-install
 (package
  (name "cabal-install")
   (version "1.22.6.0")
   (source
    (origin
     (method url-fetch)
      (uri (string-append
            "http://hackage.haskell.org/package/cabal-install/cabal-install-"
            version
            ".tar.gz"))
      (sha256
       (base32 "1d5h7h2wjwc2s3dvsvzjgmmfrfl2312ym2h6kyjgm9wnaqw9w8wx"))))
   (arguments `(#:tests? #f)) ; FIXME: testing libraries are missing.
   (build-system haskell-build-system)
   (propagated-inputs
    `(("ghc-http" ,ghc-http)
      ("ghc-mtl" ,ghc-mtl)
      ("ghc-network-uri" ,ghc-network-uri)
      ("ghc-network" ,ghc-network)
      ("ghc-random" ,ghc-random)
      ("ghc-stm" ,ghc-stm)
      ("ghc-zlib" ,ghc-zlib)))
   (home-page "http://www.haskell.org/cabal/")
   (synopsis "Command-line interface for Cabal and Hackage")
   (description
    "The cabal command-line program simplifies the process of managing
Haskell software by automating the fetching, configuration, compilation and
installation of Haskell libraries and programs.")
   (license bsd-3)))

(define-public ghc-mtl
  (package
    (name "ghc-mtl")
    (version "2.2.1")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/mtl/mtl-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1icdbj2rshzn0m1zz5wa7v3xvkf6qw811p4s7jgqwvx1ydwrvrfa"))))
    (build-system haskell-build-system)
    (home-page "http://github.com/ekmett/mtl")
    (synopsis
     "Monad classes, using functional dependencies")
    (description "Monad classes using functional dependencies, with instances
for various monad transformers, inspired by the paper 'Functional Programming
with Overloading and Higher-Order Polymorphism', by Mark P Jones, in 'Advanced
School of Functional Programming', 1995.  See
@uref{http://web.cecs.pdx.edu/~mpj/pubs/springschool.html, the paper}.")
    (license bsd-3)))

(define-public ghc-paths
  (package
    (name "ghc-paths")
    (version "0.1.0.9")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/ghc-paths/ghc-paths-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0ibrr1dxa35xx20cpp8jzgfak1rdmy344dfwq4vlq013c6w8z9mg"))))
    (build-system haskell-build-system)
    (home-page "https://github.com/simonmar/ghc-paths")
    (synopsis
     "Knowledge of GHC's installation directories")
    (description
     "Knowledge of GHC's installation directories.")
    (license bsd-3)))

(define-public ghc-utf8-string
  (package
    (name "ghc-utf8-string")
    (version "1.0.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/utf8-string/utf8-string-"
             version
             ".tar.gz"))
       (sha256
        (base32 "0h7imvxkahiy8pzr8cpsimifdfvv18lizrb33k6mnq70rcx9w2zv"))))
    (build-system haskell-build-system)
    (home-page "http://github.com/glguy/utf8-string/")
    (synopsis "Support for reading and writing UTF8 Strings")
    (description
     "A UTF8 layer for Strings.  The utf8-string package provides operations
for encoding UTF8 strings to Word8 lists and back, and for reading and writing
UTF8 without truncation.")
    (license bsd-3)))

(define-public ghc-setenv
  (package
    (name "ghc-setenv")
    (version "0.1.1.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/setenv/setenv-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0cnbgrvb9byyahb37zlqrj05rj25v190crgcw8wmlgf0mwwxyn73"))))
    (build-system haskell-build-system)
    (home-page "http://hackage.haskell.org/package/setenv")
    (synopsis "Library for setting environment variables")
    (description "This package provides a Haskell library for setting
environment variables.")
    (license expat)))

(define-public ghc-x11
  (package
    (name "ghc-x11")
    (version "1.6.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://hackage.haskell.org/package/X11/"
                           "X11-" version ".tar.gz"))
       (sha256
        (base32 "1kzjcynm3rr83ihqx2y2d852jc49da4p18gv6jzm7g87z22x85jj"))))
    (build-system haskell-build-system)
    (inputs
     `(("libx11" ,libx11)
       ("libxrandr" ,libxrandr)
       ("libxinerama" ,libxinerama)
       ("libxscrnsaver" ,libxscrnsaver)))
    (propagated-inputs
     `(("ghc-data-default" ,ghc-data-default)))
    (home-page "https://github.com/haskell-pkg-janitors/X11")
    (synopsis "Bindings to the X11 graphics library")
    (description
     "This package provides Haskell bindings to the X11 graphics library.  The
bindings are a direct translation of the C bindings.")
    (license bsd-3)))

(define-public ghc-x11-xft
  (package
    (name "ghc-x11-xft")
    (version "0.3.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://hackage.haskell.org/package/X11-xft/"
                           "X11-xft-" version ".tar.gz"))
       (sha256
        (base32 "1lgqb0s2qfwwgbvwxhjbi23rbwamzdi0l0slfr20c3jpcbp3zfjf"))))
    (propagated-inputs
     `(("ghc-x11" ,ghc-x11)
       ("ghc-utf8-string" ,ghc-utf8-string)))
    (inputs
     `(("libx11" ,libx11)
       ("libxft" ,libxft)
       ("xproto" ,xproto)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (build-system haskell-build-system)
    (home-page "http://hackage.haskell.org/package/X11-xft")
    (synopsis "Bindings to Xft")
    (description
     "Bindings to the Xft, X Free Type interface library, and some Xrender
parts.")
    (license lgpl2.1)))

(define-public ghc-stringbuilder
  (package
    (name "ghc-stringbuilder")
    (version "0.5.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/stringbuilder/stringbuilder-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1ap95xphqnrhv64c2a137wqslkdmb2jjd9ldb17gs1pw48k8hrl9"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: circular dependencies with tests
                               ; enabled
    (home-page "http://hackage.haskell.org/package/stringbuilder")
    (synopsis "Writer monad for multi-line string literals")
    (description "This package provides a writer monad for multi-line string
literals.")
    (license expat)))

(define-public ghc-zlib
  (package
    (name "ghc-zlib")
    (version "0.5.4.2")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/zlib/zlib-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "15hhsk7z3gvm7sz2ic2z1ca5c6rpsln2rr391mdbm1bxlzc1gmkm"))))
    (build-system haskell-build-system)
    (inputs `(("zlib" ,zlib)))
    (home-page "http://hackage.haskell.org/package/zlib")
    (synopsis
     "Compression and decompression in the gzip and zlib formats")
    (description
     "This package provides a pure interface for compressing and decompressing
streams of data represented as lazy 'ByteString's.  It uses the zlib C library
so it has high performance.  It supports the 'zlib', 'gzip' and 'raw'
compression formats.  It provides a convenient high level API suitable for
most tasks and for the few cases where more control is needed it provides
access to the full zlib feature set.")
    (license bsd-3)))

(define-public ghc-stm
  (package
    (name "ghc-stm")
    (version "2.4.4")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/stm/stm-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0gc8zvdijp3rwmidkpxv76b4i0dc8dw6nbd92rxl4vxl0655iysx"))))
    (build-system haskell-build-system)
    (home-page "http://hackage.haskell.org/package/stm")
    (synopsis "Software Transactional Memory")
    (description
     "A modular composable concurrency abstraction.")
    (license bsd-3)))

(define-public ghc-parallel
  (package
    (name "ghc-parallel")
    (version "3.2.0.6")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/parallel/parallel-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0hp6vf4zxsw6vz6lj505xihmnfhgjp39c9q7nyzlgcmps3xx6a5r"))))
    (build-system haskell-build-system)
    (home-page "http://hackage.haskell.org/package/parallel")
    (synopsis "Parallel programming library")
    (description
     "This package provides a library for parallel programming.")
    (license bsd-3)))

(define-public ghc-text
  (package
    (name "ghc-text")
    (version "1.2.1.3")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/text/text-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0gzqx5cpkdhshbz9xss51mpyq23pnf8dwjz4h3irbv2ryaa4qdlq"))))
    (build-system haskell-build-system)
    (arguments
     `(#:tests? #f)) ; FIXME: currently missing libraries used for tests.
    (home-page "https://github.com/bos/text")
    (synopsis "Efficient packed Unicode text type library")
    (description
     "An efficient packed, immutable Unicode text type (both strict and
lazy), with a powerful loop fusion optimization framework.

The 'Text' type represents Unicode character strings, in a time and
space-efficient manner.  This package provides text processing
capabilities that are optimized for performance critical use, both
in terms of large data quantities and high speed.")
    (license bsd-3)))

(define-public ghc-hashable
  (package
    (name "ghc-hashable")
    (version "1.2.3.3")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/hashable/hashable-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0kp4aj0x1iicz9qirpqxxqd8x5g1njbapxk1d90n406w3xykz4pw"))))
    (build-system haskell-build-system)
    (arguments
     `(#:tests? #f)) ; FIXME: currently missing libraries used for tests.
    ;; these inputs are necessary to use this library
    (propagated-inputs
     `(("ghc-text" ,ghc-text)))
    (home-page "http://github.com/tibbe/hashable")
    (synopsis
     "Class for types that can be converted to a hash value")
    (description
     "This package defines a class, 'Hashable', for types that can be
converted to a hash value.  This class exists for the benefit of hashing-based
data structures.  The package provides instances for basic types and a way to
combine hash values.")
    (license bsd-3)))

(define-public ghc-hunit
  (package
    (name "ghc-hunit")
    (version "1.2.5.2")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/HUnit/HUnit-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0hcs6qh8bqhip1kkjjnw7ccgcsmawdz5yvffjj5y8zd2vcsavx8a"))))
    (build-system haskell-build-system)
    (home-page "http://hunit.sourceforge.net/")
    (synopsis "Unit testing framework for Haskell")
    (description
     "HUnit is a unit testing framework for Haskell, inspired by the
JUnit tool for Java.")
    (license bsd-3)))

(define-public ghc-random
  (package
    (name "ghc-random")
    (version "1.1")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/random/random-"
             version
             ".tar.gz"))
       (sha256
        (base32 "0nis3lbkp8vfx8pkr6v7b7kr5m334bzb0fk9vxqklnp2aw8a865p"))))
    (build-system haskell-build-system)
    (home-page "http://hackage.haskell.org/package/random")
    (synopsis "Random number library")
    (description "This package provides a basic random number generation
library, including the ability to split random number generators.")
    (license bsd-3)))

(define-public ghc-primitive
  (package
    (name "ghc-primitive")
    (version "0.6.1.0")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/primitive/primitive-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1j1q7l21rdm8kfs93vibr3xwkkhqis181w2k6klfhx5g5skiywwk"))))
    (build-system haskell-build-system)
    (home-page
     "https://github.com/haskell/primitive")
    (synopsis "Primitive memory-related operations")
    (description
     "This package provides various primitive memory-related operations.")
    (license bsd-3)))

(define-public ghc-test-framework
  (package
    (name "ghc-test-framework")
    (version "0.8.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://hackage.haskell.org/package/test-framework/"
                           "test-framework-" version ".tar.gz"))
       (sha256
        (base32
         "0wxjgdvb1c4ykazw774zlx86550848wbsvgjgcrdzcgbb9m650vq"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-hunit" ,ghc-hunit)
       ("ghc-libxml" ,ghc-libxml)
       ("ghc-quickcheck" ,ghc-quickcheck)))
    (propagated-inputs
     `(("ghc-ansi-terminal" ,ghc-ansi-terminal)
       ("ghc-ansi-wl-pprint" ,ghc-ansi-wl-pprint)
       ("ghc-hostname" ,ghc-hostname)
       ("ghc-old-locale" ,ghc-old-locale)
       ("ghc-random" ,ghc-random)
       ("ghc-regex-posix" ,ghc-regex-posix)
       ("ghc-xml" ,ghc-xml)))
    (home-page "https://batterseapower.github.io/test-framework/")
    (synopsis "Framework for running and organising tests")
    (description
     "This package allows tests such as QuickCheck properties and HUnit test
cases to be assembled into test groups, run in parallel (but reported in
deterministic order, to aid diff interpretation) and filtered and controlled
by command line options.  All of this comes with colored test output, progress
reporting and test statistics output.")
    (license bsd-3)))

(define-public ghc-test-framework-hunit
  (package
    (name "ghc-test-framework-hunit")
    (version "0.3.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://hackage.haskell.org/package/"
                           "test-framework-hunit/test-framework-hunit-"
                           version ".tar.gz"))
       (sha256
        (base32
         "1h0h55kf6ff25nbfx1mhliwyknc0glwv3zi78wpzllbjbs7gvyfk"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-extensible-exceptions" ,ghc-extensible-exceptions)
       ("ghc-hunit" ,ghc-hunit)
       ("ghc-test-framework" ,ghc-test-framework)))
    (home-page "https://batterseapower.github.io/test-framework/")
    (synopsis "HUnit support for test-framework")
    (description
     "This package provides HUnit support for the test-framework package.")
    (license bsd-3)))

(define-public ghc-test-framework-quickcheck2
  (package
    (name "ghc-test-framework-quickcheck2")
    (version "0.3.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://hackage.haskell.org/package/"
                           "test-framework-quickcheck2/"
                           "test-framework-quickcheck2-" version ".tar.gz"))
       (sha256
        (base32
         "12p1zwrsz35r3j5gzbvixz9z1h5643rhihf5gqznmc991krwd5nc"))
       (modules '((guix build utils)))
       (snippet
        ;; The Hackage page and the cabal file linked there for this package
        ;; both list 2.9 as the upper version limit, but the source tarball
        ;; specifies 2.8.  Assume the Hackage page is correct.
        '(substitute* "test-framework-quickcheck2.cabal"
           (("QuickCheck >= 2.4 && < 2.8") "QuickCheck >= 2.4 && < 2.9")))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-extensible-exceptions" ,ghc-extensible-exceptions)
       ("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-random" ,ghc-random)
       ("ghc-test-framework" ,ghc-test-framework)))
    (home-page "https://batterseapower.github.io/test-framework/")
    (synopsis "QuickCheck2 support for test-framework")
    (description
     "This packages provides QuickCheck2 support for the test-framework
package.")
    (license bsd-3)))

(define-public ghc-tf-random
  (package
    (name "ghc-tf-random")
    (version "0.5")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/tf-random/tf-random-"
             version
             ".tar.gz"))
       (sha256
        (base32 "0445r2nns6009fmq0xbfpyv7jpzwv0snccjdg7hwj4xk4z0cwc1f"))))
    (build-system haskell-build-system)
    ;; these inputs are necessary to use this package
    (propagated-inputs
     `(("ghc-primitive" ,ghc-primitive)
       ("ghc-random" ,ghc-random)))
    (home-page "http://hackage.haskell.org/package/tf-random")
    (synopsis "High-quality splittable pseudorandom number generator")
    (description "This package contains an implementation of a high-quality
splittable pseudorandom number generator.  The generator is based on a
cryptographic hash function built on top of the ThreeFish block cipher.  See
the paper \"Splittable Pseudorandom Number Generators Using Cryptographic
Hashing\" by Claessen, Pałka for details and the rationale of the design.")
    (license bsd-3)))

(define-public ghc-transformers-base
  (package
    (name "ghc-transformers-base")
    (version "0.4.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/transformers-base/transformers-base-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "11r3slgpgpra6zi2kjg3g60gvv17b1fh6qxipcpk8n86qx7lk8va"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-stm" ,ghc-stm)))
    (inputs
     `(("ghc-transformers-compat" ,ghc-transformers-compat)))
    (home-page
     "http://hackage.haskell.org/package/transformers-compat")
    (synopsis
     "Backported transformer library")
    (description
     "Backported versions of types that were added to transformers in
transformers 0.3 and 0.4 for users who need strict transformers 0.2 or 0.3
compatibility to run on old versions of the platform.")
    (license bsd-3)))

(define-public ghc-transformers-compat
  (package
    (name "ghc-transformers-compat")
    (version "0.4.0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/transformers-compat"
             "/transformers-compat-" version ".tar.gz"))
       (sha256
        (base32
         "0lmg8ry6bgigb0v2lg0n74lxi8z5m85qq0qi4h1k9llyjb4in8ym"))))
    (build-system haskell-build-system)
    (home-page "http://github.com/ekmett/transformers-compat/")
    (synopsis "Small compatibility shim between transformers 0.3 and 0.4")
    (description "This package includes backported versions of types that were
added to transformers in transformers 0.3 and 0.4 for users who need strict
transformers 0.2 or 0.3 compatibility to run on old versions of the platform,
but also need those types.")
    (license bsd-3)))

(define-public ghc-unix-time
  (package
    (name "ghc-unix-time")
    (version "0.3.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/unix-time/unix-time-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0dyvyxwaffb94bgri1wc4b9wqaasy32pyjn0lww3dqblxv8fn5ax"))))
    (build-system haskell-build-system)
    (arguments
     `(#:tests? #f)) ; FIXME: Test fails with "System.Time not found".  This
                     ; is weird, that should be provided by GHC 7.10.2.
    (propagated-inputs
     `(("ghc-old-time" ,ghc-old-time)
       ("ghc-old-locale" ,ghc-old-locale)))
    (home-page "http://hackage.haskell.org/package/unix-time")
    (synopsis "Unix time parser/formatter and utilities")
    (description "This library provides fast parsing and formatting utilities
for Unix time in Haskell.")
    (license bsd-3)))

(define-public ghc-unix-compat
  (package
    (name "ghc-unix-compat")
    (version "0.4.1.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/unix-compat/unix-compat-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0jxk7j5pz2kgfpqr4hznndjg31pqj5xg2qfc5308fcn9xyg1myps"))))
    (build-system haskell-build-system)
    (home-page
     "http://github.com/jystic/unix-compat")
    (synopsis "Portable POSIX-compatibility layer")
    (description
     "This package provides portable implementations of parts of the unix
package.  This package re-exports the unix package when available.  When it
isn't available, portable implementations are used.")
    (license bsd-3)))

(define-public ghc-http-types
  (package
    (name "ghc-http-types")
    (version "0.9")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/http-types/http-types-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0ny15jgm5skhs2yx6snr13lrnw19hwjgfygrpsmhib8wqa8cz8cc"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: Tests cannot find
                               ; Blaze.Bytestring.Builder, which should be
                               ; provided by ghc-blaze-builder.
    (propagated-inputs
     `(("ghc-case-insensitive" ,ghc-case-insensitive)
       ("ghc-blaze-builder" ,ghc-blaze-builder)))
    (inputs
     `(("ghc-text" ,ghc-text)))
    (home-page "https://github.com/aristidb/http-types")
    (synopsis "Generic HTTP types for Haskell")
    (description "This package provides generic HTTP types for Haskell (for
both client and server code).")
    (license bsd-3)))

(define-public ghc-iproute
  (package
    (name "ghc-iproute")
    (version "1.7.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/iproute/iproute-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1ply0i110c2sppjbfyysgw48jfjnsbam5zwil8xws0hp20rh1pb5"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: Tests cannot find System.ByteOrder,
                               ; exported by ghc-byteorder.  Doctest issue.
    (propagated-inputs
     `(("ghc-appar" ,ghc-appar)
       ("ghc-byteorder" ,ghc-byteorder)))
    (inputs
     `(("ghc-network" ,ghc-network)
       ("ghc-safe" ,ghc-safe)))
    (home-page "http://www.mew.org/~kazu/proj/iproute/")
    (synopsis "IP routing table")
    (description "IP Routing Table is a tree of IP ranges to search one of
them on the longest match base.  It is a kind of TRIE with one way branching
removed.  Both IPv4 and IPv6 are supported.")
    (license bsd-3)))

(define-public ghc-regex-base
  (package
    (name "ghc-regex-base")
    (version "0.93.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/regex-base/regex-base-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0y1j4h2pg12c853nzmczs263di7xkkmlnsq5dlp5wgbgl49mgp10"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-mtl" ,ghc-mtl)))
    (home-page
     "http://sourceforge.net/projects/lazy-regex")
    (synopsis "Replaces/Enhances Text.Regex")
    (description "@code{Text.Regex.Base} provides the interface API for
regex-posix, regex-pcre, regex-parsec, regex-tdfa, regex-dfa.")
    (license bsd-3)))

(define-public ghc-regex-posix
  (package
    (name "ghc-regex-posix")
    (version "0.95.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/regex-posix/regex-posix-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0gkhzhj8nvfn1ija31c7xnl6p0gadwii9ihyp219ck2arlhrj0an"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-regex-base" ,ghc-regex-base)))
    (home-page "http://sourceforge.net/projects/lazy-regex")
    (synopsis "POSIX regular expressions for Haskell")
    (description "This library provides the POSIX regex backend used by the
Haskell library @code{regex-base}.")
    (license bsd-3)))

(define-public ghc-regex-compat
  (package
    (name "ghc-regex-compat")
    (version "0.95.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/regex-compat/regex-compat-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0fwmima3f04p9y4h3c23493n1xj629ia2dxaisqm6rynljjv2z6m"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-regex-base" ,ghc-regex-base)
       ("ghc-regex-posix" ,ghc-regex-posix)))
    (home-page "http://sourceforge.net/projects/lazy-regex")
    (synopsis "Replaces/Enhances Text.Regex")
    (description "This library provides one module layer over
@code{regex-posix} to replace @code{Text.Regex}.")
    (license bsd-3)))

(define-public ghc-regex-tdfa-rc
  (package
    (name "ghc-regex-tdfa-rc")
    (version "1.1.8.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/regex-tdfa-rc/regex-tdfa-rc-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1vi11i23gkkjg6193ak90g55akj69bhahy542frkwb68haky4pp3"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-regex-base" ,ghc-regex-base)
       ("ghc-parsec" ,ghc-parsec)))
    (inputs
     `(("ghc-mtl" ,ghc-mtl)))
    (home-page
     "http://hackage.haskell.org/package/regex-tdfa")
    (synopsis "Tagged DFA regex engine for Haskell")
    (description "A new all-Haskell \"tagged\" DFA regex engine, inspired by
@code{libtre} (fork by Roman Cheplyaka).")
    (license bsd-3)))

(define-public ghc-parsers
  (package
    (name "ghc-parsers")
    (version "0.12.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/parsers/parsers-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "18wzmp8y3py4qa8hdsxqm0jfzmwy744dw7xa48r5s8ynhpimi462"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: Test fails with "cannot satisfy
                               ; -package attoparsec-0.13.0.1"
    (propagated-inputs
     `(("ghc-base-orphans" ,ghc-base-orphans)
       ("ghc-attoparsec" ,ghc-attoparsec)
       ("ghc-parsec" ,ghc-parsec)
       ("ghc-scientific" ,ghc-scientific)
       ("ghc-charset" ,ghc-charset)))
    (inputs
     `(("ghc-text" ,ghc-text)
       ("ghc-unordered-containers" ,ghc-unordered-containers)))
    (home-page "http://github.com/ekmett/parsers/")
    (synopsis "Parsing combinators")
    (description "This library provides convenient combinators for working
with and building parsing combinator libraries.  Given a few simple instances,
you get access to a large number of canned definitions.  Instances exist for
the parsers provided by @code{parsec}, @code{attoparsec} and @code{base}'s
@code{Text.Read}.")
    (license bsd-3)))

(define-public ghc-trifecta
  (package
    (name "ghc-trifecta")
    (version "1.5.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/trifecta/trifecta-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0fjhnsbafl3yw34pyhcsvrqy6a2mnhyqys6gna3rrlygs8ck7hpb"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: Test fails with "cannot satisfy
                               ; -package ansi-terminal-0.6.2.3"
    (propagated-inputs
     `(("ghc-charset" ,ghc-charset)
       ("ghc-comonad" ,ghc-comonad)
       ("ghc-lens" ,ghc-lens)
       ("ghc-profunctors" ,ghc-profunctors)
       ("ghc-reducers" ,ghc-reducers)
       ("ghc-semigroups" ,ghc-semigroups)))
    (inputs
     `(("ghc-ansi-wl-pprint" ,ghc-ansi-wl-pprint)
       ("ghc-ansi-terminal" ,ghc-ansi-terminal)
       ("ghc-blaze-builder" ,ghc-blaze-builder)
       ("ghc-blaze-html" ,ghc-blaze-html)
       ("ghc-blaze-markup" ,ghc-blaze-markup)
       ("ghc-fingertree" ,ghc-fingertree)
       ("ghc-hashable" ,ghc-hashable)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-parsers" ,ghc-parsers)
       ("ghc-unordered-containers" ,ghc-unordered-containers)
       ("ghc-utf8-string" ,ghc-utf8-string)))
    (home-page "http://github.com/ekmett/trifecta/")
    (synopsis "Parser combinator library with convenient diagnostics")
    (description "Trifecta is a modern parser combinator library for Haskell,
with slicing and Clang-style colored diagnostics.")
    (license bsd-3)))

(define-public ghc-attoparsec
  (package
    (name "ghc-attoparsec")
    (version "0.13.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/attoparsec/attoparsec-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0cprkr7bl4lrr80pz8mryb4rbfwdgpsrl7g0fbcaybhl8p5hm26f"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-scientific" ,ghc-scientific)))
    (inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-quickcheck-unicode" ,ghc-quickcheck-unicode)
       ("ghc-test-framework" ,ghc-test-framework)
       ("ghc-test-framework-quickcheck2" ,ghc-test-framework-quickcheck2)
       ("ghc-text" ,ghc-text)
       ("ghc-vector" ,ghc-vector)))
    (home-page "https://github.com/bos/attoparsec")
    (synopsis "Fast combinator parsing for bytestrings and text")
    (description "This library provides a fast parser combinator library,
aimed particularly at dealing efficiently with network protocols and
complicated text/binary file formats.")
    (license bsd-3)))

(define-public ghc-css-text
  (package
    (name "ghc-css-text")
    (version "0.1.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/css-text/css-text-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1xi1n2f0g8y43p95lynhcg50wxbq7hqfzbfzm7fy8mn7gvd920nw"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-text" ,ghc-text)
       ("ghc-attoparsec" ,ghc-attoparsec)
       ("ghc-hspec" ,ghc-hspec)
       ("ghc-quickcheck" ,ghc-quickcheck)))
    (home-page "http://www.yesodweb.com/")
    (synopsis "CSS parser and renderer")
    (description "This package provides a CSS parser and renderer for
Haskell.")
    (license bsd-3)))

(define-public ghc-zip-archive
  (package
    (name "ghc-zip-archive")
    (version "0.2.3.7")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/zip-archive/zip-archive-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "169nkxr5zlbymiz1ydlhlqr66vqiycmg85xh559phpkr64w3nqj1"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-old-time" ,ghc-old-time)
       ("ghc-digest" ,ghc-digest)))
    (inputs
     `(("ghc-hunit" ,ghc-hunit)
       ("ghc-mtl" ,ghc-mtl)
       ("zip" ,zip)
       ("ghc-text" ,ghc-text)
       ("ghc-zlib" ,ghc-zlib)))
    (home-page "https://hackage.haskell.org/package/zip-archive")
    (synopsis "Zip archive library for Haskell")
    (description "The zip-archive library provides functions for creating,
modifying, and extracting files from zip archives in Haskell.")
    (license bsd-3)))

(define-public ghc-distributive
  (package
    (name "ghc-distributive")
    (version "0.4.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/distributive/distributive-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0s2ln9jv7bh4ri2y31178pvjl8x6nik5d0klx7j2b77yjlsgblc2"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: fails with "cannot satisfy -package
                               ; tagged-0.8.1".  Suspected Cabal issue.
    (propagated-inputs
     `(("ghc-tagged" ,ghc-tagged)
       ("ghc-transformers-compat" ,ghc-transformers-compat)))
    (home-page "http://github.com/ekmett/distributive/")
    (synopsis "Distributive functors for Haskell")
    (description "This package provides distributive functors for Haskell.
Dual to @code{Traversable}.")
    (license bsd-3)))

(define-public ghc-cereal
  (package
    (name "ghc-cereal")
    (version "0.4.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/cereal/cereal-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "15rhfn9hrjm01ksh9xpz9syxsp9vkvpp6b736iqq38wv2wb7416z"))))
    (build-system haskell-build-system)
    (home-page "http://hackage.haskell.org/package/cereal")
    (synopsis "Binary serialization library")
    (description "This package provides a binary serialization library,
similar to @code{binary}, that introduces an @code{isolate} primitive for
parser isolation, and labeled blocks for better error messages.")
    (license bsd-3)))

(define-public ghc-comonad
  (package
    (name "ghc-comonad")
    (version "4.2.7.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/comonad/comonad-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0arvbaxgkawzdp38hh53akkahjg2aa3kj2b4ns0ni8a5ylg2cqmp"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-distributive" ,ghc-distributive)
       ("ghc-transformers-compat" ,ghc-transformers-compat)
       ("ghc-contravariant" ,ghc-contravariant)))
    (arguments `(#:tests? #f)) ; FIXME: Test fails with "cannot satisfy
                               ; -package contravariant-1.3.3"
    (inputs
     `(("ghc-semigroups" ,ghc-semigroups)
       ("ghc-tagged" ,ghc-tagged)
       ("ghc-contravariant" ,ghc-contravariant)))
    (home-page "http://github.com/ekmett/comonad/")
    (synopsis "Comonads for Haskell")
    (description "This library provides @code{Comonad}s for Haskell.")
    (license bsd-3)))

(define-public hscolour
  (package
    (name "hscolour")
    (version "1.23")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/hscolour/hscolour-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1c4i2zpami8g3w9949nm3f92g7xwh5c94vkx658zz7ihrjp7w5lp"))))
    (build-system haskell-build-system)
    (home-page "https://hackage.haskell.org/package/hscolour")
    (synopsis "Script to colourise Haskell code")
    (description "HSColour is a small Haskell script to colourise Haskell
code.  It currently has six output formats: ANSI terminal codes (optionally
XTerm-256colour codes), HTML 3.2 with font tags, HTML 4.01 with CSS, HTML 4.01
with CSS and mouseover annotations, XHTML 1.0 with inline CSS styling, LaTeX,
and mIRC chat codes.")
    (license bsd-3)))

(define-public ghc-polyparse
  (package
    (name "ghc-polyparse")
    (version "1.11")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/polyparse/polyparse-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1z417f80b0jm4dgv25fk408p3d9mmcd1dlbya3ry0zdx4md09vrh"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-text" ,ghc-text)))
    (home-page
     "http://code.haskell.org/~malcolm/polyparse/")
    (synopsis
     "Alternative parser combinator libraries")
    (description
     "This package provides a variety of alternative parser combinator
libraries, including the original HuttonMeijer set.  The Poly sets have
features like good error reporting, arbitrary token type, running state, lazy
parsing, and so on.  Finally, Text.Parse is a proposed replacement for the
standard Read class, for better deserialisation of Haskell values from
Strings.")
    (license lgpl2.1)))

(define-public ghc-extra
  (package
    (name "ghc-extra")
    (version "1.4.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/extra/extra-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1h9hxkrqrqscx420yz1lmivbrhi6jc3a5ap61vkxd2mhdgark9hf"))))
    (build-system haskell-build-system)
    (inputs `(("ghc-quickcheck" ,ghc-quickcheck)))
    (home-page "https://github.com/ndmitchell/extra")
    (synopsis "Extra Haskell functions")
    (description "This library provides extra functions for the standard
Haskell libraries.  Most functions are simple additions, filling out missing
functionality.  A few functions are available in later versions of GHC, but
this package makes them available back to GHC 7.2.")
    (license bsd-3)))

(define-public ghc-profunctors
  (package
    (name "ghc-profunctors")
    (version "5.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/profunctors/profunctors-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0lw2ipacpnp9yqmi8zsp01pzpn5hwj8af3y0f3079mddrmw48gw7"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-distributive" ,ghc-distributive)))
    (inputs
     `(("ghc-comonad" ,ghc-comonad)
       ("ghc-tagged" ,ghc-tagged)))
    (home-page "http://github.com/ekmett/profunctors/")
    (synopsis "Profunctors for Haskell")
    (description "This library provides profunctors for Haskell.")
    (license bsd-3)))

(define-public ghc-reducers
  (package
    (name "ghc-reducers")
    (version "3.12.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/reducers/reducers-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0pkddg0s3cn759miq0nfrq7lnp3imk5sx784ihsilsbjh9kvffz4"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-semigroupoids" ,ghc-semigroupoids)))
    (inputs
     `(("ghc-fingertree" ,ghc-fingertree)
       ("ghc-hashable" ,ghc-hashable)
       ("ghc-text" ,ghc-text)
       ("ghc-unordered-containers" ,ghc-unordered-containers)
       ("ghc-semigroups" ,ghc-semigroups)))
    (home-page "http://github.com/ekmett/reducers/")
    (synopsis "Semigroups, specialized containers and a general map/reduce framework")
    (description "This library provides various semigroups, specialized
containers and a general map/reduce framework for Haskell.")
    (license bsd-3)))

(define-public ghc-appar
  (package
    (name "ghc-appar")
    (version "0.1.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/appar/appar-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "09jb9ij78fdkz2qk66rw99q19qnm504dpv0yq0pjsl6xwjmndsjq"))))
    (build-system haskell-build-system)
    (home-page
     "http://hackage.haskell.org/package/appar")
    (synopsis "Simple applicative parser")
    (description "This package provides a simple applicative parser in Parsec
style.")
    (license bsd-3)))

(define-public ghc-safe
  (package
    (name "ghc-safe")
    (version "0.3.9")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/safe/safe-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1jdnp5zhvalf1xy8i872n29nljfjz6lnl9ghj80ffisrnnkrwcfh"))))
    (build-system haskell-build-system)
    (home-page "https://github.com/ndmitchell/safe#readme")
    (synopsis "Library of safe (exception free) functions")
    (description "This library provides wrappers around @code{Prelude} and
@code{Data.List} functions, such as @code{head} and @code{!!}, that can throw
exceptions.")
    (license bsd-3)))

(define-public ghc-generic-deriving
  (package
    (name "ghc-generic-deriving")
    (version "1.8.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/generic-deriving/generic-deriving-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1kc6lhdanls6kgpk8xv5xi14lz1sngcd8xn930hkf7ilq4kxkcr6"))))
    (build-system haskell-build-system)
    (home-page "https://hackage.haskell.org/package/generic-deriving")
    (synopsis "Generalise the deriving mechanism to arbitrary classes")
    (description "This package provides functionality for generalising the
deriving mechanism in Haskell to arbitrary classes.")
    (license bsd-3)))

(define-public ghc-pcre-light
  (package
    (name "ghc-pcre-light")
    (version "0.4.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/pcre-light/pcre-light-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0l1df2sk5qwf424bvb8mbdkr2xjg43fi92n5r22yd7vm1zz0jqvf"))))
    (build-system haskell-build-system)
    (inputs
     `(("pcre" ,pcre)))
    (home-page "https://github.com/Daniel-Diaz/pcre-light")
    (synopsis "Haskell library for Perl 5 compatible regular expressions")
    (description "This package provides a small, efficient, and portable regex
library for Perl 5 compatible regular expressions.  The PCRE library is a set
of functions that implement regular expression pattern matching using the same
syntax and semantics as Perl 5.")
    (license bsd-3)))

(define-public ghc-logict
  (package
    (name "ghc-logict")
    (version "0.6.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/logict/logict-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "07hnirv6snnym2r7iijlfz00b60jpy2856zvqxh989q0in7bd0hi"))))
    (build-system haskell-build-system)
    (inputs `(("ghc-mtl" ,ghc-mtl)))
    (home-page "http://code.haskell.org/~dolio/")
    (synopsis "Backtracking logic-programming monad")
    (description "This library provides a continuation-based, backtracking,
logic programming monad.  An adaptation of the two-continuation implementation
found in the paper \"Backtracking, Interleaving, and Terminating Monad
Transformers\" available @uref{http://okmij.org/ftp/papers/LogicT.pdf,
online}.")
    (license bsd-3)))

(define-public ghc-xml
  (package
    (name "ghc-xml")
    (version "1.3.14")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/xml/xml-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0g814lj7vaxvib2g3r734221k80k7ap9czv9hinifn8syals3l9j"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-text" ,ghc-text)))
    (home-page "http://code.galois.com")
    (synopsis "Simple XML library for Haskell")
    (description "This package provides a simple XML library for Haskell.")
    (license bsd-3)))

(define-public ghc-exceptions
  (package
    (name "ghc-exceptions")
    (version "0.8.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/exceptions/exceptions-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1x1bk1jf42k1gigiqqmkkh38z2ffhx8rsqiszdq3f94m2h6kw2h7"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: Missing test-framework package.
    (propagated-inputs
     `(("ghc-stm" ,ghc-stm)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-transformers-compat" ,ghc-transformers-compat)))
    (home-page "http://github.com/ekmett/exceptions/")
    (synopsis "Extensible optionally-pure exceptions")
    (description "This library provides extensible optionally-pure exceptions
for Haskell.")
    (license bsd-3)))

(define-public ghc-temporary
  (package
    (name "ghc-temporary")
    (version "1.2.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/temporary/temporary-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0is67bmsjmbbw6wymhis8wyq9gax3sszm573p5719fx2c9z9r24a"))))
    (build-system haskell-build-system)
    (propagated-inputs `(("ghc-exceptions" ,ghc-exceptions)))
    (home-page "http://www.github.com/batterseapower/temporary")
    (synopsis "Temporary file and directory support")
    (description "The functions for creating temporary files and directories
in the Haskelll base library are quite limited.  This library just repackages
the Cabal implementations of its own temporary file and folder functions so
that you can use them without linking against Cabal or depending on it being
installed.")
    (license bsd-3)))

(define-public ghc-temporary-rc
  (package
    (name "ghc-temporary-rc")
    (version "1.2.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/temporary-rc/temporary-rc-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1nqih0qks439k3pr5kmbbc8rjdw730slrxlflqb27fbxbzb8skqs"))))
    (build-system haskell-build-system)
    (propagated-inputs `(("ghc-exceptions" ,ghc-exceptions)))
    (home-page
     "http://www.github.com/feuerbach/temporary")
    (synopsis
     "Portable temporary file and directory support")
    (description
     "The functions for creating temporary files and directories in the base
library are quite limited.  The unixutils package contains some good ones, but
they aren't portable to Windows.  This library just repackages the Cabal
implementations of its own temporary file and folder functions so that you can
use them without linking against Cabal or depending on it being installed.
This is a better maintained fork of the \"temporary\" package.")
    (license bsd-3)))

(define-public ghc-smallcheck
  (package
    (name "ghc-smallcheck")
    (version "1.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/smallcheck/smallcheck-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1ygrabxh40bym3grnzqyfqn96lirnxspb8cmwkkr213239y605sd"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-logict" ,ghc-logict)))
    (inputs
     `(("ghc-mtl" ,ghc-mtl)))
    (home-page
     "https://github.com/feuerbach/smallcheck")
    (synopsis "Property-based testing library")
    (description "SmallCheck is a testing library that allows to verify
properties for all test cases up to some depth.  The test cases are generated
automatically by SmallCheck.")
    (license bsd-3)))

(define-public ghc-tasty-ant-xml
  (package
    (name "ghc-tasty-ant-xml")
    (version "1.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/tasty-ant-xml/tasty-ant-xml-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0pgz2lclg2hp72ykljcbxd88pjanfdfk8m5vb2qzcyjr85kwrhxv"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-generic-deriving" ,ghc-generic-deriving)
       ("ghc-xml" ,ghc-xml)))
    (inputs
     `(("ghc-mtl" ,ghc-mtl)
       ("ghc-stm" ,ghc-stm)
       ("ghc-tagged" ,ghc-tagged)
       ("ghc-tasty" ,ghc-tasty)))
    (home-page
     "http://github.com/ocharles/tasty-ant-xml")
    (synopsis
     "Render tasty output to XML for Jenkins")
    (description
     "A tasty ingredient to output test results in XML, using the Ant
schema.  This XML can be consumed by the Jenkins continuous integration
framework.")
    (license bsd-3)))

(define-public ghc-tasty-smallcheck
  (package
    (name "ghc-tasty-smallcheck")
    (version "0.8.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/tasty-smallcheck/tasty-smallcheck-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0yckfbz8na8ccyw2911i3a4hd3fdncclk3ng5343hs5cylw6y4sm"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-tasty" ,ghc-tasty)
       ("ghc-smallcheck" ,ghc-smallcheck)
       ("ghc-async" ,ghc-async)
       ("ghc-tagged" ,ghc-tagged)))
    (home-page "http://documentup.com/feuerbach/tasty")
    (synopsis "SmallCheck support for the Tasty test framework")
    (description "This package provides SmallCheck support for the Tasty
Haskell test framework.")
    (license bsd-3)))

(define-public ghc-silently
  (package
    (name "ghc-silently")
    (version "1.2.5")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/silently/silently-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0f9qm3f7y0hpxn6mddhhg51mm1r134qkvd2kr8r6192ka1ijbxnf"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ;; circular dependency with nanospec
    ;; (inputs
    ;;  `(("ghc-temporary" ,ghc-temporary)))
    (home-page "https://github.com/hspec/silently")
    (synopsis "Prevent writing to stdout")
    (description "This package provides functions to prevent or capture
writing to stdout and other handles.")
    (license bsd-3)))

(define-public ghc-quickcheck-instances
  (package
    (name "ghc-quickcheck-instances")
    (version "0.3.11")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/"
             "quickcheck-instances/quickcheck-instances-"
             version ".tar.gz"))
       (sha256
        (base32
         "041s6963czs1pz0fc9cx17lgd6p83czqy2nxji7bhxqxwl2j15h2"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-old-time" ,ghc-old-time)
       ("ghc-unordered-containers" ,ghc-unordered-containers)))
    (inputs
     `(("ghc-hashable" ,ghc-hashable)
       ("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-text" ,ghc-text)))
    (home-page
     "https://github.com/aslatter/qc-instances")
    (synopsis "Common quickcheck instances")
    (description "This package provides QuickCheck instances for types
provided by the Haskell Platform.")
    (license bsd-3)))

(define-public ghc-quickcheck-unicode
  (package
    (name "ghc-quickcheck-unicode")
    (version "1.0.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/quickcheck-unicode/quickcheck-unicode-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1a8nl6x7l9b22yx61wm0bh2n1xzb1hd5i5zgg1w4fpaivjnrrhi4"))))
    (build-system haskell-build-system)
    (inputs `(("ghc-quickcheck" ,ghc-quickcheck)))
    (home-page
     "https://github.com/bos/quickcheck-unicode")
    (synopsis "Generator functions Unicode-related tests")
    (description "This package provides generator and shrink functions for
testing Unicode-related software.")
    (license bsd-3)))

(define-public ghc-quickcheck-io
  (package
    (name "ghc-quickcheck-io")
    (version "0.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/quickcheck-io/quickcheck-io-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1kf1kfw9fsmly0rvzvdf6jvdw10qhkmikyj0wcwciw6wad95w9sh"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-hunit" ,ghc-hunit)))
    (home-page
     "https://github.com/hspec/quickcheck-io#readme")
    (synopsis "Use HUnit assertions as QuickCheck properties")
    (description "This package provides an orphan instance that allows you to
use HUnit assertions as QuickCheck properties.")
    (license expat)))

(define-public ghc-quickcheck
  (package
    (name "ghc-quickcheck")
    (version "2.8.1")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/QuickCheck/QuickCheck-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0fvnfl30fxmj5q920l13641ar896d53z0z6z66m7c1366lvalwvh"))))
    (build-system haskell-build-system)
    (arguments
     `(#:tests? #f  ; FIXME: currently missing libraries used for tests.
       #:configure-flags '("-f base4")))
    ;; these inputs are necessary to use this package
    (propagated-inputs
     `(("ghc-tf-random" ,ghc-tf-random)))
    (home-page
     "https://github.com/nick8325/quickcheck")
    (synopsis
     "Automatic testing of Haskell programs")
    (description
     "QuickCheck is a library for random testing of program properties.")
    (license bsd-3)))

(define-public ghc-case-insensitive
  (package
    (name "ghc-case-insensitive")
    (version "1.2.0.4")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/case-insensitive/case-insensitive-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "07nm40r9yw2p9qsfp3pjbsmyn4dabrxw34p48171zmccdd5hv0v3"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-hunit" ,ghc-hunit)))
    ;; these inputs are necessary to use this library
    (propagated-inputs
     `(("ghc-text" ,ghc-text)
       ("ghc-hashable" ,ghc-hashable)))
    (arguments
     `(#:tests? #f)) ; FIXME: currently missing libraries used for tests.
    (home-page
     "https://github.com/basvandijk/case-insensitive")
    (synopsis "Case insensitive string comparison")
    (description
     "The module 'Data.CaseInsensitive' provides the 'CI' type constructor
which can be parameterised by a string-like type like: 'String', 'ByteString',
'Text', etc..  Comparisons of values of the resulting type will be insensitive
to cases.")
    (license bsd-3)))

(define-public ghc-syb
  (package
    (name "ghc-syb")
    (version "0.6")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/syb/syb-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1p3cnqjm13677r4a966zffzhi9b3a321aln8zs8ckqj0d9z1z3d3"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-hunit" ,ghc-hunit)
       ("ghc-mtl" ,ghc-mtl)))
    (home-page
     "http://www.cs.uu.nl/wiki/GenericProgramming/SYB")
    (synopsis "Scrap Your Boilerplate")
    (description "This package contains the generics system described in the
/Scrap Your Boilerplate/ papers (see
@uref{http://www.cs.uu.nl/wiki/GenericProgramming/SYB, the website}).  It
defines the 'Data' class of types permitting folding and unfolding of
constructor applications, instances of this class for primitive types, and a
variety of traversals.")
    (license bsd-3)))

(define-public ghc-fgl
  (package
    (name "ghc-fgl")
    (version "5.5.1.0")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/fgl/fgl-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0rcmz0xlyr1wj490ffja29z1jgl51gz19ka609da6bx39bwx7nga"))))
    (build-system haskell-build-system)
    (inputs `(("ghc-mtl" ,ghc-mtl)))
    (home-page "http://web.engr.oregonstate.edu/~erwig/fgl/haskell")
    (synopsis
     "Martin Erwig's Functional Graph Library")
    (description "The functional graph library, FGL, is a collection of type
and function definitions to address graph problems.  The basis of the library
is an inductive definition of graphs in the style of algebraic data types that
encourages inductive, recursive definitions of graph algorithms.")
    (license bsd-3)))

(define-public ghc-chasingbottoms
  (package
    (name "ghc-chasingbottoms")
    (version "1.3.0.13")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://hackage.haskell.org/package/ChasingBottoms/"
                           "ChasingBottoms-" version ".tar.gz"))
       (sha256
        (base32
         "1fb86jd6cdz4rx3fj3r9n8d60kx824ywwy7dw4qnrdran46ja3pl"))
       (modules '((guix build utils)))
       (snippet
        ;; The Hackage page and the cabal file linked there for this package
        ;; both list 0.7 as the upper version limit, but the source tarball
        ;; specifies 0.6.  Assume the Hackage page is correct.
        '(substitute* "ChasingBottoms.cabal"
           (("syb >= 0.1.0.2 && < 0.6") "syb >= 0.1.0.2 && < 0.7")))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-mtl" ,ghc-mtl)
       ("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-random" ,ghc-random)
       ("ghc-syb" ,ghc-syb)))
    (home-page "http://hackage.haskell.org/package/ChasingBottoms")
    (synopsis "Testing of partial and infinite values in Haskell")
    (description
     ;; FIXME: There should be a @comma{} in the uref text, but it is not
     ;; rendered properly.
     "This is a library for testing code involving bottoms or infinite values.
For the underlying theory and a larger example involving use of QuickCheck,
see the article
@uref{http://www.cse.chalmers.se/~nad/publications/danielsson-jansson-mpc2004.html,
\"Chasing Bottoms A Case Study in Program Verification in the Presence of
Partial and Infinite Values\"}.")
    (license expat)))

(define-public ghc-unordered-containers
  (package
    (name "ghc-unordered-containers")
    (version "0.2.5.1")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/unordered-containers"
             "/unordered-containers-" version ".tar.gz"))
       (sha256
        (base32
         "06l1xv7vhpxly75saxdrbc6p2zlgz1az278arfkz4rgawfnphn3f"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-chasingbottoms" ,ghc-chasingbottoms)
       ("ghc-hunit" ,ghc-hunit)
       ("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-test-framework" ,ghc-test-framework)
       ("ghc-test-framework-hunit" ,ghc-test-framework-hunit)
       ("ghc-test-framework-quickcheck2" ,ghc-test-framework-quickcheck2)))
    ;; these inputs are necessary to use this library
    (propagated-inputs `(("ghc-hashable" ,ghc-hashable)))
    (home-page
     "https://github.com/tibbe/unordered-containers")
    (synopsis
     "Efficient hashing-based container types")
    (description
     "Efficient hashing-based container types.  The containers have been
optimized for performance critical use, both in terms of large data quantities
and high speed.")
    (license bsd-3)))

(define-public ghc-uniplate
  (package
    (name "ghc-uniplate")
    (version "1.6.12")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/uniplate/uniplate-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1dx8f9aw27fz8kw0ad1nm6355w5rdl7bjvb427v2bsgnng30pipw"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-syb" ,ghc-syb)
       ("ghc-hashable" ,ghc-hashable)
       ("ghc-unordered-containers" ,ghc-unordered-containers)))
    (home-page "http://community.haskell.org/~ndm/uniplate/")
    (synopsis "Simple, concise and fast generic operations")
    (description "Uniplate is a library for writing simple and concise generic
operations.  Uniplate has similar goals to the original Scrap Your Boilerplate
work, but is substantially simpler and faster.")
    (license bsd-3)))

(define-public ghc-base64-bytestring
  (package
    (name "ghc-base64-bytestring")
    (version "1.0.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/base64-bytestring/base64-bytestring-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0l1v4ddjdsgi9nqzyzcxxj76rwar3lzx8gmwf2r54bqan3san9db"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f))         ; FIXME: testing libraries are missing.
    (home-page "https://github.com/bos/base64-bytestring")
    (synopsis "Base64 encoding and decoding for ByteStrings")
    (description "This library provides fast base64 encoding and decoding for
Haskell @code{ByteString}s.")
    (license bsd-3)))

(define-public ghc-annotated-wl-pprint
  (package
    (name "ghc-annotated-wl-pprint")
    (version "0.7.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/annotated-wl-pprint"
             "/annotated-wl-pprint-" version
             ".tar.gz"))
       (sha256
        (base32
         "061xfz6qany3wf95csl8dcik2pz22cn8iv1qchhm16isw5zjs9hc"))))
    (build-system haskell-build-system)
    (home-page
     "https://github.com/david-christiansen/annotated-wl-pprint")
    (synopsis
     "The Wadler/Leijen Pretty Printer, with annotation support")
    (description "This is a modified version of wl-pprint, which was based on
Wadler's paper \"A Prettier Printer\".  This version allows the library user
to annotate the text with semantic information, which can later be rendered in
a variety of ways.")
    (license bsd-3)))

(define-public ghc-ansi-wl-pprint
  (package
    (name "ghc-ansi-wl-pprint")
    (version "0.6.7.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/ansi-wl-pprint/ansi-wl-pprint-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "025pyphsjf0dnbrmj5nscbi6gzyigwgp3ifxb3psn7kji6mfr29p"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-ansi-terminal" ,ghc-ansi-terminal)))
    (home-page "http://github.com/ekmett/ansi-wl-pprint")
    (synopsis "Wadler/Leijen Pretty Printer for colored ANSI terminal output")
    (description "This is a pretty printing library based on Wadler's paper
\"A Prettier Printer\".  It has been enhanced with support for ANSI terminal
colored output using the ansi-terminal package.")
    (license bsd-3)))

(define-public ghc-split
  (package
    (name "ghc-split")
    (version "0.2.2")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/split/split-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0xa3j0gwr6k5vizxybnzk5fgb3pppgspi6mysnp2gwjp2dbrxkzr"))
       (modules '((guix build utils)))
       (snippet
        ;; The Cabal file on Hackage is updated, but the tar.gz does not
        ;; include it.  See
        ;; <https://hackage.haskell.org/package/split-0.2.2/revisions/>.
        '(substitute* "split.cabal"
           (("base <4.8") "base <4.9")))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)))
    (home-page "http://hackage.haskell.org/package/split")
    (synopsis "Combinator library for splitting lists")
    (description "This package provides a collection of Haskell functions for
splitting lists into parts, akin to the @code{split} function found in several
mainstream languages.")
    (license bsd-3)))

(define-public ghc-parsec
  (package
    (name "ghc-parsec")
    (version "3.1.9")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/parsec/parsec-"
             version
             ".tar.gz"))
       (sha256
        (base32 "1ja20cmj6v336jy87c6h3jzjp00sdbakwbdwp11iln499k913xvi"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-hunit" ,ghc-hunit)))
    ;; these inputs are necessary to use this library
    (propagated-inputs
     `(("ghc-text" ,ghc-text)
       ("ghc-mtl" ,ghc-mtl)))
    (arguments
     `(#:tests? #f)) ; FIXME: currently missing libraries used for tests.
    (home-page
     "https://github.com/aslatter/parsec")
    (synopsis "Monadic parser combinators")
    (description "Parsec is a parser library.  It is simple, safe, well
documented, has extensive libraries, good error messages, and is fast.  It is
defined as a monad transformer that can be stacked on arbitrary monads, and it
is also parametric in the input stream type.")
    (license bsd-3)))

(define-public ghc-vector
  (package
    (name "ghc-vector")
    (version "0.11.0.0")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/vector/vector-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1r1jlksy7b0kb0fy00g64isk6nyd9wzzdq31gx5v1wn38knj0lqa"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)))
    ;; these inputs are necessary to use this library
    (propagated-inputs
     `(("ghc-primitive" ,ghc-primitive)))
    (arguments
     `(#:tests? #f))      ; FIXME: currently missing libraries used for tests.
    (home-page "https://github.com/haskell/vector")
    (synopsis "Efficient Arrays")
    (description "This library provides an efficient implementation of
Int-indexed arrays (both mutable and immutable), with a powerful loop
optimisation framework.")
    (license bsd-3)))

(define-public ghc-vector-binary-instances
  (package
    (name "ghc-vector-binary-instances")
    (version "0.2.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/"
             "vector-binary-instances/vector-binary-instances-"
             version ".tar.gz"))
       (sha256
        (base32
         "028rsf2w193rhs1gic5yvvrwidw9sblczcn10aw64npfc6502l4l"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-cereal" ,ghc-cereal)))
    (inputs
     `(("ghc-vector" ,ghc-vector)))
    (home-page "https://github.com/bos/vector-binary-instances")
    (synopsis "Instances of Data.Binary and Data.Serialize for vector")
    (description "This library provides instances of @code{Binary} for the
types defined in the @code{vector} package, making it easy to serialize
vectors to and from disk.  We use the generic interface to vectors, so all
vector types are supported.  Specific instances are provided for unboxed,
boxed and storable vectors.")
    (license bsd-3)))

(define-public ghc-network
  (package
    (name "ghc-network")
    (version "2.6.2.1")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/network/network-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1yhvpd4wigz165jvyvw9zslx7lgqdj63jh3zv5s74b5ykdfa3zd3"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-hunit" ,ghc-hunit)))
    (arguments
     `(#:tests? #f))      ; FIXME: currently missing libraries used for tests.
    (home-page "https://github.com/haskell/network")
    (synopsis "Low-level networking interface")
    (description
     "This package provides a low-level networking interface.")
    (license bsd-3)))

(define-public ghc-network-uri
  (package
    (name "ghc-network-uri")
    (version "2.6.0.3")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/network-uri/network-uri-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1pwbqb2rk4rnvllvdch42p5368xcvpkanp7bxckdhxya8zzwvhhg"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-hunit" ,ghc-hunit)
       ("ghc-network" ,ghc-network)))
    (arguments
     `(#:tests? #f))  ; FIXME: currently missing libraries used for tests.
    (propagated-inputs
     `(("ghc-parsec" ,ghc-parsec)))
    (home-page
     "https://github.com/haskell/network-uri")
    (synopsis "Library for URI manipulation")
    (description "This package provides an URI manipulation interface.  In
'network-2.6' the 'Network.URI' module was split off from the 'network'
package into this package.")
    (license bsd-3)))

(define-public ghc-ansi-terminal
  (package
    (name "ghc-ansi-terminal")
    (version "0.6.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/ansi-terminal/ansi-terminal-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0hpfw0k025y681m9ml1c712skrb1p4vh7z5x1f0ci9ww7ssjrh2d"))))
    (build-system haskell-build-system)
    (home-page "https://github.com/feuerbach/ansi-terminal")
    (synopsis "ANSI terminal support for Haskell")
    (description "This package provides ANSI terminal support for Haskell.  It
allows cursor movement, screen clearing, color output showing or hiding the
cursor, and changing the title.")
    (license bsd-3)))

(define-public ghc-http
  (package
    (name "ghc-http")
    (version "4000.2.20")
    (outputs '("out" "doc"))
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/HTTP/HTTP-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0nyqdxr5ls2dxkf4a1f3x15xzwdm46ppn99nkcbhswlr6s3cq1s4"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-hunit" ,ghc-hunit)))
    (propagated-inputs
     `(("ghc-old-time" ,ghc-old-time)
       ("ghc-parsec" ,ghc-parsec)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-network" ,ghc-network)
       ("ghc-network-uri" ,ghc-network-uri)))
    (arguments
     `(#:tests? #f))  ; FIXME: currently missing libraries used for tests.
    (home-page "https://github.com/haskell/HTTP")
    (synopsis "Library for client-side HTTP")
    (description
     "The HTTP package supports client-side web programming in Haskell.  It
lets you set up HTTP connections, transmitting requests and processing the
responses coming back.")
    (license bsd-3)))

(define-public ghc-hspec
  (package
    (name "ghc-hspec")
    (version "2.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/hspec/hspec-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0zqisxznlbszivsgy3irvf566zhcr6ipqqj3x9i7pj5hy913jwqf"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-hspec-core" ,ghc-hspec-core)
       ("hspec-discover" ,hspec-discover)
       ("ghc-hspec-expectations" ,ghc-hspec-expectations)
       ("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-hunit" ,ghc-hunit)))
    (inputs
     `(("ghc-stringbuilder" ,ghc-stringbuilder)
       ("ghc-hspec-meta" ,ghc-hspec-meta)))
    (home-page "http://hspec.github.io/")
    (synopsis "Testing Framework for Haskell")
    (description "This library provides the Hspec testing framework for
Haskell, inspired by the Ruby library RSpec.")
    (license expat)))

(define-public ghc-hspec-expectations
  (package
    (name "ghc-hspec-expectations")
    (version "0.7.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/hspec-expectations/hspec-expectations-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1w56jiqfyl237sr207gh3b0l8sr9layy0mdsgd5wknzb49mif6ip"))))
    (build-system haskell-build-system)
    (inputs `(("ghc-hunit" ,ghc-hunit)))
    (home-page "https://github.com/sol/hspec-expectations")
    (synopsis "Catchy combinators for HUnit")
    (description "This library provides catchy combinators for HUnit, see
@uref{https://github.com/sol/hspec-expectations#readme, the README}.")
    (license expat)))

(define-public hspec-discover
  (package
    (name "hspec-discover")
    (version "2.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/hspec-discover/hspec-discover-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0w3awzbljf4hqhxrjrxqa1lfcclg92bhmq641gz2q80vycspapzx"))))
    (build-system haskell-build-system)
    (arguments `(#:haddock? #f)) ; Haddock phase fails because there are no
                                 ; documentation files.
    (inputs `(("ghc-hspec-meta" ,ghc-hspec-meta)))
    (home-page "http://hspec.github.io/")
    (synopsis "Automatically discover and run Hspec tests")
    (description "hspec-discover is a tool which automatically discovers and
runs Hspec tests.")
    (license expat)))

(define-public ghc-hspec-core
  (package
    (name "ghc-hspec-core")
    (version "2.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/hspec-core/hspec-core-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1wgd55k652jaf81nkvciyqi67ycj7zamr4nd9z1cqf8nr9fc3sa4"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: testing libraries are missing.
    (propagated-inputs
     `(("ghc-setenv" ,ghc-setenv)
       ("ghc-ansi-terminal" ,ghc-ansi-terminal)
       ("ghc-async" ,ghc-async)
       ("ghc-quickcheck-io" ,ghc-quickcheck-io)))
    (inputs
     `(("ghc-hunit" ,ghc-hunit)
       ("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-hspec-expectations" ,ghc-hspec-expectations)
       ("ghc-silently" ,ghc-silently)))
    (home-page "http://hspec.github.io/")
    (synopsis "Testing framework for Haskell")
    (description "This library exposes internal types and functions that can
be used to extend Hspec's functionality.")
    (license expat)))

(define-public ghc-hspec-meta
  (package
    (name "ghc-hspec-meta")
    (version "2.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/hspec-meta/hspec-meta-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1fmqmgrzp135cxhmxxbaswkk4bqbpgfml00cmcz0d39n11vzpa5z"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-hunit" ,ghc-hunit)
       ("ghc-ansi-terminal" ,ghc-ansi-terminal)
       ("ghc-async" ,ghc-async)
       ("ghc-hspec-expectations" ,ghc-hspec-expectations)
       ("ghc-setenv" ,ghc-setenv)
       ("ghc-random" ,ghc-random)
       ("ghc-quickcheck-io" ,ghc-quickcheck-io)))
    (home-page "http://hspec.github.io/")
    (synopsis "Version of Hspec to test Hspec itself")
    (description "This library provides a stable version of Hspec which is
used to test the in-development version of Hspec.")
    (license expat)))

(define-public ghc-vault
  (package
    (name "ghc-vault")
    (version "0.3.0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/vault/vault-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0ah6qrg71krc87f4vjy4b4shdd0mgyil8fikb3j6fl4kfwlg67jn"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-unordered-containers" ,ghc-unordered-containers)
       ("ghc-hashable" ,ghc-hashable)))
    (home-page
     "https://github.com/HeinrichApfelmus/vault")
    (synopsis "Persistent store for arbitrary values")
    (description "This package provides vaults for Haskell.  A vault is a
persistent store for values of arbitrary types.  It's like having first-class
access to the storage space behind @code{IORefs}.  The data structure is
analogous to a bank vault, where you can access different bank boxes with
different keys; hence the name.  Also provided is a @code{locker} type,
representing a store for a single element.")
    (license bsd-3)))

(define-public ghc-mmorph
  (package
    (name "ghc-mmorph")
    (version "1.0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/mmorph/mmorph-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0k5zlzmnixfwcjrqvhgi3i6xg532b0gsjvc39v5jigw69idndqr2"))))
    (build-system haskell-build-system)
    (home-page
     "http://hackage.haskell.org/package/mmorph")
    (synopsis "Monad morphisms")
    (description
     "This library provides monad morphism utilities, most commonly used for
manipulating monad transformer stacks.")
    (license bsd-3)))

(define-public ghc-monad-control
  (package
    (name "ghc-monad-control")
    (version "1.0.0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/monad-control"
             "/monad-control-" version ".tar.gz"))
       (sha256
        (base32
         "07pn1p4m80wdd7gw62s4yny8rbvm60ka1q8qx5y1plznd8sbg179"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-stm" ,ghc-stm)
       ("ghc-transformers-base" ,ghc-transformers-base)
       ("ghc-transformers-compat" ,ghc-transformers-compat)))
    (home-page "https://github.com/basvandijk/monad-control")
    (synopsis "Monad transformers to lift control operations like exception
catching")
    (description "This package defines the type class @code{MonadBaseControl},
a subset of @code{MonadBase} into which generic control operations such as
@code{catch} can be lifted from @code{IO} or any other base monad.")
    (license bsd-3)))

(define-public ghc-byteorder
  (package
    (name "ghc-byteorder")
    (version "1.0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/byteorder/byteorder-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "06995paxbxk8lldvarqpb3ygcjbg4v8dk4scib1rjzwlhssvn85x"))))
    (build-system haskell-build-system)
    (home-page
     "http://community.haskell.org/~aslatter/code/byteorder")
    (synopsis
     "Exposes the native endianness of the system")
    (description
     "This package is for working with the native byte-ordering of the
system.")
    (license bsd-3)))

(define-public ghc-base-compat
  (package
    (name "ghc-base-compat")
    (version "0.8.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/base-compat/base-compat-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "02m93hzgxg4bcnp7xcc2fdh2hrsc2h6fwl8hix5nx9k864kwf41q"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-hspec" ,ghc-hspec)))
    (home-page "https://hackage.haskell.org/package/base-compat")
    (synopsis "Haskell compiler compatibility library")
    (description "This library provides functions available in later versions
of base to a wider range of compilers, without requiring the use of CPP
pragmas in your code.")
    (license bsd-3)))

(define-public ghc-blaze-builder
  (package
    (name "ghc-blaze-builder")
    (version "0.4.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/blaze-builder/blaze-builder-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1id3w33x9f7q5m3xpggmvzw03bkp94bpfyz81625bldqgf3yqdn1"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f))          ; FIXME: Missing test libraries.
    (propagated-inputs
     `(("ghc-text" ,ghc-text)
       ("ghc-utf8-string" ,ghc-utf8-string)))
    (home-page "http://github.com/lpsmith/blaze-builder")
    (synopsis "Efficient buffered output")
    (description "This library provides an implementation of the older
@code{blaze-builder} interface in terms of the new builder that shipped with
@code{bytestring-0.10.4.0}.  This implementation is mostly intended as a
bridge to the new builder, so that code that uses the old interface can
interoperate with code that uses the new implementation.")
    (license bsd-3)))

(define-public ghc-blaze-markup
  (package
    (name "ghc-blaze-markup")
    (version "0.7.0.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/blaze-markup/blaze-markup-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "080vlhd8dwjxrma4bb524lh8gxs5lm3xh122icy6lnnyipla0s9y"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: testing libraries are missing.
    (propagated-inputs
     `(("ghc-blaze-builder" ,ghc-blaze-builder)
       ("ghc-text" ,ghc-text)))
    (home-page "http://jaspervdj.be/blaze")
    (synopsis "Fast markup combinator library for Haskell")
    (description "This library provides core modules of a markup combinator
library for Haskell.")
    (license bsd-3)))

(define-public ghc-blaze-html
  (package
    (name "ghc-blaze-html")
    (version "0.8.1.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/blaze-html/blaze-html-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1dnw50kh0s405cg9i2y4a8awanhj3bqzk21jwgfza65kcjby7lpq"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: testing libraries are missing.
    (propagated-inputs
     `(("ghc-blaze-builder" ,ghc-blaze-builder)
       ("ghc-text" ,ghc-text)
       ("ghc-blaze-markup" ,ghc-blaze-markup)))
    (home-page "http://jaspervdj.be/blaze")
    (synopsis "Fast HTML combinator library")
    (description "This library provides HTML combinators for Haskell.")
    (license bsd-3)))

(define-public ghc-easy-file
  (package
    (name "ghc-easy-file")
    (version "0.2.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/easy-file/easy-file-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0v75081bx4qzlqy29hh639nzlr7dncwza3qxbzm9njc4jarf31pz"))))
    (build-system haskell-build-system)
    (home-page
     "http://github.com/kazu-yamamoto/easy-file")
    (synopsis "File handling library for Haskell")
    (description "This library provides file handling utilities for Haskell.")
    (license bsd-3)))

(define-public ghc-async
  (package
    (name "ghc-async")
    (version "2.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/async/async-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0azx4qk65a9a2gvqsfmz3w89m6shzr2iz0i5lly2zvly4n2d6m6v"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-hunit" ,ghc-hunit)
       ("ghc-test-framework" ,ghc-test-framework)
       ("ghc-test-framework-hunit" ,ghc-test-framework-hunit)))
    (propagated-inputs
     `(("ghc-stm" ,ghc-stm)))
    (home-page "https://github.com/simonmar/async")
    (synopsis "Library to run IO operations asynchronously")
    (description "Async provides a library to run IO operations
asynchronously, and wait for their results.  It is a higher-level interface
over threads in Haskell, in which @code{Async a} is a concurrent thread that
will eventually deliver a value of type @code{a}.")
    (license bsd-3)))

(define-public ghc-fingertree
  (package
    (name "ghc-fingertree")
    (version "0.1.1.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/fingertree/fingertree-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1w6x3kp3by5yjmam6wlrf9vap5l5rrqaip0djbrdp0fpf2imn30n"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: testing libraries are missing.
    (home-page "http://hackage.haskell.org/package/fingertree")
    (synopsis "Generic finger-tree structure")
    (description "This library provides finger trees, a general sequence
representation with arbitrary annotations, for use as a base for
implementations of various collection types.  It includes examples, as
described in section 4 of Ralf Hinze and Ross Paterson, \"Finger trees: a
simple general-purpose data structure\".")
    (license bsd-3)))

(define-public ghc-optparse-applicative
  (package
    (name "ghc-optparse-applicative")
    (version "0.11.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/optparse-applicative"
             "/optparse-applicative-" version ".tar.gz"))
       (sha256
        (base32
         "0ni52ii9555jngljvzxn1ngicr6i2w647ww3rzhdrmng04y95iii"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-transformers-compat" ,ghc-transformers-compat)
       ("ghc-ansi-wl-pprint" ,ghc-ansi-wl-pprint)))
    (home-page "https://github.com/pcapriotti/optparse-applicative")
    (synopsis "Utilities and combinators for parsing command line options")
    (description "This package provides utilities and combinators for parsing
command line options in Haskell.")
    (license bsd-3)))

(define-public ghc-base-orphans
  (package
    (name "ghc-base-orphans")
    (version "0.4.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/base-orphans/base-orphans-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0hhgpwjvx7jhvlhsygmmf0q5hv2ymijzz4bjilicw99bmv13qcpl"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-hspec" ,ghc-hspec)))
    (home-page "https://hackage.haskell.org/package/base-orphans")
    (synopsis "Orphan instances for backwards compatibility")
    (description "This package defines orphan instances that mimic instances
available in later versions of base to a wider (older) range of compilers.")
    (license bsd-3)))

(define-public ghc-auto-update
  (package
    (name "ghc-auto-update")
    (version "0.1.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/auto-update/auto-update-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1ns4c5mqhnm7hsiqxf1ivjs5fflyq92b16ldzrcl0p85631h0c3v"))))
    (build-system haskell-build-system)
    (home-page "https://github.com/yesodweb/wai")
    (synopsis "Efficiently run periodic, on-demand actions")
    (description "This library provides mechanisms to efficiently run
periodic, on-demand actions in Haskell.")
    (license expat)))

(define-public ghc-tagged
  (package
    (name "ghc-tagged")
    (version "0.8.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/tagged/tagged-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1hc2qzhhz5p1xd8k03sklrdnhcflkwhgpl82k6fam8yckww9ipav"))))
    (build-system haskell-build-system)
    (home-page "https://hackage.haskell.org/package/tagged")
    (synopsis "Haskell phantom types to avoid passing dummy arguments")
    (description "This library provides phantom types for Haskell 98, to avoid
having to unsafely pass dummy arguments.")
    (license bsd-3)))

(define-public ghc-unbounded-delays
  (package
    (name "ghc-unbounded-delays")
    (version "0.1.0.9")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/unbounded-delays/unbounded-delays-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1f4h87503m3smhip432q027wj3zih18pmz2rnafh60589ifcl420"))))
    (build-system haskell-build-system)
    (home-page "https://github.com/basvandijk/unbounded-delays")
    (synopsis "Unbounded thread delays and timeouts")
    (description "The @code{threadDelay} and @code{timeout} functions from the
Haskell base library use the bounded @code{Int} type for specifying the delay
or timeout period.  This package provides alternative functions which use the
unbounded @code{Integer} type.")
    (license bsd-3)))

;; This package builds `clock` without tests, since the tests rely on tasty
;; and tasty-quickcheck, which in turn require clock to build.  When tasty and
;; tasty-quickcheck are added, we will add ghc-clock with tests enabled.
(define ghc-clock-bootstrap
  (package
    (name "ghc-clock-bootstrap")
    (version "0.5.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/"
             "clock/"
             "clock-" version ".tar.gz"))
       (sha256
        (base32 "1ncph7vi2q6ywwc8ysxl1ibw6i5dwfvln88ssfazk8jgpj4iyykw"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ;; Testing suite depends on tasty and
                               ;; tasty-quickcheck, which need clock to build.
    (home-page "https://hackage.haskell.org/package/clock")
    (synopsis "High-resolution clock for Haskell")
    (description "A package for convenient access to high-resolution clock and
timer functions of different operating systems via a unified API.")
    (license bsd-3)))

(define-public ghc-clock
  (package
    (name "ghc-clock")
    (version "0.5.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/"
             "clock/"
             "clock-" version ".tar.gz"))
       (sha256
        (base32 "1ncph7vi2q6ywwc8ysxl1ibw6i5dwfvln88ssfazk8jgpj4iyykw"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-tasty" ,ghc-tasty)
       ("ghc-tasty-quickcheck" ,ghc-tasty-quickcheck)))
    (home-page "https://hackage.haskell.org/package/clock")
    (synopsis "High-resolution clock for Haskell")
    (description "A package for convenient access to high-resolution clock and
timer functions of different operating systems via a unified API.")
    (license bsd-3)))

(define-public ghc-charset
  (package
    (name "ghc-charset")
    (version "0.3.7.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/charset/charset-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1gn0m96qpjww8hpp2g1as5yy0wcwy4iq73h3kz6g0yxxhcl5sh9x"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-semigroups" ,ghc-semigroups)))
    (inputs
     `(("ghc-unordered-containers" ,ghc-unordered-containers)))
    (home-page "http://github.com/ekmett/charset")
    (synopsis "Fast unicode character sets for Haskell")
    (description "This package provides fast unicode character sets for
Haskell, based on complemented PATRICIA tries.")
    (license bsd-3)))

(define-public ghc-bytestring-builder
  (package
    (name "ghc-bytestring-builder")
    (version "0.10.6.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/bytestring-builder"
             "/bytestring-builder-" version ".tar.gz"))
       (sha256
        (base32
         "1mkg24zl0rapb3gqzkyj5ibp07wx3yzd72hmfczssl0is63rjhww"))))
    (build-system haskell-build-system)
    (arguments `(#:haddock? #f)) ; Package contains no documentation.
    (home-page "http://hackage.haskell.org/package/bytestring-builder")
    (synopsis "The new bytestring builder, packaged outside of GHC")
    (description "This package provides the bytestring builder that is
debuting in bytestring-0.10.4.0, which should be shipping with GHC 7.8.
Compatibility package for older packages.")
    (license bsd-3)))

(define-public ghc-nats
  (package
    (name "ghc-nats")
    (version "1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/nats/nats-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0r6s8l4s0yq3x2crrkv0b8zac13magfasr9v8hnq6rn1icsfhic0"))))
    (build-system haskell-build-system)
    (arguments `(#:haddock? #f))
    (inputs
     `(("ghc-hashable" ,ghc-hashable)))
    (home-page "https://hackage.haskell.org/package/nats")
    (synopsis "Natural numbers")
    (description "This library provides the natural numbers for Haskell.")
    (license bsd-3)))

(define-public ghc-void
  (package
    (name "ghc-void")
    (version "0.7.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/void/void-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1x15x2axz84ndw2bf60vjqljhrb0w95lddaljsxrl0hcd29zvw69"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-semigroups" ,ghc-semigroups)))
    (inputs
     `(("ghc-hashable" ,ghc-hashable)))
    (home-page "http://github.com/ekmett/void")
    (synopsis
     "Logically uninhabited data type")
    (description
     "A Haskell 98 logically uninhabited data type, used to indicate that a
given term should not exist.")
    (license bsd-3)))

(define-public ghc-kan-extensions
  (package
    (name "ghc-kan-extensions")
    (version "4.2.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/kan-extensions/kan-extensions-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0iywbadpy8s3isfzlx9dlz3apaywhqq4gdbxkwygksq8pzdhwkrk"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-adjunctions" ,ghc-adjunctions)))
    (inputs
     `(("ghc-comonad" ,ghc-comonad)
       ("ghc-contravariant" ,ghc-contravariant)
       ("ghc-distributive" ,ghc-distributive)
       ("ghc-free" ,ghc-free)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-semigroupoids" ,ghc-semigroupoids)
       ("ghc-tagged" ,ghc-tagged)))
    (home-page "http://github.com/ekmett/kan-extensions/")
    (synopsis "Kan extensions library")
    (description "This library provides Kan extensions, Kan lifts, various
forms of the Yoneda lemma, and (co)density (co)monads for Haskell.")
    (license bsd-3)))

(define-public ghc-statevar
  (package
    (name "ghc-statevar")
    (version "1.1.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/StateVar/StateVar-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1ap51cvwq61xckx5hw44l82ihbxvsq3263xr5hqg42c5qp67kbhf"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-stm" ,ghc-stm)))
    (home-page "http://hackage.haskell.org/package/StateVar")
    (synopsis "State variables for Haskell")
    (description "This package provides state variables, which are references
in the @code{IO} monad, like @code{IORef}s or parts of the OpenGL state.")
    (license bsd-3)))

(define-public ghc-lens
  (package
    (name "ghc-lens")
    (version "4.13")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/lens/lens-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0g4g0xksrb2m8wgsmraaq8qnk1sssb42kr65fc7clgyid6zyfmim"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: doctest packagedb propagation problem.
    (propagated-inputs
     `(("ghc-base-orphans" ,ghc-base-orphans)
       ("ghc-bifunctors" ,ghc-bifunctors)
       ("ghc-distributive" ,ghc-distributive)
       ("ghc-exceptions" ,ghc-exceptions)
       ("ghc-free" ,ghc-free)
       ("ghc-kan-extensions" ,ghc-kan-extensions)
       ("ghc-parallel" ,ghc-parallel)
       ("ghc-reflection" ,ghc-reflection)
       ("ghc-semigroupoids" ,ghc-semigroupoids)
       ("ghc-vector" ,ghc-vector)))
    (inputs
     `(("ghc-comonad" ,ghc-comonad)
       ("ghc-contravariant" ,ghc-contravariant)
       ("ghc-hashable" ,ghc-hashable)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-profunctors" ,ghc-profunctors)
       ("ghc-semigroups" ,ghc-semigroups)
       ("ghc-tagged" ,ghc-tagged)
       ("ghc-text" ,ghc-text)
       ("ghc-transformers-compat" ,ghc-transformers-compat)
       ("ghc-unordered-containers" ,ghc-unordered-containers)
       ("ghc-void" ,ghc-void)
       ("ghc-generic-deriving" ,ghc-generic-deriving)
       ("ghc-nats" ,ghc-nats)
       ("ghc-simple-reflect" ,ghc-simple-reflect)
       ("hlint" ,hlint)))
    (home-page "http://github.com/ekmett/lens/")
    (synopsis "Lenses, Folds and Traversals")
    (description "This library provides @code{Control.Lens}.  The combinators
in @code{Control.Lens} provide a highly generic toolbox for composing families
of getters, folds, isomorphisms, traversals, setters and lenses and their
indexed variants.")
    (license bsd-3)))

(define-public ghc-tagsoup
  (package
    (name "ghc-tagsoup")
    (version "0.13.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/tagsoup/tagsoup-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "13b6zy6346r3cxhaivys84fnxarg8wbv7r2znazfjdkqil8n5a1j"))))
    (build-system haskell-build-system)
    (inputs `(("ghc-text" ,ghc-text)))
    (home-page
     "http://community.haskell.org/~ndm/tagsoup/")
    (synopsis
     "Parsing and extracting information from (possibly malformed) HTML/XML
documents")
    (description
     "TagSoup is a library for parsing HTML/XML.  It supports the HTML 5
specification, and can be used to parse either well-formed XML, or
unstructured and malformed HTML from the web.  The library also provides
useful functions to extract information from an HTML document, making it ideal
for screen-scraping.")
    (license bsd-3)))

(define-public ghc-digest
  (package
    (name "ghc-digest")
    (version "0.0.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/digest/digest-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "04gy2zp8yzvv7j9bdfvmfzcz3sqyqa6rwslqcn4vyair2vmif5v4"))))
    (build-system haskell-build-system)
    (inputs
     `(("zlib" ,zlib)))
    (home-page
     "http://hackage.haskell.org/package/digest")
    (synopsis
     "Various cryptographic hashes for bytestrings")
    (description
     "This package provides efficient cryptographic hash implementations for
strict and lazy bytestrings.  For now, CRC32 and Adler32 are supported; they
are implemented as FFI bindings to efficient code from zlib.")
    (license bsd-3)))

(define-public ghc-cheapskate
  (package
    (name "ghc-cheapskate")
    (version "0.1.0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/cheapskate/cheapskate-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0drx1hlqvdcrij4097q6bxhbfcqm73jsqv1wwhd3hsnjdmr46ch2"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-xss-sanitize" ,ghc-xss-sanitize)
       ("ghc-data-default" ,ghc-data-default)))
    (inputs
     `(("ghc-mtl" ,ghc-mtl)
       ("ghc-text" ,ghc-text)
       ("ghc-blaze-html" ,ghc-blaze-html)
       ("ghc-syb" ,ghc-syb)
       ("ghc-uniplate" ,ghc-uniplate)
       ("ghc-aeson" ,ghc-aeson)
       ("ghc-wai-extra" ,ghc-wai-extra)
       ("ghc-wai" ,ghc-wai)
       ("ghc-http-types" ,ghc-http-types)))
    (home-page "http://github.com/jgm/cheapskate")
    (synopsis "Experimental markdown processor")
    (description "Cheapskate is an experimental Markdown processor in pure
Haskell.  It aims to process Markdown efficiently and in the most forgiving
possible way.  It is designed to deal with any input, including garbage, with
linear performance.  Output is sanitized by default for protection against XSS
attacks.")
    (license bsd-3)))

(define-public ghc-bifunctors
  (package
    (name "ghc-bifunctors")
    (version "5")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/bifunctors/bifunctors-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "13990xdgx0n23qgi18ghhmsywj5zkr0a5bim0g8a4nzi0cx95ps1"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-tagged" ,ghc-tagged)
       ("ghc-semigroups" ,ghc-semigroups)))
    (home-page "http://github.com/ekmett/bifunctors/")
    (synopsis "Bifunctors for Haskell")
    (description "This package provides bifunctors for Haskell.")
    (license bsd-3)))

(define-public ghc-semigroupoids
  (package
    (name "ghc-semigroupoids")
    (version "5.0.0.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/semigroupoids/semigroupoids-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1jf7jnfhdvl6p18wdr21yi2fim1xb8alcn6szhrdswj0dkilgq6d"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-base-orphans" ,ghc-base-orphans)
       ("ghc-transformers-compat" ,ghc-transformers-compat)
       ("ghc-bifunctors" ,ghc-bifunctors)
       ("ghc-comonad" ,ghc-comonad)
       ("ghc-contravariant" ,ghc-contravariant)
       ("ghc-distributive" ,ghc-distributive)))
    (arguments `(#:tests? #f)) ; FIXME: doctest packagedb propagation problem.
    (inputs
     `(("ghc-semigroups" ,ghc-semigroups)
       ("ghc-tagged" ,ghc-tagged)))
    (home-page "http://github.com/ekmett/semigroupoids")
    (synopsis "Semigroupoids operations for Haskell")
    (description "This library provides a wide array of (semi)groupoids and
operations for working with them.  A @code{Semigroupoid} is a @code{Category}
without the requirement of identity arrows for every object in the category.
A @code{Category} is any @code{Semigroupoid} for which the Yoneda lemma holds.
Finally, to work with these weaker structures it is beneficial to have
containers that can provide stronger guarantees about their contents, so
versions of @code{Traversable} and @code{Foldable} that can be folded with
just a @code{Semigroup} are added.")
    (license bsd-3)))

(define-public ghc-contravariant
  (package
    (name "ghc-contravariant")
    (version "1.3.3")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/contravariant/contravariant-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "184hcmhsznqrkmqlc1kza9pb5p591anva574ry8wrh81vqmhwfb5"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-void" ,ghc-void)
       ("ghc-transformers-compat" ,ghc-transformers-compat)
       ("ghc-statevar" ,ghc-statevar)))
    (inputs
     `(("ghc-semigroups" ,ghc-semigroups)))
    (home-page
     "http://github.com/ekmett/contravariant/")
    (synopsis "Contravariant functors")
    (description "Contravariant functors for Haskell.")
    (license bsd-3)))

(define-public ghc-semigroups
  (package
    (name "ghc-semigroups")
    (version "0.17.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/semigroups/semigroups-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0gvpfi7s6ys4qha3y9a1zl1a15gf9cgg33wjb94ghg82ivcxnc3r"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-nats" ,ghc-nats)
       ("ghc-tagged" ,ghc-tagged)
       ("ghc-unordered-containers" ,ghc-unordered-containers)))
    (inputs
     `(("ghc-text" ,ghc-text)
       ("ghc-hashable" ,ghc-hashable)))
    (home-page "http://github.com/ekmett/semigroups/")
    (synopsis "Semigroup operations for Haskell")
    (description "This package provides semigroups for Haskell.  In
mathematics, a semigroup is an algebraic structure consisting of a set
together with an associative binary operation.  A semigroup generalizes a
monoid in that there might not exist an identity element.  It
also (originally) generalized a group (a monoid with all inverses) to a type
where every element did not have to have an inverse, thus the name
semigroup.")
    (license bsd-3)))

(define-public ghc-free
  (package
    (name "ghc-free")
    (version "4.12.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/free/free-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0sr8phvrb4ny8j1wzq55rdn8q4br23q4pw2j276npr844825jr9p"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-prelude-extras" ,ghc-prelude-extras)
       ("ghc-profunctors" ,ghc-profunctors)
       ("ghc-exceptions" ,ghc-exceptions)))
    (inputs
     `(("ghc-bifunctors" ,ghc-bifunctors)
       ("ghc-comonad" ,ghc-comonad)
       ("ghc-distributive" ,ghc-distributive)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-semigroupoids" ,ghc-semigroupoids)
       ("ghc-semigroups" ,ghc-semigroups)))
    (home-page "http://github.com/ekmett/free/")
    (synopsis "Unrestricted monads for Haskell")
    (description "This library provides free monads, which are useful for many
tree-like structures and domain specific languages.  If @code{f} is a
@code{Functor} then the free @code{Monad} on @code{f} is the type of trees
whose nodes are labeled with the constructors of @code{f}.  The word \"free\"
is used in the sense of \"unrestricted\" rather than \"zero-cost\": @code{Free
f} makes no constraining assumptions beyond those given by @code{f} and the
definition of @code{Monad}.")
    (license bsd-3)))

(define-public ghc-adjunctions
  (package
    (name "ghc-adjunctions")
    (version "4.2.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/adjunctions/adjunctions-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "00p030iypjzjib8pxz1x6mxfi59wvyrwjj11zv9bh766dgkdbwjq"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-profunctors" ,ghc-profunctors)))
    (inputs
     `(("ghc-comonad" ,ghc-comonad)
       ("ghc-contravariant" ,ghc-contravariant)
       ("ghc-distributive" ,ghc-distributive)
       ("ghc-free" ,ghc-free)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-tagged" ,ghc-tagged)
       ("ghc-semigroupoids" ,ghc-semigroupoids)
       ("ghc-semigroups" ,ghc-semigroups)
       ("ghc-void" ,ghc-void)))
    (home-page "http://github.com/ekmett/adjunctions/")
    (synopsis "Adjunctions and representable functors")
    (description "This library provides adjunctions and representable functors
for Haskell.")
    (license bsd-3)))

(define-public ghc-fast-logger
  (package
    (name "ghc-fast-logger")
    (version "2.4.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/fast-logger/fast-logger-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0kjk1861qcls8m8y7i55msfpprws5wk6c5mxzi35g2qbl2sih4p5"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-bytestring-builder" ,ghc-bytestring-builder)
       ("ghc-auto-update" ,ghc-auto-update)))
    (inputs
     `(("ghc-hspec" ,ghc-hspec)
       ("ghc-text" ,ghc-text)))
    (home-page "https://hackage.haskell.org/package/fast-logger")
    (synopsis "Fast logging system")
    (description "This library provides a fast logging system for Haskell.")
    (license bsd-3)))

(define-public ghc-doctest
  (package
    (name "ghc-doctest")
    (version "0.10.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/doctest/doctest-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1jbyhzbi2hfrfg7vbkpj6vriaap8cn99nnmzwcfscwaijz09jyrm"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f))          ; FIXME: missing test framework
    (propagated-inputs
     `(("ghc-syb" ,ghc-syb)
       ("ghc-paths" ,ghc-paths)))
    (inputs
     `(("ghc-base-compat" ,ghc-base-compat)
       ("ghc-hunit" ,ghc-hunit)
       ("ghc-hspec" ,ghc-hspec)
       ("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-stringbuilder" ,ghc-stringbuilder)
       ("ghc-silently" ,ghc-silently)
       ("ghc-setenv" ,ghc-setenv)))
    (home-page
     "https://github.com/sol/doctest#readme")
    (synopsis "Test interactive Haskell examples")
    (description "The doctest program checks examples in source code comments.
It is modeled after doctest for Python, see
@uref{http://docs.python.org/library/doctest.html, the Doctest website}.")
    (license expat)))

(define-public ghc-lifted-base
  (package
    (name "ghc-lifted-base")
    (version "0.2.3.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/lifted-base/lifted-base-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1yz14a1rsgknwyl08n4kxrlc26hfwmb95a3c2drbnsgmhdyq7iap"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: Missing testing libraries.
    (propagated-inputs
     `(("ghc-transformers-base" ,ghc-transformers-base)
       ("ghc-monad-control" ,ghc-monad-control)))
    (inputs
     `(("ghc-transformers-compat" ,ghc-transformers-compat)
       ("ghc-hunit" ,ghc-hunit)))
    (home-page "https://github.com/basvandijk/lifted-base")
    (synopsis "Lifted IO operations from the base library")
    (description "Lifted-base exports IO operations from the @code{base}
library lifted to any instance of @code{MonadBase} or @code{MonadBaseControl}.
Note that not all modules from @code{base} are converted yet.  The package
includes a copy of the @code{monad-peel} test suite written by Anders
Kaseorg.")
    (license bsd-3)))

(define-public ghc-word8
  (package
    (name "ghc-word8")
    (version "0.1.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/word8/word8-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1pbn8ra3qhwvw07p375cdmp7jzlg07hgdcr4cpscz3h7b9sy7fiw"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-hspec" ,ghc-hspec)))
    (home-page "http://hackage.haskell.org/package/word8")
    (synopsis "Word8 library for Haskell")
    (description "Word8 library to be used with @code{Data.ByteString}.")
    (license bsd-3)))

(define-public ghc-stringsearch
  (package
    (name "ghc-stringsearch")
    (version "0.3.6.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/stringsearch/stringsearch-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0jpy9xjcjdbpi3wk6mg7xwd7wfi2mma70p97v1ij5i8bj9qijpr9"))))
    (build-system haskell-build-system)
    (home-page "https://bitbucket.org/dafis/stringsearch")
    (synopsis "Fast searching, splitting and replacing of ByteStrings")
    (description "This package provides several functions to quickly search
for substrings in strict or lazy @code{ByteStrings}.  It also provides
functions for breaking or splitting on substrings and replacing all
occurrences of a substring (the first in case of overlaps) with another.")
    (license bsd-3)))

(define-public ghc-tasty-quickcheck
  (package
    (name "ghc-tasty-quickcheck")
    (version "0.8.4")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/tasty-quickcheck/"
             "tasty-quickcheck-" version ".tar.gz"))
       (sha256
        (base32
         "15rjxib5jmjq0hzj47x15kgp3awc73va4cy1pmpf7k3hvfv4qprn"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)))
    (inputs
     `(("ghc-tagged" ,ghc-tagged)
       ("ghc-tasty" ,ghc-tasty)
       ("ghc-random" ,ghc-random)
       ("ghc-ansi-terminal" ,ghc-ansi-terminal)
       ("ghc-tasty-hunit" ,ghc-tasty-hunit)
       ("ghc-pcre-light" ,ghc-pcre-light)))
    (home-page "http://documentup.com/feuerbach/tasty")
    (synopsis "QuickCheck support for the Tasty test framework")
    (description "This package provides QuickCheck support for the Tasty
Haskell test framework.")
    (license expat)))

(define-public ghc-tasty-golden
  (package
    (name "ghc-tasty-golden")
    (version "2.3.0.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/tasty-golden/tasty-golden-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0n7nll1sx75n3lffwhgnjrxdn0jz1g0921z9mj193fxqw0wz8axh"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-temporary" ,ghc-temporary)))
    (inputs
     `(("ghc-tasty" ,ghc-tasty)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-optparse-applicative" ,ghc-optparse-applicative)
       ("ghc-tagged" ,ghc-tagged)
       ("ghc-async" ,ghc-async)
       ("ghc-tasty-hunit" ,ghc-tasty-hunit)
       ("ghc-temporary-rc" ,ghc-temporary-rc)))
    (home-page
     "https://github.com/feuerbach/tasty-golden")
    (synopsis "Golden tests support for tasty")
    (description
     "This package provides support for 'golden testing'.  A golden test is an
IO action that writes its result to a file.  To pass the test, this output
file should be identical to the corresponding 'golden' file, which contains
the correct result for the test.")
    (license expat)))

(define-public ghc-tasty
  (package
    (name "ghc-tasty")
    (version "0.11.0.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/tasty/tasty-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1chapivmmwsb1ghwagvdm80bfj3hdk75m94z4p212ng2i4ghpjkx"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-stm" ,ghc-stm)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-tagged" ,ghc-tagged)
       ("ghc-regex-tdfa-rc" ,ghc-regex-tdfa-rc)
       ("ghc-optparse-applicative" ,ghc-optparse-applicative)
       ("ghc-unbounded-delays" ,ghc-unbounded-delays)
       ("ghc-async" ,ghc-async)
       ("ghc-ansi-terminal" ,ghc-ansi-terminal)
       ("ghc-clock-bootstrap" ,ghc-clock-bootstrap)))
    (home-page "http://documentup.com/feuerbach/tasty")
    (synopsis "Modern and extensible testing framework")
    (description "Tasty is a modern testing framework for Haskell.  It lets
you combine your unit tests, golden tests, QuickCheck/SmallCheck properties,
and any other types of tests into a single test suite.")
    (license expat)))

(define-public ghc-tasty-hunit
  (package
    (name "ghc-tasty-hunit")
    (version "0.9.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/tasty-hunit/tasty-hunit-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "08qnxaw34wfnzi9irs1jd4d0zczqm3k5ffkd4zwhkz0dflmgq7mf"))))
    (build-system haskell-build-system)
    (inputs
     `(("ghc-tasty" ,ghc-tasty)))
    (home-page "http://documentup.com/feuerbach/tasty")
    (synopsis "HUnit support for the Tasty test framework")
    (description "This package provides HUnit support for the Tasty Haskell
test framework.")
    (license expat)))

(define-public ghc-cookie
  (package
    (name "ghc-cookie")
    (version "0.4.1.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/cookie/cookie-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0b6ym6fn29p5az4dwydy036lxj131kagrmgb93w4bbkqfkds8b9s"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-old-locale" ,ghc-old-locale)))
    (inputs
     `(("ghc-blaze-builder" ,ghc-blaze-builder)
       ("ghc-text" ,ghc-text)
       ("ghc-data-default-class" ,ghc-data-default-class)
       ("ghc-hunit" ,ghc-hunit)
       ("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-tasty" ,ghc-tasty)
       ("ghc-tasty-hunit" ,ghc-tasty-hunit)
       ("ghc-tasty-quickcheck" ,ghc-tasty-quickcheck)))
    (home-page "http://github.com/snoyberg/cookie")
    (synopsis "HTTP cookie parsing and rendering")
    (description "HTTP cookie parsing and rendering library for Haskell.")
    (license bsd-3)))

(define-public ghc-scientific
  (package
    (name "ghc-scientific")
    (version "0.3.4.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/scientific/scientific-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "0mimdkva0cgzaychr6whv9if29z0r5wwhkss9bmd4rz8kq1kgngn"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-hashable" ,ghc-hashable)
       ("ghc-vector" ,ghc-vector)))
    (inputs
     `(("ghc-text" ,ghc-text)
       ("ghc-tasty" ,ghc-tasty)
       ("ghc-tasty-ant-xml" ,ghc-tasty-ant-xml)
       ("ghc-tasty-hunit" ,ghc-tasty-hunit)
       ("ghc-tasty-smallcheck" ,ghc-tasty-smallcheck)
       ("ghc-tasty-quickcheck" ,ghc-tasty-quickcheck)
       ("ghc-smallcheck" ,ghc-smallcheck)
       ("ghc-quickcheck" ,ghc-quickcheck)))
    (home-page "https://github.com/basvandijk/scientific")
    (synopsis "Numbers represented using scientific notation")
    (description "This package provides @code{Data.Scientific}, which provides
the number type @code{Scientific}.  Scientific numbers are arbitrary precision
and space efficient.  They are represented using
@uref{http://en.wikipedia.org/wiki/Scientific_notation, scientific
notation}.")
    (license bsd-3)))

(define-public ghc-aeson
  (package
    (name "ghc-aeson")
    (version "0.10.0.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/aeson/aeson-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "19kp33rfivr4d3myyr8xn803wd7p8x5nc4wb3qvlgjwgyqjaxvrz"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: testing libraries are missing.
    (propagated-inputs
     `(("ghc-attoparsec" ,ghc-attoparsec)
       ("ghc-dlist" ,ghc-dlist)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-scientific" ,ghc-scientific)
       ("ghc-syb" ,ghc-syb)
       ("ghc-vector" ,ghc-vector)))
    (inputs
     `(("ghc-hashable" ,ghc-hashable)
       ("ghc-text" ,ghc-text)
       ("ghc-unordered-containers" ,ghc-unordered-containers)
       ("ghc-hunit" ,ghc-hunit)
       ("ghc-quickcheck" ,ghc-quickcheck)))
    (home-page "https://github.com/bos/aeson")
    (synopsis "Fast JSON parsing and encoding")
    (description "This package provides a JSON parsing and encoding library
for Haskell, optimized for ease of use and high performance.  (A note on
naming: in Greek mythology, Aeson was the father of Jason.)")
    (license bsd-3)))

(define-public ghc-wai
  (package
    (name "ghc-wai")
    (version "3.0.4.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/wai/wai-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1551n0g0n22vml33v0jz5xgjcy6j79algvsdqg11a1z5ljjrjlqf"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-bytestring-builder" ,ghc-bytestring-builder)
       ("ghc-unix-compat" ,ghc-unix-compat)
       ("ghc-vault" ,ghc-vault)
       ("ghc-blaze-builder" ,ghc-blaze-builder)
       ("ghc-network" ,ghc-network)))
    (inputs
     `(("ghc-quickcheck" ,ghc-quickcheck)
       ("ghc-hunit" ,ghc-hunit)
       ("ghc-hspec" ,ghc-hspec)
       ("ghc-text" ,ghc-text)
       ("ghc-http-types" ,ghc-http-types)))
    (home-page "https://hackage.haskell.org/package/wai")
    (synopsis "Web application interface for Haskell")
    (description "This package provides a Web Application Interface (WAI)
library for the Haskell language.  It defines a common protocol for
communication between web applications and web servers.")
    (license bsd-3)))

(define-public ghc-wai-logger
  (package
    (name "ghc-wai-logger")
    (version "2.2.4.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/wai-logger/wai-logger-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1s6svvy3ci4j1dj1jaw8hg628miwj8f5gpy9n8d8hpsaxav6nzgk"))))
    (build-system haskell-build-system)
    (arguments `(#:tests? #f)) ; FIXME: Tests cannot find libraries exported
                               ; by propagated-inputs.
    (propagated-inputs
     `(("ghc-auto-update" ,ghc-auto-update)
       ("ghc-byteorder" ,ghc-byteorder)
       ("ghc-easy-file" ,ghc-easy-file)
       ("ghc-unix-time" ,ghc-unix-time)))
    (inputs
     `(("ghc-blaze-builder" ,ghc-blaze-builder)
       ("ghc-case-insensitive" ,ghc-case-insensitive)
       ("ghc-fast-logger" ,ghc-fast-logger)
       ("ghc-http-types" ,ghc-http-types)
       ("ghc-network" ,ghc-network)
       ("ghc-wai" ,ghc-wai)))
    (home-page "http://hackage.haskell.org/package/wai-logger")
    (synopsis "Logging system for WAI")
    (description "This package provides the logging system for WAI.")
    (license bsd-3)))

(define-public ghc-wai-extra
  (package
    (name "ghc-wai-extra")
    (version "3.0.11.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "http://hackage.haskell.org/package/wai-extra/wai-extra-"
             version
             ".tar.gz"))
       (sha256
        (base32
         "1kr2s5qyx1dvnwr372h7pca4sgxjv0pdx96xkgsfi180h3mb0vq8"))))
    (build-system haskell-build-system)
    (propagated-inputs
     `(("ghc-ansi-terminal" ,ghc-ansi-terminal)
       ("ghc-base64-bytestring" ,ghc-base64-bytestring)
       ("ghc-cookie" ,ghc-cookie)
       ("ghc-blaze-builder" ,ghc-blaze-builder)
       ("ghc-network" ,ghc-network)
       ("ghc-lifted-base" ,ghc-lifted-base)
       ("ghc-streaming-commons" ,ghc-streaming-commons)
       ("ghc-stringsearch" ,ghc-stringsearch)
       ("ghc-resourcet" ,ghc-resourcet)
       ("ghc-fast-logger" ,ghc-fast-logger)
       ("ghc-wai-logger" ,ghc-wai-logger)
       ("ghc-zlib" ,ghc-zlib)
       ("ghc-word8" ,ghc-word8)
       ("ghc-iproute" ,ghc-iproute)
       ("ghc-void" ,ghc-void)))
    (inputs
     `(("ghc-wai" ,ghc-wai)
       ("ghc-http-types" ,ghc-http-types)
       ("ghc-text" ,ghc-text)
       ("ghc-case-insensitive" ,ghc-case-insensitive)
       ("ghc-data-default-class" ,ghc-data-default-class)
       ("ghc-unix-compat" ,ghc-unix-compat)
       ("ghc-vault" ,ghc-vault)
       ("ghc-aeson" ,ghc-aeson)
       ("ghc-hspec" ,ghc-hspec)
       ("ghc-hunit" ,ghc-hunit)))
    (home-page "http://github.com/yesodweb/wai")
    (synopsis "Some basic WAI handlers and middleware")
    (description "This library provides basic WAI handlers and middleware
functionality.")
    (license expat)))

(define-public idris
  (package
    (name "idris")
    (version "0.9.19.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "https://hackage.haskell.org/package/idris-"
                           version "/idris-" version ".tar.gz"))
       (sha256
        (base32
         "10641svdsjlxbxmbvylpia04cz5nn9486lpiay8ibqcrc1792qgc"))
       (modules '((guix build utils)))
       (snippet
        '(substitute* "idris.cabal"
           ;; Package description file has a too-tight version restriction,
           ;; rendering it incompatible with GHC 7.10.2.  This is fixed
           ;; upstream.  See
           ;; <https://github.com/idris-lang/Idris-dev/issues/2734>.
           (("vector < 0.11") "vector < 0.12")))))
    (build-system haskell-build-system)
    (arguments
     `(#:phases (modify-phases %standard-phases
                  (add-before 'configure 'patch-cc-command
                              (lambda _
                                (setenv "CC" "gcc"))))))
    (inputs
     `(("gmp" ,gmp)
       ("ncurses" ,ncurses)
       ("ghc-annotated-wl-pprint" ,ghc-annotated-wl-pprint)
       ("ghc-ansi-terminal" ,ghc-ansi-terminal)
       ("ghc-ansi-wl-pprint" ,ghc-ansi-wl-pprint)
       ("ghc-base64-bytestring" ,ghc-base64-bytestring)
       ("ghc-blaze-html" ,ghc-blaze-html)
       ("ghc-blaze-markup" ,ghc-blaze-markup)
       ("ghc-cheapskate" ,ghc-cheapskate)
       ("ghc-fingertree" ,ghc-fingertree)
       ("ghc-mtl" ,ghc-mtl)
       ("ghc-network" ,ghc-network)
       ("ghc-optparse-applicative" ,ghc-optparse-applicative)
       ("ghc-parsers" ,ghc-parsers)
       ("ghc-safe" ,ghc-safe)
       ("ghc-split" ,ghc-split)
       ("ghc-text" ,ghc-text)
       ("ghc-trifecta" ,ghc-trifecta)
       ("ghc-uniplate" ,ghc-uniplate)
       ("ghc-unordered-containers" ,ghc-unordered-containers)
       ("ghc-utf8-string" ,ghc-utf8-string)
       ("ghc-vector-binary-instances" ,ghc-vector-binary-instances)
       ("ghc-vector" ,ghc-vector)
       ("ghc-zip-archive" ,ghc-zip-archive)
       ("ghc-zlib" ,ghc-zlib)))
    (home-page "http://www.idris-lang.org")
    (synopsis "General purpose language with full dependent types")
    (description "Idris is a general purpose language with full dependent
types.  It is compiled, with eager evaluation.  Dependent types allow types to
be predicated on values, meaning that some aspects of a program's behaviour
can be specified precisely in the type.  The language is closely related to
Epigram and Agda.")
    (license bsd-3)))

;;; haskell.scm ends here
