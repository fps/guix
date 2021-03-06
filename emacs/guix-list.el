;;; guix-list.el --- List buffers for displaying entries   -*- lexical-binding: t -*-

;; Copyright © 2014, 2015 Alex Kost <alezost@gmail.com>

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

;; This file provides a list-like buffer for displaying information
;; about Guix packages and generations.

;;; Code:

(require 'cl-lib)
(require 'tabulated-list)
(require 'guix-info)
(require 'guix-base)
(require 'guix-utils)

(defgroup guix-list nil
  "General settings for list buffers."
  :prefix "guix-list-"
  :group 'guix)

(defgroup guix-list-faces nil
  "Faces for list buffers."
  :group 'guix-list
  :group 'guix-faces)

(defface guix-list-file-path
  '((t :inherit guix-info-file-path))
  "Face used for file paths."
  :group 'guix-list-faces)

(defcustom guix-list-describe-warning-count 10
  "The maximum number of entries for describing without a warning.
If a user wants to describe more than this number of marked
entries, he will be prompted for confirmation."
  :type 'integer
  :group 'guix-list)

(defvar guix-list-column-format
  `((package
     (name 20 t)
     (version 10 nil)
     (outputs 13 t)
     (installed 13 t)
     (synopsis 30 nil))
    (output
     (name 20 t)
     (version 10 nil)
     (output 9 t)
     (installed 12 t)
     (synopsis 30 nil))
    (generation
     (number 5
             ,(lambda (a b) (guix-list-sort-numerically 0 a b))
             :right-align t)
     (current 10 t)
     (time 20 t)
     (path 30 t)))
  "Columns displayed in list buffers.
Each element of the list has a form:

  (ENTRY-TYPE . ((PARAM WIDTH SORT . PROPS) ...))

PARAM is the name of an entry parameter of ENTRY-TYPE.  For the
meaning of WIDTH, SORT and PROPS, see `tabulated-list-format'.")

(defvar guix-list-column-titles
  '((generation
     (number . "N.")))
  "Column titles for list buffers.
Has the same structure as `guix-param-titles', but titles from
this list have a priority.")

(defvar guix-list-column-value-methods
  '((package
     (name        . guix-package-list-get-name)
     (synopsis    . guix-list-get-one-line)
     (description . guix-list-get-one-line)
     (installed   . guix-package-list-get-installed-outputs))
    (output
     (name        . guix-package-list-get-name)
     (synopsis    . guix-list-get-one-line)
     (description . guix-list-get-one-line))
    (generation
     (current     . guix-generation-list-get-current)
     (time        . guix-list-get-time)
     (path        . guix-list-get-file-path)))
  "Methods for inserting parameter values in columns.
Each element of the list has a form:

  (ENTRY-TYPE . ((PARAM . FUN) ...))

PARAM is the name of an entry parameter of ENTRY-TYPE.

FUN is a function returning a value that will be inserted.  The
function is called with 2 arguments: the first one is the value
of the parameter; the second argument is an entry info (alist of
parameters and their values).")

(defun guix-list-get-param-title (entry-type param)
  "Return title of an ENTRY-TYPE entry parameter PARAM."
  (or (guix-assq-value guix-list-column-titles
                       entry-type param)
      (guix-get-param-title entry-type param)))

(defun guix-list-get-column-format (entry-type)
  "Return column format for ENTRY-TYPE."
  (guix-assq-value guix-list-column-format entry-type))

(defun guix-list-get-displayed-params (entry-type)
  "Return list of parameters of ENTRY-TYPE that should be displayed."
  (mapcar #'car
          (guix-list-get-column-format entry-type)))

(defun guix-list-get-sort-key (entry-type param &optional invert)
  "Return suitable sort key for `tabulated-list-sort-key'.
Define column title by ENTRY-TYPE and PARAM.  If INVERT is
non-nil, invert the sort."
  (when (memq param (guix-list-get-displayed-params entry-type))
    (cons (guix-list-get-param-title entry-type param) invert)))

(defun guix-list-sort-numerically (column a b)
  "Compare COLUMN of tabulated entries A and B numerically.
It is a sort predicate for `tabulated-list-format'.
Return non-nil, if B is bigger than A."
  (cl-flet ((num (entry)
              (string-to-number (aref (cadr entry) column))))
    (> (num b) (num a))))

(defun guix-list-make-tabulated-vector (entry-type fun)
  "Call FUN on each column specification for ENTRY-TYPE.

FUN is called with 2 argument: parameter name and column
specification (see `guix-list-column-format').

Return a vector made of values of FUN calls."
  (apply #'vector
         (mapcar (lambda (col-spec)
                   (funcall fun (car col-spec) (cdr col-spec)))
                 (guix-list-get-column-format entry-type))))

(defun guix-list-get-list-format (entry-type)
  "Return ENTRY-TYPE list specification for `tabulated-list-format'."
  (guix-list-make-tabulated-vector
   entry-type
   (lambda (param spec)
     (cons (guix-list-get-param-title entry-type param)
           spec))))

(defun guix-list-insert-entries (entries entry-type)
  "Display ENTRIES of ENTRY-TYPE in the current list buffer.
ENTRIES should have a form of `guix-entries'."
  (setq tabulated-list-entries
        (guix-list-get-tabulated-entries entries entry-type))
  (tabulated-list-print))

(defun guix-list-get-tabulated-entries (entries entry-type)
  "Return list of values of ENTRY-TYPE for `tabulated-list-entries'.
Values are taken from ENTRIES which should have the form of
`guix-entries'."
  (mapcar (lambda (entry)
            (list (guix-assq-value entry 'id)
                  (guix-list-get-tabulated-entry entry entry-type)))
          entries))

(defun guix-list-get-tabulated-entry (entry entry-type)
  "Return array of values for `tabulated-list-entries'.
Parameters are taken from ENTRY of ENTRY-TYPE."
  (guix-list-make-tabulated-vector
   entry-type
   (lambda (param _)
     (let ((val (guix-assq-value entry param))
           (fun (guix-assq-value guix-list-column-value-methods
                                 entry-type param)))
       (if fun
           (funcall fun val entry)
         (guix-get-string val))))))

(defun guix-list-get-one-line (val &optional _)
  "Return one-line string from a multi-line string VAL.
VAL may be nil."
  (if val
      (guix-get-one-line val)
    (guix-get-string nil)))

(defun guix-list-get-time (seconds &optional _)
  "Return formatted time string from SECONDS."
  (guix-get-time-string seconds))

(defun guix-list-get-file-path (path &optional _)
  "Return PATH button specification for `tabulated-list-entries'."
  (list path
        'face 'guix-list-file-path
        'action (lambda (btn) (find-file (button-label btn)))
        'follow-link t
        'help-echo "Find file"))

(defun guix-list-current-id ()
  "Return ID of the current entry."
  (or (tabulated-list-get-id)
      (user-error "No entry here")))

(defun guix-list-current-entry ()
  "Return alist of the current entry info."
  (guix-get-entry-by-id (guix-list-current-id) guix-entries))

(defun guix-list-current-package-id ()
  "Return ID of the current package."
  (cl-ecase major-mode
    (guix-package-list-mode
     (guix-list-current-id))
    (guix-output-list-mode
     (guix-assq-value (guix-list-current-entry) 'package-id))))

(defun guix-list-for-each-line (fun &rest args)
  "Call FUN with ARGS for each entry line."
  (or (derived-mode-p 'guix-list-mode)
      (error "The current buffer is not in Guix List mode"))
  (save-excursion
    (goto-char (point-min))
    (while (not (eobp))
      (apply fun args)
      (forward-line))))

(defun guix-list-fold-lines (fun init)
  "Fold over entry lines in the current list buffer.
Call FUN with RESULT as argument for each line, using INIT as
the initial value of RESULT.  Return the final result."
  (let ((res init))
    (guix-list-for-each-line
     (lambda () (setq res (funcall fun res))))
    res))


;;; Marking and sorting

(defvar-local guix-list-marked nil
  "List of the marked entries.
Each element of the list has a form:

  (ID MARK-NAME . ARGS)

ID is an entry ID.
MARK-NAME is a symbol from `guix-list-mark-alist'.
ARGS is a list of additional values.")

(defvar guix-list-mark-alist
  '((empty   . ?\s)
    (general . ?*))
  "Alist of available mark names and mark characters.")

(defsubst guix-list-get-mark (name)
  "Return mark character by its NAME."
  (or (guix-assq-value guix-list-mark-alist name)
      (error "Mark '%S' not found" name)))

(defsubst guix-list-get-mark-string (name)
  "Return mark string by its NAME."
  (string (guix-list-get-mark name)))

(defun guix-list-current-mark ()
  "Return mark character of the current line."
  (char-after (line-beginning-position)))

(defun guix-list-get-marked (&rest mark-names)
  "Return list of specs of entries marked with any mark from MARK-NAMES.
Entry specs are elements from `guix-list-marked' list.
If MARK-NAMES are not specified, use all marks from
`guix-list-mark-alist' except the `empty' one."
  (or mark-names
      (setq mark-names
            (delq 'empty
                  (mapcar #'car guix-list-mark-alist))))
  (cl-remove-if-not (lambda (assoc)
                      (memq (cadr assoc) mark-names))
                    guix-list-marked))

(defun guix-list-get-marked-args (mark-name)
  "Return list of (ID . ARGS) elements from lines marked with MARK-NAME.
See `guix-list-marked' for the meaning of ARGS."
  (mapcar (lambda (spec)
            (let ((id (car spec))
                  (args (cddr spec)))
              (cons id args)))
          (guix-list-get-marked mark-name)))

(defun guix-list-get-marked-id-list (&rest mark-names)
  "Return list of IDs of entries marked with any mark from MARK-NAMES.
See `guix-list-get-marked' for details."
  (mapcar #'car (apply #'guix-list-get-marked mark-names)))

(defun guix-list--mark (mark-name &optional advance &rest args)
  "Put a mark on the current line.
Also add the current entry to `guix-list-marked' using its ID and ARGS.
MARK-NAME is a symbol from `guix-list-mark-alist'.
If ADVANCE is non-nil, move forward by one line after marking."
  (let ((id (guix-list-current-id)))
    (if (eq mark-name 'empty)
        (setq guix-list-marked (assq-delete-all id guix-list-marked))
      (let ((assoc (assq id guix-list-marked))
            (val (cons mark-name args)))
        (if assoc
            (setcdr assoc val)
          (push (cons id val) guix-list-marked)))))
  (tabulated-list-put-tag (guix-list-get-mark-string mark-name)
                          advance))

(defun guix-list-mark (&optional arg)
  "Mark the current line and move to the next line.
With ARG, mark all lines."
  (interactive "P")
  (if arg
      (guix-list-mark-all)
    (guix-list--mark 'general t)))

(defun guix-list-mark-all (&optional mark-name)
  "Mark all lines with MARK-NAME mark.
MARK-NAME is a symbol from `guix-list-mark-alist'.
Interactively, put a general mark on all lines."
  (interactive)
  (or mark-name (setq mark-name 'general))
  (guix-list-for-each-line #'guix-list--mark mark-name))

(defun guix-list-unmark (&optional arg)
  "Unmark the current line and move to the next line.
With ARG, unmark all lines."
  (interactive "P")
  (if arg
      (guix-list-unmark-all)
    (guix-list--mark 'empty t)))

(defun guix-list-unmark-backward ()
  "Move up one line and unmark it."
  (interactive)
  (forward-line -1)
  (guix-list--mark 'empty))

(defun guix-list-unmark-all ()
  "Unmark all lines."
  (interactive)
  (guix-list-mark-all 'empty))

(defun guix-list-restore-marks ()
  "Put marks according to `guix-list-mark-alist'."
  (guix-list-for-each-line
   (lambda ()
     (let ((mark-name (car (guix-assq-value guix-list-marked
                                            (guix-list-current-id)))))
       (tabulated-list-put-tag
        (guix-list-get-mark-string (or mark-name 'empty)))))))

(defun guix-list-sort (&optional n)
  "Sort guix list entries by the column at point.
With a numeric prefix argument N, sort the Nth column.
Same as `tabulated-list-sort', but also restore marks after sorting."
  (interactive "P")
  (tabulated-list-sort n)
  (guix-list-restore-marks))


(defvar guix-list-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent
     map (make-composed-keymap guix-root-map
                               tabulated-list-mode-map))
    (define-key map (kbd "RET") 'guix-list-describe)
    (define-key map (kbd "m")   'guix-list-mark)
    (define-key map (kbd "*")   'guix-list-mark)
    (define-key map (kbd "u")   'guix-list-unmark)
    (define-key map (kbd "DEL") 'guix-list-unmark-backward)
    (define-key map [remap tabulated-list-sort] 'guix-list-sort)
    map)
  "Parent keymap for list buffers.")

(define-derived-mode guix-list-mode tabulated-list-mode "Guix-List"
  "Parent mode for displaying information in list buffers."
  (setq tabulated-list-padding 2))

(defmacro guix-list-define-entry-type (entry-type &rest args)
  "Define common stuff for displaying ENTRY-TYPE entries in list buffers.

Remaining argument (ARGS) should have a form [KEYWORD VALUE] ...  The
following keywords are available:

  - `:sort-key' - default sort key for the tabulated list buffer.

  - `:invert-sort' - if non-nil, invert initial sort.

  - `:marks' - default value for the defined
    `guix-ENTRY-TYPE-mark-alist' variable.

This macro defines the following functions:

  - `guix-ENTRY-TYPE-mark-MARK-NAME' functions for each mark
    specified in `:marks' argument."
  (let* ((entry-type-str (symbol-name entry-type))
         (prefix         (concat "guix-" entry-type-str "-list"))
         (mode-str       (concat prefix "-mode"))
         (init-fun       (intern (concat prefix "-mode-initialize")))
         (marks-var      (intern (concat prefix "-mark-alist")))
         (marks-val      nil)
         (sort-key       nil)
         (invert-sort    nil))

    ;; Process the keyword args.
    (while (keywordp (car args))
      (pcase (pop args)
        (`:sort-key    (setq sort-key (pop args)))
        (`:invert-sort (setq invert-sort (pop args)))
	(`:marks       (setq marks-val (pop args)))
	(_ (pop args))))

    `(progn
       (defvar ,marks-var ',marks-val
         ,(concat "Alist of additional marks for `" mode-str "'.\n"
                  "Marks from this list are added to `guix-list-mark-alist'."))

       ,@(mapcar (lambda (mark-spec)
                   (let* ((mark-name (car mark-spec))
                          (mark-name-str (symbol-name mark-name)))
                     `(defun ,(intern (concat prefix "-mark-" mark-name-str "-simple")) ()
                        ,(concat "Put '" mark-name-str "' mark and move to the next line.\n"
                                 "Also add the current entry to `guix-list-marked'.")
                        (interactive)
                        (guix-list--mark ',mark-name t))))
                 marks-val)

       (defun ,init-fun ()
         ,(concat "Initial settings for `" mode-str "'.")
         ,(when sort-key
            `(setq tabulated-list-sort-key
                   (guix-list-get-sort-key
                    ',entry-type ',sort-key ,invert-sort)))
         (setq tabulated-list-format
               (guix-list-get-list-format ',entry-type))
         (setq-local guix-list-mark-alist
                     (append guix-list-mark-alist ,marks-var))
         (tabulated-list-init-header)))))

(put 'guix-list-define-entry-type 'lisp-indent-function 'defun)

(defun guix-list-describe-maybe (entry-type ids)
  "Describe ENTRY-TYPE entries in info buffer using list of IDS."
  (let ((count (length ids)))
    (when (or (<= count guix-list-describe-warning-count)
              (y-or-n-p (format "Do you really want to describe %d entries? "
                                count)))
      (apply #'guix-get-show-entries
             guix-profile 'info entry-type 'id ids))))

(defun guix-list-describe (&optional arg)
  "Describe entries marked with a general mark.
If no entries are marked, describe the current entry.
With prefix (if ARG is non-nil), describe entries marked with any mark."
  (interactive "P")
  (let ((ids (or (apply #'guix-list-get-marked-id-list
                        (unless arg '(general)))
                 (list (guix-list-current-id)))))
    (guix-list-describe-maybe guix-entry-type ids)))

(defun guix-list-edit-package ()
  "Go to the location of the current package."
  (interactive)
  (guix-edit (guix-list-current-package-id)))


;;; Displaying packages

(guix-define-buffer-type list package)

(guix-list-define-entry-type package
  :sort-key name
  :marks ((install . ?I)
          (upgrade . ?U)
          (delete  . ?D)))

(defface guix-package-list-installed
  '((t :inherit guix-package-info-installed-outputs))
  "Face used if there are installed outputs for the current package."
  :group 'guix-package-list-faces)

(defface guix-package-list-obsolete
  '((t :inherit guix-package-info-obsolete))
  "Face used if a package is obsolete."
  :group 'guix-package-list-faces)

(defcustom guix-package-list-generation-marking-enabled nil
  "If non-nil, allow putting marks in a list with 'generation packages'.

By default this is disabled, because it may be confusing.  For
example a package is installed in some generation, so a user can
mark it for deletion in the list of packages from this
generation, but the package may not be installed in the latest
generation, so actually it cannot be deleted.

If you managed to understand the explanation above or if you
really know what you do or if you just don't care, you can set
this variable to t.  It should not do much harm anyway (most
likely)."
  :type 'boolean
  :group 'guix-package-list)

(let ((map guix-package-list-mode-map))
  (define-key map (kbd "e")   'guix-list-edit-package)
  (define-key map (kbd "x")   'guix-package-list-execute)
  (define-key map (kbd "i")   'guix-package-list-mark-install)
  (define-key map (kbd "d")   'guix-package-list-mark-delete)
  (define-key map (kbd "U")   'guix-package-list-mark-upgrade)
  (define-key map (kbd "^")   'guix-package-list-mark-upgrades))

(defun guix-package-list-get-name (name entry)
  "Return NAME of the package ENTRY.
Colorize it with `guix-package-list-installed' or
`guix-package-list-obsolete' if needed."
  (guix-get-string name
                   (cond ((guix-assq-value entry 'obsolete)
                          'guix-package-list-obsolete)
                         ((guix-assq-value entry 'installed)
                          'guix-package-list-installed))))

(defun guix-package-list-get-installed-outputs (installed &optional _)
  "Return string with outputs from INSTALLED entries."
  (guix-get-string
   (mapcar (lambda (entry)
             (guix-assq-value entry 'output))
           installed)))

(defun guix-package-list-marking-check ()
  "Signal an error if marking is disabled for the current buffer."
  (when (and (not guix-package-list-generation-marking-enabled)
             (or (derived-mode-p 'guix-package-list-mode)
                 (derived-mode-p 'guix-output-list-mode))
             (eq guix-search-type 'generation))
    (error "Action marks are disabled for lists of 'generation packages'")))

(defun guix-package-list-mark-outputs (mark default
                                       &optional prompt available)
  "Mark the current package with MARK and move to the next line.
If PROMPT is non-nil, use it to ask a user for outputs from
AVAILABLE list, otherwise mark all DEFAULT outputs."
  (let ((outputs (if prompt
                     (guix-completing-read-multiple
                      prompt available nil t)
                   default)))
    (apply #'guix-list--mark mark t outputs)))

(defun guix-package-list-mark-install (&optional arg)
  "Mark the current package for installation and move to the next line.
With ARG, prompt for the outputs to install (several outputs may
be separated with \",\")."
  (interactive "P")
  (guix-package-list-marking-check)
  (let* ((entry     (guix-list-current-entry))
         (all       (guix-assq-value entry 'outputs))
         (installed (guix-get-installed-outputs entry))
         (available (cl-set-difference all installed :test #'string=)))
    (or available
        (user-error "This package is already installed"))
    (guix-package-list-mark-outputs
     'install '("out")
     (and arg "Output(s) to install: ")
     available)))

(defun guix-package-list-mark-delete (&optional arg)
  "Mark the current package for deletion and move to the next line.
With ARG, prompt for the outputs to delete (several outputs may
be separated with \",\")."
  (interactive "P")
  (guix-package-list-marking-check)
  (let* ((entry (guix-list-current-entry))
         (installed (guix-get-installed-outputs entry)))
    (or installed
        (user-error "This package is not installed"))
    (guix-package-list-mark-outputs
     'delete installed
     (and arg "Output(s) to delete: ")
     installed)))

(defun guix-package-list-mark-upgrade (&optional arg)
  "Mark the current package for upgrading and move to the next line.
With ARG, prompt for the outputs to upgrade (several outputs may
be separated with \",\")."
  (interactive "P")
  (guix-package-list-marking-check)
  (let* ((entry (guix-list-current-entry))
         (installed (guix-get-installed-outputs entry)))
    (or installed
        (user-error "This package is not installed"))
    (when (or (guix-assq-value entry 'obsolete)
              (y-or-n-p "This package is not obsolete.  Try to upgrade it anyway? "))
      (guix-package-list-mark-outputs
       'upgrade installed
       (and arg "Output(s) to upgrade: ")
       installed))))

(defun guix-list-mark-package-upgrades (fun)
  "Mark all obsolete packages for upgrading.
Use FUN to perform marking of the current line.  FUN should
accept an entry as argument."
  (guix-package-list-marking-check)
  (let ((obsolete (cl-remove-if-not
                   (lambda (entry)
                     (guix-assq-value entry 'obsolete))
                   guix-entries)))
    (guix-list-for-each-line
     (lambda ()
       (let* ((id (guix-list-current-id))
              (entry (cl-find-if
                      (lambda (entry)
                        (equal id (guix-assq-value entry 'id)))
                      obsolete)))
         (when entry
           (funcall fun entry)))))))

(defun guix-package-list-mark-upgrades ()
  "Mark all obsolete packages for upgrading."
  (interactive)
  (guix-list-mark-package-upgrades
   (lambda (entry)
     (apply #'guix-list--mark
            'upgrade nil
            (guix-get-installed-outputs entry)))))

(defun guix-list-execute-package-actions (fun)
  "Perform actions on the marked packages.
Use FUN to define actions suitable for `guix-process-package-actions'.
FUN should accept action-type as argument."
  (let ((actions (delq nil
                       (mapcar fun '(install delete upgrade)))))
    (if actions
        (guix-process-package-actions
         guix-profile actions (current-buffer))
      (user-error "No operations specified"))))

(defun guix-package-list-execute ()
  "Perform actions on the marked packages."
  (interactive)
  (guix-list-execute-package-actions #'guix-package-list-make-action))

(defun guix-package-list-make-action (action-type)
  "Return action specification for the packages marked with ACTION-TYPE.
Return nil, if there are no packages marked with ACTION-TYPE.
The specification is suitable for `guix-process-package-actions'."
  (let ((specs (guix-list-get-marked-args action-type)))
    (and specs (cons action-type specs))))


;;; Displaying outputs

(guix-define-buffer-type list output
  :buffer-name "*Guix Package List*"
  :required (package-id))

(guix-list-define-entry-type output
  :sort-key name
  :marks ((install . ?I)
          (upgrade . ?U)
          (delete  . ?D)))

(let ((map guix-output-list-mode-map))
  (define-key map (kbd "RET") 'guix-output-list-describe)
  (define-key map (kbd "e")   'guix-list-edit-package)
  (define-key map (kbd "x")   'guix-output-list-execute)
  (define-key map (kbd "i")   'guix-output-list-mark-install)
  (define-key map (kbd "d")   'guix-output-list-mark-delete)
  (define-key map (kbd "U")   'guix-output-list-mark-upgrade)
  (define-key map (kbd "^")   'guix-output-list-mark-upgrades))

(defun guix-output-list-mark-install ()
  "Mark the current output for installation and move to the next line."
  (interactive)
  (guix-package-list-marking-check)
  (let* ((entry     (guix-list-current-entry))
         (installed (guix-assq-value entry 'installed)))
    (if installed
        (user-error "This output is already installed")
      (guix-list--mark 'install t))))

(defun guix-output-list-mark-delete ()
  "Mark the current output for deletion and move to the next line."
  (interactive)
  (guix-package-list-marking-check)
  (let* ((entry     (guix-list-current-entry))
         (installed (guix-assq-value entry 'installed)))
    (if installed
        (guix-list--mark 'delete t)
      (user-error "This output is not installed"))))

(defun guix-output-list-mark-upgrade ()
  "Mark the current output for deletion and move to the next line."
  (interactive)
  (guix-package-list-marking-check)
  (let* ((entry     (guix-list-current-entry))
         (installed (guix-assq-value entry 'installed)))
    (or installed
        (user-error "This output is not installed"))
    (when (or (guix-assq-value entry 'obsolete)
              (y-or-n-p "This output is not obsolete.  Try to upgrade it anyway? "))
      (guix-list--mark 'upgrade t))))

(defun guix-output-list-mark-upgrades ()
  "Mark all obsolete package outputs for upgrading."
  (interactive)
  (guix-list-mark-package-upgrades
   (lambda (_) (guix-list--mark 'upgrade))))

(defun guix-output-list-execute ()
  "Perform actions on the marked outputs."
  (interactive)
  (guix-list-execute-package-actions #'guix-output-list-make-action))

(defun guix-output-list-make-action (action-type)
  "Return action specification for the outputs marked with ACTION-TYPE.
Return nil, if there are no outputs marked with ACTION-TYPE.
The specification is suitable for `guix-process-output-actions'."
  (let ((ids (guix-list-get-marked-id-list action-type)))
    (and ids (cons action-type
                   (mapcar #'guix-get-package-id-and-output-by-output-id
                           ids)))))

(defun guix-output-list-describe (&optional arg)
  "Describe outputs or packages marked with a general mark.
If no entries are marked, describe the current output or package.
With prefix (if ARG is non-nil), describe entries marked with any mark.
Also see `guix-package-info-type'."
  (interactive "P")
  (if (eq guix-package-info-type 'output)
      (guix-list-describe arg)
    (let* ((oids (or (apply #'guix-list-get-marked-id-list
                            (unless arg '(general)))
                     (list (guix-list-current-id))))
           (pids (mapcar (lambda (oid)
                           (car (guix-get-package-id-and-output-by-output-id
                                 oid)))
                         oids)))
      (guix-list-describe-maybe 'package (cl-remove-duplicates pids)))))


;;; Displaying generations

(guix-define-buffer-type list generation)

(guix-list-define-entry-type generation
  :sort-key number
  :invert-sort t
  :marks ((delete . ?D)))

(let ((map guix-generation-list-mode-map))
  (define-key map (kbd "RET") 'guix-generation-list-show-packages)
  (define-key map (kbd "+")   'guix-generation-list-show-added-packages)
  (define-key map (kbd "-")   'guix-generation-list-show-removed-packages)
  (define-key map (kbd "=")   'guix-generation-list-diff)
  (define-key map (kbd "D")   'guix-generation-list-diff)
  (define-key map (kbd "e")   'guix-generation-list-ediff)
  (define-key map (kbd "x")   'guix-generation-list-execute)
  (define-key map (kbd "i")   'guix-list-describe)
  (define-key map (kbd "s")   'guix-generation-list-switch)
  (define-key map (kbd "d")   'guix-generation-list-mark-delete))

(defun guix-generation-list-get-current (val &optional _)
  "Return string from VAL showing whether this generation is current.
VAL is a boolean value."
  (if val "(current)" ""))

(defun guix-generation-list-switch ()
  "Switch current profile to the generation at point."
  (interactive)
  (let* ((entry   (guix-list-current-entry))
         (current (guix-assq-value entry 'current))
         (number  (guix-assq-value entry 'number)))
    (if current
        (user-error "This generation is already the current one")
      (guix-switch-to-generation guix-profile number (current-buffer)))))

(defun guix-generation-list-show-packages ()
  "List installed packages for the generation at point."
  (interactive)
  (guix-get-show-entries guix-profile 'list guix-package-list-type
                         'generation (guix-list-current-id)))

(defun guix-generation-list-generations-to-compare ()
  "Return a sorted list of 2 marked generations for comparing."
  (let ((numbers (guix-list-get-marked-id-list 'general)))
    (if (/= (length numbers) 2)
        (user-error "2 generations should be marked for comparing")
      (sort numbers #'<))))

(defun guix-generation-list-show-added-packages ()
  "List package outputs added to the latest marked generation.
If 2 generations are marked with \\[guix-list-mark], display
outputs installed in the latest marked generation that were not
installed in the other one."
  (interactive)
  (apply #'guix-get-show-entries
         guix-profile 'list 'output 'generation-diff
         (reverse (guix-generation-list-generations-to-compare))))

(defun guix-generation-list-show-removed-packages ()
  "List package outputs removed from the latest marked generation.
If 2 generations are marked with \\[guix-list-mark], display
outputs not installed in the latest marked generation that were
installed in the other one."
  (interactive)
  (apply #'guix-get-show-entries
         guix-profile 'list 'output 'generation-diff
         (guix-generation-list-generations-to-compare)))

(defun guix-generation-list-compare (diff-fun gen-fun)
  "Run GEN-FUN on the 2 marked generations and run DIFF-FUN on the results."
  (cl-multiple-value-bind (gen1 gen2)
      (guix-generation-list-generations-to-compare)
    (funcall diff-fun
             (funcall gen-fun gen1)
             (funcall gen-fun gen2))))

(defun guix-generation-list-ediff-manifests ()
  "Run Ediff on manifests of the 2 marked generations."
  (interactive)
  (guix-generation-list-compare
   #'ediff-files
   #'guix-profile-generation-manifest-file))

(defun guix-generation-list-diff-manifests ()
  "Run Diff on manifests of the 2 marked generations."
  (interactive)
  (guix-generation-list-compare
   #'guix-diff
   #'guix-profile-generation-manifest-file))

(defun guix-generation-list-ediff-packages ()
  "Run Ediff on package outputs installed in the 2 marked generations."
  (interactive)
  (guix-generation-list-compare
   #'ediff-buffers
   #'guix-profile-generation-packages-buffer))

(defun guix-generation-list-diff-packages ()
  "Run Diff on package outputs installed in the 2 marked generations."
  (interactive)
  (guix-generation-list-compare
   #'guix-diff
   #'guix-profile-generation-packages-buffer))

(defun guix-generation-list-ediff (arg)
  "Run Ediff on package outputs installed in the 2 marked generations.
With ARG, run Ediff on manifests of the marked generations."
  (interactive "P")
  (if arg
      (guix-generation-list-ediff-manifests)
    (guix-generation-list-ediff-packages)))

(defun guix-generation-list-diff (arg)
  "Run Diff on package outputs installed in the 2 marked generations.
With ARG, run Diff on manifests of the marked generations."
  (interactive "P")
  (if arg
      (guix-generation-list-diff-manifests)
    (guix-generation-list-diff-packages)))

(defun guix-generation-list-mark-delete (&optional arg)
  "Mark the current generation for deletion and move to the next line.
With ARG, mark all generations for deletion."
  (interactive "P")
  (if arg
      (guix-list-mark-all 'delete)
    (guix-list--mark 'delete t)))

(defun guix-generation-list-execute ()
  "Delete marked generations."
  (interactive)
  (let ((marked (guix-list-get-marked-id-list 'delete)))
    (or marked
        (user-error "No generations marked for deletion"))
    (guix-delete-generations guix-profile marked (current-buffer))))

(provide 'guix-list)

;;; guix-list.el ends here
