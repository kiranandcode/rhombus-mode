;;; lsp-rhombus.el --- lsp-mode rhombus integration  -*- lexical-binding: t; -*-

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

;; Client for the Racket language server.

;;; Code:

;;; lsp-racket.el --- lsp-mode racket integration    -*- lexical-binding: t; -*-

;; Copyright (C) 2020 lsp-mode maintainers

;; Author: lsp-mode maintainers
;; Keywords: languages

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

;; Client for the Racket language server.

;;; Code:

(require 'ht)
(require 'lsp-mode)


;;rhombus-langserver

(defgroup lsp-rhombus-langserver nil
  "LSP support for Rhombus, using racket-langserver"
  :group 'lsp-mode
  :link '(url-link "https://github.com/jeapostrophe/racket-langserver"))

(defcustom lsp-rhombus-langserver-command '("racket" "--lib" "racket-langserver")
  "Command to start the server."
  :type 'string
  :package-version '(lsp-mode . "8.0.0"))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection (lambda () lsp-rhombus-langserver-command))
                  :major-modes '(rhombus-mode)
                  :priority 1
                  :server-id 'rhombus-langserver))


;; Theia

(defgroup lsp-rhombus-language-server nil
  "LSP support for Rhombus, using racket-language-server."
  :group 'lsp-mode
  :link '(url-link "https://github.com/theia-ide/racket-language-server"))

(defcustom lsp-rhombus-language-server-path "racket-language-server"
  "Executable path for the server."
  :type 'string
  :package-version '(lsp-mode . "8.0.0"))

(defun lsp-rhombus-language-server-colorize-handler (&rest _args)
  "Handler for the colorize notification."
  ;; TODO:
  nil)

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection (lambda () lsp-rhombus-language-server-path))
                  :major-modes '(rhombus-mode)
                  :priority -1
                  :notification-handlers (ht ("racket/colorize" #'lsp-rhombus-language-server-colorize-handler))
                  :server-id 'rhombus-language-server))

(lsp-consistency-check lsp-rhombus)

(provide 'lsp-rhombus)
;;; lsp-rhombus.el ends here

