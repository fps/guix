;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2015 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2015 Mark H Weaver <mhw@netris.org>
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

(define-module (gnu packages samba)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system gnu)
  #:use-module (guix licenses)
  #:use-module (gnu packages acl)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages popt)
  #:use-module (gnu packages openldap)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages libunwind)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages python))

(define-public iniparser
  (package
    (name "iniparser")
    (version "3.1")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://ndevilla.free.fr/iniparser/iniparser-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "1igmxzcy0s25zcy9vmcw0kd13lh60r0b4qg8lnp1jic33f427pxf"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-replace
                 'configure
                 (lambda* (#:key outputs #:allow-other-keys)
                   (substitute* "Makefile"
                     (("/usr/lib")
                      (string-append (assoc-ref outputs "out") "/lib"))))
                 (alist-replace
                  'build
                  (lambda _
                    (and (zero? (system* "make" "libiniparser.so"))
                         (symlink "libiniparser.so.0" "libiniparser.so")))
                  (alist-replace
                   'install
                   (lambda* (#:key outputs #:allow-other-keys)
                     (let* ((out  (assoc-ref outputs "out"))
                            (lib  (string-append out "/lib"))
                            (inc  (string-append out "/include"))
                            (doc  (string-append out "/share/doc"))
                            (html (string-append doc "/html")))
                       (define (copy dir)
                         (lambda (file)
                           (copy-file file
                                      (string-append dir "/"
                                                     (basename file)))))
                       (mkdir-p lib)
                       (for-each (copy lib)
                                 (find-files "." "^lib.*\\.(so\\.|a)"))
                       (with-directory-excursion lib
                         (symlink "libiniparser.so.0" "libiniparser.so"))
                       (mkdir-p inc)
                       (for-each (copy inc)
                                 (find-files "src" "\\.h$"))
                       (mkdir-p html)
                       (for-each (copy html)
                                 (find-files "html" ".*"))
                       (for-each (copy doc)
                                 '("AUTHORS" "INSTALL" "LICENSE"
                                   "README"))))
                   %standard-phases)))))
    (home-page "http://ndevilla.free.fr/iniparser")
    (synopsis "Standalone ini file parsing library")
    (description
     "iniparser is a free stand-alone `ini' file parsing library (Windows
configuration files).  It is written in portable ANSI C and should compile
anywhere.")
    (license x11)))

(define-public samba
  (package
    (name "samba")
    (version "3.6.25")
    (source (origin
             (method url-fetch)
             (uri (string-append "https://www.samba.org/samba/ftp/stable/samba-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "0l9pz2m67vf398q3c2dwn8jwdxsjb20igncf4byhv6yq5dzqlb4g"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases (alist-cons-before
                 'configure 'chdir
                 (lambda _
                   (chdir "source3"))
                 (alist-cons-after
                  'strip 'add-lib-to-runpath
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let* ((out (assoc-ref outputs "out"))
                           (lib (string-append out "/lib")))
                      ;; Add LIB to the RUNPATH of all the executables and
                      ;; dynamic libraries.
                      (with-directory-excursion out
                        (for-each (cut augment-rpath <> lib)
                                  (append (find-files "bin" ".*")
                                          (find-files "sbin" ".*")
                                          (find-files "lib" ".*"))))))
                  %standard-phases))

       #:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (guix build rpath)
                  (srfi srfi-26))
       #:imported-modules (,@%gnu-build-system-modules
                           (guix build rpath))

       ;; This flag is required to allow for "make test".
       #:configure-flags '("--enable-socket-wrapper")

       #:test-target "test"

       ;; XXX: The test infrastructure attempts to set password with
       ;; smbpasswd, which fails with "smbpasswd -L can only be used by root."
       ;; So disable tests until there's a workaround.
       #:tests? #f))
    (inputs                                   ; TODO: Add missing dependencies
     `(;; ("cups" ,cups)
       ("acl" ,acl)
       ;; ("gamin" ,gamin)
       ("libunwind" ,libunwind)
       ("iniparser" ,iniparser)
       ("popt" ,popt)
       ("openldap" ,openldap)
       ("linux-pam" ,linux-pam)
       ("readline" ,readline)
       ("patchelf" ,patchelf)))                   ; for (guix build rpath)
    (native-inputs                                ; for the test suite
     `(("perl" ,perl)
       ("python" ,python-wrapper)))
    (home-page "http://www.samba.org/")
    (synopsis
     "The standard Windows interoperability suite of programs for GNU and Unix")
    (description
     "Since 1992, Samba has provided secure, stable and fast file and print
services for all clients using the SMB/CIFS protocol, such as all versions of
DOS and Windows, OS/2, GNU/Linux and many others.

Samba is an important component to seamlessly integrate Linux/Unix Servers and
Desktops into Active Directory environments using the winbind daemon.")
    (license gpl3+)))

(define-public talloc
  (package
    (name "talloc")
    (version "2.1.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://www.samba.org/ftp/talloc/talloc-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "13c365f7y8idjf2v1jxdjpkc3lxdmsxxfxjx1ymianm7zjiph393"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-replace
                 'configure
                 (lambda* (#:key outputs #:allow-other-keys)
                   ;; talloc uses a custom configuration script that runs a
                   ;; python script called 'waf'.
                   (setenv "CONFIG_SHELL" (which "sh"))
                   (let ((out (assoc-ref outputs "out")))
                     (zero? (system* "./configure"
                                     (string-append "--prefix=" out)))))
                 %standard-phases)))
    (inputs
     `(("python" ,python-2)))
    (home-page "http://talloc.samba.org")
    (synopsis "Hierarchical, reference counted memory pool system")
    (description
     "Talloc is a hierarchical, reference counted memory pool system with
destructors.  It is the core memory allocator used in Samba.")
    (license gpl3+))) ;; The bundled "replace" library uses LGPL3.

(define-public ppp
  (package
    (name "ppp")
    (version "2.4.7")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://www.samba.org/ftp/ppp/ppp-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0c7vrjxl52pdwi4ckrvfjr08b31lfpgwf3pp0cqy76a77vfs7q02"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ; no check target
       #:make-flags '("CC=gcc")
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-Makefile
           (lambda* (#:key inputs #:allow-other-keys)
             (let ((libc    (assoc-ref inputs "libc"))
                   (libpcap (assoc-ref inputs "libpcap")))
               (substitute* "pppd/Makefile.linux"
                 (("/usr/include/crypt\\.h")
                  (string-append libc "/include/crypt.h"))
                 (("/usr/include/pcap-bpf.h")
                  (string-append libpcap "/include/pcap-bpf.h")))))))))
    (inputs
     `(("libpcap" ,libpcap)))
    (synopsis "Implementation of the Point-to-Point Protocol")
    (home-page "https://ppp.samba.org/")
    (description
     "The Point-to-Point Protocol (PPP) provides a standard way to establish
a network connection over a serial link.  At present, this package supports IP
and IPV6 and the protocols layered above them, such as TCP and UDP.")
    ;; pppd, pppstats and pppdump are under BSD-style notices.
    ;; some of the pppd plugins are GPL'd.
    ;; chat is public domain.
    (license (list bsd-3 bsd-4 gpl2+ public-domain))))
