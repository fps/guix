;;; guix-info.el --- Info buffers for displaying entries   -*- lexical-binding: t -*-

;; Copyright © 2014, 2015 Alex Kost <alezost@gmail.com>
;; Copyright © 2015 Ludovic Courtès <ludo@gnu.org>

;; This file is part of GNU Guix.

;; GNU Guix is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; GNU Guix is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; This file provides a help-like buffer for displaying information
;; about Guix packages and generations.

;;; Code:

(require 'guix-base)
(require 'guix-utils)

(defgroup guix-info nil
  "General settings for info buffers."
  :prefix "guix-info-"
  :group 'guix)

(defgroup guix-info-faces nil
  "Faces for info buffers."
  :group 'guix-info
  :group 'guix-faces)

(defface guix-info-param-title
  '((t :inherit font-lock-type-face))
  "Face used for titles of parameters."
  :group 'guix-info-faces)

(defface guix-info-file-path
  '((t :inherit link))
  "Face used for file paths."
  :group 'guix-info-faces)

(defface guix-info-url
  '((t :inherit link))
  "Face used for URLs."
  :group 'guix-info-faces)

(defface guix-info-time
  '((t :inherit font-lock-constant-face))
  "Face used for timestamps."
  :group 'guix-info-faces)

(defface guix-info-action-button
  '((((type x w32 ns) (class color))
     :box (:line-width 2 :style released-button)
     :background "lightgrey" :foreground "black")
    (t :inherit button))
  "Face used for action buttons."
  :group 'guix-info-faces)

(defface guix-info-action-button-mouse
  '((((type x w32 ns) (class color))
     :box (:line-width 2 :style released-button)
     :background "grey90" :foreground "black")
    (t :inherit highlight))
  "Mouse face used for action buttons."
  :group 'guix-info-faces)

(defcustom guix-info-ignore-empty-vals nil
  "If non-nil, do not display parameters with nil values."
  :type 'boolean
  :group 'guix-info)

(defvar guix-info-param-title-format "%-18s: "
  "String used to format a title of a parameter.
It should be a '%s'-sequence.  After inserting a title formatted
with this string, a value of the parameter is inserted.
This string is used by `guix-info-insert-title-default'.")

(defvar guix-info-multiline-prefix (make-string 20 ?\s)
  "String used to format multi-line parameter values.
If a value occupies more than one line, this string is inserted
in the beginning of each line after the first one.
This string is used by `guix-info-insert-val-default'.")

(defvar guix-info-indent 2
  "Number of spaces used to indent various parts of inserted text.")

(defvar guix-info-fill-column 60
  "Column used for filling (word wrapping) parameters with long lines.
If a value is not multi-line and it occupies more than this
number of characters, it will be split into several lines.")

(defvar guix-info-delimiter "\n\f\n"
  "String used to separate entries.")

(defvar guix-info-insert-methods
  '((package
     (name              guix-package-info-name)
     (version           guix-package-info-version)
     (license           guix-package-info-license)
     (synopsis          guix-package-info-synopsis)
     (description       guix-package-info-insert-description
                        guix-info-insert-title-simple)
     (outputs           guix-package-info-insert-outputs
                        guix-info-insert-title-simple)
     (source            guix-package-info-insert-source
                        guix-info-insert-title-simple)
     (home-url          guix-info-insert-url)
     (inputs            guix-package-info-insert-inputs)
     (native-inputs     guix-package-info-insert-native-inputs)
     (propagated-inputs guix-package-info-insert-propagated-inputs)
     (location          guix-package-info-insert-location))
    (installed
     (path              guix-package-info-insert-output-path
                        guix-info-insert-title-simple)
     (dependencies      guix-package-info-insert-output-dependencies
                        guix-info-insert-title-simple))
    (output
     (name              guix-package-info-name)
     (version           guix-output-info-insert-version)
     (output            guix-output-info-insert-output)
     (source            guix-package-info-insert-source
                        guix-info-insert-title-simple)
     (path              guix-package-info-insert-output-path
                        guix-info-insert-title-simple)
     (dependencies      guix-package-info-insert-output-dependencies
                        guix-info-insert-title-simple)
     (license           guix-package-info-license)
     (synopsis          guix-package-info-synopsis)
     (description       guix-package-info-insert-description
                        guix-info-insert-title-simple)
     (home-url          guix-info-insert-url)
     (inputs            guix-package-info-insert-inputs)
     (native-inputs     guix-package-info-insert-native-inputs)
     (propagated-inputs guix-package-info-insert-propagated-inputs)
     (location          guix-package-info-insert-location))
    (generation
     (number            guix-generation-info-insert-number)
     (current           guix-generation-info-insert-current)
     (path              guix-info-insert-file-path)
     (time              guix-info-insert-time)))
  "Methods for inserting parameter values.
Each element of the list should have a form:

  (ENTRY-TYPE . ((PARAM INSERT-VALUE [INSERT-TITLE]) ...))

INSERT-VALUE may be either nil, a face name or a function.  If it
is nil or a face, `guix-info-insert-val-default' function is
called with parameter value and INSERT-VALUE as arguments.  If it
is a function, this function is called with parameter value and
entry info (alist of parameters and their values) as arguments.

INSERT-TITLE may be either nil, a face name or a function.  If it
is nil or a face, `guix-info-insert-title-default' function is
called with parameter title and INSERT-TITLE as arguments.  If it
is a function, this function is called with parameter title as
argument.")

(defvar guix-info-displayed-params
  '((package name version synopsis outputs source location home-url
             license inputs native-inputs propagated-inputs description)
    (output name version output synopsis source path dependencies location
            home-url license inputs native-inputs propagated-inputs
            description)
    (installed path dependencies)
    (generation number prev-number current time path))
  "List of displayed entry parameters.
Each element of the list should have a form:

  (ENTRY-TYPE . (PARAM ...))

The order of displayed parameters is the same as in this list.")

(defun guix-info-get-insert-methods (entry-type param)
  "Return list of insert methods for parameter PARAM of ENTRY-TYPE.
See `guix-info-insert-methods' for details."
  (guix-assq-value guix-info-insert-methods
                   entry-type param))

(defun guix-info-get-displayed-params (entry-type)
  "Return parameters of ENTRY-TYPE that should be displayed."
  (guix-assq-value guix-info-displayed-params
                   entry-type))

(defun guix-info-get-indent (&optional level)
  "Return `guix-info-indent' \"multiplied\" by LEVEL spaces.
LEVEL is 1 by default."
  (make-string (* guix-info-indent (or level 1)) ?\s))

(defun guix-info-insert-indent (&optional level)
  "Insert `guix-info-indent' spaces LEVEL times (1 by default)."
  (insert (guix-info-get-indent level)))

(defun guix-info-insert-entries (entries entry-type)
  "Display ENTRIES of ENTRY-TYPE in the current info buffer.
ENTRIES should have a form of `guix-entries'."
  (guix-mapinsert (lambda (entry)
                    (guix-info-insert-entry entry entry-type))
                  entries
                  guix-info-delimiter))

(defun guix-info-insert-entry-default (entry entry-type
                                       &optional indent-level)
  "Insert ENTRY of ENTRY-TYPE into the current info buffer.
If INDENT-LEVEL is non-nil, indent displayed information by this
number of `guix-info-indent' spaces."
  (let ((region-beg (point)))
    (mapc (lambda (param)
            (guix-info-insert-param param entry entry-type))
          (guix-info-get-displayed-params entry-type))
    (when indent-level
      (indent-rigidly region-beg (point)
                      (* indent-level guix-info-indent)))))

(defun guix-info-insert-entry (entry entry-type &optional indent-level)
  "Insert ENTRY of ENTRY-TYPE into the current info buffer.
Use `guix-info-insert-ENTRY-TYPE-function' or
`guix-info-insert-entry-default' if it is nil."
  (let* ((var (intern (concat "guix-info-insert-"
                              (symbol-name entry-type)
                              "-function")))
         (fun (symbol-value var)))
    (if (functionp fun)
        (funcall fun entry)
      (guix-info-insert-entry-default entry entry-type indent-level))))

(defun guix-info-insert-param (param entry entry-type)
  "Insert title and value of a PARAM at point.
ENTRY is alist with parameters and their values.
ENTRY-TYPE is a type of ENTRY."
  (let ((val (guix-assq-value entry param)))
    (unless (and guix-info-ignore-empty-vals (null val))
      (let* ((title          (guix-get-param-title entry-type param))
             (insert-methods (guix-info-get-insert-methods entry-type param))
             (val-method     (car insert-methods))
             (title-method   (cadr insert-methods)))
        (guix-info-method-funcall title title-method
                                  #'guix-info-insert-title-default)
        (guix-info-method-funcall val val-method
                                  #'guix-info-insert-val-default
                                  entry)
        (insert "\n")))))

(defun guix-info-method-funcall (val method default-fun &rest args)
  "Call METHOD or DEFAULT-FUN.

If METHOD is a function and VAL is non-nil, call this
function by applying it to VAL and ARGS.

If METHOD is a face, propertize inserted VAL with this face."
  (cond ((or (null method)
             (facep method))
         (funcall default-fun val method))
        ((functionp method)
         (apply method val args))
        (t (error "Unknown method '%S'" method))))

(defun guix-info-insert-title-default (title &optional face format)
  "Insert TITLE formatted with `guix-info-param-title-format' at point."
  (guix-format-insert title
                      (or face 'guix-info-param-title)
                      (or format guix-info-param-title-format)))

(defun guix-info-insert-title-simple (title &optional face)
  "Insert TITLE at point."
  (guix-info-insert-title-default title face "%s:"))

(defun guix-info-insert-val-default (val &optional face)
  "Format and insert parameter value VAL at point.

This function is intended to be called after
`guix-info-insert-title-default'.

If VAL is a one-line string longer than `guix-info-fill-column',
split it into several short lines.  See also
`guix-info-multiline-prefix'.

If FACE is non-nil, propertize inserted line(s) with this FACE."
  (guix-split-insert val face
                     guix-info-fill-column
                     (concat "\n" guix-info-multiline-prefix)))

(defun guix-info-insert-val-simple (val &optional face-or-fun)
  "Format and insert parameter value VAL at point.

This function is intended to be called after
`guix-info-insert-title-simple'.

If VAL is a one-line string longer than `guix-info-fill-column',
split it into several short lines and indent each line with
`guix-info-indent' spaces.

If FACE-OR-FUN is a face, propertize inserted line(s) with this FACE.

If FACE-OR-FUN is a function, call it with VAL as argument.  If
VAL is a list, call the function on each element of this list."
  (if (null val)
      (progn (guix-info-insert-indent)
             (guix-format-insert nil))
    (let ((prefix (concat "\n" (guix-info-get-indent))))
      (insert prefix)
      (if (functionp face-or-fun)
          (guix-mapinsert face-or-fun
                          (if (listp val) val (list val))
                          prefix)
        (guix-split-insert val face-or-fun
                           guix-info-fill-column prefix)))))

(defun guix-info-insert-time (seconds &optional _)
  "Insert formatted time string using SECONDS at point."
  (guix-info-insert-val-default (guix-get-time-string seconds)
                                'guix-info-time))


;;; Buttons

(defvar guix-info-button-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map button-map)
    (define-key map (kbd "c") 'guix-info-button-copy-label)
    map)
  "Keymap for buttons in info buffers.")

(define-button-type 'guix
  'keymap guix-info-button-map
  'follow-link t)

(define-button-type 'guix-action
  :supertype 'guix
  'face 'guix-info-action-button
  'mouse-face 'guix-info-action-button-mouse)

(define-button-type 'guix-file
  :supertype 'guix
  'face 'guix-info-file-path
  'help-echo "Find file"
  'action (lambda (btn)
            (guix-find-file (button-label btn))))

(define-button-type 'guix-url
  :supertype 'guix
  'face 'guix-info-url
  'help-echo "Browse URL"
  'action (lambda (btn)
            (browse-url (button-label btn))))

(define-button-type 'guix-package-location
  :supertype 'guix
  'face 'guix-package-info-location
  'help-echo "Find location of this package"
  'action (lambda (btn)
            (guix-find-location (button-label btn))))

(define-button-type 'guix-package-name
  :supertype 'guix
  'face 'guix-package-info-name-button
  'help-echo "Describe this package"
  'action (lambda (btn)
            (guix-get-show-entries guix-profile 'info guix-package-info-type
                                   'name (button-label btn))))

(defun guix-info-button-copy-label (&optional pos)
  "Copy a label of the button at POS into kill ring.
If POS is nil, use the current point position."
  (interactive)
  (let ((button (button-at (or pos (point)))))
    (when button
      (guix-copy-as-kill (button-label button)))))

(defun guix-info-insert-action-button (label action &optional message
                                             &rest properties)
  "Make action button with LABEL and insert it at point.
ACTION is a function called when the button is pressed.  It
should accept button as the argument.
MESSAGE is a button message.
See `insert-text-button' for the meaning of PROPERTIES."
  (apply #'guix-insert-button
         label 'guix-action
         'action action
         'help-echo message
         properties))

(defun guix-info-insert-file-path (path &optional _)
  "Make button from file PATH and insert it at point."
  (guix-insert-button path 'guix-file))

(defun guix-info-insert-url (url &optional _)
  "Make button from URL and insert it at point."
  (guix-insert-button url 'guix-url))


(defvar guix-info-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent
     map (make-composed-keymap (list guix-root-map button-buffer-map)
                               special-mode-map))
    map)
  "Parent keymap for info buffers.")

(define-derived-mode guix-info-mode special-mode "Guix-Info"
  "Parent mode for displaying information in info buffers.")


;;; Displaying packages

(guix-define-buffer-type info package
  :required (id installed non-unique))

(defface guix-package-info-heading
  '((((type tty pc) (class color)) :weight bold)
    (t :height 1.6 :weight bold :inherit variable-pitch))
  "Face for package name and version headings."
  :group 'guix-package-info-faces)

(defface guix-package-info-name
  '((t :inherit font-lock-keyword-face))
  "Face used for a name of a package."
  :group 'guix-package-info-faces)

(defface guix-package-info-name-button
  '((t :inherit button))
  "Face used for a full name that can be used to describe a package."
  :group 'guix-package-info-faces)

(defface guix-package-info-version
  '((t :inherit font-lock-builtin-face))
  "Face used for a version of a package."
  :group 'guix-package-info-faces)

(defface guix-package-info-synopsis
  '((((type tty pc) (class color)) :weight bold)
    (t :height 1.1 :weight bold :inherit variable-pitch))
  "Face used for a synopsis of a package."
  :group 'guix-package-info-faces)

(defface guix-package-info-description
  '((t))
  "Face used for a description of a package."
  :group 'guix-package-info-faces)

(defface guix-package-info-license
  '((t :inherit font-lock-string-face))
  "Face used for a license of a package."
  :group 'guix-package-info-faces)

(defface guix-package-info-location
  '((t :inherit link))
  "Face used for a location of a package."
  :group 'guix-package-info-faces)

(defface guix-package-info-installed-outputs
  '((default :weight bold)
    (((class color) (min-colors 88) (background light))
     :foreground "ForestGreen")
    (((class color) (min-colors 88) (background dark))
     :foreground "PaleGreen")
    (((class color) (min-colors 8))
     :foreground "green")
    (t :underline t))
  "Face used for installed outputs of a package."
  :group 'guix-package-info-faces)

(defface guix-package-info-uninstalled-outputs
  '((t :weight bold))
  "Face used for uninstalled outputs of a package."
  :group 'guix-package-info-faces)

(defface guix-package-info-obsolete
  '((t :inherit error))
  "Face used if a package is obsolete."
  :group 'guix-package-info-faces)

(defvar guix-info-insert-package-function
  #'guix-package-info-insert-with-heading
  "Function used to insert a package information.
It is called with a single argument - alist of package parameters.
If nil, insert package in a default way.")

(defvar guix-package-info-heading-params '(synopsis description)
  "List of parameters displayed in a heading along with name and version.")

(defcustom guix-package-info-fill-heading t
  "If nil, insert heading parameters in a raw form, without
filling them to fit the window."
  :type 'boolean
  :group 'guix-package-info)

(defun guix-package-info-insert-heading (entry)
  "Insert the heading for package ENTRY.
Show package name, version, and `guix-package-info-heading-params'."
  (guix-format-insert (concat (guix-assq-value entry 'name) " "
                              (guix-assq-value entry 'version))
                      'guix-package-info-heading)
  (insert "\n\n")
  (mapc (lambda (param)
          (let ((val  (guix-assq-value entry param))
                (face (guix-get-symbol (symbol-name param)
                                       'info 'package)))
            (when val
              (let* ((col (min (window-width) fill-column))
                     (val (if guix-package-info-fill-heading
                              (guix-get-filled-string val col)
                            val)))
                (guix-format-insert val (and (facep face) face))
                (insert "\n\n")))))
        guix-package-info-heading-params))

(defun guix-package-info-insert-with-heading (entry)
  "Insert package ENTRY with its heading at point."
  (guix-package-info-insert-heading entry)
  (mapc (lambda (param)
          (unless (or (memq param '(name version))
                      (memq param guix-package-info-heading-params))
            (guix-info-insert-param param entry 'package)))
        (guix-info-get-displayed-params 'package)))

(defun guix-package-info-insert-description (desc &optional _)
  "Insert description DESC at point."
  (guix-info-insert-val-simple desc 'guix-package-info-description))

(defun guix-package-info-insert-location (location &optional _)
  "Make button from file LOCATION and insert it at point."
  (guix-insert-button location 'guix-package-location))

(defmacro guix-package-info-define-insert-inputs (&optional type)
  "Define a face and a function for inserting package inputs.
TYPE is a type of inputs.
Function name is `guix-package-info-insert-TYPE-inputs'.
Face name is `guix-package-info-TYPE-inputs'."
  (let* ((type-str (symbol-name type))
         (type-name (and type (concat type-str "-")))
         (type-desc (and type (concat type-str " ")))
         (face (intern (concat "guix-package-info-" type-name "inputs")))
         (btn  (intern (concat "guix-package-" type-name "input")))
         (fun  (intern (concat "guix-package-info-insert-" type-name "inputs"))))
    `(progn
       (defface ,face
         '((t :inherit guix-package-info-name-button))
         ,(concat "Face used for " type-desc "inputs of a package.")
         :group 'guix-package-info-faces)

       (define-button-type ',btn
         :supertype 'guix-package-name
         'face ',face)

       (defun ,fun (inputs &optional _)
         ,(concat "Make buttons from " type-desc "INPUTS and insert them at point.")
         (guix-package-info-insert-full-names inputs ',btn)))))

(guix-package-info-define-insert-inputs)
(guix-package-info-define-insert-inputs native)
(guix-package-info-define-insert-inputs propagated)

(defun guix-package-info-insert-full-names (names button-type)
  "Make BUTTON-TYPE buttons from package NAMES and insert them at point.
NAMES is a list of strings."
  (if names
      (guix-info-insert-val-default
       (with-temp-buffer
         (guix-mapinsert (lambda (name)
                           (guix-insert-button name button-type))
                         names
                         guix-list-separator)
         (buffer-substring (point-min) (point-max))))
    (guix-format-insert nil)))


;;; Inserting outputs and installed parameters

(defvar guix-package-info-output-format "%-10s"
  "String used to format output names of the packages.
It should be a '%s'-sequence.  After inserting an output name
formatted with this string, an action button is inserted.")

(defvar guix-package-info-obsolete-string "(This package is obsolete)"
  "String used if a package is obsolete.")

(defvar guix-info-insert-installed-function nil
  "Function used to insert an installed information.
It is called with a single argument - alist of installed
parameters (`output', `path', `dependencies').
If nil, insert installed info in a default way.")

(defun guix-package-info-insert-outputs (outputs entry)
  "Insert OUTPUTS from package ENTRY at point."
  (and (guix-assq-value entry 'obsolete)
       (guix-package-info-insert-obsolete-text))
  (and (guix-assq-value entry 'non-unique)
       (guix-assq-value entry 'installed)
       (guix-package-info-insert-non-unique-text
        (guix-get-full-name entry)))
  (insert "\n")
  (mapc (lambda (output)
          (guix-package-info-insert-output output entry))
        outputs))

(defun guix-package-info-insert-obsolete-text ()
  "Insert a message about obsolete package at point."
  (guix-info-insert-indent)
  (guix-format-insert guix-package-info-obsolete-string
                      'guix-package-info-obsolete))

(defun guix-package-info-insert-non-unique-text (full-name)
  "Insert a message about non-unique package with FULL-NAME at point."
  (insert "\n")
  (guix-info-insert-indent)
  (insert "Installed outputs are displayed for a non-unique ")
  (guix-insert-button full-name 'guix-package-name)
  (insert " package."))

(defun guix-package-info-insert-output (output entry)
  "Insert OUTPUT at point.
Make some fancy text with buttons and additional stuff if the
current OUTPUT is installed (if there is such output in
`installed' parameter of a package ENTRY)."
  (let* ((installed (guix-assq-value entry 'installed))
         (obsolete  (guix-assq-value entry 'obsolete))
         (installed-entry (cl-find-if
                           (lambda (entry)
                             (string= (guix-assq-value entry 'output)
                                      output))
                           installed))
         (action-type (if installed-entry 'delete 'install)))
    (guix-info-insert-indent)
    (guix-format-insert output
                        (if installed-entry
                            'guix-package-info-installed-outputs
                          'guix-package-info-uninstalled-outputs)
                        guix-package-info-output-format)
    (guix-package-info-insert-action-button action-type entry output)
    (when obsolete
      (guix-info-insert-indent)
      (guix-package-info-insert-action-button 'upgrade entry output))
    (insert "\n")
    (when installed-entry
      (guix-info-insert-entry installed-entry 'installed 2))))

(defun guix-package-info-insert-action-button (type entry output)
  "Insert button to process an action on a package OUTPUT at point.
TYPE is one of the following symbols: `install', `delete', `upgrade'.
ENTRY is an alist with package info."
  (let ((type-str (capitalize (symbol-name type)))
        (full-name (guix-get-full-name entry output)))
    (guix-info-insert-action-button
     type-str
     (lambda (btn)
       (guix-process-package-actions
        guix-profile
        `((,(button-get btn 'action-type) (,(button-get btn 'id)
                                           ,(button-get btn 'output))))
        (current-buffer)))
     (concat type-str " '" full-name "'")
     'action-type type
     'id (or (guix-assq-value entry 'package-id)
             (guix-assq-value entry 'id))
     'output output)))

(defun guix-package-info-insert-output-path (path &optional _)
  "Insert PATH of the installed output."
  (guix-info-insert-val-simple path #'guix-info-insert-file-path))

(defalias 'guix-package-info-insert-output-dependencies
  'guix-package-info-insert-output-path)


;;; Inserting a source

(defface guix-package-info-source
  '((t :inherit link :underline nil))
  "Face used for a source URL of a package."
  :group 'guix-package-info-faces)

(defcustom guix-package-info-auto-find-source nil
  "If non-nil, find a source file after pressing a \"Show\" button.
If nil, just display the source file path without finding."
  :type 'boolean
  :group 'guix-package-info)

(defcustom guix-package-info-auto-download-source t
  "If nil, do not automatically download a source file if it doesn't exist.
After pressing a \"Show\" button, a derivation of the package
source is calculated and a store file path is displayed.  If this
variable is non-nil and the source file does not exist in the
store, it will be automatically downloaded (with a possible
prompt depending on `guix-operation-confirm' variable)."
  :type 'boolean
  :group 'guix-package-info)

(defvar guix-package-info-download-buffer nil
  "Buffer from which a current download operation was performed.")

(define-button-type 'guix-package-source
  :supertype 'guix
  'face 'guix-package-info-source
  'help-echo ""
  'action (lambda (_)
            ;; As a source may not be a real URL (e.g., "mirror://..."),
            ;; no action is bound to a source button.
            (message "Yes, this is the source URL. What did you expect?")))

(defun guix-package-info-insert-source-url (url &optional _)
  "Make button from source URL and insert it at point."
  (guix-insert-button url 'guix-package-source))

(defun guix-package-info-show-source (entry-id package-id)
  "Show file name of a package source in the current info buffer.
Find the file if needed (see `guix-package-info-auto-find-source').
ENTRY-ID is an ID of the current entry (package or output).
PACKAGE-ID is an ID of the package which source to show."
  (let* ((entry (guix-get-entry-by-id entry-id guix-entries))
         (file  (guix-package-source-path package-id)))
    (or file
        (error "Couldn't define file path of the package source"))
    (let* ((new-entry (cons (cons 'source-file file)
                            entry))
           (entries (cl-substitute-if
                     new-entry
                     (lambda (entry)
                       (equal (guix-assq-value entry 'id)
                              entry-id))
                     guix-entries
                     :count 1)))
      (guix-redisplay-buffer :entries entries)
      (if (file-exists-p file)
          (if guix-package-info-auto-find-source
              (guix-find-file file)
            (message "The source store path is displayed."))
        (if guix-package-info-auto-download-source
            (guix-package-info-download-source package-id)
          (message "The source does not exist in the store."))))))

(defun guix-package-info-download-source (package-id)
  "Download a source of the package PACKAGE-ID."
  (setq guix-package-info-download-buffer (current-buffer))
  (guix-package-source-build-derivation
   package-id
   "The source does not exist in the store. Download it?"))

(defun guix-package-info-insert-source (source entry)
  "Insert SOURCE from package ENTRY at point.
SOURCE is a list of URLs."
  (guix-info-insert-indent)
  (if (null source)
      (guix-format-insert nil)
    (let* ((source-file (guix-assq-value entry 'source-file))
           (entry-id    (guix-assq-value entry 'id))
           (package-id  (or (guix-assq-value entry 'package-id)
                            entry-id)))
      (if (null source-file)
          (guix-info-insert-action-button
           "Show"
           (lambda (btn)
             (guix-package-info-show-source (button-get btn 'entry-id)
                                            (button-get btn 'package-id)))
           "Show the source store path of the current package"
           'entry-id entry-id
           'package-id package-id)
        (unless (file-exists-p source-file)
          (guix-info-insert-action-button
           "Download"
           (lambda (btn)
             (guix-package-info-download-source
              (button-get btn 'package-id)))
           "Download the source into the store"
           'package-id package-id))
        (guix-info-insert-val-simple source-file
                                     #'guix-info-insert-file-path))
      (guix-info-insert-val-simple source
                                   #'guix-package-info-insert-source-url))))

(defun guix-package-info-redisplay-after-download ()
  "Redisplay an 'info' buffer after downloading the package source.
This function is used to hide a \"Download\" button if needed."
  (when (buffer-live-p guix-package-info-download-buffer)
    (guix-redisplay-buffer :buffer guix-package-info-download-buffer)
    (setq guix-package-info-download-buffer nil)))

(add-hook 'guix-after-source-download-hook
          'guix-package-info-redisplay-after-download)


;;; Displaying outputs

(guix-define-buffer-type info output
  :buffer-name "*Guix Package Info*"
  :required (id package-id installed non-unique))

(defvar guix-info-insert-output-function nil
  "Function used to insert an output information.
It is called with a single argument - alist of output parameters.
If nil, insert output in a default way.")

(defun guix-output-info-insert-version (version entry)
  "Insert output VERSION and obsolete text if needed at point."
  (guix-info-insert-val-default version
                                'guix-package-info-version)
  (and (guix-assq-value entry 'obsolete)
       (guix-package-info-insert-obsolete-text)))

(defun guix-output-info-insert-output (output entry)
  "Insert OUTPUT and action buttons at point."
  (let* ((installed (guix-assq-value entry 'installed))
         (obsolete  (guix-assq-value entry 'obsolete))
         (action-type (if installed 'delete 'install)))
    (guix-info-insert-val-default
     output
     (if installed
         'guix-package-info-installed-outputs
       'guix-package-info-uninstalled-outputs))
    (guix-info-insert-indent)
    (guix-package-info-insert-action-button action-type entry output)
    (when obsolete
      (guix-info-insert-indent)
      (guix-package-info-insert-action-button 'upgrade entry output))))


;;; Displaying generations

(guix-define-buffer-type info generation)

(defface guix-generation-info-number
  '((t :inherit font-lock-keyword-face))
  "Face used for a number of a generation."
  :group 'guix-generation-info-faces)

(defface guix-generation-info-current
  '((t :inherit guix-package-info-installed-outputs))
  "Face used if a generation is the current one."
  :group 'guix-generation-info-faces)

(defface guix-generation-info-not-current
  '((t nil))
  "Face used if a generation is not the current one."
  :group 'guix-generation-info-faces)

(defvar guix-info-insert-generation-function nil
  "Function used to insert a generation information.
It is called with a single argument - alist of generation parameters.
If nil, insert generation in a default way.")

(defun guix-generation-info-insert-number (number &optional _)
  "Insert generation NUMBER and action buttons."
  (guix-info-insert-val-default number 'guix-generation-info-number)
  (guix-info-insert-indent)
  (guix-info-insert-action-button
   "Packages"
   (lambda (btn)
     (guix-get-show-entries guix-profile 'list guix-package-list-type
                            'generation (button-get btn 'number)))
   "Show installed packages for this generation"
   'number number)
  (guix-info-insert-indent)
  (guix-info-insert-action-button
   "Delete"
   (lambda (btn)
     (guix-delete-generations guix-profile (list (button-get btn 'number))
                              (current-buffer)))
   "Delete this generation"
   'number number))

(defun guix-generation-info-insert-current (val entry)
  "Insert boolean value VAL showing whether this generation is current."
  (if val
      (guix-info-insert-val-default "Yes" 'guix-generation-info-current)
    (guix-info-insert-val-default "No" 'guix-generation-info-not-current)
    (guix-info-insert-indent)
    (guix-info-insert-action-button
     "Switch"
     (lambda (btn)
       (guix-switch-to-generation guix-profile (button-get btn 'number)
                                  (current-buffer)))
     "Switch to this generation (make it the current one)"
     'number (guix-assq-value entry 'number))))

(provide 'guix-info)

;;; guix-info.el ends here
