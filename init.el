;;; init.el --- Modus Operandi Emacs Configuration -*- lexical-binding: t -*-

;; Author: Yoav Orot
;; Created: 2021
;; Homepage: https://github.com/manzaltu/modus-emacs

;; This file is not part of GNU Emacs.

;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.

;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; Modus Operandi Emacs development environment configuration file

;;; Code:

;; Disable deferred & auto native compilation temporarily until we set the exec-path var
(setq native-comp-deferred-compilation nil)
(setq straight-disable-native-compile t)

;; Set a directory path to be used for cache files
(defvar mo-cache-dir (expand-file-name ".cache" user-emacs-directory))

(defun mo-cache-path (filename)
  "Return a valid file path for FILENAME under the cache directory."
  (concat (file-name-as-directory mo-cache-dir) filename))

(defvar straight-base-dir (mo-cache-path ""))

;; Init straight.el for package management
(defvar bootstrap-version)
(let ((bootstrap-file
       (expand-file-name ".cache/straight/repos/straight.el/bootstrap.el" user-emacs-directory))
      (bootstrap-version 5))
  (unless (file-exists-p bootstrap-file)
    (with-current-buffer
        (url-retrieve-synchronously
         "https://raw.githubusercontent.com/raxod502/straight.el/develop/install.el"
         'silent 'inhibit-cookies)
      (goto-char (point-max))
      (eval-print-last-sexp)))
  (load bootstrap-file nil 'nomessage))

;; Before loading other packages, set exec-path to the PATH var under the default shell
;; when executed under a windowing system, using the exec-path-from-shell package.
;; This is needed so libgccjit would be found by native compilation

(straight-use-package 'exec-path-from-shell)
(require 'exec-path-from-shell)
(when (memq window-system '(mac ns x))
  (exec-path-from-shell-initialize))

;; Re-enable auto & deferred native compilation
(setq straight-disable-native-compile nil)
(setq native-comp-deferred-compilation t)

;; Install use-package
(straight-use-package 'use-package)
;; Packages should be installed by default using straight
(setq straight-use-package-by-default t)
(require 'use-package)

;; Optionally, load personal settings
(load (concat (file-name-directory load-file-name) "personal.el") t)

;; Add general.el key mapper
(use-package general)

;; Init gcmh for executing GC on idle
(use-package gcmh
  :config
  (gcmh-mode 1))

;; Prefix keys for quick action menu
(setq mo-quick-menu-prefix "SPC")
(setq mo-quick-menu-nn-prefix "M-SPC")

;; Create quick menu map and definer
(general-create-definer mo-quick-menu-def :keymaps 'mo-quick-menu-map)

;; Bind the quick menu map to the leader key and the relevant states
(general-define-key
 :states '(normal insert visual motion emacs)
 :prefix mo-quick-menu-prefix
 :non-normal-prefix mo-quick-menu-nn-prefix
 :prefix-map 'mo-quick-menu-map)

;; Init evil mode for Vim emulation in Emacs
(use-package evil
  :init
  ;; Needed for evil-collection
  (setq evil-want-keybinding nil)
  ;; Undo
  (setq evil-undo-system 'undo-redo)
  (setq evil-want-fine-undo t)
  ;; Enable Emacs native bindings in insert mode
  (setq evil-disable-insert-state-bindings t)
  (setq evil-want-C-u-delete nil)
  (setq evil-want-C-w-delete nil)
  ;; Yanking
  (setq evil-want-Y-yank-to-eol t)
  ;; Use evil search instead of the native search module
  (setq evil-search-module 'evil-search)
  ;; Set word search to look for symbol boundaries
  (setq evil-symbol-word-search t)
  :config
  ;; Set word movement to operate on symbol boundaries
  (defalias #'forward-evil-word #'forward-evil-symbol)
  (mo-quick-menu-def
    "d" #'xref-find-definitions
    "r" #'xref-find-references)
  (evil-mode 1))

;; Add evil key bindings to other, non-default, modes
(use-package evil-collection
  :after evil
  :config
  (evil-collection-init))

;; Init evil-surround for quickly adding paired surrounding characters
(use-package evil-surround
  :config
  (global-evil-surround-mode 1))

;; Init anzu for showing additional search match info
(use-package anzu
  :config
  (global-anzu-mode +1))

;; Init evil-anzu for anzu integration with evil search
(use-package evil-anzu
  :after evil)

;; Init avy for text zapping using 2 chars
(use-package avy
  :general
  (:states 'motion "M" #'avy-goto-char-2))

;; Init better-jumper for better controlling the jump list logic
(use-package better-jumper
  :demand t
  :after evil
  :general
  ([remap evil-jump-forward] 'better-jumper-jump-forward)
  ([remap evil-jump-backward] 'better-jumper-jump-backward)
  :config
  ;; Jump list to work as a stack
  (setq better-jumper-add-jump-behavior 'replace)
  (better-jumper-mode +1))

;; Init origami for text and code folding
(use-package origami
  :config
  (global-origami-mode))

;; Init org mode for editing and managing notes
(use-package org
  :config
  (setq org-directory "~/org")
  (setq org-agenda-files `(,org-directory))
  (setq org-agenda-include-diary t)
  (setq org-agenda-diary-file
        (concat (file-name-as-directory org-directory) "diary.org")))

;; Init org-roam for Zettelkasten note management
(use-package org-roam
  :demand t
  :general
  (:keymaps 'org-roam-mode-map
   "C-c n l" #'org-roam
   "C-c n f" #'org-roam-find-file
   "C-c n g" #'org-roam-graph
   :keymaps 'org-mode-map
   "C-c n i" #'org-roam-insert
   "C-c n I" #'org-roam-insert-immediate)
  :custom
  (org-roam-directory org-directory)
  :config
  (setq org-roam-db-location (mo-cache-path "org-roam.db"))
  (org-roam-mode))

;; Init orderless for advanced (e.g. fuzzy) completion styles
(use-package orderless
  :demand t
  :config
  ;; Set matching style to regexp and literal
  (setq orderless-matching-styles '(orderless-regexp orderless-literal))
  :custom (completion-styles '(orderless)))

;; Init selectrum for item list selection
(use-package selectrum
  :demand t
  :after orderless
  :general
  ("C-c z" #'selectrum-repeat)
  :config
  ;; Highlight only visible candidates
  (setq orderless-skip-highlighting (lambda () selectrum-is-active))
  (setq selectrum-highlight-candidates-function #'orderless-highlight-matches)
  (selectrum-mode +1))

;; Init selectrum-prescient for completion sort and history
(use-package selectrum-prescient
  :after selectrum
  :config
  ;; We don't need filtering (orderless is used instead)
  (setq selectrum-prescient-enable-filtering nil)
  (setq prescient-save-file (mo-cache-path "persp-state"))
  (selectrum-prescient-mode +1)
  (prescient-persist-mode +1))

;; Used by project.el for project detection
(defun mo-project-try-local (dir)
  "Determine if DIR is a project.
DIR must include a .project file to be considered a project."
  (let ((root (locate-dominating-file dir ".project")))
    (and root (cons 'transient root))))

;; Enable project detection using .project files
(with-eval-after-load 'project (add-to-list 'project-find-functions #'mo-project-try-local))

;; Set project history file path
(setq project-list-file (mo-cache-path "projects"))

(defun mo-project-save ()
  "Save the current project to the persistent project list."
  (interactive)
  (message "Project saved: %s" (cdr (project-current t))))

;; Key binding for current project save
(general-def :keymaps 'project-prefix-map "w" #'mo-project-save)

;; Key binding for project switch
(mo-quick-menu-def "p" #'project-switch-project)

;; Init consult for enhanced search commands
(use-package consult
  :demand t
  :general
  ;; C-c bindings (mode-specific-map)
  ("C-c h" #'consult-history)
  ("C-c m" #'consult-mode-command)
  ("C-c b" #'consult-bookmark)
  ("C-c k" #'consult-kmacro)
  ;; C-x bindings (ctl-x-map)
  ("C-x M-:" #'consult-complex-command)     ;; orig. repeat-complex-command
  ("C-x b" #'consult-buffer)                ;; orig. switch-to-buffer
  ("C-x 4 b" #'consult-buffer-other-window) ;; orig. switch-to-buffer-other-window
  ("C-x 5 b" #'consult-buffer-other-frame)  ;; orig. switch-to-buffer-other-frame
  ;; Custom M-# bindings for fast register access
  ("M-#" #'consult-register-load)
  ("M-'" #'consult-register-store)          ;; orig. abbrev-prefix-mark (unrelated)
  ("C-M-#" #'consult-register)
  ;; Other custom bindings
  ("M-y" #'consult-yank-pop)                ;; orig. yank-pop
  ("<help> a" #'consult-apropos)            ;; orig. apropos-command
  ;; M-g bindings (goto-map)
  ("M-g e" #'consult-compile-error)
  ("M-g g" #'consult-goto-line)             ;; orig. goto-line
  ("M-g M-g" #'consult-goto-line)           ;; orig. goto-line
  ("M-g o" #'consult-outline)
  ("M-g m" #'consult-mark)
  ("M-g k" #'consult-global-mark)
  ("M-g i" #'consult-imenu)
  (:keymaps 'mo-quick-menu-map
   "m" #'consult-imenu)
  ("M-g I" #'consult-project-imenu)
  ;; M-s bindings (search-map)
  ("M-s f" #'consult-find)
  ("M-s L" #'consult-locate)
  ("M-s g" #'consult-grep)
  ("M-s G" #'consult-git-grep)
  ("M-s r" #'consult-ripgrep)
  ("M-s l" #'consult-line)
  ("M-s m" #'consult-multi-occur)
  ("M-s k" #'consult-keep-lines)
  ("M-s u" #'consult-focus-lines)
  ;; Isearch integration
  ("M-s e" #'consult-isearch)
  (:keymaps 'org-mode-map
   "M-e" #'consult-isearch)                 ;; orig. isearch-edit-string
  ("M-s e" #'consult-isearch)               ;; orig. isearch-edit-string
  ("M-s l" #'consult-line)                  ;; required by consult-line to detect isearch

  :init
  ;; Enable recentf for tracking recently opened files
  (setq recentf-save-file (mo-cache-path "recentf"))
  (recentf-mode t)
  ;; Enlarge the max size of the recent files list
  (setq recentf-max-saved-items 500)

  :config
  ;; Configure the narrowing key.
  (setq consult-narrow-key ">")

  ;; Use consult to select xref locations with preview
  (setq xref-show-xrefs-function #'consult-xref
        xref-show-definitions-function #'consult-xref)

  ;; Change find command to use fd
  (setq consult-find-command "fd --color=never -p -H -t f ARG OPTS")

  ;; Do not auto preview ripgrep results
  (consult-customize consult-ripgrep :preview-key (kbd "M-."))

  ;; Configure project detection using project.el
  (setq consult-project-root-function
        (lambda ()
          (when-let (project (project-current))
            (car (project-roots project)))))

  ;; On project switch, use consult for file and regexp search
  (setq project-switch-commands
        '((consult-find "Find file" ?f)
          (consult-ripgrep "Ripgrep" ?r))))

;; Init consult-flycheck for showing syntax errors with consult
(use-package consult-flycheck
  :general
  (:keymaps 'mo-quick-menu-map
   "f" #'consult-flycheck))

;; Init marginalia for minibuffer result annotations
(use-package marginalia
  :config
  (marginalia-mode))

;; Init embark for enabling contextual actions
(use-package embark
  :general
  ("C-M-a" #'embark-act)       ;; pick some comfortable binding
  ("C-h B" #'embark-bindings)  ;; alternative for `describe-bindings'
  :config
  ;; Hide the mode line of the Embark live/completions buffers
  (add-to-list 'display-buffer-alist
               '("\\`\\*Embark Collect \\(Live\\|Completions\\)\\*"
                 nil
                 (window-parameters (mode-line-format . none)))))

;; Init embark-consult for enabling embark actions on consult results
(use-package embark-consult
  :demand t
  :after (embark consult)
  :hook
  (embark-collect-mode . consult-preview-at-point-mode))

;; Init magit for a better git user experience
(use-package magit
  ;; Refine diff view to show sub hunk changes
  :config
  (setq transient-levels-file (mo-cache-path "transient_levels.el"))
  (setq transient-values-file (mo-cache-path "transient_values.el"))
  (setq transient-history-file (mo-cache-path "transient_history.el"))
  (setq magit-diff-refine-hunk 'all))

;; Init diff-hl for highlighting uncommitted changes
(use-package diff-hl
  :demand t
  :general
  (:states 'normal
   :keymaps 'diff-hl-mode-map
   "] h" #'diff-hl-next-hunk
   "[ h" #'diff-hl-previous-hunk)
  :hook
  (magit-pre-refresh . diff-hl-magit-pre-refresh)
  (magit-post-refresh . diff-hl-magit-post-refresh)
  (dired-mode . diff-hl-dired-mode-unless-remote)
  :config
  (global-diff-hl-mode))

;; Init lsp mode for lsp support
(use-package lsp-mode
  :general
  ;; Set the lsp prefix key
  (:keymaps 'lsp-mode-map
   "C-c l" '(:keymap lsp-command-map :which-key "lsp"))
  (:keymaps 'mo-quick-menu-map
   "i" #'lsp-find-implementation
   "a" #'lsp-execute-code-action)
  :init
  ;; Set a high read output max value for handling large language server responses
  (setq read-process-output-max (* 10 1024 1024))
  ;; Enable which-key help on the lsp prefix key
  (setq lsp-keymap-prefix "C-c l")
  ;; Enable for the following modes
  (setq mo-lsp-enable-for-modes '(c-mode
                                  c++-mode
                                  go-mode
                                  csharp-mode
                                  (python-mode (lambda () (require 'lsp-python-ms)))
                                  js2-mode
                                  typescript-mode
                                  json-mode
                                  yaml-mode
                                  dockerfile-mode
                                  terraform-mode
                                  sh-mode))

  (defun mo-maybe-enable-lsp (lsp-config)
    "If mode in LSP-CONFIG is equal to the current major-mode,
run the attached function (if exists) and enable lsp"
    (pcase lsp-config
      (`(,(pred (equal major-mode)) ,func) (funcall func) (lsp) t)
      ((pred (equal major-mode)) (lsp) t)))

  ;; Kill language server after the last associated buffer was closed
  (setq lsp-keep-workspace-alive nil)
  (setq lsp-session-file (mo-cache-path "lsp-session-v1"))
  :hook
  ;; Postpone lsp load for after dir local vars are read
  ;; Do not load lsp if dir local vars are not enabled (e.g. on preview)
  (hack-local-variables . (lambda ()
                            (when enable-dir-local-variables
                              (seq-find #'mo-maybe-enable-lsp
                                        mo-lsp-enable-for-modes))))

  ;; Enable which-key integration
  (lsp-mode . lsp-enable-which-key-integration)
  :commands lsp)

;; Init lsp-ui for an interactive lsp interface
(use-package lsp-ui
  :after lsp-mode
  :config
  ;; Do not show documentation automatically
  (setq lsp-ui-doc-show-with-cursor nil)
  (setq lsp-ui-doc-show-with-mouse nil)
  (setq lsp-ui-doc-position 'at-point))

;; When looking for references, don't ask for an identifier
(setq xref-prompt-for-identifier nil)

;; Init flycheck for on-the-fly syntax checking
(use-package flycheck
  :init
  (global-flycheck-mode))

;; Init company mode for auto completion everywhere
(use-package company
  :init
  (global-company-mode))

;; Init company-box for completions with icons
(use-package company-box
  :hook (company-mode . company-box-mode))

;; Init consult-lsp for additional interacitve lsp commands
(use-package consult-lsp
  :after (lsp-mode consult)
  :general
  (:keymaps 'mo-quick-menu-map
   "s" #'consult-lsp-symbols)
  :config
  ;; Manual preview key for symbols results
  (consult-customize consult-lsp-symbols :preview-key (kbd "M-."))
  ;; Remove initial async separator as we use spaces for search tokenization
  (consult-customize consult-lsp-symbols :initial nil))

;; Init yasnippets for adding code snippet templates
(use-package yasnippet
  :config
  (yas-global-mode 1))

;; Init yasnippet-snippets for common code templates
(use-package yasnippet-snippets)

;; Init rustic for Rust support
(use-package rustic)

;; Init go-mode for Go support
(use-package go-mode)

;; Init csharp-mode for C# support
(use-package csharp-mode)

;; Init lsp-python-ms for MS python language server
(use-package lsp-python-ms
  :init (setq lsp-python-ms-auto-install-server t))

;; Init pip-requirements for editing pip requirements files
(use-package pip-requirements)

;; Init pipenv for supporting pipenv projects and commands
(use-package pipenv
  :hook (python-mode . pipenv-mode)
  :config
  ;; We don't use projectile
  (setq pipenv-with-projectile nil))

;; Init js2-mode for enhanced JavaScript editing
(use-package js2-mode
  :mode "\\.js\\'")

;; Init typescript-mode for enhanced TypeScript editing
(use-package typescript-mode)

;; Init web-mode for enhanced web files editing
(use-package web-mode
  :mode "\\.html?\\'" "\\.htm?\\'")

;; Init json mode for enhanced JSON editing
(use-package json-mode)

;; Init yaml-mode for enhanced YAML editing
(use-package yaml-mode)

;; Init dockerfile-mode for editing docker files
(use-package dockerfile-mode
  :mode "Dockerfile\\'")

;; Init docker for managing docker from Emacs
(use-package docker
  :general
  ("C-c d" #'docker))

;; Init terraform-mode for editing terraform files
(use-package terraform-mode)

;; Init markdown-mode for enhanced markdown editing
(use-package markdown-mode)

;; Init formal-all for a universal code formatter
(use-package format-all)

;; Init dtrt-indent for auto indentation detection
(use-package dtrt-indent
  :hook
  (prog-mode . dtrt-indent-mode))

;; Init which-key for interactively displaying key bindings
(use-package which-key
  :config
  (setq which-key-idle-delay 0.5)
  (which-key-mode))

;; Init helpful for better lisp help
(use-package helpful
  :general
  ("C-h f" #'helpful-callable)
  ("C-h v" #'helpful-variable)
  ("C-h k" #'helpful-key)
  ("C-c H" #'helpful-at-point)
  ("C-h F" #'helpful-function)
  ("C-h C" #'helpful-command))

;; Init google-this for quick Google searches from Emacs
(use-package google-this
  :config
  (google-this-mode 1))

;; Init rainbow-delimiters for highlighting parens by their depth
(use-package rainbow-delimiters
  :hook
  (prog-mode . rainbow-delimiters-mode))

;; Init evil-nerd-commenter for comment editing
(use-package evil-nerd-commenter
  :after evil
  :general
  (:states '(normal, visual) "gc" #'evilnc-comment-operator))

;; Init popwin for popup management
(use-package popwin
  :config
  (popwin-mode 1))

;; Init vterm for terminal emulation
(use-package vterm
  :init
  ;; Set a low response delay
  (setq vterm-timer-delay 0.07))

;; Init vterm-toggle for quick vterm access
(use-package vterm-toggle
  :general
  ("C-c t" #'vterm-toggle)
  :config
  (setq vterm-toggle-scope 'project)
  ;; Show vterm window at the bottom
  (add-to-list 'display-buffer-alist
               '((lambda(bufname _) (with-current-buffer bufname (equal major-mode 'vterm-mode)))
                 (display-buffer-reuse-window display-buffer-in-direction)
                 (direction . bottom)
                 (dedicated . t)
                 (reusable-frames . visible)
                 (window-height . 0.4))))

;; Set eshell cache directory
(setq eshell-directory-name (file-name-as-directory (mo-cache-path "eshell")))

;; Init dashboard for an informative splash screen
(use-package dashboard
  :config
  (setq dashboard-startup-banner 'logo)
  (setq dashboard-banner-logo-title "Welcome to Modus Operandi Emacs!")
  (setq dashboard-init-info "In Absentia Lucis, Tenebrae Vincunt")
  (setq dashboard-center-content t)
  (setq dashboard-set-footer nil)
  (dashboard-setup-startup-hook))

;; Init doom vibrant theme
(use-package doom-themes
  :config
  ;; Global settings (defaults)
  (setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
        doom-themes-enable-italic t) ; if nil, italics is universally disabled
  ;; Set brighter comments
  (setq doom-vibrant-brighter-comments t)
  (load-theme 'doom-vibrant t))

;; Init minions for collapsing the minor mode indicator in the modeline
(use-package minions
  :config
  (minions-mode 1))

;; Init flyspell-correct for spell correction
(use-package flyspell-correct
  :demand t
  :general
  (:states 'normal "z =" #'flyspell-correct-wrapper)
  :hook
  ;; Enable spell checking
  (text-mode . flyspell-mode)
  (prog-mode . flyspell-prog-mode))

;; Init zoom-window for toggling window zoom
(use-package zoom-window
  :general
  (:states 'normal "C-w z" #'zoom-window-zoom)
  :config
  (setq zoom-window-mode-line-color "#3b404e")
  (minions-mode 1))

;; Init zoom-frm to scale text in frame
(use-package zoom-frm
  :general
  ("s--" #'zoom-in/out)
  ("s-+" #'zoom-in/out)
  ("s-=" #'zoom-in/out))

;; Cleanup the frame UI
(tool-bar-mode -1)
(toggle-scroll-bar -1)

;; Inhibit the splash screen
(setq inhibit-splash-screen t)

;; Enable window management
(winner-mode 1)

;; Set the default initial frame size
(add-to-list 'default-frame-alist '(height . 55))
(add-to-list 'default-frame-alist '(width . 210))

;; Scroll incrementally
(setq scroll-step 1)
;; Don't automatically recenter after scrolling
(setq scroll-conservatively 101)

;; Ask for confirmation before exiting emacs
(setq confirm-kill-emacs #'y-or-n-p)

;; Replace yes or no questions to y or n
(defalias 'yes-or-no-p 'y-or-n-p)

;; Don't create backup & autosave files
(setq make-backup-files nil)
(setq auto-save-default nil)

;; Disable bell audio
(setq ring-bell-function 'ignore)

;; Show cursor's column number
(setq column-number-mode t)

;; Remove average load time indicator from the modeline
(setq display-time-default-load-average nil)

;; Show time in the modeline
(display-time-mode 1)

;; Show trailing whitespaces in code
(require 'whitespace)
(setq whitespace-style '(face trailing))
(add-hook 'prog-mode-hook 'whitespace-mode)

;; Start Emacs server
(server-start)

;; Set url configuration directory
(setq url-configuration-directory (mo-cache-path "url"))

;; Persist minibuffer history over Emacs restarts
(savehist-mode)
(setq savehist-file (mo-cache-path "history"))

;; Set customization file path
(setq custom-file (expand-file-name "custom.el" user-emacs-directory))
(when (file-exists-p custom-file)
  (load custom-file))

;;; init.el ends here
