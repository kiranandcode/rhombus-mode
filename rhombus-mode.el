;;; rhombus-mode.el --- GNU+Emacs mode for Rhombus   -*- lexical-binding: t; -*-

;; Copyright (C) 2023  Kiran Gopinathan

;; Author: Kiran Gopinathan <kirang@comp.nus.edu.sg>
;; Keywords: 

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <https://www.gnu.org/licenses/>.

;;; Commentary:

;;; Code:

;;;; Variables 

(defvar rhombus-nav-beginning-of-defun-regexp
  (rx line-start (* space) (seq symbol-start (or "fun" "def" "val") symbol-end) (+ (or space (and ?\\ ?\n)))
             (group (seq (any letter ?_) (* (any word ?_)))))
  "Regexp matching class or function definition.
The name of the defun should be grouped so it can be retrieved
via `match-string'.")

(defvar rhombus-nav-beginning-of-block-regexp
  (rx line-start (* space) (* (not "\n")) ":\n")
  "Regexp matching block start.")

;;;; Customisation 

(defcustom rhombus-indent-offset 2
  "Default indentation offset for rhombus."
  :type 'integer
  :safe 'integerp)

;;;; Navigation
(defun rhombus-beginning-of-defun (&optional arg)
  "Move to beginning of current defun. With positive ARG search backwards, else search forwards."
  (interactive)
  (when (or (null arg) (= arg 0)) (setq arg 1))
  
  (let* ((re-search-fn (if (> arg 0) #'re-search-backward #'re-search-forward))
         (line-indent (current-indentation))
         (pos (point))
         found)
    (while (and (> pos (point-min)) (not found))
      (previous-line)
      (back-to-indentation)
      (if (and (or (< (current-indentation) line-indent) (and (= line-indent 0) (= (current-indentation) 0)))
               (looking-at-p (rx (or "def" "expr.macro" "macro" "fun" "defn.macro") symbol-end)))
          (setq found t)))
    (when found (forward-word))))

(defun rhombus-indent-line ()
  (interactive)
  (let (previous-line-indent previous-line-begins-group)
    (save-excursion
      (previous-line)
      (back-to-indentation)
      (setq previous-line-indent (current-indentation))
      (setq previous-line-begins-group (looking-at-p (rx (* (not "\n")) ":" eol))))

    ;; if previous line ends with :, then increment indentation, otherwise keep same
    (indent-line-to
     (if previous-line-begins-group
         (+ rhombus-indent-offset previous-line-indent)
       previous-line-indent))))

;;;; Syntax Highlighting
;;;;; Syntax table

(setq rhombus-mode-syntax-table
  (let ((table (make-syntax-table)))

    ;; symbols
    (modify-syntax-entry ?$ "w" table)
    (modify-syntax-entry ?. "." table)
    (modify-syntax-entry ?_ "w" table)

    ;; strings
    (modify-syntax-entry ?\" "\"" table)

    ;; blocks
    (modify-syntax-entry ?{ "(" table)
    (modify-syntax-entry ?} ")" table)
    (modify-syntax-entry ?[ "(" table)
    (modify-syntax-entry ?] ")" table)
    
    ;; comments
    (modify-syntax-entry ?/  ". 124b" table)
    (modify-syntax-entry ?*  ". 23n"  table)
    (modify-syntax-entry ?\n "> b"    table)
    (modify-syntax-entry ?\^m "> b"   table)

    (modify-syntax-entry ?' "$" table)
    table)
  ;; "Syntax table for Rhombus files."
  )


;;;;; Font lock
(setq rhombus-font-lock-keywords-level-1
      `((,(rx symbol-start "fun"
              (1+ (or space (and ?\\ ?\n)))
              (group (seq (any letter ?_) (* (any word ?_)))))
         (1 font-lock-function-name-face))
        (,(rx symbol-start
              "def"
              (1+ (or space (and ?\\ ?\n)))
              (group (seq (any letter ?_) (* (any word ?_)))))
         (1 font-lock-variable-name-face))
        (,(rx symbol-start
              "#lang"
              (1+ (or space (and ?\\ ?\n)))
              (group (seq (any letter ?_) (* (any word ?_)))))
         (1 font-lock-variable-name-face))
        (,(rx symbol-start
              (or "interface" "class" "namespace")
              (1+ (or space (and ?\\ ?\n)))
              (group (seq (any letter ?_) (* (any word ?_)))))
         (1 font-lock-type-face))))

(setq rhombus-font-lock-keywords-level-2
  `(,@rhombus-font-lock-keywords-level-1
    (,(rx (or
           (seq
            symbol-start
            (or  "namespace" "lib" "open" "as"
                "def" "fun" "operator" 
                "match" "cond" "if" "unless" "when"
                )
            symbol-end)
           "..." "#lang")) 
     (0 font-lock-keyword-face))
    (,(rx 
       (or
        "+" "." "-" "!"
        (seq
         symbol-start
         (or "import" "export")
         (or symbol-end ":"))
        (seq
         symbol-start
         (or "interface" "class"
             "macro" "expr.macro" "bind.macro" "defn.macro")
         symbol-end)
        (seq
         "~" (any letter ?_) (* (any word ?_))
         symbol-end)))
     (0 font-lock-builtin-face))
    (,(rx
            symbol-start (group (seq (any letter ?_) (* (any word ?_)))) ?.)
         (1 font-lock-preprocessor-face))
    (,(rx (or
           
            (seq "#" (or "true" "false" "void" "inf" "neginf" "nan") symbol-end)
            (seq symbol-start "$" (any letter ?_) (* (any word ?_)))
            (seq symbol-start digit (* (any word ?_)) symbol-end)))
      (0 font-lock-constant-face))
     (,(rx (or
            (seq "#" (or "true" "false" "void" "inf" "neginf" "nan") symbol-end)
            (seq symbol-start "$" (any letter ?_) (* (any word ?_)))
            (seq symbol-start digit (* (any word ?_)) symbol-end)))
      (0 font-lock-constant-face))))

(defvar rhombus-font-lock-keywords
  '(rhombus-font-lock-keywords-level-1 rhombus-font-lock-keywords-level-2))

;;;;; Syntactic-face-function

(defun rhombus-font-lock-syntactic-face-function (state)
  (if (nth 3 state)
      font-lock-string-face
    font-lock-comment-face))

;;;; Setup Common Variables

(defun rhombus--common-variables ()
  (set-syntax-table rhombus-mode-syntax-table)

  (setq-local font-lock-defaults
              (list rhombus-font-lock-keywords ;keywords
                    nil                        ;keywords-only?
                    nil                        ;case-fold?
                    nil                        ;syntax-alist
                    nil                        ;syntax-begin
                    ;; Additional variables
                    (cons 'font-lock-syntactic-face-function
                          #'rhombus-font-lock-syntactic-face-function)))

  (syntax-propertize (point-max))

  (setq-local comment-use-syntax t)
  (setq-local comment-start "//")
  (setq-local comment-end "")
  (setq-local comment-start-skip "//+\\s-*")

  (setq-local parse-sexp-lookup-properties t)
  (setq-local parse-sexp-ignore-comments t)

  ;; (setq-local forward-sexp-function #'rhombus-nav-forward-sexp)
  (setq-local indent-line-function #'rhombus-indent-line)
  ;; (setq-local indent-region-function #'rhombus-indent-region)

  ;; Because indentation is not redundant, we cannot safely reindent code.
  (setq-local electric-indent-inhibit t)
  (setq-local electric-indent-chars
              (cons ?: electric-indent-chars))

  (setq-local paragraph-start "\\s-*$")
  ;; (setq-local fill-paragraph-function #'rhombus-fill-paragraph)
  ;; (setq-local normal-auto-fill-function #'rhombus-do-auto-fill)

  (setq-local beginning-of-defun-function #'rhombus-beginning-of-defun)
  ;; (setq-local end-of-defun-function #'rhombus-nav-end-of-defun)

  (add-hook 'completion-at-point-functions
            #'racket-complete-at-point nil 'local)

  ;; (add-hook 'post-self-insert-hook
  ;;           #'rhombus-indent-post-self-insert-function 'append 'local)

  ;; (setq-local add-log-current-defun-function
  ;;             #'rhombus-info-current-defun)

  (setq-local paragraph-separate
              (concat "\f\\|^[\t]*$\\|^[ \t]*" comment-start "[ \t]*$\\|^[\t\f]*:[[:alpha:]]+ [[:alpha:]]+:.+$"))
  (setq-local paragraph-start
	      (concat "\f\\|^[ \t]*$\\|^[ \t]*" comment-start "[ \t]*$\\|^[ \t\f]*:[[:alpha:]]+ [[:alpha:]]+:.+$"))
  (setq-local paragraph-separate
	      (concat "\f\\|^[ \t]*$\\|^[ \t]*" comment-start "[ \t]*$\\|^[ \t\f]*:[[:alpha:]]+ [[:alpha:]]+:.+$"))


  (setq-local comment-column 40)
  (setq-local comment-multi-line t)
  (setq-local block-comment-start "/*")
  (setq-local block-comment-end "*/")
  (setq-local font-lock-comment-start-skip "//+ *")
  
  (setq-local indent-tabs-mode nil)
  (setq-local tab-always-indent t)

  (setq-local local-abbrev-table rhombus-mode-abbrev-table)
  ;; (setq-local fill-paragraph-function #'rhombus-fill-paragraph)
  (setq-local adaptive-fill-mode nil)
  (setq-local beginning-of-defun-function #'rhombus-beginning-of-defun))

;;;; Major mode

(define-derived-mode rhombus-mode racket-mode "Rhombus"
  "Major mode for editing Rhombus files."
  :syntax-table rhombus-mode-syntax-table
  (rhombus--common-variables))


;;;###autoload
(progn
  ;; Use simple regexps for auto-mode-alist as they may be given to
  ;; grep (e.g. by default implementation of `xref-find-references').
  (add-to-list 'auto-mode-alist '("\\.rhombus\\'" . rhombus-mode)))

(provide 'rhombus-mode)
;;; rhombus-mode.el ends here
