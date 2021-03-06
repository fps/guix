;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2012, 2013, 2014, 2015 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2013, 2014, 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2012 Nikita Karetnikov <nikita@karetnikov.org>
;;; Copyright © 2014, 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2015 Federico Beffa <beffa@fbengineering.ch>
;;; Copyright © 2015 Taylan Ulrich Bayırlı/Kammer <taylanbayirli@gmail.com>
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

(define-module (gnu packages linux)
  #:use-module ((guix licenses)
                #:hide (zlib))
  #:use-module (gnu packages)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages gcc)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pciutils)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages python)
  #:use-module (gnu packages slang)
  #:use-module (gnu packages algebra)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages attr)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages texinfo)
  #:use-module (gnu packages check)
  #:use-module (gnu packages maths)
  #:use-module (gnu packages base)
  #:use-module (gnu packages rrdtool)
  #:use-module (gnu packages elf)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages asciidoc)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages calendar)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system cmake)
  #:use-module (guix build-system python)
  #:use-module (guix build-system trivial)
  #:use-module (srfi srfi-26)
  #:use-module (ice-9 match))

(define-public (system->linux-architecture arch)
  "Return the Linux architecture name for ARCH, a Guix system name such as
\"x86_64-linux\"."
  (let ((arch (car (string-split arch #\-))))
    (cond ((string=? arch "i686") "i386")
          ((string-prefix? "mips" arch) "mips")
          ((string-prefix? "arm" arch) "arm")
          (else arch))))

(define (linux-libre-urls version)
  "Return a list of URLs for Linux-Libre VERSION."
  (list (string-append
         "http://linux-libre.fsfla.org/pub/linux-libre/releases/"
         version "-gnu/linux-libre-" version "-gnu.tar.xz")

        ;; XXX: Work around <http://bugs.gnu.org/14851>.
        (string-append
         "ftp://alpha.gnu.org/gnu/guix/mirror/linux-libre-"
         version "-gnu.tar.xz")

        ;; Maybe this URL will become valid eventually.
        (string-append
         "mirror://gnu/linux-libre/" version "-gnu/linux-libre-"
         version "-gnu.tar.xz")))

(define-public linux-libre-headers
  (let* ((version "3.14.37")
         (build-phase
          (lambda (arch)
            `(lambda _
               (setenv "ARCH" ,(system->linux-architecture arch))
               (format #t "`ARCH' set to `~a'~%" (getenv "ARCH"))

               (and (zero? (system* "make" "defconfig"))
                    (zero? (system* "make" "mrproper" "headers_check"))))))
         (install-phase
          `(lambda* (#:key outputs #:allow-other-keys)
             (let ((out (assoc-ref outputs "out")))
               (and (zero? (system* "make"
                                    (string-append "INSTALL_HDR_PATH=" out)
                                    "headers_install"))
                    (begin
                      (mkdir (string-append out "/include/config"))
                      (call-with-output-file
                          (string-append out
                                         "/include/config/kernel.release")
                        (lambda (p)
                          (format p "~a-default~%" ,version)))

                      ;; Remove the '.install' and '..install.cmd' files; the
                      ;; latter contains store paths, which pulls in bootstrap
                      ;; binaries in the build environment, and prevents bit
                      ;; reproducibility for the bootstrap binaries.
                      (for-each delete-file (find-files out "\\.install"))

                      #t))))))
   (package
    (name "linux-libre-headers")
    (version version)
    (source (origin
             (method url-fetch)
             (uri (linux-libre-urls version))
             (sha256
              (base32
               "1blxr2bsvfqi9khj4cpspv434bmx252zak2wsbi2mgl60zh77gza"))))
    (build-system gnu-build-system)
    (native-inputs `(("perl" ,perl)))
    (arguments
     `(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-1))
       #:phases (alist-replace
                 'build ,(build-phase (or (%current-target-system)
                                          (%current-system)))
                 (alist-replace
                  'install ,install-phase
                  (alist-delete 'configure %standard-phases)))
       #:allowed-references ()
       #:tests? #f))
    (synopsis "GNU Linux-Libre kernel headers")
    (description "Headers of the Linux-Libre kernel.")
    (license gpl2)
    (home-page "http://www.gnu.org/software/linux-libre/"))))

(define-public module-init-tools
  (package
    (name "module-init-tools")
    (version "3.16")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://kernel.org/linux/utils/kernel/module-init-tools/module-init-tools-"
                   version ".tar.bz2"))
             (sha256
              (base32
               "0jxnz9ahfic79rp93l5wxcbgh4pkv85mwnjlbv1gz3jawv5cvwp1"))
             (patches
              (list (search-patch "module-init-tools-moduledir.patch")))))
    (build-system gnu-build-system)
    (arguments
     ;; FIXME: The upstream tarball lacks man pages, and building them would
     ;; require DocBook & co.  We used to use Gentoo's pre-built man pages,
     ;; but they vanished.  In the meantime, fake it.
     '(#:phases (alist-cons-before
                 'configure 'fake-docbook
                 (lambda _
                   (substitute* "Makefile.in"
                     (("^DOCBOOKTOMAN.*$")
                      "DOCBOOKTOMAN = true\n")))
                 %standard-phases)))
    (home-page "http://www.kernel.org/pub/linux/utils/kernel/module-init-tools/")
    (synopsis "Tools for loading and managing Linux kernel modules")
    (description
     "Tools for loading and managing Linux kernel modules, such as `modprobe',
`insmod', `lsmod', and more.")
    (license gpl2+)))

(define %boot-logo-patch
  ;; Linux-Libre boot logo featuring Freedo and a gnu.
  (origin
    (method url-fetch)
    (uri (string-append "http://www.fsfla.org/svn/fsfla/software/linux-libre/"
                        "lemote/gnewsense/branches/3.16/100gnu+freedo.patch"))
    (sha256
     (base32
      "1hk9swxxc80bmn2zd2qr5ccrjrk28xkypwhl4z0qx4hbivj7qm06"))))

(define (kernel-config system)
  "Return the absolute file name of the Linux-Libre build configuration file
for SYSTEM, or #f if there is no configuration for SYSTEM."
  (define (lookup file)
    (let ((file (string-append "gnu/packages/" file)))
      (search-path %load-path file)))

  (match system
    ("i686-linux"
     (lookup "linux-libre-i686.conf"))
    ("x86_64-linux"
     (lookup "linux-libre-x86_64.conf"))
    (_
     #f)))

(define-public linux-libre
  (let* ((version "4.2.6")
         (build-phase
          '(lambda* (#:key system inputs #:allow-other-keys #:rest args)
             ;; Apply the neat patch.
             (system* "patch" "-p1" "--force"
                      "-i" (assoc-ref inputs "patch/freedo+gnu"))

             (let ((arch (car (string-split system #\-))))
               (setenv "ARCH"
                       (cond ((string=? arch "i686") "i386")
                             ((string=? arch "mips64el") "mips")
                             (else arch)))
               (format #t "`ARCH' set to `~a'~%" (getenv "ARCH")))

             (let ((build  (assoc-ref %standard-phases 'build))
                   (config (assoc-ref inputs "kconfig")))

               ;; Use the architecture-specific config if available, and
               ;; 'defconfig' otherwise.
               (if config
                   (begin
                     (copy-file config ".config")
                     (chmod ".config" #o666))
                   (system* "make" "defconfig"))

               ;; Appending works even when the option wasn't in the
               ;; file.  The last one prevails if duplicated.
               (let ((port (open-file ".config" "a")))
                 (display (string-append "CONFIG_NET_9P=m\n"
                                         "CONFIG_NET_9P_VIRTIO=m\n"
                                         "CONFIG_VIRTIO_BLK=m\n"
                                         "CONFIG_VIRTIO_NET=m\n"
                                         ;; https://lists.gnu.org/archive/html/guix-devel/2014-04/msg00039.html
                                         "CONFIG_DEVPTS_MULTIPLE_INSTANCES=y\n"
                                         "CONFIG_VIRTIO_PCI=m\n"
                                         "CONFIG_VIRTIO_BALLOON=m\n"
                                         "CONFIG_VIRTIO_MMIO=m\n"
                                         "CONFIG_FUSE_FS=m\n"
                                         "CONFIG_CIFS=m\n"
                                         "CONFIG_9P_FS=m\n")
                          port)
                 (close-port port))

               (zero? (system* "make" "oldconfig"))

               ;; Call the default `build' phase so `-j' is correctly
               ;; passed.
               (apply build #:make-flags "all" args))))
         (install-phase
          `(lambda* (#:key inputs outputs #:allow-other-keys)
             (let* ((out    (assoc-ref outputs "out"))
                    (moddir (string-append out "/lib/modules"))
                    (mit    (assoc-ref inputs "module-init-tools")))
               (mkdir-p moddir)
               (for-each (lambda (file)
                           (copy-file file
                                      (string-append out "/" (basename file))))
                         (find-files "." "^(bzImage|vmlinuz|System\\.map)$"))
               (copy-file ".config" (string-append out "/config"))
               (zero? (system* "make"
                               (string-append "DEPMOD=" mit "/sbin/depmod")
                               (string-append "MODULE_DIR=" moddir)
                               (string-append "INSTALL_PATH=" out)
                               (string-append "INSTALL_MOD_PATH=" out)
                               "INSTALL_MOD_STRIP=1"
                               "modules_install"))))))
   (package
    (name "linux-libre")
    (version version)
    (source (origin
             (method url-fetch)
             (uri (linux-libre-urls version))
             (sha256
              (base32
               "0phjk4dp0bk9s5mwawkxg3myl7fh244s833b33dc6m2y9clvzskl"))))
    (build-system gnu-build-system)
    (supported-systems '("x86_64-linux" "i686-linux"))
    (native-inputs `(("perl" ,perl)
                     ("bc" ,bc)
                     ("module-init-tools" ,module-init-tools)
                     ("patch/freedo+gnu" ,%boot-logo-patch)

                     ,@(let ((conf (kernel-config (or (%current-target-system)
                                                      (%current-system)))))
                         (if conf
                             `(("kconfig" ,conf))
                             '()))))
    (arguments
     `(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-1)
                  (ice-9 match))
       #:phases (alist-replace
                 'build ,build-phase
                 (alist-replace
                  'install ,install-phase
                  (alist-delete 'configure %standard-phases)))
       #:tests? #f))
    (synopsis "100% free redistribution of a cleaned Linux kernel")
    (description
     "GNU Linux-Libre is a free (as in freedom) variant of the Linux kernel.
It has been modified to remove all non-free binary blobs.")
    (license gpl2)
    (home-page "http://www.gnu.org/software/linux-libre/"))))


;;;
;;; Pluggable authentication modules (PAM).
;;;

(define-public linux-pam
  (package
    (name "linux-pam")
    (version "1.2.1")
    (source
     (origin
      (method url-fetch)
      (uri (list (string-append "http://www.linux-pam.org/library/Linux-PAM-"
                                version ".tar.bz2")
                 (string-append "mirror://kernel.org/linux/libs/pam/library/Linux-PAM-"
                                version ".tar.bz2")))
      (sha256
       (base32
        "1n9lnf9gjs72kbj1g354v1xhi2j27aqaah15vykh7cnkq08i4arl"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("flex" ,flex)

       ;; TODO: optional dependencies
       ;; ("libxcrypt" ,libxcrypt)
       ;; ("cracklib" ,cracklib)
       ))
    (arguments
     '(;; Most users, such as `shadow', expect the headers to be under
       ;; `security'.
       #:configure-flags (list (string-append "--includedir="
                                              (assoc-ref %outputs "out")
                                              "/include/security"))

       ;; XXX: Tests won't run in chroot, presumably because /etc/pam.d
       ;; isn't available.
       #:tests? #f))
    (home-page "http://www.linux-pam.org/")
    (synopsis "Pluggable authentication modules for Linux")
    (description
     "A *Free* project to implement OSF's RFC 86.0.
Pluggable authentication modules are small shared object files that can
be used through the PAM API to perform tasks, like authenticating a user
at login.  Local and dynamic reconfiguration are its key features.")
    (license bsd-3)))


;;;
;;; Miscellaneous.
;;;

(define-public psmisc
  (package
    (name "psmisc")
    (version "22.20")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://sourceforge/psmisc/psmisc/psmisc-"
                          version ".tar.gz"))
      (sha256
       (base32
        "052mfraykmxnavpi8s78aljx8w87hyvpx8mvzsgpjsjz73i28wmi"))))
    (build-system gnu-build-system)
    (inputs `(("ncurses" ,ncurses)))
    (home-page "http://psmisc.sourceforge.net/")
    (synopsis
     "Small utilities that use the proc filesystem")
    (description
     "This PSmisc package is a set of some small useful utilities that
use the proc filesystem.  We're not about changing the world, but
providing the system administrator with some help in common tasks.")
    (license gpl2+)))

(define-public util-linux
  (package
    (name "util-linux")
    (version "2.27")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kernel.org/linux/utils/"
                                  name "/v" (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1ivdx1bhjbakf77agm9dn3wyxia1wgz9lzxgd61zqxw3xzih9gzw"))
              (patches (list (search-patch "util-linux-tests.patch")))
              (modules '((guix build utils)))
              (snippet
               ;; We take the 'logger' program from GNU Inetutils and 'kill'
               ;; from GNU Coreutils.
               '(begin
                  (substitute* "configure"
                    (("build_logger=yes") "build_logger=no")
                    (("build_kill=yes") "build_kill=no"))
                  #t))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags (list "--disable-use-tty-group"

                               ;; Install completions where our
                               ;; bash-completion package expects them.
                               (string-append "--with-bashcompletiondir="
                                              (assoc-ref %outputs "out")
                                              "/etc/bash_completion.d"))
       #:phases (modify-phases %standard-phases
                  (add-before
                   'build 'set-umount-file-name
                   (lambda* (#:key outputs #:allow-other-keys)
                     ;; Tell 'eject' the right file name of 'umount'.
                     (let ((out (assoc-ref outputs "out")))
                       (substitute* "sys-utils/eject.c"
                         (("\"/bin/umount\"")
                          (string-append "\"" out "/bin/umount\"")))
                       #t)))
                  (add-before
                   'check 'pre-check
                   (lambda* (#:key inputs outputs #:allow-other-keys)
                     (let ((out (assoc-ref outputs "out"))
                           (net (assoc-ref inputs "net-base")))
                       ;; Change the test to refer to the right file.
                       (substitute* "tests/ts/misc/mcookie"
                         (("/etc/services")
                          (string-append net "/etc/services")))
                       #t))))))
    (inputs `(("zlib" ,zlib)
              ("ncurses" ,ncurses)))
    (native-inputs
     `(("perl" ,perl)
       ("net-base" ,net-base)))                   ;for tests
    (home-page "https://www.kernel.org/pub/linux/utils/util-linux/")
    (synopsis "Collection of utilities for the Linux kernel")
    (description
     "Util-linux is a random collection of utilities for the Linux kernel.")

    ;; Note that util-linux doesn't use the same license for all the
    ;; code.  GPLv2+ is the default license for a code without an
    ;; explicitly defined license.
    (license (list gpl3+ gpl2+ gpl2 lgpl2.0+
                   bsd-4 public-domain))))

(define-public procps
  (package
    (name "procps")
    (version "3.2.8")
    (source (origin
             (method url-fetch)
             ;; A mirror://sourceforge URI doesn't work, presumably becuase
             ;; the SourceForge project is misconfigured.
             (uri (string-append "http://procps.sourceforge.net/procps-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "0d8mki0q4yamnkk4533kx8mc0jd879573srxhg6r2fs3lkc6iv8i"))
             (patches (list (search-patch "procps-make-3.82.patch")))))
    (build-system gnu-build-system)
    (inputs `(("ncurses" ,ncurses)))
    (arguments
     '(#:modules ((guix build utils)
                  (guix build gnu-build-system)
                  (srfi srfi-1)
                  (srfi srfi-26))
       #:phases (alist-replace
                 'configure
                 (lambda* (#:key outputs #:allow-other-keys)
                   ;; No `configure', just a single Makefile.
                   (let ((out (assoc-ref outputs "out")))
                     (substitute* "Makefile"
                       (("/usr/") "/")
                       (("--(owner|group) 0") "")
                       (("ldconfig") "true")
                       (("^LDFLAGS[[:blank:]]*:=(.*)$" _ value)
                        ;; Add libproc to the RPATH.
                        (string-append "LDFLAGS := -Wl,-rpath="
                                       out "/lib" value))))
                   (setenv "CC" "gcc"))
                 (alist-replace
                  'install
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let ((out (assoc-ref outputs "out")))
                      (and (zero?
                            (system* "make" "install"
                                     (string-append "DESTDIR=" out)))

                           ;; Remove commands and man pages redundant with
                           ;; Coreutils.
                           (let ((dup (append-map (cut find-files out <>)
                                                  '("^kill" "^uptime"))))
                             (for-each delete-file dup)
                             #t)

                           ;; Sanity check.
                           (zero?
                            (system* (string-append out "/bin/ps")
                                     "--version")))))
                  %standard-phases))

       ;; What did you expect?  Tests?
       #:tests? #f))
    (home-page "http://procps.sourceforge.net/")
    (synopsis "Utilities that give information about processes")
    (description
     "Procps is the package that has a bunch of small useful utilities
that give information about processes using the Linux /proc file system.
The package includes the programs ps, top, vmstat, w, kill, free,
slabtop, and skill.")
    (license gpl2)))

(define-public usbutils
  (package
    (name "usbutils")
    (version "006")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://kernel.org/linux/utils/usb/usbutils/"
                          "usbutils-" version ".tar.xz"))
      (sha256
       (base32
        "03pd57vv8c6x0hgjqcbrxnzi14h8hcghmapg89p8k5zpwpkvbdfr"))))
    (build-system gnu-build-system)
    (inputs
     `(("libusb" ,libusb)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "http://www.linux-usb.org/")
    (synopsis
     "Tools for working with USB devices, such as lsusb")
    (description
     "Tools for working with USB devices, such as lsusb.")
    (license gpl2+)))

(define-public e2fsprogs
  (package
    (name "e2fsprogs")
    (version "1.42.13")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://kernel.org/linux/kernel/people/tytso/"
                   name "/v" version "/"
                   name "-" version ".tar.xz"))
             (sha256
              (base32
               "1ix0b83zgw5n0p2grh2961c6796m92yr2jqc2sbr23x3lfsp8r71"))
             (modules '((guix build utils)))
             (snippet
              '(substitute* "MCONFIG.in"
                 (("INSTALL_SYMLINK = /bin/sh")
                  "INSTALL_SYMLINK = sh")))))
    (build-system gnu-build-system)
    (inputs `(("util-linux" ,util-linux)))
    (native-inputs `(("pkg-config" ,pkg-config)
                     ("texinfo" ,texinfo)))     ;for the libext2fs Info manual
    (arguments
     '(;; util-linux is not the preferred source for some of the libraries and
       ;; commands, so disable them (see, e.g.,
       ;; <http://git.buildroot.net/buildroot/commit/?id=e1ffc2f791b33633>.)
       #:configure-flags '("--disable-libblkid"
                           "--disable-libuuid" "--disable-uuidd"
                           "--disable-fsck"

                           ;; Install libext2fs et al.
                           "--enable-elf-shlibs")

       #:make-flags (list (string-append "LDFLAGS=-Wl,-rpath="
                                         (assoc-ref %outputs "out")
                                         "/lib"))

       #:phases (alist-cons-before
                 'configure 'patch-shells
                 (lambda _
                   (substitute* "configure"
                     (("/bin/sh (.*)parse-types.sh" _ dir)
                      (string-append (which "sh") " " dir
                                     "parse-types.sh")))
                   (substitute* (find-files "." "^Makefile.in$")
                     (("#!/bin/sh")
                      (string-append "#!" (which "sh")))))
                 (alist-cons-after
                  'install 'install-libs
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let* ((out (assoc-ref outputs "out"))
                           (lib (string-append out "/lib")))
                      (and (zero? (system* "make" "install-libs"))

                           ;; Make the .a writable so that 'strip' works.
                           ;; Failing to do that, due to debug symbols, we
                           ;; retain a reference to the final
                           ;; linux-libre-headers, which refer to the
                           ;; bootstrap binaries.
                           (let ((archives (find-files lib "\\.a$")))
                             (for-each (lambda (file)
                                         (chmod file #o666))
                                       archives)
                             #t))))
                  %standard-phases))

       ;; FIXME: Tests work by comparing the stdout/stderr of programs, that
       ;; they fail because we get an extra line that says "Can't check if
       ;; filesystem is mounted due to missing mtab file".
       #:tests? #f))
    (home-page "http://e2fsprogs.sourceforge.net/")
    (synopsis "Creating and checking ext2/ext3/ext4 file systems")
    (description
     "This package provides tools for manipulating ext2/ext3/ext4 file systems.")
    (license (list gpl2                           ; programs
                   lgpl2.0                        ; libext2fs
                   x11))))                        ; libuuid

(define e2fsprogs/static
  (static-package
   (package (inherit e2fsprogs)
            (arguments
             ;; Do not build shared libraries.
             (substitute-keyword-arguments (package-arguments e2fsprogs)
               ((#:configure-flags _)
                '(list "--disable-blkid"))
               ((#:make-flags _)
                '(list)))))))

(define-public e2fsck/static
  (package
    (name "e2fsck-static")
    (version (package-version e2fsprogs))
    (build-system trivial-build-system)
    (source #f)
    (arguments
     `(#:modules ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils)
                      (ice-9 ftw)
                      (srfi srfi-26))

         (let ((source (string-append (assoc-ref %build-inputs "e2fsprogs")
                                      "/sbin"))
               (bin    (string-append (assoc-ref %outputs "out") "/sbin")))
           (mkdir-p bin)
           (with-directory-excursion bin
             (for-each (lambda (file)
                         (copy-file (string-append source "/" file)
                                    file)
                         (remove-store-references file)
                         (chmod file #o555))
                       (scandir source (cut string-prefix? "fsck." <>))))))))
    (inputs `(("e2fsprogs" ,e2fsprogs/static)))
    (synopsis "Statically-linked fsck.* commands from e2fsprogs")
    (description
     "This package provides statically-linked command of fsck.ext[234] taken
from the e2fsprogs package.  It is meant to be used in initrds.")
    (home-page (package-home-page e2fsprogs))
    (license (package-license e2fsprogs))))

(define-public extundelete
  (package
    (name "extundelete")
    (version "0.2.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/extundelete/"
                                  version "/extundelete-" version ".tar.bz2"))
              (sha256
               (base32
                "1x0r7ylxlp9lbj3d7sqf6j2a222dwy2nfpff05jd6mkh4ihxvyd1"))))
    (build-system gnu-build-system)
    (inputs `(("e2fsprogs" ,e2fsprogs)))
    (home-page "http://extundelete.sourceforge.net/")
    (synopsis "Recover deleted files from ext2/3/4 partitions")
    (description
     "Extundelete is a set of tools that can recover deleted files from an
ext3 or ext4 partition.")
    (license gpl2)))

(define-public zerofree
  (package
    (name "zerofree")
    (version "1.0.3")
    (home-page "http://intgat.tigress.co.uk/rmy/uml/")
    (source (origin
              (method url-fetch)
              (uri (string-append home-page name "-" version
                                  ".tgz"))
              (sha256
               (base32
                "1xncw3dn2cp922ly42m96p6fh7jv8ysg6bwqbk5xvw701f3dmkrs"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-replace
                 'install
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let* ((out (assoc-ref outputs "out"))
                          (bin (string-append out "/bin")))
                     (mkdir-p bin)
                     (copy-file "zerofree"
                                (string-append bin "/zerofree"))
                     (chmod (string-append bin "/zerofree")
                            #o555)
                     #t))
                 (alist-delete 'configure %standard-phases))
       #:tests? #f))                              ;no tests
    (inputs `(("libext2fs" ,e2fsprogs)))
    (synopsis "Zero non-allocated regions in ext2/ext3/ext4 file systems")
    (description
     "The zerofree command scans the free blocks in an ext2 file system and
fills any non-zero blocks with zeroes.  This is a useful way to make disk
images more compressible.")
    (license gpl2)))

(define-public strace
  (package
    (name "strace")
    (version "4.7")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://sourceforge/strace/strace-"
                                 version ".tar.xz"))
             (sha256
              (base32
               "158iwk0pl2mfw93m1843xb7a2zb8p6lh0qim07rca6f1ff4dk764"))))
    (build-system gnu-build-system)
    (native-inputs `(("perl" ,perl)))
    (home-page "http://strace.sourceforge.net/")
    (synopsis "System call tracer for Linux")
    (description
     "strace is a system call tracer, i.e. a debugging tool which prints out a
trace of all the system calls made by a another process/program.")
    (license bsd-3)))

(define-public ltrace
  (package
    (name "ltrace")
    (version "0.7.3")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://www.ltrace.org/ltrace_" version
                                 ".orig.tar.bz2"))
             (sha256
              (base32
               "00wmbdghqbz6x95m1mcdd3wd46l6hgcr4wggdp049dbifh3qqvqf"))))
    (build-system gnu-build-system)
    (inputs `(("libelf" ,libelf)))
    (arguments
     ;; Compilation uses -Werror by default, but it fails.
     '(#:configure-flags '("--disable-werror")))
    (home-page "http://www.ltrace.org/")
    (synopsis "Library call tracer for Linux")
    (description
     "ltrace intercepts and records dynamic library calls which are called by
an executed process and the signals received by that process.  It can also
intercept and print the system calls executed by the program.")
    (license gpl2+)))

(define-public alsa-lib
  (package
    (name "alsa-lib")
    (version "1.0.27.1")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "ftp://ftp.alsa-project.org/pub/lib/alsa-lib-"
                   version ".tar.bz2"))
             (sha256
              (base32
               "0fx057746dj7rjdi0jnvx2m9b0y1lgdkh1hks87d8w32xyihf3k9"))
             (patches (list (search-patch "alsa-lib-mips-atomic-fix.patch")))))
    (build-system gnu-build-system)
    (home-page "http://www.alsa-project.org/")
    (synopsis "The Advanced Linux Sound Architecture libraries")
    (description
     "The Advanced Linux Sound Architecture (ALSA) provides audio and
MIDI functionality to the Linux-based operating system.")
    (license lgpl2.1+)))

(define-public alsa-utils
  (package
    (name "alsa-utils")
    (version "1.0.27.2")
    (source (origin
             (method url-fetch)
             (uri (string-append "ftp://ftp.alsa-project.org/pub/utils/alsa-utils-"
                                 version ".tar.bz2"))
             (sha256
              (base32
               "1sjjngnq50jv5ilwsb4zys6smifni3bd6fn28gbnhfrg14wsrgq2"))))
    (build-system gnu-build-system)
    (arguments
     ;; XXX: Disable man page creation until we have DocBook.
     '(#:configure-flags (list "--disable-xmlto"

                               ;; The udev rule is responsible for restoring
                               ;; the volume.
                               (string-append "--with-udev-rules-dir="
                                              (assoc-ref %outputs "out")
                                              "/lib/udev/rules.d"))
       #:phases (alist-cons-before
                 'install 'pre-install
                 (lambda _
                   ;; Don't try to mkdir /var/lib/alsa.
                   (substitute* "Makefile"
                     (("\\$\\(MKDIR_P\\) .*ASOUND_STATE_DIR.*")
                      "true\n")))
                 %standard-phases)))
    (inputs
     `(("libsamplerate" ,libsamplerate)
       ("ncurses" ,ncurses)
       ("alsa-lib" ,alsa-lib)
       ("xmlto" ,xmlto)
       ("gettext" ,gnu-gettext)))
    (home-page "http://www.alsa-project.org/")
    (synopsis "Utilities for the Advanced Linux Sound Architecture (ALSA)")
    (description
     "The Advanced Linux Sound Architecture (ALSA) provides audio and
MIDI functionality to the Linux-based operating system.")

    ;; This is mostly GPLv2+ but a few files such as 'alsactl.c' are
    ;; GPLv2-only.
    (license gpl2)))

(define-public iptables
  (package
    (name "iptables")
    (version "1.4.16.2")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "http://www.netfilter.org/projects/iptables/files/iptables-"
                   version ".tar.bz2"))
             (sha256
              (base32
               "0vkg5lzkn4l3i1sm6v3x96zzvnv9g7mi0qgj6279ld383mzcws24"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f       ; no test suite
       #:configure-flags ; add $libdir to the RUNPATH of executables
       (list (string-append "LDFLAGS=-Wl,-rpath=" %output "/lib"))))
    (home-page "http://www.netfilter.org/projects/iptables/index.html")
    (synopsis "Program to configure the Linux IP packet filtering rules")
    (description
     "iptables is the userspace command line program used to configure the
Linux 2.4.x and later IPv4 packet filtering ruleset.  It is targeted towards
system administrators.  Since Network Address Translation is also configured
from the packet filter ruleset, iptables is used for this, too.  The iptables
package also includes ip6tables.  ip6tables is used for configuring the IPv6
packet filter.")
    (license gpl2+)))

(define-public iproute
  (package
    (name "iproute2")
    (version "3.12.0")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://kernel.org/linux/utils/net/iproute2/iproute2-"
                   version ".tar.xz"))
             (sha256
              (base32
               "04gi11gh087bg2nlxhj0lxrk8l9qxkpr88nsiil23917bm3h1xj4"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f                                ; no test suite
       #:make-flags (let ((out (assoc-ref %outputs "out")))
                      (list "DESTDIR="
                            (string-append "LIBDIR=" out "/lib")
                            (string-append "SBINDIR=" out "/sbin")
                            (string-append "CONFDIR=" out "/etc")
                            (string-append "DOCDIR=" out "/share/doc/"
                                           ,name "-" ,version)
                            (string-append "MANDIR=" out "/share/man")))
       #:phases (alist-cons-before
                 'install 'pre-install
                 (lambda _
                   ;; Don't attempt to create /var/lib/arpd.
                   (substitute* "Makefile"
                     (("^.*ARPDDIR.*$") "")))
                 %standard-phases)))
    (inputs
     `(("iptables" ,iptables)
       ("db4" ,bdb)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("flex" ,flex)
       ("bison" ,bison)))
    (home-page
     "http://www.linuxfoundation.org/collaborate/workgroups/networking/iproute2")
    (synopsis
     "Utilities for controlling TCP/IP networking and traffic in Linux")
    (description
     "Iproute2 is a collection of utilities for controlling TCP/IP
networking and traffic with the Linux kernel.

Most network configuration manuals still refer to ifconfig and route as the
primary network configuration tools, but ifconfig is known to behave
inadequately in modern network environments.  They should be deprecated, but
most distros still include them.  Most network configuration systems make use
of ifconfig and thus provide a limited feature set.  The /etc/net project aims
to support most modern network technologies, as it doesn't use ifconfig and
allows a system administrator to make use of all iproute2 features, including
traffic control.

iproute2 is usually shipped in a package called iproute or iproute2 and
consists of several tools, of which the most important are ip and tc.  ip
controls IPv4 and IPv6 configuration and tc stands for traffic control.  Both
tools print detailed usage messages and are accompanied by a set of
manpages.")
    (license gpl2+)))

(define-public net-tools
  ;; XXX: This package is basically unmaintained, but it provides a few
  ;; commands not yet provided by Inetutils, such as 'route', so we have to
  ;; live with it.
  (package
    (name "net-tools")
    (version "1.60")
    (home-page "http://www.tazenda.demon.co.uk/phil/net-tools/")
    (source (origin
             (method url-fetch)
             (uri (string-append home-page "/" name "-"
                                 version ".tar.bz2"))
             (sha256
              (base32
               "0yvxrzk0mzmspr7sa34hm1anw6sif39gyn85w4c5ywfn8inxvr3s"))
             (patches
              (list (search-patch "net-tools-bitrot.patch")))))
    (build-system gnu-build-system)
    (arguments
     '(#:modules ((guix build gnu-build-system)
                  (guix build utils)
                  (srfi srfi-1)
                  (srfi srfi-26))
       #:phases (alist-cons-after
                 'unpack 'patch
                 (lambda* (#:key inputs #:allow-other-keys)
                   (define (apply-patch file)
                     (zero? (system* "patch" "-p1" "--force"
                                     "--input" file)))

                   (let ((patch.gz (assoc-ref inputs "patch")))
                     (format #t "applying Debian patch set '~a'...~%"
                             patch.gz)
                     (system (string-append "gunzip < " patch.gz " > the-patch"))
                     (and (apply-patch "the-patch")
                          (for-each apply-patch
                                    (find-files "debian/patches"
                                                "\\.patch")))))
                 (alist-replace
                  'configure
                  (lambda* (#:key outputs #:allow-other-keys)
                    (let ((out (assoc-ref outputs "out")))
                      (mkdir-p (string-append out "/bin"))
                      (mkdir-p (string-append out "/sbin"))

                      ;; Pretend we have everything...
                      (system "yes | make config")

                      ;; ... except for the things we don't have.
                      ;; HAVE_AFDECnet requires libdnet, which we don't have.
                      ;; HAVE_HWSTRIP and HAVE_HWTR require kernel headers
                      ;; that have been removed.
                      (substitute* '("config.make" "config.h")
                        (("^.*HAVE_(AFDECnet|HWSTRIP|HWTR)[ =]1.*$") ""))))
                  (alist-cons-after
                   'install 'remove-redundant-commands
                   (lambda* (#:key outputs #:allow-other-keys)
                     ;; Remove commands and man pages redundant with
                     ;; Inetutils.
                     (let* ((out (assoc-ref outputs "out"))
                            (dup (append-map (cut find-files out <>)
                                             '("^hostname"
                                               "^(yp|nis|dns)?domainname"))))
                       (for-each delete-file dup)
                       #t))
                   %standard-phases)))

       ;; Binaries that depend on libnet-tools.a don't declare that
       ;; dependency, making it parallel-unsafe.
       #:parallel-build? #f

       #:tests? #f                                ; no test suite
       #:make-flags (let ((out (assoc-ref %outputs "out")))
                      (list "CC=gcc"
                            (string-append "BASEDIR=" out)
                            (string-append "INSTALLNLSDIR=" out "/share/locale")
                            (string-append "mandir=/share/man")))))

    ;; Use the big Debian patch set (the thing does not even compile out of
    ;; the box.)
    (inputs `(("patch" ,(origin
                         (method url-fetch)
                         (uri
                          "http://ftp.de.debian.org/debian/pool/main/n/net-tools/net-tools_1.60-24.2.diff.gz")
                         (sha256
                          (base32
                           "0p93lsqx23v5fv4hpbrydmfvw1ha2rgqpn2zqbs2jhxkzhjc030p"))))))
    (native-inputs `(("gettext" ,gnu-gettext)))

    (synopsis "Tools for controlling the network subsystem in Linux")
    (description
     "This package includes the important tools for controlling the network
subsystem of the Linux kernel.  This includes arp, hostname, ifconfig,
netstat, rarp and route.  Additionally, this package contains utilities
relating to particular network hardware types (plipconfig, slattach) and
advanced aspects of IP configuration (iptunnel, ipmaddr).")
    (license gpl2+)))

(define-public libcap
  (package
    (name "libcap")
    (version "2.24")
    (source (origin
             (method url-fetch)
             (uri (string-append
                   "mirror://kernel.org/linux/libs/security/linux-privs/"
                   "libcap2/libcap-" version ".tar.xz"))
             (sha256
              (base32
               "0rbc9qbqs5bp9am9s9g83wxj5k4ixps2agy9dxr1v1fwg27mdr6f"))))
    (build-system gnu-build-system)
    (arguments '(#:phases
                 (modify-phases %standard-phases
                   (replace 'configure
                            ;; Add $libdir to the RUNPATH of executables.
                            (lambda _
                              (substitute* "Make.Rules"
                                (("LDFLAGS := #-g")
                                 (string-append "LDFLAGS := -Wl,-rpath="
                                                %output "/lib"))))))
                 #:tests? #f                      ; no 'check' target
                 #:make-flags (list "lib=lib"
                                    (string-append "prefix="
                                                   (assoc-ref %outputs "out"))
                                    "RAISE_SETFCAP=no")))
    (native-inputs `(("perl" ,perl)))
    (inputs `(("attr" ,attr)))
    (home-page "https://sites.google.com/site/fullycapable/")
    (synopsis "Library for working with POSIX capabilities")
    (description
     "Libcap2 provides a programming interface to POSIX capabilities on
Linux-based operating systems.")

    ;; License is BSD-3 or GPLv2, at the user's choice.
    (license gpl2)))

(define-public bridge-utils
  (package
    (name "bridge-utils")
    (version "1.5")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://sourceforge/bridge/bridge-utils-"
                                 version ".tar.gz"))
             (sha256
              (base32
               "12367cwqmi0yqphi6j8rkx97q8hw52yq2fx4k0xfclkcizxybya2"))))
    (build-system gnu-build-system)

    ;; The tarball lacks all the generated files.
    (native-inputs `(("autoconf" ,autoconf)
                     ("automake" ,automake)))
    (arguments
     '(#:phases (alist-cons-after
                 'unpack 'bootstrap
                 (lambda _
                   ;; Fix "field ‘ip6’ has incomplete type" errors.
                   (substitute* "libbridge/libbridge.h"
                     (("#include <linux/if_bridge.h>")
                      "#include <linux/in6.h>\n#include <linux/if_bridge.h>"))

                   ;; Ensure that the entire build fails if one of the
                   ;; sub-Makefiles fails.
                   (substitute* "Makefile.in"
                     (("\\$\\(MAKE\\) \\$\\(MFLAGS\\) -C \\$\\$x ;")
                      "$(MAKE) $(MFLAGS) -C $$x || exit 1;"))

                   (zero? (system* "autoreconf" "-vf")))
                 %standard-phases)
       #:tests? #f))                              ; no 'check' target

    (home-page
     "http://www.linuxfoundation.org/collaborate/workgroups/networking/bridge")
    (synopsis "Manipulate Ethernet bridges")
    (description
     "Utilities for Linux's Ethernet bridging facilities.  A bridge is a way
to connect two Ethernet segments together in a protocol independent way.
Packets are forwarded based on Ethernet address, rather than IP address (like
a router).  Since forwarding is done at Layer 2, all protocols can go
transparently through a bridge.")
    (license gpl2+)))

(define-public libnl
  (package
    (name "libnl")
    (version "3.2.25")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://www.infradead.org/~tgr/libnl/files/libnl-"
                    version ".tar.gz"))
              (sha256
               (base32
                "1icfrv8yihcb74as1gcgmp0wfpdq632q2zvbvqqvjms9cy87bswb"))))
    (build-system gnu-build-system)
    (native-inputs `(("flex" ,flex) ("bison" ,bison)))
    (home-page "http://www.infradead.org/~tgr/libnl/")
    (synopsis "NetLink protocol library suite")
    (description
     "The libnl suite is a collection of libraries providing APIs to netlink
protocol based Linux kernel interfaces.  Netlink is an IPC mechanism primarily
between the kernel and user space processes.  It was designed to be a more
flexible successor to ioctl to provide mainly networking related kernel
configuration and monitoring interfaces.")

    ;; Most files are LGPLv2.1-only, but some are GPLv2-only (like
    ;; 'nl-addr-add.c'), so the result is GPLv2-only.
    (license gpl2)))

(define-public iw
  (package
    (name "iw")
    (version "3.17")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://www.kernel.org/pub/software/network/iw/iw-"
                    version ".tar.xz"))
              (sha256
               (base32
                "14zsapqhivk0ws5z21y1ys2c2czi05mzk7bl2yb7qxcfrnsjx9j8"))))
    (build-system gnu-build-system)
    (native-inputs `(("pkg-config" ,pkg-config)))
    (inputs `(("libnl" ,libnl)))
    (arguments
     `(#:make-flags (list (string-append "PREFIX=" (assoc-ref %outputs "out"))
                          "CC=gcc")
       #:phases (alist-delete 'configure %standard-phases)))
    (home-page "http://wireless.kernel.org/en/users/Documentation/iw")
    (synopsis "Tool for configuring wireless devices")
    (description
     "iw is a new nl80211 based CLI configuration utility for wireless
devices.  It replaces 'iwconfig', which is deprecated.")
    (license isc)))

(define-public powertop
  (package
    (name "powertop")
    (version "2.7")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "https://01.org/sites/default/files/downloads/powertop/powertop-"
             version ".tar.gz"))
       (sha256
        (base32
         "1jkqqr3l1x98m7rgin1dgfzxqwj4vciw9lyyq1kl9bdswa818jwd"))))
    (build-system gnu-build-system)
    (inputs
     `(("zlib" ,zlib)
       ("pciutils" ,pciutils)
       ("ncurses" ,ncurses)
       ("libnl" ,libnl)))
    (native-inputs
       `(("pkg-config" ,pkg-config)))
    (home-page "https://01.org/powertop/")
    (synopsis "Analyze power consumption on Intel-based laptops")
    (description
     "PowerTOP is a Linux tool to diagnose issues with power consumption and
power management.  In addition to being a diagnostic tool, PowerTOP also has
an interactive mode where the user can experiment various power management
settings for cases where the operating system has not enabled these
settings.")
    (license gpl2)))

(define-public aumix
  (package
    (name "aumix")
    (version "2.9.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://www.jpj.net/~trevor/aumix/releases/aumix-"
                    version ".tar.bz2"))
              (sha256
               (base32
                "0a8fwyxnc5qdxff8sl2sfsbnvgh6pkij4yafiln0fxgg6bal7knj"))))
    (build-system gnu-build-system)
    (inputs `(("ncurses" ,ncurses)))
    (home-page "http://www.jpj.net/~trevor/aumix.html")
    (synopsis "Audio mixer for X and the console")
    (description
     "Aumix adjusts an audio mixer from X, the console, a terminal,
the command line or a script.")
    (license gpl2+)))

(define-public iotop
  (package
    (name "iotop")
    (version "0.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://guichaz.free.fr/iotop/files/iotop-"
                           version ".tar.gz"))
       (sha256 (base32
                "1kp8mqg2pbxq4xzpianypadfxcsyfgwcaqgqia6h9fsq6zyh4z0s"))))
    (build-system python-build-system)
    (arguments
     ;; The setup.py script expects python-2.
     `(#:python ,python-2
       ;; There are currently no checks in the package.
       #:tests? #f))
    (native-inputs `(("python" ,python-2)))
    (home-page "http://guichaz.free.fr/iotop/")
    (synopsis
     "Displays the IO activity of running processes")
    (description
     "Iotop is a Python program with a top like user interface to show the
processes currently causing I/O.")
    (license gpl2+)))

(define-public fuse
  (package
    (name "fuse")
    (version "2.9.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/fuse/fuse-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "071r6xjgssy8vwdn6m28qq1bqxsd2bphcd2mzhq0grf5ybm87sqb"))
              (patches (list (search-patch "fuse-CVE-2015-3202.patch")))))
    (build-system gnu-build-system)
    (inputs `(("util-linux" ,util-linux)))
    (arguments
     '(#:configure-flags (list (string-append "MOUNT_FUSE_PATH="
                                              (assoc-ref %outputs "out")
                                              "/sbin")
                               (string-append "INIT_D_PATH="
                                              (assoc-ref %outputs "out")
                                              "/etc/init.d")

                               ;; The rule makes /dev/fuse 666.
                               (string-append "UDEV_RULES_PATH="
                                              (assoc-ref %outputs "out")
                                              "/lib/udev/rules.d"))
      #:phases (alist-cons-before
                'build 'set-file-names
                (lambda* (#:key inputs #:allow-other-keys)
                  ;; libfuse calls out to mount(8) and umount(8).  Make sure
                  ;; it refers to the right ones.
                  (substitute* '("lib/mount_util.c" "util/mount_util.c")
                    (("/bin/(u?)mount" _ maybe-u)
                     (string-append (assoc-ref inputs "util-linux")
                                    "/bin/" maybe-u "mount")))
                  (substitute* '("util/mount.fuse.c")
                    (("/bin/sh")
                     (which "sh")))

                  ;; This hack leads libfuse to search for 'fusermount' in
                  ;; $PATH, where it may find a setuid-root binary, instead of
                  ;; trying solely $out/sbin/fusermount and failing because
                  ;; it's not setuid.
                  (substitute* "lib/Makefile"
                    (("-DFUSERMOUNT_DIR=[[:graph:]]+")
                     "-DFUSERMOUNT_DIR=\\\"/var/empty\\\"")))
                %standard-phases)))
    (home-page "http://fuse.sourceforge.net/")
    (synopsis "Support file systems implemented in user space")
    (description
     "As a consequence of its monolithic design, file system code for Linux
normally goes into the kernel itself---which is not only a robustness issue,
but also an impediment to system extensibility.  FUSE, for \"file systems in
user space\", is a kernel module and user-space library that tries to address
part of this problem by allowing users to run file system implementations as
user-space processes.")
    (license (list lgpl2.1                        ; library
                   gpl2+))))                      ; command-line utilities

(define-public unionfs-fuse
  (package
    (name "unionfs-fuse")
    (version "0.26")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://podgorny.cz/unionfs-fuse/releases/unionfs-fuse-"
                    version ".tar.xz"))
              (sha256
               (base32
                "0qpnr4czgc62vsfnmv933w62nq3xwcbnvqch72qakfgca75rsp4d"))))
    (build-system cmake-build-system)
    (inputs `(("fuse" ,fuse)))
    (arguments '(#:tests? #f))                    ; no tests
    (home-page "http://podgorny.cz/moin/UnionFsFuse")
    (synopsis "User-space union file system")
    (description
     "UnionFS-FUSE is a flexible union file system implementation in user
space, using the FUSE library.  Mounting a union file system allows you to
\"aggregate\" the contents of several directories into a single mount point.
UnionFS-FUSE additionally supports copy-on-write.")
    (license bsd-3)))

(define fuse-static
  (package (inherit fuse)
    (name "fuse-static")
    (source (origin (inherit (package-source fuse))
              (modules '((guix build utils)))
              (snippet
               ;; Normally libfuse invokes mount(8) so that /etc/mtab is
               ;; updated.  Change calls to 'mtab_needs_update' to 0 so that
               ;; it doesn't do that, allowing us to remove the dependency on
               ;; util-linux (something that is useful in initrds.)
               '(substitute* '("lib/mount_util.c"
                               "util/mount_util.c")
                  (("mtab_needs_update[[:blank:]]*\\([a-z_]+\\)")
                   "0")
                  (("/bin/")
                   "")))))))

(define-public unionfs-fuse/static
  (package (inherit unionfs-fuse)
    (synopsis "User-space union file system (statically linked)")
    (name (string-append (package-name unionfs-fuse) "-static"))
    (source (origin (inherit (package-source unionfs-fuse))
              (modules '((guix build utils)))
              (snippet
               ;; Add -ldl to the libraries, because libfuse.a needs that.
               '(substitute* "src/CMakeLists.txt"
                  (("target_link_libraries(.*)\\)" _ libs)
                   (string-append "target_link_libraries"
                                  libs " dl)"))))))
    (arguments
     '(#:tests? #f
       #:configure-flags '("-DCMAKE_EXE_LINKER_FLAGS=-static")
       #:phases (alist-cons-after
                 'install 'post-install
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let* ((out (assoc-ref outputs "out"))
                          (exe (string-append out "/bin/unionfs")))
                     ;; By default, 'unionfs' keeps references to
                     ;; $glibc/share/locale and similar stuff.  Remove them.
                     (remove-store-references exe)))
                 %standard-phases)))
    (inputs `(("fuse" ,fuse-static)))))

(define-public sshfs-fuse
  (package
    (name "sshfs-fuse")
    (version "2.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/fuse/sshfs-fuse-"
                                  version ".tar.gz"))
              (sha256
               (base32
                "0gp6qr33l2p0964j0kds0dfmvyyf5lpgsn11daf0n5fhwm9185z9"))))
    (build-system gnu-build-system)
    (inputs
     `(("fuse" ,fuse)
       ("glib" ,glib)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "http://fuse.sourceforge.net/sshfs.html")
    (synopsis "Mount remote file systems over SSH")
    (description
     "This is a file system client based on the SSH File Transfer Protocol.
Since most SSH servers already support this protocol it is very easy to set
up: on the server side there's nothing to do; on the client side mounting the
file system is as easy as logging into the server with an SSH client.")
    (license gpl2+)))

(define-public numactl
  (package
    (name "numactl")
    (version "2.0.9")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "ftp://oss.sgi.com/www/projects/libnuma/download/numactl-"
                    version
                    ".tar.gz"))
              (sha256
               (base32
                "073myxlyyhgxh1w3r757ajixb7s2k69czc3r0g12c3scq7k3784w"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-replace
                 'configure
                 (lambda* (#:key outputs #:allow-other-keys)
                   ;; There's no 'configure' script, just a raw makefile.
                   (substitute* "Makefile"
                     (("^prefix := .*$")
                      (string-append "prefix := " (assoc-ref outputs "out")
                                     "\n"))
                     (("^libdir := .*$")
                      ;; By default the thing tries to install under
                      ;; $prefix/lib64 when on a 64-bit platform.
                      (string-append "libdir := $(prefix)/lib\n"))))
                 %standard-phases)

       #:make-flags (list
                     ;; By default the thing tries to use 'cc'.
                     "CC=gcc"

                     ;; Make sure programs have an RPATH so they can find
                     ;; libnuma.so.
                     (string-append "LDLIBS=-Wl,-rpath="
                                    (assoc-ref %outputs "out") "/lib"))

       ;; There's a 'test' target, but it requires NUMA support in the kernel
       ;; to run, which we can't assume to have.
       #:tests? #f))
    (home-page "http://oss.sgi.com/projects/libnuma/")
    (synopsis "Tools for non-uniform memory access (NUMA) machines")
    (description
     "NUMA stands for Non-Uniform Memory Access, in other words a system whose
memory is not all in one place.  The numactl program allows you to run your
application program on specific CPU's and memory nodes.  It does this by
supplying a NUMA memory policy to the operating system before running your
program.

The package contains other commands, such as numademo, numastat and memhog.
The numademo command provides a quick overview of NUMA performance on your
system.")
    (license (list gpl2                           ; programs
                   lgpl2.1))))                    ; library

(define-public kbd
  (package
    (name "kbd")
    (version "2.0.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kernel.org/linux/utils/kbd/kbd-"
                                  version ".tar.xz"))
              (sha256
               (base32
                "04mrms12nm5sas0nxs94yrr3hz7gmqhnmfgb9ff34bh1jszxmzcx"))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  (substitute* "tests/Makefile.in"
                    ;; The '%: %.in' rule incorrectly uses @VERSION@.
                    (("@VERSION@")
                     "[@]VERSION[@]"))
                  (substitute* '("src/unicode_start" "src/unicode_stop")
                    ;; Assume the Coreutils are in $PATH.
                    (("/usr/bin/tty")
                     "tty"))))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-cons-before
                 'build 'pre-build
                 (lambda* (#:key inputs #:allow-other-keys)
                   (let ((gzip  (assoc-ref %build-inputs "gzip"))
                         (bzip2 (assoc-ref %build-inputs "bzip2")))
                     (substitute* "src/libkeymap/findfile.c"
                       (("gzip")
                        (string-append gzip "/bin/gzip"))
                       (("bzip2")
                        (string-append bzip2 "/bin/bzip2")))))
                 (alist-cons-after
                  'install 'post-install
                  (lambda* (#:key outputs #:allow-other-keys)
                    ;; Make sure these programs find their comrades.
                    (let* ((out (assoc-ref outputs "out"))
                           (bin (string-append out "/bin")))
                      (for-each (lambda (prog)
                                  (wrap-program (string-append bin "/" prog)
                                                `("PATH" ":" prefix (,bin))))
                                '("unicode_start" "unicode_stop"))))
                  %standard-phases))))
    (inputs `(("check" ,check)
              ("gzip" ,gzip)
              ("bzip2" ,bzip2)
              ("pam" ,linux-pam)))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (home-page "ftp://ftp.kernel.org/pub/linux/utils/kbd/")
    (synopsis "Linux keyboard utilities and keyboard maps")
    (description
     "This package contains keytable files and keyboard utilities compatible
for systems using the Linux kernel.  This includes commands such as
'loadkeys', 'setfont', 'kbdinfo', and 'chvt'.")
    (license gpl2+)))

(define-public inotify-tools
  (package
    (name "inotify-tools")
    (version "3.13")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://sourceforge/inotify-tools/inotify-tools/"
                    version "/inotify-tools-" version ".tar.gz"))
              (sha256
               (base32
                "0icl4bx041axd5dvhg89kilfkysjj86hjakc7bk8n49cxjn4cha6"))))
    (build-system gnu-build-system)
    (home-page "http://inotify-tools.sourceforge.net/")
    (synopsis "Monitor file accesses")
    (description
     "The inotify-tools packages provides a C library and command-line tools
to use Linux' inotify mechanism, which allows file accesses to be monitored.")
    (license gpl2+)))

(define-public kmod
  (package
    (name "kmod")
    (version "17")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "mirror://kernel.org/linux/utils/kernel/kmod/"
                              "kmod-" version ".tar.xz"))
              (sha256
               (base32
                "1yid3a9b64a60ybj66fk2ysrq5klnl0ijl4g624cl16y8404g9rv"))
              (patches (list (search-patch "kmod-module-directory.patch")))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("xz" ,xz)
       ("zlib" ,zlib)))
    (arguments
     `(#:tests? #f ; FIXME: Investigate test failures
       #:configure-flags '("--with-xz" "--with-zlib")
       #:phases (alist-cons-after
                 'install 'install-modprobe&co
                 (lambda* (#:key outputs #:allow-other-keys)
                   (let* ((out (assoc-ref outputs "out"))
                          (bin (string-append out "/bin")))
                     (for-each (lambda (tool)
                                 (symlink "kmod"
                                          (string-append bin "/" tool)))
                               '("insmod" "rmmod" "lsmod" "modprobe"
                                 "modinfo" "depmod"))))
                 %standard-phases)))
    (home-page "https://www.kernel.org/")
    (synopsis "Kernel module tools")
    (description "Kmod is a set of tools to handle common tasks with Linux
kernel modules like insert, remove, list, check properties, resolve
dependencies and aliases.

These tools are designed on top of libkmod, a library that is shipped with
kmod.  The aim is to be compatible with tools, configurations and indices
from the module-init-tools project.")
    (license gpl2+))) ; library under lgpl2.1+

(define-public eudev
  ;; The post-systemd fork, maintained by Gentoo.
  (package
    (name "eudev")
    (version "3.1.5")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://dev.gentoo.org/~blueness/eudev/eudev-"
                    version ".tar.gz"))
              (sha256
               (base32
                "0akg9gcc3c2p56xbhlvbybqavcprly5q0bvk655zwl6d62j8an7p"))
              (patches (list (search-patch "eudev-rules-directory.patch")))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("perl" ,perl)
       ("gperf" ,gperf)))
    (inputs
     `(("kmod" ,kmod)))
    (home-page "http://www.gentoo.org/proj/en/eudev/")
    (synopsis "Userspace device management")
    (description "Udev is a daemon which dynamically creates and removes
device nodes from /dev/, handles hotplug events and loads drivers at boot
time.")
    (license gpl2+)))

(define-public lvm2
  (package
    (name "lvm2")
    (version "2.02.109")
    (source (origin
              (method url-fetch)
              (uri (string-append "ftp://sources.redhat.com/pub/lvm2/releases/LVM2."
                                  version ".tgz"))
              (sha256
               (base32
                "1rv5ivg0l1w3nwzwdkqixm96h5bzg7ib4rr196ysb2lw42jmpjbv"))
              (modules '((guix build utils)))
              (snippet
               '(begin
                  (use-modules (guix build utils))

                  ;; Honor sysconfdir.
                  (substitute* "make.tmpl.in"
                    (("confdir = .*$")
                     "confdir = @sysconfdir@\n")
                    (("DEFAULT_SYS_DIR = @DEFAULT_SYS_DIR@")
                     "DEFAULT_SYS_DIR = @sysconfdir@"))))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("procps" ,procps)))                       ;tests use 'pgrep'
    (inputs
     `(("udev" ,eudev)))
    (arguments
     '(#:phases (alist-cons-after
                 'configure 'set-makefile-shell
                 (lambda _
                   ;; Use 'sh', not 'bash', so that '. lib/utils.sh' works as
                   ;; expected.
                   (setenv "SHELL" (which "sh"))

                   ;; Replace /bin/sh with the right file name.
                   (patch-makefile-SHELL "make.tmpl"))
                 %standard-phases)

       #:configure-flags (list (string-append "--sysconfdir="
                                              (assoc-ref %outputs "out")
                                              "/etc/lvm")
                               "--enable-udev_sync"
                               "--enable-udev_rules"

                               ;; Make sure programs such as 'dmsetup' can
                               ;; find libdevmapper.so.
                               (string-append "LDFLAGS=-Wl,-rpath="
                                              (assoc-ref %outputs "out")
                                              "/lib"))

       ;; The tests use 'mknod', which requires root access.
       #:tests? #f))
    (home-page "http://sourceware.org/lvm2/")
    (synopsis "Logical volume management for Linux")
    (description
     "LVM2 is the logical volume management tool set for Linux-based systems.
This package includes the user-space libraries and tools, including the device
mapper.  Kernel components are part of Linux-libre.")

    ;; Libraries (liblvm2, libdevmapper) are LGPLv2.1.
    ;; Command-line tools are GPLv2.
    (license (list gpl2 lgpl2.1))))

(define-public wireless-tools
  (package
    (name "wireless-tools")
    (version "30.pre9")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/wireless_tools."
                                  version ".tar.gz"))
              (sha256
               (base32
                "0qscyd44jmhs4k32ggp107hlym1pcyjzihiai48xs7xzib4wbndb"))
              (snippet
               '(begin
                  ;; Remove the older header files that are not free software.
                  (for-each (lambda (n)
                              (delete-file (format #f "wireless.~a.h" n)))
                            '(10 11 12 13 14 15 16 17 18 19 20))
                  #t))))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags
       (list (string-append "PREFIX=" %output)
             (string-append "INSTALL_MAN=" %output "/share/man")
             (string-append "LDFLAGS=-Wl,-rpath=" %output "/lib")
             "BUILD_STATIC=")
       #:phases (modify-phases %standard-phases
                  (delete 'configure))
       #:tests? #f))
    (synopsis "Tools for manipulating Linux Wireless Extensions")
    (description "Wireless Tools are used to manipulate the now-deprecated
Linux Wireless Extensions; consider using 'iw' instead.  The Wireless
Extension was an interface allowing you to set Wireless LAN specific
parameters and get the specific stats.  It is deprecated in favor the nl80211
interface.")
    (home-page "http://www.hpl.hp.com/personal/Jean_Tourrilhes/Linux/Tools.html")
    ;; wireless.21.h and wireless.22.h are distributed under lgpl2.1+, the
    ;; other files are distributed under gpl2.
    (license (list gpl2 lgpl2.1+))))

(define-public crda
  (package
    (name "crda")
    (version "3.18")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kernel.org/software/network/crda/"
                                  "crda-" version ".tar.xz"))
              (sha256
               (base32
                "1gydiqgb08d9gbx4l6gv98zg3pljc984m50hmn3ysxcbkxkvkz23"))
              (patches (list (search-patch "crda-optional-gcrypt.patch")))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (modify-phases %standard-phases
                  (delete 'configure)
                  (add-before
                   'build 'no-werror-no-ldconfig
                   (lambda _
                     (substitute* "Makefile"
                       (("-Werror")  "")
                       (("ldconfig") "true"))
                     #t))
                  (add-before
                   'build 'set-regulator-db-file-name
                   (lambda* (#:key inputs #:allow-other-keys)
                     ;; Tell CRDA where to find our database.
                     (let ((regdb (assoc-ref inputs "wireless-regdb")))
                       (substitute* "crda.c"
                         (("\"/lib/crda/regulatory.bin\"")
                          (string-append "\"" regdb
                                         "/lib/crda/regulatory.bin\"")))
                       #t))))
       #:test-target "verify"
       #:make-flags (let ((out   (assoc-ref %outputs "out"))
                          (regdb (assoc-ref %build-inputs "wireless-regdb")))
                      (list "CC=gcc" "V=1"

                            ;; Disable signature-checking on 'regulatory.bin'.
                            ;; The reason is that this simplifies maintenance
                            ;; on our side (no need to manage a distro key
                            ;; pair), and we can guarantee integrity of
                            ;; 'regulatory.bin' by other means anyway, such as
                            ;; 'guix gc --verify'.  See
                            ;; <https://wireless.wiki.kernel.org/en/developers/regulatory/wireless-regdb>
                            ;; for a discssion.
                            "USE_OPENSSL=0"

                            (string-append "PREFIX=" out)
                            (string-append "SBINDIR=" out "/sbin/")
                            (string-append "UDEV_RULE_DIR="
                                           out "/lib/udev/rules.d")
                            (string-append "LDFLAGS=-Wl,-rpath="
                                           out "/lib -L.")
                            (string-append "REG_BIN=" regdb
                                           "/lib/crda/regulatory.bin")))))
    (native-inputs `(("pkg-config" ,pkg-config)
                     ("python" ,python-2)
                     ("wireless-regdb" ,wireless-regdb)))
    (inputs `(("libnl" ,libnl)))
    (home-page
     "https://wireless.wiki.kernel.org/en/developers/Regulatory/CRDA")
    (synopsis "Central regulatory domain agent (CRDA) for WiFi")
    (description
     "The Central Regulatory Domain Agent (CRDA) acts as the udev helper for
communication between the kernel Linux and user space for regulatory
compliance.")
    (license copyleft-next)))

(define-public wireless-regdb
  (package
    (name "wireless-regdb")
    (version "2015.04.06")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://kernel.org/software/network/wireless-regdb/"
                    "wireless-regdb-" version ".tar.xz"))
              (sha256
               (base32
                "0czi83k311fp27z42hxjm8vi88fsbc23mhavv96lkb4pmari0jjc"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (modify-phases %standard-phases
                  (delete 'configure))
       #:tests? #f                                ;no tests
       #:make-flags (let ((out (assoc-ref %outputs "out")))
                      (list (string-append "PREFIX=" out)
                            (string-append "LSB_ID=GuixSD")
                            (string-append "DISTRO_PUBKEY=/dev/null")
                            (string-append "DISTRO_PRIVKEY=/dev/null")
                            (string-append "REGDB_PUBKEY=/dev/null")

                            ;; Leave that empty so that db2bin.py doesn't try
                            ;; to sign 'regulatory.bin'.  This allows us to
                            ;; avoid managing a key pair for the whole distro.
                            (string-append "REGDB_PRIVKEY=")))))
    (native-inputs `(("python" ,python-2)))
    (home-page
     "https://wireless.wiki.kernel.org/en/developers/regulatory/wireless-regdb")
    (synopsis "Wireless regulatory database")
    (description
     "This package contains the wireless regulatory database Central
Regulatory Database Agent (CRDA) daemon.  The database contains information on
country-specific regulations for the wireless spectrum.")
    (license isc)))

(define-public lm-sensors
  (package
    (name "lm-sensors")
    (version "3.3.5")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://dl.lm-sensors.org/lm-sensors/releases/lm_sensors-"
                    version ".tar.bz2"))
              (sha256
               (base32
                "1ksgrynxgrq590nb2fwxrl1gwzisjkqlyg3ljfd1al0ibrk6mbjx"))
              (patches (list (search-patch "lm-sensors-hwmon-attrs.patch")))))
    (build-system gnu-build-system)
    (inputs `(("rrdtool" ,rrdtool)
              ("perl" ,perl)
              ("kmod" ,kmod)
              ("gnuplot" ,gnuplot)))
    (native-inputs `(("pkg-config" ,pkg-config)
                     ("flex" ,flex)
                     ("bison" ,bison)
                     ("which" ,which)))
    (arguments
     `(#:tests? #f  ; no 'check' target
       #:make-flags (list (string-append "PREFIX=" %output)
                          (string-append "ETCDIR=" %output "/etc")
                          (string-append "MANDIR=" %output "/share/man"))
       #:phases
       (alist-delete
        'configure
        (alist-cons-before
         'build 'patch-exec-paths
         (lambda* (#:key inputs outputs #:allow-other-keys)
           (substitute* "prog/detect/sensors-detect"
             (("`uname")
              (string-append "`" (assoc-ref inputs "coreutils")
                             "/bin/uname"))
             (("(`|\")modprobe" all open-quote)
              (string-append open-quote
                             (assoc-ref inputs "kmod")
                             "/bin/modprobe")))
           (substitute* '("prog/pwm/pwmconfig"
                          "prog/pwm/fancontrol")
             (("gnuplot")
              (string-append (assoc-ref inputs "gnuplot")
                             "/bin/gnuplot"))
             (("cat ")
              (string-append (assoc-ref inputs "coreutils")
                             "/bin/cat "))
             (("egrep ")
              (string-append (assoc-ref inputs "grep")
                             "/bin/egrep "))
             (("sed -e")
              (string-append (assoc-ref inputs "sed")
                             "/bin/sed -e"))
             (("cut -d")
              (string-append (assoc-ref inputs "coreutils")
                             "/bin/cut -d"))
             (("sleep ")
              (string-append (assoc-ref inputs "coreutils")
                             "/bin/sleep "))
             (("readlink -f")
              (string-append (assoc-ref inputs "coreutils")
                             "/bin/readlink -f"))))
         %standard-phases))))
    (home-page "http://www.lm-sensors.org/")
    (synopsis "Utilities to read temperature/voltage/fan sensors")
    (description
     "Lm-sensors is a hardware health monitoring package for Linux.  It allows
you to access information from temperature, voltage, and fan speed sensors.
It works with most newer systems.")
    (license gpl2+)))

(define-public i2c-tools
  (package
    (name "i2c-tools")
    (version "3.1.1")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://dl.lm-sensors.org/i2c-tools/releases/i2c-tools-"
                    version ".tar.bz2"))
              (sha256
               (base32
                "000pvg995qy1b15ks59gd0klri55hb33kqpg5czy84hw1pbdgm0l"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f  ; no 'check' target
       #:make-flags (list (string-append "prefix=" %output)
                          "CC=gcc")
       ;; no configure script
       #:phases (alist-delete 'configure %standard-phases)))
    (inputs
     `(("perl" ,perl)))
    (home-page "http://www.lm-sensors.org/wiki/I2CTools")
    (synopsis "I2C tools for Linux")
    (description
     "The i2c-tools package contains a heterogeneous set of I2C tools for
Linux: a bus probing tool, a chip dumper, register-level SMBus access helpers,
EEPROM decoding scripts, EEPROM programming tools, and a python module for
SMBus access.")
    (license gpl2+)))

(define-public xsensors
  (package
    (name "xsensors")
    (version "0.70")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://www.linuxhardware.org/xsensors/xsensors-"
                    version ".tar.gz"))
              (sha256
               (base32
                "1siplsfgvcxamyqf44h71jx6jdfmvhfm7mh0y1q8ps4zs6pj2zwh"))))
    (build-system gnu-build-system)
    (inputs `(("lm-sensors" ,lm-sensors)
              ("gtk" ,gtk+-2)))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (arguments
     `(#:phases (alist-cons-before
                 'configure 'enable-deprecated
                 (lambda _
                   (substitute* "src/Makefile.in"
                     (("-DGDK_DISABLE_DEPRECATED") "")
                     (("-DGTK_DISABLE_DEPRECATED") "")))
                 (alist-cons-before
                  'configure 'remove-Werror
                  (lambda _
                    (substitute* '("configure" "src/Makefile.in")
                      (("-Werror") "")))
                  %standard-phases))))
    (home-page "http://www.linuxhardware.org/xsensors/")
    (synopsis "Hardware health information viewer")
    (description
     "Xsensors reads data from the libsensors library regarding hardware
health such as temperature, voltage and fan speed and displays the information
in a digital read-out.")
    (license gpl2+)))

(define-public perf
  (package
    (name "perf")
    (version (package-version linux-libre))
    (source (package-source linux-libre))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (alist-replace
                 'configure
                 (lambda* (#:key inputs #:allow-other-keys)
                   (setenv "SHELL_PATH" (which "bash"))
                   (chdir "tools/perf"))
                 %standard-phases)
       #:make-flags (list (string-append "DESTDIR="
                                         (assoc-ref %outputs "out"))
                          "WERROR=0"

                          ;; By default, 'config/Makefile' uses lib64 on
                          ;; x86_64.  Work around that.
                          "lib=lib")
       #:tests? #f))                              ;no tests
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("bison" ,bison)
       ("flex" ,flex)

       ;; There are build scripts written in these languages.
       ("perl" ,perl)
       ("python" ,python-2)))
    (inputs
     `(("slang" ,slang)                        ;for the interactive TUI
       ;; ("newt" ,newt)
       ("python" ,python-2)                    ;'perf' links against libpython
       ("elfutils" ,elfutils)

       ;; Documentation.
       ("libxml2" ,libxml2)                       ;for $XML_CATALOG_FILES
       ("libxslt" ,libxslt)
       ("docbook-xml" ,docbook-xml)
       ("docbook-xsl" ,docbook-xsl)
       ("xmlto" ,xmlto)
       ("asciidoc" ,asciidoc)))
    (home-page "https://perf.wiki.kernel.org/")
    (synopsis "Linux profiling with performance counters")
    (description
     "perf is a tool suite for profiling using hardware performance counters,
with support in the Linux kernel.  perf can instrument CPU performance
counters, tracepoints, kprobes, and uprobes (dynamic tracing).  It is capable
of lightweight profiling.  This package contains the user-land tools and in
particular the 'perf' command.")
    (license (package-license linux-libre))))

(define-public pflask
  (package
    (name "pflask")
    (version "0.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/ghedo/pflask/archive/v"
                                  version ".tar.gz"))
              (file-name (string-append name "-" version ".tar.gz"))
              (sha256
               (base32
                "1g8fjj67dfkc2s0852l9vqi1pm61gp4rxbpzbzg780f5s5hd1fys"))))
    (build-system cmake-build-system)
    (arguments
     '(#:tests? #f)) ; no tests
    (home-page "http://ghedo.github.io/pflask/")
    (synopsis "Simple tool for creating Linux namespace containers")
    (description "pflask is a simple tool for creating Linux namespace
containers.  It can be used for running a command or even booting an OS inside
an isolated container, created with the help of Linux namespaces.  It is
similar in functionality to chroot, although pflask provides better isolation
thanks to the use of namespaces.")
    (license bsd-2)))

(define-public hdparm
  (package
    (name "hdparm")
    (version "9.45")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/" name "/"
                                  name "-" version ".tar.gz"))
              (sha256
               (base32
                "0sc6yf3k6sd7n6a2ig2my9fjlqpak3znlyw7jw4cz5d9asm1rc13"))))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags (let ((out (assoc-ref %outputs "out")))
                      (list (string-append "binprefix=" out)
                            (string-append "manprefix=" out)
                            "CC=gcc"))
       #:phases (alist-delete 'configure %standard-phases)
       #:tests? #f))  ; no test suite
    (home-page "http://sourceforge.net/projects/hdparm/")
    (synopsis "Tune hard disk parameters for high performance")
    (description
     "Get/set device parameters for Linux SATA/IDE drives.  It's primary use
is for enabling irq-unmasking and IDE multiple-mode.")
    (license (non-copyleft "file://LICENSE.TXT"))))

(define-public rfkill
  (package
    (name "rfkill")
    (version "0.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://kernel.org/software/network/"
                                  name "/" name "-" version ".tar.xz"))
              (sha256
               (base32
                "0snqj5h0y991lszbigbyyqb8swj0hxajc1vfqg2scfay44231bp0"))))
    (build-system gnu-build-system)
    (arguments
     `(#:make-flags (list "CC=gcc"
                          (string-append "PREFIX=" %output))
       #:phases (modify-phases %standard-phases
                  (delete 'configure))
       #:tests? #f))
    (home-page "https://wireless.wiki.kernel.org/en/users/Documentation/rfkill")
    (synopsis "Tool for enabling and disabling wireless devices")
    (description
     "rfkill is a simple tool for accessing the rfkill device interface,
which is used to enable and disable wireless networking devices, typically
WLAN, Bluetooth and mobile broadband.")
    (license (non-copyleft "file://COPYING"
                           "See COPYING in the distribution."))))

(define-public acpid
  (package
    (name "acpid")
    (version "2.0.23")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/acpid2/acpid-"
                                  version ".tar.xz"))
              (sha256
               (base32
                "1vl7c6vc724v4jwki17czgj6lnrknnj1a6llm8gkl32i2gnam5j3"))))
    (build-system gnu-build-system)
    (home-page "http://sourceforge.net/projects/acpid2/")
    (synopsis "Daemon for delivering ACPI events to user-space programs")
    (description
     "acpid is designed to notify user-space programs of Advanced
Configuration and Power Interface (ACPI) events.  acpid should be started
during the system boot, and will run as a background process.  When an ACPI
event is received from the kernel, acpid will examine the list of rules
specified in /etc/acpi/events and execute the rules that match the event.")
    (license gpl2+)))

(define-public sysfsutils
  (package
    (name "sysfsutils")
    (version "2.1.0")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append
         "mirror://sourceforge/linux-diag/sysfsutils/" version "/sysfsutils-"
         version ".tar.gz"))
       (sha256
        (base32 "12i0ip11xbfcjzxz4r10cvz7mbzgq1hfcdn97w6zz7sm3wndwrg8"))))
    (build-system gnu-build-system)
    (home-page "http://linux-diag.sourceforge.net/Sysfsutils.html")
    (synopsis "System utilities based on Linux sysfs")
    (description
     "These are a set of utilities built upon sysfs, a virtual filesystem in
Linux kernel versions 2.5+ that exposes a system's device tree.  The package
also contains the libsysfs library.")
    ;; The library is under lgpl2.1+ (all files say "or any later version").
    ;; The rest is mostly gpl2, with a few files indicating gpl2+.
    (license (list gpl2 gpl2+ lgpl2.1+))))

(define-public sysfsutils-1
  (package
    (inherit sysfsutils)
    (version "1.3.0")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append
         "mirror://sourceforge/linux-diag/sysfsutils/sysfsutils-" version
         "/sysfsutils-" version ".tar.gz"))
       (sha256
        (base32 "0kdhs07fm8263pxwd5blwn2x211cg4fk63fyf9ijcdkvzmwxrqq3"))
       (modules '((guix build utils)))
       (snippet
        '(begin
           (substitute* "Makefile.in"
             (("includedir = /usr/include/sysfs")
              "includedir = @includedir@"))
           (substitute* "configure"
             (("includedir='(\\$\\{prefix\\}/include)'" all orig)
              (string-append "includedir='" orig "/sysfs'")))))))
    (synopsis "System utilities based on Linux sysfs (version 1.x)")))

(define-public cpufrequtils
  (package
    (name "cpufrequtils")
    (version "0.3")
    (source
     (origin
       (method url-fetch)
       (uri
        (string-append
         "https://www.kernel.org/pub/linux/utils/kernel/cpufreq/cpufrequtils-"
         version ".tar.gz"))
       (sha256
        (base32 "0qfqv7nqmjfr3p0bwrdlxkiqwqr7vmx053cadaa548ybqbghxmvm"))
       (patches (list (search-patch "cpufrequtils-fix-aclocal.patch")))))
    (build-system gnu-build-system)
    (native-inputs
     `(("sysfsutils" ,sysfsutils-1)))
    (arguments
     '(#:make-flags (list (string-append "LDFLAGS=-Wl,-rpath="
                                         (assoc-ref %outputs "out") "/lib"))))
    (home-page "https://www.kernel.org/pub/linux/utils/kernel/cpufreq/")
    (synopsis "Utilities to get and set CPU frequency on Linux")
    (description
     "The cpufrequtils suite contains utilities to retrieve CPU frequency
information, and set the CPU frequency if supported, using the cpufreq
capabilities of the Linux kernel.")
    (license gpl2)))

(define-public libraw1394
  (package
    (name "libraw1394")
    (version "2.1.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://kernel.org/linux/libs/ieee1394/"
                    name "-" version ".tar.xz"))
              (sha256
               (base32
                "0kwnf4ha45c04mhc4yla672aqmvqqihxix1gvblns5cd2pc2cc8b"))))
    (build-system gnu-build-system)
    (home-page "https://ieee1394.wiki.kernel.org/index.php/Main_Page")
    (synopsis "Interface library for the Linux IEEE1394 drivers")
    (description
     "Libraw1394 is the only supported interface to the kernel side raw1394 of
the Linux IEEE-1394 subsystem, which provides direct access to the connected
1394 buses to user space.  Through libraw1394/raw1394, applications can directly
send to and receive from other nodes without requiring a kernel driver for the
protocol in question.")
    (license lgpl2.1+)))

(define-public libavc1394
  (package
    (name "libavc1394")
    (version "0.5.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/libavc1394/"
                                  name "-" version ".tar.gz"))
              (sha256
               (base32
                "0lsv46jdqvdx5hx92v0z2cz3yh6212pz9gk0k3513sbaa04zzcbw"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("libraw1394" ,libraw1394))) ; required by libavc1394.pc
    (home-page "http://sourceforge.net/projects/libavc1394/")
    (synopsis "AV/C protocol library for IEEE 1394")
    (description
     "Libavc1394 is a programming interface to the AV/C specification from
the 1394 Trade Association.  AV/C stands for Audio/Video Control.")
    (license lgpl2.1+)))

(define-public libiec61883
  (package
    (name "libiec61883")
    (version "1.2.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://kernel.org/linux/libs/ieee1394/"
                    name "-" version ".tar.xz"))
              (sha256
               (base32
                "17ph458zya2l8dr2xwqnzy195qd9swrir31g78qkgb3g4xz2rq6i"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("libraw1394" ,libraw1394))) ; required by libiec61883.pc
    (home-page "https://ieee1394.wiki.kernel.org/index.php/Main_Page")
    (synopsis "Isochronous streaming media library for IEEE 1394")
    (description
     "The libiec61883 library provides a higher level API for streaming DV,
MPEG-2 and audio over Linux IEEE 1394.")
    (license lgpl2.1+)))

(define-public mdadm
  (package
    (name "mdadm")
    (version "3.3.2")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://kernel.org/linux/utils/raid/mdadm/mdadm-"
                    version ".tar.xz"))
              (sha256
               (base32
                "132vdvh3myjgcjn6i9w90ck16ddjxjcszklzkyvr4f5ifqd7wfhg"))
              (patches (list (search-patch "mdadm-gcc-4.9-fix.patch")))))
    (build-system gnu-build-system)
    (inputs
     `(("udev" ,eudev)))
    (arguments
     `(#:make-flags (let ((out (assoc-ref %outputs "out")))
                      (list "INSTALL=install"
                            "CHECK_RUN_DIR=0"
                            ;; TODO: tell it where to find 'sendmail'
                            ;; (string-append "MAILCMD=" <???> "/sbin/sendmail")
                            (string-append "BINDIR=" out "/sbin")
                            (string-append "MANDIR=" out "/share/man")
                            (string-append "UDEVDIR=" out "/lib/udev")))
       #:phases (alist-cons-before
                 'build 'patch-program-paths
                 (lambda* (#:key inputs #:allow-other-keys)
                   (let ((coreutils (assoc-ref inputs "coreutils")))
                     (substitute* "udev-md-raid-arrays.rules"
                       (("/usr/bin/(readlink|basename)" all program)
                        (string-append coreutils "/bin/" program)))))
                 (alist-delete 'configure %standard-phases))
       ;;tests must be done as root
       #:tests? #f))
    (home-page "http://neil.brown.name/blog/mdadm")
    (synopsis "Tool for managing Linux Software RAID arrays")
    (description
     "mdadm is a tool for managing Linux Software RAID arrays.  It can create,
assemble, report on, and monitor arrays.  It can also move spares between raid
arrays when needed.")
    (license gpl2+)))

(define-public libaio
  (package
    (name "libaio")
    (version "0.3.110")
    (source (origin
              (method url-fetch)
             (uri (list
                   (string-append "mirror://debian/pool/main/liba/libaio/"
                                  name "_" version ".orig.tar.gz")
                   (string-append "https://fedorahosted.org/releases/l/i/libaio/"
                                  name "-" version ".tar.gz")))
             (sha256
              (base32
               "0zjzfkwd1kdvq6zpawhzisv7qbq1ffs343i5fs9p498pcf7046g0"))))
    (build-system gnu-build-system)
    (arguments
     '(#:make-flags
       (list "CC=gcc" (string-append "prefix=" %output))
       #:test-target "partcheck" ; need root for a full 'check'
       #:phases
       (alist-delete 'configure %standard-phases))) ; no configure script
    (home-page "http://lse.sourceforge.net/io/aio.html")
    (synopsis "Linux-native asynchronous I/O access library")
    (description
     "This library enables userspace to use Linux kernel asynchronous I/O
system calls, important for the performance of databases and other advanced
applications.")
    (license lgpl2.1+)))

(define-public bluez
  (package
    (name "bluez")
    (version "5.35")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "https://www.kernel.org/pub/linux/bluetooth/bluez-"
                    version ".tar.xz"))
              (sha256
               (base32
                "1qphz25hganfnd5ipfscbj7s70anv5favmwqmi9ig2saciaf1zhs"))
              (patches
               (list (search-patch "bluez-tests.patch")))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags
       (let ((out (assoc-ref %outputs "out")))
         (list "--enable-library"
               "--disable-systemd"
               ;; Install dbus/udev files to the correct location.
               (string-append "--with-dbusconfdir=" out "/etc")
               (string-append "--with-udevdir=" out "/lib/udev")))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("gettext" ,gnu-gettext)))
    (inputs
     `(("glib" ,glib)
       ("dbus" ,dbus)
       ("eudev" ,eudev)
       ("libical" ,libical)
       ("readline" ,readline)))
    (home-page "http://www.bluez.org/")
    (synopsis "Linux Bluetooth protocol stack")
    (description
     "BlueZ provides support for the core Bluetooth layers and protocols.  It
is flexible, efficient and uses a modular implementation.")
    (license gpl2+)))

(define-public fuse-exfat
  (package
    (name "fuse-exfat")
    (version "1.1.0")
    (source (origin
              (method url-fetch)
              (uri "https://docs.google.com/uc?export=download&\
id=0B7CLI-REKbE3VTdaa0EzTkhYdU0")
              (sha256
               (base32
                "0glmgwrf0nv09am54i6s35ksbvrywrwc51w6q32mv5by8475530r"))
              (file-name (string-append name "-" version ".tar.gz"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("scons" ,scons)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("fuse" ,fuse)))
    (arguments
     '(#:tests? #f                                ;no test suite

       ;; XXX: Factorize with 'exfat-utils'.
       #:phases (modify-phases %standard-phases
                  (delete 'configure)
                  (add-after 'unpack 'scons-propagate-environment
                             (lambda _
                               ;; Modify the SConstruct file to arrange for
                               ;; environment variables to be propagated.
                               (substitute* "SConstruct"
                                 (("^env = Environment\\(")
                                  "env = Environment(ENV=os.environ, "))))
                  (replace 'build
                           (lambda _
                             (zero? (system* "scons"))))
                  (replace 'install
                           (lambda* (#:key outputs #:allow-other-keys)
                             (let* ((out  (assoc-ref outputs "out"))
                                    (bin  (string-append out "/bin"))
                                    (man8 (string-append out
                                                         "/share/man/man8")))
                               (mkdir-p bin)
                               (mkdir-p man8)
                               (for-each (lambda (file)
                                           (copy-file
                                            file
                                            (string-append man8 "/"
                                                           (basename file))))
                                         (find-files "." "\\.8$"))
                               (zero? (system* "scons" "install"
                                               (string-append "DESTDIR="
                                                              bin)))))))))
    (home-page "http://code.google.com/p/exfat/")
    (synopsis "Mount exFAT file systems")
    (description
     "This package provides a FUSE-based file system that provides read and
write access to exFAT devices.")
    (license gpl2+)))

(define-public gpm
  (package
    (name "gpm")
    (version "1.20.7")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "http://www.nico.schottelius.org/software/gpm/archives/gpm-"
                    version ".tar.bz2"))
              (sha256
               (base32
                "13d426a8h403ckpc8zyf7s2p5rql0lqbg2bv0454x0pvgbfbf4gh"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases (modify-phases %standard-phases
                  (add-before 'configure 'bootstrap
                    (lambda _
                      ;; The tarball was not generated with 'make dist' so we
                      ;; need to bootstrap things ourselves.
                      (and (zero? (system* "./autogen.sh"))
                           (begin
                             (patch-makefile-SHELL "Makefile.include.in")
                             #t)))))

       ;; Make sure programs find libgpm.so.
       #:configure-flags (list (string-append "LDFLAGS=-Wl,-rpath="
                                              (assoc-ref %outputs "out")
                                              "/lib"))))
    (native-inputs
     `(("texinfo" ,texinfo)
       ("bison" ,bison)
       ("flex" ,flex)
       ("autoconf" ,autoconf)
       ("automake" ,automake)
       ("libtool" ,libtool)))
    (home-page "http://www.nico.schottelius.org/software/gpm/")
    (synopsis "Mouse support for the Linux console")
    (description
     "The GPM (general-purpose mouse) daemon is a mouse server for
applications running on the Linux console.  It allows users to select items
and copy/paste text in the console and in xterm.")
    (license gpl2+)))
