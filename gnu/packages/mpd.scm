;;; GNU Guix --- Functional package management for GNU
;;; Copyright © 2014, 2015 David Thompson <dthompson2@worcester.edu>
;;; Copyright © 2014 Andreas Enge <andreas@enge.fr>
;;; Copyright © 2014 Cyrill Schenkel <cyrill.schenkel@gmail.com>
;;; Copyright © 2014 Ian Denhardt <ian@zenhack.net>
;;; Copyright © 2015 Paul van der Walt <paul@denknerd.org>
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

(define-module (gnu packages mpd)
  #:use-module (gnu packages)
  #:use-module ((guix licenses) #:prefix license:)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix utils)
  #:use-module (guix build-system gnu)
  #:use-module (gnu packages avahi)
  #:use-module (gnu packages boost)
  #:use-module (gnu packages icu4c)
  #:use-module (gnu packages readline)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages curl)
  #:use-module (gnu packages doxygen)
  #:use-module (gnu packages glib)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages mp3)
  #:use-module (gnu packages ncurses)
  #:use-module (gnu packages pkg-config)
  #:use-module (gnu packages autotools)
  #:use-module (gnu packages pulseaudio)
  #:use-module (gnu packages databases)
  #:use-module (gnu packages video)
  #:use-module (gnu packages xiph))

(define-public libmpdclient
  (package
    (name "libmpdclient")
    (version "2.10")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "http://musicpd.org/download/libmpdclient/"
                              (car (string-split version #\.))
                              "/libmpdclient-" version ".tar.xz"))
              (sha256
               (base32
                "10pzs9z815a8hgbbbiliapyiw82bnplsccj5irgqjw5f5plcs22g"))))
    (build-system gnu-build-system)
    (native-inputs `(("doxygen" ,doxygen)))
    (synopsis "Music Player Daemon client library")
    (description "A stable, documented, asynchronous API library for
interfacing MPD in the C, C++ & Objective C languages.")
    (home-page "http://www.musicpd.org/libs/libmpdclient/")
    (license license:bsd-3)))

(define-public mpd
  (package
    (name "mpd")
    (version "0.19.10")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "http://musicpd.org/download/mpd/"
                              (version-major+minor version)
                              "/mpd-" version ".tar.xz"))
              (sha256
               (base32
                "0laqn68iggqf0h06hg282cvpd9wsjqpjfg5fnn9wk3gr48yyp1n3"))))
    (build-system gnu-build-system)
    (inputs `(("ao" ,ao)
              ("alsa-lib" ,alsa-lib)
              ("avahi" ,avahi)
              ("boost" ,boost)
              ("curl" ,curl)
              ("ffmpeg" ,ffmpeg)
              ("flac" ,flac)
              ("glib" ,glib)
              ("icu4c" ,icu4c)
              ("lame" ,lame)
              ("libid3tag" ,libid3tag)
              ("libmad" ,libmad)
              ("libmpdclient" ,libmpdclient)
              ("libsamplerate" ,libsamplerate)
              ("libsndfile" ,libsndfile)
              ("libvorbis" ,libvorbis)
              ("opus" ,opus)
              ("pulseaudio" ,pulseaudio)
              ("sqlite" ,sqlite)
              ("zlib" ,zlib)))
    (native-inputs `(("pkg-config" ,pkg-config)))
    ;; Missing optional inputs:
    ;;   libyajl
    ;;   libcdio_paranoia
    ;;   libmms
    ;;   libadplug
    ;;   libaudiofile
    ;;   faad2
    ;;   fluidsynth
    ;;   libgme
    ;;   libshout
    ;;   libmpg123
    ;;   libmodplug
    ;;   libmpcdec
    ;;   libsidplay2
    ;;   libwavpack
    ;;   libwildmidi
    ;;   libtwolame
    ;;   libroar
    ;;   libjack
    ;;   OpenAL
    (synopsis "Music Player Daemon")
    (description "Music Player Daemon (MPD) is a flexible, powerful,
server-side application for playing music.  Through plugins and libraries it
can play a variety of sound files while being controlled by its network
protocol.")
    (home-page "http://www.musicpd.org/")
    (license license:gpl2)))

(define-public mpd-mpc
  (package
    (name "mpd-mpc")
    (version "0.27")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "http://www.musicpd.org/download/mpc/"
                              (car (string-split version #\.))
                              "/mpc-" version ".tar.xz"))
              (sha256
               (base32
                "0r10wsqxsi07gns6mfnicvpci0sbwwj4qa9iyr1ysrgadl5bx8j5"))))
    (build-system gnu-build-system)
    (inputs `(("libmpdclient" ,libmpdclient)))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (synopsis "Music Player Daemon client")
    (description "MPC is a minimalist command line interface to MPD, the music
player daemon.")
    (home-page "http://www.musicpd.org/clients/mpc/")
    (license license:gpl2)))

(define-public ncmpc
  (package
    (name "ncmpc")
    (version "0.24")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "http://musicpd.org/download/ncmpc/"
                              (car (string-split version #\.))
                              "/ncmpc-" version ".tar.xz"))
              (sha256
               (base32
                "1sf3nirs3mcx0r5i7acm9bsvzqzlh730m0yjg6jcyj8ln6r7cvqf"))))
    (build-system gnu-build-system)
    (inputs `(("glib" ,glib)
              ("libmpdclient" ,libmpdclient)
              ("ncurses" ,ncurses)))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (synopsis "Curses Music Player Daemon client")
    (description "ncmpc is a fully featured MPD client, which runs in a
terminal using ncurses.")
    (home-page "http://www.musicpd.org/clients/ncmpc/")
    (license license:gpl2)))

(define-public ncmpcpp
  (package
    (name "ncmpcpp")
    (version "0.6.7")
    (source (origin
              (method url-fetch)
              (uri
               (string-append "http://ncmpcpp.rybczak.net/stable/ncmpcpp-"
                              version ".tar.bz2"))
              (sha256
               (base32
                "0yr1ib14qkgbsv839anpzkfbwkm6gg8wv4bf98ar7q5l2p2pv008"))))
    (build-system gnu-build-system)
    (inputs `(("libmpdclient" ,libmpdclient)
              ("boost"  ,boost)
              ("readline" ,readline)
              ("ncurses" ,ncurses)
              ("taglib" ,taglib)))
    (native-inputs
     `(("pkg-config" ,pkg-config)
       ("automake" ,automake)
       ("autoconf" ,autoconf)
       ("libtool" ,libtool)))
    (arguments
     '(#:configure-flags
       '("BOOST_LIB_SUFFIX=" "--with-taglib")
       #:phases
       (alist-cons-after
        'unpack 'autogen
        (lambda _
          (setenv "NOCONFIGURE" "true")
          (zero? (system* "sh" "autogen.sh")))
        %standard-phases)))
    (synopsis "Featureful ncurses based MPD client inspired by ncmpc")
    (description "Ncmpcpp is an mpd client with a UI very similar to ncmpc,
but it provides new useful features such as support for regular expressions
for library searches, extended song format, items filtering, the ability to
sort playlists, and a local filesystem browser.")
    (home-page "http://ncmpcpp.rybczak.net/")
    (license license:gpl2+)))

(define-public mpdscribble
  (package
    (name "mpdscribble")
    (version "0.22")
    (source (origin
              (method url-fetch)
              (uri (string-append "http://www.musicpd.org/download/mpdscribble/"
                                  version "/mpdscribble-" version ".tar.gz"))
              (sha256
               (base32
                "0f0ybx380x2z2g1qvdndpvcrhkrgsfqckhz3ryydq2w3pl12v27z"))))
    (build-system gnu-build-system)
    (inputs `(("libmpdclient" ,libmpdclient)
              ("curl" ,curl)
              ("glib" ,glib)))
    (native-inputs `(("pkg-config" ,pkg-config)))
    (synopsis "MPD client for track scrobbling")
    (description "mpdscribble is a Music Player Daemon client which submits
information about tracks being played to a scrobbler, such as Libre.FM.")
    ;; musicpd.org doesn't mention mpdscribble.  It points users to this wiki
    ;; instead.
    (home-page "http://mpd.wikia.com/wiki/Client:Mpdscribble")
    (license license:gpl2+)))
