;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2014, 2015 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013, 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2015 Eric Bavier <bavier@member.fsf.org>
;;; Copyright © 2015 Sou Bunnbu <iyzsong@gmail.com>
;;; Copyright © 2015 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2015 Efraim Flashner <efraim@flashner.co.il>
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

(define-module (gnu packages xml)
  #:use-module (gnu packages)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages python)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages web)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system perl)
  #:use-module (guix build-system python)
  #:use-module (gnu packages linux))

(define-public expat
  (package
    (name "expat")
    (version "2.1.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://sourceforge/expat/expat/"
                                 version "/expat-" version ".tar.gz"))
             (sha256
              (base32
               "11pblz61zyxh68s5pdcbhc30ha1b2vfjd83aiwfg4vc15x3hadw2"))
             (patches (list (search-patch "expat-CVE-2015-1283.patch")))))
    (build-system gnu-build-system)
    (home-page "http://www.libexpat.org/")
    (synopsis "Stream-oriented XML parser library written in C")
    (description
     "Expat is an XML parser library written in C.  It is a
stream-oriented parser in which an application registers handlers for
things the parser might find in the XML document (like start tags).")
    (license license:expat)))

(define-public libxml2
  (package
    (name "libxml2")
    (version "2.9.2")
    (source (origin
             (method url-fetch)
             (uri (string-append "ftp://xmlsoft.org/libxml2/libxml2-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "1g6mf03xcabmk5ing1lwqmasr803616gb2xhn7pll10x2l5w6y2i"))
             (patches
              (map search-patch
                   '("libxml2-fix-catalog-corruption.patch"
                     "libxml2-bug-738805.patch"
                     "libxml2-id-attrs-in-xmlSetTreeDoc.patch"
                     "libxml2-CVE-2015-7941-pt1.patch"
                     "libxml2-CVE-2015-7941-pt2.patch"
                     "libxml2-node-sort-order-pt1.patch"
                     "libxml2-bug-747437.patch"
                     "libxml2-CVE-2015-1819.patch"
                     "libxml2-bug-751603.patch"
                     "libxml2-bug-751631.patch"
                     "libxml2-node-sort-order-pt2.patch"
                     "libxml2-bug-737840.patch"
                     "libxml2-bug-754946.patch"
                     "libxml2-bug-754947.patch"
                     "libxml2-bug-755857.patch"
                     "libxml2-CVE-2015-7942-pt1.patch"
                     "libxml2-CVE-2015-7942-pt2.patch"
                     "libxml2-bug-746048.patch"
                     "libxml2-CVE-2015-8035.patch")))))
    (build-system gnu-build-system)
    (home-page "http://www.xmlsoft.org/")
    (synopsis "C parser for XML")
    (propagated-inputs `(("zlib" ,zlib))) ; libxml2.la says '-lz'.
    (native-inputs `(("perl" ,perl)))
    ;; $XML_CATALOG_FILES lists 'catalog.xml' files found in under the 'xml'
    ;; sub-directory of any given package.
    (native-search-paths (list (search-path-specification
                                (variable "XML_CATALOG_FILES")
                                (separator " ")
                                (files '("xml"))
                                (file-pattern "^catalog\\.xml$")
                                (file-type 'regular))))
    (search-paths native-search-paths)
    (description
     "Libxml2 is the XML C parser and toolkit developed for the Gnome
project (but it is usable outside of the Gnome platform).")
    (license license:x11)))

(define-public python-libxml2
  (package (inherit libxml2)
    (name "python-libxml2")
    (build-system python-build-system)
    (arguments
     `(;; XXX: Tests are specified in 'Makefile.am', but not in 'setup.py'.
       #:tests? #f
       #:phases
       (modify-phases %standard-phases
         (add-before
          'build 'configure
          (lambda* (#:key inputs #:allow-other-keys)
            (chdir "python")
            (let ((glibc   (assoc-ref inputs ,(if (%current-target-system)
                                                  "cross-libc" "libc")))
                  (libxml2 (assoc-ref inputs "libxml2")))
              (substitute* "setup.py"
                ;; For 'libxml2/libxml/tree.h'.
                (("ROOT = r'/usr'")
                 (format #f "ROOT = r'~a'" libxml2))
                ;; For 'iconv.h'.
                (("/opt/include")
                 (string-append glibc "/include")))))))))
    (inputs `(("libxml2" ,libxml2)))
    (synopsis "Python bindings for the libxml2 library")))

(define-public python2-libxml2
  (package-with-python2 python-libxml2))

(define-public libxslt
  (package
    (name "libxslt")
    (version "1.1.28")
    (source (origin
             (method url-fetch)
             (uri (string-append "ftp://xmlsoft.org/libxslt/libxslt-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "13029baw9kkyjgr7q3jccw2mz38amq7mmpr5p3bh775qawd1bisz"))
             (patches (list (search-patch "libxslt-CVE-2015-7995.patch")))))
    (build-system gnu-build-system)
    (home-page "http://xmlsoft.org/XSLT/index.html")
    (synopsis "C library for applying XSLT stylesheets to XML documents")
    (inputs `(("libgcrypt" ,libgcrypt)
              ("libxml2" ,libxml2)
              ("python" ,python-minimal-wrapper)
              ("zlib" ,zlib)))
    (description
     "Libxslt is an XSLT C library developed for the GNOME project.  It is
based on libxml for XML parsing, tree manipulation and XPath support.")
    (license license:x11)))

(define-public perl-xml-parser
  (package
    (name "perl-xml-parser")
    (version "2.44")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://cpan/authors/id/T/TO/TODDR/XML-Parser-"
                   version ".tar.gz"))
             (sha256
              (base32
               "05ij0g6bfn27iaggxf8nl5rhlwx6f6p6xmdav6rjcly3x5zd1s8s"))))
    (build-system perl-build-system)
    (arguments `(#:make-maker-flags
                 (let ((expat (assoc-ref %build-inputs "expat")))
                   (list (string-append "EXPATLIBPATH=" expat "/lib")
                         (string-append "EXPATINCPATH=" expat "/include")))))
    (inputs `(("expat" ,expat)))
    (license (package-license perl))
    (synopsis "Perl bindings to the Expat XML parsing library")
    (description
     "This module provides ways to parse XML documents.  It is built on top of
XML::Parser::Expat, which is a lower level interface to James Clark's expat
library.  Each call to one of the parsing methods creates a new instance of
XML::Parser::Expat which is then used to parse the document.  Expat options
may be provided when the XML::Parser object is created.  These options are
then passed on to the Expat object on each parse call.  They can also be given
as extra arguments to the parse methods, in which case they override options
given at XML::Parser creation time.")
    (home-page "http://search.cpan.org/dist/XML-Parser")))

(define-public perl-libxml
  (package
    (name "perl-libxml")
    (version "0.08")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://cpan/authors/id/K/KM/KMACLEOD/libxml-perl-"
                   version ".tar.gz"))
             (sha256
              (base32
               "1jy9af0ljyzj7wakqli0437zb2vrbplqj4xhab7bfj2xgfdhawa5"))))
    (build-system perl-build-system)
    (propagated-inputs
     `(("perl-xml-parser" ,perl-xml-parser)))
    (license (package-license perl))
    (synopsis "Perl SAX parser using XML::Parser")
    (description
     "XML::Parser::PerlSAX is a PerlSAX parser using the XML::Parser
module.")
    (home-page "http://search.cpan.org/~kmacleod/libxml-perl/lib/XML/Parser/PerlSAX.pm")))

(define-public perl-xml-libxml
  (package
    (name "perl-xml-libxml")
    (version "2.0118")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://cpan/authors/id/S/SH/SHLOMIF/"
                           "XML-LibXML-" version ".tar.gz"))
       (sha256
        (base32
         "170c8dbk4p6jw9is0cria73021yp3hpmhb19p9j0zg2yxwkawr6c"))))
    (build-system perl-build-system)
    (propagated-inputs
     `(("perl-xml-namespacesupport" ,perl-xml-namespacesupport)
       ("perl-xml-sax" ,perl-xml-sax)))
    (inputs
     `(("libxml2" ,libxml2)))
    (home-page "http://search.cpan.org/dist/XML-LibXML")
    (synopsis "Perl interface to libxml2")
    (description "This module implements a Perl interface to the libxml2
library which provides interfaces for parsing and manipulating XML files. This
module allows Perl programmers to make use of the highly capable validating
XML parser and the high performance DOM implementation.")
    (license (package-license perl))))

(define-public perl-xml-namespacesupport
  (package
    (name "perl-xml-namespacesupport")
    (version "1.11")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://cpan/authors/id/P/PE/PERIGRIN/"
                           "XML-NamespaceSupport-" version ".tar.gz"))
       (sha256
        (base32
         "1sklgcldl3w6gn706vx1cgz6pm4y5lfgsjxnfqyk20pilgq530bd"))))
    (build-system perl-build-system)
    (home-page "http://search.cpan.org/dist/XML-NamespaceSupport")
    (synopsis "XML namespace support class")
    (description "This module offers a simple to process namespaced XML
names (unames) from within any application that may need them.  It also helps
maintain a prefix to namespace URI map, and provides a number of basic
checks.")
    (license (package-license perl))))

(define-public perl-xml-sax
  (package
    (name "perl-xml-sax")
    (version "0.99")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://cpan/authors/id/G/GR/GRANTM/"
                           "XML-SAX-" version ".tar.gz"))
       (sha256
        (base32
         "115dypb50w1l94y3iwihv5nkixbsv1cxiqkd93y4rk5n6s74pc1j"))))
    (build-system perl-build-system)
    (propagated-inputs
     `(("perl-xml-namespacesupport" ,perl-xml-namespacesupport)
       ("perl-xml-sax-base" ,perl-xml-sax-base)))
    (arguments
     `(#:phases (modify-phases %standard-phases
                  (add-before
                   'install 'augment-path
                   ;; The install target tries to load the newly-installed
                   ;; XML::SAX module, but can't find it, so we need to tell
                   ;; perl where to look.
                   (lambda* (#:key outputs #:allow-other-keys)
                     (setenv "PERL5LIB"
                             (string-append (getenv "PERL5LIB") ":"
                                            (assoc-ref outputs "out")
                                            "/lib/perl5/site_perl")))))))
    (home-page "http://search.cpan.org/dist/XML-SAX")
    (synopsis "Perl API for XML")
    (description "XML::SAX consists of several framework classes for using and
building Perl SAX2 XML parsers, filters, and drivers.")
    (license (package-license perl))))

(define-public perl-xml-sax-base
  (package
    (name "perl-xml-sax-base")
    (version "1.08")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://cpan/authors/id/G/GR/GRANTM/"
                           "XML-SAX-Base-" version ".tar.gz"))
       (sha256
        (base32
         "17i161rq1ngjlk0c8vdkrkkc56y1pf51k1g54y28py0micqp0qk6"))))
    (build-system perl-build-system)
    (home-page "http://search.cpan.org/dist/XML-SAX-Base")
    (synopsis "Base class for SAX Drivers and Filters")
    (description "This module has a very simple task - to be a base class for
PerlSAX drivers and filters.  It's default behaviour is to pass the input
directly to the output unchanged.  It can be useful to use this module as a
base class so you don't have to, for example, implement the characters()
callback.")
    (license (package-license perl))))

(define-public perl-xml-simple
  (package
    (name "perl-xml-simple")
    (version "2.20")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://cpan/authors/id/G/GR/GRANTM/XML-Simple-"
                   version ".tar.gz"))
             (sha256
              (base32
               "0jj3jiray1l4pi9wkjcpxjc3v431whdwx5aqnhgdm4i7h3817zsw"))))
    (build-system perl-build-system)
    (propagated-inputs
     `(("perl-xml-parser" ,perl-xml-parser)))
    (license (package-license perl))
    (synopsis "Perl module for easy reading/writing of XML files")
    (description
     "The XML::Simple module provides a simple API layer on top of an
underlying XML parsing module (either XML::Parser or one of the SAX2
parser modules).")
    (home-page "http://search.cpan.org/~grantm/XML-Simple-2.20/lib/XML/Simple.pm")))

(define-public perl-xml-regexp
  (package
    (name "perl-xml-regexp")
    (version "0.04")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://cpan/authors/id/T/TJ/TJMATHER/XML-RegExp-"
                   version ".tar.gz"))
             (sha256
              (base32
               "0m7wj00a2kik7wj0azhs1zagwazqh3hlz4255n75q21nc04r06fz"))))
    (build-system perl-build-system)
    (inputs
     `(("perl-xml-parser" ,perl-xml-parser)))
    (license (package-license perl))
    (synopsis "Perl regular expressions for XML tokens")
    (description
     "XML::RegExp contains regular expressions for the following XML tokens:
BaseChar, Ideographic, Letter, Digit, Extender, CombiningChar, NameChar,
EntityRef, CharRef, Reference, Name, NmToken, and AttValue.")
    (home-page "http://search.cpan.org/~tjmather/XML-RegExp/lib/XML/RegExp.pm")))

(define-public perl-xml-dom
  (package
    (name "perl-xml-dom")
    (version "1.44")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://cpan/authors/id/T/TJ/TJMATHER/XML-DOM-"
                   version ".tar.gz"))
             (sha256
              (base32
               "1r0ampc88ni3sjpzr583k86076qg399arfm9xirv3cw49k3k5bzn"))))
    (build-system perl-build-system)
    (propagated-inputs
     `(("perl-libwww" ,perl-libwww)
       ("perl-libxml" ,perl-libxml)
       ("perl-xml-regexp" ,perl-xml-regexp)))
    (license (package-license perl))
    (synopsis
     "Perl module for building DOM Level 1 compliant document structures")
    (description
     "This module extends the XML::Parser module by Clark Cooper.  The
XML::Parser module is built on top of XML::Parser::Expat, which is a lower
level interface to James Clark's expat library.  XML::DOM::Parser is derived
from XML::Parser.  It parses XML strings or files and builds a data structure
that conforms to the API of the Document Object Model.")
    (home-page "http://search.cpan.org/~tjmather/XML-DOM-1.44/lib/XML/DOM.pm")))

(define-public pugixml
  (package
    (name "pugixml")
    (version "1.6")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "https://github.com/zeux/pugixml/archive/v"
                          version ".tar.gz"))
      (file-name (string-append name "-" version ".tar.gz"))
      (sha256
       (base32
        "0czbcv9aqf2rw3s9cljz2wb1f4zbhd07wnj7ykklklccl0ipfnwi"))))
    (build-system cmake-build-system)
    (arguments
     `(#:tests? #f
       #:out-of-source? #f
       #:phases (modify-phases %standard-phases
                  (add-before
                   'configure 'chdir
                   (lambda _
                     (chdir "scripts")
                     #t)))))
    (home-page "http://pugixml.org")
    (synopsis "Light-weight, simple and fast XML parser for C++ with XPath support")
    (description
     "pugixml is a C++ XML processing library, which consists of a DOM-like
interface with rich traversal/modification capabilities, a fast XML parser
which constructs the DOM tree from an XML file/buffer, and an XPath 1.0
implementation for complex data-driven tree queries.  Full Unicode support is
also available, with Unicode interface variants and conversions between
different Unicode encodings which happen automatically during
parsing/saving.")
    (license license:expat)))

(define-public xmlto
  (package
    (name "xmlto")
    (version "0.0.28")
    (source
     (origin
      (method url-fetch)
      (uri (string-append
            "https://fedorahosted.org/releases/x/m/xmlto/xmlto-"
            version ".tar.bz2"))
      (sha256
       (base32
        "0xhj8b2pwp4vhl9y16v3dpxpsakkflfamr191mprzsspg4xdyc0i"))))
    (build-system gnu-build-system)
    (arguments
     ;; Make sure the reference to util-linux's 'getopt' is kept in 'xmlto'.
     '(#:configure-flags (list (string-append "GETOPT="
                                              (assoc-ref %build-inputs
                                                         "util-linux")
                                              "/bin/getopt"))))
    (inputs
     `(("util-linux" ,util-linux)                 ; for 'getopt'
       ("libxml2" ,libxml2)                       ; for 'xmllint'
       ("libxslt" ,libxslt)))                     ; for 'xsltproc'
    (home-page "http://cyberelk.net/tim/software/xmlto/")
    (synopsis "Front-end to an XSL toolchain")
    (description
     "Xmlto is a front-end to an XSL toolchain.  It chooses an appropriate
stylesheet for the conversion you want and applies it using an external
XSL-T processor.  It also performs any necessary post-processing.")
    (license license:gpl2+)))

(define-public xmlsec
  (package
    (name "xmlsec")
    (version "1.2.20")
    (source (origin
             (method url-fetch)
             (uri (string-append "https://www.aleksey.com/xmlsec/download/"
                                 name "1-" version ".tar.gz"))
             (sha256
              (base32
               "01bkbv2y3x8d1sf4dcln1x3y2jyj391s3208d9a2ndhglly5j89j"))))
    (build-system gnu-build-system)
    (propagated-inputs ; according to xmlsec1.pc
     `(("libxml2" ,libxml2)
       ("libxslt" ,libxslt)))
    (inputs
     `(("gnutls" ,gnutls)
       ("libgcrypt" ,libgcrypt)
       ("libltdl" ,libltdl)))
    (home-page "http://www.libexpat.org/")
    (synopsis "XML Security Library")
    (description
     "The XML Security Library is a C library based on Libxml2.  It
supports XML security standards such as XML Signature, XML Encryption,
Canonical XML (part of Libxml2) and Exclusive Canonical XML (part of
Libxml2).")
    (license (license:x11-style "file://COPYING"
                                "See 'COPYING' in the distribution."))))

(define-public minixml
  (package
    (name "minixml")
    (version "2.9")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://www.msweet.org/files/project3/mxml-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "14pzhlfidj5v1qbxy7a59yn4jz9pnjrs2zwalz228jsq7ijm9vfd"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f))  ;no "check" target
    (home-page "http://www.minixml.org/")
    (synopsis "Small XML parsing library")
    (description
     "Mini-XML is a small C library to read and write XML files and strings in
UTF-8 and UTF-16 encoding.")
    ;; LGPL 2.0+ with additional exceptions for static linking
    (license license:lgpl2.0+)))

;; TinyXML is an unmaintained piece of software, so the patches and build
;; system massaging have no upstream potential.
(define-public tinyxml
  (package
    (name "tinyxml")
    (version "2.6.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/tinyxml/tinyxml_"
                                  (string-join (string-split version #\.) "_")
                                  ".tar.gz"))
              (sha256
               (base32
                "14smciid19lvkxqznfig77jxn5s4iq3jpb47vh5a6zcaqp7gvg8m"))
              (patches (list (search-patch "tinyxml-use-stl.patch")))))
    (build-system gnu-build-system)
    ;; This library is missing *a lot* of the steps to make it usable, so we
    ;; have to add them here, like every other distro must do.
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (delete 'configure)
         (add-after 'build 'build-shared-library
           (lambda _
             (zero? (system* "g++" "-Wall" "-O2" "-shared" "-fpic"
                             "tinyxml.cpp" "tinyxmlerror.cpp"
                             "tinyxmlparser.cpp" "tinystr.cpp"
                             "-o" "libtinyxml.so"))))
         (replace 'check
           (lambda _ (zero? (system "./xmltest"))))
         (replace 'install
           (lambda* (#:key outputs #:allow-other-keys)
             (let* ((out (assoc-ref outputs "out"))
                    (include (string-append out "/include"))
                    (lib (string-append out "/lib"))
                    (pkgconfig (string-append out "/lib/pkgconfig"))
                    (doc (string-append out "/share/doc")))
               ;; Install libs and headers.
               (install-file "libtinyxml.so" lib)
               (install-file "tinystr.h" include)
               (install-file "tinyxml.h" include)
               ;; Generate and install pkg-config file.
               (mkdir-p pkgconfig)
               ;; Software such as Kodi expect this file to be present, but
               ;; it's not provided in the source code.
               (call-with-output-file (string-append pkgconfig "/tinyxml.pc")
                 (lambda (port)
                   (format port "prefix=~a
exec_prefix=${prefix}
libdir=${exec_prefix}/lib
includedir=${prefix}/include

Name: TinyXML
Description: A simple, small, C++ XML parser
Version: ~a
Libs: -L${libdir} -ltinyxml
Cflags: -I${includedir}
"
                           out ,version)))
               ;; Install docs.
               (mkdir-p doc)
               (copy-recursively "docs" (string-append doc "tinyxml"))
               #t))))))
    (synopsis "Small XML parser for C++")
    (description "TinyXML is a small and simple XML parsing library for the
C++ programming langauge.")
    (home-page "http://www.grinninglizard.com/tinyxml/index.html")
    (license license:zlib)))
