(define-module (gnu packages ipfs-hack)
  #:use-module (guix packages)
  #:use-module (guix download)
  #:use-module (guix build-system trivial)
  #:use-module (guix licenses)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages base)
  #:use-module (gnu packages compression)
  #:use-module (gnu packages elf))

(define-public ipfs
  (package
    (name "ipfs")
    (version "0.4.18")
    (inputs `(("glibc" ,glibc)
	      ("patchelf" ,patchelf)
	      ("tar" ,tar)
	      ("coreutils" ,coreutils)
	      ("gzip" ,gzip)))
    (supported-systems '("x86_64-linux"))
    (source (origin
	      (method url-fetch)
	      (uri "https://ipfs.io/ipns/dist.ipfs.io/go-ipfs/v0.4.18/go-ipfs_v0.4.18_linux-amd64.tar.gz")
	      (sha256
	       (base32
	        "1xh3d8grw5qa3f35drk2jj3klk1a6ibq47kzf8dgkvd81x6c9ri1"))))
    (build-system trivial-build-system)
    (arguments
     '(#:modules
       ((guix build utils))
       #:builder
       (begin
         (use-modules (guix build utils))
         (let*
	     ((out (assoc-ref %outputs "out"))
	      (source (assoc-ref %build-inputs "source"))
	      (tar (string-append (assoc-ref %build-inputs "tar") "/bin/tar"))
	      (patchelf (string-append (assoc-ref %build-inputs "patchelf") "/bin/patchelf"))
	      (ld (string-append (assoc-ref %build-inputs "glibc") "/lib/ld-linux-x86-64.so.2"))
	      (ln (string-append (assoc-ref %build-inputs "coreutils") "/bin/ln"))
	      (cp (string-append (assoc-ref %build-inputs "coreutils") "/bin/cp"))
	      (rm (string-append (assoc-ref %build-inputs "coreutils") "/bin/rm"))	   	   
	      (PATH
	       (string-append
	        (assoc-ref %build-inputs "gzip") "/bin"
	        ":"
	        (assoc-ref %build-inputs "tar") "/bin")))
	   (mkdir-p out)
	   (mkdir-p (string-append out "/bin"))
	   (with-directory-excursion out
	     (setenv "PATH" PATH)
	     (system* tar "xf" source)
	     (system* patchelf "--set-interpreter" ld (string-append out "/go-ipfs/ipfs"))
	     (system* cp (string-append out "/go-ipfs/ipfs") (string-append out "/bin/ipfs"))
	     (system* rm "-rf" (string-append out "/go-ipfs")))))))
    (synopsis "IPFS")
    (description "intergalactic, planetary")
    (home-page "http://ipfs.io")
    (license "oh well")))
  
