;;;; Begin Init

;; increase memory
(setq gc-cons-threshold 100000000) ; 100 mb

;;; loadpath
(let ((default-directory "~/.emacs.d/"))
  (normal-top-level-add-subdirs-to-load-path))

(if (eq system-type 'windows-nt)
    (add-to-list 'exec-path "C:/Program Files (x86)/Git/bin/"))

(add-to-list 'load-path "~/.emacs.d/packages/")

(setq inhibit-startup-screen t) ; disable startup screen
(setq ring-bell-function #'ignore) ; mute system sound

;;yasnippet

;;; packages
(setq package-list '(diminish))

(setq package-enable-at-startup nil)

;;; repositories
(setq package-archives '(("elpa" . "http://tromey.com/elpa/")
                         ("gnu" . "http://elpa.gnu.org/packages/")
                         ("melpa" . "http://melpa.milkbox.net/packages/")
                         ("marmalade" . "http://marmalade-repo.org/packages/")))

(package-initialize) ; activate all packages (in particular autoloads)

;; bootstrap 'use-package'
(unless (package-installed-p 'use-package)
  (package-refresh-contents)
  (package-install 'use-package))

(eval-when-compile
  (require 'use-package))
(require 'diminish) ; for :diminish
(require 'bind-key) ; for :bind

(setq use-package-always-ensure t) ; install package if not existing
(setq use-package-verbose t) ; check loading times

;; fetch the list of packages available
(when (not package-archive-contents)
  (package-refresh-contents))

;; install the missing packages
(dolist (package package-list)
  (when (not (package-installed-p package))
    (package-install package)))

;; set the shell environment properly
(when (memq window-system '(mac ns))
  (use-package exec-path-from-shell
    :config
    (setq exec-path-from-shell-check-startup-files nil)
    (exec-path-from-shell-initialize)))

(use-package multi-term
  :if (not (eq system-type 'windows-nt))
  :commands (multi-term)
  :init
  :config
  (add-to-list 'term-unbind-key-list "C-q") ; C-q binds to raw input by default
  (setq multi-term-program "/bin/zsh"))

(use-package dash)
(use-package s)

;;;; End Init

;;;; Begin Theme

(use-package spacemacs-theme
  :defer)

(setq frame-title-format '("%b")) ; set the title to be the current file

(add-to-list 'custom-theme-load-path "~/.emacs.d/packages/solarized")
(add-to-list 'custom-theme-load-path "~/.emacs.d/themes")

;; https://stackoverflow.com/questions/9840558/why-cant-emacs-24-find-a-custom-theme-i-added
;; adds wildcard matching to themes in elpa folder.
(-each
    (-map
     (lambda (item)
       (format "~/.emacs.d/elpa/%s" item))
     (-filter
      (lambda (item) (s-contains? "theme" item))
      (directory-files "~/.emacs.d/elpa/")))
  (lambda (item)
    (add-to-list 'custom-theme-load-path item)))

(use-package spaceline-config
  :ensure spaceline
  :config
  (spaceline-emacs-theme)
  (setq powerline-default-separator 'wave)
  (setq spaceline-highlight-face-func 'spaceline-highlight-face-evil-state))

(use-package theme-changer
  :init
  (setq calendar-location-name "Dallas, TX")
  (setq calendar-latitude 32.85)
  (setq calendar-longitude -96.85)
  :config
  ;; requires spaceline-config package to be loaded already
  (defun reset-line--change-theme (&rest args)
    (powerline-reset))
  (advice-add 'change-theme :after #'reset-line--change-theme)
  (change-theme 'spacemacs-light 'spacemacs-dark))

;; disable ui fluff
(if (fboundp 'scroll-bar-mode) (scroll-bar-mode -1))
(if (fboundp 'tool-bar-mode) (tool-bar-mode -1))
(if (fboundp 'menu-bar-mode) (menu-bar-mode -1))

;; colorful delimiters
(use-package rainbow-delimiters
  :init
  (add-hook 'prog-mode-hook 'rainbow-delimiters-mode))

;; diminish modeline clutter
(when (require 'diminish nil 'noerror)
  (diminish 'subword-mode)
  (diminish 'visual-line-mode)
  (eval-after-load "hideshow"
    '(diminish 'hs-minor-mode))
  (eval-after-load "autorevert"
    '(diminish 'auto-revert-mode)))

;;;; End Theme

;;;; Begin Platform

;;; Windows Specifc
(when (eq system-type 'windows-nt)
  (defun explorer ()
    (interactive)
    (cond
     ;; in buffers with file name
     ((buffer-file-name)
      (shell-command (concat "start explorer /e,/select,\""
                             (replace-regexp-in-string "/" "\\\\" (buffer-file-name)) "\"")))
     ;; in dired mode
     ((eq major-mode 'dired-mode)
      (shell-command (concat "start explorer /e,\""
                             (replace-regexp-in-string "/" "\\\\" (dired-current-directory)) "\"")))
     ;; in eshell mode
     ((eq major-mode 'eshell-mode)
      (shell-command (concat "start explorer /e,\""
                             (replace-regexp-in-string "/" "\\\\" (eshell/pwd)) "\"")))
     ;; use default-directory as last resource
     (t
      (shell-command (concat "start explorer /e,\""
                             (replace-regexp-in-string "/" "\\\\" default-directory) "\"")))))
  (global-set-key (kbd "s-j") 'explorer))

;;; Mac Specific
;; https://github.com/adobe-fonts/source-code-pro
(when (eq system-type 'darwin)
  (defun find-and-set-font (&rest candidates)
    "Set the first font found in CANDIDATES."
    (let ((font (cl-find-if (lambda (f) (find-font (font-spec :name f)))
                            candidates)))
      (when font
        (set-face-attribute 'default nil :font font))
      font))
  (find-and-set-font "Source Code Pro-12" "Consolas-12" "Envy Code R-12" "DejaVu Sans Mono-11" "Menlo-12")

  ;; use the osx emoji font for emoticons
  (when (fboundp 'set-fontset-font)
    (set-fontset-font "fontset-default"
                      '(#x1F600 . #x1F64F)
                      (font-spec :name "Apple Color Emoji") nil 'prepend))

  (defvar osx-use-option-as-meta t) ; flag to disable meta

  ;; command key is super
  (setq mac-command-key-is-meta nil)
  (setq mac-command-modifier 'super)

  ;; treat option key as meta
  (when osx-use-option-as-meta
    (setq mac-option-key-is-meta t)
    (setq mac-option-modifier 'meta))

  ;; some key bindings to match osx
  (global-set-key (kbd "s-f") 'evil-search-forward)
  (global-set-key (kbd "s-F") 'evil-search-backward)
  (global-set-key (kbd "s-q") 'save-buffers-kill-terminal)
  (global-set-key (kbd "s-v") 'yank)
  (global-set-key (kbd "s-c") 'evil-yank)
  (global-set-key (kbd "s-a") 'mark-whole-buffer)
  (global-set-key (kbd "s-x") 'kill-region)
  (global-set-key (kbd "s-w") 'delete-window)
  (global-set-key (kbd "s-W") 'delete-frame)
  (global-set-key (kbd "s-n") 'make-frame)
  (global-set-key (kbd "s-z") 'undo-tree-undo)
  (global-set-key (kbd "s-Z") 'undo-tree-redo)
  (global-set-key (kbd "s-s")
                  (lambda ()
                    (interactive)
                    (call-interactively (key-binding "\C-x\C-s"))))
  (if window-system
      (menu-bar-mode 1)) ; mac needs a menu bar

  ;; reveal in finder
  (use-package reveal-in-osx-finder
    :commands (reveal-in-osx-finder)
    :config
    (global-set-key (kbd "s-r") 'reveal-in-osx-finder)))

(when (eq system-type 'linux)
  (set-face-attribute 'default nil :family "Inconsolata For Powerline")
  (set-face-attribute 'default nil :height 130)
  (set-fontset-font t 'hangul (font-spec :name "NanumGothicCoding")))

;;;; End Platform

;;;; Begin Experience

(use-package magit
  :commands (magit-autoload-commands)
  :config
  (setq magit-completing-read-function 'ivy-completing-read))

;; prefer vertical splits
;; https://stackoverflow.com/questions/2081577/setting-emacs-split-to-horizontal
(setq split-height-threshold nil)
(setq split-width-threshold 150)

;; scroll by 1 line at the end of the file
;;(setq scroll-step 1
;;      scroll-conservatively 10000)
;;;; set mouse wheel to scroll one line at a time
;;(setq mouse-wheel-progressive-speed nil)
;;;; scroll one line at a time (less "jumpy" than defaults)
;;(setq mouse-wheel-scroll-amount '(1 ((shift) . 1)))
;;;; don't accelerate scrolling
;;(setq mouse-wheel-progressive-speed nil)
;;;; scroll window under mouse
;;(setq mouse-wheel-follow-mouse 't)

(use-package smooth-scrolling
  :config
  (set-variable 'smooth-scroll-margin 5)
  (setq scroll-preserve-screen-position 1))

(add-hook 'text-mode-hook 'turn-on-visual-line-mode) ; wraps line when it reaches end

(use-package git-gutter+
  :diminish git-gutter+-mode
  :commands (global-git-gutter+-mode)
  :init
  (add-hook 'after-save-hook #'global-git-gutter+-mode)
  :config
  (use-package git-gutter-fringe+))

;;; folding
(use-package fold-dwim-org)

;; hide the comments too when you do a 'hs-hide-all'
(setq hs-hide-comments nil)
;; Set whether isearch opens folded comments, code, or both
;; where x is code, comments, t (both), or nil (neither)
(setq hs-isearch-open 'x)

;;; line numbers
(use-package linum
  :config
  (global-linum-mode 1))

;;; highlight parentheses
(use-package paren
  :config
  (show-paren-mode t))

;;;; End Experience
(use-package flycheck
  :diminish flycheck-mode
  :init
  (add-hook 'python-mode-hook #'flycheck-mode)
  :commands flycheck-mode)


;;;; Begin Completion

;;; company
(use-package company
  :diminish company-mode
  :init
  (add-hook 'after-init-hook 'global-company-mode)

  ;; ios
  (add-hook 'objc-mode-hook
            (lambda ()
              (set (make-local-variable 'company-backends) '(company-xcode))))
  :config
  (setq company-idle-delay .1)
  (setq company-minimum-prefix-length 2))

;;; python - jedi
(defun my/python-mode-hook ()
  (add-to-list 'company-backends 'company-jedi))
(use-package company-jedi
  :commands (my/python-mode-hook)
  :init
  (add-hook 'python-mode-hook #'my/python-mode-hook))

;;;  c# - omnisharp
(use-package omnisharp
  :commands (omnisharp-mode)
  :init
  (add-hook 'csharp-mode-hook #'omnisharp-mode)
  :config
  (eval-after-load 'company
    '(add-to-list 'company-backends 'company-omnisharp))
  ;; https://stackoverflow.com/questions/29382137/omnisharp-on-emacs-speed
  (setq omnisharp-eldoc-support nil)) ; disable for speed

;;;; End Completion

;;;; Begin Mappings

;; another way to use meta
(global-set-key "\C-x\C-m" 'execute-extended-command)
(global-set-key "\C-c\C-m" 'execute-extended-command)

;; ways to delete word backwards
(global-set-key "\C-w" 'backward-kill-word)
(global-set-key "\C-x\C-k" 'kill-region)
(global-set-key "\C-c\C-k" 'kill-region)

(global-set-key (kbd "C-c o") 'occur) ;; occur!!
(global-set-key (kbd "C-x C-r") 'rename-current-buffer-file) ;; rename

;;;; End Mappings

;;;; Begin Editing

;;; tramp for remote editing
(use-package tramp
  :config
  (setq tramp-default-method "ssh"))

(transient-mark-mode 1) ; enable transient mark mode

(setq kill-whole-line t) ; kills entire line if at the beginning
(fset 'yes-or-no-p 'y-or-n-p) ; yes or no to y or n
(column-number-mode 1) ; makes the column number show up

;; add auto indent to all programming modes
;; doing this after init for the first install
(add-hook 'after-init-hook
          (function (lambda ()
                      (add-hook 'prog-mode-hook 'set-newline-and-indent))))

;;; indenting
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(setq indent-line-function 'insert-tab)
(setq c-default-style "k&r"
      c-basic-offset 4)

(defvaralias 'c-basic-offset 'tab-width)
(defvaralias 'cperl-indent-level 'tab-width)

;;; folding
(add-hook 'c-mode-common-hook   'hs-minor-mode)
(add-hook 'emacs-lisp-mode-hook 'hs-minor-mode)
(add-hook 'java-mode-hook       'hs-minor-mode)
(add-hook 'lisp-mode-hook       'hs-minor-mode)
(add-hook 'perl-mode-hook       'hs-minor-mode)
(add-hook 'sh-mode-hook         'hs-minor-mode)
(add-hook 'python-mode-hook     'hs-minor-mode)

(global-auto-revert-mode t) ; automatically reload buffers on change

(use-package autopair
  :diminish autopair-mode
  :config
  (autopair-global-mode 1))

;;; clipboards

;; for linux
(when (eq system-type 'linux)
  (use-package xclip
    :config
    (xclip-mode 1)))

;; for mac
(if (window-system)
    (progn)
  (when (eq system-type 'darwin)
    (use-package pbcopy
      :config
      (turn-on-pbcopy))))

;;;; End Editing

;;;; Begin Navigation

;; windmove & framemove
(when (fboundp 'windmove-default-keybindings)
  (windmove-default-keybindings 'meta))

(use-package framemove
  :config
  (windmove-default-keybindings)
  (setq framemove-hook-into-windmove t))

;; navigating splits similar to tmux config
(global-unset-key (kbd "C-q"))
(global-set-key (kbd "C-q -") 'split-window-below)
(global-set-key (kbd "C-q |") 'split-window-right)
(global-set-key (kbd "C-q \\") 'split-window-right)
(global-set-key (kbd "C-q h") 'windmove-left)
(global-set-key (kbd "C-q l") 'windmove-right)
(global-set-key (kbd "C-q k") 'windmove-up)
(global-set-key (kbd "C-q j") 'windmove-down)
(global-set-key (kbd "C-q x") 'delete-window)
(global-set-key (kbd "C-q C-h") 'windmove-left)
(global-set-key (kbd "C-q C-l") 'windmove-right)
(global-set-key (kbd "C-q C-k") 'windmove-up)
(global-set-key (kbd "C-q C-j") 'windmove-down)
(global-set-key (kbd "C-q C-x") 'delete-window)

;;;; End Navigation

;;;; Begin File Management

(use-package swiper
  :ensure counsel
  :diminish ivy-mode
  :config
  ;(ivy-mode 1)
  ;(define-key ivy-mode-map [escape] 'minibuffer-keyboard-quit)
  (setq ivy-count-format "")
  ;(define-key ivy-mode-map (kbd "RET") 'ivy-alt-done)
  ;(define-key ivy-mode-map (kbd "C-j") 'ivy-done)
  ;(setq ivy-use-virtual-buffers t)
  (setq ivy-height 7))

(use-package smex
  :bind (("M-x" . smex))
  :config
  (global-set-key (kbd "M-X") 'smex-major-mode-commands))

(use-package ag) ; silver searcher

;;; projectile
(use-package projectile
  :commands (projectile-find-file
             projectile-switch-project
             projectile-switch-to-buffer
             projectile-ag)
  :diminish projectile-mode
  :init
  :config
  (projectile-global-mode)
  (setq projectile-completion-system 'ivy))

;;; saving
(setq auto-save-default nil) ; no autosave

;;; backups
;; write backup files to own directory
(setq backup-directory-alist
      `(("." . ,(expand-file-name
                 (concat user-emacs-directory "backups")))))

(setq vc-make-backup-files t) ; make backups of files, even when they're in version control

;;; ido
(setq ido-enable-flex-matching t)
(setq ido-everywhere t)
(ido-mode 1)
(ido-mode 'both) ; for buffers and files

(setq confirm-nonexistent-file-or-buffer nil) ; do not confirm a new file or buffer
(setq ido-enable-tramp-completion t) ; tramp completion

(setq ido-enable-flex-matching t)
(setq ido-create-new-buffer 'always)
(setq ido-enable-last-directory-history nil)
(setq ido-confirm-unique-completion nil) ; wait for RET, even for unique?
(setq ido-use-filename-at-point t) ; prefer file names near point

;;; flx matching
(use-package flx-ido
  :init
  (ido-everywhere 1)
  (flx-ido-mode 1)
  (setq ido-use-faces nil))

;; same filenames get the directory name inserted also
(use-package uniquify
  :ensure nil
  :config
  (setq uniquify-buffer-name-style 'reverse)
  (setq uniquify-separator "|")
  (setq uniquify-after-kill-buffer-p t)
  (setq uniquify-ignore-buffers-re "^\\*"))

;;; most recently used files
(use-package recentf
  :config
  (setq recentf-auto-cleanup 'never) ;; disable before we start recentf!
  (recentf-mode 1)
  (setq recentf-max-menu-items 25))

;;;; End File Management

;;;; Begin Evil

;;; vim style undo
(use-package undo-tree
  :diminish undo-tree-mode
  :config
  (global-undo-tree-mode))

(use-package evil
  :init
  (setq evil-want-C-u-scroll t) ; regain scroll up with c-u
  (setq evil-want-C-i-jump t) ; C-i jumps foward in jumplist

  ;; indenting related to evil
  (add-hook 'python-mode-hook
            (function (lambda ()
                        (setq evil-shift-width python-indent))))
  (add-hook 'ruby-mode-hook
            (function (lambda ()
                        (setq evil-shift-width ruby-indent-level))))
  (add-hook 'emacs-lisp-mode-hook
            (function (lambda ()
                        (setq evil-shift-width lisp-body-indent))))
  (add-hook 'org-mode-hook
            (function (lambda ()
                        (setq evil-shift-width 4))))
  :config
  (evil-mode 1)
  ;; keybinds
  (define-key evil-normal-state-map ";" 'evil-ex)
  (define-key evil-visual-state-map ";" 'evil-ex)
  (define-key evil-normal-state-map "Y" 'copy-to-end-of-line)
  (evil-define-key 'normal org-mode-map (kbd "C-i") 'org-cycle) ; cycle org mode in terminal

  ;;; occur mode
  (evil-set-initial-state 'occur-mode 'motion)
  (evil-define-key 'motion occur-mode-map (kbd "RET") 'occur-mode-goto-occurrence)
  (evil-define-key 'motion occur-mode-map (kbd "q")   'quit-window)
  (setq evil-default-cursor t))  ; fix black cursor

(use-package evil-matchit
  :config
  (global-evil-matchit-mode 1))

(use-package key-chord
  :config
  (key-chord-mode 1)
  (key-chord-define evil-insert-state-map "jk" 'evil-normal-state))

;;; magit integration
(use-package evil-magit
  :after magit)

;; esc quits
(defun minibuffer-keyboard-quit ()
  "Abort recursive edit.
In Delete Selection mode, if the mark is active, just deactivate it;
then it takes a second \\[keyboard-quit] to abort the minibuffer."
  (interactive)
  (if (and delete-selection-mode transient-mark-mode mark-active)
      (setq deactivate-mark  t)
    (when (get-buffer "*Completions*") (delete-windows-on "*Completions*"))
    (abort-recursive-edit)))

(define-key evil-normal-state-map [escape] 'keyboard-quit)
(define-key evil-visual-state-map [escape] 'keyboard-quit)
(define-key minibuffer-local-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-ns-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-completion-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-must-match-map [escape] 'minibuffer-keyboard-quit)
(define-key minibuffer-local-isearch-map [escape] 'minibuffer-keyboard-quit)
(global-set-key [escape] 'evil-exit-emacs-state)

(global-set-key [escape] 'minibuffer-keyboard-quit)

;;; evil surround
(use-package evil-surround
  :config
  (global-evil-surround-mode 1))

;;; tree like vim
(use-package neotree
  :commands (neotree-enter neotree-hide)
  :init
  (add-hook 'neotree-mode-hook
            (lambda ()
              (define-key evil-normal-state-local-map (kbd "TAB") 'neotree-enter)
              (define-key evil-normal-state-local-map (kbd "q") 'neotree-hide)
              (define-key evil-normal-state-local-map (kbd "RET") 'neotree-enter))))

;;; evil leader
(use-package evil-leader
  :config
  (add-hook 'fundamental-mode 'evil-leader-mode)
  (add-hook 'text-mode-hook 'evil-leader-mode)
  (add-hook 'prog-mode-hook 'evil-leader-mode)
  :config
  (global-evil-leader-mode)
  (evil-leader/set-leader "<SPC>")
  (evil-leader/set-key
    ;; projectile
    "f"  'projectile-find-file
    "p"  'projectile-switch-project
    "ag" 'projectile-ag
    "b"  'projectile-switch-to-buffer

    ;; ivy
    "r"  'ivy-recentf

    ;; random
    "wh" 'split-window-below
    "wv" 'split-window-right
    "-"  'split-window-below
    "|"  'split-window-right
    "\\" 'split-window-right
    "="  'iwb
    "n"  'neotree-toggle
    "v"  (lambda() (interactive)(find-file "~/.emacs.d/init.el"))
    "e"  'explorer-finder
    "m"  'multi-term

    ;; evil-nerd-commenter
    "ci" 'evilnc-comment-or-uncomment-lines
    "cl" 'evilnc-quick-comment-or-uncomment-to-the-line
    "cc" 'evilnc-copy-and-comment-lines
    "cp" 'evilnc-comment-or-uncomment-paragraphs
    "cr" 'comment-or-uncomment-region
    "cv" 'evilnc-toggle-invert-comment-line-by-line
    "\\" 'evilnc-comment-or-uncomment-lines
    "co" 'evilnc-comment-operator

    ;; magit
    "gs" 'magit-status
    "gb" 'magit-blame
    "gl" 'magit-log))

(use-package evil-nerd-commenter
  :commands (evilnc-comment-or-uncomment-lines
             evilnc-quick-comment-or-uncomment-to-the-line
             evilnc-copy-and-comment-lines
             evilnc-comment-or-uncomment-paragraphs
             comment-or-uncomment-region
             evilnc-toggle-invert-comment-line-by-line
             evilnc-comment-operator))

;;;; End Evil

;;;; Begin Languages

;;; Haskell
(use-package haskell-mode
  :mode "\\.hs\\'"
  :init
  (add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
  (add-hook 'haskell-mode-hook 'turn-on-haskell-indentation)
  (add-hook 'haskell-mode-hook 'auto-revert-mode)
  (add-hook 'haskell-mode-hook 'fold-dwim-org/minor-mode)
  (add-hook 'haskell-mode-hook 'set-newline-and-indent)
  (add-to-list 'completion-ignored-extensions ".hi"))

;;; C#
(use-package csharp-mode
  :mode "\\.cs\\'"
  :config
  (setq csharp-want-imenu nil)) ; turn off the menu

;;; Python

;; pdb setup
(when (eq system-type 'darwin)
  (setq pdb-path '/usr/lib/python2.7/pdb.py)
  (setq gud-pdb-command-name (symbol-name pdb-path))

  (defadvice pdb (before gud-query-cmdline activate)
    "Provide a better default command line when called interactively."
    (interactive
     (list (gud-query-cmdline pdb-path
                              (file-name-nondirectory buffer-file-name))))))

;; https://github.com/emacsmirror/python-mode - see troubleshooting
;; https://bugs.launchpad.net/python-mode/+bug/963253
;; http://pswinkels.blogspot.com/2010/04/debugging-python-code-from-within-emacs.html
(when (eq system-type 'windows-nt)
  (setq windows-python-pdb-path "c:/python27/python -i c:/python27/Lib/pdb.py")
  (setq pdb-path 'C:/Python27/Lib/pdb.py)
  (setq gud-pdb-command-name (symbol-name pdb-path))
  (setq gud-pdb-command-name windows-python-pdb-path)

  ;; everytime we enter a new python buffer, set the command path to include the buffer filename
  (add-hook 'python-mode-hook (function
                               (lambda ()
                                 (setq gud-pdb-command-name
                                       (concat windows-python-pdb-path " " buffer-file-name))))))

;;;; End Languages

;;;; Begin Functions

;; function that returns list of magit commands that will load magit
(defun magit-autoload-commands ()
  (list 'magit-status 'magit-blame 'magit-log))

;; auto indent function using return
(defun set-newline-and-indent ()
  (local-set-key (kbd "RET") 'newline-and-indent))

;; function to rename current buffer file
(defun rename-current-buffer-file ()
  "Renames current buffer and file it is visiting."
  (interactive)
  (let ((name (buffer-name))
        (filename (buffer-file-name)))
    (if (not (and filename (file-exists-p filename)))
        (error "Buffer '%s' is not visiting a file!" name)
      (let ((new-name (read-file-name "New name: " filename)))
        (if (get-buffer new-name)
            (error "A buffer named '%s' already exists!" new-name)
          (rename-file filename new-name 1)
          (rename-buffer new-name)
          (set-visited-file-name new-name)
          (set-buffer-modified-p nil)
          (message "File '%s' successfully renamed to '%s'"
                   name (file-name-nondirectory new-name)))))))

;; indent whole buffer
(defun iwb ()
  "indent whole buffer"
  (interactive)
  (delete-trailing-whitespace)
  (indent-region (point-min) (point-max) nil)
  (untabify (point-min) (point-max)))

;; toggle window split
(defun toggle-window-split ()
  (interactive)
  (if (= (count-windows) 2)
      (let* ((this-win-buffer (window-buffer))
             (next-win-buffer (window-buffer (next-window)))
             (this-win-edges (window-edges (selected-window)))
             (next-win-edges (window-edges (next-window)))
             (this-win-2nd (not (and (<= (car this-win-edges)
                                         (car next-win-edges))
                                     (<= (cadr this-win-edges)
                                         (cadr next-win-edges)))))
             (splitter
              (if (= (car this-win-edges)
                     (car (window-edges (next-window))))
                  'split-window-horizontally
                'split-window-vertically)))
        (delete-other-windows)
        (let ((first-win (selected-window)))
          (funcall splitter)
          (if this-win-2nd (other-window 1))
          (set-window-buffer (selected-window) this-win-buffer)
          (set-window-buffer (next-window) next-win-buffer)
          (select-window first-win)
          (if this-win-2nd (other-window 1))))))

;; rotate windows
(defun rotate-windows-helper(x d)
  (if (equal (cdr x) nil) (set-window-buffer (car x) d)
    (set-window-buffer (car x) (window-buffer (cadr x))) (rotate-windows-helper (cdr x) d)))

(defun rotate-windows ()
  (interactive)
  (rotate-windows-helper (window-list) (window-buffer (car (window-list))))
  (select-window (car (last (window-list)))))

;; use variable width font faces in current buffer
(defun my-buffer-face-mode-variable ()
  "Set font to a variable width (proportional) fonts in current buffer"
  (interactive)
  (setq buffer-face-mode-face '(:family "Helvetica" :height 130 :width semi-condensed))
  (buffer-face-mode))

;; use monospaced font faces in current buffer
(defun my-buffer-face-mode-fixed ()
  "Sets a fixed width (monospace) font in current buffer"
  (interactive)
  (setq buffer-face-mode-face '(:family "Consolas" :height 120))
  (buffer-face-mode))

;; os agnostic open in file explorer
(defun explorer-finder ()
  "Opens up file explorer based on operating system."
  (interactive)
  (if (eq system-type 'windows-nt)
      (explorer))
  (if (eq system-type 'darwin)
      (reveal-in-osx-finder)))

;; close compilation window on successful compile
(setq compilation-finish-functions 'compile-autoclose)
(defun compile-autoclose (buffer string)
  (cond ((string-match "finished" string)
         (message "Build maybe successful: closing window.")
         (run-with-timer 1 nil
                         'delete-window
                         (get-buffer-window buffer t)))
        (t
         (message "Compilation exited abnormally: %s" string))))

;; function to find recent files using ido
(defun recentf-ido-find-file ()
  "Find a recent file using Ido."
  (interactive)
  (let* ((file-assoc-list
          (mapcar (lambda (x)
                    (cons (file-name-nondirectory x)
                          x))
                  recentf-list))
         (filename-list
          (remove-duplicates (mapcar #'car file-assoc-list)
                             :test #'string=))
         (filename (ido-completing-read "Choose recent file: "
                                        filename-list
                                        nil
                                        t)))
    (when filename
      (find-file (cdr (assoc filename
                             file-assoc-list))))))
;;;; End Functions

;;;; Begin Org Mode

(use-package org
  :mode ("\\.org\\'" . org-mode)
  :init
  ;; folding like Org Mode in all modes
  (add-hook 'prog-mode-hook 'fold-dwim-org/minor-mode)
  (add-hook 'text-mode-hook 'fold-dwim-org/minor-mode)
  ;; associate .org files with org-mode inside of emacs
  :config
  ;; hotkeys for org-mode
  (global-set-key "\C-cl" 'org-store-link)
  (global-set-key "\C-cc" 'org-capture)
  (global-set-key "\C-ca" 'org-agenda)
  (global-set-key "\C-cb" 'org-iswitchb)
  (setq org-src-fontify-natively t)
  (setq org-hide-leading-stars t)
  (setq org-goto-interface 'outline-path-completion
        org-goto-max-level 10))

;;;; End Org Mode
