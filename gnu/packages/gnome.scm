;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2013, 2015 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2014, 2015 Ludovic Courtès <ludo@gnu.org>
;;; Copyright © 2014 Ian Denhardt <ian@zenhack.net>
;;; Copyright © 2014 Eric Bavier <bavier@member.fsf.org>
;;; Copyright © 2014, 2015 Federico Beffa <beffa@fbengineering.ch>
;;; Copyright © 2015 Sou Bunnbu <iyzsong@gmail.com>
;;; Copyright © 2015 Mathieu Lirzin <mthl@openmailbox.org>
;;; Copyright © 2015 Andy Wingo <wingo@igalia.com>
;;; Copyright © 2015 David Hashe <david.hashe@dhashe.com>
;;; Copyright © 2015 Ricardo Wurmus <rekado@elephly.net>
;;; Copyright © 2015 Mark H Weaver <mhw@netris.org>
;;; Copyright © 2015 David Thompson <davet@gnu.org>
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

(define-module (gnu packages gnome)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (guix build-system glib-or-gtk)
  #:use-module (gnu packages)
  #:use-module (gnu packages admin)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages avahi)
  #:use-module (gnu packages base)
  #:use-module (gnu packages bison)
  #:use-module (gnu packages calendar)
  #:use-module (gnu packages cups)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages djvu)
  #:use-module (gnu packages dns)
  #:use-module (gnu packages flex)
  #:use-module (gnu packages docbook)
  #:use-module (gnu packages enchant)
  #:use-module (gnu packages gettext)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages gnupg)
  #:use-module (gnu packages gnuzilla)
  #:use-module (gnu packages gstreamer)
  #:use-module (gnu packages gtk)
  #:use-module (gnu packages gperf)
  #:use-module (gnu packages guile)
  #:use-module (gnu packages pdf)
  #:use-module (gnu packages polkit)
  #:use-module (gnu packages popt)
  #:use-module (gnu packages ghostscript)
  #:use-module (gnu packages iso-codes)
  #:use-module (gnu packages libcanberra)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages libusb)
  #:use-module (gnu packages lirc)
  #:use-module (gnu packages lua)
  #:use-module (gnu packages m4)
  #:use-module (gnu packages image)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages perl)
  #:use-module (gnu packages photo)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages python)
  #:use-module (gnu packages scanner)
  #:use-module (gnu packages ssh)
  #:use-module (gnu packages xml)
  #:use-module (gnu packages geeqie)
  #:use-module (gnu packages gl)
  #:use-module (gnu packages qt)  ; for libxkbcommon
  #:use-module (gnu packages compression)
  #:use-module (gnu packages texlive)
  #:use-module (gnu packages tls)
  #:use-module (gnu packages web)
  #:use-module (gnu packages webkit)
  #:use-module (gnu packages xorg)
  #:use-module (gnu packages xdisorg)
  #:use-module (gnu packages freedesktop)
  #:use-module (gnu packages mail)
  #:use-module (gnu packages backup)
  #:use-module (gnu packages nettle)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages video)
  #:use-module (gnu packages cdrom)
  #:use-module (gnu packages samba)
  #:use-module (gnu packages readline)
  #:use-module (srfi srfi-1))

(define-public brasero
  (package
    (name "brasero")
    (version "3.12.1")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnome/sources/" name "/"
                                 (version-major+minor version) "/"
                                 name "-" version ".tar.xz"))
             (sha256
              (base32
               "09vi2hyhl0bz7imv3ky6h7x5m3d546n968wcghydwrkvwm9ylpls"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     `(#:configure-flags (list
                          (string-append "--with-girdir="
                                         (assoc-ref %outputs "out")
                                         "/share/gir-1.0")
                          (string-append "--with-typelibdir="
                                         (assoc-ref %outputs "out")
                                         "/lib/girepository-1.0"))))
    (propagated-inputs
     `(("hicolor-icon-theme" ,hicolor-icon-theme)))
    (native-inputs
     `(("intltool" ,intltool)
       ("glib" ,glib "bin")                       ; glib-compile-schemas, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("glib" ,glib)
       ("gnome-doc-utils" ,gnome-doc-utils)
       ("gstreamer" ,gstreamer)
       ("gst-plugins-base" ,gst-plugins-base)
       ("gtk+" ,gtk+)
       ("itstool" ,itstool)
       ("libcanberra" ,libcanberra)
       ("libice" ,libice)
       ("libnotify" ,libnotify)
       ("libsm" ,libsm)
       ("libxml2" ,libxml2)
       ("nettle" ,nettle)
       ("totem-pl-parser" ,totem-pl-parser)))
    (home-page "https://projects.gnome.org/brasero/")
    (synopsis "CD/DVD burning tool for Gnome")
    (description "Brasero is an application to burn CD/DVD for the Gnome
Desktop.  It is designed to be as simple as possible and has some unique
features to enable users to create their discs easily and quickly.")
    (license license:gpl2+)))

(define-public gnome-common
  (package
    (name "gnome-common")
    (version "3.14.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version)  "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "0b1676g4q44ah73c5gwl1kg88pc93pnq1pa9kwl43d0vg0pj802c"))))
    (build-system gnu-build-system)
    (home-page "https://www.gnome.org/")
    (synopsis "Bootstrap GNOME modules built from Git")
    (description "gnome-common contains various files needed to bootstrap
GNOME modules built from Git.  It contains a common \"autogen.sh\" script that
can be used to configure a source directory checked out from Git and some
commonly used macros.")
    (license license:gpl2+)))

(define-public gnome-desktop
  (package
    (name "gnome-desktop")
    (version "3.18.1")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnome/sources/" name "/"
                          (version-major+minor version)  "/"
                          name "-" version ".tar.xz"))
      (sha256
       (base32
        "0avpmyhzz5b3pyfpkp8iq5ym5r5w7zs3a396hqkdpdsiym0vrazc"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("gobject-introspection" ,gobject-introspection)
       ("itstool" ,itstool)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("xmllint" ,libxml2)))
    (propagated-inputs
     ;; Required by gnome-desktop-3.0.pc.
     `(("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("gtk+" ,gtk+)))
    (inputs
     `(("gdk-pixbuf" ,gdk-pixbuf)
       ("glib" ,glib)
       ("iso-codes" ,iso-codes)
       ("libx11" ,libx11)
       ("libxext" ,libxext)
       ("libxkbfile" ,libxkbfile)
       ("libxrandr" ,libxrandr)
       ("xkeyboard-config" ,xkeyboard-config)))
    (home-page "https://www.gnome.org/")
    (synopsis
     "Libgnome-desktop, gnome-about, and desktop-wide documents")
    (description
     "The libgnome-desktop library provides API shared by several applications
on the desktop, but that cannot live in the platform for various reasons.
There is no API or ABI guarantee, although we are doing our best to provide
stability.  Documentation for the API is available with gtk-doc.

The gnome-about program helps find which version of GNOME is installed.")
    ; Some bits under the LGPL.
    (license license:gpl2+)))

(define-public gnome-doc-utils
  (package
    (name "gnome-doc-utils")
    (version "0.20.10")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnome/sources/" name "/"
                          (version-major+minor version)  "/"
                          name "-" version ".tar.xz"))
      (sha256
       (base32
        "19n4x25ndzngaciiyd8dd6s2mf9gv6nv3wv27ggns2smm7zkj1nb"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("intltool" ,intltool)
       ("docbook-xml" ,docbook-xml-4.4)
       ("python2-libxml2" ,python2-libxml2)
       ("libxml2" ,libxml2)
       ("libxslt" ,libxslt)
       ("pkg-config" ,pkg-config)
       ("python-2" ,python-2)))
    (home-page "https://wiki.gnome.org/GnomeDocUtils")
    (synopsis
     "Documentation utilities for the Gnome project")
    (description
     "Gnome-doc-utils is a collection of documentation utilities for the
Gnome project.  It includes xml2po tool which makes it easier to translate
and keep up to date translations of documentation.")
    (license license:gpl2+))) ; xslt under lgpl

(define-public gcr
  (package
    (name "gcr")
    (version "3.18.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnome/sources/" name "/"
                                 (version-major+minor version)  "/"
                                 name "-" version ".tar.xz"))
             (sha256
              (base32
               "006f6xbd3jppkf9avg83mpqdld5d0z6mr0sm81lql52mmyjnvlfl"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ;25 of 598 tests fail because /var/lib/dbus/machine-id does
                   ;not exist
       #:phases (modify-phases %standard-phases
                  (add-before
                   'check 'pre-check
                   (lambda* (#:key inputs #:allow-other-keys)
                     (substitute* "build/tap-driver"
                       (("/usr/bin/env python") (which "python"))))))))
    (inputs
     `(("dbus" ,dbus)
       ("gnupg" ,gnupg) ;called as a child process during tests
       ("libgcrypt" ,libgcrypt)))
    (native-inputs
     `(("python" ,python-2) ;for tests
       ("pkg-config" ,pkg-config)
       ("glib" ,glib "bin")
       ("gobject-introspection" ,gobject-introspection)
       ("intltool" ,intltool)
       ("xsltproc" ,libxslt)))
    ;; mentioned in gck.pc, gcr.pc and gcr-ui.pc
    (propagated-inputs
     `(("p11-kit" ,p11-kit)
       ("glib" ,glib)
       ("gtk+" ,gtk+)))
    (home-page "http://www.gnome.org")
    (synopsis "Libraries for displaying certificates and accessing key stores")
    (description
     "The GCR package contains libraries used for displaying certificates and
accessing key stores.  It also provides the viewer for crypto files on the
GNOME Desktop.")
    (license license:lgpl2.1+)))

(define-public libgnome-keyring
  (package
    (name "libgnome-keyring")
    (version "3.6.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnome/sources/" name "/"
                                 (version-major+minor version)  "/"
                                 name "-" version ".tar.xz"))
             (sha256
              (base32
               "0c4qrjpmv1hqga3xv6wsq2z10x2n78qgw7q3k3s01y1pggxkgjkd"))))
    (build-system gnu-build-system)
    (inputs
     `(("libgcrypt" ,libgcrypt)
       ("dbus" ,dbus)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("glib" ,glib "bin")
       ("intltool" ,intltool)))
    (propagated-inputs
     ;; Referred to in .h files and .pc.
     `(("glib" ,glib)))
    (home-page "http://www.gnome.org")
    (synopsis "Accessing passwords from the GNOME keyring")
    (description
     "Client library to access passwords from the GNOME keyring.")

    ;; Though a couple of files are LGPLv2.1+.
    (license license:lgpl2.0+)))

(define-public gnome-keyring
  (package
    (name "gnome-keyring")
    (version "3.16.0")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnome/sources/" name "/"
                                 (version-major+minor version)  "/"
                                 name "-" version ".tar.xz"))
             (sha256
              (base32
               "1xg1xha3x3hzlmvdq2zm90hc61pj7pnf9yxxvgq4ynl5af6bp8qm"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f ;48 of 603 tests fail because /var/lib/dbus/machine-id does
                   ;not exist
       #:configure-flags
       (list
        (string-append "--with-pkcs11-config="
                       (assoc-ref %outputs "out") "/share/p11-kit/modules/")
        (string-append "--with-pkcs11-modules="
                       (assoc-ref %outputs "out") "/share/p11-kit/modules/"))
       #:phases
       (modify-phases %standard-phases
         (add-before
          'check 'pre-check
          (lambda* (#:key inputs #:allow-other-keys)
            (substitute* "build/tap-driver"
              (("/usr/bin/env python") (which "python")))))
         (add-before
          'configure 'fix-docbook
          (lambda* (#:key inputs #:allow-other-keys)
            (substitute* "docs/Makefile.am"
              (("http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl")
               (string-append (assoc-ref inputs "docbook-xsl")
                              "/xml/xsl/docbook-xsl-"
                              ,(package-version docbook-xsl)
                              "/manpages/docbook.xsl")))
            (setenv "XML_CATALOG_FILES"
                    (string-append (assoc-ref inputs "docbook-xml")
                                   "/xml/dtd/docbook/catalog.xml")))))))
    (inputs
     `(("libgcrypt" ,libgcrypt)
       ("dbus" ,dbus)
       ("gcr" ,gcr)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("glib" ,glib "bin")
       ("python" ,python-2) ;for tests
       ("intltool" ,intltool)
       ("autoconf" ,autoconf)
       ("automake" ,automake)
       ("libxslt" ,libxslt) ;for documentation
       ("docbook-xml" ,docbook-xml-4.2)
       ("docbook-xsl" ,docbook-xsl)))
    (home-page "http://www.gnome.org")
    (synopsis "Daemon to store passwords and encryption keys")
    (description
     "gnome-keyring is a program that keeps passwords and other secrets for
users.  It is run as a daemon in the session, similar to ssh-agent, and other
applications locate it via an environment variable or D-Bus.

The program can manage several keyrings, each with its own master password,
and there is also a session keyring which is never stored to disk, but
forgotten when the session ends.")
    (license license:lgpl2.1+)))

(define-public evince
  (package
    (name "evince")
    (version "3.18.1")
    (source (origin
             (method url-fetch)
             (uri (string-append "mirror://gnome/sources/" name "/"
                                 (version-major+minor version) "/"
                                 name "-" version ".tar.xz"))
             (sha256
              (base32
               "0cccmbvl1b6d2976642iyfr8g3r69zf3mzl2ln6vjvvdbrv26l3v"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     `(#:configure-flags '("--disable-nautilus")

       ;; FIXME: Tests fail with:
       ;;   ImportError: No module named gi.repository
       ;; Where should that module come from?
       #:tests? #f))
    (inputs
     `(("libspectre" ,libspectre)
       ("djvulibre" ,djvulibre)
       ("ghostscript" ,ghostscript)
       ("poppler" ,poppler)
       ("libtiff" ,libtiff)
       ;; TODO:
       ;;   Add libgxps for XPS support.
       ;;   Build libkpathsea as a shared library for DVI support.
       ;; ("libkpathsea" ,texlive-bin)
       ("gnome-desktop" ,gnome-desktop)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("libgnome-keyring" ,libgnome-keyring)
       ("adwaita-icon-theme" ,adwaita-icon-theme)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("atk" ,atk)
       ("pango" ,pango)
       ("gtk+" ,gtk+)
       ("glib" ,glib)
       ("libxml2" ,libxml2)
       ("libsm" ,libsm)
       ("libice" ,libice)
       ("shared-mime-info" ,shared-mime-info)
       ("dconf" ,dconf)
       ("libcanberra" ,libcanberra)
       ("libsecret" ,libsecret)
       ;; For tests.
       ("dogtail" ,python2-dogtail)))
    (native-inputs
     `(("itstool" ,itstool)
       ("intltool" ,intltool)
       ("glib" ,glib "bin")
       ("pkg-config" ,pkg-config)
       ("xmllint" ,libxml2)))
    (home-page
     "http://www.gnome.org/projects/evince/")
    (synopsis "GNOME's document viewer")
    (description
     "Evince is a document viewer for multiple document formats.  It
currently supports PDF, PostScript, DjVu, TIFF and DVI.  The goal
of Evince is to replace the multiple document viewers that exist
on the GNOME Desktop with a single simple application.")
    (license license:gpl2+)))

(define-public gsettings-desktop-schemas
  (package
    (name "gsettings-desktop-schemas")
    (version "3.18.0")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnome/sources/" name "/"
                          (version-major+minor version)  "/"
                          name "-" version ".tar.xz"))
      (sha256
       (base32
        "1szc857f46spdhrbnq9ci3kwfqg5vwpikbf0hprq6vd94rr369xs"))))
    (build-system gnu-build-system)
    (inputs
     `(("glib" ,glib)))
    (native-inputs
     `(("intltool" ,intltool)
       ("glib" ,glib "bin")                       ; glib-compile-schemas, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)))
    (home-page "https://launchpad.net/gsettings-desktop-schemas")
    (synopsis
     "GNOME settings for various desktop components")
    (description
     "Gsettings-desktop-schemas contains a collection of GSettings schemas
for settings shared by various components of the GNOME desktop.")
    (license license:lgpl2.1+)))

(define-public icon-naming-utils
  (package
    (name "icon-naming-utils")
    (version "0.8.90")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "http://tango.freedesktop.org/releases/icon-naming-utils-"
                          version ".tar.bz2"))
      (sha256
       (base32
        "1mc3v28fdfqanx3lqx233vcr4glb4c2376k0kx2v91a4vxwqcdxi"))))
    (build-system gnu-build-system)
    (inputs
     `(("perl" ,perl)
       ("perl-xml-simple" ,perl-xml-simple)))
    (arguments
     '(#:phases
       (alist-cons-after
        'install 'set-load-paths
        ;; Tell 'icon-name-mapping' where XML::Simple is.
        (lambda* (#:key outputs #:allow-other-keys)
          (let* ((out  (assoc-ref outputs "out"))
                 (prog (string-append out "/libexec/icon-name-mapping")))
            (wrap-program
             prog
             `("PERL5LIB" = ,(list (getenv "PERL5LIB"))))))
        %standard-phases)))
    (home-page "http://tango.freedesktop.org/Standard_Icon_Naming_Specification")
    (synopsis
     "Utility to implement the Freedesktop Icon Naming Specification")
    (description
     "To help with the transition to the Freedesktop Icon Naming
Specification, the icon naming utility maps the icon names used by the
GNOME and KDE desktops to the icon names proposed in the specification.")
    (license license:lgpl2.1+)))

(define-public desktop-file-utils
  (package
    (name "desktop-file-utils")
    (version "0.22")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://www.freedesktop.org/software/" name
                                  "/releases/" name "-" version ".tar.xz"))
              (sha256
               (base32
                "1ianvr2a69yjv4rpyv30w7yjsmnsb23crrka5ndqxycj4rkk4dc4"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("glib" ,glib)))
    (home-page "http://www.freedesktop.org/wiki/Software/desktop-file-utils/")
    (synopsis "Utilities for working with desktop entries")
    (description
     "This package contains a few command line utilities for working with
desktop entries:

desktop-file-validate: validates a desktop file and prints warnings/errors
                       about desktop entry specification violations.

desktop-file-install: installs a desktop file to the applications directory,
                      optionally munging it a bit in transit.

update-desktop-database: updates the database containing a cache of MIME types
                         handled by desktop files.")
    (license license:gpl2+)))

(define-public gnome-icon-theme
  (package
    (name "gnome-icon-theme")
    (version "3.12.0")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnome/sources/" name "/"
                          (version-major+minor version)  "/"
                          name "-" version ".tar.xz"))
      (sha256
       (base32
        "0fjh9qmmgj34zlgxb09231ld7khys562qxbpsjlaplq2j85p57im"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("gtk+" ,gtk+) ; for gtk-update-icon-cache
       ("icon-naming-utils" ,icon-naming-utils)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (home-page "http://art.gnome.org/")
    (synopsis
     "GNOME icon theme")
    (description
     "Icons for the GNOME desktop.")
    (license license:lgpl3))) ; or Creative Commons BY-SA 3.0

;; gnome-icon-theme was renamed to adwaita-icon-theme after version 3.12.0.
(define-public adwaita-icon-theme
  (package (inherit gnome-icon-theme)
    (name "adwaita-icon-theme")
    (version "3.16.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1hmlw7kvhr7c2asc5y77adpymi9ka17gaf76zz835nwwffnn4rlw"))))))

(define-public shared-mime-info
  (package
    (name "shared-mime-info")
    (version "1.2")
    (source (origin
             (method url-fetch)
             (uri (string-append "http://freedesktop.org/~hadess/"
                                 "shared-mime-info-" version ".tar.xz"))
             (sha256
              (base32
               "0y5vi0vr6rbhvfzcfg57cfskn362bpvcpca9cy598nmr87i6lld5"))))
    (build-system gnu-build-system)
    (arguments
     ;; The build system appears not to be parallel-safe.
     '(#:parallel-build? #f))
    (inputs
     `(("glib" ,glib)
       ("libxml2" ,libxml2)))
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (home-page "http://freedesktop.org/wiki/Software/shared-mime-info")
    (synopsis "Database of common MIME types")
    (description
     "The shared-mime-info package contains the core database of common types
and the update-mime-database command used to extend it.  It requires glib2 to
be installed for building the update command.  Additionally, it uses intltool
for translations, though this is only a dependency for the maintainers.  This
database is translated at Transifex.")
    (license license:gpl2+)))

(define-public hicolor-icon-theme
  (package
    (name "hicolor-icon-theme")
    (version "0.12")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "http://icon-theme.freedesktop.org/releases/"
                          "hicolor-icon-theme-" version ".tar.gz"))
      (sha256
       (base32
        "0wzc7g4ldb2l8zc0x2785ck808c03i857jji942ikakyc68adp4y"))))
    (build-system gnu-build-system)
    (arguments
     `(#:tests? #f)) ; no check target
    (home-page "http://icon-theme.freedesktop.org/releases/")
    (synopsis
     "Freedesktop icon theme")
    (description
     "Freedesktop icon theme.")
    (license license:gpl2)))

(define-public libnotify
  (package
    (name "libnotify")
    (version "0.7.6")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnome/sources/" name "/"
                          (version-major+minor version)  "/"
                          name "-" version ".tar.xz"))
      (sha256
       (base32
        "0dyq8zgjnnzcah31axnx6afb21kl7bks1gvrg4hjh3nk02j1rxhf"))))
    (build-system gnu-build-system)
    (inputs
     `(("gdk-pixbuf" ,gdk-pixbuf)
       ("glib" ,glib)
       ("gtk+" ,gtk+)
       ("libpng" ,libpng)))
    (native-inputs
      `(("pkg-config" ,pkg-config)
        ("glib" ,glib "bin")))
    (home-page "https://developer-next.gnome.org/libnotify/")
    (synopsis
     "GNOME desktop notification library")
    (description
     "Libnotify is a library that sends desktop notifications to a
notification daemon, as defined in the Desktop Notifications spec.  These
notifications can be used to inform the user about an event or display
some form of information without getting in the user's way.")
    (license license:lgpl2.1+)))

(define-public libpeas
  (package
    (name "libpeas")
    (version "1.16.0")
    (source
     (origin
      (method url-fetch)
      (uri (string-append "mirror://gnome/sources/" name "/"
                          (version-major+minor version)  "/"
                          name "-" version ".tar.xz"))
      (sha256
       (base32
        "0kj5n5hz93xq7qdb2r7n86nibzwqjr88jxaih1fdbxv5rn7014xh"))))
    (build-system gnu-build-system)
    (inputs
     `(("atk" ,atk)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("glib" ,glib)
       ("gtk+" ,gtk+)
       ("pango" ,pango)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("glib:bin" ,glib "bin")
       ("gobject-introspection" ,gobject-introspection)
       ("intltool" ,intltool)))
    (home-page "https://wiki.gnome.org/Libpeas")
    (synopsis "GObject plugin system")
    (description
     "Libpeas is a gobject-based plugins engine, and is targetted at giving
every application the chance to assume its own extensibility.  It also has a
set of features including, but not limited to: multiple extension points; on
demand (lazy) programming language support for C, Python and JS; simplicity of
the API.")
    (license license:lgpl2.0+)))

(define-public gtkglext
  (package
    (name "gtkglext")
    (version "1.2.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://sourceforge/project/gtkglext/gtkglext/"
                                  version "/gtkglext-" version ".tar.gz"))
              (sha256
               (base32 "1ya4d2j2aacr9ii5zj4ac95fjpdvlm2rg79mgnk7yvl1dcy3y1z5"))
              (patches (list
                        (search-patch "gtkglext-disable-disable-deprecated.patch")))))
    (build-system gnu-build-system)
    (inputs `(("gtk+" ,gtk+-2)
              ("mesa" ,mesa)
              ("glu" ,glu)
              ("libx11" ,libx11)
              ("libxt" ,libxt)))
    (native-inputs `(("pkg-config" ,pkg-config)
                     ("glib" ,glib "bin")))
    (propagated-inputs `(("pangox-compat" ,pangox-compat)))
    (home-page "https://projects.gnome.org/gtkglext")
    (synopsis "OpenGL extension to GTK+")
    (description "GtkGLExt is an OpenGL extension to GTK+.  It provides
additional GDK objects which support OpenGL rendering in GTK+ and GtkWidget
API add-ons to make GTK+ widgets OpenGL-capable.")
    (license license:lgpl2.1+)))

(define-public glade3
  (package
    (name "glade")
    (version "3.8.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "3-" version ".tar.xz"))
              (sha256
               (base32 "021xgq2l18w3rvwms9aq2idm0fk66vwb4f777gs0qh3ap5shgbn7"))))
    (build-system gnu-build-system)
    (inputs
     `(("gtk+" ,gtk+-2)
       ("libxml2" ,libxml2)))
    (native-inputs
     `(("intltool" ,intltool)
       ("python" ,python)
       ("pkg-config" ,pkg-config)))
    (home-page "https://glade.gnome.org")
    (synopsis "GTK+ rapid application development tool")
    (description "Glade is a rapid application development (RAD) tool to
enable quick & easy development of user interfaces for the GTK+ toolkit and
the GNOME desktop environment.")
    (license license:lgpl2.0+)))

(define-public libcroco
  (package
    (name "libcroco")
    (version "0.6.8")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0w453f3nnkbkrly7spx5lx5pf6mwynzmd5qhszprq8amij2invpa"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("glib" ,glib)
       ("libxml2" ,libxml2)
       ("zlib" ,zlib)))
    (home-page "https://github.com/GNOME/libcroco")
    (synopsis "CSS2 parsing and manipulation library")
    (description
     "Libcroco is a standalone CSS2 parsing and manipulation library.
The parser provides a low level event driven SAC-like API and a CSS object
model like API.  Libcroco provides a CSS2 selection engine and an experimental
XML/CSS rendering engine.")

    ;; LGPLv2.1-only.
    (license license:lgpl2.1)))

(define-public libgsf
  (package
    (name "libgsf")
    (version "1.14.34")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0a5m1i5gp4m2z0cn2x1rrdm8wgrr04bzv65l8pgp6jipw13s9zph"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("python" ,python)
       ("zlib" ,zlib)
       ("bzip2" ,bzip2)))
    (propagated-inputs
     `(("gdk-pixbuf" ,gdk-pixbuf)
       ("glib" ,glib)
       ("libxml2" ,libxml2)))
    (home-page "http://www.gnome.org/projects/libgsf")
    (synopsis "GNOME's Structured File Library")
    (description
     "Libgsf aims to provide an efficient extensible I/O abstraction for
dealing with different structured file formats.")

    ;; LGPLv2.1-only.
    (license license:lgpl2.1)))

(define-public librsvg
  (package
    (name "librsvg")
    (version "2.40.11")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "00ifd9wjjjsw0ybk5j6qs4yyh66jj34hjmggy6dhrgfy8ksw06k1"))
              (patches
               (list (search-patch "librsvg-tests.patch")))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (alist-cons-before
        'configure 'augment-gir-search-path
        (lambda* (#:key inputs #:allow-other-keys)
          (substitute* "gdk-pixbuf-loader/Makefile.in"
            ;; By default the gdk-pixbuf loader is installed under
            ;; gdk-pixbuf's prefix.  Work around that.
            (("gdk_pixbuf_moduledir = .*$")
             (string-append "gdk_pixbuf_moduledir = "
                            "$(prefix)/lib/gdk-pixbuf-2.0/2.10.0/"
                             "loaders\n"))
            ;; Likewise, create a separate 'loaders.cache' file.
            (("gdk_pixbuf_cache_file = .*$")
             "gdk_pixbuf_cache_file = $(gdk_pixbuf_moduledir).cache\n")))
        (alist-cons-after
         'install 'generate-full-cache
         (lambda* (#:key inputs outputs #:allow-other-keys)
           (let ((loaders-directory
                  (string-append (assoc-ref outputs "out")
                                 "/lib/gdk-pixbuf-2.0/2.10.0/loaders")))
             (zero?
              (system
               (string-append
                "gdk-pixbuf-query-loaders "
                loaders-directory "/libpixbufloader-svg.so "
                (string-join (find-files (assoc-ref inputs "gdk-pixbuf")
                                         "libpixbufloader-.*\\.so") " ")
                "> " loaders-directory ".cache")))))
         %standard-phases))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("glib" ,glib "bin")                               ; glib-mkenums, etc.
       ("gobject-introspection" ,gobject-introspection))) ; g-ir-compiler, etc.
    (inputs
     `(("pango" ,pango)
       ("libcroco" ,libcroco)
       ("bzip2" ,bzip2)
       ("libgsf" ,libgsf)
       ("libxml2" ,libxml2)))
    (propagated-inputs
     ;; librsvg-2.0.pc refers to all of that.
     `(("cairo" ,cairo)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("glib" ,glib)))
    (home-page "https://wiki.gnome.org/LibRsvg")
    (synopsis "Render SVG files using Cairo")
    (description
     "Librsvg is a C library to render SVG files using the Cairo 2D graphics
library.")
    (license license:lgpl2.0+)))

(define-public libidl
  (package
    (name "libidl")
    (version "0.8.14")
    (source (origin
              (method url-fetch)
              (uri (let ((upstream-name "libIDL"))
		     (string-append "mirror://gnome/sources/" upstream-name "/"
                                    (version-major+minor version) "/"
                                    upstream-name "-" version ".tar.bz2")))
              (sha256
               (base32
                "08129my8s9fbrk0vqvnmx6ph4nid744g5vbwphzkaik51664vln5"))))
    (build-system gnu-build-system)
    (inputs `(("glib" ,glib)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("flex", flex)
       ("bison" ,bison)))
    (home-page "http://freecode.com/projects/libidl")
    (synopsis "Create trees of CORBA Interface Definition Language files")
    (description  "Libidl is a library for creating trees of CORBA Interface
Definition Language (idl) files, which is a specification for defining
portable interfaces. libidl was initially written for orbit (the orb from the
GNOME project, and the primary means of libidl distribution).  However, the
functionality was designed to be as reusable and portable as possible.")
    (license license:lgpl2.0+)))


(define-public orbit2
  (package
    (name "orbit2")
    (version "2.14.19")
    (source (origin
              (method url-fetch)
              (uri (let ((upstream-name "ORBit2"))
                     (string-append "mirror://gnome/sources/" upstream-name "/"
                                    (version-major+minor version) "/"
                                    upstream-name "-" version ".tar.bz2")))
              (sha256
               (base32
                "0l3mhpyym9m5iz09fz0rgiqxl2ym6kpkwpsp1xrr4aa80nlh1jam"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags
       ;; The programmer kindly gives us a hook to turn off deprecation
       ;; warnings ...
       '("DISABLE_DEPRECATED_CFLAGS=-DGLIB_DISABLE_DEPRECATION_WARNINGS")
       ;; ... which they then completly ignore !!
       #:phases
       (alist-cons-before
        'configure 'ignore-deprecations
        (lambda _
          (substitute* "linc2/src/Makefile.in"
            (("-DG_DISABLE_DEPRECATED") "-DGLIB_DISABLE_DEPRECATION_WARNINGS")))
        %standard-phases)))
    (inputs `(("glib" ,glib)
              ("libidl" ,libidl)))
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "https://projects.gnome.org/orbit2/")
    (synopsis "CORBA 2.4-compliant Object Request Broker")
    (description  "ORBit2 is a CORBA 2.4-compliant Object Request Broker (orb)
featuring mature C, C++ and Python bindings.")
    ;; Licence notice is unclear.  The Web page simply say "GPL" without giving
    ;; a version.  SOME of the code files have licence notices for GPLv2+.
    ;; The tarball contains files of the text of GPLv2 and LGPLv2.
    (license license:gpl2+)))


(define-public libbonobo
  (package
    (name "libbonobo")
    (version "2.32.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)
                                  "/" name "-" version ".tar.bz2"))
              (sha256
               (base32 "0swp4kk6x7hy1rvd1f9jba31lvfc6qvafkvbpg9h0r34fzrd8q4i"))
              (patches (list (search-patch "libbonobo-activation-test-race.patch")))))
    (build-system gnu-build-system)
    (arguments
     ;; The programmer kindly gives us a hook to turn off deprecation warnings ...
     `(#:configure-flags
       '("DISABLE_DEPRECATED_CFLAGS=-DGLIB_DISABLE_DEPRECATION_WARNINGS")
       ;; ... which they then completly ignore !!
       #:phases
       (alist-cons-before
        'configure 'ignore-deprecations
        (lambda _
          (substitute* "activation-server/Makefile.in"
            (("-DG_DISABLE_DEPRECATED") "-DGLIB_DISABLE_DEPRECATION_WARNINGS")))
        %standard-phases)))
    (inputs `(("popt" ,popt)
              ("libxml2" ,libxml2)))
    ;; The following are Required by the .pc file
    (propagated-inputs
     `(("glib" ,glib)
       ("orbit2" ,orbit2)))
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("glib" ,glib "bin")             ; for glib-genmarshal, etc.
       ("flex" ,flex)
       ("bison" ,bison)))
    (home-page "https://developer.gnome.org/libbonobo/")
    (synopsis "Framework for creating reusable components for use in GNOME applications")
    (description "Bonobo is a framework for creating reusable components for
use in GNOME applications, built on top of CORBA.")
    ;; Licence not explicitly stated.  Source files contain no licence notices.
    ;; Tarball contains text of both GPLv2 and LGPLv2
    ;; GPLv2 covers both conditions
    (license license:gpl2+)))


(define-public gconf
  (package
    (name "gconf")
    (version "3.2.6")
    (source (origin
              (method url-fetch)
              (uri
               (let ((upstream-name "GConf"))
                 (string-append "mirror://gnome/sources/" upstream-name "/"
                                (version-major+minor version) "/"
                                upstream-name "-" version ".tar.xz")))
              (sha256
               (base32 "0k3q9nh53yhc9qxf1zaicz4sk8p3kzq4ndjdsgpaa2db0ccbj4hr"))))
    (build-system gnu-build-system)
    (inputs `(("dbus-glib" ,dbus-glib)
              ("libxml2" ,libxml2)))
    (propagated-inputs `(("glib" ,glib) ; referred to in the .pc file
                         ("orbit2" ,orbit2)))
    (native-inputs
     `(("intltool" ,intltool)
       ("glib" ,glib "bin")             ; for glib-genmarshal, etc.
       ("pkg-config" ,pkg-config)))
    (home-page "https://projects.gnome.org/gconf/")
    (synopsis "Store application preferences")
    (description "Gconf is a system for storing application preferences.  It
is intended for user preferences; not arbitrary data storage.")
    (license license:lgpl2.0+)))


(define-public gnome-mime-data
  (package
    (name "gnome-mime-data")
    (version "2.18.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "1mvg8glb2a40yilmyabmb7fkbzlqd3i3d31kbkabqnq86xdnn69p"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("perl" ,perl)
       ("intltool" ,intltool)))
    (home-page "http://www.gnome.org")
    (synopsis "Base MIME and Application database for GNOME")
    (description  "GNOME Mime Data is a module which contains the base MIME
and Application database for GNOME.  The data stored by this module is
designed to be accessed through the MIME functions in GnomeVFS.")
    (license license:gpl2+)))


(define-public gnome-vfs
  (package
    (name "gnome-vfs")
    (version "2.24.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "1ajg8jb8k3snxc7rrgczlh8daxkjidmcv3zr9w809sq4p2sn9pk2"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (alist-cons-before
        'configure 'ignore-deprecations
        (lambda _
          (substitute* '("libgnomevfs/Makefile.in"
                         "daemon/Makefile.in")
            (("-DG_DISABLE_DEPRECATED") "-DGLIB_DISABLE_DEPRECATION_WARNINGS"))
          #t)
        (alist-cons-before
         'configure 'patch-test-async-cancel-to-never-fail
         (lambda _
           (substitute* "test/test-async-cancel.c"
             (("EXIT_FAILURE") "77")))
         %standard-phases))))
    (inputs `(("libxml2" ,libxml2)
              ("dbus-glib" ,dbus-glib)
              ("gconf" ,gconf)
              ("gnome-mime-data" ,gnome-mime-data)
              ("zlib" ,zlib)))
    (native-inputs
     `(("glib" ,glib "bin")             ; for glib-mkenums, etc.
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (home-page "https://developer.gnome.org/gnome-vfs/")
    (synopsis "Access files and folders in GNOME applications")
    (description
     "GnomeVFS is the core library used to access files and folders in GNOME
applications.  It provides a file system abstraction which allows applications
to access local and remote files with a single consistent API.")
    (license license:lgpl2.0+)))



(define-public libgnome
  (package
    (name "libgnome")
    (version "2.32.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "197pnq8y0knqjhm2fg4j6hbqqm3qfzfnd0irhwxpk1b4hqb3kimj"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (alist-cons-before
        'configure 'enable-deprecated
        (lambda _
          (substitute* "libgnome/Makefile.in"
            (("-DG_DISABLE_DEPRECATED") "-DGLIB_DISABLE_DEPRECATION_WARNINGS")))
        %standard-phases)))
    (inputs `(("libxml2" ,libxml2)))
    (native-inputs
     `(("glib" ,glib "bin")             ; for glib-mkenums, etc.
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    ;; The following are listed as Required in the .pc file
    ;; (except for libcanberra -- which seems to be oversight on the part
    ;; of the upstream developers -- anything that links against libgnome,
    ;; must also link against libcanberra
    (propagated-inputs
     `(("libcanberra" ,libcanberra)
       ("libbonobo" ,libbonobo)
       ("gconf" ,gconf)
       ("gnome-vfs" ,gnome-vfs)
       ("popt" ,popt)))                       ;gnome-program.h includes popt.h
    (home-page "https://developer.gnome.org/libgnome/")
    (synopsis "Useful routines for building applications")
    (description  "The libgnome library provides a number of useful routines
for building modern applications, including session management, activation of
files and URIs, and displaying help.")
    (license license:lgpl2.0+)))


(define-public libart-lgpl
  (package
    (name "libart-lgpl")
    (version "2.3.21")
    (source (origin
              (method url-fetch)
              (uri (let ((upstream-name "libart_lgpl"))
                     (string-append "mirror://gnome/sources/" upstream-name "/"
                                    (version-major+minor version) "/"
                                    upstream-name "-" version ".tar.bz2")))
              (sha256
               (base32
                "1yknfkyzgz9s616is0l9gp5aray0f2ry4dw533jgzj8gq5s1xhgx"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "https://people.gnome.org/~mathieu/libart")
    (synopsis "2D drawing library")
    (description  "Libart is a 2D drawing library intended as a
high-quality vector-based 2D library with antialiasing and alpha composition.")
    (license license:lgpl2.0+)))



(define-public libgnomecanvas
  (package
    (name "libgnomecanvas")
    (version "2.30.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.gz"))
              (sha256
               (base32
                "1nhnq4lfkk8ljkdafscwaggx0h95mq0rxnd7zgqyq0xb6kkqbjm8"))))
    (build-system gnu-build-system)
    ;; Mentioned as Required in the .pc file
    (propagated-inputs `(("libart-lgpl" ,libart-lgpl)
                         ("gtk+" ,gtk+-2)))
    (native-inputs
     `(("intltool" ,intltool)
       ("glib" ,glib "bin")             ; for glib-genmarshal, etc.
       ("pkg-config" ,pkg-config)))
    (home-page "https://developer.gnome.org/libgnomecanvas/")
    (synopsis "Flexible widget for creating interactive structured graphics")
    (description  "The GnomeCanvas widget provides a flexible widget for
creating interactive structured graphics.")
    (license license:lgpl2.0+)))

(define-public libgnomecanvasmm
  (package
    (name "libgnomecanvasmm")
    (version "2.26.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "0679hcnpam2gkag2i63sm0wdm35gwvzafnz1354mg6j5gzwpfrcr"))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags '("CXXFLAGS=-std=c++11"))) ; required by gtkmm
    (propagated-inputs `(("libgnomecanvas" ,libgnomecanvas)))
    (native-inputs
     `(("gtkmm-2" ,gtkmm-2)
       ("pkg-config" ,pkg-config)))
    (home-page "http://gtkmm.org")
    (synopsis "C++ bindings to the GNOME Canvas library")
    (description "C++ bindings to the GNOME Canvas library.")
    (license license:lgpl2.0+)))

(define-public libgnomeui
  (package
    (name "libgnomeui")
    (version "2.24.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "03rwbli76crkjl6gp422wrc9lqpl174k56cp9i96b7l8jlj2yddf"))))
    (build-system gnu-build-system)
    ;; Mentioned as Required in the .pc file
    (propagated-inputs `(("libbonoboui" ,libbonoboui)
                         ("libgnome" ,libgnome)
                         ("libgnomecanvas" ,libgnomecanvas)
                         ("libgnome-keyring" ,libgnome-keyring)))
    (inputs `(("libjpeg" ,libjpeg)
              ("popt" ,popt)
              ("libbonobo" ,libbonobo)
              ("libxml2" ,libxml2)
              ("libglade" ,libglade)))
    (native-inputs
     `(("glib" ,glib "bin")             ; for glib-mkenums, etc.
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (home-page "https://developer.gnome.org/libgnomeui/")
    (synopsis "Additional widgets for applications")
    (description "The libgnomeui library provides additional widgets for
applications.  Many of the widgets from libgnomeui have already been
ported to GTK+.")
    (license license:lgpl2.0+)))

(define-public libglade
  (package
    (name "libglade")
    (version "2.6.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "1v2x2s04jry4gpabws92i0wq2ghd47yr5n9nhgnkd7c38xv1wdk4"))))
    (build-system gnu-build-system)
    (inputs
     `(("python" ,python))) ;; needed for the optional libglade-convert program
    (propagated-inputs
     `(("gtk+-2" ,gtk+-2)
       ("libxml2" ,libxml2))) ; required by libglade-2.0.pc
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (home-page "https://developer.gnome.org/libglade")
    (synopsis "Load glade interfaces and access the glade built widgets")
    (description "Libglade is a library that provides interfaces for loading
graphical interfaces described in glade files and for accessing the
widgets built in the loading process.")
    (license license:gpl2+))) ; This is correct.  GPL not LGPL

(define-public libgnomeprint
  ;; This library has been deprecated since 2006; see
  ;; <https://mail.gnome.org/archives/devel-announce-list/2006-August/msg00005.html>.
  (package
    (name "libgnomeprint")
    (version "2.8.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "129ka3nn8gx9dlfry17ib79azxk45wzfv5rgqzw6dwx2b5ns8phm"))
              (modules '((guix build utils)))
              (snippet
               ;; Adapt to newer freetype. As the package is deprecated, there
               ;; is no use in creating a patch and reporting it.
               '(substitute* '("libgnomeprint/gnome-font-face.c"
                               "libgnomeprint/gnome-rfont.c")
                  (("freetype/") "freetype2/")))))
    (build-system gnu-build-system)
    (inputs
     `(("popt" ,popt)
       ("libart-lgpl" ,libart-lgpl)
       ("gtk+" ,gtk+-2)
       ("libxml2" ,libxml2)))
    (native-inputs
     `(("intltool" ,intltool)
       ("glib" ,glib "bin")             ; for glib-genmarshal, etc.
       ("pkg-config" ,pkg-config)))
    (home-page "https://projects.gnome.org/gnome-print/home/faq.html")
    (synopsis "Printing framework for GNOME")
    (description
     "GNOME-print was a printing framework for GNOME.  It has been deprecated
since ca. 2006, when GTK+ itself incorporated printing support.")
    (license license:lgpl2.0+)))


(define-public libgnomeprintui
  ;; Deprecated; see libgnomeprint.
  (package
    (name "libgnomeprintui")
    (version "2.8.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "1ivipk7r61rg90p9kp889j28xlyyj6466ypvwa4jvnrcllnaajsw"))))
    (build-system gnu-build-system)
    ;; Mentioned as Required in the .pc file
    (propagated-inputs `(("libgnomeprint" ,libgnomeprint)))
    (inputs `(("gtk+" ,gtk+-2)
              ("glib" ,glib)
              ("gnome-icon-theme" ,gnome-icon-theme)
              ("libgnomecanvas" ,libgnomecanvas)
              ("libxml2" ,libxml2)))
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (home-page "https://projects.gnome.org/gnome-print/home/faq.html")
    (synopsis "Printing framework for GNOME")
    (description (package-description libgnomeprint))
    (license license:lgpl2.0+)))

(define-public libbonoboui
  (package
    (name "libbonoboui")
    (version "2.24.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.bz2"))
              (sha256
               (base32
                "1kbgqh7bw0fdx4f1a1aqwpff7gp5mwhbaz60c6c98bc4djng5dgs"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (alist-cons-before
        'check 'start-xserver
        (lambda* (#:key inputs #:allow-other-keys)
          (let ((xorg-server (assoc-ref inputs "xorg-server"))
                (disp ":1"))

            (setenv "HOME" (getcwd))
            (setenv "DISPLAY" disp)
            ;; There must be a running X server and make check doesn't start one.
            ;; Therefore we must do it.
            (zero? (system (format #f "~a/bin/Xvfb ~a &" xorg-server disp)))))
        %standard-phases)))
    ;; Mentioned as Required by the .pc file
    (propagated-inputs `(("libxml2" ,libxml2)))
    (inputs
     `(("popt" ,popt)
       ("pangox-compat" ,pangox-compat)
       ("libgnome" ,libgnome)
       ("libgnomecanvas" ,libgnomecanvas)
       ("libglade" ,libglade)))
    (native-inputs
     `(("glib" ,glib "bin")             ; for glib-genmarshal, etc.
       ("intltool" ,intltool)
       ("xorg-server" ,xorg-server) ; For running the tests
       ("pkg-config" ,pkg-config)))
    (home-page "https://developer.gnome.org/libbonoboui/")
    (synopsis "Some user interface controls using Bonobo")
    (description  "The Bonobo UI library provides a number of user interface
controls using the Bonobo component framework.")
    (license license:lgpl2.0+)))

(define-public libwnck
  (package
    (name "libwnck")
    (version "3.14.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32 "074jww04z8g9r1acndqap79wx4kbm3rpkf4lcg1v82b66iv0027m"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (propagated-inputs
     `(("gtk+" ,gtk+)
       ("libxres" ,libxres)
       ("startup-notification" ,startup-notification)))
    (home-page "https://developer.gnome.org/libwnck/")
    (synopsis "Window Navigator Construction Kit")
    (description
     "Libwnck is the Window Navigator Construction Kit, a library for use in
writing pagers, tasklists, and more generally applications that are dealing
with window management.  It tries hard to respect the Extended Window Manager
Hints specification (EWMH).")
    (license license:lgpl2.0+)))

;; stable version for gtk2, required by xfwm4.
(define-public libwnck-1
  (package (inherit libwnck)
    (name "libwnck")
    (version "2.30.7")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "15713yl0f8f3p99jzqqfmbicrdswd3vwpx7r3bkf1bgh6d9lvs4b"))))
    (propagated-inputs
     `(("gtk+" ,gtk+-2)
       ("libxres" ,libxres)
       ("startup-notification" ,startup-notification)))))

(define-public goffice
  (package
    (name "goffice")
    (version "0.10.14")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32 "0kj0iwng6w4axm7yv2zy7myn5dhw5ilrlq2pzrjlm9i852ikqy60"))))
    (build-system gnu-build-system)
    (inputs
     `(("gtk+" ,gtk+)
       ("libgsf" ,libgsf)
       ("librsvg" ,librsvg)
       ("libxslt" ,libxslt)
       ("libxml2" ,libxml2)))
    (native-inputs
     `(("intltool" ,intltool)
       ("glib" ,glib "bin")
       ("pkg-config" ,pkg-config)))
    (home-page "https://developer.gnome.org/goffice/")
    (synopsis "Document-centric objects and utilities")
    (description "A GLib/GTK+ set of document-centric objects and utilities.")
    (license
     ;; Dual licensed under GPLv2 or GPLv3 (both without "or later")
     ;; Note: NOT LGPL
     (list license:gpl2 license:gpl3))))

(define-public goffice-0.8
  (package (inherit goffice)
    (version "0.8.17")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" (package-name goffice) "/"
                                  (version-major+minor version)  "/"
                                  (package-name goffice) "-" version ".tar.xz"))
              (sha256
               (base32 "05fvzbs5bin05bbsr4dp79aiva3lnq0a3a40zq55i13vnsz70l0n"))))
    (arguments
     `(#:phases
       (alist-cons-after
        'unpack 'fix-pcre-check
        (lambda _
          ;; Only glib.h can be included directly.  See
          ;; https://bugzilla.gnome.org/show_bug.cgi?id=670316
          (substitute* "configure"
            (("glib/gregex\\.h") "glib.h")) #t)
        %standard-phases)))
    (propagated-inputs
     ;; libgoffice-0.8.pc mentions libgsf-1
     `(("libgsf" ,libgsf)))
    (inputs
     `(("gtk" ,gtk+-2)
       ,@(alist-delete "gtk" (package-inputs goffice))))))

(define-public gnumeric
  (package
    (name "gnumeric")
    (version "1.12.17")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version)  "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "18bvc3phghr4p5440fp8hm6gvp53d3mqs9cyc637zpmk0b6bcp7c"))))
    (build-system gnu-build-system)
    (arguments
     `(;; The gnumeric developers don't worry much about failing tests.
       ;; See https://bugzilla.gnome.org/show_bug.cgi?id=732387
       #:tests? #f
       #:phases
       (alist-cons-before
        'configure 'pre-conf
        (lambda* (#:key outputs #:allow-other-keys)
          ;; Make install tries to write into the directory of goffice
          ;; I am informed that this only affects the possibility to embed a
          ;; spreadsheet inside an Abiword document.   So presumably when we
          ;; package Abiword we'll have to refer it to this directory.
          (substitute* "configure"
            (("^GOFFICE_PLUGINS_DIR=.*")
             (string-append "GOFFICE_PLUGINS_DIR="
                            (assoc-ref outputs "out") "/goffice/plugins"))))
        %standard-phases)))
    (inputs
     `(("glib" ,glib)
       ("gtk+" ,gtk+)
       ("goffice" ,goffice)
       ("libgsf" ,libgsf)
       ("libxml2" ,libxml2)
       ("zlib" ,zlib)))
    (native-inputs
     `(("intltool" ,intltool)
       ("glib:bin" ,glib "bin")
       ("pkg-config" ,pkg-config)))
    (home-page "http://www.gnumeric.org")
    (synopsis "Spreadsheet application")
    (description
     "GNUmeric is a GNU spreadsheet application, running under GNOME.  It is
interoperable with other spreadsheet applications.  It has a vast array of
features beyond typical spreadsheet functionality, such as support for linear
and non-linear solvers, statistical analysis, and telecommunication
engineering.")
    (license
    ;; Dual licensed under GPLv2 or GPLv3 (both without "or later")
     (list license:gpl2 license:gpl3))))

(define-public gnome-themes-standard
  (package
    (name "gnome-themes-standard")
    (version "3.18.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/" name "-"
                           version ".tar.xz"))
       (sha256
        (base32
         "1jxss8kxszhf66vic9n1sagczm5amm0mgxpzyxyjna15q82fnip6"))))
    (build-system gnu-build-system)
    (inputs
     `(("gtk+" ,gtk+)
       ("gtk+-2" ,gtk+-2)
       ("librsvg" ,librsvg)
       ("libxml2" ,libxml2)
       ("glib" ,glib)))
    (native-inputs
     `(("intltool" ,intltool)
       ("glib:bin" ,glib "bin")
       ("pkg-config" ,pkg-config)))
    (arguments
     `(#:phases
       (alist-cons-before
        'build 'use-full-cache
        ;; Use librsvg's loaders.cache instead of the one provided by
        ;; gdk-pixbuf because the latter does not include support for SVG
        ;; files.
        (lambda* (#:key inputs #:allow-other-keys)
          (setenv "GDK_PIXBUF_MODULE_FILE"
                  (car (find-files (assoc-ref inputs "librsvg")
                                   "loaders\\.cache"))))
        %standard-phases)))
    (home-page "https://launchpad.net/gnome-themes-standard")
    (synopsis "Default GNOME 3 themes")
    (description
     "The default GNOME 3 themes (Adwaita and some accessibility themes).")
    (license license:lgpl2.1+)))

(define-public seahorse
  (package
    (name "seahorse")
    (version "3.16.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/" name "-"
                           version ".tar.xz"))
       (sha256
        (base32
         "0cg1grgpwbfkiny5148n17rzpc8kswyr5yff0kpm8l3lp01my2kp"))))
    (build-system glib-or-gtk-build-system)
    (inputs
     `(("gtk+" ,gtk+)
       ("gcr" ,gcr)
       ("gnupg" ,gnupg-1)
       ("gpgme" ,gpgme)
       ("openssh" ,openssh)
       ("libsecret" ,libsecret)))
    (native-inputs
     `(("intltool" ,intltool)
       ("glib:bin" ,glib "bin")
       ("itstool" ,itstool)
       ("pkg-config" ,pkg-config)
       ("xmllint" ,libxml2)))
    (home-page "https://launchpad.net/gnome-themes-standard")
    (synopsis "Manage encryption keys and passwords in the GNOME keyring")
    (description
     "Seahorse is a GNOME application for managing encryption keys and
passwords in the GNOME keyring.")
    (license license:gpl2+)))

(define-public vala
  (package
    (name "vala")
    (version "0.30.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1pyyhfw3zzbhxfscbn8xz70dg6vx0kh8gshzikpxczhg01xk7w31"))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (add-before 'check 'pre-check
                     (lambda _
                       (setenv "CC" "gcc")
                       ;; For missing '/etc/machine-id'.
                       (setenv "DBUS_FATAL_WARNINGS" "0")
                       #t)))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("flex" ,flex)
       ("bison" ,bison)
       ("xsltproc" ,libxslt)
       ("dbus" ,dbus)                                     ; for dbus tests
       ("gobject-introspection" ,gobject-introspection))) ; for gir tests
    (propagated-inputs
     `(("glib" ,glib))) ; required by libvala-0.26.pc
    (home-page "http://live.gnome.org/Vala/")
    (synopsis "Compiler for the GObject type system")
    (description
     "Vala is a programming language that aims to bring modern programming
language features to GNOME developers without imposing any additional runtime
requirements and without using a different ABI compared to applications and
libraries written in C.")
    (license license:lgpl2.1+)))

(define-public vte
  (package
    (name "vte")
    (version "0.40.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0lnq0bgkmsixjwmfacb2ch9qfjqjxa8zkk1hiv3l29kgca0n3nal"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)
       ("vala" ,vala)
       ("gobject-introspection" ,gobject-introspection)
       ("glib" ,glib "bin") ; for glib-genmarshal, etc.
       ("xmllint" ,libxml2)))
    (propagated-inputs
     `(("gtk+" ,gtk+)                             ;required by vte-2.91.pc
       ("gnutls" ,gnutls)))                       ;ditto
    (home-page "http://www.gnome.org/")
    (synopsis "Virtual Terminal Emulator")
    (description
     "VTE is a library (libvte) implementing a terminal emulator widget for
GTK+, and a minimal sample application (vte) using that.  Vte is mainly used in
gnome-terminal, but can also be used to embed a console/terminal in games,
editors, IDEs, etc.")
    (license license:lgpl2.1+)))

;; provides vte 2.90, required for some terminal emulators
;; tilda bug: https://github.com/lanoxx/tilda/issues/94
;; pantheon-terminal bug: https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=788021
;; roxterm bug: http://sourceforge.net/p/roxterm/bugs/107/
;; pantheon-terminal, roxterm are not currently packaged
(define-public vte-0.36
  (package (inherit vte)
    (name "vte")
    (version "0.36.5")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1psfnqsmxx4qzc55qwvb8jai824ix4pqcdqhgxk0g2zh82bcxhn2"))))
    (propagated-inputs
     `(("gtk" ,gtk+)
       ("ncurses" ,ncurses)))))

;; stable version for gtk2, required by xfce4-terminal.
(define-public vte/gtk+-2
  (package (inherit vte)
    (name "vte")
    (version "0.28.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1bmhahkf8wdsra9whd3k5l5z4rv7r58ksr8mshzajgq2ma0hpkw6"))))
    (arguments
     '(#:configure-flags '("--disable-python")))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)
       ("glib" ,glib "bin")))   ; for glib-genmarshal, etc.
    (propagated-inputs
     `(("gtk+" ,gtk+-2)         ; required by libvte.pc
       ("ncurses" ,ncurses))))) ; required by libvte.la

(define-public dconf
  (package
    (name "dconf")
    (version "0.22.0")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://gnome/sources/" name "/"
                    (version-major+minor version) "/"
                    name "-" version ".tar.xz"))
              (sha256
               (base32 "13jb49504bir814v8n8vjip5sazwfwsrnniw87cpg7phqfq7q9qa"))))
    (build-system glib-or-gtk-build-system)
    (inputs
     `(("gtk+" ,gtk+)
       ("glib" ,glib)
       ("dbus" ,dbus)
       ("libxml2" ,libxml2)))
    (native-inputs
     `(("libxslt" ,libxslt)
       ("docbook-xml" ,docbook-xml-4.2)
       ("docbook-xsl" ,docbook-xsl)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (arguments
     `(#:tests? #f ; To contact dbus it needs to load /var/lib/dbus/machine-id
                   ; or /etc/machine-id.
       #:configure-flags
       ;; Set the correct RUNPATH in binaries.
       (list (string-append "LDFLAGS=-Wl,-rpath="
                            (assoc-ref %outputs "out") "/lib")
             "--disable-gtk-doc-html") ; FIXME: requires gtk-doc
       #:phases
       (alist-cons-before
        'configure 'fix-docbook
        (lambda* (#:key inputs #:allow-other-keys)
          (substitute* "docs/Makefile.in"
            (("http://docbook.sourceforge.net/release/xsl/current/manpages/docbook.xsl")
             (string-append (assoc-ref inputs "docbook-xsl")
                            "/xml/xsl/docbook-xsl-"
                            ,(package-version docbook-xsl)
                            "/manpages/docbook.xsl")))
          (setenv "XML_CATALOG_FILES"
                  (string-append (assoc-ref inputs "docbook-xml")
                                 "/xml/dtd/docbook/catalog.xml")))
        %standard-phases)))
    (home-page "https://developer.gnome.org/dconf")
    (synopsis "Low-level GNOME configuration system")
    (description "Dconf is a low-level configuration system.  Its main purpose
is to provide a backend to GSettings on platforms that don't already have
configuration storage systems.")
    (license license:lgpl2.1)))

(define-public json-glib
  (package
    (name "json-glib")
    (version "1.0.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1k85vvb2prmk8aa8hmr2rp9rnbhffjgnmr18b13g24xxnqy5kww0"))
              (modules '((guix build utils)))
              (snippet
               ;; Don't duplicate test names.
               ;; <https://bugzilla.gnome.org/show_bug.cgi?id=755977>.
               '(substitute* "json-glib/tests/builder.c"
                  (("\"/builder/complex\", test_builder_empty")
                   "\"/builder/empty\", test_builder_empty")))))
    (build-system gnu-build-system)
    (native-inputs
     `(("glib" ,glib "bin")              ;for glib-mkenums and glib-genmarshal
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("glib" ,glib)))                         ;according to json-glib-1.0.pc
    (home-page "https://wiki.gnome.org/Projects/JsonGlib")
    (synopsis "Compiler for the GObject type system")
    (description
     "JSON-GLib is a C library based on GLib providing serialization and
deserialization support for the JavaScript Object Notation (JSON) format
described by RFC 4627.  It provides parser and generator GObject classes and
various wrappers for the complex data types employed by JSON, such as arrays
and objects.")
    (license license:lgpl2.1+)))

(define-public libxklavier
  (package
    (name "libxklavier")
    (version "5.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  version "/" name "-" version ".tar.xz"))
              (sha256
               (base32
                "016lpdv35z0qsw1cprdc2k5qzkdi5waj6qmr0a2q6ljn9g2kpv7b"))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags
       (list (string-append "--with-xkb-base="
                            (assoc-ref %build-inputs "xkeyboard-config")
                            "/share/X11/xkb"))))
    (native-inputs
     `(("glib:bin"              ,glib "bin") ; for glib-mkenums, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config"            ,pkg-config)))
    (propagated-inputs
     ;; Required by libxklavier.pc.
     `(("glib"    ,glib)
       ("libxml2" ,libxml2)))
    (inputs
     `(("iso-codes"        ,iso-codes)
       ("libxi"            ,libxi)
       ("libxkbfile"       ,libxkbfile)
       ("xkbcomp"          ,xkbcomp)
       ("xkeyboard-config" ,xkeyboard-config)))
    (home-page "http://www.freedesktop.org/wiki/Software/LibXklavier/")
    (synopsis "High-level API for X Keyboard Extension")
    (description
     "LibXklavier is a library providing high-level API for X Keyboard
Extension known as XKB.  This library is intended to support XFree86 and other
commercial X servers.  It is useful for creating XKB-related software (layout
indicators etc).")
    (license license:lgpl2.0+)))

(define-public python2-rsvg
  ;; XXX: This is actually a subset of gnome-python-desktop.
  (package
    (name "python2-rsvg")
    (version "2.32.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append
             "mirror://gnome/sources/gnome-python-desktop/2.32/gnome-python-desktop-"
             version ".tar.bz2"))
       (sha256
        (base32
         "1s8f9rns9v7qlwjv9qh9lr8crp88dpzfm45hj47zc3ivpy0dbnq9"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (inputs
     `(("python" ,python-2)
       ("python2-pygtk" ,python2-pygtk)
       ("librsvg" ,librsvg)))
    (home-page "http://www.gnome.org")
    (synopsis "Python bindings to librsvg")
    (description
     "This packages provides Python bindings to librsvg, the SVG rendering
library.")

    ;; This is the license of the rsvg bindings.  The license of each module
    ;; of gnome-python-desktop is given in 'COPYING'.
    (license license:lgpl2.1+)))

(define-public glib-networking
  (package
    (name "glib-networking")
    (version "2.46.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/glib-networking/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1cchmi08jpjypgmm9i7xzh5qfg2q5k61kry9ns8mhw3z44a440ym"))
              (patches
               (list (search-patch "glib-networking-ssl-cert-file.patch")))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags
       '("--with-ca-certificates=/etc/ssl/certs/ca-certificates.crt")
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-giomoduledir
                     ;; Install GIO modules into $out/lib/gio/modules.
                     (lambda _
                       (substitute* "configure"
                         (("GIO_MODULE_DIR=.*")
                          (string-append "GIO_MODULE_DIR=" %output
                                         "/lib/gio/modules\n")))))
         (add-before 'check 'use-empty-ssl-cert-file
                     (lambda _
                       ;; The ca-certificates.crt is not available in the build
                       ;; environment.
                       (setenv "SSL_CERT_FILE" "/dev/null")
                       #t)))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("glib" ,glib)
       ("gnutls" ,gnutls)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("p11-kit" ,p11-kit)))
    (home-page "http://www.gnome.org")
    (synopsis "Network-related GIO modules")
    (description
     "This package contains various network related extensions for the GIO
library.")
    (license license:lgpl2.0+)))

(define-public rest
  (package
    (name "rest")
    (version "0.7.93")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/rest/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "05mj10hhiik23ai8w4wkk5vhsp7hcv24bih5q3fl82ilam268467"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f ; tests require internet connection
       #:configure-flags
       '("--with-ca-certificates=/etc/ssl/certs/ca-certificates.crt")))
    (native-inputs
     `(("glib-mkenums" ,glib "bin")
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     ;; rest-0.7.pc refers to all these.
     `(("glib"    ,glib)
       ("libsoup" ,libsoup)
       ("libxml2" ,libxml2)))
    (home-page "http://www.gtk.org/")
    (synopsis "RESTful web api query library")
    (description
     "This library was designed to make it easier to access web services that
claim to be \"RESTful\".  It includes convenience wrappers for libsoup and
libxml to ease remote use of the RESTful API.")
    (license license:lgpl2.1+)))

(define-public libsoup
  (package
    (name "libsoup")
    (version "2.52.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/libsoup/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0j6cnnpqqgnb9nj2r0j8j6898np4z503hrnpis7b4l5d8yhbq68f"))))
    (build-system gnu-build-system)
    (outputs '("out" "doc"))
    (arguments
     `(#:configure-flags
       (list (string-append "--with-html-dir="
                            (assoc-ref %outputs "doc")
                            "/share/gtk-doc/html"))
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'disable-unconnected-socket-test
                     ;; This test fails due to missing /etc/nsswitch.conf
                     ;; in the build environment.
                     (lambda _
                       (substitute* "tests/socket-test.c"
                         ((".*/sockets/unconnected.*") ""))
                       #t))
         (add-before 'check 'pre-check
                     (lambda _
                       ;; The 'check-local' target runs 'env LANG=C sort -u',
                       ;; unset 'LC_ALL' to make 'LANG' working.
                       (unsetenv "LC_ALL")
                       ;; The ca-certificates.crt is not available in the build
                       ;; environment.
                       (setenv "SSL_CERT_FILE" "/dev/null")
                       #t))
         (replace 'install
                  (lambda _
                    (zero?
                     (system* "make"
                              ;; Install vala bindings into $out.
                              (string-append "vapidir=" %output
                                             "/share/vala/vapi")
                              "install")))))))
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-mkenums
       ("gobject-introspection" ,gobject-introspection)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("python" ,python-wrapper)
       ("vala" ,vala)
       ;; These are needed for the tests.
       ;; FIXME: Add PHP once available.
       ("curl" ,curl)
       ("httpd" ,httpd)))
    (propagated-inputs
     ;; libsoup-2.4.pc refers to all these.
     `(("glib" ,glib)
       ("libxml2" ,libxml2)))
    (inputs
     `(("glib-networking" ,glib-networking)
       ("sqlite" ,sqlite)))
    (home-page "https://live.gnome.org/LibSoup/")
    (synopsis "GLib-based HTTP Library")
    (description
     "LibSoup is an HTTP client/server library for GNOME.  It uses GObjects
and the GLib main loop, to integrate well with GNOME applications.")
    (license license:lgpl2.0+)))

(define-public libsecret
  (package
    (name "libsecret")
    (version "0.18")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://gnome/sources/libsecret/" version "/"
                    name "-" version ".tar.xz"))
              (sha256
               (base32
                "1qq29c01xxjyx5sl6y5h22w8r0ff4c73bph3gfx3h7mx5mvalwqc"))))
    (build-system gnu-build-system)
    (outputs '("out" "doc"))
    (arguments
     `(#:tests? #f ; FIXME: Testing hangs.
       #:configure-flags
       (list (string-append "--with-html-dir="
                            (assoc-ref %outputs "doc")
                            "/share/gtk-doc/html"))))
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for gdbus-codegen, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("vala" ,vala)
       ("xsltproc" ,libxslt)))
       ;; These are needed for the tests.
       ;; FIXME: Add gjs once available.
       ;("dbus" ,dbus)
       ;("python2" ,python-2)
       ;("python2-dbus" ,python2-dbus)
       ;("python2-pygobject" ,python2-pygobject)
       ;("python2-pygobject-2" ,python2-pygobject-2)))
    (propagated-inputs
     `(("glib" ,glib))) ; required by libsecret-1.pc
    (inputs
     `(("docbook-xsl" ,docbook-xsl)
       ("libgcrypt" ,libgcrypt)
       ("libxml2" ,libxml2))) ; for XML_CATALOG_FILES
    (home-page "https://wiki.gnome.org/Projects/Libsecret/")
    (synopsis "GObject bindings for \"Secret Service\" API")
    (description
     "Libsecret is a GObject based library for storing and retrieving passwords
and other secrets.  It communicates with the \"Secret Service\" using DBus.")
    (license license:lgpl2.1+)))

(define-public gnome-mines
  (package
    (name "gnome-mines")
    (version "3.16.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "0wfvqyryc1093l4dr75zv9h0jyn28z6wirdq03lm5w24qf9lvjjx"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-/bin/true
                     (lambda _
                       (substitute* "configure"
                         (("/bin/true") (which "true")))))
         (add-after 'install 'wrap-pixbuf
                    ;; Use librsvg's loaders.cache to support SVG files.
                    (lambda* (#:key inputs outputs #:allow-other-keys)
                      (let* ((out    (assoc-ref outputs "out"))
                             (prog   (string-append out "/bin/gnome-mines"))
                             (rsvg   (assoc-ref inputs "librsvg"))
                             (pixbuf (find-files rsvg "^loaders\\.cache$")))
                        (wrap-program prog
                          `("GDK_PIXBUF_MODULE_FILE" = ,pixbuf))))))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("desktop-file-utils" ,desktop-file-utils)
       ("intltool" ,intltool)
       ("itstool" ,itstool)
       ("xmllint" ,libxml2)))
    (inputs
     `(("gtk+" ,gtk+)
       ("librsvg" ,librsvg)))
    (home-page "https://wiki.gnome.org/Apps/Mines")
    (synopsis "Minesweeper game")
    (description
     "Mines (previously gnomine) is a puzzle game where you locate mines
floating in an ocean using only your brain and a little bit of luck.")
    (license license:gpl2+)))

(define-public gnome-terminal
  (package
    (name "gnome-terminal")
    (version "3.16.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "1s3zwqxs4crlqmh6l7s7n87pbmh2nnjdvhxlkalh58pbl0bk0qrd"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '(#:configure-flags
       (list "--disable-migration" "--disable-search-provider"
             "--without-nautilus-extension")
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-/bin/true
                     (lambda _
                       (substitute* "configure"
                         (("/bin/true") (which "true"))))))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("desktop-file-utils" ,desktop-file-utils)
       ("intltool" ,intltool)
       ("itstool" ,itstool)
       ("xmllint" ,libxml2)))
    (propagated-inputs
     `(("dconf" ,dconf)))
    (inputs
     `(("gtk+" ,gtk+)
       ("vte" ,vte)
       ("gnutls" ,gnutls)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("util-linux" ,util-linux)
       ("vala" ,vala)))
    (home-page "https://wiki.gnome.org/Apps/Terminal")
    (synopsis "Terminal emulator")
    (description
     "GNOME Terminal is a terminal emulator application for accessing a
UNIX shell environment which can be used to run programs available on
your system.

It supports several profiles, multiple tabs and implements several
keyboard shortcuts.")
    (license license:gpl3+)))

(define-public colord
  (package
    (name "colord")
    (version "1.1.8")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://www.freedesktop.org/software/colord/releases/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "01w97rgzk4qi6fp03scq5jyw0ayx11b479p7dkm2r77k84b9agph"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '(;; The tests want to run valgrind.  Punt for now.
       #:tests? #f
       #:configure-flags (list "--localstatedir=/var"
                               ;; GUSB not packaged yet.
                               "--disable-gusb"
                               ;; No dep on systemd.
                               "--disable-systemd-login"
                               ;; Wants to install to global completion dir;
                               ;; punt.
                               "--disable-bash-completion"
                               ;; colord-gtk not packaged yet.
                               "--disable-session-example"
                               "--with-daemon-user=colord"
                               "--enable-sane"
                               (string-append "--with-udevrulesdir="
                                              (assoc-ref %outputs "out")
                                              "/lib/udev/rules.d"))
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-/bin/true
                     (lambda _
                       (substitute* "configure"
                         (("/bin/true") (which "true")))
                       (substitute* "src/Makefile.in"
                         (("if test -w \\$\\(DESTDIR\\)\\$\\(prefix\\)/;")
                          "if test -w $(DESTDIR)$(localstatedir);")))))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("gobject-introspection" ,gobject-introspection)
       ("libtool" ,libtool)
       ("intltool" ,intltool)))
    (propagated-inputs
     ;; colord.pc refers to all these.
     `(("glib" ,glib)
       ("udev" ,eudev)
       ("lcms" ,lcms)))
    (inputs
     `(("dbus-glib" ,dbus-glib)
       ("libgudev" ,libgudev)
       ("libusb" ,libusb)
       ("sqlite" ,sqlite)
       ("polkit" ,polkit)
       ("sane-backends" ,sane-backends)))
    (home-page "http://www.freedesktop.org/software/colord/")
    (synopsis "Color management service")
    (description "Colord is a system service that makes it easy to manage,
install and generate color profiles to accurately color manage input and
output devices.")
    (license license:gpl2+)))

(define-public geoclue
  (package
    (name "geoclue")
    (version "2.2.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "http://www.freedesktop.org/software/" name
                           "/releases/" (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "0inlqx0zar498fhi9hh92p2g4kp8qy3zdl4z3vw6bjwp9w6xx454"))
       (patches (list (search-patch "geoclue-config.patch")))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '(;; The tests want to run the system bus.
       #:tests? #f
       #:configure-flags (list ;; Disable bits requiring ModemManager.
                               "--disable-3g-source"
                               "--disable-cdma-source"
                               "--disable-modem-gps-source"
                               "--with-dbus-service-user=geoclue")
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-/bin/true
                     (lambda _
                       (substitute* "configure"
                         (("/bin/true") (which "true"))))))))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (inputs
     `(("glib" ,glib)
       ("json-glib" ,json-glib)
       ("libsoup" ,libsoup)))
    (home-page "http://freedesktop.org/wiki/Software/GeoClue/")
    (synopsis "Geolocation service")
    (description "Geoclue is a D-Bus service that provides location
information.  The primary goal of the Geoclue project is to make creating
location-aware applications as simple as possible, while the secondary goal is
to ensure that no application can access location information without explicit
permission from user.")
    (license license:gpl2+)))

(define-public geocode-glib
  (package
    (name "geocode-glib")
    (version "3.16.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/geocode-glib/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1cbfv0kds6b6k0cl7q47xpj3x1scwcd7m68zl1rf7i4hmhw4hpqj"))))
    (build-system gnu-build-system)
    (arguments
     `(;; The tests want to write to $HOME/.cache/geocode-glib, which doesn't
       ;; work for the builder.  Punt.
       #:tests? #f))
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-mkenums
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)
       ("json-glib" ,json-glib)))
    (propagated-inputs
     ;; geocode-glib-1.0.pc refers to GIO.
     `(("glib" ,glib)))
    (inputs
     `(("libsoup" ,libsoup)))
    (home-page "https://github.com/GNOME/geocode-glib/")
    (synopsis "Geocoding and reverse-geocoding library")
    (description
     "geocode-glib is a convenience library for geocoding (finding longitude,
and latitude from an address) and reverse geocoding (finding an address from
coordinates) using the Nominatim service.  geocode-glib caches requests for
faster results and to avoid unnecessary server load.")
    (license license:lgpl2.0+)))

(define-public upower
  (package
    (name "upower")
    (version "0.99.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://upower.freedesktop.org/releases/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0f6x9mi1jzgqdpycaikyhjljnw3aacsl3gxndyg0dfqkq6y9jwb9"))
              (patches (list (search-patch "upower-builddir.patch")))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '( ;; The tests want to contact the system bus, which can't be done in the
       ;; build environment.  The integration test can run, but the last of
       ;; the up-self-tests doesn't.  Disable tests for now.
       #:tests? #f
       #:configure-flags (list "--localstatedir=/var"
                               (string-append "--with-udevrulesdir="
                                              (assoc-ref %outputs "out")
                                              "/lib/udev/rules.d"))
       #:phases
       (modify-phases %standard-phases
         (add-before 'configure 'patch-/bin/true
                     (lambda _
                       (substitute* "configure"
                         (("/bin/true") (which "true")))))
         (add-before 'configure 'patch-integration-test
                     (lambda _
                       (substitute* "src/linux/integration-test"
                         (("/usr/bin/python3") (which "python3"))))))))
    (native-inputs
     `(("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)
       ("intltool" ,intltool)
       ("python" ,python)))
    (inputs
     `(("dbus-glib" ,dbus-glib)
       ("libgudev" ,libgudev)
       ("libusb" ,libusb)))
    (home-page "http://upower.freedesktop.org/")
    (synopsis "System daemon for managing power devices")
    (description
     "UPower is an abstraction for enumerating power devices,
listening to device events and querying history and statistics.  Any
application or service on the system can access the org.freedesktop.UPower
service via the system message bus.")
    (license license:gpl2+)))

(define-public libgweather
  (package
    (name "libgweather")
    (version "3.18.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1l3sra84k5dnavbdbjyf1ar84xmjszpnnldih6mf45kniwpjkcll"))))
    (build-system gnu-build-system)
    (arguments
     `(#:configure-flags
       `(,(string-append "--with-zoneinfo-dir="
                         (assoc-ref %build-inputs "tzdata")
                         "/share/zoneinfo"))
       #:phases
       (modify-phases %standard-phases
         (add-before
          'check 'pre-check
          (lambda* (#:key inputs #:allow-other-keys)
            (substitute* "data/check-timezones.sh"
              (("/usr/share/zoneinfo/zone.tab")
               (string-append (assoc-ref inputs "tzdata")
                              "/share/zoneinfo/zone.tab")))
            #t)))))
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-mkenums
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)
       ("intltool" ,intltool)))
    (propagated-inputs
     ;; gweather-3.0.pc refers to GTK+, GDK-Pixbuf, GLib/GObject, libxml, and
     ;; libsoup.
     `(("gtk+" ,gtk+)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("libxml2" ,libxml2)
       ("libsoup" ,libsoup)))
    (inputs
     `(("tzdata" ,tzdata)
       ("geocode-glib" ,geocode-glib)))
    (home-page "https://wiki.gnome.org/action/show/Projects/LibGWeather")
    (synopsis "Location, time zone, and weather library for GNOME")
    (description
     "libgweather is a library to access weather information from online
services for numerous locations.")
    (license license:gpl2+)))

(define-public gnome-settings-daemon
  (package
    (name "gnome-settings-daemon")
    (version "3.16.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "1w29x2izq59125ga5ncmmaklc8kw7x7rdn6swn26bs23mah1r1g3"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     `(;; Network manager not yet packaged.
       #:configure-flags '("--disable-network-manager")
       ;; Color management test can't reach the colord system service.
       #:tests? #f))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("intltool" ,intltool)
       ("xsltproc" ,libxslt)
       ("libxml2" ,libxml2)                       ;for XML_CATALOG_FILES
       ("docbook-xml" ,docbook-xml-4.2)
       ("docbook-xsl" ,docbook-xsl)))
    (inputs
     `(("colord" ,colord)
       ("libgudev" ,libgudev)
       ("upower" ,upower)
       ("polkit" ,polkit)
       ("pulseaudio" ,pulseaudio)
       ("libcanberra" ,libcanberra)
       ("libx11" ,libx11)
       ("libxtst" ,libxtst)
       ("lcms" ,lcms)
       ("libnotify" ,libnotify)
       ("geoclue" ,geoclue)
       ("geocode-glib" ,geocode-glib)
       ("libgweather" ,libgweather)
       ("gnome-desktop" ,gnome-desktop)
       ("nss" ,nss)
       ("cups" ,cups)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("libwacom" ,libwacom)
       ("librsvg" ,librsvg)
       ("xf86-input-wacom" ,xf86-input-wacom)))
    (home-page "http://www.gnome.org")
    (synopsis "GNOME settings daemon")
    (description
     "This package contains the daemon responsible for setting the various
parameters of a GNOME session and the applications that run under it.  It
handles settings such keyboard layout, shortcuts, and accessibility, clipboard
settings, themes, mouse settings, and startup of other daemons.")
    (license license:gpl2+)))

(define-public totem-pl-parser
 (package
   (name "totem-pl-parser")
   (version "3.10.5")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/totem-pl-parser/3.10/"
                                "totem-pl-parser-" version ".tar.xz"))
            (sha256
             (base32
              "0dw1kiwmjwdjrighri0j9nagsnj44dllm0mamnfh4y5nc47mhim7"))))
   (build-system gnu-build-system)
   (arguments
    ;; FIXME: Tests require gvfs.
    `(#:tests? #f))
   (native-inputs
    `(("intltool" ,intltool)
      ("glib" ,glib "bin")
      ("gobject-introspection" ,gobject-introspection)
      ("pkg-config" ,pkg-config)))
   (propagated-inputs
    `(("glib" ,glib)
      ("gmime" ,gmime)
      ("libxml2" ,libxml2)))
   (inputs
    `(("libarchive" ,libarchive)
      ("libgcrypt" ,libgcrypt)
      ("nettle" ,nettle)
      ("libsoup" ,libsoup)))
   (home-page "https://projects.gnome.org/totem")
   (synopsis "Library to parse and save media playlists for GNOME")
   (description "Totem-pl-parser is a GObjects-based library to parse and save
playlists in a variety of formats.")
   (license license:lgpl2.0+)))

(define-public aisleriot
  (package
    (name "aisleriot")
    (version "3.16.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "19k483x9dkq8vjbq8f333pk9qil64clpsfg20q8xk9bgmk38aj8h"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '(#:configure-flags
       '("--with-platform=gtk-only"
         "--with-card-theme-formats=svg")))
    (native-inputs
     `(("desktop-file-utils" ,desktop-file-utils)
       ("glib:bin" ,glib "bin") ; for glib-compile-schemas, etc.
       ("intltool" ,intltool)
       ("itstool" ,itstool)
       ("pkg-config" ,pkg-config)
       ("xmllint" ,libxml2)))
    (inputs
     `(("gtk+" ,gtk+)
       ("guile" ,guile-2.0)
       ("libcanberra" ,libcanberra)
       ("librsvg" ,librsvg)))
    (home-page "https://wiki.gnome.org/Apps/Aisleriot")
    (synopsis "Solitaire card games")
    (description
     "Aisleriot (also known as Solitaire or sol) is a collection of card games
which are easy to play with the aid of a mouse.")
    (license license:gpl3+)))

(define-public devhelp
  (package
    (name "devhelp")
    (version "3.16.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0i8kyh86hzwxs8dm047ivghl2b92vigdxa3x4pk4ha0whpk38g37"))))
    (build-system glib-or-gtk-build-system)
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("webkitgtk" ,webkitgtk)))
    (home-page "https://wiki.gnome.org/Apps/Devhelp")
    (synopsis "API documentation browser for GNOME")
    (description
     "Devhelp is an API documentation browser for GTK+ and GNOME.  It works
natively with GTK-Doc (the API reference system developed for GTK+ and used
throughout GNOME for API documentation).")
    (license license:gpl2+)))

(define-public cogl
  (package
    (name "cogl")
    (version "1.22.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "14daxqrid5039xmq9yl4pk86awng1n9zgl6ysblhc4gw2ifzp7b8"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("glib:bin" ,glib "bin")     ; for glib-mkenums
       ("gobject-introspection" ,gobject-introspection)
       ;;("xorg-server" ,xorg-server) ; for the test suite
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("glib" ,glib)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("libx11" ,libx11)
       ("libxext" ,libxext)
       ("libxfixes" ,libxfixes)
       ("libxdamage" ,libxdamage)
       ("libxcomposite" ,libxcomposite)
       ("libxrandr" ,libxrandr)))
    (inputs
     `(("mesa" ,mesa)
       ("cairo" ,cairo)
       ("pango" ,pango)
       ("gstreamer" ,gstreamer)
       ("gst-plugins-base" ,gst-plugins-base)))
    (arguments
     `(#:configure-flags (list "--enable-cogl-gst"
                               ;; Arrange to pass an absolute file name to
                               ;; dlopen for libGL.so.
                               (string-append "--with-gl-libname="
                                              (assoc-ref %build-inputs "mesa")
                                              "/lib/libGL.so"))
       ;; XXX FIXME: All tests fail, with many warnings printed like this:
       ;;   _FontTransOpen: Unable to Parse address
       ;;   ${prefix}/share/fonts/X11/misc/
       #:tests? #f
       #; #:phases
       #;
       (modify-phases %standard-phases
         (add-before 'check 'start-xorg-server
                     (lambda* (#:key inputs #:allow-other-keys)
                       ;; The test suite requires a running X server.
                       (system (format #f "~a/bin/Xvfb :1 &"
                                       (assoc-ref inputs "xorg-server")))
                       (setenv "DISPLAY" ":1")
                       #t)))))
    (home-page "http://www.cogl3d.org")
    (synopsis "Object oriented GL/GLES Abstraction/Utility Layer")
    (description
     "Cogl is a small library for using 3D graphics hardware to draw pretty
pictures.  The API departs from the flat state machine style of OpenGL and is
designed to make it easy to write orthogonal components that can render
without stepping on each others toes.")
    (license (list license:expat       ; most of the code
                   license:bsd-3       ; cogl/cogl-point-in-poly.c
                   license:sgifreeb2.0 ; cogl-path/tesselator/
                   license:asl2.0))))  ; examples/android/

(define-public clutter
  (package
    (name "clutter")
    (version "1.24.2")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "0qyd0cw17wi8gl6y9z2j2lh2gwghxskfmsdvw4ayrgxwnj6cjccn"))))
    (build-system gnu-build-system)
    (outputs '("out"
               "doc"))                            ;9 MiB of gtk-doc HTML pages
    (native-inputs
     `(("glib:bin" ,glib "bin")     ; for glib-genmarshal
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)
       ("xsltproc" ,libxslt)))
    (propagated-inputs
     `(("cogl" ,cogl)
       ("cairo" ,cairo)
       ("atk" ,atk)
       ("gtk+" ,gtk+)
       ("json-glib" ,json-glib)
       ("glib" ,glib)
       ("libxcomposite" ,libxcomposite)
       ("libxdamage" ,libxdamage)
       ("libxext" ,libxext)
       ("xinput" ,xinput)))
    (inputs
     `(("libxkbcommon" ,libxkbcommon)
       ("udev" ,eudev)))
    (arguments
     `(#:configure-flags (list "--enable-x11-backend=yes"

                               ;; This produces share/doc/{clutter,cally}.
                               (string-append "--with-html-dir="
                                              (assoc-ref %outputs "doc")
                                              "/share/doc"))
       ;; XXX FIXME: Get test suite working.  It would probably fail in the
       ;; same way the cogl tests fail, since clutter is based on cogl.
       #:tests? #f))
    (home-page "http://www.clutter-project.org")
    (synopsis "Open GL based interactive canvas library")
    (description
     "Clutter is an Open GL based interactive canvas library, designed for
creating fast, mainly 2D single window applications such as media box UIs,
presentations, kiosk style applications and so on.")
    (license license:lgpl2.0+)))

(define-public clutter-gtk
  (package
    (name "clutter-gtk")
    (version "1.6.0")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "0k93hbf5d1970hs7vjddr3nnngygc7mxqbj474r3cdm0fjsm0dc8"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("gobject-introspection" ,gobject-introspection)))
    (inputs
     `(("clutter" ,clutter)
       ("gtk+" ,gtk+)))
    (home-page "http://www.clutter-project.org")
    (synopsis "Open GL based interactive canvas library GTK+ widget")
    (description
     "Clutter is an Open GL based interactive canvas library, designed for
creating fast, mainly 2D single window applications such as media box UIs,
presentations, kiosk style applications and so on.")
    (license license:lgpl2.0+)))

(define-public clutter-gst
  (package
    (name "clutter-gst")
    (version "3.0.6")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "0xnzfdzawl1kdx715gp31nwjp7a1kib094s7xvg7bhbwwlx4kmfn"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("glib:bin" ,glib "bin")     ; for glib-mkenums
       ("pkg-config" ,pkg-config)
       ("gobject-introspection" ,gobject-introspection)))
    (inputs
     `(("clutter" ,clutter)
       ("gstreamer" ,gstreamer)
       ("gst-plugins-base" ,gst-plugins-base)))
    (home-page "http://www.clutter-project.org")
    (synopsis "Integration library for using GStreamer with Clutter")
    (description
     "Clutter-Gst is an integration library for using GStreamer with Clutter.
It provides a GStreamer sink to upload frames to GL and an actor that
implements the ClutterGstPlayer interface using playbin.  Clutter is an Open
GL based interactive canvas library.")
    (license license:lgpl2.0+)))

(define-public libchamplain
  (package
    (name "libchamplain")
    (version "0.12.10")
    (source (origin
              (method url-fetch)
              (uri (string-append
                    "mirror://gnome/sources/libchamplain/0.12/libchamplain-"
                    version ".tar.xz"))
              (sha256
               (base32
                "019b8scnx7d3wdylmpk9ihzh06w25b63x9cn8nhj6kjx82rcwlxz"))))
    (build-system gnu-build-system)
    (native-inputs `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("libsoup" ,libsoup)
       ("sqlite" ,sqlite)
       ("clutter" ,clutter)
       ("clutter-gtk" ,clutter-gtk)
       ("glib:bin" ,glib "bin")                   ;glib-mkenums, etc.
       ("cairo" ,cairo)
       ("gtk+3" ,gtk+)
       ("glib" ,glib)))
    (home-page "http://projects.gnome.org/libchamplain/")
    (synopsis "C library providing a ClutterActor to display maps")
    (description
     "libchamplain is a C library providing a ClutterActor to display maps.
It also provides a Gtk+ widget to display maps in Gtk+ applications.  Python
and Perl bindings are also available.  It supports numerous free map sources
such as OpenStreetMap, OpenCycleMap, OpenAerialMap, and Maps for free.")
    (license license:lgpl2.1+)))

(define-public gom
  (package
    (name "gom")
    (version "0.3.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "1x9qgviszzh59d009jd13k0pdxzv9w4dmwp3wszbsk3qxr3fnlbr"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("gobject-introspection" ,gobject-introspection)))
    (inputs
     `(("glib" ,glib)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("sqlite" ,sqlite)))
    ;; XXX TODO: Figure out how to run the test suite.
    (arguments `(#:tests? #f))
    (home-page "https://wiki.gnome.org/Projects/Gom")
    (synopsis "Object mapper from GObjects to SQLite")
    (description
     "Gom provides an object mapper from GObjects to SQLite.  It helps you
write applications that need to store structured data as well as make complex
queries upon that data.")
    (license license:lgpl2.1+)))

(define-public gnome-klotski
  (package
    (name "gnome-klotski")
    (version "3.16.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0a64935c7pp51jhaf29q9zlx3lamj7zrhyff7clvv0w8v1w6gpax"))))
    (build-system glib-or-gtk-build-system)
    (native-inputs
     `(("desktop-file-utils" ,desktop-file-utils)
       ("intltool" ,intltool)
       ("itstool" ,itstool)
       ("pkg-config" ,pkg-config)
       ("xmllint" ,libxml2)))
    (inputs
     `(("gtk+" ,gtk+)
       ("librsvg" ,librsvg)))
    (home-page "https://wiki.gnome.org/Apps/Klotski")
    (synopsis "Sliding block puzzles")
    (description
     "GNOME Klotski is a set of block sliding puzzles.  The objective is to move
the patterned block to the area bordered by green markers.  To do so, you will
need to slide other blocks out of the way.  Complete each puzzle in as few moves
as possible!")
    (license license:gpl2+)))

(define-public grilo
  (package
    (name "grilo")
    (version "0.2.12")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "11bvc7rsrjjwz8hp67p3fn8zmywrpawrcbi3vgw8b0dwa0sndd2m"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("glib:bin" ,glib "bin")         ; for glib-mkenums and glib-genmarshal
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("gobject-introspection" ,gobject-introspection)))
    (inputs
     `(("glib" ,glib)
       ("gtk+" ,gtk+)
       ("libxml2" ,libxml2)
       ;; XXX TODO: Add oauth
       ("libsoup" ,libsoup)
       ("totem-pl-parser" ,totem-pl-parser)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-introspection-install-dir
                    (lambda* (#:key outputs #:allow-other-keys)
                      (let ((out (assoc-ref outputs "out")))
                        (substitute* '("src/Makefile.in"
                                       "libs/pls/Makefile.in"
                                       "libs/net/Makefile.in")
                          (("@INTROSPECTION_GIRDIR@")
                           (string-append out "/share/gir-1.0/"))
                          (("@INTROSPECTION_TYPELIBDIR@")
                           (string-append out "/lib/girepository-1.0/")))))))))
    (native-search-paths
     (list (search-path-specification
            (variable "GRL_PLUGIN_PATH")
            (files (list (string-append "lib/grilo-"
                                        (version-major+minor version)))))))
    (home-page "http://live.gnome.org/Grilo")
    (synopsis "Framework for discovering and browsing media")
    (description
     "Grilo is a framework focused on making media discovery and browsing easy
for application developers.")
    (license license:lgpl2.1+)))

(define-public grilo-plugins
  (package
    (name "grilo-plugins")
    (version "0.2.14")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "1aykhc679pwn2qxsg19g8nh9hffpsqkgxcbqq7lcfn2hcwb83wfh"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("glib:bin" ,glib "bin")     ; for glib-mkenums and glib-genmarshal
       ("intltool" ,intltool)
       ("itstool" ,itstool)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("grilo" ,grilo)
       ("glib" ,glib)
       ("libxml2" ,libxml2)
       ("sqlite" ,sqlite)
       ("gom" ,gom)
       ;; XXX TODO: Add oauth
       ;; XXX TODO: Add goa
       ;; XXX TODO: Add gdata (e.g. needed for youtube plugin)
       ;; XXX TODO: Add lua (needs help finding it)
       ("json-glib" ,json-glib)
       ("avahi" ,avahi)
       ("gmime" ,gmime)
       ("libsoup" ,libsoup)
       ("libarchive" ,libarchive)
       ("totem-pl-parser" ,totem-pl-parser)))
    (arguments
     `(#:make-flags (list (string-append "GRL_PLUGINS_DIR="
                                         %output
                                         "/lib/grilo-"
                                         ,(version-major+minor version)))
       ;; XXX FIXME: Try to get the test suite working.  It appears to require
       ;; a working system dbus.  Inside the build container, all tests fail
       ;; with: "assertion failed: (source)".  Outside of the build container,
       ;; most tests succeed.
       #:tests? #f))
    (home-page "http://live.gnome.org/Grilo")
    (synopsis "Plugins for the Grilo media discovery library")
    (description
     "Grilo is a framework focused on making media discovery and browsing easy
for application developers.")
    (license license:lgpl2.1+)))

(define-public totem
  (package
    (name "totem")
    (version "3.16.1")
    (source
     (origin
       (method url-fetch)
       (uri (string-append "mirror://gnome/sources/" name "/"
                           (version-major+minor version) "/"
                           name "-" version ".tar.xz"))
       (sha256
        (base32
         "1nkm2i271ivq40hryrl6px39gbbvhmlx4vmvwvw4h3z8xh3013f9"))))
    (build-system glib-or-gtk-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("desktop-file-utils" ,desktop-file-utils)
       ("gobject-introspection" ,gobject-introspection)
       ("intltool" ,intltool)
       ("itstool" ,itstool)
       ("xmllint" ,libxml2)))
    (propagated-inputs
     `(("dconf" ,dconf)))
    (inputs
     `(("gtk+" ,gtk+)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("atk" ,atk)
       ("cairo" ,cairo)
       ("dbus-glib" ,dbus-glib)
       ("clutter" ,clutter)
       ("clutter-gtk" ,clutter-gtk)
       ("clutter-gst" ,clutter-gst)
       ("xproto" ,xproto)
       ("libxxf86vm" ,libxxf86vm)
       ("libxtst" ,libxtst)
       ("libxrandr" ,libxrandr)
       ("libxml2" ,libxml2)
       ("libsoup" ,libsoup)
       ("libpeas" ,libpeas)
       ("librsvg" ,librsvg)
       ("lirc" ,lirc)
       ("gnome-desktop" ,gnome-desktop)
       ("gstreamer" ,gstreamer)
       ("gst-plugins-base" ,gst-plugins-base)
       ("gst-plugins-good" ,gst-plugins-good)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("adwaita-icon-theme" ,adwaita-icon-theme)
       ;; XXX We use python-2 because libxml2 because itstool (which needs
       ;; libxml) currently uses python-2.
       ("python" ,python-2)
       ("python-pygobject" ,python2-pygobject)
       ;; XXX TODO pylint needed for python support
       ("totem-pl-parser" ,totem-pl-parser)
       ("grilo" ,grilo)
       ("grilo-plugins" ,grilo-plugins)
       ("nettle" ,nettle)
       ("vala" ,vala)))
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after
          'install 'wrap-totem
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (let ((out             (assoc-ref outputs "out"))
                  (gst-plugin-path (getenv "GST_PLUGIN_SYSTEM_PATH"))
                  (grl-plugin-path (getenv "GRL_PLUGIN_PATH")))
              (wrap-program (string-append out "/bin/totem")
                `("GST_PLUGIN_SYSTEM_PATH" ":" prefix (,gst-plugin-path))
                `("GRL_PLUGIN_PATH"        ":" prefix (,grl-plugin-path))))
            #t)))))
    (home-page "https://wiki.gnome.org/Apps/Videos")
    (synopsis "Simple media player for GNOME based on GStreamer")
    (description "Totem is a simple yet featureful media player for GNOME
which can read a large number of file formats.")
    ;; GPL2+ with an exception clause for non-GPL compatible GStreamer plugins
    ;; to be used and distributed together with GStreamer and Totem.  See
    ;; file://COPYING in the source distribution for details.
    (license license:gpl2+)))

(define-public rhythmbox
 (package
   (name "rhythmbox")
   (version "3.2.1")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/" name "/"
                                (version-major+minor version) "/"
                                name "-" version ".tar.xz"))
            (sha256
             (base32
              "0f3radhlji7rxl760yl2vm49fvfslympxrpm8497acbmbd7wlhxz"))))
   (build-system glib-or-gtk-build-system)
   (arguments
    `(#:configure-flags
      (list "--enable-lirc"
            "--enable-python"
            "--enable-vala"
            "--with-brasero"
            "--with-gudev"
            "--with-libsecret")
      #:phases
      (modify-phases %standard-phases
        (add-after
         'install 'wrap-rhythmbox
         (lambda* (#:key inputs outputs #:allow-other-keys)
           (let ((out               (assoc-ref outputs "out"))
                 (gi-typelib-path   (getenv "GI_TYPELIB_PATH"))
                 (gst-plugin-path   (getenv "GST_PLUGIN_SYSTEM_PATH"))
                 (grl-plugin-path   (getenv "GRL_PLUGIN_PATH")))
             (wrap-program (string-append out "/bin/rhythmbox")
               `("GI_TYPELIB_PATH"        ":" prefix (,gi-typelib-path))
               `("GST_PLUGIN_SYSTEM_PATH" ":" prefix (,gst-plugin-path))
               `("GRL_PLUGIN_PATH"        ":" prefix (,grl-plugin-path))))
           #t)))))
   (propagated-inputs
    `(("dconf" ,dconf)))
   (native-inputs
    `(("itstool" ,itstool)
      ("intltool" ,intltool)
      ("glib" ,glib "bin")
      ("gobject-introspection" ,gobject-introspection)
      ("desktop-file-utils" ,desktop-file-utils)
      ("pkg-config" ,pkg-config)
      ("xmllint" ,libxml2)))
   (inputs
    `(("json-glib" ,json-glib)
      ("tdb" ,tdb)
      ("gnome-desktop" ,gnome-desktop)
      ("python" ,python)
      ("python-pygobject" ,python2-pygobject)
      ("vala" ,vala)
      ("gmime" ,gmime)
      ("nettle" ,nettle)
      ("adwaita-icon-theme" ,adwaita-icon-theme)
      ("grilo" ,grilo)
      ("grilo-plugins" ,grilo-plugins)
      ("gstreamer" ,gstreamer)
      ("gst-plugins-base" ,gst-plugins-base)
      ("gst-plugins-good" ,gst-plugins-good)
      ("totem-pl-parser" ,totem-pl-parser)
      ("libgudev" ,libgudev)
      ;;("libmtp" ,libmtp) FIXME: Not detected
      ("libsecret" ,libsecret)
      ("libsoup" ,libsoup)
      ("libnotify" ,libnotify)
      ("libpeas" ,libpeas)
      ("lirc" ,lirc)
      ;; TODO: clutter* only used by visualizer plugin, which also requires mx
      ;;("clutter" ,clutter)
      ;;("clutter-gtk" ,clutter-gtk)
      ;;("clutter-gst" ,clutter-gst)
      ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
      ("atk" ,atk)
      ("pango" ,pango)
      ("gtk+" ,gtk+)
      ;; TODO:
      ;;  * libgpod
      ;;  * mx
      ;;  * webkit
      ("brasero" ,brasero)))
   (home-page "https://wiki.gnome.org/Apps/Rhythmbox")
   (synopsis "Music player for GNOME")
   (description "Rhythmbox is a music playing application for GNOME.  It
supports playlists, song ratings, and any codecs installed through gstreamer.")
   (license license:gpl2+)))

(define-public eog
 (package
   (name "eog")
   (version "3.16.2")
   (source (origin
            (method url-fetch)
            (uri (string-append "mirror://gnome/sources/" name "/"
                                (version-major+minor version) "/"
                                name "-" version ".tar.xz"))
            (sha256
             (base32
              "0frw1b5jix9pffznav5s7ajjx91a8rv5lf4sjvjv3fw65mbnhbw0"))))
   (build-system glib-or-gtk-build-system)
   (arguments
    `(#:phases
      (modify-phases %standard-phases
        (add-after
         'install 'wrap-eog
         (lambda* (#:key outputs #:allow-other-keys)
           (let ((out               (assoc-ref outputs "out"))
                 (gi-typelib-path   (getenv "GI_TYPELIB_PATH")))
             (wrap-program (string-append out "/bin/eog")
               `("GI_TYPELIB_PATH" ":" prefix (,gi-typelib-path))))
           #t)))))
   (propagated-inputs
    `(("dconf" ,dconf)))
   (native-inputs
    `(("intltool" ,intltool)
      ("itstool", itstool)
      ("glib" ,glib "bin")
      ("gobject-introspection" ,gobject-introspection)
      ("pkg-config" ,pkg-config)
      ("xmllint" ,libxml2)))
   (inputs
    `(("gnome-desktop" ,gnome-desktop)
      ("shared-mime-info" ,shared-mime-info)
      ("adwaita-icon-theme" ,adwaita-icon-theme)
      ("exempi" ,exempi)
      ("lcms" ,lcms)
      ("libexif" ,libexif)
      ("libpeas" ,libpeas)
      ("libjpeg" ,libjpeg)
      ("librsvg" ,librsvg)
      ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
      ("gtk+" ,gtk+)))
   (home-page "https://wiki.gnome.org/Apps/EyeOfGnome")
   (synopsis "GNOME image viewer")
   (description "Eye of GNOME is the GNOME image viewer.  It
supports image conversion, rotation, and slideshows.")
   (license license:gpl2+)))

(define-public libgudev
  (package
    (name "libgudev")
    (version "230")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  version "/" name "-" version ".tar.xz"))
              (sha256
               (base32
                "063w6j35n0i0ssmv58kivc1mw4070z6fzb83hi4xfrhcxnn7zrx2"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-genmarshal, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("glib" ,glib))) ; required by gudev-1.0.pc
    (inputs
     `(("udev" ,eudev)))
    (home-page "https://wiki.gnome.org/Projects/libgudev")
    (synopsis "GObject bindings for libudev")
    (description
     "This library provides GObject bindings for libudev.  It was originally
part of udev-extras, then udev, then systemd.  It's now a project on its own.")
    (license license:lgpl2.1+)))

(define-public gvfs
  (package
    (name "gvfs")
    (version "1.24.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1ygiknnd24qgzds8wif3jns981mqr65lgjlxs5pw65cl3376g0yk"))))
    (build-system gnu-build-system)
    (arguments
     '(#:tests? #f)) ; XXX: requiring `pidof'
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-genmarshal, etc.
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("xsltproc" ,libxslt)))
    (inputs
     `(("avahi" ,avahi)
       ("docbook-xml" ,docbook-xml-4.2)
       ("docbook-xsl" ,docbook-xsl)
       ("dbus" ,dbus)
       ("fuse" ,fuse)
       ("glib" ,glib)
       ("libarchive" ,libarchive)
       ("libbluray" ,libbluray)
       ("libcdio-paranoia" ,libcdio-paranoia)
       ("libgcrypt" ,libgcrypt)
       ("libgphoto2" ,libgphoto2)
       ("libgudev" ,libgudev)
       ("libmtp" ,libmtp)
       ("libsecret" ,libsecret)
       ("libsmbclient" ,samba)
       ("libsoup" ,libsoup)
       ("libxml2" ,libxml2)
       ("nettle" ,nettle) ; XXX: required by libarchive.pc
       ("udisks" ,udisks)))
    (home-page "https://wiki.gnome.org/gvfs/")
    (synopsis "Userspace virtual filesystem for GIO")
    (description
     "GVFS is a userspace virtual filesystem designed to work with the I/O
abstraction of GIO.  It contains a GIO module that seamlessly adds GVFS support
to all applications using the GIO API.  It also supports exposing the GVFS
mounts to non-GIO applications using FUSE.

GVFS comes with a set of backends, including trash support, SFTP, SMB, HTTP,
DAV, and others.")
    (license license:lgpl2.0+)))

(define-public gusb
  (package
    (name "gusb")
    (version "0.2.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://github.com/hughsie/libgusb/archive/"
                                  "gusb_"
                                  (string-join (string-split version #\.)
                                               "_")
                                  ".tar.gz"))
              (sha256
               (base32
                "0h9dzaza81b0mx5jfh5cnc31xdynl0jsxgwvl6vqyhy8mnwfi5nr"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("glib:bin" ,glib "bin")         ; for glib-genmarshal, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)
       ("vala" ,vala)
       ("autoconf" ,autoconf)
       ("automake" ,automake)
       ("libtool" ,libtool)
       ("gtk-doc" ,gtk-doc)))
    (propagated-inputs
     ;; Both of these are required by gusb.pc.
     `(("glib" ,glib)
       ("libusb" ,libusb)))
    (arguments
     `(#:tests? #f  ; libusb fails to initialize.  Wonder what that is.
       #:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'autogen
                    (lambda _
                      (and (zero? (system* "gtkdocize"))
                           (zero? (system* "autoreconf" "-vif"))))))))
    (home-page "https://github/hughsie/libgusb")
    (synopsis "GLib binding for libusb1")
    (description
     "GUsb is a GObject wrapper for libusb1 that makes it easy to do
asynchronous control, bulk and interrupt transfers with proper cancellation
and integration into a mainloop.  This makes it easy to integrate low level
USB transfers with your high-level application or system daemon.")
    (license license:lgpl2.1+)))

(define-public simple-scan
  (package
    (name "simple-scan")
    (version "3.17.4")
    (source (origin
              (method url-fetch)
              (uri (string-append "https://launchpad.net/simple-scan/"
                                  (version-major+minor version) "/"
                                  version "/+download/simple-scan-"
                                  version ".tar.xz"))
              (sha256
               (base32
                "1pslbv45g01g039zj2b01k08f763kkhzqw8wwz7yh27m7bjllnx6"))))
    (build-system glib-or-gtk-build-system)
    (inputs
     `(("gtk" ,gtk+)
       ("zlib" ,zlib)
       ("cairo" ,cairo)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("gusb" ,gusb)
       ("libgudev" ,libgudev)
       ("libsane" ,sane-backends)))
    (native-inputs
     `(("intltool" ,intltool)
       ("itstool" ,itstool)
       ("colord" ,colord)
       ("glib" ,glib "bin")                       ; glib-compile-schemas, etc.
       ("pkg-config" ,pkg-config)
       ("vala" ,vala)
       ("xmllint" ,libxml2)))
    (home-page "https://launchpad.net/simple-scan")
    (synopsis "Document and image scanner")
    (description "Simple Scan is an easy-to-use application, designed to let
users connect their scanner and quickly have the image/document in an
appropriate format.  Simple Scan is basically a frontend for SANE - which is
the same backend as XSANE uses. This means that all existing scanners will
work and the interface is well tested.")
    (license license:gpl3+)))

(define-public epiphany
  (package
    (name "epiphany")
    (version "3.16.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1cch4c7gh6lq1i4g0gs39qa2csl4i8a3pcdfapcj5v3r0xvz29ym"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     ;; FIXME: tests run under Xvfb, but fail with:
     ;;   /src/bookmarks/ephy-bookmarks/create:
     ;;   ** (test-ephy-bookmarks:19591): WARNING **: Unable to start Zeroconf
     ;;      subsystem
     ;;   FAIL
     '(#:tests? #f))
    (propagated-inputs
     `(("dconf" ,dconf)))
    (native-inputs
     `(("intltool" ,intltool)
       ("itstool" ,itstool)
       ("pkg-config" ,pkg-config)
       ("xmllint" ,libxml2)))
    (inputs
     `(("avahi" ,avahi)
       ("gcr" ,gcr)
       ("glib-networking" ,glib-networking)
       ("gnome-desktop" ,gnome-desktop)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("iso-codes" ,iso-codes)
       ("libnotify" ,libnotify)
       ("libsecret" ,libsecret)
       ("libwnck" ,libwnck)
       ("libxslt" ,libxslt)
       ("nss" ,nss)
       ("sqlite" ,sqlite)
       ("webkitgtk" ,webkitgtk)))
    (home-page "https://wiki.gnome.org/Apps/Web")
    (synopsis "GNOME web browser")
    (description
     "Epiphany is a GNOME web browser targeted at non-technical users.  Its
principles are simplicity and standards compliance.")
    (license license:gpl2+)))

(define-public d-feet
  (package
    (name "d-feet")
    (version "0.3.10")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0nb31bvwnj7pcpm85g8bvgjc6s5kbqy8g4qp7pzqf8w6rdgxzw48"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '(#:out-of-source? #f ; tests need to run in the source directory.
       #:phases
       (modify-phases %standard-phases
         (add-before
          'check 'pre-check
          (lambda _
            ;; The test suite requires a running X server.
            (system "Xvfb :1 &")
            (setenv "DISPLAY" ":1")
            ;; Don't fail on missing '/etc/machine-id'.
            (setenv "DBUS_FATAL_WARNINGS" "0")
            ;; tests.py and window.py don't meet E402:
            ;;   E402 module level import not at top of file
            (substitute* "src/tests/Makefile"
              (("--ignore=E123") "--ignore=E123,E402"))
            #t))
         (add-after
          'install 'wrap-program
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((prog (string-append (assoc-ref outputs "out")
                                       "/bin/d-feet")))
              (wrap-program prog
                `("PYTHONPATH" = (,(getenv "PYTHONPATH")))
                `("GI_TYPELIB_PATH" = (,(getenv "GI_TYPELIB_PATH"))))
              #t))))))
    (native-inputs
     `(("intltool" ,intltool)
       ("itstool" ,itstool)
       ("pkg-config" ,pkg-config)
       ("python-pep8" ,python-pep8)
       ("xmllint" ,libxml2)
       ("xorg-server" ,xorg-server)))
    (inputs
     `(("gobject-introspection" ,gobject-introspection)
       ("gtk+" ,gtk+)
       ("python" ,python-wrapper)
       ("python-pygobject" ,python-pygobject)))
    (home-page "https://wiki.gnome.org/Apps/DFeet")
    (synopsis "D-Bus debugger")
    (description
     "D-Feet is a D-Bus debugger, which can be used to inspect D-Bus interfaces
of running programs and invoke methods on those interfaces.")
    (license license:gpl2+)))

(define-public yelp-xsl
  (package
    (name "yelp-xsl")
    (version "3.16.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0jhpni4mmfvj3xf57rjm61nc8d0x66hz9gd1ywws5lh39g6fx59j"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("intltool" ,intltool)
       ("itstool" ,itstool)
       ("xmllint" ,libxml2)))
    (home-page "https://wiki.gnome.org/Apps/Yelp")
    (synopsis "XSL stylesheets for Yelp")
    (description
     "Yelp-xsl contains XSL stylesheets that are used by the yelp help browser
to format Docbook and Mallard documents.")
    (license license:gpl2+)))

(define-public yelp
  (package
    (name "yelp")
    (version "3.16.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1jk7aad1srykhgc3x0hd3q3dnlshmy1ak00alwjzaasxvy6hp0b0"))))
    (build-system glib-or-gtk-build-system)
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-genmarshal, etc.
       ("intltool" ,intltool)
       ("itstool" ,itstool)
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     `(("dconf" ,dconf)))
    (inputs
     `(("libxslt" ,libxslt)
       ("sqlite" ,sqlite)
       ("webkitgtk" ,webkitgtk-2.4)
       ("yelp-xsl" ,yelp-xsl)
       ;; XXX: need by libwebkitgtk-3.0.la.
       ("icu4c" ,(@ (gnu packages icu4c) icu4c))))
    (home-page "https://wiki.gnome.org/Apps/Yelp")
    (synopsis "GNOME help browser")
    (description
     "Yelp is the help viewer in Gnome.  It natively views Mallard, DocBook,
man, info, and HTML documents.  It can locate documents according to the
freedesktop.org help system specification.")
    (license license:gpl2+)))

(define-public yelp-tools
  (package
    (name "yelp-tools")
    (version "3.16.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "177qzvj5w019isdp41qxqcys2kc4sq2x6dqhqn6l9ipib8a6rxml"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("pkg-config" ,pkg-config)))
    (propagated-inputs
     ;; Needed by `yelp-build', `yelp-check' or 'yelp.m4'.
     `(("itstool" ,itstool)
       ("xmllint" ,libxml2)
       ("xsltproc" ,libxslt)))
    (inputs
     `(("yelp-xsl" ,yelp-xsl)))
    (home-page "https://wiki.gnome.org/Apps/Yelp/Tools")
    (synopsis "Yelp documentation tools")
    (description
     "Yelp-tools is a collection of scripts and build utilities to help create,
manage, and publish documentation for Yelp and the web.  Most of the heavy
lifting is done by packages like yelp-xsl and itstool.  This package just
wraps things up in a developer-friendly way.")
    (license license:gpl2+)))

(define-public libgee
  (package
    (name "libgee")
    (version "0.18.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "16a34js81w9m2bw4qd8csm4pcgr3zq5z87867j4b8wfh6zwrxnaa"))))
    (build-system gnu-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after 'unpack 'fix-introspection-install-dir
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((out (assoc-ref outputs "out")))
              (substitute* "gee/Makefile.in"
                (("@INTROSPECTION_GIRDIR@")
                 (string-append out "/share/gir-1.0/"))
                (("@INTROSPECTION_TYPELIBDIR@")
                 (string-append out "/lib/girepository-1.0/")))))))))
    (native-inputs
     `(("glib" ,glib "bin")
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("glib" ,glib)
       ("gobject-introspection" ,gobject-introspection)))
    (home-page "https://wiki.gnome.org/Projects/Libgee")
    (synopsis "GObject collection library")
    (description
     "Libgee is a utility library providing GObject-based interfaces and
classes for commonly used data structures.")
    (license license:lgpl2.1+)))

(define-public gexiv2
  (package
    (name "gexiv2")
    (version "0.10.3")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "121r5lv6l82pjr0ycdf2b01mdwy7sxwca2r068zrzylpc6bgn31r"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("glib" ,glib "bin")
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     ;; Listed in "Requires" section of gexiv2.pc
     `(("exiv2" ,exiv2)))
    (inputs
     `(("glib" ,glib)
       ("gobject-introspection" ,gobject-introspection)))
    (home-page "https://wiki.gnome.org/Projects/gexiv2")
    (synopsis "GObject wrapper around the Exiv2 photo metadata library")
    (description
     "Gexiv2 is a GObject wrapper around the Exiv2 photo metadata library.  It
allows for GNOME applications to easily inspect and update EXIF, IPTC, and XMP
metadata in photo and video files of various formats.")
    (license license:gpl2+)))

(define-public shotwell
  (package
    (name "shotwell")
    (version "0.22.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0cgqaaikrb10plhf6zxbgqy32zqpiwyi9dpx3g8yr261q72r5c81"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     `(#:tests? #f ;no "check" target
       #:make-flags '("CC=gcc")
       #:configure-flags '("--disable-gsettings-convert-install")
       #:out-of-source? #f))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("gettext" ,gnu-gettext)
       ("m4" ,m4)
       ("desktop-file-utils" ,desktop-file-utils)
       ("vala" ,vala)
       ("which" ,which)
       ("gnome-doc-utils" ,gnome-doc-utils)
       ;; FIXME: I only added python2-libxml2 because xml2po needs it at
       ;; runtime.  It should be propagated.
       ("python2-libxml2" ,python2-libxml2)
       ("python2" ,python-2)))
    (inputs
     `(("gstreamer" ,gstreamer)
       ("gst-plugins-base" ,gst-plugins-base)
       ("gst-plugins-good" ,gst-plugins-good)
       ("libgee" ,libgee)
       ("gexiv2" ,gexiv2)
       ("libraw" ,libraw)
       ("json-glib" ,json-glib)
       ("rest" ,rest)
       ("webkitgtk" ,webkitgtk-2.4)
       ("sqlite" ,sqlite)
       ("libsoup" ,libsoup)
       ("libxml2" ,libxml2)
       ("gtk+" ,gtk+)
       ("libgudev" ,libgudev)
       ("libgphoto2" ,libgphoto2)))
    (home-page "https://wiki.gnome.org/Apps/Shotwell")
    (synopsis "Photo manager for GNOME 3")
    (description
     "Shotwell is a digital photo manager designed for the GNOME desktop
environment.  It allows you to import photos from disk or camera, organize
them by keywords and events, view them in full-window or fullscreen mode, and
share them with others via social networking and more.")
    (license license:lgpl2.1+)))

(define-public file-roller
  (package
    (name "file-roller")
    (version "3.10.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "04sg4yzz4c3hzgxhbgx2dc36lq5hjrnrmal2q0amfvhl0jcvp2fq"))))
    (build-system glib-or-gtk-build-system)
    (native-inputs
     `(("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    ;; TODO: Add libnautilus.
    (inputs
     `(("gtk+" ,gtk+)
       ("gdk-pixbuf" ,gdk-pixbuf)
       ("json-glib" ,json-glib)
       ("libarchive" ,libarchive)
       ("libnotify" ,libnotify)
       ("nettle" ,nettle)
       ("itstool" ,itstool)
       ("libxml2" ,libxml2)))
    (synopsis "Graphical archive manager for GNOME")
    (description "File Roller is an archive manager for the GNOME desktop
environment that allows users to view, unpack, and create compressed archives
such as gzip tarballs.")
    (home-page "http://fileroller.sourceforge.net/")
    (license license:gpl2+)))

(define-public gnome-session
  (package
    (name "gnome-session")
    (version "3.18.1.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0icajbzqf5llvp5s8nafwkhwz6a6jmwn4hhs81bk0bpzawyq4zdk"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-compile-schemas, etc.
       ("pkg-config" ,pkg-config)
       ("intltool" ,intltool)
       ("xsltproc" ,libxslt)))
    (inputs
     `(("gnome-desktop" ,gnome-desktop)
       ("gtk+" ,gtk+)
       ("json-glib" ,json-glib)
       ("libsm" ,libsm)
       ("libxcomposite" ,libxcomposite)
       ("libxtst" ,libxtst)
       ("mesa" ,mesa)
       ("upower" ,upower)
       ("xtrans" ,xtrans)))
    (synopsis "Session manager for GNOME")
    (description
     "This package contains the GNOME session manager, as well as a
configuration program to choose applications starting on login.")
    (home-page "https://wiki.gnome.org/Projects/SessionManagement")
    (license license:gpl2+)))

(define-public gjs
  (package
    (name "gjs")
    (version "1.44.0")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "106fgpr4y99sj68l72pnfa2za11ps4bn6p9z28fr79j7mpv61jc8"))
              (modules '((guix build utils)))
              (snippet '(substitute* "test/run-with-dbus"
                          (("/bin/rm") "rm")))))
    (build-system gnu-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (add-before
          'check 'pre-check
          (lambda _
            ;; For the missing /etc/machine-id.
            (setenv "DBUS_FATAL_WARNINGS" "0")
            #t)))))
    (native-inputs
     `(("glib:bin" ,glib "bin")       ; for glib-compile-resources
       ("pkg-config" ,pkg-config)
       ("xmllint" ,libxml2)
       ;; For testing
       ("dbus-launch" ,dbus)
       ("uuidgen" ,util-linux)
       ("xvfb" ,xorg-server)))
    (propagated-inputs
     ;; These are all in the Requires.private field of gjs-1.0.pc.
     `(("gobject-introspection" ,gobject-introspection)
       ("mozjs" ,mozjs-24)))
    (inputs
     `(("gtk+" ,gtk+)
       ("readline" ,readline)))
    (synopsis "Javascript bindings for GNOME")
    (home-page "http://live.gnome.org/Gjs")
    (description
     "Gjs is a javascript binding for GNOME.  It's mainly based on spidermonkey
javascript engine and the GObject introspection framework.")
    (license license:gpl2+)))

(define-public gedit
  (package
    (name "gedit")
    (version "3.18.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1kb3hglcppap7fdy7i7w2wk746kfz77jzs2lq6vrna8a3fqaxmas"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     `(#:phases
       (modify-phases %standard-phases
         (add-after
          'install 'wrap-gedit
          (lambda* (#:key inputs outputs #:allow-other-keys)
            (let ((out               (assoc-ref outputs "out"))
                  (gtksourceview     (assoc-ref inputs "gtksourceview"))
                  (gi-typelib-path   (getenv "GI_TYPELIB_PATH")))
              (wrap-program (string-append out "/bin/gedit")
                `("GI_TYPELIB_PATH" ":" prefix (,gi-typelib-path))
                ;; For language-specs.
                `("XDG_DATA_DIRS" ":" prefix (,(string-append gtksourceview
                                                              "/share")))))
            #t)))))
    (propagated-inputs
     `(("dconf" ,dconf)))
    (native-inputs
     `(("intltool" ,intltool)
       ("itstool", itstool)
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("glib" ,glib)
       ("gtk+" ,gtk+)
       ("gtksourceview" ,gtksourceview)
       ("libpeas" ,libpeas)
       ("libxml2" ,libxml2)
       ("enchant" ,enchant)
       ("iso-codes" ,iso-codes)
       ("python-pygobject" ,python-pygobject)
       ("python" ,python)
       ("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("libx11" ,libx11)
       ("vala" ,vala)
       ("adwaita-icon-theme" ,adwaita-icon-theme)
       ("libsoup" ,libsoup)
       ("gnome-desktop" ,gnome-desktop)))
    (home-page "https://wiki.gnome.org/Apps/Gedit")
    (synopsis "GNOME text editor")
    (description "While aiming at simplicity and ease of use, gedit is a
powerful general purpose text editor.")
    (license license:gpl2+)))

(define-public zenity
  (package
    (name "zenity")
    (version "3.18.1.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "02m88dfm1rziqk2ywakwib06wl1rxangbzih6cp8wllbyl1plcg6"))))
    (build-system gnu-build-system)
    (native-inputs
     `(("gettext" ,gnu-gettext)
       ("itstool" ,itstool)
       ("pkg-config" ,pkg-config)))
    (inputs
     `(("libnotify" ,libnotify)
       ("webkitgtk" ,webkitgtk)))
    (synopsis "Display graphical dialog boxes from shell scripts")
    (home-page "http://www.gnome.org")
    (description
     "Zenity is a rewrite of gdialog, the GNOME port of dialog which allows you
to display dialog boxes from the commandline and shell scripts.")
    (license license:lgpl2.0+)))

(define-public mutter
  (package
    (name "mutter")
    (version "3.18.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1ab959z5fgi4rq0ifxdqvpdbv99a2b1lfgvj327s9crdvk4ygpjg"))))
    (build-system gnu-build-system)
    (arguments
     '(#:configure-flags
       ;; XXX: build fails with [-Werror]:
       ;;    backends/meta-cursor-renderer.c:112:5: error:
       ;;      implicit declaration of function ?roundf?
       '("--enable-compile-warnings=minimum")))
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-compile-schemas, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     ;; libmutter.pc refers to all these.
     `(("gsettings-desktop-schemas" ,gsettings-desktop-schemas)
       ("gtk+" ,gtk+)
       ("clutter" ,clutter)))
    (inputs
     `(("gnome-desktop" ,gnome-desktop)
       ("libcanberra-gtk" ,libcanberra)
       ("libice" ,libice)
       ("libsm" ,libsm)
       ("libxkbcommon" ,libxkbcommon)
       ("libxkbfile" ,libxkbfile)
       ("mesa-headers" ,mesa-headers)
       ("startup-notification" ,startup-notification)
       ("upower-glib" ,upower)
       ("xkeyboard-config" ,xkeyboard-config)
       ("zenity" ,zenity)))
    (synopsis "Window and compositing manager")
    (home-page "http://www.gnome.org")
    (description
     "Mutter is a window and compositing manager that displays and manages your
desktop via OpenGL.  Mutter combines a sophisticated display engine using the
Clutter toolkit with solid window-management logic inherited from the Metacity
window manager.")
    (license license:gpl2+)))

(define-public gnome-online-accounts
  (package
    (name "gnome-online-accounts")
    (version "3.18.1")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1hn2fvkr1f4qh4gix03avnvk7pklvv5272ns8ws56v4kcq4nppkc"))))
    (build-system glib-or-gtk-build-system)
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-compile-schemas, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("xsltproc" ,libxslt)))
    (propagated-inputs
     `(("glib" ,glib)           ; required by goa-1.0.pc
       ("gtk+" ,gtk+)))         ; required by goa-backend-1.0.pc
    (inputs
     `(("docbook-xsl" ,docbook-xsl)
       ("json-glib" ,json-glib)
       ("libsecret" ,libsecret)
       ("rest" ,rest)
       ("telepathy-glib" ,telepathy-glib)
       ("webkitgtk" ,webkitgtk)))
    (synopsis "Single sign-on framework for GNOME")
    (home-page "https://wiki.gnome.org/Projects/GnomeOnlineAccounts")
    (description
     "GNOME Online Accounts provides interfaces so that applications and
libraries in GNOME can access the user's online accounts.  It has providers for
Google, ownCloud, Facebook, Flickr, Windows Live, Pocket, Foursquare, Microsoft
Exchange, Last.fm, IMAP/SMTP, Jabber, SIP and Kerberos.")
    (license license:lgpl2.0+)))

(define-public evolution-data-server
  (package
    (name "evolution-data-server")
    (version "3.18.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "16yfd2a00xqxikyf6pi2awfd0qfq4hwdhfar88axrb4mycfgqhjr"))))
    (build-system gnu-build-system)
    (arguments
     '(;; XXX: fails with:
       ;;   /Fixture/Calendar0: cleaning up pid xxxx
       ;;   t status: 139)
       #:tests? #f
       #:configure-flags
       (let ((nss  (assoc-ref %build-inputs "nss"))
             (nspr (assoc-ref %build-inputs "nspr")))
         (list "--disable-uoa"    ; disable Ubuntu Online Accounts support
               "--disable-google" ; disable Google Contacts support
               (string-append "--with-nspr-includes=" nspr "/include/nspr")
               (string-append "--with-nss-includes=" nss "/include/nss")
               (string-append "--with-nss-libs=" nss "/lib/nss")))
       #:phases
       (modify-phases %standard-phases
         (add-before 'check 'pre-check
          (lambda _
            (substitute* "tests/test-server-utils/e-test-server-utils.c"
              (("/bin/rm") (which "rm")))
            #t)))))
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-mkenums, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("gperf" ,gperf)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("python" ,python)))
    (propagated-inputs
     ;; These are all in the Requires field of .pc files.
     `(("gtk+" ,gtk+)
       ("libical" ,libical)
       ("libsecret" ,libsecret)
       ("libsoup" ,libsoup)
       ("nss" ,nss)
       ("sqlite" ,sqlite)))
    (inputs
     `(("bdb" ,bdb)
       ("gcr" ,gcr)
       ("gnome-online-accounts" ,gnome-online-accounts)
       ("libgweather" ,libgweather)))
    (synopsis "Store address books and calendars")
    (home-page "https://wiki.gnome.org/Apps/Evolution")
    (description
     "This package provides a unified backend for programs that work with
contacts, tasks, and calendar information.  It was originally developed for
Evolution (hence the name), but is now used by other packages as well.")
    (license license:lgpl2.0)))

(define-public caribou
  (package
    (name "caribou")
    (version "0.4.19")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0i2s2xy9ami3wslam15cajhggpcsj4c70qm7qddcz52z9k0x02rg"))))
    (build-system glib-or-gtk-build-system)
    (arguments
     '(#:phases
       (modify-phases %standard-phases
         (add-before
          'build 'pre-build
          (lambda* (#:key outputs #:allow-other-keys)
            (let ((out (assoc-ref outputs "out")))
              ;; Use absolute shared library path in Caribou-1.0.typelib.
              (substitute* "libcaribou/Makefile"
                (("--shared-library=libcaribou.so")
                 (string-append "--shared-library="
                                out "/lib/libcaribou.so")))
              #t)))
         (add-after 'install 'wrap-programs
          (lambda* (#:key outputs #:allow-other-keys)
            (let* ((out (assoc-ref outputs "out"))
                   (python-path (getenv "PYTHONPATH"))
                   (gi-typelib-path (getenv "GI_TYPELIB_PATH")))
              (for-each
               (lambda (prog)
                 (wrap-program prog
                   `("PYTHONPATH"      ":" prefix (,python-path))
                   `("GI_TYPELIB_PATH" ":" prefix (,gi-typelib-path))))
               (list (string-append out "/bin/caribou-preferences")
                     (string-append out "/libexec/antler-keyboard"))))
            #t)))))
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for glib-compile-schemas, etc.
       ("gobject-introspection" ,gobject-introspection)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ("python" ,python-2) ; incompatible with Python 3 (print syntax)
       ("vala" ,vala)
       ("xsltproc" ,libxslt)))
    (propagated-inputs
     ;; caribou-1.0.pc refers to all these.
     `(("libgee" ,libgee)
       ("libxklavier" ,libxklavier)
       ("libxtst" ,libxtst)
       ("gtk+" ,gtk+)))
    (inputs
     `(("clutter" ,clutter)
       ("dconf" ,dconf)
       ("gtk+-2" ,gtk+-2)
       ("python-pygobject" ,python2-pygobject)))
    (synopsis "Text entry and UI navigation application")
    (home-page "https://wiki.gnome.org/Projects/Caribou")
    (description
     "Caribou is an input assistive technology intended for switch and pointer
users.")
    (license license:lgpl2.1)))

(define %network-manager-glib-duplicate-test-patch
  (origin
    (method url-fetch)
    (uri (string-append
          "http://cgit.freedesktop.org/NetworkManager/NetworkManager/"
          "patch/libnm-core/tests/test-general.c"
          "?id=874f455d6d47c5a34ed9861a6710f4b78202e0d6"))
    (file-name "network-manager-glib-duplicate-test.patch")
    (sha256
     (base32
      "1v0vpxzf0p0b1y5lmq8w7rjndp216gr60nbf2dpdz5rgxx3p3ml6"))))

(define-public network-manager
  (package
    (name "network-manager")
    (version "1.0.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/NetworkManager/"
                                  (version-major+minor version) "/"
                                  "NetworkManager-" version ".tar.xz"))
              (sha256
               (base32
                "1galh9j95yw33iv1jj8zz0h88ahx8gm5mqmam7zq9f730cj01siq"))
              (patches (list %network-manager-glib-duplicate-test-patch))))
    (build-system gnu-build-system)
    (outputs '("out"
               "doc")) ; 8 MiB of gtk-doc HTML
    (arguments
     '(#:configure-flags
       (let ((out      (assoc-ref %outputs "out"))
             (doc      (assoc-ref %outputs "doc"))
             (dhclient (string-append (assoc-ref %build-inputs "isc-dhcp")
                                      "/sbin/dhclient")))
         (list "--with-crypto=gnutls"
               "--disable-config-plugin-ibft"
               "--sysconfdir=/etc"
               "--localstatedir=/var"
               (string-append "--with-udev-dir="
                              out "/lib/udev")
               (string-append "--with-dbus-sys-dir="
                              out "/etc/dbus-1/system.d")
               (string-append "--with-html-dir="
                              doc "/share/gtk-doc/html")
               (string-append "--with-dhclient=" dhclient)))
       #:phases
       (modify-phases %standard-phases
         (add-before 'check 'pre-check
           (lambda _
             ;; For the missing /etc/machine-id.
             (setenv "DBUS_FATAL_WARNINGS" "0")
             #t))
         (replace 'install
           (lambda _
             (zero? (system* "make"
                             "sysconfdir=/tmp"
                             "localstatedir=/tmp"
                             "install")))))))
    (native-inputs
     `(("glib:bin" ,glib "bin") ; for gdbus-codegen
       ("gobject-introspection" ,gobject-introspection)
       ("intltool" ,intltool)
       ("pkg-config" ,pkg-config)
       ;; For testing.
       ("python" ,python-wrapper)
       ("python-dbus" ,python-dbus)
       ("python-pygobject" ,python-pygobject)))
    (inputs
     `(("dbus-glib" ,dbus-glib)
       ("dnsmasq" ,dnsmasq)
       ("gnutls" ,gnutls)
       ("iptables" ,iptables)
       ("isc-dhcp" ,isc-dhcp)
       ("libgcrypt" ,libgcrypt)
       ("libgudev" ,libgudev)
       ("libndp" ,libndp)
       ("libnl" ,libnl)
       ("libsoup" ,libsoup)
       ("polkit" ,polkit)
       ("ppp" ,ppp)
       ("readline" ,readline)
       ("util-linux" ,util-linux)))
    (synopsis "Network connection manager")
    (home-page "http://www.gnome.org/projects/NetworkManager/")
    (description
     "NetworkManager is a system network service that manages your network
devices and connections, attempting to keep active network connectivity when
available.  It manages ethernet, WiFi, mobile broadband (WWAN), and PPPoE
devices, and provides VPN integration with a variety of different VPN
services.")
    (license license:gpl2+)))

(define-public network-manager-applet
  (package
    (name "network-manager-applet")
    (version "1.0.6")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "1yj0m6fb9v12d0di0rfmk3hx1vmygjkiff2c476rf792sbh56kax"))))
    (build-system glib-or-gtk-build-system)
    (arguments '(#:configure-flags '("--disable-migration")))
    (native-inputs
     `(("intltool" ,intltool)
       ("gobject-introspection" ,gobject-introspection)
       ("pkg-config" ,pkg-config)))
    (propagated-inputs
     ;; libnm-gtk.pc refers to all these.
     `(("dbus-glib" ,dbus-glib)
       ("gtk+" ,gtk+)
       ("network-manager" ,network-manager)))
    (inputs
     `(("iso-codes" ,iso-codes)
       ("libgudev" ,libgudev)
       ("libnotify" ,libnotify)
       ("libsecret" ,libsecret)))
    (synopsis "Applet for managing network connections")
    (home-page "http://www.gnome.org/projects/NetworkManager/")
    (description
     "This package contains a systray applet for NetworkManager.  It displays
the available networks and allows users to easily switch between them.")
    (license license:gpl2+)))

(define-public libxml++
  (package
    (name "libxml++")
    (version "2.91.2")
    (source (origin
              (method url-fetch)
              (uri (string-append "mirror://gnome/sources/" name "/"
                                  (version-major+minor version) "/"
                                  name "-" version ".tar.xz"))
              (sha256
               (base32
                "0h4h7hhh9lg8h34py116517m3wqbzhd5v63k1c6pp1p2a43s18fs"))))
    (build-system gnu-build-system)
    ;; libxml++-3.0.pc refers to all these.
    (propagated-inputs
     `(("libxml2" ,libxml2)
       ("glibmm" ,glibmm)))
    (native-inputs
     `(("perl" ,perl)
       ("pkg-config" ,pkg-config)))
    (home-page "http://libxmlplusplus.sourceforge.net/")
    (synopsis "C++ wrapper for XML parser library libxml2")
    (description
     "This package provides a C++ wrapper for the XML parser library
libxml2.")
    (license license:lgpl2.1+)))
