;; @file       destructuring.nu
;; @discussion Macros similar to destructuring-bind in Common Lisp.
;;
;; @copyright  Copyright (c) 2008 Issac Trotts
;;
;;   Licensed under the Apache License, Version 2.0 (the "License");
;;   you may not use this file except in compliance with the License.
;;   You may obtain a copy of the License at
;;
;;       http://www.apache.org/licenses/LICENSE-2.0
;;
;;   Unless required by applicable law or agreed to in writing, software
;;   distributed under the License is distributed on an "AS IS" BASIS,
;;   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
;;   See the License for the specific language governing permissions and
;;   limitations under the License.

;; Destructuring bind.  The implementation here is very loosely based
;; on the one on p. 232 of Paul Graham's book On Lisp.
(macro dbind
    (set __pat (first margs))
    (set __seq (eval (second margs)))
    (set __body (cdr (cdr margs)))
    (set __bindings (destructure __pat __seq))
    (check-bindings __bindings)
    (set __result (append (list 'let __bindings)
                          __body))
    (eval __result))

(macro dset
    (set __pat (first margs))
    (set __seq (eval (second margs)))
    (set __bindings (destructure __pat __seq))
    (check-bindings __bindings)
    (set __set-statements
          (__bindings map:(do (b)
                              (list 'set (first b) (second b)))))
    (eval (cons 'progn __set-statements)))

;; Given a pattern like '(a (b c)) and a sequence like '(1 (2 3)),
;; returns a list of bindings like '((a 1) (b 2) (c 3)).
(function destructure (pat seq)
    (cond
     ((null? pat)
      nil)
     ((symbol? pat)
      (let (seq (if (or (pair? seq) (symbol? seq))
                    (then (list 'quote seq))
                    (else seq)))
          (list (list pat seq))))
     ((pair? pat)
      (then (let ((bindings1 (destructure (car pat) (car seq)))
                  (bindings2 (destructure (cdr pat) (cdr seq))))
                (append bindings1 bindings2))))
     (else (print "ERROR: pat is not nil, a symbol or a pair: " pat "\n"))))

;; Makes sure that no key is set to two different values.
;; For example (check-bindings '((a 1) (a 1) (b 2))) just returns its argument,
;; but (check-bindings '((a 1) (a 2) (b 2))) throws a NuDestructuringException.
(function check-bindings (bindings)
    (set dic (dict))
    (bindings each:(do (b) 
                       (set key (first b))
                       (set val (second b))
                       (set prev-val (dic key))  ; valueForKey inexplicably rejects symbols
                       (if (eq nil prev-val)
                           (then (dic setValue:val forKey:key))
                           (else
                               (if (not (eq val prev-val))
                                   (then 
                                       ;; TODO(issac.trotts@gmail.com): Add a more informative
                                       ;; error message.
                                       (set exn
                                            ((NSException alloc) initWithName:"NuDestructuringException"
                                                                       reason:"Inconsistent bindings"
                                                                     userInfo:nil))
                                       (exn raise)))))))
    bindings)
