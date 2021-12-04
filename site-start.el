;;; site-start.el --- 

;; Copyright © 2012 Sébastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>

;; Author: Sébastien Gross <seb•ɑƬ•chezwam•ɖɵʈ•org>
;; Keywords: emacs, 
;; Created: 2012-09-21
;; Last changed: 2020-04-02 22:08:59
;; Licence: WTFPL, grab your copy here: http://sam.zoy.org/wtfpl/

;; This file is NOT part of GNU Emacs.

;;; Commentary:
;; 


;;; Code:

(require 'dired)
(require 'files)

(setq source-directory
      (expand-file-name  ".." data-directory))

(defvar emacs-patches-directory
  (expand-file-name  "../patches" data-directory)
  "Directory containing all patches used when Emacs was built.")

(defvar emacs-patches-list
  (directory-files emacs-patches-directory nil ".*\\.patch" nil)
  "List of all patches applied when Emacs was built.")

(defun view-emacs-patches ()
  "Open `dired' in `emacs-patches-directory'."
  (interactive)
  (dired emacs-patches-directory))

(defun view-emacs-patch (&optional patch)
  "Find PATCH used when Emacs was built in
`emacs-patches-directory'."
  (interactive)
  (let* ((patch (or patch
		    (completing-read "View patch: "
				     emacs-patches-list nil t)))
	 (patch-file (format "%s/%s" emacs-patches-directory patch)))
    (if (file-exists-p patch-file)
	(find-file patch-file)
      (error "No patch matching %s found in %s."
	     patch emacs-patches-directory))))

(provide 'site-start)

;; site-start.el ends here
