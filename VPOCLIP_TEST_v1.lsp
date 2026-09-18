;; ============================================================================
;; VPOCLIP_TEST_v1.lsp - automatyczne testy integracyjne filtrowania XREF
;;
;; Cel: sprawdzic w prawdziwym BricsCAD (nie da sie tego zrobic poza CAD-em,
;; bo funkcje vla-*/vlax-* dzialaja na zywym dokumencie), ze filtrowanie
;; XREF w VPOCLIP_v3.39_brics.lsp poprawnie bierze pod uwage TYLKO glowny
;; (najwyzszego poziomu) XREF, a zagniezdzone XREF-y (nazwy w postaci
;; "GLOWNY|ZAGNIEZDZONY") sa ignorowane przy liczeniu/odlaczaniu.
;;
;; Test sam buduje potrzebne rysunki .dwg (nie trzeba nic przygotowywac
;; recznie) w folderze %TEMP%\VPOCLIP_TEST:
;;   vptest_leaf.dwg   - prosty rysunek bez XREF-ow
;;   vptest_middle.dwg - dolacza vptest_leaf.dwg jako XREF "LEAF"
;;   vptest_host.dwg   - dolacza:
;;       * vptest_middle.dwg jako XREF "VPTEST_MIDDLE"
;;         (w srodku ma zagniezdzony XREF "VPTEST_MIDDLE|LEAF")
;;       * vptest_leaf.dwg jako XREF "VPTEST_OTHER" (plaski, bez zagniezdzenia)
;;
;; Sposob uzycia w BricsCAD:
;;   1. APPLOAD -> VPOCLIP_v3.39_brics.lsp   (najpierw glowny plik!)
;;   2. APPLOAD -> VPOCLIP_TEST_v1.lsp
;;   3. w linii poleceń: VPOTEST
;;   4. wynik PASS/FAIL pojawia sie w linii poleceń i w pliku
;;      %TEMP%\VPOCLIP_TEST\vptest_report.txt
;;
;; UWAGA: test tworzy i zamyka wlasne dokumenty testowe (bez zapisywania
;; zmian dokonanych w trakcie testu) - nie dotyka aktualnie otwartego
;; rysunku uzytkownika. Mozna go uruchamiac wielokrotnie, pliki testowe
;; sa za kazdym razem nadpisywane.
;; ============================================================================

(vl-load-com)

(setq vptest:results nil)

(defun vptest:check ( name condition detail / passed )
    (setq passed (if condition T nil))
    (setq vptest:results (cons (list name passed detail) vptest:results))
    (princ (strcat "\n[" (if passed "PASS" "FAIL") "] " name
                    (if (and detail (/= detail "")) (strcat "  (" detail ")") "")))
    passed
)

(defun vptest:try ( fn / r )
    ;; Wykonuje fn (funkcje bezargumentowa) i chroni cala reszte testow
    ;; przed nieprzechwyconym bledem lispa w jednym z krokow.
    (setq r (vl-catch-all-apply fn nil))
    (if (vl-catch-all-error-p r)
        (progn
            (vptest:check "runtime" nil (vl-catch-all-error-message r))
            nil
        )
        T
    )
)

(defun vptest:temp-dir ( / base dir )
    (setq base (getenv "TEMP"))
    (if (or (null base) (= (vclip:trim-v34 base) "")) (setq base "C:\\Temp"))
    (setq dir (strcat base "\\VPOCLIP_TEST"))
    (if (not (vl-catch-all-apply 'vl-file-directory-p (list dir)))
        (vl-catch-all-apply 'vl-mkdir (list dir)))
    dir
)

(defun vptest:new-blank-doc ( / app docs r )
    (setq app  (vlax-get-acad-object)
          docs (vla-get-Documents app))
    (setq r (vl-catch-all-apply 'vla-Add (list docs)))
    (if (vl-catch-all-error-p r) nil r)
)

(defun vptest:save-as ( doc path / r )
    (setq r (vl-catch-all-apply 'vla-SaveAs (list doc path)))
    (not (vl-catch-all-error-p r))
)

(defun vptest:draw-line ( doc / ms r )
    (setq ms (vla-get-ModelSpace doc))
    (setq r
        (vl-catch-all-apply
            'vla-AddLine
            (list ms (vlax-3d-point 0.0 0.0 0.0) (vlax-3d-point 10.0 10.0 0.0))))
    (not (vl-catch-all-error-p r))
)

(defun vptest:attach-xref ( doc path xrefname / ms r )
    (setq ms (vla-get-ModelSpace doc))
    (setq r
        (vl-catch-all-apply
            'vla-AttachExternalReference
            (list ms path xrefname
                  (vlax-3d-point 0.0 0.0 0.0)
                  1.0 1.0 1.0 0.0 :vlax-false)))
    (not (vl-catch-all-error-p r))
)

(defun vptest:build-fixtures ( / dir leafpath middlepath hostpath doc ok )
    (setq dir        (vptest:temp-dir)
          leafpath   (strcat dir "\\vptest_leaf.dwg")
          middlepath (strcat dir "\\vptest_middle.dwg")
          hostpath   (strcat dir "\\vptest_host.dwg")
          ok         T)

    ;; leaf.dwg - najnizszy poziom, zwykly rysunek bez XREF-ow
    (setq doc (vptest:new-blank-doc))
    (if (null doc)
        (setq ok (vptest:check "fixture: nowy rysunek (leaf)" nil ""))
        (progn
            (vclip:activate-doc-v31 doc)
            (vptest:draw-line doc)
            (setq ok (and (vptest:check "fixture: zapis leaf.dwg"
                              (vptest:save-as doc leafpath) leafpath)
                          ok))
            (vclip:close-doc-nosave-v31 doc)
        )
    )

    ;; middle.dwg - dolacza leaf.dwg jako XREF "LEAF"; po dolaczeniu middle.dwg
    ;; do hosta ten XREF stanie sie zagniezdzony (host widzi go jako
    ;; "VPTEST_MIDDLE|LEAF")
    (if ok
        (progn
            (setq doc (vptest:new-blank-doc))
            (if (null doc)
                (setq ok (vptest:check "fixture: nowy rysunek (middle)" nil ""))
                (progn
                    (vclip:activate-doc-v31 doc)
                    (vptest:draw-line doc)
                    (setq ok (and (vptest:check "fixture: XREF LEAF w middle.dwg"
                                      (vptest:attach-xref doc leafpath "LEAF") "")
                                  ok))
                    (setq ok (and (vptest:check "fixture: zapis middle.dwg"
                                      (vptest:save-as doc middlepath) middlepath)
                                  ok))
                    (vclip:close-doc-nosave-v31 doc)
                )
            )
        )
    )

    ;; host.dwg - rysunek testowy uzywany przez wlasciwe testy
    (setq doc nil)
    (if ok
        (progn
            (setq doc (vptest:new-blank-doc))
            (if (null doc)
                (progn
                    (vptest:check "fixture: nowy rysunek (host)" nil "")
                    (setq ok nil)
                )
                (progn
                    (vclip:activate-doc-v31 doc)
                    (setq ok (and (vptest:check
                                      "fixture: XREF VPTEST_MIDDLE w host.dwg (zagniezdza LEAF)"
                                      (vptest:attach-xref doc middlepath "VPTEST_MIDDLE") "")
                                  ok))
                    (setq ok (and (vptest:check
                                      "fixture: XREF VPTEST_OTHER w host.dwg (plaski, ma nie pasowac do wzorca)"
                                      (vptest:attach-xref doc leafpath "VPTEST_OTHER") "")
                                  ok))
                    (setq ok (and (vptest:check "fixture: zapis host.dwg"
                                      (vptest:save-as doc hostpath) hostpath)
                                  ok))
                )
            )
        )
    )
    (list dir leafpath middlepath hostpath (if ok doc nil))
)

(defun vptest:block-t1-t4 ( / fx doc pattern xprep xres nm )
    (setq pattern "*MIDDLE*")
    (setq fx  (vptest:build-fixtures)
          doc (nth 4 fx))
    (if (null doc)
        (vptest:check "T1-T4 setup" nil "nie udalo sie zbudowac rysunkow testowych")
        (progn
            (vclip:activate-doc-v31 doc)
            (vclip:reset-xref-name-cache-v325)

            ;; T1 - to jest bezposredni test poprawki: przed nia funkcja liczyla
            ;; TAKZE zagniezdzony XREF "VPTEST_MIDDLE|LEAF" (wynik = 3). Po
            ;; poprawce liczy tylko definicje najwyzszego poziomu (wynik = 2:
            ;; VPTEST_MIDDLE + VPTEST_OTHER).
            (vptest:check "T1: xref-definition-count pomija zagniezdzony XREF"
                (= 2 (vclip:xref-definition-count-v325))
                (strcat "oczekiwano 2, otrzymano "
                        (itoa (vclip:xref-definition-count-v325))))

            ;; T2 - wstawienia najwyzszego poziomu w przestrzeniach hosta
            (vptest:check "T2: top-level-xref-count = 2 (VPTEST_MIDDLE, VPTEST_OTHER)"
                (= 2 (vclip:top-level-xref-count-v333))
                (strcat "otrzymano " (itoa (vclip:top-level-xref-count-v333))))

            ;; T3 - reload/unload przygotowujacy XREF-y do PDF potrafi
            ;; dynamicznie tworzyc/kasowac definicje zagniezdzonego LEAF;
            ;; liczba GLOWNYCH XREF-ow ma pozostac stabilna
            (setq xprep (vclip:prepare-xrefs-for-pdf-v333 pattern nil))
            (vptest:check "T3: prepare-xrefs-for-pdf zakonczone bez bledow"
                (car xprep) (vl-princ-to-string xprep))
            (vptest:check "T3: liczba glownych XREF stabilna po reload/unload"
                (= 2 (vclip:xref-definition-count-v325))
                (strcat "oczekiwano 2, otrzymano "
                        (itoa (vclip:xref-definition-count-v325))))

            ;; T4 - filtr wg wzorca "*MIDDLE*": ma odlaczyc VPTEST_OTHER
            ;; (nie pasuje), zostawic VPTEST_MIDDLE razem z zagniezdzonym
            ;; LEAF w srodku (zagniezdzony XREF nigdy nie jest odlaczany
            ;; bezposrednio - idzie razem z rodzicem)
            (vclip:reset-xref-name-cache-v325)
            (setq xres (vclip:filter-xrefs-v34 pattern))
            (vptest:check "T4: filter-xrefs bez bledow odlaczania"
                (= 0 (nth 4 xres)) (vl-princ-to-string xres))
            (vptest:check "T4: po filtrze zostaje 1 glowny XREF (VPTEST_MIDDLE)"
                (= 1 (vclip:xref-definition-count-v325))
                (strcat "oczekiwano 1, otrzymano "
                        (itoa (vclip:xref-definition-count-v325))))
            (setq nm (vclip:collect-nonmatching-xref-names-v34 pattern))
            (vptest:check "T4: brak niedopasowanych definicji XREF po filtrze"
                (null nm) (vl-princ-to-string nm))
            (vptest:check "T4: VPTEST_MIDDLE nadal dolaczony"
                (vclip:xref-block-exists-p-v34 "VPTEST_MIDDLE") "")

            (vclip:close-doc-nosave-v31 doc)
        )
    )
    (princ)
)

(defun vptest:block-t5 ( / fx doc pattern before after )
    ;; T5 - wierna symulacja sciezki z vclip:fast-export-task-v324:
    ;; UNDO mark -> reload/unload dla PDF -> filtr XREF -> UNDO Back,
    ;; z porownaniem liczby GLOWNYCH definicji XREF przed/po. To dokladnie
    ;; ten mechanizm, ktory przed poprawka falszywie zglaszal blad zadania
    ;; ("UNDO nie przywrocilo kopii zrodlowej") wylacznie w rysunkach
    ;; z zagniezdzonymi XREF-ami.
    (setq pattern "*MIDDLE*")
    (setq fx  (vptest:build-fixtures)
          doc (nth 4 fx))
    (if (null doc)
        (vptest:check "T5 setup" nil "nie udalo sie zbudowac swiezej kopii testowej")
        (progn
            (vclip:activate-doc-v31 doc)
            (vclip:reset-xref-name-cache-v325)
            (LM:startundo doc)
            (setq before (vclip:xref-definition-count-v325))
            (vclip:prepare-xrefs-for-pdf-v333 pattern nil)
            (vclip:filter-xrefs-v34 pattern)
            (LM:endundo doc)
            (vclip:undo-back-v312)
            (vclip:reset-xref-name-cache-v325)
            (setq after (vclip:xref-definition-count-v325))
            (vptest:check "T5: liczba glownych XREF przed/po UNDO Back zgodna"
                (= before after)
                (strcat "przed=" (itoa before) " po=" (itoa after)))
            (vclip:close-doc-nosave-v31 doc)
        )
    )
    (princ)
)

(defun vptest:print-summary ( / total passed failed report f )
    (setq total  (length vptest:results)
          passed (length (vl-remove-if-not '(lambda (r) (cadr r)) vptest:results))
          failed (- total passed))
    (princ (strcat "\n\n=== VPOTEST PODSUMOWANIE: " (itoa passed) "/" (itoa total)
                    " zaliczone, " (itoa failed) " bledow ==="))
    (if (> failed 0)
        (progn
            (princ "\nNIEZALICZONE:")
            (foreach r (reverse vptest:results)
                (if (not (cadr r))
                    (princ (strcat "\n  - " (car r)
                                    (if (and (caddr r) (/= (caddr r) ""))
                                        (strcat "  (" (caddr r) ")")
                                        "")))))))
    (setq report (strcat (vptest:temp-dir) "\\vptest_report.txt"))
    (setq f (vl-catch-all-apply 'open (list report "w")))
    (if (and f (not (vl-catch-all-error-p f)))
        (progn
            (write-line "VPOCLIP TEST - filtrowanie XREF (w tym zagniezdzone)" f)
            (foreach r (reverse vptest:results)
                (write-line
                    (strcat (if (cadr r) "PASS " "FAIL ") (car r)
                            (if (and (caddr r) (/= (caddr r) ""))
                                (strcat " | " (caddr r))
                                ""))
                    f))
            (write-line (strcat "SUMMARY " (itoa passed) "/" (itoa total)) f)
            (close f)
            (princ (strcat "\nRaport zapisany: " report))
        )
    )
    (list passed failed)
)

(defun c:VPOTEST ( / oldfiledia summary )
    (vl-load-com)
    (cond
        ((not (and (boundp 'vclip:xref-definition-count-v325)
                   (boundp 'vclip:filter-xrefs-v34)
                   (boundp 'vclip:prepare-xrefs-for-pdf-v333)
                   (boundp 'vclip:collect-nonmatching-xref-names-v34)
                   (boundp 'vclip:top-level-xref-count-v333)
                   (boundp 'vclip:undo-back-v312)))
         (princ "\nVPOTEST: najpierw wczytaj (APPLOAD) VPOCLIP_v3.39_brics.lsp, dopiero potem VPOCLIP_TEST_v1.lsp, i ponownie uruchom VPOTEST.")
        )
        (t
         (setq vptest:results nil
               oldfiledia (vclip:getvar-safe-v35 'FILEDIA 1))
         (vl-catch-all-apply 'setvar (list 'FILEDIA 0))
         (princ "\n=== VPOTEST: automatyczne testy filtrowania XREF (w tym zagniezdzonych) ===")
         (vptest:try 'vptest:block-t1-t4)
         (vptest:try 'vptest:block-t5)
         (setq summary (vptest:print-summary))
         (vl-catch-all-apply 'setvar (list 'FILEDIA oldfiledia))
         (princ (strcat "\nVPOTEST zakonczony. Wynik: "
                         (itoa (car summary)) "/"
                         (itoa (+ (car summary) (cadr summary)))))
        )
    )
    (princ)
)

(princ "\nVPOCLIP_TEST_v1.lsp wczytany. Uruchom komende VPOTEST.")
(princ)
