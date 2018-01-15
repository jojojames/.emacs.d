;;;; -*- lexical-binding: t; -*-

(use-package csharp-mode
  :ensure t
  :mode "\\.cs\\'"
  :config
  (setq csharp-want-imenu t)
  ;; Folding support for `hs-minor-mode'.
  (defun csharp-hs-forward-sexp (&optional arg)
    (message "csharp-hs-forward-sexp, (arg %d) (point %d)…"
             (if (numberp arg) arg -1)
             (point))
    (let ((nestlevel 0)
          (done nil))
      (if (and arg (< arg 0))
          (message "negative arg (%d) is not supported…" arg)
        ;; else, we have a positive argument, hence move forward.
        ;; simple case is just move forward one brace
        (if (looking-at "{")
            (forward-sexp arg)
          ;; The more complex case is dealing with a "region/endregion" block.
          ;; We have to deal with nested regions!
          (and
           (while (not done)
             (re-search-forward "^[ \\t]*#[ \\t]*\\(region\\|endregion\\)\\b"
                                (point-max) 'move)
             (cond
              ((eobp)) ;; Do nothing if at end of buffer.
              ((and
                (match-beginning 1)
                ;; If the match is longer than 6 chars, we know it is "endregion".
                (if (> (- (match-end 1) (match-beginning 1)) 6)
                    (setq nestlevel (1- nestlevel))
                  (setq nestlevel (1+ nestlevel))))))
             (setq done (not (and (> nestlevel 0) (not (eobp)))))) ; while
           (if (= nest 0)
               (goto-char (match-end 2))))))))

  (unless (assoc 'csharp-mode hs-special-modes-alist)
    (push '(csharp-mode
            ;; regexp for start block
            "\\(^[ \\t]*#[ \\t]*region\\b\\)\\|{"
            ;; regexp for end block
            "\\(^[ \\t]*#[ \\t]*endregion\\b\\)\\|}"
            ;; regexp for comment start
            "/[*/]"
            ;; hs-forward-sexp-func
            csharp-hs-forward-sexp
            ;; c-like adjust (1 char))
            hs-c-like-adjust-block-beginning)
          hs-special-modes-alist)))

(use-package omnisharp
  :ensure t
  :commands (omnisharp-mode)
  :init
  (defun +company-omnisharp-setup ()
    "Sets up c# completion with company."
    (+company-push-backend 'company-omnisharp))
  (defun +omnisharp-setup ()
    "Bootstrap omnisharp."
    (setq omnisharp-debug t)
    (omnisharp-mode))
  (defun +csharp-mode-hook ()
    "csharp mode hook"
    (+omnisharp-setup)
    (+company-omnisharp-setup))
  (add-hook 'csharp-mode-hook #'+csharp-mode-hook)
  :config
  (evil-define-key 'normal csharp-mode-map
    (kbd "K") 'omnisharp-current-type-information)

  ;; Hangs Emacs currently for some types.
  ;; Revisit at some point.
  (setq omnisharp-eldoc-support nil))

;;;###autoload
(defun +csharp-mode ()
  "Bootstrap `jn-csharp'."
  (setq auto-mode-alist (rassq-delete-all #'+csharp-mode auto-mode-alist))
  (csharp-mode))

;; https://github.com/josteink/csharp-mode/issues/72
;; https://emacs.stackexchange.com/questions/22490/how-do-i-prevent-indentation-of-braces-in-function-arguments-with-csharp-mode
(c-add-style
 "csharp"
 '("C#"
   (c-offsets-alist . ((arglist-intro  . +)
                       (statement-cont . (add c-lineup-assignments +))))))

(+update-c-style '(csharp-mode . "csharp"))

;; (use-package jn-xamarin :ensure nil)

(provide 'jn-csharp)
;; Local Variables:
;; byte-compile-warnings: (not free-vars unresolved noruntime cl-functions)
;; End:
;;; jn-csharp.el ends here
