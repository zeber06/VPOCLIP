;;==================================================================;;
;;  VPOCLIP_v3.39_brics.lsp                                          ;;
;;  VPOCLIP / VPOONLY                                               ;;
;;  Zostawia jeden layout oraz zawartosc ramek VPO-NPLT tego layoutu ;;
;;  w Modelu, reszte Modelu usuwa. Papier zostawionego layoutu       ;;
;;  pozostaje bez zmian.                                             ;;
;;                                                                  ;;
;;  Nowosc v3.1:                                                     ;;
;;    - VPOEXPORT / VPOONLYEXPORT                                   ;;
;;      zapisuje wynik do nowego pliku DWG bez ingerencji            ;;
;;      w otwarty plik zrodlowy.                                     ;;
;;                                                                  ;;
;;  Poprawka v3.2:                                                   ;;
;;    - LM:acdoc nie zapamietuje juz pierwszego dokumentu.           ;;
;;      To naprawia VPOEXPORT: czyszczenie wykonuje sie na kopii,     ;;
;;      a nie na pliku zrodlowym.                                    ;;
;;                                                                  ;;
;;  Nowosc v3.3:                                                     ;;
;;    - po usunieciu obiektow i layoutow wykonywany jest PURGE/All.;;
;;                                                                  ;;
;;  Nowosc v3.4:                                                     ;;
;;    - VPOEXPORTCFG zostawia wszystkie XREF-y pasujace do klucza,  ;;
;;      niezaleznie od ramek, oraz chroni warstwe _Podzial...       ;;
;;                                                                  ;;
;;  Poprawka v3.12:                                                  ;;
;;    - LINE i proste LWPOLYLINE sa przycinane do sumy ramek.       ;;
;;    - INSERT (blok lokalny lub XREF) nigdy nie jest rozbijany      ;;
;;      ani przycinany; obiekt przecinajacy ramke zostaje w calosci.;;
;;    - poprawiony bbox przyspiesza filtrowanie duzych rysunkow.     ;;
;;                                                                  ;;
;;  Poprawka v3.13:                                                  ;;
;;    - BricsCAD zapamiętuje ścieżkę LISP-a używaną przez VPOBATCH.  ;;
;;    - brak okna wyboru, gdy narzędzie pozostaje w tym folderze.    ;;
;;                                                                  ;;
;;  Poprawka v3.14:                                                  ;;
;;    - wyniki powstaja od razu pod nazwa z VPOCLIP_CONF.txt.            ;;
;;    - brak roboczych DWG/PDF z dopiskiem _VPOCLIP_WORK.           ;;
;;    - kazde zadanie dziala w osobnym procesie BricsCAD; poprzedni  ;;
;;      proces jest zamykany przed utworzeniem kolejnego DWG.       ;;
;;                                                                  ;;
;;  Poprawka v3.15:                                                  ;;
;;    - panel pokazuje liste zadan, aktualny etap i postep eksportu. ;;
;;    - wynik kazdego zadania jest widoczny jako Gotowe lub Blad.   ;;
;;                                                                  ;;
;;  Poprawka v3.32:                                                  ;;
;;    - jedna instancja BricsCAD obsluguje cala kolejke zadan.        ;;
;;    - szybki eksport wykorzystuje WBLOCK i UNDO na kopii zrodla.  ;;
;;    - PROXYNOTICE=0 jest zapisywane w aktywnym profilu BricsCAD-a.  ;;
;;    - kontroler i roboczy BricsCAD dzialaja w tle.         ;;
;;    - pakiet jest instalowany w stalym katalogu C:/VPOCLIP.        ;;
;;    - lokalizator akceptuje wylacznie dokladna wersje v3.32.       ;;
;;    - brak okien wyboru LISP i CONF podczas VPOBATCH.              ;;
;;    - panel pokazuje folder eksportu i pozwala go otworzyc.        ;;
;;    - panel podsumowuje opcje i pozwala bezpiecznie przerwac prace.;;
;;    - PDF_From_Source wybiera wydruk przed albo po podziale.       ;;
;;    - XREF-y sa ladowane selektywnie wedlug klucza zadania.        ;;
;;    - Process_All wyznacza klucz z 2 pierwszych znakow layoutu.    ;;
;;    - Ignore_XREF=YES laduje wszystkie XREF-y po potwierdzeniu.    ;;
;;                                                                  ;;
;;  Poprawka v3.33:                                                  ;;
;;    - przygotowanie PDF obsluguje tylko faktycznie wstawione       ;;
;;      XREF-y; osierocone definicje XREF sa pomijane.               ;;
;;    - licznik ostrzezenia Ignore_XREF uwzglednia tylko wstawki.    ;;
;;                                                                  ;;
;;  Wariant v3.35-brics:                                             ;;
;;    - osobna wersja dla BricsCAD V26 na Windows.  ;;
;;    - przecinajace ramki INSERT-y sa wykrywane jawnie po bbox.     ;;
;;    - skrypt nie wywoluje CLOSE pomiedzy zadaniami BricsCAD.        ;;
;;    - DWG/PDF sa finalizowane przez bezpieczna kopie plikow.       ;;
;;    - PDF powstaje z Page Setup pozostawionego layoutu.            ;;
;;    - zapisuje VPOCLIP_brics_trace.txt do diagnostyki BricsCAD-a.      ;;
;;                                                                  ;;
;;  Poprawka v3.34-brics:                                            ;;
;;    - ramki prostokatne dzialaja niezaleznie od kierunku           ;;
;;      kolejnosci wierzcholkow (CW albo CCW).                       ;;
;;    - usunieto odbijanie obszaru ciecia na druga strone ramki.     ;;
;;                                                                  ;;
;;  Nowosc v3.35-brics:                                              ;;
;;    - LCLIP eksportuje wybrane lub wszystkie layouty bez CONF.     ;;
;;    - nazwa DWG/PDF jest identyczna z nazwa zakladki.              ;;
;;    - panel odswieza etap pracy od razu po starcie workera.        ;;
;;                                                                  ;;
;;  Nowosc v3.36-brics:                                              ;;
;;    - LCLIP i VPOBATCH automatycznie tworza prostokatne ramki,     ;;
;;      gdy layout nie ma zadnej ramki VPOutline.                    ;;
;;    - ramki powstaja tylko w kopii roboczej i sa usuwane przed     ;;
;;      zapisem wynikowego DWG/PDF.                                  ;;
;;    - panel pokazuje osobny etap tworzenia ramek.                  ;;
;;                                                                  ;;

;;  Poprawka v3.37-brics:                                            ;;
;;    - osierocone VPO_LINK do skasowanych ramek sa traktowane jak   ;;
;;      brak ramek i naprawiane w kopii roboczej.                    ;;
;;    - istniejace, lecz uszkodzone ramki nadal zatrzymuja zadanie.  ;;
;;                                                                  ;;
;;  Poprawka v3.38-brics:                                            ;;
;;    - opcje zakresu LCLIP sa po angielsku: Current/Select/All.      ;;
;;    - jednoznaczne skroty klawiaturowe: C, S oraz A.                ;;
;;                                                                  ;;
;;  Poprawka v3.39-brics:                                            ;;
;;    - walidator instalacji korzysta z nazwy aktualnego pakietu.    ;;
;;    - LCLIP nie odrzuca poprawnie zaladowanego pliku v3.39.        ;;
;;                                                                  ;;
;;  Baza: v3.0 potwierdzona jako dzialajaca.                         ;;
;;==================================================================;;

(vl-load-com)

;;------------------------------------------------------------------;;
;;  Stale                                                           ;;
;;------------------------------------------------------------------;;
(setq vclip:xapp     "VPO_LINK"
      vclip:tapp     "VPO_TEXT"
      vclip:auto-frame-records-v339 nil
      vclip:auto-frame-debug-v339 nil
      vclip:nplt-lay "VPO-NPLT"
      vclip:always-keep-layer-v34 "_Podzia? na odcinki"
      vclip:ignore-layers-text-v324 vclip:always-keep-layer-v34
      vclip:ignore-layer-patterns-v324 (list vclip:always-keep-layer-v34)
      vclip:ignore-pattern-joined-v325 (strcase vclip:always-keep-layer-v34)
      vclip:xref-name-cache-v325 nil
      vclip:acad-trace-v35 T
      vclip:acad-plot-pdf-v36 T
      vclip:acad-close-copy-v36 nil
)

(defun vclip:split-layer-patterns-v324 ( text / pos item out )
    (setq text (if text text "") out nil)
    (while (setq pos (vl-string-search ";" text))
        (setq item (vclip:trim-v34 (substr text 1 pos))
              text (substr text (+ pos 2)))
        (if (/= item "") (setq out (cons item out))))
    (setq item (vclip:trim-v34 text))
    (if (/= item "") (setq out (cons item out)))
    (reverse out)
)

(defun vclip:set-ignore-layers-v324 ( text / pattern )
    (setq vclip:ignore-layers-text-v324
              (if text (vclip:trim-v34 text) "")
          vclip:ignore-layer-patterns-v324
              (vclip:split-layer-patterns-v324
                  vclip:ignore-layers-text-v324)
          vclip:ignore-pattern-joined-v325 "")
    (foreach pattern vclip:ignore-layer-patterns-v324
        (setq vclip:ignore-pattern-joined-v325
            (strcat vclip:ignore-pattern-joined-v325
                (if (= vclip:ignore-pattern-joined-v325 "") "" ",")
                (strcase pattern))))
    vclip:ignore-layer-patterns-v324
)

(defun vclip:ignored-layer-p-v324 ( layer )
    (and layer
         (/= vclip:ignore-pattern-joined-v325 "")
         (wcmatch (strcase layer) vclip:ignore-pattern-joined-v325))
)

(defun vclip:add-model-handles-on-ignored-layers-v324
       ( handles / doc ms obj ent enx lay )
    (setq doc (LM:acdoc) ms (vla-get-ModelSpace doc))
    (vlax-for obj ms
        (setq ent (vclip:vla-object->ename-safe obj))
        (if ent
            (progn
                (setq enx (entget ent) lay (cdr (assoc 8 enx)))
                (if (vclip:ignored-layer-p-v324 lay)
                    (setq handles (vclip:add-handle-v30 ent handles))))))
    handles
)
;;------------------------------------------------------------------;;
;;  Podstawowe helpery                                              ;;
;;------------------------------------------------------------------;;
(defun LM:acdoc nil
    ;; v3.2: zawsze zwracaj aktualnie aktywny dokument.
    ;; Poprzednia wersja Lee Mac cache'owala pierwszy dokument i przy
    ;; VPOEXPORT po otwarciu kopii nadal wskazywala plik zrodlowy.
    (vla-get-ActiveDocument (vlax-get-acad-object))
)

(defun LM:startundo ( doc )
    (LM:endundo doc)
    (vla-startundomark doc)
)

(defun LM:endundo ( doc )
    (while (= 8 (logand 8 (getvar 'undoctl)))
        (vla-endundomark doc)
    )
)


(defun vclip:getvar-safe-v35 ( name default / r )
    (setq r (vl-catch-all-apply 'getvar (list name)))
    (if (vl-catch-all-error-p r) default r)
)
(defun vclip:timestamp ( / s )
    ;; CDATE np. 20260610.204512 -> 20260610_204512
    (setq s (rtos (getvar 'cdate) 2 6))
    (vl-string-translate "." "_" s)
)

(defun vclip:safe-delete-entity ( ent )
    (if ent
        (not
            (vl-catch-all-error-p
                (vl-catch-all-apply 'entdel (list ent))
            )
        )
    )
)

(defun vclip:safe-vla-delete ( obj )
    (if obj
        (not
            (vl-catch-all-error-p
                (vl-catch-all-apply 'vla-delete (list obj))
            )
        )
    )
)

(defun vclip:member-ename-p ( ent lst )
    ;; member dla ename zwykle dziala, ale porownanie handle jest pewniejsze
    (if ent
        (member ent lst)
    )
)

;;------------------------------------------------------------------;;
;;  Odczyt XData VPO                                                ;;
;;------------------------------------------------------------------;;
(defun vclip:getappvalue ( ent app / itm rec )
    (if (and ent app
             (setq itm (assoc -3 (entget ent (list app)))))
        (progn
            (setq rec (cadr itm))
            (cdr (assoc 1000 (cdr rec)))
        )
    )
)

(defun vclip:getlink ( ent )
    (vclip:getappvalue ent vclip:xapp)
)

(defun vclip:linked-entity ( ent / h )
    (if (setq h (vclip:getlink ent))
        (handent h)
    )
)

;;------------------------------------------------------------------;;
;;  Wierzcholki polilinii w WCS                                     ;;
;;------------------------------------------------------------------;;
(defun vclip:polyvertices ( ent )
    (apply 'append
        (mapcar
            '(lambda ( pair )
                (if (= 10 (car pair)) (list (cdr pair)) nil))
            (entget ent)))
)

(defun vclip:polyvertices-wcs ( ent / enx ocs pts )
    (setq enx (entget ent)
          ocs (cdr (assoc 210 enx)))
    (if (null ocs) (setq ocs '(0.0 0.0 1.0)))
    (mapcar '(lambda (p) (trans p ocs 0))
            (vclip:polyvertices ent))
)

;;------------------------------------------------------------------;;
;;  Geometria 2D ramek                                              ;;
;;------------------------------------------------------------------;;
(defun vclip:rect-local ( pts / p0 p1 p3 dx dy len ux uy w h )
    ;; Zwraca (p0 ux uy width height) dla prostokatnej ramki VPO.
    ;; Dziala dla ramek obroconych.
    (if (and pts (>= (length pts) 4))
        (progn
            (setq p0  (list (car (nth 0 pts)) (cadr (nth 0 pts)))
                  p1  (list (car (nth 1 pts)) (cadr (nth 1 pts)))
                  p3  (list (car (nth 3 pts)) (cadr (nth 3 pts)))
                  dx  (- (car p1) (car p0))
                  dy  (- (cadr p1) (cadr p0))
                  len (sqrt (+ (* dx dx) (* dy dy))))
            (if (> len 1e-10)
                (progn
                    (setq ux (list (/ dx len) (/ dy len))
                          uy (list (- (cadr ux)) (car ux))
                          w  len
                          h  (+ (* (- (car p3) (car p0)) (car uy))
                                (* (- (cadr p3) (cadr p0)) (cadr uy))))
                    ;; P3 moze lezec po prawej stronie P0->P1, gdy
                    ;; polilinia ma kierunek zgodny z ruchem wskazowek.
                    ;; Odwroc wtedy os lokalna zamiast odbijac prostokat.
                    (if (< h 0.0)
                        (setq uy (list (- (car uy)) (- (cadr uy)))
                              h  (- h)))
                    (if (> h 1e-10)
                        (list p0 ux uy w h))
                )
            )
        )
    )
)

(defun vclip:to-local ( px py p0 ux uy )
    (list (+ (* (- px (car p0)) (car  ux)) (* (- py (cadr p0)) (cadr ux)))
          (+ (* (- px (car p0)) (car  uy)) (* (- py (cadr p0)) (cadr uy))))
)

(defun vclip:rect-inside-p ( px py rect / lc lx ly )
    (if (and rect (numberp px) (numberp py))
        (progn
            (setq lc (vclip:to-local px py
                         (car rect) (cadr rect) (caddr rect))
                  lx (car lc)
                  ly (cadr lc))
            (and (>= lx -1e-6) (<= lx (+ (cadddr rect) 1e-6))
                 (>= ly -1e-6) (<= ly (+ (car (cddddr rect)) 1e-6)))
        )
    )
)

(defun vclip:number-list-p ( lst )
    (and (listp lst)
         (vl-every '(lambda (x) (numberp x)) lst))
)

(defun vclip:valid-point-p ( pt )
    ;; Poprawny punkt 2D/3D: lista, min. 2 wspolrzedne liczbowe.
    ;; W BricsCAD przy nietypowych obiektach punkt reprezentatywny potrafi
    ;; wrocic jako NIL/T albo inny atom - nie wolno wtedy robic (car pt).
    (and (listp pt)
         (>= (length pt) 2)
         (numberp (car pt))
         (numberp (cadr pt)))
)

(defun vclip:valid-bbox-p ( bbox )
    ;; Poprawny bbox ma postac (xmin ymin xmax ymax).
    ;; W BricsCAD przy niektorych obiektach potrafi wrocic NIL/T/blad,
    ;; dlatego wszystko sprawdzamy przed uzyciem CAR/CADR/CADDR.
    (and (vclip:number-list-p bbox)
         (>= (length bbox) 4)
         (<= (car bbox) (caddr bbox))
         (<= (cadr bbox) (cadddr bbox)))
)

(defun vclip:bbox-poly ( bbox )
    (if (vclip:valid-bbox-p bbox)
        (list
            (list (car bbox)   (cadr bbox))
            (list (caddr bbox) (cadr bbox))
            (list (caddr bbox) (cadddr bbox))
            (list (car bbox)   (cadddr bbox))
        )
    )
)

(defun vclip:pt-in-bbox-p ( p bbox )
    (and (vclip:valid-point-p p)
         (vclip:valid-bbox-p bbox)
         (>= (car p)   (- (car bbox) 1e-6))
         (<= (car p)   (+ (caddr bbox) 1e-6))
         (>= (cadr p)  (- (cadr bbox) 1e-6))
         (<= (cadr p)  (+ (cadddr bbox) 1e-6)))
)

(defun vclip:cross2d ( a b c )
    ;; iloczyn wektorowy AB x AC
    (- (* (- (car b) (car a)) (- (cadr c) (cadr a)))
       (* (- (cadr b) (cadr a)) (- (car c) (car a))))
)

(defun vclip:on-segment-p ( a b c )
    ;; czy punkt C lezy na odcinku AB
    (and (<= (abs (vclip:cross2d a b c)) 1e-8)
         (>= (car c)  (- (min (car a) (car b)) 1e-8))
         (<= (car c)  (+ (max (car a) (car b)) 1e-8))
         (>= (cadr c) (- (min (cadr a) (cadr b)) 1e-8))
         (<= (cadr c) (+ (max (cadr a) (cadr b)) 1e-8)))
)

(defun vclip:segments-intersect-p ( p1 p2 q1 q2 / d1 d2 d3 d4 )
    (setq d1 (vclip:cross2d p1 p2 q1)
          d2 (vclip:cross2d p1 p2 q2)
          d3 (vclip:cross2d q1 q2 p1)
          d4 (vclip:cross2d q1 q2 p2))
    (or
        (and (<= (* d1 d2) 0.0) (<= (* d3 d4) 0.0)
             ;; dla przypadkow wspolliniowych sprawdzamy zakresy
             (or (> (abs d1) 1e-8) (vclip:on-segment-p p1 p2 q1))
             (or (> (abs d2) 1e-8) (vclip:on-segment-p p1 p2 q2))
             (or (> (abs d3) 1e-8) (vclip:on-segment-p q1 q2 p1))
             (or (> (abs d4) 1e-8) (vclip:on-segment-p q1 q2 p2)))
        (vclip:on-segment-p p1 p2 q1)
        (vclip:on-segment-p p1 p2 q2)
        (vclip:on-segment-p q1 q2 p1)
        (vclip:on-segment-p q1 q2 p2)
    )
)

(defun vclip:poly-edges ( pts / res i n )
    (setq res nil
          i   0
          n   (length pts))
    (while (< i n)
        (setq res (cons (list (nth i pts) (nth (rem (1+ i) n) pts)) res)
              i   (1+ i))
    )
    res
)

(defun vclip:bbox-intersects-frame-p ( bbox frame / rect fpts bpts hit be fe )
    ;; frame = (ent pts rect)
    ;; Test pelniejszy niz same rogi bbox: rogi bbox w ramce, rogi ramki w bbox,
    ;; oraz przeciecia krawedzi.
    (if (not (vclip:valid-bbox-p bbox))
        t ; nieznany/niepoprawny obrys - dla bezpieczenstwa zostaw
        (progn
            (setq fpts (cadr frame)
                  rect (caddr frame)
                  bpts (vclip:bbox-poly bbox)
                  hit  nil)

            (if (and fpts rect bpts)
                (progn
                    ;; 1. Rogi bbox w ramce
                    (foreach p bpts
                        (if (and (not hit) (vclip:rect-inside-p (car p) (cadr p) rect))
                            (setq hit t)))

                    ;; 2. Rogi ramki w bbox
                    (foreach p fpts
                        (if (and (not hit) (vclip:pt-in-bbox-p p bbox))
                            (setq hit t)))

                    ;; 3. Przeciecia krawedzi bbox i ramki
                    (if (not hit)
                        (foreach be (vclip:poly-edges bpts)
                            (foreach fe (vclip:poly-edges fpts)
                                (if (and (not hit)
                                         (vclip:segments-intersect-p (car be) (cadr be) (car fe) (cadr fe)))
                                    (setq hit t)
                                )
                            )
                        )
                    )
                    hit
                )
                t ; uszkodzony opis ramki - bezpieczniej nie kasowac
            )
        )
    )
)

(defun vclip:bbox-intersects-any-frame-p ( bbox frames )
    (if (not (vclip:valid-bbox-p bbox))
        t ; dla bezpieczenstwa zostaw obiekty bez poprawnego obrysu
        (vl-some
            '(lambda (frame) (vclip:bbox-intersects-frame-p bbox frame))
            frames
        )
    )
)

;;------------------------------------------------------------------;;
;;  Obrys obiektu                                                   ;;
;;------------------------------------------------------------------;;
(defun vclip:variant->list ( v )
    (cond
        ((= (type v) 'variant)   (vlax-safearray->list (vlax-variant-value v)))
        ((= (type v) 'safearray) (vlax-safearray->list v))
        (t nil)
    )
)

(defun vclip:vla-bbox ( ent / obj minpt maxpt pmin pmax x1 y1 x2 y2 res )
    (setq obj (vlax-ename->vla-object ent))
    (if (not
            (vl-catch-all-error-p
                (vl-catch-all-apply 'vla-GetBoundingBox (list obj 'minpt 'maxpt))
            )
        )
        (progn
            (setq pmin (vclip:variant->list minpt)
                  pmax (vclip:variant->list maxpt))
            (if (and (vclip:number-list-p pmin)
                     (vclip:number-list-p pmax)
                     (>= (length pmin) 2)
                     (>= (length pmax) 2))
                (progn
                    (setq x1 (car pmin)  y1 (cadr pmin)
                          x2 (car pmax)  y2 (cadr pmax))
                    (setq res (list (min x1 x2) (min y1 y2) (max x1 x2) (max y1 y2)))
                )
            )
        )
    )
    (if (vclip:valid-bbox-p res) res nil)
)

(defun vclip:bbox ( ent / box enx typ pts xs ys p10 p11 )
    ;; AutoLISP OR returns T, not the successful operand. Keep the actual
    ;; bounding-box list so callers can use it for fast spatial filtering.
    (if (setq box (vclip:vla-bbox ent))
        box
        (progn
            (setq enx (entget ent)
                  typ (cdr (assoc 0 enx)))
            (cond
                ((= typ "LINE")
                 (setq p10 (cdr (assoc 10 enx))
                       p11 (cdr (assoc 11 enx)))
                 (if (and p10 p11)
                     (list (min (car p10) (car p11))
                           (min (cadr p10) (cadr p11))
                           (max (car p10) (car p11))
                           (max (cadr p10) (cadr p11)))))

                ((and typ (wcmatch typ "*POLYLINE"))
                 (setq pts (vclip:polyvertices-wcs ent))
                 (if pts
                     (progn
                         (setq xs (mapcar 'car pts)
                               ys (mapcar 'cadr pts))
                         (list (apply 'min xs) (apply 'min ys)
                               (apply 'max xs) (apply 'max ys)))))

                (T nil)
            )
        )
    )
)

;;------------------------------------------------------------------;;
;;  Sprawdzenie istnienia layoutu                                   ;;
;;------------------------------------------------------------------;;
(defun vclip:layout-exists-p ( lay / ok layouts obj )
    (setq ok nil
          layouts (vla-get-layouts (LM:acdoc)))
    (vlax-for obj layouts
        (if (= (strcase (vla-get-name obj)) (strcase lay))
            (setq ok t)
        )
    )
    ok
)

;;------------------------------------------------------------------;;
;;  Wybierz rzutnie lub ramke VPO i zwroc: (vpe phe lay)            ;;
;;------------------------------------------------------------------;;
(defun vclip:get-picked-vpo-pair ( / ent enx typ vpe phe lay )
    (setq ent (car (entsel "\nWskaz rzutnie albo ramke VPO: ")))
    (if ent
        (progn
            (setq enx (entget ent)
                  typ (cdr (assoc 0 enx)))
            (cond
                ((= typ "VIEWPORT")
                 (setq vpe ent
                       phe (vclip:linked-entity vpe)))
                ((and typ (wcmatch typ "*POLYLINE"))
                 (setq phe ent
                       vpe (vclip:linked-entity phe)))
                (t nil)
            )
            (if (and vpe (= "VIEWPORT" (cdr (assoc 0 (entget vpe)))))
                (progn
                    (setq lay (cdr (assoc 410 (entget vpe))))
                    (list vpe phe lay)
                )
            )
        )
    )
)

;;------------------------------------------------------------------;;
;;  Zbierz ramki VPO nalezace do layoutu                            ;;
;;  Zwraca liste rekordow: (frame-ent points rect)                  ;;
;;------------------------------------------------------------------;;
(defun vclip:frame-record-from-entity ( ent / pts rect enx )
    (if ent
        (progn
            (setq enx (entget ent))
            (if (and enx
                     (wcmatch (cdr (assoc 0 enx)) "*POLYLINE")
                     (= "MODEL" (strcase (cdr (assoc 410 enx)))))
                (progn
                    (setq pts (vclip:polyvertices-wcs ent))
                    (if (and pts (= 4 (length pts)))
                        (progn
                            (setq rect (vclip:rect-local pts))
                            (if rect (list ent pts rect))
                        )
                    )
                )
            )
        )
    )
)

(defun vclip:ename-list-contains-p ( ent lst / hit )
    (setq hit nil)
    (foreach e lst
        (if (= e ent) (setq hit t))
    )
    hit
)

(defun vclip:collect-frames-for-layout ( lay / sel i vpe phe rec out used )
    ;; Najpewniejsza metoda:
    ;; 1. znajdz rzutnie w wybranym layoucie,
    ;; 2. z kazdej rzutni odczytaj jej sparowana ramke VPO w Modelu,
    ;; 3. tylko te ramki trafiaja do listy zostajacej.
    ;;
    ;; Dzieki temu ramki z innych layoutow nie wejda do zakresu czyszczenia,
    ;; nawet jesli ich obrysy nachodza na ramki wybranego layoutu.
    (setq out  nil
          used nil)
    (setq sel
        (ssget "_X"
            (list
                '(0 . "VIEWPORT")
                (cons 410 lay)
            )
        )
    )
    (if sel
        (progn
            (setq i 0)
            (while (< i (sslength sel))
                (setq vpe (ssname sel i)
                      i   (1+ i)
                      phe (vclip:linked-entity vpe))
                (if (and phe (not (vclip:ename-list-contains-p phe used)))
                    (progn
                        (setq rec (vclip:frame-record-from-entity phe))
                        (if rec
                            (progn
                                (setq out  (cons rec out))
                                (setq used (cons phe used))
                            )
                        )
                    )
                )
            )
        )
    )
    out
)

;;------------------------------------------------------------------;;
;;  Etykiety ramek VPO                                              ;;
;;------------------------------------------------------------------;;
(defun vclip:collect-keep-ents ( frames / keep frame txt )
    ;; Zostawiamy ramki oraz ich etykiety zapisane w XData VPO_TEXT.
    (setq keep nil)
    (foreach frame frames
        (setq keep (cons (car frame) keep))
        (setq txt (vclip:getappvalue (car frame) vclip:tapp))
        (if (and txt (setq txt (handent txt)))
            (setq keep (cons txt keep))
        )
    )
    keep
)

;;------------------------------------------------------------------;;
;;  Usun ramki i etykiety VPO nie nalezace do wybranego layoutu     ;;
;;------------------------------------------------------------------;;
(defun vclip:delete-other-vpo-frames-and-labels ( keep-ents / sel i ent txt to-del cnt )
    ;; To jest wazne: ramek VPO innych layoutow nie zostawiamy nawet wtedy,
    ;; gdy geometrycznie leza w obszarze ramek wybranego layoutu.
    (setq sel    (ssget "_X"
                    (list
                        '(0 . "LWPOLYLINE")
                        '(410 . "Model")
                        (cons 8 vclip:nplt-lay)
                    )
                 )
          i      0
          to-del nil
          cnt    0)

    (if sel
        (progn
            (while (< i (sslength sel))
                (setq ent (ssname sel i)
                      i   (1+ i))
                (if (not (vclip:member-ename-p ent keep-ents))
                    (progn
                        ;; etykieta zapisana jako handle w XData VPO_TEXT na ramce
                        (setq txt (vclip:getappvalue ent vclip:tapp))
                        (if (and txt (setq txt (handent txt)))
                            (setq to-del (cons txt to-del))
                        )
                        (setq to-del (cons ent to-del))
                    )
                )
            )

            (foreach ent to-del
                (if (vclip:safe-delete-entity ent)
                    (setq cnt (1+ cnt))
                )
            )
        )
    )
    cnt
)

;;------------------------------------------------------------------;;
;;  Odblokuj warstwy, zapamietajac stan                             ;;
;;------------------------------------------------------------------;;
(defun vclip:unlock-all-layers ( / states lay )
    (setq states nil)
    (vlax-for lay (vla-get-layers (LM:acdoc))
        (setq states (cons (cons lay (vla-get-lock lay)) states))
        (if (= :vlax-true (vla-get-lock lay))
            (vl-catch-all-apply 'vla-put-lock (list lay :vlax-false))
        )
    )
    states
)

(defun vclip:restore-layer-locks ( states / rec )
    (foreach rec states
        (vl-catch-all-apply 'vla-put-lock (list (car rec) (cdr rec)))
    )
)

;;------------------------------------------------------------------;;
;;  Usun wszystkie layouty poza wskazanym                           ;;
;;------------------------------------------------------------------;;
(defun vclip:delete-layouts-except ( keep-lay / layouts lay name cnt )
    (setq layouts (vla-get-layouts (LM:acdoc))
          cnt     0)

    ;; Nie da sie skasowac aktywnego layoutu, wiec aktywujemy docelowy.
    (if (and keep-lay
             (/= (strcase keep-lay) "MODEL")
             (vclip:layout-exists-p keep-lay))
        (setvar 'ctab keep-lay)
    )

    (vlax-for lay layouts
        (setq name (vla-get-name lay))
        (if (and (/= (strcase name) "MODEL")
                 (/= (strcase name) (strcase keep-lay)))
            (if (vclip:safe-vla-delete lay)
                (setq cnt (1+ cnt))
            )
        )
    )
    cnt
)

;;------------------------------------------------------------------;;
;;  Usun z Modelu wszystko poza obszarami ramek VPO                 ;;
;;------------------------------------------------------------------;;
(defun vclip:vla-object->ename-safe ( obj / r )
    (setq r (vl-catch-all-apply 'vlax-vla-object->ename (list obj)))
    (if (not (vl-catch-all-error-p r)) r nil)
)

(defun vclip:delete-model-outside-frames
       ( frames keep-ents / doc ms obj ent enx typ bbox to-del cnt checked no-bbox keep-tech )
    ;; v2.7:
    ;; Nie korzystamy z (ssget "_X" '((410 . "Model"))), bo w BricsCAD
    ;; potrafi to nie zebrac calego Modelu albo nie zebrac nic w niektorych
    ;; sytuacjach. Przechodzimy bezposrednio po kolekcji ModelSpace.
    (setq doc       (LM:acdoc)
          ms        (vla-get-ModelSpace doc)
          to-del    nil
          cnt       0
          checked   0
          no-bbox   0
          keep-tech 0)

    (vlax-for obj ms
        (setq ent (vclip:vla-object->ename-safe obj))
        (if ent
            (progn
                (setq enx (entget ent)
                      typ (cdr (assoc 0 enx))
                      checked (1+ checked))
                (cond
                    ;; ramki VPO wybranego layoutu + etykiety ramek
                    ((vclip:member-ename-p ent keep-ents)
                     (setq keep-tech (1+ keep-tech))
                    )

                    ;; technicznie bezpieczniej nie ruszac viewportow systemowych
                    ((= typ "VIEWPORT")
                     (setq keep-tech (1+ keep-tech))
                    )

                    ;; Obiekty bez obrysu zostawiamy, ale zliczamy je diagnostycznie.
                    ;; Przy normalnej geometrii powinno byc ich malo.
                    ((not (setq bbox (vclip:bbox ent)))
                     (setq no-bbox (1+ no-bbox))
                    )

                    ;; Zostaw obiekty, ktore leza w ramce albo przecinaja ramke.
                    ;; Kasuj tylko te, ktore sa calkowicie poza ramkami wybranego layoutu.
                    ((not (vclip:bbox-intersects-any-frame-p bbox frames))
                     (setq to-del (cons ent to-del))
                    )
                )
            )
        )
    )

    (foreach ent to-del
        (if (vclip:safe-delete-entity ent)
            (setq cnt (1+ cnt))
        )
    )

    ;; Zwracamy liste diagnostyczna: (usuniete sprawdzone do_usuniecia bez_obrysu techniczne)
    (list cnt checked (length to-del) no-bbox keep-tech)
)



;;------------------------------------------------------------------;;
;;  Dodatkowa geometria i czyszczenie v2.9                          ;;
;;------------------------------------------------------------------;;
(defun vclip:frame-rect ( frame )
    ;; frame w v2.6+ ma postac: (ent pts rect)
    (caddr frame)
)

(defun vclip:point-inside-any-frame-p ( pt frames / hit )
    (setq hit nil)
    (if (vclip:valid-point-p pt)
        (foreach frame frames
            (if (and (not hit)
                     (vclip:rect-inside-p (car pt) (cadr pt) (vclip:frame-rect frame)))
                (setq hit t)
            )
        )
    )
    hit
)

(defun vclip:bbox-fully-inside-frame-p ( bbox frame / rect bpts ok )
    (setq rect (vclip:frame-rect frame)
          bpts (vclip:bbox-poly bbox)
          ok   nil)
    (if (and rect bpts)
        (progn
            (setq ok t)
            (foreach p bpts
                (if (not (vclip:rect-inside-p (car p) (cadr p) rect))
                    (setq ok nil)
                )
            )
        )
    )
    ok
)

(defun vclip:bbox-fully-inside-any-frame-p ( bbox frames / hit )
    (setq hit nil)
    (if (vclip:valid-bbox-p bbox)
        (foreach frame frames
            (if (and (not hit) (vclip:bbox-fully-inside-frame-p bbox frame))
                (setq hit t)
            )
        )
    )
    hit
)

(defun vclip:entity-point ( ent / enx typ pt )
    ;; Punkt reprezentatywny dla obiektow opisowych.
    ;; Przy tekstach/wymiarach bbox bywa szeroki i moze dotykac ramki,
    ;; ale sam opis jest poza ramka - wtedy decyduje punkt wstawienia.
    ;; Zwracamy tylko poprawna liste punktu. NIL/T/inne atomy sa ignorowane.
    (setq enx (entget ent)
          typ (cdr (assoc 0 enx)))
    (setq pt
        (cond
            ((and typ (wcmatch typ "TEXT,MTEXT,ATTRIB,ATTDEF,POINT,INSERT"))
             (cdr (assoc 10 enx)))
            ((and typ (wcmatch typ "DIMENSION,LEADER,MULTILEADER"))
             (or (cdr (assoc 10 enx)) (cdr (assoc 11 enx))))
            (t nil)
        )
    )
    (if (vclip:valid-point-p pt) pt nil)
)

(defun vclip:model-ents-list ( / doc ms obj ent out )
    (setq doc (LM:acdoc)
          ms  (vla-get-ModelSpace doc)
          out nil)
    (vlax-for obj ms
        (setq ent (vclip:vla-object->ename-safe obj))
        (if ent (setq out (cons ent out)))
    )
    out
)

(defun vclip:delete-model-outside-frames-v29
       ( frames keep-ents / ent enx typ bbox pt to-del cnt checked no-bbox keep-tech textpt )
    ;; Mocniejsze czyszczenie niz v2.7:
    ;; - teksty/wymiary/atrybuty kasuje po punkcie wstawienia,
    ;; - reszte kasuje gdy bbox nie przecina ramek,
    ;; - obiekty bez bbox nadal zostawia, ale raportuje.
    (setq to-del    nil
          cnt       0
          checked   0
          no-bbox   0
          keep-tech 0
          textpt    0)

    (foreach ent (vclip:model-ents-list)
        (setq enx (entget ent (list vclip:xapp vclip:tapp))
              typ (cdr (assoc 0 enx))
              checked (1+ checked))
        (cond
            ((vclip:member-ename-p ent keep-ents)
             (setq keep-tech (1+ keep-tech)))

            ((= typ "VIEWPORT")
             (setq keep-tech (1+ keep-tech)))

            ;; Obiekty opisowe: decyduje punkt wstawienia/opisu.
            ((and (and typ (wcmatch typ "TEXT,MTEXT,ATTRIB,ATTDEF,DIMENSION,LEADER,MULTILEADER,POINT"))
                  (setq pt (vclip:entity-point ent))
                  (not (vclip:point-inside-any-frame-p pt frames)))
             (setq to-del (cons ent to-del)
                   textpt (1+ textpt)))

            ((not (setq bbox (vclip:bbox ent)))
             (setq no-bbox (1+ no-bbox)))

            ((not (vclip:bbox-intersects-any-frame-p bbox frames))
             (setq to-del (cons ent to-del)))
        )
    )

    (foreach ent to-del
        (if (vclip:safe-delete-entity ent)
            (setq cnt (1+ cnt))
        )
    )

    ;; (usuniete sprawdzone do_usuniecia bez_obrysu techniczne tekst_po_punkcie)
    (list cnt checked (length to-del) no-bbox keep-tech textpt)
)

(defun vclip:distance2d ( a b )
    (if (and (vclip:valid-point-p a) (vclip:valid-point-p b))
        (sqrt (+ (expt (- (car a) (car b)) 2.0)
                 (expt (- (cadr a) (cadr b)) 2.0)))
        0.0
    )
)

(defun vclip:cliptest-lb ( p q res / ok t0 t1 r )
    ;; Pomocnicza funkcja Liang-Barsky. Zwraca (ok t0 t1).
    (setq ok (car res)
          t0 (cadr res)
          t1 (caddr res))
    (if (not ok)
        res
        (cond
            ((equal p 0.0 1e-12)
             (if (< q 0.0) (list nil t0 t1) res))
            (t
             (setq r (/ q p))
             (cond
                 ((< p 0.0)
                  (cond
                      ((> r t1) (list nil t0 t1))
                      ((> r t0) (list t r t1))
                      (t res)))
                 ((> p 0.0)
                  (cond
                      ((< r t0) (list nil t0 t1))
                      ((< r t1) (list t t0 r))
                      (t res)))
                 (t res)
             )
            )
        )
    )
)

(defun vclip:clip-segment-to-rect ( p1 p2 rect / l1 l2 x0 y0 x1 y1 dx dy res t0 t1 q1 q2 )
    ;; Zwraca ((x y z) (x y z)) albo NIL.
    ;; Przycinanie w lokalnym układzie ramki, wiec dziala dla ramek obroconych.
    (if (and (vclip:valid-point-p p1)
             (vclip:valid-point-p p2)
             rect)
        (progn
            (setq l1 (vclip:to-local (car p1) (cadr p1) (car rect) (cadr rect) (caddr rect))
                  l2 (vclip:to-local (car p2) (cadr p2) (car rect) (cadr rect) (caddr rect))
                  x0 (car l1) y0 (cadr l1)
                  x1 (car l2) y1 (cadr l2)
                  dx (- x1 x0)
                  dy (- y1 y0)
                  res (list t 0.0 1.0))

            ;; x >= 0, x <= width, y >= 0, y <= height
            (setq res (vclip:cliptest-lb (- dx) x0 res))
            (setq res (vclip:cliptest-lb dx (- (cadddr rect) x0) res))
            (setq res (vclip:cliptest-lb (- dy) y0 res))
            (setq res (vclip:cliptest-lb dy (- (car (cddddr rect)) y0) res))

            (if (car res)
                (progn
                    (setq t0 (cadr res)
                          t1 (caddr res))
                    (if (<= (- t1 t0) 1e-10)
                        nil
                        (progn
                            (setq q1 (list (+ (car p1) (* t0 (- (car p2) (car p1))))
                                           (+ (cadr p1) (* t0 (- (cadr p2) (cadr p1))))
                                           (if (and (listp p1) (caddr p1)) (caddr p1) 0.0))
                                  q2 (list (+ (car p1) (* t1 (- (car p2) (car p1))))
                                           (+ (cadr p1) (* t1 (- (cadr p2) (cadr p1))))
                                           (if (and (listp p2) (caddr p2)) (caddr p2) 0.0)))
                            (if (> (vclip:distance2d q1 q2) 1e-8)
                                (list q1 q2)
                                nil
                            )
                        )
                    )
                )
            )
        )
    )
)

(defun vclip:make-line-like ( src p1 p2 / enx lay col lt lts lw norm data )
    ;; Tworzy nowa linie z podstawowymi parametrami z obiektu zrodlowego.
    (setq enx  (entget src)
          lay  (cdr (assoc 8 enx))
          col  (assoc 62 enx)
          lt   (assoc 6 enx)
          lts  (assoc 48 enx)
          lw   (assoc 370 enx)
          norm (assoc 210 enx)
          data (list '(0 . "LINE")
                     (cons 8 (if lay lay "0"))
                     (cons 10 p1)
                     (cons 11 p2)))
    (if col  (setq data (append data (list col))))
    (if lt   (setq data (append data (list lt))))
    (if lts  (setq data (append data (list lts))))
    (if lw   (setq data (append data (list lw))))
    (if norm (setq data (append data (list norm))))
    (entmakex data)
)

(defun vclip:line-inside-any-frame-p ( p1 p2 frames / hit rect )
    (setq hit nil)
    (if (and (vclip:valid-point-p p1) (vclip:valid-point-p p2))
        (foreach frame frames
            (if (not hit)
                (progn
                    (setq rect (vclip:frame-rect frame))
                    (if (and (vclip:rect-inside-p (car p1) (cadr p1) rect)
                             (vclip:rect-inside-p (car p2) (cadr p2) rect))
                        (setq hit t)
                    )
                )
            )
        )
    )
    hit
)

(defun vclip:clip-line-to-frames-v29 ( ent frames / enx p1 p2 seg created )
    (setq enx (entget ent)
          p1  (cdr (assoc 10 enx))
          p2  (cdr (assoc 11 enx))
          created 0)
    (if (and (vclip:valid-point-p p1) (vclip:valid-point-p p2))
        (if (vclip:line-inside-any-frame-p p1 p2 frames)
            0 ; zostaje bez zmian
            (progn
                (foreach frame frames
                    (setq seg (vclip:clip-segment-to-rect p1 p2 (vclip:frame-rect frame)))
                    (if seg
                        (if (vclip:make-line-like ent (car seg) (cadr seg))
                            (setq created (1+ created))
                        )
                    )
                )
                (vclip:safe-delete-entity ent)
                created
            )
        )
        0
    )
)

(defun vclip:lwpoly-closed-p ( ent / f )
    (setq f (cdr (assoc 70 (entget ent))))
    (and f (= 1 (logand 1 f)))
)

(defun vclip:clip-lwpoly-to-frames-v29 ( ent frames / pts pts2 i p1 p2 seg created )
    ;; LWPOLYLINE przecinajace ramke rozkladamy na przyciete segmenty LINE.
    ;; To jest celowo agresywne: po operacji nie zostaja odcinki poza ramkami.
    (setq pts (vclip:polyvertices-wcs ent)
          created 0)
    (if (and pts (> (length pts) 1))
        (progn
            (setq pts2 pts)
            (if (vclip:lwpoly-closed-p ent)
                (setq pts2 (append pts2 (list (car pts2))))
            )
            (setq i 0)
            (while (< i (1- (length pts2)))
                (setq p1 (nth i pts2)
                      p2 (nth (1+ i) pts2)
                      i  (1+ i))
                (foreach frame frames
                    (setq seg (vclip:clip-segment-to-rect p1 p2 (vclip:frame-rect frame)))
                    (if seg
                        (if (vclip:make-line-like ent (car seg) (cadr seg))
                            (setq created (1+ created))
                        )
                    )
                )
            )
            (vclip:safe-delete-entity ent)
        )
    )
    created
)

(defun vclip:clip-simple-crossing-v29 ( frames keep-ents / ent enx typ bbox created deleted skipped c )
    ;; Przytnij LINE i LWPOLYLINE, ktore przecinaja ramki, ale nie sa w calosci wewnatrz.
    ;; Ramki VPO i etykiety VPO sa pomijane.
    (setq created 0
          deleted 0
          skipped 0)
    (foreach ent (vclip:model-ents-list)
        (setq enx (entget ent (list vclip:xapp vclip:tapp))
              typ (cdr (assoc 0 enx)))
        (cond
            ((vclip:member-ename-p ent keep-ents) nil)
            ((= (cdr (assoc 8 enx)) vclip:nplt-lay) nil)
            ((assoc -3 enx) nil)
            ((not (and typ (wcmatch typ "LINE,LWPOLYLINE"))) nil)
            ((not (setq bbox (vclip:bbox ent)))
             (setq skipped (1+ skipped)))
            ((vclip:bbox-fully-inside-any-frame-p bbox frames) nil)
            ((vclip:bbox-intersects-any-frame-p bbox frames)
             (setq c (if (= typ "LINE")
                         (vclip:clip-line-to-frames-v29 ent frames)
                         (vclip:clip-lwpoly-to-frames-v29 ent frames)))
             (setq created (+ created c)
                   deleted (1+ deleted)))
        )
    )
    (list created deleted skipped)
)

(defun vclip:insert-xref-p ( ent / obj name blk res )
    (setq res nil)
    (if (and ent (= "INSERT" (cdr (assoc 0 (entget ent)))))
        (progn
            (setq obj (vlax-ename->vla-object ent))
            (setq name
                (cond
                    ((not (vl-catch-all-error-p
                              (setq name (vl-catch-all-apply 'vla-get-EffectiveName (list obj))))) name)
                    ((not (vl-catch-all-error-p
                              (setq name (vl-catch-all-apply 'vla-get-Name (list obj))))) name)
                    (t nil)
                )
            )
            (if name
                (progn
                    (setq blk (vl-catch-all-apply 'vla-Item (list (vla-get-Blocks (LM:acdoc)) name)))
                    (if (not (vl-catch-all-error-p blk))
                        (if (not (vl-catch-all-error-p
                                     (setq res (vl-catch-all-apply 'vla-get-IsXRef (list blk)))))
                            (= res :vlax-true)
                            nil
                        )
                    )
                )
            )
        )
    )
)

(defun vclip:explode-one-insert-v29 ( ent / obj r )
    (setq obj (vlax-ename->vla-object ent))
    (setq r (vl-catch-all-apply 'vla-Explode (list obj)))
    (if (vl-catch-all-error-p r)
        nil
        (progn
            (vclip:safe-delete-entity ent)
            t
        )
    )
)

(defun vclip:explode-crossing-blocks-v29 ( frames keep-ents / pass changed ent enx bbox exploded skipped-xref failed )
    ;; Rozbijamy tylko zwykle bloki, ktore przecinaja ramke i nie sa w calosci wewnatrz.
    ;; XREF-y pomijamy, bo nie da sie ich bezpiecznie czesciowo skasowac bez bindowania/wyciagania geometrii.
    (setq pass 0
          exploded 0
          skipped-xref 0
          failed 0
          changed t)
    (while (and changed (< pass 10))
        (setq pass (1+ pass)
              changed nil)
        (foreach ent (vclip:model-ents-list)
            (setq enx (entget ent (list vclip:xapp vclip:tapp)))
            (if (and (= "INSERT" (cdr (assoc 0 enx)))
                     (not (vclip:member-ename-p ent keep-ents))
                     (setq bbox (vclip:bbox ent))
                     (vclip:bbox-intersects-any-frame-p bbox frames)
                     (not (vclip:bbox-fully-inside-any-frame-p bbox frames)))
                (if (vclip:insert-xref-p ent)
                    (setq skipped-xref (1+ skipped-xref))
                    (if (vclip:explode-one-insert-v29 ent)
                        (setq exploded (1+ exploded)
                              changed t)
                        (setq failed (1+ failed))
                    )
                )
            )
        )
    )
    (list exploded skipped-xref failed)
)




(defun vclip:delete-complex-crossing-v29 ( frames keep-ents / ent enx typ bbox cnt xref no-bbox )
    ;; Agresywny krok porzadkujacy:
    ;; po rozbiciu blokow i przycieciu LINE/LWPOLYLINE usuwamy obiekty zlozone,
    ;; ktore nadal przecinaja ramke i nie sa w calosci w ramce.
    ;; Nie dotyczy XREF-ow - te tylko raportujemy.
    (setq cnt 0
          xref 0
          no-bbox 0)
    (foreach ent (vclip:model-ents-list)
        (setq enx (entget ent (list vclip:xapp vclip:tapp))
              typ (cdr (assoc 0 enx)))
        (cond
            ((vclip:member-ename-p ent keep-ents) nil)
            ((= (cdr (assoc 8 enx)) vclip:nplt-lay) nil)
            ((assoc -3 enx) nil)
            ((and typ (wcmatch typ "VIEWPORT,LINE,LWPOLYLINE")) nil)
            ((not (setq bbox (vclip:bbox ent)))
             (setq no-bbox (1+ no-bbox)))
            ((and (vclip:bbox-intersects-any-frame-p bbox frames)
                  (not (vclip:bbox-fully-inside-any-frame-p bbox frames)))
             (if (and (= typ "INSERT") (vclip:insert-xref-p ent))
                 (setq xref (1+ xref))
                 (if (vclip:safe-delete-entity ent)
                     (setq cnt (1+ cnt))
                 )
             )
            )
        )
    )
    (list cnt xref no-bbox)
)

(defun vclip:report-leftovers-v29 ( frames keep-ents / ent enx typ bbox no-bbox xref complex linepoly )
    ;; Raportuje obiekty, ktorych obrys nadal przecina ramke, ale nie jest w calosci w ramce.
    ;; To sa potencjalne obiekty, ktore moga wizualnie wystawac poza ramki.
    (setq no-bbox 0
          xref    0
          complex 0
          linepoly 0)
    (foreach ent (vclip:model-ents-list)
        (setq enx (entget ent (list vclip:xapp vclip:tapp))
              typ (cdr (assoc 0 enx)))
        (cond
            ((vclip:member-ename-p ent keep-ents) nil)
            ((= (cdr (assoc 8 enx)) vclip:nplt-lay) nil)
            ((assoc -3 enx) nil)
            ((not (setq bbox (vclip:bbox ent)))
             (setq no-bbox (1+ no-bbox)))
            ((and (vclip:bbox-intersects-any-frame-p bbox frames)
                  (not (vclip:bbox-fully-inside-any-frame-p bbox frames)))
             (cond
                 ((and (= typ "INSERT") (vclip:insert-xref-p ent))
                  (setq xref (1+ xref)))
                 ((and typ (wcmatch typ "LINE,LWPOLYLINE"))
                  (setq linepoly (1+ linepoly)))
                 (t
                  (setq complex (1+ complex)))
             )
            )
        )
    )
    (list xref complex linepoly no-bbox)
)

;;------------------------------------------------------------------;;
;;  Kopia zapasowa DWG                                              ;;
;;------------------------------------------------------------------;;
(defun vclip:make-backup ( / src dst )
    (setq src (strcat (getvar 'dwgprefix) (getvar 'dwgname)))
    (if (and (/= "" (getvar 'dwgprefix))
             (/= "" (getvar 'dwgname))
             (findfile src))
        (progn
            (setq dst
                (strcat
                    (getvar 'dwgprefix)
                    (vl-filename-base (getvar 'dwgname))
                    "_VPOCLIP_backup_"
                    (vclip:timestamp)
                    ".dwg"
                )
            )
            (if (vl-file-copy src dst)
                dst
                nil
            )
        )
    )
)

;;------------------------------------------------------------------;;
;;  Glowne polecenie                                                ;;
;;------------------------------------------------------------------;;

;; Alias pomocniczy - bardziej opisowa nazwa komendy.

;;==================================================================;;
;;                    End of File v2.9                              ;;
;;==================================================================;;


;;==================================================================;;
;;  OVERRIDE v3.0                                                   ;;
;;  Uproszczona zasada: po rozpoznaniu layoutu zostawiamy tylko     ;;
;;  ramki VPO-NPLT tego layoutu, ich etykiety oraz obiekty wybrane  ;;
;;  przez te ramki jako okna CP w Modelu. Reszta Modelu jest        ;;
;;  kasowana.                                                       ;;
;;==================================================================;;

(defun vclip:handle-v30 ( ent / enx )
    (if (and ent (setq enx (entget ent)))
        (cdr (assoc 5 enx))
    )
)

(defun vclip:add-handle-v30 ( ent handles / h )
    (setq h (vclip:handle-v30 ent))
    (if (and h (not (member h handles)))
        (cons h handles)
        handles
    )
)

(defun vclip:ss-add-handles-v30 ( ss handles / i ent )
    (if ss
        (progn
            (setq i 0)
            (while (< i (sslength ss))
                (setq ent (ssname ss i)
                      i   (1+ i))
                (setq handles (vclip:add-handle-v30 ent handles))
            )
        )
    )
    handles
)

(defun vclip:keep-ents-to-handles-v30 ( keep-ents / handles ent )
    (setq handles nil)
    (foreach ent keep-ents
        (setq handles (vclip:add-handle-v30 ent handles))
    )
    handles
)
(defun vclip:add-model-handles-on-layer-v34 ( handles layer-name / doc ms obj ent enx lay )
    (if (and layer-name (/= "" layer-name))
        (progn
            (setq doc (LM:acdoc)
                  ms  (vla-get-ModelSpace doc))
            (vlax-for obj ms
                (setq ent (vclip:vla-object->ename-safe obj))
                (if ent
                    (progn
                        (setq enx (entget ent)
                              lay (cdr (assoc 8 enx)))
                        (if (and lay (= (strcase lay) (strcase layer-name)))
                            (setq handles (vclip:add-handle-v30 ent handles))
                        )
                    )
                )
            )
        )
    )
    handles
)

(defun vclip:add-matching-xref-handles-v34 ( handles pattern / doc ms obj ent name cnt )
    ;; Uzywane przez eksport konfiguracyjny: XREF-y pasujace do klucza
    ;; maja zostac w calosci, nawet jezeli ich insert nie przecina ramki.
    (setq cnt 0)
    (if (and pattern (/= "" (vclip:trim-v34 pattern)) (/= "*" (vclip:trim-v34 pattern)))
        (progn
            (setq doc (LM:acdoc)
                  ms  (vla-get-ModelSpace doc))
            (vlax-for obj ms
                (setq ent (vclip:vla-object->ename-safe obj))
                (if (setq name (vclip:xref-insert-name-v34 ent))
                    (if (vclip:xref-name-keep-p-v34 name pattern)
                        (progn
                            (setq handles (vclip:add-handle-v30 ent handles))
                            (setq cnt (1+ cnt))
                        )
                    )
                )
            )
            (if (> cnt 0)
                (princ (strcat "\nVPOCLIP: XREF-y pasujace do klucza dodane do zostawienia: " (itoa cnt)))
            )
        )
    )
    handles
)

(defun vclip:add-extra-keep-handles-v34 ( handles / before after )
    (setq before (length handles))
    (setq handles (vclip:add-model-handles-on-ignored-layers-v324 handles))
    (if (and (boundp 'vclip:extra-keep-xref-pattern-v34)
             vclip:extra-keep-xref-pattern-v34)
        (setq handles (vclip:add-matching-xref-handles-v34 handles vclip:extra-keep-xref-pattern-v34))
    )
    (setq after (length handles))
    (if (> after before)
        (princ (strcat "\nVPOCLIP: dodatkowe obiekty chronione przed kasowaniem: " (itoa (- after before))))
    )
    handles
)

(defun vclip:wcspt->ucspt-v30 ( p / z )
    (if (vclip:valid-point-p p)
        (progn
            (setq z (if (and (caddr p) (numberp (caddr p))) (caddr p) 0.0))
            (trans (list (car p) (cadr p) z) 0 1)
        )
    )
)

(defun vclip:frame-cp-points-v30 ( frame / pts out p )
    ;; Punkty ramki sa zapisane w WCS. ssget CP oczekuje punktow w biezacym UCS.
    (setq pts (cadr frame)
          out nil)
    (foreach p pts
        (if (vclip:wcspt->ucspt-v30 p)
            (setq out (cons (vclip:wcspt->ucspt-v30 p) out))
        )
    )
    (reverse out)
)

(defun vclip:collect-handles-in-frames-v30 ( frames keep-ents / oldctab handles frame pts ss cp-ok cp-empty )
    ;; Zbiera obiekty z Modelu przez rzeczywiste okna wyboru CP po ramkach VPO-NPLT.
    ;; To zastępuje testy po bounding boxach, które przepuszczały za dużo obiektów.
    (setq oldctab (getvar 'ctab)
          handles (vclip:keep-ents-to-handles-v30 keep-ents)
          cp-ok    0
          cp-empty 0)

    (vl-catch-all-apply 'setvar (list 'ctab "Model"))

    (foreach frame frames
        (setq pts (vclip:frame-cp-points-v30 frame))
        (if (and pts (>= (length pts) 3))
            (progn
                (setq ss (ssget "_CP" pts '((410 . "Model"))))
                (if ss
                    (progn
                        (setq handles (vclip:ss-add-handles-v30 ss handles))
                        (setq cp-ok (1+ cp-ok))
                    )
                    (setq cp-empty (1+ cp-empty))
                )
            )
            (setq cp-empty (1+ cp-empty))
        )
    )

    (if oldctab (vl-catch-all-apply 'setvar (list 'ctab oldctab)))

    ;; Zwraca: (handles liczba_ramek_z_wyborem liczba_ramek_pustych)
    (list handles cp-ok cp-empty)
)

(defun vclip:delete-model-not-in-handles-v30 ( keep-handles / doc ms obj ent h checked kept to-del deleted no-handle )
    (setq doc       (LM:acdoc)
          ms        (vla-get-ModelSpace doc)
          checked   0
          kept      0
          to-del    nil
          deleted   0
          no-handle 0)

    (vlax-for obj ms
        (setq ent (vclip:vla-object->ename-safe obj))
        (if ent
            (progn
                (setq checked (1+ checked)
                      h       (vclip:handle-v30 ent))
                (cond
                    ((null h)
                     ;; Brak handle jest nietypowy - zostawiamy dla bezpieczenstwa.
                     (setq no-handle (1+ no-handle))
                    )
                    ((member h keep-handles)
                     (setq kept (1+ kept))
                    )
                    (t
                     (setq to-del (cons ent to-del))
                    )
                )
            )
        )
    )

    (foreach ent to-del
        (if (vclip:safe-delete-entity ent)
            (setq deleted (1+ deleted))
        )
    )

    ;; (usuniete sprawdzone zostawione wskazane_do_usuniecia bez_handle)
    (list deleted checked kept (length to-del) no-handle)
)


(defun vclip:insert-xref-p-v30 ( ent / enx name r )
    (setq enx  (entget ent)
          name (cdr (assoc 2 enx)))
    (if name
        (progn
            (setq r
                (vl-catch-all-apply
                    '(lambda ( / blk )
                         (setq blk (vla-item (vla-get-Blocks (LM:acdoc)) name))
                         (= :vlax-true (vla-get-IsXRef blk))
                     )
                    nil
                )
            )
            (and (not (vl-catch-all-error-p r)) r)
        )
    )
)

(defun vclip:report-xrefs-kept-v30 ( keep-handles / doc ms obj ent enx typ h cnt )
    (setq doc (LM:acdoc)
          ms  (vla-get-ModelSpace doc)
          cnt 0)
    (vlax-for obj ms
        (setq ent (vclip:vla-object->ename-safe obj))
        (if ent
            (progn
                (setq enx (entget ent)
                      typ (cdr (assoc 0 enx))
                      h   (vclip:handle-v30 ent))
                (if (and (= typ "INSERT") h (member h keep-handles)
                         (vclip:insert-xref-p-v30 ent))
                    (setq cnt (1+ cnt))
                )
            )
        )
    )
    cnt
)



;;==================================================================;;
;;                    End of File v3.0                              ;;
;;==================================================================;;

;;==================================================================;;
;;  OVERRIDE v3.3                                                   ;;
;;  Dodaje eksport do nowego DWG oraz PURGE po czyszczeniu Modelu.  ;;
;;                                                                  ;;
;;  Komendy:                                                        ;;
;;    VPOCLIP / VPOONLY       - dzialanie jak v3.0 na biezacym DWG   ;;
;;    VPOEXPORT / VPOONLYEXPORT - zapisuje kopie DWG, otwiera ja,   ;;
;;                                wykonuje VPOCLIP w kopii i wraca  ;;
;;                                do pliku zrodlowego.              ;;
;;                                                                  ;;
;;  UWAGA: eksport korzysta z pliku zapisanego na dysku. Jezeli      ;;
;;  aktualny DWG ma niezapisane zmiany (DBMOD /= 0), komenda         ;;
;;  przerywa prace, zeby nie modyfikowac oryginalu i nie tworzyc     ;;
;;  eksportu ze starego stanu pliku.                                 ;;
;;==================================================================;;


;;------------------------------------------------------------------;;
;;  PURGE                                                           ;;
;;------------------------------------------------------------------;;
(defun vclip:purge-all-v33 ( / oldcmdecho oldexpert res )
    ;; Wykonuje czyszczenie definicji na koncu VPOCLIP/VPOEXPORT.
    ;; Uzywamy wersji command-line -PURGE, zeby nie otwierac okna dialogowego.
    ;; Dwie iteracje pomagaja usunac elementy, ktore staja sie nieuzywane
    ;; dopiero po pierwszym przebiegu.
    (setq oldcmdecho (getvar 'CMDECHO)
          oldexpert  (getvar 'EXPERT))
    (vl-catch-all-apply 'setvar (list 'CMDECHO 0))
    (vl-catch-all-apply 'setvar (list 'EXPERT 5))

    (setq res
        (vl-catch-all-apply
            '(lambda ( / )
                 (vl-cmdf "_.-PURGE" "_All" "*" "_No")
                 (vl-cmdf "_.-PURGE" "_All" "*" "_No")
             )
            nil
        )
    )

    (if oldcmdecho (vl-catch-all-apply 'setvar (list 'CMDECHO oldcmdecho)))
    (if oldexpert  (vl-catch-all-apply 'setvar (list 'EXPERT oldexpert)))

    (not (vl-catch-all-error-p res))
)

(defun vclip:ensure-dwg-extension-v31 ( path / ext )
    (if path
        (progn
            (setq ext (vl-filename-extension path))
            (if ext
                path
                (strcat path ".dwg")
            )
        )
    )
)

(defun vclip:current-dwg-path-v31 ( / p n )
    (setq p (getvar 'dwgprefix)
          n (getvar 'dwgname))
    (if (and p n (/= p "") (/= n ""))
        (strcat p n)
    )
)

(defun vclip:path-equal-p-v31 ( a b )
    (and a b (= (strcase a) (strcase b)))
)

(defun vclip:get-export-filename-v31 ( keep-lay / src dir base def out )
    (setq src  (vclip:current-dwg-path-v31)
          dir  (getvar 'dwgprefix)
          base (vl-filename-base (getvar 'dwgname)))
    (if (or (null dir) (= dir "")) (setq dir ""))
    (setq def (strcat dir base "_" keep-lay "_VPOEXPORT.dwg"))
    (setq out (getfiled "Zapisz eksport VPO jako" def "dwg" 1))
    (vclip:ensure-dwg-extension-v31 out)
)

(defun vclip:copy-dwg-to-target-v31 ( src dst / ans ok )
    (setq ok nil)
    (cond
        ((or (null src) (not (findfile src)))
         (princ "\nVPOEXPORT: nie znaleziono zapisanego pliku zrodlowego DWG.")
        )
        ((or (null dst) (= dst ""))
         (princ "\nVPOEXPORT: nie wskazano pliku wynikowego.")
        )
        ((vclip:path-equal-p-v31 src dst)
         (princ "\nVPOEXPORT: plik wynikowy nie moze byc tym samym plikiem co zrodlowy.")
        )
        (t
         (if (findfile dst)
             (progn
                 (initget "Tak Nie")
                 (setq ans (getkword "\nPlik wynikowy juz istnieje. Nadpisac? [Tak/Nie] <Nie>: "))
                 (if (= ans "Tak")
                     (progn
                         (if (vl-catch-all-error-p (vl-catch-all-apply 'vl-file-delete (list dst)))
                             (princ "\nVPOEXPORT: nie udalo sie usunac istniejacego pliku wynikowego.")
                         )
                     )
                 )
             )
         )
         (if (findfile dst)
             (princ "\nVPOEXPORT: przerwano, plik wynikowy juz istnieje.")
             (progn
                 (setq ok (vl-file-copy src dst))
                 (if (not ok)
                     (princ "\nVPOEXPORT: nie udalo sie utworzyc kopii DWG. Sprawdz uprawnienia/sciezke.")
                 )
             )
         )
        )
    )
    ok
)

(defun vclip:open-document-v31 ( path / app docs r )
    (setq app  (vlax-get-acad-object)
          docs (vla-get-Documents app))
    (setq r (vl-catch-all-apply 'vla-open (list docs path)))
    (if (vl-catch-all-error-p r)
        nil
        r
    )
)

(defun vclip:activate-doc-v31 ( doc )
    (if doc
        (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-Activate (list doc))))
    )
)

(defun vclip:doc-fullname-v32 ( doc / r )
    (if doc
        (progn
            (setq r (vl-catch-all-apply 'vla-get-FullName (list doc)))
            (if (vl-catch-all-error-p r) nil r)
        )
    )
)

(defun vclip:active-document-path-is-v32 ( path / act full )
    ;; Dodatkowy bezpiecznik: przed kasowaniem upewniamy sie,
    ;; ze aktywnym dokumentem jest plik wynikowy, a nie zrodlo.
    (setq act  (LM:acdoc)
          full (vclip:doc-fullname-v32 act))
    (vclip:path-equal-p-v31 full path)
)

(defun vclip:save-doc-v31 ( doc )
    (if doc
        (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-Save (list doc))))
    )
)

(defun vclip:close-doc-nosave-v31 ( doc )
    (if doc
        (not (vl-catch-all-error-p (vl-catch-all-apply 'vla-Close (list doc :vlax-false))))
    )
)

(defun vclip:clip-current-document-by-layout-v31
       ( keep-lay make-backup-p / doc oldctab layer-states ok res )

    (setq doc          (LM:acdoc)
          oldctab      (getvar 'ctab)
          layer-states nil
          ok           nil)

    (setq res
        (vl-catch-all-apply
            '(lambda ( / frames keep-ents labels-count backup del-vpo cp-result keep-handles del-model del-layouts xref-count )
                 (cond
                     ((or (null keep-lay) (= (strcase keep-lay) "MODEL"))
                      (princ "\nVPOCLIP: nie rozpoznano layoutu papieru.")
                     )
                     ((not (vclip:layout-exists-p keep-lay))
                      (princ (strcat "\nVPOCLIP: layout nie istnieje: " keep-lay))
                     )
                     (t
                      (princ (strcat "\nVPOCLIP v3.4: zostaje layout: " keep-lay))

                      (setq frames (vclip:collect-frames-for-layout keep-lay))
                      (if (null frames)
                          (princ "\nVPOCLIP: nie znaleziono poprawnych ramek VPO-NPLT dla tego layoutu. Nic nie skasowano.")
                          (progn
                              (setq keep-ents    (vclip:collect-keep-ents frames)
                                    labels-count (- (length keep-ents) (length frames)))

                              (princ (strcat "\nVPOCLIP: ramki VPO-NPLT tego layoutu: " (itoa (length frames))))
                              (princ (strcat "\nVPOCLIP: etykiety VPO do zostawienia: " (itoa labels-count)))

                              (if make-backup-p
                                  (progn
                                      (setq backup (vclip:make-backup))
                                      (if backup
                                          (princ (strcat "\nVPOCLIP: kopia zapasowa: " backup))
                                          (princ "\nVPOCLIP: UWAGA - nie udalo sie wykonac kopii zapasowej.")
                                      )
                                  )
                              )

                              (LM:startundo doc)
                              (setq layer-states (vclip:unlock-all-layers))

                              (princ "\n[1] Usuwam ramki i etykiety VPO z innych layoutow...")
                              (setq del-vpo (vclip:delete-other-vpo-frames-and-labels keep-ents))
                              (princ (strcat " usunieto: " (itoa del-vpo)))

                              (princ "\n[2] Wybieram zawartosc ramek VPO-NPLT przez CP...")
                              (setq cp-result    (vclip:collect-handles-in-frames-v30 frames keep-ents)
                                    keep-handles (vclip:add-extra-keep-handles-v34 (car cp-result)))
                              (princ
                                  (strcat
                                      " ramek z wyborem: " (itoa (cadr cp-result))
                                      " / ramek pustych: " (itoa (caddr cp-result))
                                      " / obiektow do zostawienia: " (itoa (length keep-handles))
                                  )
                              )

                              (princ "\n[3] Kasuje z Modelu wszystko, co nie zostalo wybrane w ramkach...")
                              (setq del-model (vclip:delete-model-not-in-handles-v30 keep-handles))
                              (princ
                                  (strcat
                                      " usunieto: " (itoa (car del-model))
                                      " / sprawdzono: " (itoa (cadr del-model))
                                      " / zostawiono: " (itoa (caddr del-model))
                                      " / wskazano do usuniecia: " (itoa (cadddr del-model))
                                      " / bez handle zostawiono: " (itoa (car (cddddr del-model)))
                                  )
                              )

                              (setq xref-count (vclip:report-xrefs-kept-v30 keep-handles))
                              (if (> xref-count 0)
                                  (princ (strcat "\n[UWAGA] Zostawiono XREF-y przecinajace ramki jako cale obiekty: " (itoa xref-count)))
                              )

                              (princ "\n[4] Usuwam pozostale layouty...")
                              (setq del-layouts (vclip:delete-layouts-except keep-lay))
                              (princ (strcat " usunieto: " (itoa del-layouts)))

                              (princ "\n[5] Wykonuje PURGE po usunieciu obiektow spoza ramek i layoutow...")
                              (if (vclip:purge-all-v33)
                                  (princ " OK")
                                  (princ " UWAGA - PURGE nie zostal wykonany poprawnie")
                              )

                              (vclip:restore-layer-locks layer-states)
                              (setq layer-states nil)
                              (LM:endundo doc)

                              (if (vclip:layout-exists-p keep-lay)
                                  (vl-catch-all-apply 'setvar (list 'ctab keep-lay))
                              )

                              (setq ok T)
                              (princ "\nVPOCLIP v3.4: gotowe. Zostawiono jeden layout, jego ramki VPO-NPLT, etykiety oraz obiekty wybrane w tych ramkach. Reszta Modelu zostala skasowana. PURGE wykonano po czyszczeniu Modelu i usunieciu layoutow.")
                          )
                      )
                     )
                 )
             )
            nil
        )
    )

    ;; Awaryjne sprzatanie po bledzie.
    (if layer-states
        (progn
            (vclip:restore-layer-locks layer-states)
            (setq layer-states nil)
        )
    )
    (LM:endundo doc)

    (if (vl-catch-all-error-p res)
        (progn
            (if oldctab
                (if (vclip:layout-exists-p oldctab)
                    (vl-catch-all-apply 'setvar (list 'ctab oldctab))
                )
            )
            (princ (strcat "\nVPOCLIP blad: " (vl-catch-all-error-message res)))
            nil
        )
        ok
    )
)


;;------------------------------------------------------------------;;
;;  Eksport wsadowy z VPOCLIP_CONF.txt                                  ;;
;;------------------------------------------------------------------;;
(defun vclip:trim-v34 ( s )
    (if s
        (vl-string-trim (strcat " " (chr 9) (chr 10) (chr 13)) s)
        ""
    )
)

(defun vclip:config-skip-line-p-v34 ( line / txt first )
    (setq txt (vclip:trim-v34 line))
    (if (> (strlen txt) 0)
        (setq first (substr txt 1 1))
    )
    (or (= txt "")
        (= first "#")
        (wcmatch (strcase txt) "NAZWA LAYOUTA*"))
)

(defun vclip:parse-config-line-v34 ( line / p1 p2 a rest b c )
    (setq p1 (vl-string-search ";" line))
    (if p1
        (progn
            (setq a    (substr line 1 p1)
                  rest (substr line (+ p1 2))
                  p2   (vl-string-search ";" rest))
            (if p2
                (progn
                    (setq b (substr rest 1 p2)
                          c (substr rest (+ p2 2)))
                    (list (vclip:trim-v34 a) (vclip:trim-v34 b) (vclip:trim-v34 c))
                )
            )
        )
    )
)

(defun vclip:config-row-valid-p-v34 ( rec )
    (and rec
         (= 3 (length rec))
         (/= "" (car rec))
         (/= "" (cadr rec))
         (not (wcmatch (strcase (car rec)) "NAZWA LAYOUTA*")))
)

(defun vclip:read-config-v34 ( path / fh line rec rows ln bad )
    (setq rows nil
          ln   0
          bad  0)
    (if (setq fh (open path "r"))
        (progn
            (while (setq line (read-line fh))
                (setq ln (1+ ln))
                (cond
                    ((vclip:config-skip-line-p-v34 line) nil)
                    ((vclip:config-row-valid-p-v34 (setq rec (vclip:parse-config-line-v34 line)))
                     (setq rows (cons rec rows))
                    )
                    (t
                     (setq bad (1+ bad))
                     (princ (strcat "\nVPOCFG: pominieto niepoprawny wiersz " (itoa ln) ": " line))
                    )
                )
            )
            (close fh)
            (if (> bad 0)
                (princ (strcat "\nVPOCFG: liczba pominietych wierszy: " (itoa bad)))
            )
            (reverse rows)
        )
        (progn
            (princ (strcat "\nVPOCFG: nie udalo sie otworzyc pliku konfiguracji: " path))
            nil
        )
    )
)

(defun vclip:config-path-v34 ( )
    ;; Właściwa implementacja v3.12 jest zdefiniowana w dalszej części pliku.
    (vclip:config-path-v312)
)

(defun vclip:dir-with-sep-v34 ( path / dir last )
    (setq dir (vl-filename-directory path))
    (if dir
        (progn
            (setq last (substr dir (strlen dir) 1))
            (if (or (= last "\\") (= last "/"))
                dir
                (strcat dir "\\")
            )
        )
        ""
    )
)

(defun vclip:pdf-path-from-dwg-v35 ( dwgpath / dir base )
    (if dwgpath
        (progn
            (setq dir  (vclip:dir-with-sep-v34 dwgpath)
                  base (vl-filename-base dwgpath))
            (strcat dir base ".pdf")
        )
    )
)

(defun vclip:delete-file-if-exists-v35 ( path / r )
    (if (and path (findfile path))
        (progn
            (setq r (vl-catch-all-apply 'vl-file-delete (list path)))
            (not (vl-catch-all-error-p r))
        )
        T
    )
)

(defun vclip:layout-object-v35 ( lay / layouts r )
    (if lay
        (progn
            (setq layouts (vla-get-Layouts (LM:acdoc))
                  r       (vl-catch-all-apply 'vla-item (list layouts lay)))
            (if (vl-catch-all-error-p r) nil r)
        )
    )
)

(defun vclip:layout-plot-info-v35 ( lay / obj cfg media style )
    (if (setq obj (vclip:layout-object-v35 lay))
        (progn
            (setq cfg   (vl-catch-all-apply 'vla-get-ConfigName (list obj))
                  media (vl-catch-all-apply 'vla-get-CanonicalMediaName (list obj))
                  style (vl-catch-all-apply 'vla-get-StyleSheet (list obj)))
            (list
                (if (vl-catch-all-error-p cfg) "" cfg)
                (if (vl-catch-all-error-p media) "" media)
                (if (vl-catch-all-error-p style) "" style)
            )
        )
    )
)

(defun vclip:plot-layout-to-pdf-v35 ( lay pdfpath / doc plot oldctab oldfiledia oldcmddia oldback r info plot-ok )
    ;; Wariant BricsCAD: uzywa wylacznie Page Setup aktualnego layoutu.
    ;; Nie zmienia ConfigName, nie odpytuje listy plotterow i nie robi
    ;; RefreshPlotDeviceInfo, bo te operacje potrafia destabilizowac BricsCAD
    ;; na niektorych sterownikach PDF.
    (setq doc     (LM:acdoc)
          plot    (vla-get-Plot doc)
          oldctab (getvar 'ctab)
          info    (vclip:layout-plot-info-v35 lay))
    (cond
        ((or (null lay) (= "" lay) (= (strcase lay) "MODEL"))
         (princ "\nVPOCFG: PDF - niepoprawna nazwa layoutu.")
         (vclip:trace-v35 "PDF FAIL invalid layout")
         nil
        )
        ((not (vclip:layout-exists-p lay))
         (princ (strcat "\nVPOCFG: PDF - layout nie istnieje: " lay))
         (vclip:trace-v35 (strcat "PDF FAIL missing layout " lay))
         nil
        )
        ((or (null pdfpath) (= "" pdfpath))
         (princ "\nVPOCFG: PDF - niepoprawna sciezka PDF.")
         (vclip:trace-v35 "PDF FAIL invalid path")
         nil
        )
        ((not (vclip:delete-file-if-exists-v35 pdfpath))
         (princ (strcat "\nVPOCFG: PDF - nie udalo sie usunac istniejacego pliku: " pdfpath))
         (vclip:trace-v35 (strcat "PDF FAIL delete existing " pdfpath))
         nil
        )
        (t
         (if info
             (princ
                 (strcat
                     "\nVPOCFG: PDF - layout: " lay
                     " / plotter: " (car info)
                     " / papier: " (cadr info)
                     " / styl: " (caddr info)
                 )
             )
         )
         (vclip:trace-v35 (strcat "PDF START layout=" lay " file=" pdfpath))
         (setq oldfiledia (vclip:getvar-safe-v35 'FILEDIA 1)
               oldcmddia  (vclip:getvar-safe-v35 'CMDDIA 1)
               oldback    (vclip:getvar-safe-v35 'BACKGROUNDPLOT 2))
         (vl-catch-all-apply 'setvar (list 'FILEDIA 0))
         (vl-catch-all-apply 'setvar (list 'CMDDIA 0))
         (vl-catch-all-apply 'setvar (list 'BACKGROUNDPLOT 0))
         (vl-catch-all-apply 'setvar (list 'ctab lay))
         (setq r (vl-catch-all-apply 'vla-PlotToFile (list plot pdfpath)))
         (setq plot-ok (and (not (vl-catch-all-error-p r)) (findfile pdfpath)))
         (if oldctab (vl-catch-all-apply 'setvar (list 'ctab oldctab)))
         (vl-catch-all-apply 'setvar (list 'FILEDIA 1))
         (vl-catch-all-apply 'setvar (list 'CMDDIA oldcmddia))
         (vl-catch-all-apply 'setvar (list 'BACKGROUNDPLOT oldback))
         (if plot-ok
             (progn
                 (princ (strcat "\nVPOCFG: PDF zapisany: " pdfpath))
                 (vclip:trace-v35 (strcat "PDF OK " pdfpath))
                 T
             )
             (progn
                 (if (vl-catch-all-error-p r)
                     (princ (strcat "\nVPOCFG: PDF - blad plotowania: " (vl-catch-all-error-message r)))
                     (princ "\nVPOCFG: PDF - plotowanie nie utworzylo pliku PDF. Sprawdz Page Setup layoutu.")
                 )
                 (vclip:trace-v35 "PDF FAIL PlotToFile")
                 nil
             )
         )
        )
    )
)
(defun vclip:copy-dwg-to-target-auto-v34 ( src dst overwrite / ok )
    (setq ok nil)
    (cond
        ((or (null src) (not (findfile src)))
         (princ "\nVPOCFG: nie znaleziono zapisanego pliku zrodlowego DWG.")
        )
        ((or (null dst) (= dst ""))
         (princ "\nVPOCFG: nie wskazano pliku wynikowego.")
        )
        ((vclip:path-equal-p-v31 src dst)
         (princ "\nVPOCFG: plik wynikowy nie moze byc tym samym plikiem co zrodlowy.")
        )
        ((and (findfile dst) (not overwrite))
         (princ (strcat "\nVPOCFG: pomijam, plik juz istnieje: " dst))
        )
        (t
         (if (and (findfile dst) overwrite)
             (if (vl-catch-all-error-p (vl-catch-all-apply 'vl-file-delete (list dst)))
                 (princ (strcat "\nVPOCFG: nie udalo sie usunac istniejacego pliku: " dst))
             )
         )
         (if (findfile dst)
             (princ (strcat "\nVPOCFG: pomijam, plik wynikowy nadal istnieje: " dst))
             (progn
                 (setq ok (vl-file-copy src dst))
                 (if (not ok)
                     (princ (strcat "\nVPOCFG: nie udalo sie utworzyc kopii: " dst))
                 )
             )
         )
        )
    )
    ok
)

(defun vclip:xref-name-keep-p-v34 ( name pattern / pat )
    (setq pat (vclip:trim-v34 pattern))
    (or (null pat)
        (= pat "")
        (= pat "*")
        (and name (wcmatch (strcase name) (strcase pat))))
)

(defun vclip:xref-block-p-v34 ( blk / r )
    (setq r (vl-catch-all-apply 'vla-get-IsXRef (list blk)))
    (and (not (vl-catch-all-error-p r)) (= :vlax-true r))
)

(defun vclip:xref-block-exists-p-v34 ( name / r )
    (if name
        (progn
            (setq r
                (vl-catch-all-apply
                    '(lambda ( / blk )
                         (setq blk (vla-item (vla-get-Blocks (LM:acdoc)) name))
                         (vclip:xref-block-p-v34 blk)
                     )
                    nil
                )
            )
            (and (not (vl-catch-all-error-p r)) r)
        )
    )
)

(defun vclip:reset-xref-name-cache-v325 ( )
    (setq vclip:xref-name-cache-v325 nil)
)

(defun vclip:xref-block-name-p-v325
       ( name / key cached result is-xref )
    (if name
        (progn
            (setq key (strcase name)
                  cached (assoc key vclip:xref-name-cache-v325))
            (if cached
                (cdr cached)
                (progn
                    (setq result
                        (vl-catch-all-apply
                            'vla-Item
                            (list (vla-get-Blocks (LM:acdoc)) name))
                          is-xref
                        (and (not (vl-catch-all-error-p result))
                             (vclip:xref-block-p-v34 result))
                          vclip:xref-name-cache-v325
                        (cons (cons key is-xref)
                              vclip:xref-name-cache-v325))
                    is-xref))))
)

(defun vclip:xref-insert-name-v34 ( ent / enx typ name )
    (if ent
        (progn
            (setq enx  (entget ent)
                  typ  (cdr (assoc 0 enx))
                  name (cdr (assoc 2 enx)))
            (if (and (= typ "INSERT")
                     name
                     (vclip:xref-block-name-p-v325 name))
                name)))
)

(defun vclip:string-member-ci-v324 ( value values )
    (and value (member (strcase value) values))
)

(defun vclip:copy-object-to-owner-v324 ( doc obj owner / data result )
    (setq data (vlax-make-safearray vlax-vbObject '(0 . 0)))
    (vlax-safearray-put-element data 0 obj)
    (setq result
        (vl-catch-all-apply
            'vla-CopyObjects
            (list doc (vlax-make-variant data) owner)))
    (not (vl-catch-all-error-p result))
)

(defun vclip:count-matching-top-level-xrefs-v324
       ( pattern / selection index ent name key names )
    (setq selection (ssget "_X" '((0 . "INSERT")))
          index 0
          names nil)
    (if selection
        (while (< index (sslength selection))
            (setq ent (ssname selection index)
                  index (1+ index)
                  name (vclip:xref-insert-name-v34 ent))
            (if (and name (vclip:xref-name-keep-p-v34 name pattern))
                (progn
                    (setq key (strcase name))
                    (if (not (member key names))
                        (setq names (cons key names)))))))
    (length names)
)

(if (not (boundp 'vclip:active-xref-key-v333))
    (setq vclip:active-xref-key-v333 nil))

(defun vclip:top-level-xref-names-v333
       ( / selection index ent name key keys names )
    ;; Tylko rzeczywiste INSERT-y. Definicje XREF bez wstawki nie sa
    ;; przygotowywane do PDF i nie moga zablokowac calego zadania.
    (vclip:reset-xref-name-cache-v325)
    (setq selection (ssget "_X" '((0 . "INSERT")))
          index 0
          keys nil
          names nil)
    (if selection
        (while (< index (sslength selection))
            (setq ent (ssname selection index)
                  index (1+ index)
                  name (vclip:xref-insert-name-v34 ent))
            (if (and name
                     (null (vl-string-search "|" name))
                     (not (member (setq key (strcase name)) keys)))
                (setq keys (cons key keys)
                      names (cons name names)))))
    (reverse names)
)
(defun vclip:top-level-xref-count-v333 ( )
    (length (vclip:top-level-xref-names-v333))
)

(defun vclip:set-xref-loaded-state-v333 ( name load-p / blocks blk result )
    (setq blocks (vla-get-Blocks (LM:acdoc))
          blk (vl-catch-all-apply 'vla-Item (list blocks name)))
    (if (vl-catch-all-error-p blk)
        nil
        (progn
            (setq result
                (vl-catch-all-apply
                    (if load-p 'vla-Reload 'vla-Unload)
                    (list blk)))
            (not (vl-catch-all-error-p result))))
)

(defun vclip:prepare-xrefs-for-pdf-v333
       ( pattern ignore-xref
         / effective names name want-load result total loaded unloaded failed )
    (setq effective (if ignore-xref "<ALL>" (strcase (vclip:trim-v34 pattern)))
          names (vclip:top-level-xref-names-v333)
          total (length names)
          loaded 0
          unloaded 0
          failed 0)
    (if (= effective vclip:active-xref-key-v333)
        (list T total 0 0 0 T)
        (progn
            (foreach name names
                (setq want-load
                    (or ignore-xref
                        (vclip:xref-name-keep-p-v34 name pattern))
                      result
                    (vclip:set-xref-loaded-state-v333 name want-load))
                (if result
                    (if want-load
                        (setq loaded (1+ loaded))
                        (setq unloaded (1+ unloaded)))
                    (setq failed (1+ failed))))
            (vclip:reset-xref-name-cache-v325)
            (vl-catch-all-apply 'vla-Regen (list (LM:acdoc) 1))
            (if (= failed 0)
                (setq vclip:active-xref-key-v333 effective)
                (setq vclip:active-xref-key-v333 nil))
            (vclip:trace-v35
                (strcat "XREF330 PREPARE key=" effective
                        " total=" (itoa total)
                        " loaded=" (itoa loaded)
                        " unloaded=" (itoa unloaded)
                        " failed=" (itoa failed)))
            (list (= failed 0) total loaded unloaded failed nil)))
)
(defun vclip:layout-owner-map-v326 ( / layouts lay block owner result )
    (setq layouts (vla-get-Layouts (LM:acdoc))
          result nil)
    (vlax-for lay layouts
        (setq block (vla-get-Block lay)
              owner (vclip:vla-object->ename-safe block))
        (if owner
            (setq result
                (cons (cons owner (vla-get-Name lay)) result))))
    result
)

(defun vclip:preserve-matching-xrefs-v324
       ( keep-lay pattern
         / doc layouts target target-block owner-map selection index ent enx
           owner lay-name name key names present candidates pair obj copied failed )
    ;; Keep one top-level insertion of every matching XREF definition. When
    ;; its only insertion lives on a layout that will be deleted, clone that
    ;; insertion to the exported layout before deleting the other layouts.
    (setq doc        (LM:acdoc)
          layouts    (vla-get-Layouts doc)
          target     (vl-catch-all-apply 'vla-Item (list layouts keep-lay))
          owner-map  (vclip:layout-owner-map-v326)
          selection  (ssget "_X" '((0 . "INSERT")))
          index      0
          names      nil
          present    nil
          candidates nil
          copied     0
          failed     0)
    (if (vl-catch-all-error-p target)
        (list 0 0 0 1)
        (progn
            (setq target-block (vla-get-Block target))
            (if selection
                (while (< index (sslength selection))
                    (setq ent (ssname selection index)
                          index (1+ index)
                          enx (entget ent)
                          owner (cdr (assoc 330 enx))
                          lay-name (cdr (assoc owner owner-map))
                          name (vclip:xref-insert-name-v34 ent))
                    (if (and lay-name name
                             (vclip:xref-name-keep-p-v34 name pattern))
                        (progn
                            (setq key (strcase name))
                            (if (not (member key names))
                                (setq names (cons key names)))
                            (if (or (= "MODEL" (strcase lay-name))
                                    (= (strcase keep-lay) (strcase lay-name)))
                                (if (not (member key present))
                                    (setq present (cons key present)))
                                (if (null (assoc key candidates))
                                    (setq candidates
                                        (cons (cons key ent) candidates))))))))
            (foreach key names
                (if (not (member key present))
                    (progn
                        (setq pair (assoc key candidates)
                              obj (if pair
                                  (vl-catch-all-apply
                                      'vlax-ename->vla-object
                                      (list (cdr pair)))))
                        (if (and pair
                                 (not (vl-catch-all-error-p obj))
                                 (vclip:copy-object-to-owner-v324
                                     doc obj target-block))
                            (setq copied (1+ copied)
                                  present (cons key present))
                            (setq failed (1+ failed))))))
            (vclip:trace-v35
                (strcat "XREF326 PRESERVE names=" (itoa (length names))
                        " present=" (itoa (- (length names) copied))
                        " copied=" (itoa copied)
                        " failed=" (itoa failed)))
            ;; unique names, already present, copied, failed
            (list (length names) (- (length present) copied) copied failed)))
)
(defun vclip:delete-nonmatching-xref-inserts-v34 ( pattern / doc spaces space obj ent name to-del checked kept deleted )
    (setq doc     (LM:acdoc)
          spaces  (list (vla-get-ModelSpace doc) (vla-get-PaperSpace doc))
          to-del  nil
          checked 0
          kept    0
          deleted 0)
    (foreach space spaces
        (vlax-for obj space
            (setq ent (vclip:vla-object->ename-safe obj))
            (if (setq name (vclip:xref-insert-name-v34 ent))
                (progn
                    (setq checked (1+ checked))
                    (if (vclip:xref-name-keep-p-v34 name pattern)
                        (setq kept (1+ kept))
                        (setq to-del (cons ent to-del))
                    )
                )
            )
        )
    )
    (foreach ent to-del
        (if (vclip:safe-delete-entity ent)
            (setq deleted (1+ deleted))
        )
    )
    (list deleted checked kept)
)

(defun vclip:collect-nonmatching-xref-names-v34 ( pattern / blocks blk name out )
    (setq blocks (vla-get-Blocks (LM:acdoc))
          out    nil)
    (vlax-for blk blocks
        (if (vclip:xref-block-p-v34 blk)
            (progn
                (setq name (vla-get-Name blk))
                ;; Nested xrefs contain | and cannot be detached directly from host DWG.
                (if (and name
                         (not (vl-string-search "|" name))
                         (not (vclip:xref-name-keep-p-v34 name pattern))
                         (not (member name out)))
                    (setq out (cons name out))
                )
            )
        )
    )
    (reverse out)
)

(defun vclip:detach-xref-by-name-v34
       ( name / blocks blk r oldcmdecho detached )
    (setq blocks (vla-get-Blocks (LM:acdoc))
          r      (vl-catch-all-apply 'vla-item (list blocks name))
          detached nil)
    (if (not (vl-catch-all-error-p r))
        (progn
            (setq blk r
                  r   (vl-catch-all-apply 'vla-Detach (list blk)))
            (if (vl-catch-all-error-p r)
                (progn
                    (setq oldcmdecho (getvar 'CMDECHO))
                    (vl-catch-all-apply 'setvar (list 'CMDECHO 0))
                    (setq r
                        (vl-catch-all-apply
                            '(lambda ( / )
                                 (vl-cmdf "_.-XREF" "_Detach" name))
                            nil))
                    (if oldcmdecho
                        (vl-catch-all-apply
                            'setvar (list 'CMDECHO oldcmdecho)))))
            (setq detached
                (not (vclip:xref-block-exists-p-v34 name)))))
    (vclip:reset-xref-name-cache-v325)
    detached
)

(defun vclip:detach-nonmatching-xrefs-v34 ( pattern / names name detached failed )
    (setq names    (vclip:collect-nonmatching-xref-names-v34 pattern)
          detached 0
          failed   0)
    (foreach name names
        (if (vclip:detach-xref-by-name-v34 name)
            (setq detached (1+ detached))
            (setq failed (1+ failed))
        )
    )
    (list detached failed (length names))
)

(defun vclip:filter-xrefs-v34 ( pattern / del det )
    (if (or (null pattern) (= "" (vclip:trim-v34 pattern)) (= "*" (vclip:trim-v34 pattern)))
        (progn
            (princ "\nVPOCFG: filtr XREF pusty lub *, zostawiam wszystkie odnosniki.")
            (list 0 0 0 0 0)
        )
        (progn
            (setq del (vclip:delete-nonmatching-xref-inserts-v34 pattern)
                  det (vclip:detach-nonmatching-xrefs-v34 pattern))
            (princ
                (strcat
                    "\nVPOCFG: filtr XREF '" pattern "'"
                    " / usunieto wstawien: " (itoa (car del))
                    " / sprawdzono wstawien: " (itoa (cadr del))
                    " / zostawiono wstawien: " (itoa (caddr del))
                    " / odlaczono definicji: " (itoa (car det))
                    " / bledy odlaczania: " (itoa (cadr det))
                )
            )
            (list (car del) (cadr del) (caddr del) (car det) (cadr det))
        )
    )
)

(defun vclip:run-config-row-v34 ( srcdoc srcpath rec overwrite / keep-lay out-name pattern dst pdf newdoc result xres saved pdf-ok )
    (setq keep-lay (car rec)
          out-name (cadr rec)
          pattern  (caddr rec)
          dst      (vclip:target-path-from-config-v34 srcpath out-name)
          pdf      (vclip:pdf-path-from-dwg-v35 dst)
          saved    nil
          pdf-ok   nil)

    (vclip:activate-doc-v31 srcdoc)
    (princ (strcat "\n\nVPOCFG: layout " keep-lay " -> " dst " / zostaw XREF: " pattern))
    (vclip:trace-v35 (strcat "ROW START layout=" keep-lay " dst=" dst " pattern=" pattern))

    (cond
        ((not (vclip:layout-exists-p keep-lay))
         (princ (strcat "\nVPOCFG: layout nie istnieje w pliku zrodlowym: " keep-lay))
         "FAIL"
        )
        ((not (vclip:copy-dwg-to-target-auto-v34 srcpath dst overwrite))
         "SKIP"
        )
        (t
         (vclip:trace-v35 (strcat "OPEN COPY " dst))
         (setq newdoc (vclip:open-document-v31 dst))
         (cond
             ((null newdoc)
              (princ "\nVPOCFG: nie udalo sie otworzyc pliku wynikowego.")
              (vclip:activate-doc-v31 srcdoc)
              "FAIL"
             )
             ((not (vclip:activate-doc-v31 newdoc))
              (princ "\nVPOCFG: nie udalo sie aktywowac pliku wynikowego.")
              (vclip:activate-doc-v31 srcdoc)
              (if vclip:acad-close-copy-v36
                  (progn
                      (vclip:trace-v35 "CLOSE COPY")
                      (vclip:close-doc-nosave-v31 newdoc)
                  )
                  (progn
                      (princ "\nVPOCFG: BricsCAD SAFE - zostawiam plik wynikowy otwarty, zeby uniknac zamkniecia BricsCAD-a.")
                      (vclip:trace-v35 "CLOSE COPY SKIP safe mode")
                  )
              )
              "FAIL"
             )
             ((not (vclip:active-document-path-is-v32 dst))
              (princ "\nVPOCFG: BEZPIECZNIK - aktywny dokument nie jest plikiem wynikowym.")
              (vclip:activate-doc-v31 srcdoc)
              (if vclip:acad-close-copy-v36
                  (progn
                      (vclip:trace-v35 "CLOSE COPY")
                      (vclip:close-doc-nosave-v31 newdoc)
                  )
                  (progn
                      (princ "\nVPOCFG: BricsCAD SAFE - zostawiam plik wynikowy otwarty, zeby uniknac zamkniecia BricsCAD-a.")
                      (vclip:trace-v35 "CLOSE COPY SKIP safe mode")
                  )
              )
              "FAIL"
             )
             (t
              (setq vclip:extra-keep-xref-pattern-v34 pattern)
              (vclip:trace-v35 (strcat "CLIP START layout=" keep-lay))
              (setq result (vclip:clip-current-document-by-layout-v31 keep-lay nil))
              (vclip:trace-v35 (strcat "CLIP END result=" (if result "OK" "FAIL")))
              (setq vclip:extra-keep-xref-pattern-v34 nil)
              (if result
                  (progn
                      (setq xres (vclip:filter-xrefs-v34 pattern))
                      (princ "\nVPOCFG: finalny PURGE po filtrze XREF...")
                      (if (vclip:purge-all-v33)
                          (princ " OK")
                          (princ " UWAGA - PURGE nie zostal wykonany poprawnie")
                      )
                      (setq saved (vclip:save-doc-v31 newdoc))
                      (if saved
                          (progn
                              (princ (strcat "\nVPOCFG: zapisano plik wynikowy: " dst))
                              (if vclip:acad-plot-pdf-v36
                                  (progn
                                      (vclip:trace-v35 (strcat "PDF CALL " pdf))
                                      (setq pdf-ok (vclip:plot-layout-to-pdf-v35 keep-lay pdf))
                                      (if pdf-ok (vclip:save-doc-v31 newdoc))
                                  )
                                  (progn
                                      (setq pdf-ok T)
                                      (princ "\nVPOCFG: BricsCAD SAFE - pomijam automatyczny PDF w tej wersji.")
                                      (vclip:trace-v35 "PDF SKIP safe mode")
                                  )
                              )
                          )
                          (princ "\nVPOCFG: UWAGA - nie udalo sie zapisac pliku wynikowego.")
                      )
                  )
                  (princ "\nVPOCFG: czyszczenie layoutu nie zostalo wykonane poprawnie.")
              )
              (vclip:activate-doc-v31 srcdoc)
              (if vclip:acad-close-copy-v36
                  (progn
                      (vclip:trace-v35 "CLOSE COPY")
                      (vclip:close-doc-nosave-v31 newdoc)
                  )
                  (progn
                      (princ "\nVPOCFG: BricsCAD SAFE - zostawiam plik wynikowy otwarty, zeby uniknac zamkniecia BricsCAD-a.")
                      (vclip:trace-v35 "CLOSE COPY SKIP safe mode")
                  )
              )
              (if (and result saved pdf-ok) "OK" "FAIL")
             )
         )
        )
    )
)


(defun vclip:legacy-command-vpoclip ( / pair keep-lay )
    (vl-load-com)
    (setq pair (vclip:get-picked-vpo-pair))
    (cond
        ((null pair)
         (princ "\nVPOCLIP: wskazany obiekt nie jest rzutnia ani ramka VPO z poprawnym linkiem.")
        )
        (t
         (setq keep-lay (caddr pair))
         (vclip:clip-current-document-by-layout-v31 keep-lay T)
        )
    )
    (princ)
)

(defun vclip:legacy-command-vpoonly () (c:VPOCLIP))

(defun vclip:legacy-command-vpoexport ( / srcdoc srcpath pair keep-lay dst newdoc result )
    (vl-load-com)
    (setq srcdoc  (LM:acdoc)
          srcpath (vclip:current-dwg-path-v31))

    (cond
        ((or (null srcpath) (not (findfile srcpath)) (= 0 (getvar 'dwgtitled)))
         (princ "\nVPOEXPORT: najpierw zapisz rysunek zrodlowy jako DWG. Eksport pracuje na kopii pliku z dysku.")
        )
        ((/= 0 (getvar 'dbmod))
         (princ "\nVPOEXPORT: rysunek ma niezapisane zmiany. Zapisz go najpierw, a potem uruchom VPOEXPORT. Oryginal nie zostanie modyfikowany.")
        )
        ((/= 0 (vclip:getvar-safe-v35 'SDI 0))
         (princ "\nVPOEXPORT: BricsCAD ma SDI=1. Ustaw SDI na 0 przed eksportem do kopii.")
        )
        (t
         (setq pair (vclip:get-picked-vpo-pair))
         (if (null pair)
             (princ "\nVPOEXPORT: wskazany obiekt nie jest rzutnia ani ramka VPO z poprawnym linkiem.")
             (progn
                 (setq keep-lay (caddr pair))
                 (if (or (null keep-lay) (= (strcase keep-lay) "MODEL"))
                     (princ "\nVPOEXPORT: nie rozpoznano layoutu papieru dla wskazanej rzutni.")
                     (progn
                         (setq dst (vclip:get-export-filename-v31 keep-lay))
                         (if (and dst (vclip:copy-dwg-to-target-v31 srcpath dst))
                             (progn
                                 (princ (strcat "\nVPOEXPORT: utworzono kopie: " dst))
                                 (vclip:trace-v35 (strcat "OPEN COPY " dst))
         (setq newdoc (vclip:open-document-v31 dst))
                                 (if (null newdoc)
                                     (progn
                                         (princ "\nVPOEXPORT: nie udalo sie otworzyc pliku wynikowego.")
                                         (vclip:activate-doc-v31 srcdoc)
                                     )
                                     (progn
                                         (if (not (vclip:activate-doc-v31 newdoc))
                                             (princ "\nVPOEXPORT: nie udalo sie aktywowac pliku wynikowego. Czyszczenie przerwane.")
                                             (progn
                                                 (if (not (vclip:active-document-path-is-v32 dst))
                                                     (princ "\nVPOEXPORT: BEZPIECZNIK - aktywny dokument nie jest plikiem wynikowym. Czyszczenie przerwane.")
                                                     (progn
                                                         (setq result (vclip:clip-current-document-by-layout-v31 keep-lay nil))
                                                         (if result
                                                             (progn
                                                                 (if (vclip:save-doc-v31 newdoc)
                                                                     (princ (strcat "\nVPOEXPORT: zapisano plik wynikowy: " dst))
                                                                     (princ "\nVPOEXPORT: UWAGA - nie udalo sie zapisac pliku wynikowego.")
                                                                 )
                                                             )
                                                             (princ "\nVPOEXPORT: czyszczenie pliku wynikowego nie zostalo wykonane poprawnie.")
                                                         )
                                                     )
                                                 )
                                             )
                                         )
                                         (vclip:activate-doc-v31 srcdoc)
              (if vclip:acad-close-copy-v36
                  (progn
                      (vclip:trace-v35 "CLOSE COPY")
                      (vclip:close-doc-nosave-v31 newdoc)
                  )
                  (progn
                      (princ "\nVPOCFG: BricsCAD SAFE - zostawiam plik wynikowy otwarty, zeby uniknac zamkniecia BricsCAD-a.")
                      (vclip:trace-v35 "CLOSE COPY SKIP safe mode")
                  )
              )
                                     )
                                 )
                             )
                         )
                     )
                 )
             )
         )
        )
    )
    (princ)
)

(defun vclip:legacy-command-vpoonlyexport () (c:VPOEXPORT))


;;------------------------------------------------------------------;;
;;  OVERRIDE v3.7-acad - eksport przez skrypt BricsCAD               ;;
;;------------------------------------------------------------------;;
(defun vclip:path-slash-v37 ( path )
    (if path (vl-string-translate "\\" "/" path) "")
)

(defun vclip:script-quote-v37 ( path )
    (strcat "\"" (vclip:path-slash-v37 path) "\"")
)

(defun vclip:lisp-quote-v37 ( value / s )
    (setq s (if value value ""))
    (strcat "\"" (vl-string-subst "'" "\"" s) "\"")
)

(defun vclip:acad-batch-script-path-v37 ( srcpath )
    (strcat (vclip:dir-with-sep-v34 srcpath) "VPOCLIP_brics_batch.scr")
)

(defun vclip:self-lisp-path-v37 ( )
    ;; Bez ścieżki użytkownika; delegacja do aktywnej implementacji v3.12.
    (vclip:self-lisp-path-v312)
)


(defun vclip:normalize-path-v38 ( path )
    (strcase (vl-string-translate "/" "\\" (if path path "")))
)

(defun vclip:same-path-p-v38 ( a b )
    (= (vclip:normalize-path-v38 a) (vclip:normalize-path-v38 b))
)

(defun vclip:source-collision-target-v38 ( dst / dir base alt )
    (setq dir  (vclip:dir-with-sep-v34 dst)
          base (vl-filename-base dst)
          alt  (strcat dir base "_VPOCLIP.dwg"))
    alt
)

(defun vclip:target-path-acad-v38 ( srcpath filename / dst alt )
    (setq dst (vclip:target-path-from-config-v34 srcpath filename))
    (if (and dst (vclip:same-path-p-v38 srcpath dst))
        (progn
            (setq alt (vclip:source-collision-target-v38 dst))
            (princ (strcat "\nVPOCFG: nazwa wynikowa jest taka sama jak plik zrodlowy. Uzywam bezpiecznej kopii: " alt))
            (vclip:trace-v35 (strcat "TARGET COLLISION src=dst, using " alt))
            alt
        )
        dst
    )
)
(defun vclip:acad-process-current-file-v37 ( keep-lay pattern / doc path result xres saved pdf pdf-ok )
    (vl-load-com)
    (setq doc  (LM:acdoc)
          path (vclip:current-dwg-path-v31))
    (vclip:trace-v35 (strcat "SCRIPT PROCESS START file=" path " layout=" keep-lay " pattern=" pattern))
    (cond
        ((or (null path) (= "" path))
         (princ "\nVPOCFG SCRIPT: aktywny plik nie ma sciezki DWG.")
         (vclip:trace-v35 "SCRIPT PROCESS FAIL no dwg path")
         nil
        )
        ((not (vclip:layout-exists-p keep-lay))
         (princ (strcat "\nVPOCFG SCRIPT: layout nie istnieje: " keep-lay))
         (vclip:trace-v35 (strcat "SCRIPT PROCESS FAIL missing layout " keep-lay))
         nil
        )
        (T
         (setq vclip:extra-keep-xref-pattern-v34 pattern)
         (vclip:trace-v35 "SCRIPT CLIP START")
         (setq result (vclip:clip-current-document-by-layout-v31 keep-lay nil))
         (vclip:trace-v35 (strcat "SCRIPT CLIP END result=" (if result "OK" "FAIL")))
         (setq vclip:extra-keep-xref-pattern-v34 nil)
         (if result
             (progn
                 (vclip:trace-v35 "SCRIPT XREF FILTER START")
                 (setq xres (vclip:filter-xrefs-v34 pattern))
                 (vclip:trace-v35 "SCRIPT XREF FILTER END")
                 (princ "\nVPOCFG SCRIPT: finalny PURGE po filtrze XREF...")
                 (vclip:trace-v35 "SCRIPT PURGE START")
                 (if (vclip:purge-all-v33)
                     (princ " OK")
                     (princ " UWAGA - PURGE nie zostal wykonany poprawnie")
                 )
                 (vclip:trace-v35 "SCRIPT PURGE END")
                 (vclip:trace-v35 "SCRIPT SAVE START")
                 (setq saved (vclip:save-doc-v31 doc))
                 (vclip:trace-v35 (strcat "SCRIPT SAVE END result=" (if saved "OK" "FAIL")))
                 (if saved
                     (progn
                         (princ (strcat "\nVPOCFG SCRIPT: zapisano plik wynikowy: " path))
                         (if vclip:acad-plot-pdf-v36
                             (progn
                                 (setq pdf (vclip:pdf-path-from-dwg-v35 path))
                                 (vclip:trace-v35 (strcat "SCRIPT PDF CALL " pdf))
                                 (setq pdf-ok (vclip:plot-layout-to-pdf-v35 keep-lay pdf))
                                 (vclip:trace-v35 (strcat "SCRIPT PDF END result=" (if pdf-ok "OK" "FAIL")))
                                 (if pdf-ok (vclip:save-doc-v31 doc))
                             )
                             (progn
                                 (setq pdf-ok T)
                                 (vclip:trace-v35 "SCRIPT PDF SKIP disabled")
                             )
                         )
                     )
                     (princ "\nVPOCFG SCRIPT: UWAGA - nie udalo sie zapisac pliku wynikowego.")
                 )
             )
             (princ "\nVPOCFG SCRIPT: czyszczenie nie zostalo wykonane poprawnie.")
         )
         (and result saved (or (not vclip:acad-plot-pdf-v36) pdf-ok))
        )
    )
)

(defun vclip:write-acad-batch-script-v37 ( script tasks / fh task dwg lay pattern lisp )
    (setq lisp (vclip:self-lisp-path-v37))
    (if (setq fh (open script "w"))
        (progn
            (write-line "FILEDIA" fh)
            (write-line "0" fh)
            (write-line "CMDDIA" fh)
            (write-line "0" fh)
            (foreach task tasks
                (setq lay     (car task)
                      dwg     (cadr task)
                      pattern (caddr task))
                (write-line "_.OPEN" fh)
                (write-line (vclip:script-quote-v37 dwg) fh)
                (write-line (strcat "(load " (vclip:script-quote-v37 lisp) ")") fh)
                (write-line (strcat "(vclip:acad-process-current-file-v37 " (vclip:lisp-quote-v37 lay) " " (vclip:lisp-quote-v37 pattern) ")") fh)
            )
            (write-line "FILEDIA" fh)
            (write-line "1" fh)
            (write-line "CMDDIA" fh)
            (write-line "1" fh)
            (close fh)
            script
        )
        nil
    )
)

(defun vclip:run-acad-script-v39 ( script / doc cmd )
    (setq doc (LM:acdoc))
    (vclip:trace-v35 (strcat "SCRIPT RUN " script))
    (princ (strcat "\nVPOCFG BricsCAD SCRIPT: plik SCR: " script))
    (princ "\nVPOCFG BricsCAD SCRIPT: wylaczam FILEDIA/CMDDIA i podaje sciezke automatycznie.")
    (vl-catch-all-apply 'setvar (list 'FILEDIA 0))
    (vl-catch-all-apply 'setvar (list 'CMDDIA 0))
    (setq cmd
        (strcat
            "FILEDIA\n0\n"
            "CMDDIA\n0\n"
            "_.SCRIPT\n"
            (vclip:script-quote-v37 script)
            "\nFILEDIA\n1\n"
        )
    )
    (vla-SendCommand doc cmd)
    T
)

(defun vclip:legacy-command-vpoexportcfg ( / srcdoc srcpath cfg rows overwrite-key overwrite tasks rec keep-lay dst pattern script run-key ok skip fail )
    (vl-load-com)
    (setq srcdoc  (LM:acdoc)
          srcpath (vclip:current-dwg-path-v31)
          tasks   nil
          ok      0
          skip    0
          fail    0)
    (cond
        ((or (null srcpath) (not (findfile srcpath)) (= 0 (getvar 'dwgtitled)))
         (princ "\nVPOCFG: najpierw zapisz rysunek zrodlowy jako DWG.")
        )
        ((/= 0 (getvar 'dbmod))
         (princ "\nVPOCFG: rysunek ma niezapisane zmiany. Zapisz go najpierw, a potem uruchom VPOEXPORTCFG.")
        )
        ((/= 0 (vclip:getvar-safe-v35 'SDI 0))
         (princ "\nVPOCFG: BricsCAD ma SDI=1. Ustaw SDI na 0 i uruchom BricsCAD ponownie przed wsadowym eksportem.")
        )
        ((null (setq cfg (vclip:config-path-v34)))
         (princ "\nVPOCFG: nie wskazano pliku VPOCLIP_CONF.txt.")
        )
        ((null (setq rows (vclip:read-config-v34 cfg)))
         (princ "\nVPOCFG: brak poprawnych wierszy konfiguracji.")
        )
        (T
         (princ (strcat "\nVPOCFG BricsCAD SCRIPT: plik konfiguracji: " cfg))
         (princ (strcat "\nVPOCFG BricsCAD SCRIPT: liczba zadan: " (itoa (length rows))))
         (initget "Tak Nie")
         (setq overwrite-key (getkword "\nVPOCFG: nadpisac istniejace pliki wynikowe? [Tak/Nie] <Nie>: "))
         (setq overwrite (= overwrite-key "Tak"))
         (foreach rec rows
             (setq keep-lay (car rec)
                   pattern  (caddr rec)
                   dst      (vclip:target-path-acad-v38 srcpath (cadr rec)))
             (cond
                 ((not (vclip:layout-exists-p keep-lay))
                  (setq fail (1+ fail))
                  (princ (strcat "\nVPOCFG: layout nie istnieje w pliku zrodlowym: " keep-lay))
                 )
                 ((not (vclip:copy-dwg-to-target-auto-v34 srcpath dst overwrite))
                  (setq skip (1+ skip))
                 )
                 (T
                  (setq ok (1+ ok))
                  (setq tasks (append tasks (list (list keep-lay dst pattern))))
                  (princ (strcat "\nVPOCFG: przygotowano kopie: " dst))
                 )
             )
         )
         (if tasks
             (progn
                 (setq script (vclip:acad-batch-script-path-v37 srcpath))
                 (if (vclip:write-acad-batch-script-v37 script tasks)
                     (progn
                         (princ (strcat "\nVPOCFG BricsCAD SCRIPT: zapisano skrypt: " script))
                         (princ (strcat "\nVPOCFG BricsCAD SCRIPT: przygotowano: " (itoa ok) " / pominieto: " (itoa skip) " / bledy: " (itoa fail)))
                         (initget "Tak Nie")
                         (setq run-key (getkword "\nVPOCFG: uruchomic teraz skrypt BricsCAD? [Tak/Nie] <Tak>: "))
                         (if (/= run-key "Nie")
                             (progn
                                 (princ "\nVPOCFG BricsCAD SCRIPT: uruchamiam skrypt. BricsCAD bedzie przechodzil po plikach wynikowych.")
                                 (vclip:run-acad-script-v39 script)
                             )
                             (princ (strcat "\nVPOCFG: uruchom pozniej poleceniem SCRIPT i wskaz plik: " script))
                         )
                     )
                     (princ "\nVPOCFG: nie udalo sie zapisac skryptu BricsCAD.")
                 )
             )
             (princ "\nVPOCFG: nie przygotowano zadnych plikow do obrobki.")
         )
        )
    )
    (princ)
)

(defun vclip:legacy-command-vpobatch () (c:VPOEXPORTCFG))
(defun vclip:legacy-command-vpocfg () (c:VPOEXPORTCFG))
;; Komendy aktywne są definiowane w sekcji v3.12 poniżej.
(princ)

;;==================================================================;;
;;                    End of File v3.10-acad                              ;;
;;==================================================================;;

;;==================================================================;;
;;  OVERRIDE v3.39-brics - stabilny eksport transakcyjny             ;;
;;==================================================================;;

(setq vclip:version-v312 "3.39-brics"
      vclip:self-deployment-v312 "C:/VPOCLIP/VPOCLIP_v3.39_brics.lsp"
      vclip:self-file-v312 (findfile vclip:self-deployment-v312)
      vclip:batch-report-v312 nil)

;; Lokalizacja pakietu jest jawna, stala i niezalezna od profilu BricsCAD-a.

(defun vclip:trace-v35 ( msg / res )
    ;; Diagnostyka nigdy nie może przerwać właściwego zadania.
    (if vclip:acad-trace-v35
        (setq res
            (vl-catch-all-apply
                '(lambda ( / dir path f stamp )
                     (setq dir (vclip:getvar-safe-v35 'DWGPREFIX ""))
                     (if (= dir "") (setq dir "C:\\TMP\\"))
                     (setq path  (strcat dir "VPOCLIP_brics_trace.txt")
                           stamp (rtos (vclip:getvar-safe-v35 'CDATE 0.0) 2 8)
                           f     (open path "a"))
                     (if f
                         (progn
                             (write-line
                                 (strcat stamp " | " (if msg msg "<nil>")) f)
                             (close f)
                         )
                     )
                 )
                nil
            )
        )
    )
    nil
)

(defun vclip:file-delete-confirmed-v312 ( path / r )
    (if (or (null path) (= path "") (not (findfile path)))
        T
        (progn
            (setq r (vl-catch-all-apply 'vl-file-delete (list path)))
            (and (not (vl-catch-all-error-p r)) (not (findfile path)))
        )
    )
)

(defun vclip:file-rename-attempt-v312 ( old new / r fso oldwin newwin )
    (setq r (vl-catch-all-apply 'vl-file-rename (list old new)))
    (if (and (not (findfile old)) (findfile new))
        T
        (progn
            ;; OneDrive reparse points can reject vl-file-rename even when
            ;; Windows MoveFile can complete the same atomic move.
            (setq oldwin (vl-string-translate "/" "\\" old)
                  newwin (vl-string-translate "/" "\\" new)
                  fso    (vl-catch-all-apply
                             'vlax-create-object
                             (list "Scripting.FileSystemObject")))
            (if (not (vl-catch-all-error-p fso))
                (progn
                    (if (and (findfile old) (not (findfile new)))
                        (setq r
                            (vl-catch-all-apply
                                'vlax-invoke-method
                                (list fso 'MoveFile oldwin newwin))))
                    (vlax-release-object fso)))
            (and (not (findfile old)) (findfile new))
        )
    )
)

(defun vclip:file-rename-confirmed-v312 ( old new / attempt ok )
    (setq attempt 0
          ok      nil)
    (if (and old new (findfile old) (not (findfile new)))
        (while (and (not ok) (< attempt 12))
            (setq attempt (1+ attempt)
                  ok      (vclip:file-rename-attempt-v312 old new))
            (if (not ok)
                (vl-catch-all-apply 'vlax-sleep (list 250)))))
    ok
)

(defun vclip:file-copy-confirmed-v312 ( old new / r )
    (if (and old new (findfile old) (not (findfile new)))
        (progn
            (setq r (vl-catch-all-apply 'vl-file-copy (list old new)))
            (and (not (vl-catch-all-error-p r)) (findfile new)))
        nil)
)
(defun vclip:open-control-v325 ( path mode / r )
    ;; MBCS is CP-1250 on a Polish Windows installation. BricsCAD V26
    ;; accepts the third argument; the fallback supports the legacy engine.
    (setq r (vl-catch-all-apply 'open (list path mode "mbcs")))
    (if (vl-catch-all-error-p r)
        (open path mode)
        r)
)

(defun vclip:write-control-text-v325 ( path value / r )
    (setq r
        (vl-catch-all-apply
            '(lambda ( / f )
                 (if (setq f (vclip:open-control-v325 path "w"))
                     (progn
                         (write-line (if value value "") f)
                         (close f)
                         T)
                     nil))
            nil))
    (and (not (vl-catch-all-error-p r)) r)
)

(defun vclip:append-control-text-v325 ( path value / r )
    (setq r
        (vl-catch-all-apply
            '(lambda ( / f )
                 (if (setq f (vclip:open-control-v325 path "a"))
                     (progn
                         (write-line (if value value "") f)
                         (close f)
                         T)
                     nil))
            nil))
    (and (not (vl-catch-all-error-p r)) r)
)
(defun vclip:write-text-v312 ( path value / r )
    (setq r
        (vl-catch-all-apply
            '(lambda ( / f )
                 (if (setq f (open path "w"))
                     (progn
                         (write-line (if value value "") f)
                         (close f)
                         T
                     )
                     nil
                 )
             )
            nil
        )
    )
    (and (not (vl-catch-all-error-p r)) r)
)

(defun vclip:append-text-v312 ( path value / r )
    (setq r
        (vl-catch-all-apply
            '(lambda ( / f )
                 (if (setq f (open path "a"))
                     (progn
                         (write-line (if value value "") f)
                         (close f)
                         T
                     )
                     nil
                 )
             )
            nil
        )
    )
    (and (not (vl-catch-all-error-p r)) r)
)

(defun vclip:read-first-line-v312 ( path / r )
    (setq r
        (vl-catch-all-apply
            '(lambda ( / f line )
                 (if (and path (findfile path) (setq f (open path "r")))
                     (progn
                         (setq line (read-line f))
                         (close f)
                         line
                     )
                 )
             )
            nil
        )
    )
    (if (vl-catch-all-error-p r) nil r)
)

(defun vclip:append-report-v312 ( text )
    (if (and vclip:batch-report-v312 (/= vclip:batch-report-v312 ""))
        (vclip:append-text-v312 vclip:batch-report-v312 text)
    )
)

(defun vclip:string-has-any-v312 ( value needles / hit needle )
    (setq hit nil)
    (foreach needle needles
        (if (and (not hit) (vl-string-search needle value))
            (setq hit T)
        )
    )
    hit
)

(defun vclip:reserved-filename-p-v312 ( base / up )
    (setq up (strcase base))
    (wcmatch up
        "CON,PRN,AUX,NUL,COM1,COM2,COM3,COM4,COM5,COM6,COM7,COM8,COM9,LPT1,LPT2,LPT3,LPT4,LPT5,LPT6,LPT7,LPT8,LPT9")
)

(defun vclip:valid-output-name-v312 ( value / s ext base last dirpart )
    (setq s    (vclip:trim-v34 value)
          ext  (if (/= s "") (vl-filename-extension s))
          base (if (/= s "") (vl-filename-base s))
          dirpart (if (/= s "") (vl-filename-directory s))
          last (if (> (strlen s) 0) (substr s (strlen s) 1) ""))
    (and (/= s "")
         base
         (/= base "")
         (or (null dirpart) (= "" dirpart))
         (not (vclip:string-has-any-v312
                  s (list "\\" "/" ":" "*" "?" "<" ">" "|" (chr 34))))
         (not (vl-string-search ".." s))
         (/= last ".")
         (or (null ext) (= ".DWG" (strcase ext)))
         (not (vclip:reserved-filename-p-v312 base)))
)

(defun vclip:validated-dwg-name-v312 ( value / s )
    (setq s (vclip:trim-v34 value))
    (if (vclip:valid-output-name-v312 s)
        (if (vl-filename-extension s) s (strcat s ".dwg"))
    )
)


(defun vclip:work-path-v312 ( final / dir base stamp )
    (setq dir   (vclip:dir-with-sep-v34 final)
          base  (vl-filename-base final)
          stamp (vclip:timestamp))
    (strcat dir base "._VPOCLIP_WORK_" stamp ".dwg")
)

(defun vclip:work-pdf-path-v312 ( workdwg )
    (strcat (vclip:dir-with-sep-v34 workdwg)
            (vl-filename-base workdwg) ".pdf")
)

(defun vclip:final-pdf-path-v312 ( finaldwg )
    (strcat (vclip:dir-with-sep-v34 finaldwg)
            (vl-filename-base finaldwg) ".pdf")
)

(defun vclip:self-lisp-file-p-v312 ( path )
    (and path
         (= 'STR (type path))
         (findfile path)
         (= (strcase (vl-filename-base vclip:self-deployment-v312))
            (strcase (vl-filename-base path)))
         (= ".LSP"
            (strcase (if (vl-filename-extension path)
                         (vl-filename-extension path)
                         ""))))
)

(defun vclip:remember-self-lisp-v312 ( path / resolved )
    (if (and (vclip:self-lisp-file-p-v312 path)
             (setq resolved (findfile path)))
        (progn
            (setq vclip:self-file-v312 resolved)
            resolved)
    )
)

(defun vclip:self-lisp-path-v312 ( )
    (cond
        ((vclip:remember-self-lisp-v312 vclip:self-file-v312))
        ((vclip:remember-self-lisp-v312 vclip:self-deployment-v312))
        (T
         (princ
             "\nVPOCFG: brak C:/VPOCLIP/VPOCLIP_v3.39_brics.lsp. Zainstaluj kompletny pakiet w C:/VPOCLIP.")
         nil)
    )
)

(defun vclip:config-path-v312 ( / self same )
    (if (setq self (vclip:self-lisp-path-v312))
        (setq same
            (findfile
                (strcat (vclip:dir-with-sep-v34 self) "VPOCLIP_CONF.txt")))
    )
    (if same
        same
        (progn
            (princ "\nVPOCFG: brak C:/VPOCLIP/VPOCLIP_CONF.txt.")
            nil))
)

(defun vclip:config-row-valid-v34 ( rec )
    ;; Pusty filtr jest ryzykowną literówką. Do jawnego zachowania
    ;; wszystkich XREF-ów służy wzorzec *.
    (and rec
         (= 3 (length rec))
         (/= "" (car rec))
         (/= "" (cadr rec))
         (/= "" (caddr rec))
         (not (wcmatch (strcase (car rec)) "NAZWA LAYOUTA*")))
)
(defun vclip:handle-equal-v312 ( a b )
    (and (= 'STR (type a))
         (= 'STR (type b))
         (= (strcase a) (strcase b)))
)

(defun vclip:vsub2-v312 ( a b )
    (list (- (car a) (car b)) (- (cadr a) (cadr b)))
)

(defun vclip:vlen2-v312 ( v )
    (sqrt (+ (* (car v) (car v)) (* (cadr v) (cadr v))))
)

(defun vclip:vdot2-v312 ( a b )
    (+ (* (car a) (car b)) (* (cadr a) (cadr b)))
)

(defun vclip:rect-points-p-v312
       ( pts / p0 p1 p2 p3 e0 e1 l0 l1 tol sum02 sum13 )
    (and (= 4 (length pts))
         (setq p0 (list (car (nth 0 pts)) (cadr (nth 0 pts)))
               p1 (list (car (nth 1 pts)) (cadr (nth 1 pts)))
               p2 (list (car (nth 2 pts)) (cadr (nth 2 pts)))
               p3 (list (car (nth 3 pts)) (cadr (nth 3 pts)))
               e0 (vclip:vsub2-v312 p1 p0)
               e1 (vclip:vsub2-v312 p2 p1)
               l0 (vclip:vlen2-v312 e0)
               l1 (vclip:vlen2-v312 e1))
         (> l0 1e-8)
         (> l1 1e-8)
         (<= (/ (abs (vclip:vdot2-v312 e0 e1)) (* l0 l1)) 1e-7)
         (setq tol (* 1e-7 (max 1.0 l0 l1))
               sum02 (mapcar '+ p0 p2)
               sum13 (mapcar '+ p1 p3))
         (<= (vclip:vlen2-v312 (vclip:vsub2-v312 sum02 sum13)) tol))
)

;;------------------------------------------------------------------;;
;;  Automatyczne ramki z prostokatnych rzutni - v3.39 BricsCAD      ;;
;;------------------------------------------------------------------;;

(defun vclip:strip-app-v339 ( enx app / item out )
    (foreach item enx
        (if (and (= -3 (car item))
                 (cadr item)
                 (= app (car (cadr item))))
            nil
            (setq out (cons item out))))
    (reverse out)
)

(defun vclip:set-app-vla-v339 ( ent app value / error got object types values )
    (setq object (vlax-ename->vla-object ent)
          types  (vlax-make-safearray vlax-vbInteger '(0 . 1))
          values (vlax-make-safearray vlax-vbVariant '(0 . 1)))
    (vlax-safearray-fill types '(1001 1000))
    (vlax-safearray-put-element values 0 app)
    (vlax-safearray-put-element values 1 value)
    (setq error
        (vl-catch-all-apply 'vla-SetXData
            (list object types values)))
    (setq got (vclip:getappvalue ent app))
    (and (not (vl-catch-all-error-p error))
         (= 'STR (type got))
         (= (strcase got) (strcase value)))
)

(defun vclip:set-app-v339 ( ent app value / current enx result got )
    (if (and ent app value)
        (progn
            (if (not (tblsearch "APPID" app)) (regapp app))
            (setq current (vclip:getappvalue ent app))
            (if (and (= 'STR (type current))
                     (= (strcase current) (strcase value)))
                T
                (if (vclip:set-app-vla-v339 ent app value)
                    T
                    (progn
                        (setq enx (vclip:strip-app-v339
                                        (entget ent '("*")) app)
                              result
                                (vl-catch-all-apply
                                    'entmod
                                    (list
                                        (append enx
                                            (list
                                                (list -3
                                                    (list app
                                                        (cons 1000 value))))))))
                        (if (not (vl-catch-all-error-p result))
                            (entupd ent))
                        (setq got (vclip:getappvalue ent app))
                        (and (= 'STR (type got))
                             (= (strcase got) (strcase value))))))))
)
(defun vclip:clear-app-vla-v339 ( ent app / error object types values )
    (setq object (vlax-ename->vla-object ent)
          types  (vlax-make-safearray vlax-vbInteger '(0 . 0))
          values (vlax-make-safearray vlax-vbVariant '(0 . 0)))
    (vlax-safearray-put-element types 0 1001)
    (vlax-safearray-put-element values 0 app)
    (setq error
        (vl-catch-all-apply 'vla-SetXData
            (list object types values)))
    (and (not (vl-catch-all-error-p error))
         (null (vclip:getappvalue ent app)))
)

(defun vclip:clear-app-v339 ( ent app / enx result )
    (if (and ent app)
        (if (vclip:getappvalue ent app)
            (if (vclip:clear-app-vla-v339 ent app)
                T
                (progn
                    (setq enx (vclip:strip-app-v339
                                    (entget ent '("*")) app)
                          result (vl-catch-all-apply 'entmod (list enx)))
                    (if (not (vl-catch-all-error-p result))
                        (entupd ent))
                    (null (vclip:getappvalue ent app))))
            T))
)
(defun vclip:ensure-nplt-layer-v339 ( / doc layers layer result )
    (setq doc (LM:acdoc)
          layers (vla-get-Layers doc))
    (setq layer
        (vl-catch-all-apply 'vla-Item (list layers vclip:nplt-lay)))
    (if (vl-catch-all-error-p layer)
        (setq layer
            (vl-catch-all-apply 'vla-Add (list layers vclip:nplt-lay))))
    (if (not (vl-catch-all-error-p layer))
        (progn
            (vl-catch-all-apply 'vlax-put-property
                (list layer 'Plottable :vlax-false))
            (vl-catch-all-apply 'vlax-put-property
                (list layer 'LayerOn :vlax-true))
            (vl-catch-all-apply 'vlax-put-property
                (list layer 'Freeze :vlax-false))
            (vl-catch-all-apply 'vlax-put-property
                (list layer 'Lock :vlax-false))
            vclip:nplt-lay))
)

(defun vclip:auto-2d3d-v339 ( point )
    (cond
        ((= 3 (length point)) point)
        ((= 2 (length point)) (list (car point) (cadr point) 0.0))
        (point (append point (list 0.0)))
        (T '(0.0 0.0 0.0)))
)

(defun vclip:auto-transpose-v339 ( matrix )
    (apply 'mapcar (cons 'list matrix))
)

(defun vclip:auto-mxv-v339 ( matrix vector )
    (mapcar
        '(lambda ( row ) (apply '+ (mapcar '* row vector)))
        matrix)
)

(defun vclip:auto-mxm-v339 ( left right / transposed )
    (setq transposed (vclip:auto-transpose-v339 right))
    (mapcar
        '(lambda ( row ) (vclip:auto-mxv-v339 transposed row))
        left)
)

(defun vclip:auto-vxs-v339 ( vector scale )
    (mapcar '(lambda ( value ) (* value scale)) vector)
)

(defun vclip:auto-pcs2wcs-v339
       ( point viewport / angle enx matrix normal scale )
    (setq point  (trans point 0 0)
          enx    (entget viewport)
          angle  (- (cdr (assoc 51 enx)))
          normal (cdr (assoc 16 enx))
          scale  (/ (cdr (assoc 45 enx)) (cdr (assoc 41 enx)))
          matrix
            (vclip:auto-mxm-v339
                (mapcar
                    '(lambda ( vector ) (trans vector 0 normal T))
                    '((1.0 0.0 0.0)
                      (0.0 1.0 0.0)
                      (0.0 0.0 1.0)))
                (list
                    (list (cos angle) (- (sin angle)) 0.0)
                    (list (sin angle)    (cos angle)  0.0)
                    '(0.0 0.0 1.0))))
    (mapcar '+
        (vclip:auto-mxv-v339 matrix
            (mapcar '+
                (vclip:auto-vxs-v339 point scale)
                (vclip:auto-vxs-v339 (cdr (assoc 10 enx)) (- scale))
                (vclip:auto-2d3d-v339 (cdr (assoc 12 enx)))))
        (cdr (assoc 17 enx)))
)

(defun vclip:auto-viewport-paper-points-v339
       ( viewport / boundary center enx half-height half-width points )
    (setq enx (entget viewport))
    (if (setq boundary (cdr (assoc 340 enx)))
        (if (and (entget boundary)
                 (= "LWPOLYLINE" (cdr (assoc 0 (entget boundary)))))
            (setq points (vclip:polyvertices boundary)))
        (progn
            (setq center      (cdr (assoc 10 enx))
                  half-width  (/ (cdr (assoc 40 enx)) 2.0)
                  half-height (/ (cdr (assoc 41 enx)) 2.0)
                  points
                    (list
                        (list (- (car center) half-width)
                              (- (cadr center) half-height))
                        (list (+ (car center) half-width)
                              (- (cadr center) half-height))
                        (list (+ (car center) half-width)
                              (+ (cadr center) half-height))
                        (list (- (car center) half-width)
                              (+ (cadr center) half-height))))))
    points
)

(defun vclip:auto-frame-spec-v339
       ( viewport / enx normal paper-points result wcs-points ocs-points )
    (setq enx (entget viewport)
          normal (cdr (assoc 16 enx)))
    (if (null normal) (setq normal '(0.0 0.0 1.0)))
    (cond
        ((or (null (cdr (assoc 41 enx)))
             (null (cdr (assoc 45 enx)))
             (equal 0.0 (cdr (assoc 41 enx)) 1e-12))
         (list nil "rzutnia ma niepoprawna skale"))
        ((null (setq paper-points
                    (vclip:auto-viewport-paper-points-v339 viewport)))
         (list nil "nie mozna odczytac obrysu rzutni"))
        ((not (vclip:rect-points-p-v312 paper-points))
         (list nil "obrys rzutni nie jest prostokatem"))
        (T
         (setq result
            (vl-catch-all-apply
                '(lambda ( / point out )
                     (foreach point paper-points
                         (setq out
                             (cons
                                 (vclip:auto-pcs2wcs-v339 point viewport)
                                 out)))
                     (reverse out))
                nil))
         (if (vl-catch-all-error-p result)
             (list nil
                 (strcat "blad transformacji rzutni: "
                         (vl-catch-all-error-message result)))
             (progn
                 (setq wcs-points result)
                 (if (not (vclip:rect-points-p-v312 wcs-points))
                     (list nil "obrys rzutni po transformacji nie jest prostokatem")
                     (progn
                         (setq ocs-points
                             (mapcar
                                 '(lambda ( point ) (trans point 0 normal))
                                 wcs-points))
                         (list T viewport wcs-points ocs-points normal)))))))
)

(defun vclip:auto-frame-plan-v339
       ( layout / check errors index selection spec specs viewport )
    (setq selection
        (ssget "_X"
            (list '(0 . "VIEWPORT") '(-4 . "<>") '(69 . 1)
                  (cons 410 layout)))
          index 0
          specs nil
          errors nil)
    (if selection
        (while (< index (sslength selection))
            (setq viewport (ssname selection index)
                  index (1+ index)
                  check (vclip:auto-frame-spec-v339 viewport))
            (if (car check)
                (setq specs (cons check specs))
                (setq errors
                    (cons
                        (list (vclip:handle-v30 viewport) (cadr check))
                        errors)))))
    (if (null selection)
        (setq errors (list (list nil "layout nie ma rzutni papieru"))))
    (list (reverse specs) (reverse errors))
)

(defun vclip:print-auto-frame-errors-v339 ( layout errors / item )
    (foreach item errors
        (princ
            (strcat "\nVPOCLIP FRAME: layout " layout ", rzutnia "
                (if (car item) (car item) "<brak>") " - " (cadr item)))
        (vclip:trace-v35
            (strcat "AUTO FRAME FAIL layout=" layout
                " viewport=" (if (car item) (car item) "<nil>")
                " reason=" (cadr item))))
)

(defun vclip:only-stale-frame-links-p-v339 ( errors / item ok )
    (setq ok (if errors T nil))
    (foreach item errors
        (if (not (eq 'STALE_FRAME_LINK (caddr item)))
            (setq ok nil)))
    ok
)

(defun vclip:clear-stale-layout-links-v339
       ( layout / cleared failed index phe raw selection viewport )
    (setq selection
        (ssget "_X" (list '(0 . "VIEWPORT") (cons 410 layout)))
          index 0
          cleared 0
          failed 0)
    (if selection
        (while (< index (sslength selection))
            (setq viewport (ssname selection index)
                  index (1+ index)
                  raw (vclip:getlink viewport))
            (if raw
                (progn
                    (setq phe (handent raw))
                    (if (or (null phe) (null (entget phe)))
                        (if (vclip:clear-app-v339 viewport vclip:xapp)
                            (setq cleared (1+ cleared))
                            (setq failed (1+ failed))))))))
    (vclip:trace-v35
        (strcat "STALE LINKS layout=" layout
            " cleared=" (itoa cleared) " failed=" (itoa failed)))
    (list (= failed 0) cleared failed)
)

(defun vclip:auto-frame-plan-ready-v339 ( layout / plan )
    (setq plan (vclip:auto-frame-plan-v339 layout))
    (if (cadr plan)
        (progn
            (vclip:print-auto-frame-errors-v339 layout (cadr plan))
            nil)
        T)
)

(defun vclip:layout-ready-for-cleanup-v339
       ( layout auto-create / frames invalid linked plan )
    (setq plan (vclip:collect-frames-for-layout-v312 layout)
          frames (car plan)
          linked (cadr plan)
          invalid (caddr plan))
    (cond
        ((and auto-create
              (= 0 (length frames))
              (vclip:only-stale-frame-links-p-v339 invalid))
         (princ
             (strcat "\nVPOCFG PRECHECK: layout " layout " ma "
                 (itoa (length invalid))
                 " osieroconych linkow VPO_LINK; ramki zostana odtworzone."))
         (vclip:auto-frame-plan-ready-v339 layout))
        (invalid
         (vclip:print-frame-errors-v312 invalid)
         nil)
        ((> linked 0)
         (if (= linked (length frames))
             T
             (progn
                 (princ
                     (strcat "\nVPOCFG PRECHECK: layout " layout
                             " ma niespojna liczbe rzutni i ramek."))
                 nil)))
        ((not auto-create)
         (princ
             (strcat "\nVPOCFG PRECHECK: layout " layout
                     " nie ma ramek VPOutline, a Auto_Create_Frames=NO."))
         nil)
        (T (vclip:auto-frame-plan-ready-v339 layout)))
)
(defun vclip:create-auto-frame-record-v339
       ( layout spec / frame frame-handle height label normal ocs-points
                       viewport viewport-data viewport-handle wcs-points )
    (setq vclip:auto-frame-debug-v339 (list "START" layout)
          viewport       (nth 1 spec)
          wcs-points      (nth 2 spec)
          ocs-points      (nth 3 spec)
          normal          (nth 4 spec)
          viewport-data   (entget viewport)
          viewport-handle (vclip:handle-v30 viewport))
    (if (and viewport-handle (vclip:ensure-nplt-layer-v339))
        (progn
            (setq frame
                (entmakex
                    (append
                        (list
                            '(0 . "LWPOLYLINE")
                            '(100 . "AcDbEntity")
                            (cons 8 vclip:nplt-lay)
                            '(100 . "AcDbPolyline")
                            (cons 90 4)
                            '(70 . 1)
                            '(410 . "Model"))
                        (apply 'append
                            (mapcar
                                '(lambda ( point )
                                     (list
                                         (cons 10
                                             (list (car point) (cadr point)))
                                         '(42 . 0.0)))
                                ocs-points))
                        (list (cons 210 normal)))))
            (setq vclip:auto-frame-debug-v339
                (append vclip:auto-frame-debug-v339
                    (list (if frame "FRAME_OK" "FRAME_FAIL"))))
            (if frame
                (progn
                    (setq frame-handle (vclip:handle-v30 frame)
                          height
                            (max 1.0
                                (* 2.5
                                   (/ (abs (cdr (assoc 45 viewport-data)))
                                      (abs (cdr (assoc 41 viewport-data))))))
                          label
                            (entmakex
                                (list
                                    '(0 . "TEXT")
                                    '(100 . "AcDbEntity")
                                    (cons 8 vclip:nplt-lay)
                                    '(100 . "AcDbText")
                                    (cons 10 (car wcs-points))
                                    (cons 40 height)
                                    (cons 1 layout)
                                    '(50 . 0.0)
                                    '(410 . "Model"))))
                    (setq vclip:auto-frame-debug-v339
                        (append vclip:auto-frame-debug-v339
                            (list (if label "LABEL_OK" "LABEL_FAIL"))))
                    (if (and label
                             (vclip:set-app-v339 viewport vclip:xapp frame-handle)
                             (vclip:set-app-v339 frame vclip:xapp viewport-handle)
                             (vclip:set-app-v339 frame vclip:tapp
                                 (vclip:handle-v30 label))
                             (vclip:set-app-v339 label vclip:tapp frame-handle))
                        (list viewport frame label)
                        (progn
                            (setq vclip:auto-frame-debug-v339
                                (append vclip:auto-frame-debug-v339
                                    (list "LINK_FAIL"
                                        (vclip:getappvalue viewport vclip:xapp)
                                        (vclip:getappvalue frame vclip:xapp)
                                        (vclip:getappvalue frame vclip:tapp)
                                        (if label (vclip:getappvalue label vclip:tapp) nil))))
                            (vclip:clear-app-v339 viewport vclip:xapp)
                            (if label (vclip:safe-delete-entity label))
                            (vclip:safe-delete-entity frame)
                            nil))))))
)

(defun vclip:remove-auto-frame-records-v339
       ( records keep / deleted failed frame item label record viewport )
    (setq deleted 0 failed 0)
    (foreach record records
        (setq viewport (nth 0 record)
              frame    (nth 1 record)
              label    (nth 2 record))
        (if (not (vclip:clear-app-v339 viewport vclip:xapp))
            (setq failed (1+ failed)))
        (foreach item (list label frame)
            (if item
                (progn
                    (if (and keep (ssmemb item keep)) (ssdel item keep))
                    (if (or (null (entget item))
                            (vclip:safe-delete-entity item))
                        (setq deleted (1+ deleted))
                        (setq failed (1+ failed)))))))
    (list (= failed 0) deleted failed)
)

(defun vclip:create-auto-frames-v339
       ( layout / created oldtab plan record spec )
    (setq plan (vclip:auto-frame-plan-v339 layout))
    (if (cadr plan)
        (progn
            (vclip:print-auto-frame-errors-v339 layout (cadr plan))
            nil)
        (progn
            (setq oldtab (getvar 'CTAB))
            (vl-catch-all-apply 'setvar (list 'CTAB "Model"))
            (foreach spec (car plan)
                (if (setq record
                        (vclip:create-auto-frame-record-v339 layout spec))
                    (setq created (cons record created))))
            (if (and oldtab (vclip:layout-exists-p oldtab))
                (vl-catch-all-apply 'setvar (list 'CTAB oldtab)))
            (setq created (reverse created))
            (if (= (length created) (length (car plan)))
                created
                (progn
                    (vclip:remove-auto-frame-records-v339 created nil)
                    nil))))
)

(defun vclip:ensure-layout-frames-v339
       ( layout auto-create / created frames invalid linked pre stale-clean stale-count )
    (setq pre (vclip:collect-frames-for-layout-v312 layout)
          frames (car pre)
          linked (cadr pre)
          invalid (caddr pre)
          stale-count 0)
    (if (and auto-create
             (= 0 (length frames))
             (vclip:only-stale-frame-links-p-v339 invalid))
        (progn
            (setq stale-clean
                (vclip:clear-stale-layout-links-v339 layout))
            (if (car stale-clean)
                (progn
                    (setq stale-count (cadr stale-clean)
                          pre (vclip:collect-frames-for-layout-v312 layout)
                          frames (car pre)
                          linked (cadr pre)
                          invalid (caddr pre))))))
    (cond
        ((and stale-clean (not (car stale-clean)))
         (list nil nil
             (strcat "nie usunieto osieroconych VPO_LINK; bledy="
                 (itoa (caddr stale-clean)))))
        (invalid (list nil nil "uszkodzone linki VPOutline"))
        ((> linked 0)
         (if (= linked (length frames))
             (list T nil "istniejace ramki VPOutline")
             (list nil nil "niespojna liczba ramek VPOutline")))
        ((not auto-create)
         (list nil nil "brak ramek VPOutline i Auto_Create_Frames=NO"))
        ((null (setq created (vclip:create-auto-frames-v339 layout)))
         (list nil nil "nie utworzono automatycznych ramek"))
        (T
         (setq pre (vclip:collect-frames-for-layout-v312 layout)
               frames (car pre)
               linked (cadr pre)
               invalid (caddr pre))
         (if (and (null invalid)
                  (= linked (length frames))
                  (= linked (length created)))
             (list T created
                 (strcat
                     (if (> stale-count 0)
                         (strcat "usunieto stare linki: " (itoa stale-count) "; ")
                         "")
                     "utworzono ramek: " (itoa (length created))))
             (progn
                 (vclip:remove-auto-frame-records-v339 created nil)
                 (list nil nil "kontrola automatycznych ramek nie powiodla sie")))))
)
(defun vclip:frame-contract-v312
       ( vpe phe / enx pts rec rev vh txtval txt typ txtback ph flags )
    (setq vh (vclip:handle-v30 vpe))
    (cond
        ((null phe) (list nil "VPO_LINK wskazuje nieistniejącą ramkę"))
        ((null (setq enx (entget phe)))
         (list nil "nie można odczytać ramki"))
        ((/= "LWPOLYLINE" (cdr (assoc 0 enx)))
         (list nil "ramka nie jest LWPOLYLINE"))
        ((/= "MODEL" (strcase (if (cdr (assoc 410 enx))
                                  (cdr (assoc 410 enx)) "")))
         (list nil "ramka nie leży w ModelSpace"))
        ((/= (strcase vclip:nplt-lay)
             (strcase (if (cdr (assoc 8 enx)) (cdr (assoc 8 enx)) "")))
         (list nil "ramka nie leży na warstwie VPO-NPLT"))
        ((progn
             (setq flags (if (cdr (assoc 70 enx)) (cdr (assoc 70 enx)) 0))
             (= 0 (logand 1 flags)))
         (list nil "ramka nie jest zamknięta"))
        ((progn (setq pts (vclip:polyvertices-wcs phe))
                (/= 4 (length pts)))
         (list nil "ramka nie ma czterech wierzchołków"))
        ((not (vclip:rect-points-p-v312 pts))
         (list nil "ramka nie jest poprawnym prostokątem"))
        ((not (vclip:handle-equal-v312 (vclip:getlink phe) vh))
         (list nil "link ramka -> rzutnia nie jest wzajemny"))
        ((or (null (setq txtval (vclip:getappvalue phe vclip:tapp)))
             (null (setq txt (handent txtval))))
         (list nil "brak istniejącej etykiety VPO_TEXT"))
        ((progn
             (setq typ (cdr (assoc 0 (entget txt))))
             (not (member typ '("TEXT" "MTEXT"))))
         (list nil "VPO_TEXT nie wskazuje obiektu TEXT/MTEXT"))
        ((progn
             (setq ph      (vclip:handle-v30 phe)
                   txtback (vclip:getappvalue txt vclip:tapp))
             (not (vclip:handle-equal-v312 txtback ph)))
         (list nil "link etykieta -> ramka nie jest wzajemny"))
        ((null (setq rec (vclip:frame-record-from-entity phe)))
         (list nil "nie można utworzyć rekordu geometrii ramki"))
        (T (list T rec txt))
    )
)

(defun vclip:collect-frames-for-layout-v312
       ( lay / sel i vpe raw phe check frames linked invalid used )
    (setq frames  nil
          linked  0
          invalid nil
          used    nil
          sel     (ssget "_X"
                      (list '(0 . "VIEWPORT") (cons 410 lay))))
    (if sel
        (progn
            (setq i 0)
            (while (< i (sslength sel))
                (setq vpe (ssname sel i)
                      i   (1+ i)
                      raw (vclip:getlink vpe))
                (if raw
                    (progn
                        (setq linked (1+ linked)
                              phe   (handent raw)
                              check (vclip:frame-contract-v312 vpe phe))
                        (if (car check)
                            (if (member phe used)
                                (setq invalid
                                    (cons
                                        (list (vclip:handle-v30 vpe)
                                              "ta sama ramka jest przypisana do kilku rzutni"
                                              'INVALID_FRAME)
                                        invalid))
                                (progn
                                    (setq frames (cons (cadr check) frames)
                                          used   (cons phe used))
                                )
                            )
                            (setq invalid
                                (cons
                                    (list (vclip:handle-v30 vpe) (cadr check)
                                        (if (or (null phe) (null (entget phe)))
                                            'STALE_FRAME_LINK
                                            'INVALID_FRAME))
                                    invalid))
                        )
                    )
                )
            )
        )
    )
    (list (reverse frames) linked (reverse invalid))
)

(defun vclip:print-frame-errors-v312 ( errors / item )
    (foreach item errors
        (princ
            (strcat
                "\nVPOCLIP PRECHECK: rzutnia "
                (if (car item) (car item) "<bez handle>")
                " - " (cadr item)))
        (vclip:trace-v35
            (strcat "PRECHECK FRAME FAIL viewport="
                    (if (car item) (car item) "<nil>")
                    " reason=" (cadr item)))
    )
)

(defun vclip:ss-add-v312 ( ss ent )
    (if (and ss ent (entget ent)) (ssadd ent ss))
    ss
)

(defun vclip:ss-merge-v312 ( target source / i )
    (if (and target source)
        (progn
            (setq i 0)
            (while (< i (sslength source))
                (ssadd (ssname source i) target)
                (setq i (1+ i))
            )
        )
    )
    target
)

(defun vclip:add-intersecting-inserts-v312
       ( keep frames / sel i ent bbox checked added no-bbox )
    ;; AutoCAD and BricsCAD differ in how CP selects block references.
    ;; Add every intersecting INSERT explicitly and always keep it whole.
    (setq sel
        (ssget "_X" '((0 . "INSERT") (410 . "Model")))
          i       0
          checked 0
          added   0
          no-bbox 0)
    (if sel
        (while (< i (sslength sel))
            (setq ent (ssname sel i)
                  i   (1+ i)
                  checked (1+ checked))
            (if (not (ssmemb ent keep))
                (if (setq bbox (vclip:bbox ent))
                    (if (vclip:bbox-intersects-any-frame-p bbox frames)
                        (progn
                            (ssadd ent keep)
                            (setq added (1+ added))))
                    (setq no-bbox (1+ no-bbox))))))
    ;; added, checked, objects without a usable bbox
    (list added checked no-bbox)
)
(defun vclip:collect-keep-selection-v312
       ( frames keep-ents / oldctab keep frame pts raw ss cpok empty errors ent insertres )
    (setq oldctab (getvar 'CTAB)
          keep    (ssadd)
          cpok    0
          empty   0
          errors  0)
    (foreach ent keep-ents (vclip:ss-add-v312 keep ent))
    (vl-catch-all-apply 'setvar (list 'CTAB "Model"))
    (foreach frame frames
        (setq pts (vclip:frame-cp-points-v30 frame))
        (if (and pts (>= (length pts) 3))
            (progn
                (setq raw
                    (vl-catch-all-apply
                        'ssget (list "_CP" pts '((410 . "Model")))))
                (cond
                    ((vl-catch-all-error-p raw)
                     (setq errors (1+ errors)))
                    ((null raw)
                     (setq empty (1+ empty)))
                    (T
                     (setq ss raw
                           cpok (1+ cpok))
                     (vclip:ss-merge-v312 keep ss))
                )
            )
            (setq errors (1+ errors))
        )
    )
    (setq insertres (vclip:add-intersecting-inserts-v312 keep frames))
    (vclip:trace-v35
        (strcat "KEEP312 INSERTS added=" (itoa (car insertres))
                " checked=" (itoa (cadr insertres))
                " no-bbox=" (itoa (caddr insertres))))
    (if (and oldctab (vclip:layout-exists-p oldctab))
        (vl-catch-all-apply 'setvar (list 'CTAB oldctab)))
    (list keep cpok empty errors)
)

(defun vclip:delete-other-vpo-v312
       ( keep-ents / sel i ent txt to-del intended deleted failed )
    (setq sel (ssget "_X"
                    (list '(0 . "LWPOLYLINE")
                          '(410 . "Model")
                          (cons 8 vclip:nplt-lay)))
          i 0
          to-del nil
          intended 0
          deleted 0)
    (if sel
        (while (< i (sslength sel))
            (setq ent (ssname sel i)
                  i   (1+ i))
            (if (not (vclip:member-ename-p ent keep-ents))
                (progn
                    (setq txt (vclip:getappvalue ent vclip:tapp))
                    (if (and txt (setq txt (handent txt)))
                        (setq to-del (cons txt to-del)))
                    (setq to-del (cons ent to-del))
                )
            )
        )
    )
    (setq intended (length to-del))
    (foreach ent to-del
        (if (vclip:safe-delete-entity ent)
            (setq deleted (1+ deleted))))
    (setq failed (- intended deleted))
    (list deleted intended failed)
)

(defun vclip:count-matching-model-xrefs-v312 ( pattern / doc ms obj ent name cnt )
    (setq doc (LM:acdoc)
          ms  (vla-get-ModelSpace doc)
          cnt 0)
    (vlax-for obj ms
        (setq ent (vclip:vla-object->ename-safe obj))
        (if (and ent
                 (setq name (vclip:xref-insert-name-v34 ent))
                 (vclip:xref-name-keep-p-v34 name pattern))
            (setq cnt (1+ cnt))
        )
    )
    cnt
)

(defun vclip:erase-model-selection-v325
       ( selection entities / oldecho oldtile oldctab run ent deleted )
    (setq oldecho (vclip:getvar-safe-v35 'CMDECHO 1)
          oldtile (vclip:getvar-safe-v35 'TILEMODE 1)
          oldctab (vclip:getvar-safe-v35 'CTAB "Model")
          deleted 0)
    (if (> (sslength selection) 0)
        (setq run
            (vl-catch-all-apply
                '(lambda ( / )
                     (setvar 'CMDECHO 0)
                     (if (= oldtile 0) (setvar 'TILEMODE 1))
                     (vl-cmdf "_.ERASE" selection "")
                     T)
                nil)))
    (vl-catch-all-apply 'setvar (list 'CMDECHO oldecho))
    (vl-catch-all-apply 'setvar (list 'TILEMODE oldtile))
    (if (and (= oldtile 0) oldctab (vclip:layout-exists-p oldctab))
        (vl-catch-all-apply 'setvar (list 'CTAB oldctab)))
    (foreach ent entities
        (if (null (entget ent))
            (setq deleted (1+ deleted))))
    deleted
)

(defun vclip:delete-model-by-policy-v312
       ( keep pattern / doc ms obj ent enx typ lay name to-del to-del-ents
                      checked kept protected keptxref intended deleted failed noent )
    (setq doc         (LM:acdoc)
          ms          (vla-get-ModelSpace doc)
          to-del      (ssadd)
          to-del-ents nil
          checked     0
          kept        0
          protected   0
          keptxref    0
          noent       0)
    (vlax-for obj ms
        (setq ent (vclip:vla-object->ename-safe obj))
        (if (null ent)
            (setq noent (1+ noent))
            (progn
                (setq checked (1+ checked)
                      enx     (entget ent)
                      typ     (cdr (assoc 0 enx))
                      lay     (cdr (assoc 8 enx))
                      name    nil)
                (cond
                    ((ssmemb ent keep)
                     (setq kept (1+ kept)))
                    ((vclip:ignored-layer-p-v324 lay)
                     (setq protected (1+ protected)))
                    ((and (= typ "INSERT")
                          (setq name (vclip:xref-insert-name-v34 ent))
                          (vclip:xref-name-keep-p-v34 name pattern))
                     (setq keptxref (1+ keptxref)))
                    ((= typ "VIEWPORT")
                     (setq kept (1+ kept)))
                    (T
                     (ssadd ent to-del)
                     (setq to-del-ents (cons ent to-del-ents)))))))
    (setq intended (sslength to-del)
          deleted  (vclip:erase-model-selection-v325 to-del to-del-ents)
          failed   (- intended deleted))
    ;; deleted checked kept protected kept-xref intended failed no-ename
    (list deleted checked kept protected keptxref intended failed noent)
)
(defun vclip:paper-layout-count-v312 ( / cnt lay name )
    (setq cnt 0)
    (vlax-for lay (vla-get-Layouts (LM:acdoc))
        (setq name (vla-get-Name lay))
        (if (/= "MODEL" (strcase name))
            (setq cnt (1+ cnt)))
    )
    cnt
)

;;------------------------------------------------------------------;;
;;  Exact clipping of simple model geometry v3.12                   ;;
;;------------------------------------------------------------------;;

(defun vclip:dxf-subset-v312 ( enx codes / out code pair )
    (foreach code codes
        (if (setq pair (assoc code enx))
            (setq out (cons pair out))))
    (reverse out)
)

(defun vclip:segment-param-v312 ( p p1 p2 / dx dy )
    (setq dx (- (car p2) (car p1))
          dy (- (cadr p2) (cadr p1)))
    (cond
        ((> (abs dx) (abs dy))
         (if (> (abs dx) 1e-12) (/ (- (car p) (car p1)) dx) 0.0))
        ((> (abs dy) 1e-12)
         (/ (- (cadr p) (cadr p1)) dy))
        (T 0.0)
    )
)

(defun vclip:point-at-param-v312 ( p1 p2 par / z1 z2 )
    (setq z1 (if (caddr p1) (caddr p1) 0.0)
          z2 (if (caddr p2) (caddr p2) 0.0))
    (list
        (+ (car p1) (* par (- (car p2) (car p1))))
        (+ (cadr p1) (* par (- (cadr p2) (cadr p1))))
        (+ z1 (* par (- z2 z1))))
)

(defun vclip:merge-intervals-v312 ( intervals / sorted current item out )
    (setq sorted
        (vl-sort intervals
            '(lambda ( a b )
                 (if (equal (car a) (car b) 1e-12)
                     (< (cadr a) (cadr b))
                     (< (car a) (car b))))))
    (if sorted
        (progn
            (setq current (car sorted))
            (foreach item (cdr sorted)
                (if (<= (car item) (+ (cadr current) 1e-9))
                    (setq current
                        (list (car current) (max (cadr current) (cadr item))))
                    (setq out     (cons current out)
                          current item)))
            (reverse (cons current out)))
        nil)
)

(defun vclip:segment-union-intervals-v312
       ( p1 p2 frames / frame seg a b swap intervals )
    (foreach frame frames
        (setq seg
            (vclip:clip-segment-to-rect p1 p2 (vclip:frame-rect frame)))
        (if seg
            (progn
                (setq a (vclip:segment-param-v312 (car seg) p1 p2)
                      b (vclip:segment-param-v312 (cadr seg) p1 p2))
                (if (> a b)
                    (setq swap a a b b swap))
                (setq a (max 0.0 (min 1.0 a))
                      b (max 0.0 (min 1.0 b)))
                (if (> (- b a) 1e-10)
                    (setq intervals (cons (list a b) intervals))))))
    (vclip:merge-intervals-v312 intervals)
)

(defun vclip:full-segment-interval-p-v312 ( intervals )
    (and (= 1 (length intervals))
         (<= (abs (caar intervals)) 1e-9)
         (<= (abs (- 1.0 (cadar intervals))) 1e-9))
)

(defun vclip:make-line-like-v312 ( src p1 p2 / enx common lineprops data )
    ;; New fragments inherit common display and plot properties that are
    ;; safely transferable from LINE or LWPOLYLINE to LINE.
    (setq enx        (entget src)
          common     (vclip:dxf-subset-v312
                         enx '(67 410 8 6 62 420 430 440 48 370 390 347 60))
          lineprops  (vclip:dxf-subset-v312 enx '(39 210)))
    (if (null (assoc 8 common))
        (setq common (append common (list '(8 . "0")))))
    (setq data
        (append
            (list '(0 . "LINE") '(100 . "AcDbEntity"))
            common
            (list '(100 . "AcDbLine") (cons 10 p1) (cons 11 p2))
            lineprops))
    (entmakex data)
)

(defun vclip:delete-created-v312 ( ents )
    (foreach ent ents (vclip:safe-delete-entity ent))
)

(defun vclip:clip-line-atomic-v312
       ( ent frames / enx p1 p2 intervals interval new created failed )
    (setq enx (entget ent)
          p1  (cdr (assoc 10 enx))
          p2  (cdr (assoc 11 enx)))
    (if (and (vclip:valid-point-p p1) (vclip:valid-point-p p2))
        (progn
            (setq intervals (vclip:segment-union-intervals-v312 p1 p2 frames))
            (cond
                ((or (null intervals)
                     (vclip:full-segment-interval-p-v312 intervals))
                 (list 0 0 0 nil))
                (T
                 (foreach interval intervals
                     (if (not failed)
                         (if (setq new
                                  (vclip:make-line-like-v312
                                      ent
                                      (vclip:point-at-param-v312 p1 p2 (car interval))
                                      (vclip:point-at-param-v312 p1 p2 (cadr interval))))
                             (setq created (cons new created))
                             (setq failed T))))
                 (cond
                     (failed
                      (vclip:delete-created-v312 created)
                      (list 0 0 1 nil))
                     ((vclip:safe-delete-entity ent)
                      (list 1 (length created) 0 created))
                     (T
                      (vclip:delete-created-v312 created)
                      (list 0 0 1 nil)))
                ))
            )
        (list 0 0 1 nil))
)
(defun vclip:lwpoly-unsupported-v312 ( ent / enx bad pair )
    ;; Bulged or wide polylines are kept whole; converting them to straight
    ;; LINE fragments would silently change their geometry.
    (setq enx (entget ent))
    (foreach pair enx
        (if (or (and (= 42 (car pair))
                     (> (abs (cdr pair)) 1e-12))
                (and (member (car pair) '(40 41 43))
                     (> (abs (cdr pair)) 1e-12)))
            (setq bad T)))
    bad
)

(defun vclip:clip-lwpoly-atomic-v312
       ( ent frames / pts p1 p2 i intervals interval new created failed )
    (setq pts (vclip:polyvertices-wcs ent))
    (if (and pts (> (length pts) 1))
        (progn
            (if (vclip:lwpoly-closed-p ent)
                (setq pts (append pts (list (car pts)))))
            (setq i 0)
            (while (and (< i (1- (length pts))) (not failed))
                (setq p1 (nth i pts)
                      p2 (nth (1+ i) pts)
                      i  (1+ i)
                      intervals
                         (vclip:segment-union-intervals-v312 p1 p2 frames))
                (foreach interval intervals
                    (if (not failed)
                        (if (setq new
                                 (vclip:make-line-like-v312
                                     ent
                                     (vclip:point-at-param-v312 p1 p2 (car interval))
                                     (vclip:point-at-param-v312 p1 p2 (cadr interval))))
                            (setq created (cons new created))
                            (setq failed T)))))
            (cond
                (failed
                 (vclip:delete-created-v312 created)
                 (list 0 0 1 nil))
                ((null created)
                 (list 0 0 0 nil))
                ((vclip:safe-delete-entity ent)
                 (list 1 (length created) 0 created))
                (T
                 (vclip:delete-created-v312 created)
                 (list 0 0 1 nil)))
        )
        (list 0 0 1 nil))
)
(defun vclip:clip-simple-geometry-v312
       ( frames keep-ents
         / sel i ent enx typ lay bbox result created replaced skipped failed newents )
    ;; INSERT objects are never clipped. Query only the simple geometry types
    ;; handled here instead of walking the whole ModelSpace collection.
    (setq created  0
          replaced 0
          skipped  0
          failed   0
          newents  nil
          sel      (ssget "_X"
                         '((0 . "LINE,LWPOLYLINE") (410 . "Model")))
          i        0)
    (if sel
        (while (< i (sslength sel))
            (setq ent (ssname sel i)
                  i   (1+ i)
                  enx (entget ent (list vclip:xapp vclip:tapp))
                  typ (cdr (assoc 0 enx))
                  lay (cdr (assoc 8 enx)))
            (cond
                ((vclip:member-ename-p ent keep-ents) nil)
                ((and lay (= (strcase lay) (strcase vclip:nplt-lay))) nil)
                ((vclip:ignored-layer-p-v324 lay) nil)
                ((assoc -3 enx) nil)
                ((not (setq bbox (vclip:bbox ent)))
                 (setq skipped (1+ skipped)))
                ((vclip:bbox-fully-inside-any-frame-p bbox frames) nil)
                ((vclip:bbox-intersects-any-frame-p bbox frames)
                 (if (and (= typ "LWPOLYLINE")
                          (vclip:lwpoly-unsupported-v312 ent))
                     (setq skipped (1+ skipped))
                     (progn
                         (setq result
                             (if (= typ "LINE")
                                 (vclip:clip-line-atomic-v312 ent frames)
                                 (vclip:clip-lwpoly-atomic-v312 ent frames)))
                         (setq replaced (+ replaced (car result))
                               created  (+ created (cadr result))
                               failed   (+ failed (caddr result))
                               newents  (append (nth 3 result) newents)))))))
    )
    ;; created, replaced sources, safely skipped, failures, new entities
    (list created replaced skipped failed newents)
)
(defun vclip:undo-back-v312 ( / r oldecho )
    (setq oldecho (vclip:getvar-safe-v35 'CMDECHO 1))
    (vl-catch-all-apply 'setvar (list 'CMDECHO 0))
    (setq r
        (vl-catch-all-apply
            '(lambda ( / ) (vl-cmdf "_.UNDO" "_Back"))
            nil))
    (vl-catch-all-apply 'setvar (list 'CMDECHO oldecho))
    (not (vl-catch-all-error-p r))
)

(defun vclip:clip-current-document-by-layout-v312
       ( keep-lay make-backup-p use-undo-p pattern
         / doc oldctab layer-states pre frames linked invalid keep-ents
           selection keep-set backup before-layouts expected-layout-delete
           matching-before res operation-ok undo-started vpores delmodel
           deleted-layouts failure-message clipres newent xkeepres auto-clean )
    (vclip:reset-xref-name-cache-v325)
    (setq doc          (LM:acdoc)
          oldctab      (getvar 'CTAB)
          layer-states nil
          operation-ok nil
          undo-started nil
          failure-message nil)
    (cond
        ((or (null keep-lay) (= "" keep-lay)
             (= "MODEL" (strcase keep-lay)))
         (princ "\nVPOCLIP PRECHECK: niepoprawna nazwa layoutu.")
         nil)
        ((not (vclip:layout-exists-p keep-lay))
         (princ (strcat "\nVPOCLIP PRECHECK: layout nie istnieje: " keep-lay))
         nil)
        (T
         (setq pre     (vclip:collect-frames-for-layout-v312 keep-lay)
               frames  (car pre)
               linked  (cadr pre)
               invalid (caddr pre))
         (cond
             ((= linked 0)
              (princ
                  (strcat "\nVPOCLIP PRECHECK: layout " keep-lay
                          " nie ma rzutni połączonych przez VPO_LINK."))
              nil)
             (invalid
              (vclip:print-frame-errors-v312 invalid)
              (princ "\nVPOCLIP PRECHECK: wykryto uszkodzone lub niewzajemne linki. Nic nie skasowano.")
              nil)
             ((/= linked (length frames))
              (princ "\nVPOCLIP PRECHECK: liczba rzutni i poprawnych ramek jest różna. Nic nie skasowano.")
              nil)
             (T
              (setq keep-ents (vclip:collect-keep-ents frames)
                    selection (vclip:collect-keep-selection-v312 frames keep-ents)
                    keep-set  (car selection))
              (if (> (cadddr selection) 0)
                  (progn
                      (princ "\nVPOCLIP PRECHECK: błąd wyboru CP. Nic nie skasowano.")
                      nil)
                  (progn
                      (if make-backup-p
                          (setq backup (vclip:make-backup))
                          (setq backup T))
                      (if (null backup)
                          (progn
                              (princ "\nVPOCLIP PRECHECK: nie udało się utworzyć kopii zapasowej. Operacja przerwana.")
                              nil)
                          (progn
                              (if (and make-backup-p (= 'STR (type backup)))
                                  (princ (strcat "\nVPOCLIP: kopia zapasowa: " backup)))
                              (setq before-layouts
                                        (vclip:paper-layout-count-v312)
                                    expected-layout-delete
                                        (max 0 (1- before-layouts))
                                    matching-before
                                        (vclip:count-matching-top-level-xrefs-v324 pattern))
                              (vclip:trace-v35
                                  (strcat "CLIP312 START layout=" keep-lay
                                          " frames=" (itoa (length frames))
                                          " keep-selection=" (itoa (sslength keep-set))))
                              (setq res
                                  (vl-catch-all-apply
                                      '(lambda ( / )
                                           (if use-undo-p
                                               (progn
                                                   (LM:startundo doc)
                                                   (setq undo-started T)))
                                           (setq layer-states
                                               (vclip:unlock-all-layers))
                                           (setq clipres
                                               (vclip:clip-simple-geometry-v312
                                                   frames keep-ents))
                                           (if (> (nth 3 clipres) 0)
                                               (setq failure-message
                                                   (strcat
                                                       "nie udało się przyciąć "
                                                       (itoa (nth 3 clipres))
                                                       " obiektów")))
                                           ;; Add fresh fragments directly to the original
                                           ;; selection; a second CP scan is unnecessary.
                                           (foreach newent (nth 4 clipres)
                                               (vclip:ss-add-v312 keep-set newent))
                                           (if (null failure-message)
                                               (progn
                                                   (setq xkeepres
                                                       (vclip:preserve-matching-xrefs-v324
                                                           keep-lay pattern))
                                                   (if (> (nth 3 xkeepres) 0)
                                                       (setq failure-message
                                                           (strcat
                                                               "nie zachowano "
                                                               (itoa (nth 3 xkeepres))
                                                               " pasujacych definicji XREF")))))
                                           (if (null failure-message)
                                               (progn
                                                   (setq vpores
                                                       (vclip:delete-other-vpo-v312
                                                           keep-ents))
                                                   (setq delmodel
                                                       (vclip:delete-model-by-policy-v312
                                                           keep-set pattern))
                                                   (setq deleted-layouts
                                                       (vclip:delete-layouts-except
                                                           keep-lay))
                                                   (cond
                                                       ((> (caddr vpores) 0)
                                                        (setq failure-message
                                                            (strcat
                                                                "nie usunięto "
                                                                (itoa (caddr vpores))
                                                                " obiektów ramek/etykiet")))
                                                       ((> (nth 6 delmodel) 0)
                                                        (setq failure-message
                                                            (strcat
                                                                "nie usunięto "
                                                                (itoa (nth 6 delmodel))
                                                                " obiektów ModelSpace")))
                                                       ((/= deleted-layouts
                                                            expected-layout-delete)
                                                        (setq failure-message
                                                            (strcat
                                                                "usunięto layoutów "
                                                                (itoa deleted-layouts)
                                                                ", oczekiwano "
                                                                (itoa expected-layout-delete))))
                                                       (T
                                                         (setq auto-clean
                                                            (if vclip:auto-frame-records-v339
                                                                (vclip:remove-auto-frame-records-v339
                                                                    vclip:auto-frame-records-v339 keep-set)
                                                                (list T 0 0)))
                                                         (if (car auto-clean)
                                                             (setq operation-ok T)
                                                             (setq failure-message
                                                                (strcat
                                                                    "nie usunieto automatycznych ramek; bledy="
                                                                    (itoa (caddr auto-clean))))))
                                                   )))
                                       )
                                      nil))
                              (if layer-states
                                  (progn
                                      (vclip:restore-layer-locks layer-states)
                                      (setq layer-states nil)))
                              (if undo-started
                                  (progn
                                      (LM:endundo doc)
                                      (setq undo-started nil)))
                              (if (vl-catch-all-error-p res)
                                  (setq failure-message
                                      (vl-catch-all-error-message res)
                                      operation-ok nil))
                              (if operation-ok
                                  (progn
                                      (vl-catch-all-apply
                                          'setvar (list 'CTAB keep-lay))
                                      (princ
                                          (strcat
                                              "\nVPOCLIP 3.39-brics: ramki="
                                              (itoa (length frames))
                                              " / wybrane="
                                              (itoa (sslength keep-set))
                                              " / przycięte źródła="
                                              (itoa (cadr clipres))
                                              " / nowe fragmenty="
                                              (itoa (car clipres))
                                              " / pominięte przycinanie="
                                              (itoa (caddr clipres))
                                              " / usunięte ModelSpace="
                                              (itoa (car delmodel))
                                              " / chroniona warstwa="
                                              (itoa (nth 3 delmodel))
                                              " / zachowane XREF="
                                              (itoa (nth 4 delmodel))))
                                      (vclip:trace-v35 "CLIP312 END OK")
                                      (list T keep-set matching-before))
                                  (progn
                                      (princ
                                          (strcat
                                              "\nVPOCLIP 3.39-brics: operacja niepełna - "
                                              (if failure-message
                                                  failure-message
                                                  "nieznany błąd")))
                                      (vclip:trace-v35
                                          (strcat "CLIP312 END FAIL "
                                              (if failure-message
                                                  failure-message
                                                  "unknown")))
                                      (if use-undo-p
                                          (if (vclip:undo-back-v312)
                                              (princ "\nVPOCLIP: wycofano niepełną operację przez UNDO Back.")
                                              (princ "\nVPOCLIP: UWAGA - automatyczne UNDO Back nie powiodło się.")))
                                      (if (and oldctab
                                               (vclip:layout-exists-p oldctab))
                                          (vl-catch-all-apply
                                              'setvar (list 'CTAB oldctab)))
                                      nil
                                  )
                              )
                          )
                      )
                  )
              )
             )
         )
        )
    )
)
(defun vclip:collect-nonmatching-inserts-v312
       ( pattern / doc spaces space obj ent name out )
    (setq doc    (LM:acdoc)
          spaces (list (vla-get-ModelSpace doc) (vla-get-PaperSpace doc))
          out    nil)
    (foreach space spaces
        (vlax-for obj space
            (setq ent (vclip:vla-object->ename-safe obj))
            (if (and ent
                     (setq name (vclip:xref-insert-name-v34 ent))
                     (not (vclip:xref-name-keep-p-v34 name pattern)))
                (setq out
                    (cons
                        (strcat name "@" (if (vclip:handle-v30 ent)
                                             (vclip:handle-v30 ent) "?"))
                        out))
            )
        )
    )
    (reverse out)
)

(defun vclip:model-policy-violations-v312
       ( keep pattern / doc ms obj ent enx typ lay name out )
    (setq doc (LM:acdoc)
          ms  (vla-get-ModelSpace doc)
          out nil)
    (vlax-for obj ms
        (setq ent (vclip:vla-object->ename-safe obj))
        (if ent
            (progn
                (setq enx  (entget ent)
                      typ  (cdr (assoc 0 enx))
                      lay  (cdr (assoc 8 enx))
                      name (if (= typ "INSERT")
                               (vclip:xref-insert-name-v34 ent)))
                (if
                    (cond
                        (name
                         (vclip:xref-name-keep-p-v34 name pattern))
                        ((vclip:ignored-layer-p-v324 lay) T)
                        ((= typ "VIEWPORT") T)
                        ((ssmemb ent keep) T)
                        (T nil))
                    nil
                    (setq out
                        (cons
                            (strcat
                                (if typ typ "?") "@"
                                (if (vclip:handle-v30 ent)
                                    (vclip:handle-v30 ent) "?"))
                            out))
                )
            )
        )
    )
    (reverse out)
)

(defun vclip:postcondition-v312
       ( keep-lay pattern keep matching-before
         / layouts matching-after bad-inserts bad-defs bad-model ok )
    (setq layouts       (vclip:paper-layout-count-v312)
          matching-after (vclip:count-matching-top-level-xrefs-v324 pattern)
          bad-inserts   (vclip:collect-nonmatching-inserts-v312 pattern)
          bad-defs      (vclip:collect-nonmatching-xref-names-v34 pattern)
          bad-model     (vclip:model-policy-violations-v312 keep pattern)
          ok             T)
    (if (or (not (vclip:layout-exists-p keep-lay)) (/= layouts 1))
        (progn
            (setq ok nil)
            (vclip:trace-v35
                (strcat "POST FAIL layouts=" (itoa layouts)))))
    (if bad-inserts
        (progn
            (setq ok nil)
            (vclip:trace-v35
                (strcat "POST FAIL nonmatching inserts="
                        (vl-princ-to-string bad-inserts)))))
    (if bad-defs
        (progn
            (setq ok nil)
            (vclip:trace-v35
                (strcat "POST FAIL nonmatching xref defs="
                        (vl-princ-to-string bad-defs)))))
    (if bad-model
        (progn
            (setq ok nil)
            (vclip:trace-v35
                (strcat "POST FAIL model policy="
                        (vl-princ-to-string bad-model)))))
    (if (/= matching-before matching-after)
        (progn
            (setq ok nil)
            (vclip:trace-v35
                (strcat "POST FAIL matching xref count before="
                        (itoa matching-before)
                        " after=" (itoa matching-after)))))
    (if (not ok)
        (princ
            (strcat
                "\nVPOCFG POSTCHECK: layoutów=" (itoa layouts)
                " / niedozwolone wstawienia XREF="
                (itoa (length bad-inserts))
                " / niedozwolone definicje XREF="
                (itoa (length bad-defs))
                " / niedozwolone obiekty ModelSpace="
                (itoa (length bad-model))
                " / zachowane XREF przed/po="
                (itoa matching-before) "/" (itoa matching-after))))
    ok
)

(defun vclip:pdf-file-p-v312 ( path / r )
    (setq r
        (vl-catch-all-apply
            '(lambda ( / f chars code i )
                 (if (and path (findfile path) (setq f (open path "r")))
                     (progn
                         (setq chars nil
                               i 0)
                         (while (< i 5)
                             (setq code (read-char f))
                             (if code
                                 (setq chars (cons (chr code) chars)
                                       i (1+ i))
                                 (setq i 5 chars nil))
                         )
                         (close f)
                         (and chars
                              (= "%PDF-" (apply 'strcat (reverse chars))))
                     )
                     nil
                 )
             )
            nil))
    (and (not (vl-catch-all-error-p r)) r)
)

(defun vclip:replace-one-file-v312 ( new final / backup moved-old ok )
    (setq backup
        (strcat final "._VPO_OLD_" (vclip:timestamp))
          moved-old nil
          ok nil)
    (if (and new final (findfile new))
        (progn
            (vclip:file-delete-confirmed-v312 backup)
            (if (findfile final)
                (if (vclip:file-rename-confirmed-v312 final backup)
                    (setq moved-old T)
                    (setq new nil)))
            (if (and new
                     (vclip:file-rename-confirmed-v312 new final))
                (setq ok T)
                (if moved-old
                    (vclip:file-rename-confirmed-v312 backup final)))
            (if (and ok moved-old)
                (vclip:file-delete-confirmed-v312 backup))
        )
    )
    ok
)

(defun vclip:plot-layout-to-pdf-v312
       ( lay pdfpath / oldctab oldfiledia oldcmddia oldback temp info res ok )
    (setq oldctab     (vclip:getvar-safe-v35 'CTAB "Model")
          oldfiledia  (vclip:getvar-safe-v35 'FILEDIA 1)
          oldcmddia   (vclip:getvar-safe-v35 'CMDDIA 1)
          oldback     (vclip:getvar-safe-v35 'BACKGROUNDPLOT 2)
          temp        (strcat
                          (vclip:dir-with-sep-v34 pdfpath)
                          (vl-filename-base pdfpath)
                          "._VPO_PLOT_" (vclip:timestamp) ".vpotmp")
          ok          nil)
    (vclip:file-delete-confirmed-v312 temp)
    (setq res
        (vl-catch-all-apply
            '(lambda ( / doc plot call )
                 (cond
                     ((or (null lay) (= "" lay)
                          (= "MODEL" (strcase lay)))
                      (princ "\nVPOCFG PDF: niepoprawna nazwa layoutu.")
                      nil)
                     ((not (vclip:layout-exists-p lay))
                      (princ (strcat "\nVPOCFG PDF: layout nie istnieje: " lay))
                      nil)
                     ((or (null pdfpath) (= "" pdfpath))
                      (princ "\nVPOCFG PDF: niepoprawna ścieżka.")
                      nil)
                     ((null (setq info (vclip:layout-plot-info-v35 lay)))
                      (princ "\nVPOCFG PDF: nie można odczytać Page Setup.")
                      nil)
                     ((or (= "" (car info)) (= "" (cadr info)))
                      (princ
                          (strcat "\nVPOCFG PDF: niepełny Page Setup / plotter='"
                                  (car info) "' / papier='" (cadr info) "'."))
                      nil)
                     (T
                      (princ
                          (strcat "\nVPOCFG PDF: plotter=" (car info)
                                  " / papier=" (cadr info)
                                  " / styl=" (caddr info)))
                      (vclip:trace-v35
                          (strcat "PDF312 START layout=" lay
                                  " temp=" temp
                                  " device=" (car info)))
                      (vl-catch-all-apply 'setvar (list 'FILEDIA 0))
                      (vl-catch-all-apply 'setvar (list 'CMDDIA 0))
                      (vl-catch-all-apply 'setvar (list 'BACKGROUNDPLOT 0))
                      (vl-catch-all-apply 'setvar (list 'CTAB lay))
                      (setq doc  (LM:acdoc)
                            plot (vla-get-Plot doc)
                            call (vl-catch-all-apply
                                     'vla-PlotToFile
                                     (list plot temp)))
                      (and (not (vl-catch-all-error-p call))
                           (vclip:pdf-file-p-v312 temp))
                     )
                 )
             )
            nil))
    ;; Przywrócenie następuje niezależnie od wyniku lub wyjątku.
    (if (and oldctab (vclip:layout-exists-p oldctab))
        (vl-catch-all-apply 'setvar (list 'CTAB oldctab)))
    (vl-catch-all-apply 'setvar (list 'FILEDIA 1))
    (vl-catch-all-apply 'setvar (list 'CMDDIA oldcmddia))
    (vl-catch-all-apply 'setvar (list 'BACKGROUNDPLOT oldback))
    (if (and (not (vl-catch-all-error-p res)) res)
        (if (vclip:replace-one-file-v312 temp pdfpath)
            (progn
                (setq ok T)
                (princ (strcat "\nVPOCFG PDF: zapisano prawidłowy PDF: " pdfpath))
                (vclip:trace-v35
                    (strcat "PDF312 OK staged-no-viewer " pdfpath)))
            (progn
                (princ "\nVPOCFG PDF: nie udało się bezpiecznie podmienić pliku wynikowego.")
                (vclip:trace-v35 "PDF312 FAIL replace")))
        (progn
            (if (findfile temp)
                (if (vclip:pdf-file-p-v312 temp)
                    (vclip:trace-v35 "PDF312 FAIL valid temp but operation failed")
                    (vclip:trace-v35 "PDF312 FAIL output is not PDF")))
            (vclip:file-delete-confirmed-v312 temp)
            (princ "\nVPOCFG PDF: sterownik nie utworzył prawidłowego pliku PDF. Poprzedni PDF pozostawiono bez zmian.")
        )
    )
    ok
)
(defun vclip:write-task-marker-v312 ( marker status detail )
    (vclip:write-text-v312 marker
        (strcat status "|" (if detail detail "")))
)

(defun vclip:acad-process-body-v312
       ( keep-lay pattern workpdf
         / doc path core keep matching-before xres postok saved pdfok )
    (setq doc  (LM:acdoc)
          path (vclip:current-dwg-path-v31))
    (cond
        ((or (null path) (= "" path))
         (list nil "aktywny dokument nie ma ścieżki DWG"))
        ((not (vclip:layout-exists-p keep-lay))
         (list nil (strcat "layout nie istnieje: " keep-lay)))
        ((null
             (setq core
                 (vclip:clip-current-document-by-layout-v312
                     keep-lay nil nil pattern)))
         (list nil "precheck lub czyszczenie nie powiodło się"))
        (T
         (setq keep            (cadr core)
               matching-before (caddr core)
               xres             (vclip:filter-xrefs-v34 pattern))
         (vclip:trace-v35
             (strcat "XREF FILTER result=" (vl-princ-to-string xres)))
         (if (not (vclip:purge-all-v33))
             (vclip:trace-v35 "PURGE warning"))
         (setq postok
             (vclip:postcondition-v312
                 keep-lay pattern keep matching-before))
         (cond
             ((not postok)
              (list nil "kontrola stanu końcowego nie powiodła się"))
             ((not (setq saved (vclip:save-doc-v31 doc)))
              (list nil "nie udało się zapisać roboczego DWG"))
             ((/= 0 (vclip:getvar-safe-v35 'DBMOD 0))
              (list nil "po zapisie DBMOD nie wynosi 0"))
             ((not
                  (setq pdfok
                      (vclip:plot-layout-to-pdf-v312 keep-lay workpdf)))
              (list nil "nie utworzono prawidłowego PDF"))
             (T (list T "OK"))
         )
        )
    )
)

(defun vclip:worker-stage-v315 ( code detail )
    (if (and (boundp 'vclip:worker-progress-v315)
             vclip:worker-progress-v315
             (= 'STR (type vclip:worker-progress-v315))
             (/= "" vclip:worker-progress-v315))
        (vclip:write-text-v312
            vclip:worker-progress-v315
            (strcat code "|" detail)))
    T
)

(defun vclip:acad-process-body-v315
       ( keep-lay pattern workpdf
         / doc path core keep matching-before xres postok saved pdfok )
    (setq doc  (LM:acdoc)
          path (vclip:current-dwg-path-v31))
    (vclip:worker-stage-v315 "PRECHECK" "Sprawdzanie layoutu i ramek")
    (cond
        ((or (null path) (= "" path))
         (list nil "aktywny dokument nie ma sciezki DWG"))
        ((not (vclip:layout-exists-p keep-lay))
         (list nil (strcat "layout nie istnieje: " keep-lay)))
        ((null
             (progn
                 (vclip:worker-stage-v315
                     "MODEL" "Czyszczenie modelu wedlug ramek")
                 (setq core
                     (vclip:clip-current-document-by-layout-v312
                         keep-lay nil nil pattern))))
         (list nil "precheck lub czyszczenie nie powiodlo sie"))
        (T
         (setq keep            (cadr core)
               matching-before (caddr core))
         (vclip:worker-stage-v315
             "XREF" "Filtrowanie odnosnikow zewnetrznych")
         (setq xres (vclip:filter-xrefs-v34 pattern))
         (vclip:trace-v35
             (strcat "XREF FILTER result=" (vl-princ-to-string xres)))
         (vclip:worker-stage-v315
             "PURGE" "Porzadkowanie rysunku")
         (if (not (vclip:purge-all-v33))
             (vclip:trace-v35 "PURGE warning"))
         (vclip:worker-stage-v315
             "VERIFY" "Kontrola przygotowanego rysunku")
         (setq postok
             (vclip:postcondition-v312
                 keep-lay pattern keep matching-before))
         (cond
             ((not postok)
              (list nil "kontrola stanu koncowego nie powiodla sie"))
             ((progn
                  (vclip:worker-stage-v315 "SAVE" "Zapisywanie pliku DWG")
                  (not (setq saved (vclip:save-doc-v31 doc))))
              (list nil "nie udalo sie zapisac roboczego DWG"))
             ((/= 0 (vclip:getvar-safe-v35 'DBMOD 0))
              (list nil "po zapisie DBMOD nie wynosi 0"))
             ((progn
                  (vclip:worker-stage-v315 "PDF" "Drukowanie pliku PDF")
                  (not
                      (setq pdfok
                          (vclip:plot-layout-to-pdf-v312
                              keep-lay workpdf))))
              (list nil "nie utworzono prawidlowego PDF"))
             (T
              (vclip:worker-stage-v315
                  "FINAL" "Koncowa kontrola wyniku")
              (list T "OK"))
         )
        )
    )
)
(defun vclip:acad-process-current-file-v312
       ( keep-lay pattern workpdf marker
         / doc path run success detail final-save )
    ;; No exception or ambiguous local state is allowed to escape into SCR.
    (vl-load-com)
    (setq doc     (LM:acdoc)
          path    (vclip:current-dwg-path-v31)
          success nil
          detail  "nieznany błąd")
    (vclip:trace-v35
        (strcat "TASK START file=" (if path path "<nil>")
                " layout=" (if keep-lay keep-lay "<nil>")
                " pattern=" (if pattern pattern "<nil>")))
    (setq run
        (vl-catch-all-apply
            'vclip:acad-process-body-v315
            (list keep-lay pattern workpdf)))
    (cond
        ((vl-catch-all-error-p run)
         (setq success nil
               detail (strcat "wyjątek: " (vl-catch-all-error-message run)))
         (vclip:trace-v35 (strcat "TASK EXCEPTION " detail)))
        ((and (listp run) (>= (length run) 2))
         (setq success (car run)
               detail  (cadr run)))
        (T
         (setq success nil
               detail "nieprawidłowy wynik części roboczej zadania"))
    )
    ;; Save the work file even after failure so CLOSE never asks a question.
    ;; A failed work file is never installed as the final result.
    (setq final-save (vclip:save-doc-v31 doc))
    (if (not final-save)
        (progn
            (setq success nil
                  detail (strcat detail "; końcowy zapis roboczy nieudany"))))
    (if success
        (if (not (vclip:write-task-marker-v312 marker "OK" detail))
            (setq success nil
                  detail "nie udało się zapisać markera sukcesu")))
    (if (not success)
        (vclip:write-task-marker-v312 marker "FAIL" detail))
    (vclip:trace-v35
        (strcat "TASK END result=" (if success "OK" "FAIL")
                " detail=" detail))
    (princ
        (strcat "\nVPOCFG TASK: " (if success "OK" "FAIL")
                " - " detail))
    success
)

(defun vclip:replace-task-pair-v312
       ( workdwg finaldwg workpdf finalpdf overwrite
         / bd bp had-dwg had-pdf moved-dwg moved-pdf new-dwg new-pdf ok )
    (setq bd (strcat finaldwg "._VPO_OLD_" (vclip:timestamp))
          bp (strcat finalpdf "._VPO_OLD_" (vclip:timestamp))
          had-dwg (findfile finaldwg)
          had-pdf (findfile finalpdf)
          moved-dwg nil
          moved-pdf nil
          new-dwg nil
          new-pdf nil
          ok nil)
    (cond
        ((or (not (findfile workdwg))
             (not (vclip:pdf-file-p-v312 workpdf)))
         nil)
        ((and (not overwrite) (or had-dwg had-pdf))
         nil)
        ((or (not (vclip:file-delete-confirmed-v312 bd))
             (not (vclip:file-delete-confirmed-v312 bp)))
         nil)
        (T
         (if had-dwg
             (setq moved-dwg
                 (vclip:file-rename-confirmed-v312 finaldwg bd))
             (setq moved-dwg T))
         (if moved-dwg
             (if had-pdf
                 (setq moved-pdf
                     (vclip:file-rename-confirmed-v312 finalpdf bp))
                 (setq moved-pdf T)))
         (if (and moved-dwg moved-pdf)
             (progn
                 (setq new-dwg
                     (vclip:file-rename-confirmed-v312 workdwg finaldwg))
                 (if new-dwg
                     (setq new-pdf
                         (vclip:file-rename-confirmed-v312 workpdf finalpdf)))
                 (setq ok (and new-dwg new-pdf))
             )
         )
         (if ok
             (progn
                 (if had-dwg (vclip:file-delete-confirmed-v312 bd))
                 (if had-pdf (vclip:file-delete-confirmed-v312 bp)))
             (progn
                 ;; Wycofanie podmiany zachowuje poprzednią parę wyników.
                 (if (and new-dwg (findfile finaldwg))
                     (vclip:file-delete-confirmed-v312 finaldwg))
                 (if (and new-pdf (findfile finalpdf))
                     (vclip:file-delete-confirmed-v312 finalpdf))
                 (if (and had-dwg (findfile bd))
                     (vclip:file-rename-confirmed-v312 bd finaldwg))
                 (if (and had-pdf (findfile bp))
                     (vclip:file-rename-confirmed-v312 bp finalpdf))
             )
         )
        )
    )
    ok
)

(defun vclip:finalize-task-copy-v312
       ( task overwrite report
         / lay work final workpdf finalpdf marker status stamp install-dwg
           install-pdf copied-dwg copied-pdf ok )
    ;; The work DWG may still be open. Copy both saved artifacts first, then
    ;; install the independent copies with the existing pair transaction.
    (setq lay         (nth 0 task)
          work        (nth 1 task)
          final       (nth 2 task)
          workpdf     (nth 4 task)
          finalpdf    (nth 5 task)
          marker      (nth 6 task)
          status      (vclip:read-first-line-v312 marker)
          stamp       (vclip:timestamp)
          install-dwg (strcat final "._VPO_INSTALL_" stamp)
          install-pdf (strcat finalpdf "._VPO_INSTALL_" stamp)
          vclip:batch-report-v312 report
          ok          nil)
    (vclip:file-delete-confirmed-v312 install-dwg)
    (vclip:file-delete-confirmed-v312 install-pdf)
    (if (and status
             (>= (strlen status) 3)
             (= "OK|" (substr status 1 3)))
        (progn
            (setq copied-dwg
                    (vclip:file-copy-confirmed-v312 work install-dwg)
                  copied-pdf
                    (vclip:file-copy-confirmed-v312 workpdf install-pdf))
            (if (and copied-dwg copied-pdf)
                (setq ok
                    (vclip:replace-task-pair-v312
                        install-dwg final install-pdf finalpdf overwrite)))))
    (if ok
        (progn
            (vclip:file-delete-confirmed-v312 marker)
            (vclip:append-report-v312
                (strcat "OK|" lay "|" final "|" finalpdf))
            (princ (strcat "\nVPOCFG FINAL COPY: OK - " final)))
        (progn
            (vclip:file-delete-confirmed-v312 install-dwg)
            (vclip:file-delete-confirmed-v312 install-pdf)
            (vclip:append-report-v312
                (strcat "FAIL|" lay "|" final "|"
                        (if status status "brak markera zadania")))
            (princ
                (strcat "\nVPOCFG FINAL COPY: FAIL - " final
                        ". Poprzednie wyniki pozostawiono bez zmian."))))
    ok
)

(defun vclip:close-inactive-work-docs-v312
       ( tasks / app docs active paths task doc full candidates closed r )
    (setq app    (vlax-get-acad-object)
          docs   (vla-get-Documents app)
          active (vla-get-ActiveDocument app)
          paths  nil
          closed 0)
    (foreach task tasks
        (setq paths
            (cons (vclip:canonical-path-v312 (nth 1 task)) paths)))
    (vlax-for doc docs
        (setq full
            (vl-catch-all-apply 'vla-get-FullName (list doc)))
        (if (and (not (eq doc active))
                 (not (vl-catch-all-error-p full))
                 full
                 (member (vclip:canonical-path-v312 full) paths))
            (setq candidates (cons doc candidates))))
    (foreach doc candidates
        (setq r (vl-catch-all-apply 'vla-Close (list doc :vlax-false)))
        (if (not (vl-catch-all-error-p r))
            (setq closed (1+ closed))))
    closed
)
(defun vclip:finalize-task-v312
       ( task overwrite report / lay work final workpdf finalpdf marker status ok )
    (setq lay      (nth 0 task)
          work     (nth 1 task)
          final    (nth 2 task)
          workpdf  (nth 4 task)
          finalpdf (nth 5 task)
          marker   (nth 6 task)
          status   (vclip:read-first-line-v312 marker)
          vclip:batch-report-v312 report
          ok       nil)
    (if (and status
             (>= (strlen status) 3)
             (= "OK|" (substr status 1 3)))
        (setq ok
            (vclip:replace-task-pair-v312
                work final workpdf finalpdf overwrite)))
    (if ok
        (progn
            (vclip:file-delete-confirmed-v312 marker)
            (vclip:append-report-v312
                (strcat "OK|" lay "|" final "|" finalpdf))
            (princ (strcat "\nVPOCFG FINAL: OK - " final)))
        (progn
            (vclip:append-report-v312
                (strcat "FAIL|" lay "|" final "|"
                        (if status status "brak markera zadania")))
            (princ
                (strcat "\nVPOCFG FINAL: FAIL - " final
                        ". Poprzednie wyniki pozostawiono bez zmian."))
        )
    )
    ok
)

(defun vclip:lisp-string-v312 ( value / s out i ch slash quote )
    (setq s     (if value value "")
          slash (chr 92)
          quote (chr 34)
          out   quote
          i     1)
    (while (<= i (strlen s))
        (setq ch (substr s i 1))
        (cond
            ((= ch slash)
             (setq out (strcat out slash slash)))
            ((= ch quote)
             (setq out (strcat out slash quote)))
            (T (setq out (strcat out ch)))
        )
        (setq i (1+ i))
    )
    (strcat out quote)
)

(defun vclip:path-lisp-string-v312 ( path )
    (vclip:lisp-string-v312
        (vl-string-translate "\\" "/" (if path path "")))
)

(defun vclip:task-expression-v312 ( task )
    (strcat
        "(list "
        (vclip:lisp-string-v312 (nth 0 task)) " "
        (vclip:path-lisp-string-v312 (nth 1 task)) " "
        (vclip:path-lisp-string-v312 (nth 2 task)) " "
        (vclip:lisp-string-v312 (nth 3 task)) " "
        (vclip:path-lisp-string-v312 (nth 4 task)) " "
        (vclip:path-lisp-string-v312 (nth 5 task)) " "
        (vclip:path-lisp-string-v312 (nth 6 task))
        ")")
)

(defun vclip:batch-sidecar-path-v314 ( script suffix / dir base )
    (setq dir  (vclip:dir-with-sep-v34 script)
          base (vl-filename-base script))
    (strcat dir base suffix)
)

(defun vclip:batch-task-token-v314 ( index / s )
    (setq s (itoa index))
    (cond
        ((< index 10)  (strcat "00" s))
        ((< index 100) (strcat "0" s))
        (T s)
    )
)

(defun vclip:batch-task-path-v314 ( script index suffix )
    (vclip:batch-sidecar-path-v314
        script
        (strcat "_task_" (vclip:batch-task-token-v314 index) suffix))
)

(defun vclip:worker-helper-path-v314 ( / self candidate )
    (if (setq self (vclip:self-lisp-path-v312))
        (setq candidate
            (strcat (vclip:dir-with-sep-v34 self)
                    "VPOCLIP_worker_v3.39_brics.ps1")))
    (if (and candidate (findfile candidate))
        (findfile candidate))
)

(defun vclip:acad-exe-path-v314 ( / app root candidate fallback )
    (setq app      (vlax-get-acad-object)
          root     (vl-catch-all-apply 'vla-get-Path (list app))
          fallback "C:/Program Files/Bricsys/BricsCAD V26 en_US/bricscad.exe")
    (if (and (not (vl-catch-all-error-p root))
             root
             (/= "" root))
        (setq candidate (strcat root "\bricscad.exe")))
    (cond
        ((and candidate (vl-file-systime candidate)) candidate)
        ((vl-file-systime fallback) fallback)
        ((findfile "bricscad.exe"))
    )
)

(defun vclip:manifest-field-valid-v314 ( value )
    (and value
         (= 'STR (type value))
         (null (vl-string-search "|" value))
         (null (vl-string-search (chr 10) value))
         (null (vl-string-search (chr 13) value)))
)

(defun vclip:write-worker-task-script-v314
       ( path task lisp marker done / f r lay pattern finalpdf progress )
    (setq lay      (nth 0 task)
          pattern  (nth 3 task)
          finalpdf (nth 5 task)
          progress (strcat marker ".progress")
          f        nil)
    (if (and (vclip:manifest-field-valid-v314 lay)
             (vclip:manifest-field-valid-v314 pattern)
             (vclip:manifest-field-valid-v314 finalpdf)
             (setq f (open path "w")))
        (progn
            (setq r
                (vl-catch-all-apply
                    '(lambda ( / )
                         (write-line "(vl-load-com)" f)
                         (write-line
                             (strcat "(load "
                                     (vclip:path-lisp-string-v312 lisp)
                                     ")") f)
                         (write-line
                             (strcat "(setq vclip:self-file-v312 "
                                     (vclip:path-lisp-string-v312 lisp)
                                     ")") f)
                         (write-line
                             (strcat "(setq vclip:worker-progress-v315 "
                                     (vclip:path-lisp-string-v312 progress)
                                     ")") f)
                         (write-line "(setvar 'FILEDIA 0)" f)
                         (write-line "(setvar 'CMDDIA 0)" f)
                         (write-line
                             (strcat
                                 "(setq vclip:worker-result-v314 "
                                 "(vclip:acad-process-current-file-v312 "
                                 (vclip:lisp-string-v312 lay) " "
                                 (vclip:lisp-string-v312 pattern) " "
                                 (vclip:path-lisp-string-v312 finalpdf) " "
                                 (vclip:path-lisp-string-v312 marker)
                                 "))") f)
                         (write-line
                             (strcat
                                 "(vclip:write-control-text-v325 "
                                 (vclip:path-lisp-string-v312 done) " "
                                 "(if vclip:worker-result-v314 "
                                 (vclip:lisp-string-v312 "DONE|OK") " "
                                 (vclip:lisp-string-v312 "DONE|FAIL")
                                 "))") f)
                         ;; Quit closes the one drawing owned by this worker.
                         ;; The external controller waits for process exit.
                         (write-line "(setvar 'FILEDIA 1)" f)
                         (write-line
                             "(vl-catch-all-apply 'vla-Quit (list (vlax-get-acad-object)))"
                             f)
                         T
                     )
                    nil))
            (close f)
            (and (not (vl-catch-all-error-p r)) r)
        )
        nil
    )
)

(defun vclip:write-worker-manifest-v314
       ( manifest tasks script lisp
         / f ok index task taskscript marker done lay final finalpdf pattern )
    (setq f (open manifest "w")
          ok T
          index 0)
    (if f
        (progn
            (foreach task tasks
                (setq index      (1+ index)
                      taskscript (vclip:batch-task-path-v314
                                     script index ".scr")
                      marker     (vclip:batch-task-path-v314
                                     script index ".status")
                      done       (vclip:batch-task-path-v314
                                     script index ".done")
                      lay        (nth 0 task)
                      final      (nth 2 task)
                      finalpdf   (nth 5 task)
                      pattern    (nth 3 task))
                (vclip:file-delete-confirmed-v312 marker)
                (vclip:file-delete-confirmed-v312 done)
                (if (and ok
                         (vclip:manifest-field-valid-v314 lay)
                         (vclip:manifest-field-valid-v314 final)
                         (vclip:manifest-field-valid-v314 finalpdf)
                         (vclip:manifest-field-valid-v314 taskscript)
                         (vclip:manifest-field-valid-v314 marker)
                         (vclip:manifest-field-valid-v314 done)
                         (vclip:manifest-field-valid-v314 pattern)
                         (vclip:write-worker-task-script-v314
                             taskscript task lisp marker done))
                    (write-line
                        (strcat lay "|" final "|" finalpdf "|"
                                taskscript "|" marker "|" done "|"
                                pattern)
                        f)
                    (setq ok nil)
                )
            )
            (close f)
            (if ok manifest)
        )
        nil
    )
)

(defun vclip:cleanup-batch-sidecars-v314
       ( script count / index path )
    (vclip:file-delete-confirmed-v312
        (vclip:batch-sidecar-path-v314 script ".manifest"))
    (setq index 1)
    (while (<= index count)
        (foreach suffix '(".scr" ".status" ".done")
            (setq path
                (vclip:batch-task-path-v314 script index suffix))
            (vclip:file-delete-confirmed-v312 path))
        (setq index (1+ index))
    )
    T
)

(defun vclip:cmd-quote-v314 ( value )
    (strcat (chr 34) (if value value "") (chr 34))
)

(defun vclip:file-exists-v314 ( path )
    (and path
         (= 'STR (type path))
         (or (findfile path)
             (vl-file-systime path)))
)

(defun vclip:launch-controller-v314
       ( helper acad source manifest report overwrite
         / powershell shell cmd r )
    (setq powershell
        "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe")
    (if (and (vclip:file-exists-v314 powershell)
             (vclip:file-exists-v314 helper)
             (vclip:file-exists-v314 acad)
             (vclip:file-exists-v314 source)
             (vclip:file-exists-v314 manifest))
        (progn
            (setq cmd
                (strcat
                    (vclip:cmd-quote-v314 powershell)
                    " -NoProfile -STA -ExecutionPolicy Bypass"
                    " -File "
                    (vclip:cmd-quote-v314 helper)
                    " -BricsExe " (vclip:cmd-quote-v314 acad)
                    " -SourceDwg " (vclip:cmd-quote-v314 source)
                    " -Manifest " (vclip:cmd-quote-v314 manifest)
                    " -Report " (vclip:cmd-quote-v314 report)
                    " -Overwrite " (itoa overwrite)
                    " -ShowProgress 1"
                    " -IdleTimeoutSeconds 600")
                  shell
                    (vl-catch-all-apply
                        'vlax-create-object (list "WScript.Shell")))
            (if (vl-catch-all-error-p shell)
                (setq r shell)
                (progn
                    (setq r
                        (vl-catch-all-apply
                            'vlax-invoke-method
                            (list shell 'Run cmd 1 :vlax-false)))
                    (vlax-release-object shell)
                )
            )
            (if (vl-catch-all-error-p r)
                (progn
                    (vclip:append-text-v312 report
                        (strcat "FAIL|CONTROLLER||"
                                (vl-catch-all-error-message r)))
                    (vclip:append-text-v312 report "BATCH_END")
                    (princ
                        (strcat "
VPOCFG: nie udało się uruchomić kontrolera: "
                                (vl-catch-all-error-message r)))
                    nil)
                (progn
                    (princ
                        "
VPOCFG: kontroler uruchomiony. Zadania będą wykonywane kolejno.")
                    T)
            )
        )
        (progn
            (vclip:append-text-v312 report
                (strcat
                    "FAIL|CONTROLLER||brak pliku: powershell="
                    (if (vclip:file-exists-v314 powershell) "OK" "BRAK")
                    ", helper="
                    (if (vclip:file-exists-v314 helper) "OK" "BRAK")
                    ", acad="
                    (if (vclip:file-exists-v314 acad) "OK" "BRAK")
                    ", źródło="
                    (if (vclip:file-exists-v314 source) "OK" "BRAK")
                    ", manifest="
                    (if (vclip:file-exists-v314 manifest) "OK" "BRAK")))
            (vclip:append-text-v312 report "BATCH_END")
            (princ "
VPOCFG: brak pliku wymaganego przez kontroler v3.39.")
            nil)
    )
)


(defun vclip:run-acad-script-v312
       ( script oldfiledia oldcmddia / doc cmd r )
    (setq doc (LM:acdoc)
          cmd (strcat
                  "FILEDIA\n0\n"
                  "CMDDIA\n0\n"
                  "_.SCRIPT\n"
                  (vclip:script-quote-v37 script)
                  "\nFILEDIA\n1\n"))
    (vl-catch-all-apply 'setvar (list 'FILEDIA 0))
    (vl-catch-all-apply 'setvar (list 'CMDDIA 0))
    (setq r
        (vl-catch-all-apply 'vla-SendCommand (list doc cmd)))
    (if (vl-catch-all-error-p r)
        (progn
            (vl-catch-all-apply 'setvar (list 'FILEDIA 1))
            (vl-catch-all-apply 'setvar (list 'CMDDIA oldcmddia))
            (princ
                (strcat "\nVPOCFG: nie udało się uruchomić skryptu: "
                        (vl-catch-all-error-message r)))
            nil)
        T
    )
)
(defun vclip:canonical-path-v312 ( path / fso r )
    (setq fso
        (vl-catch-all-apply
            'vlax-create-object (list "Scripting.FileSystemObject")))
    (if (vl-catch-all-error-p fso)
        (vclip:normalize-path-v38 path)
        (progn
            (setq r
                (vl-catch-all-apply
                    'vlax-invoke-method
                    (list fso 'GetAbsolutePathName path)))
            (vlax-release-object fso)
            (if (vl-catch-all-error-p r)
                (vclip:normalize-path-v38 path)
                (vclip:normalize-path-v38 r))
        )
    )
)

(defun vclip:same-canonical-path-p-v312 ( a b )
    (and a b
         (= (vclip:canonical-path-v312 a)
            (vclip:canonical-path-v312 b)))
)

(defun vclip:layout-contract-ok-v312 ( lay / pre frames linked invalid )
    (setq pre     (vclip:collect-frames-for-layout-v312 lay)
          frames  (car pre)
          linked  (cadr pre)
          invalid (caddr pre))
    (cond
        ((= linked 0)
         (princ
             (strcat "\nVPOCFG PRECHECK: layout " lay
                     " nie ma rzutni VPO_LINK."))
         nil)
        (invalid
         (vclip:print-frame-errors-v312 invalid)
         nil)
        ((/= linked (length frames))
         (princ
             (strcat "\nVPOCFG PRECHECK: layout " lay
                     " ma niespójną liczbę rzutni i ramek."))
         nil)
        (T T)
    )
)

(defun vclip:unique-work-path-v312 ( final / dir base stamp n candidate )
    (setq dir   (vclip:dir-with-sep-v34 final)
          base  (vl-filename-base final)
          stamp (vclip:timestamp)
          n     0)
    (while
        (progn
            (setq candidate
                (strcat dir base "._VPOCLIP_WORK_" stamp
                        (if (> n 0) (strcat "_" (itoa n)) "")
                        ".dwg"))
            (setq n (1+ n))
            (or (findfile candidate)
                (findfile (vclip:work-pdf-path-v312 candidate))
                (findfile (strcat candidate ".status"))))
    )
    candidate
)

(defun vclip:copy-source-to-work-v312 ( src work / r )
    (setq r (vl-catch-all-apply 'vl-file-copy (list src work)))
    (and (not (vl-catch-all-error-p r))
         r
         (findfile work))
)

(defun vclip:prepare-task-v312
       ( src keep-lay final pattern overwrite / finalpdf )
    (cond
        ((not (vclip:layout-exists-p keep-lay))
         (princ (strcat "
VPOCFG: layout nie istnieje: " keep-lay))
         (list "FAIL" nil))
        ((not (vclip:layout-contract-ok-v312 keep-lay))
         (princ (strcat "
VPOCFG: niepoprawny kontrakt VPOutline: " keep-lay))
         (list "FAIL" nil))
        ((or (null pattern) (= "" (vclip:trim-v34 pattern)))
         (princ (strcat "
VPOCFG: pusty filtr XREF dla layoutu " keep-lay))
         (list "FAIL" nil))
        ((or (null final) (= "" final)
             (/= ".DWG" (strcase (if (vl-filename-extension final)
                                     (vl-filename-extension final) ""))))
         (princ "
VPOCFG: niepoprawna ścieżka końcowego DWG.")
         (list "FAIL" nil))
        ((vclip:same-canonical-path-p-v312 src final)
         (princ "
VPOCFG: plik wynikowy wskazuje plik źródłowy. Zadanie odrzucono.")
         (list "FAIL" nil))
        (T
         (setq finalpdf (vclip:final-pdf-path-v312 final))
         (if (and (not overwrite)
                  (or (findfile final) (findfile finalpdf)))
             (progn
                 (princ
                     (strcat "
VPOCFG: pomijam istniejącą parę wyników: "
                             final))
                 (list "SKIP" nil))
             (progn
                 ;; v3.14: no DWG/PDF work copy is created here. The external
                 ;; sequential controller creates the exact final name only
                 ;; after the previous BricsCAD worker has exited.
                 (princ (strcat "
VPOCFG: przygotowano zadanie: " final))
                 (list "OK"
                     (list keep-lay final final pattern
                           finalpdf finalpdf ""))
             )
         )
        )
    )
)

(defun vclip:new-batch-path-v312 ( srcpath ext / dir stamp )
    (setq dir   (vclip:dir-with-sep-v34 srcpath)
          stamp (vclip:timestamp))
    (strcat dir "VPOCLIP_brics_batch_" stamp ext)
)

(defun c:VPOEXPORT
       ( / srcpath pair keep-lay def final filename overwrite-key overwrite
           prepared task script report oldfiledia oldcmddia run-key )
    (vl-load-com)
    (vclip:apply-ignore-layers-config-v324)
    (setq srcpath (vclip:current-dwg-path-v31))
    (cond
        ((or (null srcpath) (not (findfile srcpath))
             (= 0 (getvar 'DWGTITLED)))
         (princ "\nVPOEXPORT: najpierw zapisz rysunek źródłowy."))
        ((/= 0 (getvar 'DBMOD))
         (princ "\nVPOEXPORT: zapisz niezapisane zmiany przed eksportem."))
        ((/= 0 (vclip:getvar-safe-v35 'SDI 0))
         (princ "\nVPOEXPORT: wymagane jest SDI=0."))
        ((null (setq pair (vclip:get-picked-vpo-pair)))
         (princ "\nVPOEXPORT: nie wskazano poprawnej rzutni lub ramki VPO."))
        (T
         (setq keep-lay (caddr pair)
               def (strcat
                       (vclip:dir-with-sep-v34 srcpath)
                       (vl-filename-base srcpath)
                       "_" keep-lay "_VPOEXPORT.dwg")
               final (getfiled "Zapisz eksport VPO jako" def "dwg" 1))
         (if final
             (progn
                 (if (null (vl-filename-extension final))
                     (setq final (strcat final ".dwg")))
                 (setq filename
                     (strcat (vl-filename-base final)
                             (if (vl-filename-extension final)
                                 (vl-filename-extension final) "")))
                 (if (not (vclip:valid-output-name-v312 filename))
                     (princ "\nVPOEXPORT: niedozwolona nazwa pliku wynikowego.")
                     (progn
                         (setq overwrite nil)
                         (if (or (findfile final)
                                 (findfile (vclip:final-pdf-path-v312 final)))
                             (progn
                                 (initget "Tak Nie")
                                 (setq overwrite-key
                                     (getkword
                                         "\nVPOEXPORT: zastąpić istniejące wyniki po pełnym sukcesie? [Tak/Nie] <Nie>: ")
                                       overwrite (= overwrite-key "Tak"))))
                         (setq prepared
                             (vclip:prepare-task-v312
                                 srcpath keep-lay final "*" overwrite))
                         (if (= "OK" (car prepared))
                             (progn
                                 (setq task        (cadr prepared)
                                       script      (vclip:new-batch-path-v312 srcpath ".scr")
                                       report      (vclip:new-batch-path-v312 srcpath ".txt")
                                       oldfiledia  (vclip:getvar-safe-v35 'FILEDIA 1)
                                       oldcmddia   (vclip:getvar-safe-v35 'CMDDIA 1)
                                       vclip:batch-report-v312 report)
                                 (vclip:write-text-v312 report
                                     (strcat "VPOCLIP " vclip:version-v312
                                             "|START|tasks=1|source=" srcpath))
                                 (if (vclip:write-acad-batch-script-v312
                                         script (list task) overwrite report
                                         oldfiledia oldcmddia nil)
                                     (progn
                                         (initget "Tak Nie")
                                         (setq run-key
                                             (getkword
                                                 "\nVPOEXPORT: uruchomić eksport teraz? [Tak/Nie] <Tak>: "))
                                         (if (/= run-key "Nie")
                                             (vclip:run-acad-script-v312
                                                 script oldfiledia oldcmddia)
                                             (princ
                                                 (strcat "\nVPOEXPORT: uruchom SCRIPT i wskaż: "
                                                         script))))
                                     (princ "\nVPOEXPORT: nie udało się utworzyć skryptu."))
                             )
                             (if (= "SKIP" (car prepared))
                                 (princ "\nVPOEXPORT: istniejące wyniki pozostawiono bez zmian.")
                                 (princ "\nVPOEXPORT: przygotowanie zadania nie powiodło się."))
                         )
                     )
                 )
             )
         )
        )
    )
    (princ)
)

(defun c:VPOCLIP ( / pair keep-lay result )
    (vl-load-com)
    (vclip:apply-ignore-layers-config-v324)
    (cond
        ((= 0 (getvar 'DWGTITLED))
         (princ "\nVPOCLIP: najpierw zapisz rysunek. Bez aktualnej kopii zapasowej operacja nie zostanie uruchomiona."))
        ((/= 0 (getvar 'DBMOD))
         (princ "\nVPOCLIP: rysunek ma niezapisane zmiany. Zapisz go przed uruchomieniem VPOCLIP."))
        ((null (setq pair (vclip:get-picked-vpo-pair)))
         (princ "\nVPOCLIP: nie wskazano poprawnej rzutni lub ramki VPO."))
        (T
         (setq keep-lay (caddr pair)
               result
                 (vclip:clip-current-document-by-layout-v312
                     keep-lay T T "__VPO_NO_EXTRA_XREF__"))
         (if result
             (progn
                 (vclip:purge-all-v33)
                 (princ "\nVPOCLIP 3.39-brics: zakończono poprawnie."))
             (princ "\nVPOCLIP 3.39-brics: operacja przerwana lub wycofana."))
        )
    )
    (princ)
)

(defun c:VPORESET ( )
    (vl-catch-all-apply 'setvar (list 'FILEDIA 1))
    (vl-catch-all-apply 'setvar (list 'CMDDIA 1))
    (vl-catch-all-apply 'setvar (list 'BACKGROUNDPLOT 2))
    (princ "\nVPORESET: przywrócono FILEDIA=1, CMDDIA=1, BACKGROUNDPLOT=2.")
    (princ)
)

(defun c:VPOONLY () (c:VPOCLIP))
(defun c:VPOONLYEXPORT () (c:VPOEXPORT))

;;==================================================================;;
;;  OVERRIDE v3.39-brics - szybka kolejka WBLOCK w jednym procesie   ;;
;;==================================================================;;



(defun vclip:fast-progress-v324 ( path index code detail )
    (vclip:write-control-text-v325 path
        (strcat (itoa index) "|" code "|" (if detail detail "")))
)

(defun vclip:fast-result-v324 ( path index status lay detail )
    (vclip:append-control-text-v325 path
        (strcat (itoa index) "|" status "|" lay "|"
                (if detail detail "")))
)

(defun vclip:undo-mark-v324 ( / r oldecho )
    (setq oldecho (vclip:getvar-safe-v35 'CMDECHO 1))
    (vl-catch-all-apply 'setvar (list 'CMDECHO 0))
    (setq r
        (vl-catch-all-apply
            '(lambda ( / ) (vl-cmdf "_.UNDO" "_Mark"))
            nil))
    (vl-catch-all-apply 'setvar (list 'CMDECHO oldecho))
    (not (vl-catch-all-error-p r))
)
(defun vclip:wblock-current-v324
       ( path / oldecho oldexpert oldcmddia oldtile oldctab r ok )
    (setq oldecho  (vclip:getvar-safe-v35 'CMDECHO 1)
          oldexpert (vclip:getvar-safe-v35 'EXPERT 0)
          oldcmddia (vclip:getvar-safe-v35 'CMDDIA 1)
          oldtile   (vclip:getvar-safe-v35 'TILEMODE 0)
          oldctab   (vclip:getvar-safe-v35 'CTAB "Model")
          ok        nil)
    (vclip:file-delete-confirmed-v312 path)
    (setq r
        (vl-catch-all-apply
            '(lambda ( / )
                 (setvar 'CMDECHO 0)
                 (setvar 'EXPERT 2)
                 (setvar 'CMDDIA 0)
                 (setvar 'TILEMODE 1)
                 (vl-cmdf "_.UCS" "_World")
                 (setvar 'TILEMODE 0)
                 (vl-cmdf "_.-WBLOCK" path "*")
                 (if (> (logand 1 (getvar 'CMDACTIVE)) 0)
                     (vl-cmdf "_Y"))
                 T)
            nil))
    (vl-catch-all-apply 'setvar (list 'CMDECHO oldecho))
    (vl-catch-all-apply 'setvar (list 'EXPERT oldexpert))
    (vl-catch-all-apply 'setvar (list 'CMDDIA oldcmddia))
    (vl-catch-all-apply 'setvar (list 'TILEMODE oldtile))
    (if (and oldctab (vclip:layout-exists-p oldctab))
        (vl-catch-all-apply 'setvar (list 'CTAB oldctab)))
    (setq ok
        (and (not (vl-catch-all-error-p r))
             r
             (findfile path)
             (> (vl-file-size path) 100)))
    (if (not ok) (vclip:file-delete-confirmed-v312 path))
    ok
)


(defun vclip:fast-batch-run-v324
       ( manifest progress results / rows total index rec result fatal allok )
    (setq vclip:active-xref-key-v333 nil)
    (setq rows  (vclip:read-fast-manifest-v324 manifest)
          total (length rows)
          index 0
          fatal nil
          allok T)
    (vclip:file-delete-confirmed-v312 results)
    (if (= total 0)
        nil
        (progn
            (foreach rec rows
                (setq index (1+ index))
                (if fatal
                    (progn
                        (vclip:fast-result-v324 results index "FAIL"
                            (car rec) "pominieto po bledzie UNDO")
                        (vclip:fast-progress-v324 progress index "TASK_FAIL"
                            "Pominieto po bledzie przywracania kopii")
                        (setq allok nil))
                    (progn
                        (setq result
                            (vclip:fast-export-task-v324
                                rec index total progress))
                        (vclip:fast-result-v324 results index
                            (if (car result) "OK" "FAIL")
                            (car rec) (cadr result))
                        (if (not (car result)) (setq allok nil))
                        (if (not (caddr result)) (setq fatal T))))
            )
            (vclip:fast-progress-v324 progress total "FINAL"
                (if allok
                    "Wszystkie zadania zakonczone"
                    "Kolejka zakonczona z bledami"))
            allok))
)


(defun vclip:write-fast-worker-script-v324
       ( path lisp manifest progress results done / f r )
    (setq f (vclip:open-control-v325 path "w"))
    (if f
        (progn
            (setq r
                (vl-catch-all-apply
                    '(lambda ( / )
                         (write-line "(vl-load-com)" f)
                         (write-line
                             (strcat "(load "
                                     (vclip:path-lisp-string-v312 lisp)
                                     ")") f)
                         (write-line
                             (strcat "(setq vclip:self-file-v312 "
                                     (vclip:path-lisp-string-v312 lisp)
                                     ")") f)
                         (write-line "(setvar 'FILEDIA 0)" f)
                         (write-line "(setvar 'CMDDIA 0)" f)
                         (write-line "(setvar 'BACKGROUNDPLOT 0)" f)
                         (write-line
                             (strcat
                                 "(setq vclip:fast-run-v324 "
                                 "(vl-catch-all-apply 'vclip:fast-batch-run-v324 "
                                 "(list "
                                 (vclip:path-lisp-string-v312 manifest) " "
                                 (vclip:path-lisp-string-v312 progress) " "
                                 (vclip:path-lisp-string-v312 results)
                                 ")))" ) f)
                         (write-line
                             (strcat "(vclip:write-control-text-v325 "
                                     (vclip:path-lisp-string-v312 done) " "
                                     "(if (vl-catch-all-error-p vclip:fast-run-v324) "
                                     (vclip:lisp-string-v312 "DONE|FAIL") " "
                                     (vclip:lisp-string-v312 "DONE|COMPLETE")
                                     "))") f)
                         (write-line
                             "(vl-catch-all-apply 'vclip:save-doc-v31 (list (LM:acdoc)))"
                             f)
                         (write-line "(setvar 'FILEDIA 1)" f)
                         (write-line
                             "(vl-catch-all-apply 'vla-Quit (list (vlax-get-acad-object)))"
                             f)
                         T)
                    nil))
            (close f)
            (and (not (vl-catch-all-error-p r)) r))
    )
)

(defun vclip:worker-helper-path-v324 ( / self candidate )
    (if (setq self (vclip:self-lisp-path-v312))
        (setq candidate
            (strcat (vclip:dir-with-sep-v34 self)
                    "VPOCLIP_worker_v3.39_brics.ps1")))
    (if (and candidate (findfile candidate)) (findfile candidate))
)

(defun vclip:disable-proxy-dialog-v324
       ( / acad preferences open-save r )
    (vl-catch-all-apply 'setvar (list "PROXYNOTICE" 0))
    (setq acad
        (vl-catch-all-apply 'vlax-get-acad-object nil))
    (if (not (vl-catch-all-error-p acad))
        (progn
            (setq preferences
                (vl-catch-all-apply 'vla-get-Preferences (list acad)))
            (if (not (vl-catch-all-error-p preferences))
                (progn
                    (setq open-save
                        (vl-catch-all-apply
                            'vla-get-OpenSave (list preferences)))
                    (if (not (vl-catch-all-error-p open-save))
                        (setq r
                            (vl-catch-all-apply
                                'vla-put-ShowProxyDialogBox
                                (list open-save :vlax-false))))))))
    (if (and open-save (not (vl-catch-all-error-p open-save)))
        (vl-catch-all-apply 'vlax-release-object (list open-save)))
    (if (and preferences (not (vl-catch-all-error-p preferences)))
        (vl-catch-all-apply 'vlax-release-object (list preferences)))
    (and (= 0 (vclip:getvar-safe-v35 "PROXYNOTICE" 1))
         (or (null r) (not (vl-catch-all-error-p r))))
)

(defun vclip:launch-controller-v324
       ( helper acad source manifest report worker progress done results overwrite
         process-all / powershell shell cmd r profile )
    (setq powershell
            "C:/Windows/System32/WindowsPowerShell/v1.0/powershell.exe"
          profile
            (vclip:getvar-safe-v35 "CPROFILE" ""))
    (if (and (vclip:file-exists-v314 powershell)
             (vclip:file-exists-v314 helper)
             (vclip:file-exists-v314 acad)
             (vclip:file-exists-v314 source)
             (vclip:file-exists-v314 manifest)
             (vclip:file-exists-v314 worker))
        (progn
            (setq cmd
                (strcat
                    (vclip:cmd-quote-v314 powershell)
                    " -NoProfile -STA -ExecutionPolicy Bypass -File "
                    (vclip:cmd-quote-v314 helper)
                    " -BricsExe " (vclip:cmd-quote-v314 acad)
                    " -SourceDwg " (vclip:cmd-quote-v314 source)
                    " -Manifest " (vclip:cmd-quote-v314 manifest)
                    " -Report " (vclip:cmd-quote-v314 report)
                    " -WorkerScript " (vclip:cmd-quote-v314 worker)
                    " -Progress " (vclip:cmd-quote-v314 progress)
                    " -Done " (vclip:cmd-quote-v314 done)
                    " -Results " (vclip:cmd-quote-v314 results)
                    " -Overwrite " (itoa overwrite)
                    " -ProcessAllLayouts "
                    (cond
                        ((eq process-all 'LCLIP) "-1")
                        (process-all "1")
                        (T "0"))
                    " -BricsProfile " (vclip:cmd-quote-v314 profile)
                    " -ShowProgress 1 -IdleTimeoutSeconds 600")
                  shell
                    (vl-catch-all-apply
                        'vlax-create-object (list "WScript.Shell")))
            (if (vl-catch-all-error-p shell)
                (setq r shell)
                (progn
                    (vclip:disable-proxy-dialog-v324)
                    (setq r
                        (vl-catch-all-apply
                            'vlax-invoke-method
                            (list shell 'Run cmd 1 :vlax-false)))
                    (vlax-release-object shell)))
            (if (vl-catch-all-error-p r)
                (progn
                    (vclip:append-text-v312 report
                        (strcat "FAIL|CONTROLLER||"
                                (vl-catch-all-error-message r)))
                    (vclip:append-text-v312 report "BATCH_END")
                    nil)
                (progn
                    (princ
                        "\nVPOCFG FAST: eksport uruchomiono w tle; panel pokazuje postep.")
                    T)))
        (progn
            (vclip:append-text-v312 report
                "FAIL|CONTROLLER||brak pliku wymaganego przez szybki kontroler")
            (vclip:append-text-v312 report "BATCH_END")
            nil))
)

(defun vclip:write-acad-batch-script-v312
       ( script tasks overwrite report oldfiledia oldcmddia process-all
         / f r lisp source helper acad manifest worker progress done results
           taskcount )
    (setq lisp      (vclip:self-lisp-path-v312)
          source    (vclip:current-dwg-path-v31)
          helper    (vclip:worker-helper-path-v324)
          acad      (vclip:acad-exe-path-v314)
          manifest  (vclip:batch-sidecar-path-v314 script ".manifest")
          worker    (vclip:batch-sidecar-path-v314 script "_worker.scr")
          progress  (vclip:batch-sidecar-path-v314 script ".progress")
          done      (vclip:batch-sidecar-path-v314 script ".done")
          results   (vclip:batch-sidecar-path-v314 script ".results")
          taskcount (length tasks)
          f         nil)
    (foreach path (list manifest worker progress done results)
        (vclip:file-delete-confirmed-v312 path))
    (if (and lisp source helper acad (> taskcount 0)
             (vclip:write-fast-manifest-v324 manifest tasks)
             (vclip:write-fast-worker-script-v324
                 worker lisp manifest progress results done)
             (setq f (vclip:open-control-v325 script "w")))
        (progn
            (setq r
                (vl-catch-all-apply
                    '(lambda ( / )
                         (write-line "(vl-load-com)" f)
                         (write-line
                             (strcat "(load "
                                     (vclip:path-lisp-string-v312 lisp)
                                     ")") f)
                         (write-line
                             (strcat "(setq vclip:self-file-v312 "
                                     (vclip:path-lisp-string-v312 lisp)
                                     ")") f)
                         (write-line
                             (strcat
                                 "(vclip:launch-controller-v324 "
                                 (vclip:path-lisp-string-v312 helper) " "
                                 (vclip:path-lisp-string-v312 acad) " "
                                 (vclip:path-lisp-string-v312 source) " "
                                 (vclip:path-lisp-string-v312 manifest) " "
                                 (vclip:path-lisp-string-v312 report) " "
                                 (vclip:path-lisp-string-v312 worker) " "
                                 (vclip:path-lisp-string-v312 progress) " "
                                 (vclip:path-lisp-string-v312 done) " "
                                 (vclip:path-lisp-string-v312 results) " "
                                 (if overwrite "1" "0") " "
                                 (if process-all "T" "nil") ")") f)
                         (write-line "(setvar 'FILEDIA 1)" f)
                         (write-line
                             (strcat "(setvar 'CMDDIA "
                                     (itoa oldcmddia) ")") f)
                         T)
                    nil))
            (close f)
            (if (and (not (vl-catch-all-error-p r)) r)
                script
                (progn
                    (foreach path (list manifest worker progress done results)
                        (vclip:file-delete-confirmed-v312 path))
                    nil)))
        (progn
            (if f (close f))
            (foreach path (list manifest worker progress done results)
                (vclip:file-delete-confirmed-v312 path))
            nil))
)


;;------------------------------------------------------------------;;
;;  OVERRIDE v3.39-brics - wspolny katalog wynikowy obok LISP        ;;
;;------------------------------------------------------------------;;
(defun vclip:export-dir-v324 ( / self dir made )
    (if (setq self (vclip:self-lisp-path-v312))
        (progn
            (setq dir
                (strcat
                    (vclip:dir-with-sep-v34 self)
                    "VPOCLIP_export"))
            (cond
                ((vl-file-directory-p dir) dir)
                (T
                 (setq made
                     (vl-catch-all-apply 'vl-mkdir (list dir)))
                 (if (and (not (vl-catch-all-error-p made))
                          (vl-file-directory-p dir))
                     (progn
                         (princ
                             (strcat
                                 "\nVPOCFG: utworzono katalog wynikowy: "
                                 dir))
                         dir)
                     (progn
                         (princ
                             (strcat
                                 "\nVPOCFG: nie mozna utworzyc katalogu wynikowego: "
                                 dir))
                         nil))))))
)

(defun vclip:target-path-safe-v312 ( srcpath filename / name dir )
    ;; srcpath pozostaje w sygnaturze dla zgodnosci ze starszym kodem.
    (if (and (setq name (vclip:validated-dwg-name-v312 filename))
             (setq dir (vclip:export-dir-v324)))
        (strcat dir "\\" name))
)

(defun vclip:target-path-from-config-v34 ( srcpath filename )
    (vclip:target-path-safe-v312 srcpath filename)
)
;;------------------------------------------------------------------;;
;;  OVERRIDE v3.39-brics - rozszerzony VPOCLIP_CONF.txt              ;;
;;------------------------------------------------------------------;;

(defun vclip:split-string-v324 ( text separator / pos parts seplen )
    (setq parts nil seplen (strlen separator))
    (while (setq pos (vl-string-search separator text))
        (setq parts (cons (substr text 1 pos) parts)
              text  (substr text (+ pos seplen 1))))
    (reverse (cons text parts))
)

(defun vclip:parse-yes-no-v324 ( value / up )
    (setq up (strcase (vclip:trim-v34 value)))
    (cond ((= up "YES") T)
          ((= up "NO") nil)
          (T 'VPO_INVALID))
)

(defun vclip:config-key-v324 ( value )
    (strcase (vl-string-translate " -" "__" (vclip:trim-v34 value)))
)

(defun vclip:config-section-line-p-v324 ( text )
    (and (> (strlen text) 2)
         (= "[" (substr text 1 1))
         (= "]" (substr text (strlen text) 1)))
)

(defun vclip:read-config-v324
       ( path / fh line txt lineno section eqpos key value parsed rec
         tasks errors config-version create-dwg create-pdf pdf-from-source default-folder
         user-export-path dwg-template pdf-template process-all ignore-xref auto-create-frames
         exclude-layouts ignore-layers )
    (setq lineno 0 section "" tasks nil errors 0 config-version "1"
          create-dwg T create-pdf T pdf-from-source T default-folder T user-export-path ""
          dwg-template "<source>_<layout>" pdf-template "<source>_<layout>"
          process-all nil ignore-xref nil auto-create-frames T exclude-layouts "" ignore-layers "_Podzia? na odcinki")
    (if (setq fh (vclip:open-control-v325 path "r"))
        (progn
            (while (setq line (read-line fh))
                (setq lineno (1+ lineno) txt (vclip:trim-v34 line))
                (cond
                    ((or (= txt "") (= "#" (substr txt 1 1))) nil)
                    ((vclip:config-section-line-p-v324 txt)
                     (setq section
                         (strcase (vclip:trim-v34
                             (substr txt 2 (- (strlen txt) 2)))))
                     (if (not (member section '("OUTPUT" "PROCESSING" "TASKS")))
                         (progn
                             (setq errors (1+ errors))
                             (princ (strcat "\nVPOCFG: nieznana sekcja w wierszu "
                                            (itoa lineno) ": " txt)))))
                    ((setq eqpos (vl-string-search "=" txt))
                     (setq key (vclip:config-key-v324 (substr txt 1 eqpos))
                           value (vclip:trim-v34 (substr txt (+ eqpos 2))))
                     (cond
                         ((= key "CONFIG_VERSION") (setq config-version value))
                         ((member key '("CREATE_DWG" "CREATE_PDF" "PDF_FROM_SOURCE" "DEFAULT_FOLDER"
                                        "PROCESS_ALL_LAYOUTS" "IGNORE_XREF" "AUTO_CREATE_FRAMES"))
                          (setq parsed (vclip:parse-yes-no-v324 value))
                          (if (eq parsed 'VPO_INVALID)
                              (progn
                                  (setq errors (1+ errors))
                                  (princ (strcat "\nVPOCFG: opcja " key
                                      " wymaga YES albo NO (wiersz "
                                      (itoa lineno) ").")))
                              (cond
                                  ((= key "CREATE_DWG") (setq create-dwg parsed))
                                  ((= key "CREATE_PDF") (setq create-pdf parsed))
                                  ((= key "PDF_FROM_SOURCE") (setq pdf-from-source parsed))
                                  ((= key "DEFAULT_FOLDER") (setq default-folder parsed))
                                  ((= key "PROCESS_ALL_LAYOUTS") (setq process-all parsed))
                                  ((= key "IGNORE_XREF") (setq ignore-xref parsed))
                                  ((= key "AUTO_CREATE_FRAMES") (setq auto-create-frames parsed)))))
                         ((= key "USER_EXPORT_PATH") (setq user-export-path value))
                         ((= key "DWG_NAME_TEMPLATE") (setq dwg-template value))
                         ((= key "PDF_NAME_TEMPLATE") (setq pdf-template value))
                         ((= key "EXCLUDE_LAYOUTS") (setq exclude-layouts value))
                         ((= key "IGNORE_LAYERS") (setq ignore-layers value))
                         (T
                          (setq errors (1+ errors))
                          (princ (strcat "\nVPOCFG: nieznana opcja w wierszu "
                                         (itoa lineno) ": " key)))))
                    ((or (= section "TASKS") (= section ""))
                     (setq rec (vclip:parse-config-line-v34 txt))
                     (if (and rec (= 3 (length rec))
                              (/= "" (car rec)) (/= "" (cadr rec))
                              (not (wcmatch (strcase (car rec)) "NAZWA LAYOUTA*")))
                         (setq tasks (cons rec tasks))
                         (if (not (wcmatch (strcase txt) "NAZWA LAYOUTA*"))
                             (progn
                                 (setq errors (1+ errors))
                                 (princ (strcat "\nVPOCFG: niepoprawne zadanie w wierszu "
                                                (itoa lineno) ": " txt))))))
                    (T
                     (setq errors (1+ errors))
                     (princ (strcat "\nVPOCFG: nierozpoznany wiersz "
                                    (itoa lineno) ": " txt)))))
            (close fh)
            (if (/= config-version "1")
                (progn
                    (setq errors (1+ errors))
                    (princ (strcat "\nVPOCFG: nieobslugiwana Config_Version="
                                   config-version "."))))
            (if (and (not create-dwg) (not create-pdf))
                (progn
                    (setq errors (1+ errors))
                    (princ "\nVPOCFG: Create_DWG i Create_PDF nie moga jednoczesnie miec wartosci NO.")))
            (if (and (not default-folder) (= user-export-path ""))
                (progn
                    (setq errors (1+ errors))
                    (princ "\nVPOCFG: Default_Folder=NO wymaga User_Export_Path.")))
            (if (and process-all
                     (or (and create-dwg
                              (null (vl-string-search "<layout>" dwg-template)))
                         (and create-pdf
                              (null (vl-string-search "<layout>" pdf-template)))))
                (progn
                    (setq errors (1+ errors))
                    (princ "\nVPOCFG: aktywny szablon nazwy musi zawierac token <layout>.")))
            (if (and (not process-all) (null tasks))
                (progn
                    (setq errors (1+ errors))
                    (princ "\nVPOCFG: Process_All_Layouts=NO wymaga zadan w sekcji [TASKS].")))
            (if (and (not process-all) (not ignore-xref))
                (foreach rec tasks
                    (if (= "" (vclip:trim-v34 (caddr rec)))
                        (progn
                            (setq errors (1+ errors))
                            (princ (strcat "\nVPOCFG: pusty filtr XREF dla layoutu "
                                           (car rec) "."))))))
            (if (> errors 0)
                (progn
                    (princ (strcat "\nVPOCFG: liczba bledow konfiguracji: "
                                   (itoa errors)))
                    nil)
                (list
                    (cons 'CONFIG_VERSION config-version)
                    (cons 'CREATE_DWG create-dwg)
                    (cons 'CREATE_PDF create-pdf)
                    (cons 'PDF_FROM_SOURCE pdf-from-source)
                    (cons 'DEFAULT_FOLDER default-folder)
                    (cons 'USER_EXPORT_PATH user-export-path)
                    (cons 'DWG_NAME_TEMPLATE dwg-template)
                    (cons 'PDF_NAME_TEMPLATE pdf-template)
                    (cons 'PROCESS_ALL_LAYOUTS process-all)
                    (cons 'IGNORE_XREF ignore-xref)
                    (cons 'AUTO_CREATE_FRAMES auto-create-frames)
                    (cons 'EXCLUDE_LAYOUTS exclude-layouts)
                    (cons 'IGNORE_LAYERS ignore-layers)
                    (cons 'TASKS (reverse tasks)))))
        (progn
            (princ (strcat "\nVPOCFG: nie udalo sie otworzyc konfiguracji: " path))
            nil))
)

(defun vclip:config-value-v324 ( key config ) (cdr (assoc key config)))

(defun vclip:apply-ignore-layers-config-v324 ( / self cfg config value )
    (vclip:set-ignore-layers-v324 "_Podzia? na odcinki")
    (if (and (setq self (vclip:self-lisp-path-v312))
             (setq cfg (findfile
                 (strcat (vclip:dir-with-sep-v34 self) "VPOCLIP_CONF.txt")))
             (setq config (vclip:read-config-v324 cfg))
             (setq value (assoc 'IGNORE_LAYERS config)))
        (vclip:set-ignore-layers-v324 (cdr value)))
    vclip:ignore-layer-patterns-v324
)
(defun vclip:ensure-directory-v324 ( path / clean made )
    (setq clean (vl-string-right-trim "\\/" (vclip:trim-v34 path)))
    (cond
        ((= clean "") nil)
        ((vl-file-directory-p clean) clean)
        (T
         (setq made (vl-catch-all-apply 'vl-mkdir (list clean)))
         (if (and (not (vl-catch-all-error-p made))
                  (vl-file-directory-p clean))
             clean
             (progn
                 (princ (strcat "\nVPOCFG: nie mozna utworzyc katalogu: " clean))
                 nil))))
)

(defun vclip:config-export-dir-v324 ( config / self dir )
    (if (vclip:config-value-v324 'DEFAULT_FOLDER config)
        (if (setq self (vclip:self-lisp-path-v312))
            (setq dir (strcat (vclip:dir-with-sep-v34 self) "VPOCLIP_export")))
        (setq dir (vclip:config-value-v324 'USER_EXPORT_PATH config)))
    (if dir (vclip:ensure-directory-v324 dir))
)

(defun vclip:replace-all-v324 ( text token replacement / pos )
    (if (setq pos (vl-string-search token text))
        (strcat (substr text 1 pos) replacement
            (vclip:replace-all-v324
                (substr text (+ pos (strlen token) 1)) token replacement))
        text)
)

(defun vclip:expand-name-template-v324 ( template source layout )
    (vclip:replace-all-v324
        (vclip:replace-all-v324 template "<source>" source)
        "<layout>" layout)
)

(defun vclip:valid-output-name-for-ext-v324
       ( value wanted-ext / s ext base last dirpart )
    (setq s (vclip:trim-v34 value)
          ext (if (/= s "") (vl-filename-extension s))
          base (if (/= s "") (vl-filename-base s))
          dirpart (if (/= s "") (vl-filename-directory s))
          last (if (> (strlen s) 0) (substr s (strlen s) 1) ""))
    (and (/= s "") base (/= base "")
         (or (null dirpart) (= "" dirpart))
         (not (vclip:string-has-any-v312
                  s (list "\\" "/" ":" "*" "?" "<" ">" "|" (chr 34))))
         (not (vl-string-search ".." s))
         (/= last ".")
         (or (null ext) (= (strcase wanted-ext) (strcase ext)))
         (not (vclip:reserved-filename-p-v312 base)))
)

(defun vclip:validated-output-name-v324 ( value wanted-ext / s )
    (setq s (vclip:trim-v34 value))
    (if (vclip:valid-output-name-for-ext-v324 s wanted-ext)
        (if (vl-filename-extension s) s (strcat s wanted-ext)))
)

(defun vclip:path-in-dir-v324 ( dir name )
    (strcat (vl-string-right-trim "\\/" dir) "\\" name)
)

(defun vclip:layout-excluded-p-v324 ( layout patterns / hit pattern )
    (setq hit nil)
    (foreach pattern patterns
        (setq pattern (vclip:trim-v34 pattern))
        (if (and (not hit) (/= pattern "")
                 (wcmatch (strcase layout) (strcase pattern)))
            (setq hit T)))
    hit
)

(defun vclip:paper-layouts-v324 ( exclude-text / result lay patterns )
    (setq patterns (vclip:split-string-v324 exclude-text ";") result nil)
    (foreach lay (layoutlist)
        (if (not (vclip:layout-excluded-p-v324 lay patterns))
            (setq result (cons lay result))))
    (reverse result)
)

(defun vclip:layout-xref-pattern-v333 ( layout / clean )
    (setq clean (vclip:trim-v34 layout))
    (if (>= (strlen clean) 2)
        (strcat "*- " (strcase (substr clean 1 2)))
        nil)
)
(defun vclip:prepare-config-task-v324
       ( src keep-lay finaldwg finalpdf pattern overwrite create-dwg create-pdf
         ignore-layers ignore-xref pdf-from-source auto-create-frames / exists-output needs-cleanup )
    (setq needs-cleanup
            (or create-dwg (and create-pdf (not pdf-from-source)))
          exists-output
            (or (and create-dwg (findfile finaldwg))
            (and create-pdf (findfile finalpdf))))
    (cond
        ((not (vclip:layout-exists-p keep-lay))
         (princ (strcat "\nVPOCFG: layout nie istnieje: " keep-lay))
         (list "FAIL" nil))
        ((and needs-cleanup
               (not (vclip:layout-ready-for-cleanup-v339
                        keep-lay auto-create-frames)))
         (princ (strcat "\nVPOCFG: niepoprawny kontrakt VPOutline: " keep-lay))
         (list "FAIL" nil))
        ((or (null pattern) (= "" (vclip:trim-v34 pattern)))
         (princ (strcat "\nVPOCFG: pusty filtr XREF: " keep-lay))
         (list "FAIL" nil))
        ((or (null finaldwg) (null finalpdf))
         (princ "\nVPOCFG: niepoprawna sciezka wyniku.")
         (list "FAIL" nil))
        ((and create-dwg (vclip:same-canonical-path-p-v312 src finaldwg))
         (princ "\nVPOCFG: wynik DWG wskazuje plik zrodlowy.")
         (list "FAIL" nil))
        ((and exists-output (not overwrite))
         (princ (strcat "\nVPOCFG: pomijam istniejacy wynik layoutu " keep-lay))
         (list "SKIP" nil))
        (T
         (princ (strcat "\nVPOCFG: przygotowano zadanie: " keep-lay))
         (list "OK"
             (list keep-lay finaldwg finaldwg pattern
                   finalpdf finalpdf ""
                   (if create-dwg "1" "0")
                   (if create-pdf "1" "0")
                   ignore-layers
                   (if ignore-xref "1" "0")
                   (if pdf-from-source "1" "0")
                   (if auto-create-frames "1" "0")))))
)

(defun vclip:build-config-tasks-v324
       ( src config overwrite / output-dir source-name create-dwg create-pdf
         process-all ignore-xref pdf-from-source auto-create-frames ignore-layers dwg-template pdf-template rows layouts rec lay
         rawname dwgname pdfname finaldwg finalpdf pattern prepared status task
         tasks seen ok skip fail collision-key )
    (setq tasks nil seen nil ok 0 skip 0 fail 0 rows nil
          source-name (vl-filename-base src)
          create-dwg (vclip:config-value-v324 'CREATE_DWG config)
          create-pdf (vclip:config-value-v324 'CREATE_PDF config)
          process-all (vclip:config-value-v324 'PROCESS_ALL_LAYOUTS config)
          ignore-xref (vclip:config-value-v324 'IGNORE_XREF config)
          pdf-from-source (vclip:config-value-v324 'PDF_FROM_SOURCE config)
          auto-create-frames (vclip:config-value-v324 'AUTO_CREATE_FRAMES config)
          ignore-layers (vclip:config-value-v324 'IGNORE_LAYERS config)
          dwg-template (vclip:config-value-v324 'DWG_NAME_TEMPLATE config)
          pdf-template (vclip:config-value-v324 'PDF_NAME_TEMPLATE config))
    (if (setq output-dir (vclip:config-export-dir-v324 config))
        (progn
            (if process-all
                (progn
                    (setq layouts (vclip:paper-layouts-v324
                        (vclip:config-value-v324 'EXCLUDE_LAYOUTS config)))
                    (if (null layouts)
                        (progn (setq fail (1+ fail))
                               (princ "\nVPOCFG: brak layoutow do eksportu.")))
                    (foreach lay layouts
                        (setq dwgname
                            (vclip:validated-output-name-v324
                                (if create-dwg
                                    (vclip:expand-name-template-v324
                                        dwg-template source-name lay)
                                    (strcat source-name "_" lay)) ".dwg")
                              pdfname
                            (vclip:validated-output-name-v324
                                (if create-pdf
                                    (vclip:expand-name-template-v324
                                        pdf-template source-name lay)
                                    (strcat source-name "_" lay)) ".pdf")
                              pattern (if ignore-xref
                                          "*"
                                          (vclip:layout-xref-pattern-v333 lay))
                              rows (cons (list lay dwgname pdfname pattern) rows))))
                (foreach rec (vclip:config-value-v324 'TASKS config)
                    (setq rawname (cadr rec)
                          dwgname (vclip:validated-output-name-v324 rawname ".dwg")
                          pdfname (if dwgname
                              (vclip:validated-output-name-v324
                                  (vl-filename-base dwgname) ".pdf"))
                          pattern (if ignore-xref "*"
                                      (vclip:trim-v34 (caddr rec)))
                          rows (cons (list (car rec) dwgname pdfname pattern) rows))))
            (setq rows (reverse rows))
            (foreach rec rows
                (setq lay (nth 0 rec) dwgname (nth 1 rec)
                      pdfname (nth 2 rec) pattern (nth 3 rec))
                (cond
                    ((or (null dwgname) (null pdfname))
                     (setq fail (1+ fail))
                     (princ (strcat "\nVPOCFG: niedozwolona nazwa wyniku: " lay)))
                    (T
                     (setq finaldwg (vclip:path-in-dir-v324 output-dir dwgname)
                           finalpdf (vclip:path-in-dir-v324 output-dir pdfname)
                           collision-key nil)
                     (if (and create-dwg
                              (member (vclip:canonical-path-v312 finaldwg) seen))
                         (setq collision-key finaldwg))
                     (if (and (not collision-key) create-pdf
                              (member (vclip:canonical-path-v312 finalpdf) seen))
                         (setq collision-key finalpdf))
                     (if collision-key
                         (progn
                             (setq fail (1+ fail))
                             (princ (strcat "\nVPOCFG: powtorzona nazwa wyniku: "
                                            collision-key)))
                         (progn
                             (if create-dwg
                                 (setq seen (cons
                                     (vclip:canonical-path-v312 finaldwg) seen)))
                             (if create-pdf
                                 (setq seen (cons
                                     (vclip:canonical-path-v312 finalpdf) seen)))
                             (setq prepared
                                 (vclip:prepare-config-task-v324
                                     src lay finaldwg finalpdf pattern overwrite
                                     create-dwg create-pdf ignore-layers ignore-xref pdf-from-source auto-create-frames)
                                   status (car prepared) task (cadr prepared))
                             (cond
                                 ((= status "OK")
                                  (setq ok (1+ ok) tasks (cons task tasks)))
                                 ((= status "SKIP") (setq skip (1+ skip)))
                                 (T (setq fail (1+ fail))))))))))
        (setq fail (1+ fail)))
    (list (reverse tasks) ok skip fail output-dir)
)

(defun vclip:parse-fast-manifest-line-v324 ( line )
    (vclip:split-string-v324 line "|")
)

(defun vclip:read-fast-manifest-v324 ( path / f line rec rows )
    (setq rows nil)
    (if (setq f (vclip:open-control-v325 path "r"))
        (progn
            (while (setq line (read-line f))
                (if (and (/= "" (vclip:trim-v34 line))
                         (setq rec (vclip:parse-fast-manifest-line-v324 line))
                         (= 10 (length rec)))
                    (setq rows (cons rec rows))))
            (close f)
            (reverse rows)))
)

(defun vclip:write-fast-manifest-v324
       ( path tasks / f ok task create-dwg create-pdf ignore-layers ignore-xref pdf-from-source auto-create-frames )
    (setq f (vclip:open-control-v325 path "w") ok T)
    (if f
        (progn
            (foreach task tasks
                (setq create-dwg
                          (if (> (length task) 7) (nth 7 task) "1")
                      create-pdf
                          (if (> (length task) 8) (nth 8 task) "1")
                      ignore-layers
                          (if (> (length task) 9)
                              (nth 9 task)
                              vclip:ignore-layers-text-v324)
                      ignore-xref
                          (if (> (length task) 10) (nth 10 task) "0")
                      pdf-from-source
                          (if (> (length task) 11) (nth 11 task) "1")
                      auto-create-frames
                          (if (> (length task) 12) (nth 12 task) "1"))
                (if (and
                        (vclip:manifest-field-valid-v314 (nth 0 task))
                        (vclip:manifest-field-valid-v314 (nth 2 task))
                        (vclip:manifest-field-valid-v314 (nth 5 task))
                        (vclip:manifest-field-valid-v314 (nth 3 task))
                        (member create-dwg '("0" "1"))
                        (member create-pdf '("0" "1"))
                        (vclip:manifest-field-valid-v314 ignore-layers)
                        (member ignore-xref '("0" "1"))
                        (member pdf-from-source '("0" "1"))
                        (member auto-create-frames '("0" "1")))
                    (write-line
                        (strcat (nth 0 task) "|" (nth 2 task) "|"
                                (nth 5 task) "|" (nth 3 task) "|"
                                create-dwg "|" create-pdf "|" ignore-layers "|"
                                ignore-xref "|" pdf-from-source "|" auto-create-frames)
                        f)
                    (setq ok nil)))
            (close f)
            (if ok path)))
)
(defun vclip:model-object-count-v325 ( / result )
    (setq result
        (vl-catch-all-apply
            '(lambda ( / count obj )
                 (setq count 0)
                 (vlax-for obj (vla-get-ModelSpace (LM:acdoc))
                     (setq count (1+ count)))
                 count)
            nil))
    (if (vl-catch-all-error-p result) -1 result)
)

(defun vclip:xref-definition-count-v325 ( / result )
    ;; Liczy tylko glowne (najwyzszego poziomu) definicje XREF. Definicje
    ;; zagniezdzonych XREF-ow maja nazwy w postaci "GLOWNY|ZAGNIEZDZONY" i
    ;; pojawiaja sie/znikaja z kolekcji Blocks przy kazdym Reload/Unload
    ;; nadrzednego odnosnika (np. w vclip:prepare-xrefs-for-pdf-v333 oraz
    ;; vclip:filter-xrefs-v34). Wliczanie ich do porownania przed/po UNDO
    ;; Back powodowalo falszywe niezgodnosci i blad zadania wylacznie w
    ;; rysunkach z zagniezdzonymi XREF-ami, mimo poprawnego przywrocenia
    ;; kopii zrodlowej.
    (setq result
        (vl-catch-all-apply
            '(lambda ( / count blk name )
                 (setq count 0)
                 (vlax-for blk (vla-get-Blocks (LM:acdoc))
                     (if (and (vclip:xref-block-p-v34 blk)
                              (setq name (vla-get-Name blk))
                              (not (vl-string-search "|" name)))
                         (setq count (1+ count))))
                 count)
            nil))
    (if (vl-catch-all-error-p result) -1 result)
)
(defun vclip:fast-export-task-v324
       ( rec index total progress
         / lay final pdf pattern create-dwg create-pdf ignore-layers ignore-xref
           pdf-from-source auto-create-frames needs-cleanup before-count before-model before-xrefs
           oldctab core frameprep markstarted keep matching xprep xres postok wblockok
           pdfok run success detail undo-ok after-count after-model after-xrefs )
    (vclip:reset-xref-name-cache-v325)
    (setq lay (nth 0 rec) final (nth 1 rec) pdf (nth 2 rec)
          pattern (nth 3 rec) create-dwg (= "1" (nth 4 rec))
          create-pdf (= "1" (nth 5 rec))
          ignore-layers (nth 6 rec)
          ignore-xref (and (> (length rec) 7) (= "1" (nth 7 rec)))
          pdf-from-source (or (< (length rec) 9) (= "1" (nth 8 rec)))
          auto-create-frames (or (< (length rec) 10) (= "1" (nth 9 rec)))
          needs-cleanup
              (or create-dwg (and create-pdf (not pdf-from-source)))
          before-count -1
          before-model -1
          before-xrefs -1
          oldctab (getvar 'CTAB)
          markstarted nil
          wblockok (not create-dwg)
          pdfok (not create-pdf)
          success nil
          detail "nieznany blad szybkiego eksportu"
          undo-ok T)
    (setq vclip:auto-frame-records-v339 nil)
    (vclip:set-ignore-layers-v324 ignore-layers)
    (vclip:fast-progress-v324 progress index "PRECHECK"
        (if needs-cleanup
            "Sprawdzanie layoutu i ramek"
            "Sprawdzanie layoutu"))
    (setq run
        (vl-catch-all-apply
            '(lambda ( / )
                 (cond
                     ((not (vclip:layout-exists-p lay))
                      (setq detail "layout nie istnieje"))
                     ((and needs-cleanup
                            (not (vclip:layout-ready-for-cleanup-v339
                                    lay auto-create-frames)))
                      (setq detail "nie mozna przygotowac ramek"))
                     (T
                      (if create-pdf
                          (progn
                              (vclip:fast-progress-v324 progress index "XREF"
                                  (if ignore-xref
                                      "Wczytywanie wszystkich odnosnikow dla PDF"
                                      (strcat "Wczytywanie odnosnikow dla klucza "
                                              pattern)))
                              (setq xprep
                                  (vclip:prepare-xrefs-for-pdf-v333
                                      pattern ignore-xref))
                              (if (not (car xprep))
                                  (setq detail
                                      (strcat
                                          "nie przygotowano XREF dla PDF; bledy="
                                          (itoa (nth 4 xprep)))))))
                      (if (or (not create-pdf) (and xprep (car xprep)))
                          (progn
                              (if (and create-pdf pdf-from-source)
                                  (progn
                                      (vclip:fast-progress-v324 progress index
                                          "PDF"
                                          "Drukowanie PDF z rysunku zrodlowego")
                                      (setq pdfok
                                          (vclip:plot-layout-to-pdf-v312 lay pdf))
                                      (if (not pdfok)
                                          (setq detail
                                              "nie utworzono prawidlowego PDF ze zrodla"))))
                              (if (or (not pdf-from-source) pdfok)
                                  (if needs-cleanup
                                      (progn
                                          (setq before-count
                                                    (vclip:paper-layout-count-v312)
                                                before-model
                                                    (vclip:model-object-count-v325)
                                                before-xrefs
                                                    (vclip:xref-definition-count-v325)
                                                markstarted
                                                    (vclip:undo-mark-v324))
                                          (if markstarted
                                              (progn
                                                  (vclip:fast-progress-v324
                                                      progress index "FRAME"
                                                      "Kontrola i tworzenie ramek z rzutni")
                                                  (setq frameprep
                                                      (vclip:ensure-layout-frames-v339
                                                          lay auto-create-frames))
                                                  (if (car frameprep)
                                                      (progn
                                                          (setq vclip:auto-frame-records-v339
                                                              (cadr frameprep))
                                                          (vclip:fast-progress-v324
                                                              progress index "MODEL"
                                                              (strcat "Czyszczenie modelu; "
                                                                  (caddr frameprep)))
                                                          (setq core
                                                              (vclip:clip-current-document-by-layout-v312
                                                                  lay nil nil pattern)))
                                                      (setq detail (caddr frameprep))))
                                              (setq detail
                                                  "nie udalo sie utworzyc UNDO Mark"))
                                          (if core
                                              (progn
                                                  (setq keep (cadr core)
                                                        matching (caddr core))
                                                  (vclip:fast-progress-v324
                                                      progress index "XREF"
                                                      (if ignore-xref
                                                          "Zachowanie wszystkich odnosnikow"
                                                          "Filtrowanie odnosnikow dla DWG"))
                                                  (setq xres
                                                      (vclip:filter-xrefs-v34 pattern))
                                                  (vclip:fast-progress-v324
                                                      progress index "PURGE"
                                                      "Porzadkowanie rysunku")
                                                  (vclip:purge-all-v33)
                                                  (vclip:fast-progress-v324
                                                      progress index "VERIFY"
                                                      "Kontrola przygotowanego rysunku")
                                                  (setq postok
                                                      (vclip:postcondition-v312
                                                          lay pattern keep matching))
                                                  (if postok
                                                      (progn
                                                          (if create-dwg
                                                              (progn
                                                                  (vclip:fast-progress-v324
                                                                      progress index "WBLOCK"
                                                                      "Zapisywanie oczyszczonego DWG")
                                                                  (setq wblockok
                                                                      (vclip:wblock-current-v324
                                                                          final))))
                                                          (if (and wblockok create-pdf
                                                                   (not pdf-from-source))
                                                              (progn
                                                                  (vclip:fast-progress-v324
                                                                      progress index "PDF"
                                                                      "Drukowanie PDF po podziale modelu")
                                                                  (setq pdfok
                                                                      (vclip:plot-layout-to-pdf-v312
                                                                          lay pdf))))
                                                          (setq success
                                                              (and wblockok pdfok))
                                                          (if success
                                                              (setq detail "OK")
                                                              (setq detail
                                                                  (if (not wblockok)
                                                                      "polecenie WBLOCK nie utworzylo DWG"
                                                                      "nie utworzono prawidlowego PDF po podziale"))))
                                                      (setq detail
                                                          "kontrola oczyszczonego rysunku nie powiodla sie")))
                                              (if markstarted
                                                  (setq detail
                                                      "czyszczenie rysunku nie powiodlo sie"))))
                                      (setq success pdfok
                                            detail (if pdfok "OK" detail))))))))
                 T)
            nil))
    (setq vclip:auto-frame-records-v339 nil)
    (if (vl-catch-all-error-p run)
        (setq success nil
              detail (strcat "wyjatek: "
                             (vl-catch-all-error-message run))))
    (if markstarted
        (progn
            (vclip:fast-progress-v324 progress index "UNDO"
                "Przywracanie kopii zrodlowej")
            (setq undo-ok (vclip:undo-back-v312))
            (if (and oldctab (vclip:layout-exists-p oldctab))
                (vl-catch-all-apply 'setvar (list 'CTAB oldctab)))
            (setq after-count (vclip:paper-layout-count-v312)
                  after-model (vclip:model-object-count-v325)
                  after-xrefs (vclip:xref-definition-count-v325))
            (if (or (not undo-ok)
                    (/= before-count after-count)
                    (and (>= before-model 0) (/= before-model after-model))
                    (and (>= before-xrefs 0) (/= before-xrefs after-xrefs)))
                (setq success nil
                      undo-ok nil
                      detail
                        (strcat "UNDO nie przywrocilo kopii zrodlowej"
                            " [layouty " (itoa before-count) "/" (itoa after-count)
                            ", ModelSpace " (itoa before-model) "/" (itoa after-model)
                            ", XREF " (itoa before-xrefs) "/" (itoa after-xrefs) "]")))))
    (vclip:fast-progress-v324 progress index
        (if success "TASK_OK" "TASK_FAIL")
        (if success
            (strcat "Gotowe: " lay " (" (itoa index) "/" (itoa total) ")")
            detail))
    (list success detail undo-ok)
)

(defun vclip:confirm-ignore-all-xrefs-v333 ( config / count answer )
    (if (and (vclip:config-value-v324 'CREATE_PDF config)
             (vclip:config-value-v324 'IGNORE_XREF config)
             (> (setq count (vclip:top-level-xref-count-v333)) 8))
        (progn
            (initget "Tak Nie")
            (setq answer
                (getkword
                    (strcat
                        "\nVPOCFG: wykryto " (itoa count)
                        " XREF-ow. Wczytac wszystkie? [Tak/Nie] <Nie>: ")))
            (if (= answer "Tak")
                T
                (progn
                    (princ "\nVPOCFG: eksport anulowany - nie potwierdzono wczytania wszystkich XREF-ow.")
                    nil)))
        T)
)
(defun c:VPOEXPORTCFG
       ( / srcpath cfg config overwrite-key overwrite built tasks ok skip fail
         script report run-key oldfiledia oldcmddia self output-dir )
    (vl-load-com)
    (setq srcpath (vclip:current-dwg-path-v31))
    (cond
        ((or (null srcpath) (not (findfile srcpath)) (= 0 (getvar 'DWGTITLED)))
         (princ "\nVPOCFG: najpierw zapisz rysunek zrodlowy jako DWG."))
        ((/= 0 (getvar 'DBMOD))
         (princ "\nVPOCFG: zapisz niezapisane zmiany przed eksportem."))
        ((/= 0 (vclip:getvar-safe-v35 'SDI 0))
         (princ "\nVPOCFG: wymagane jest SDI=0."))
        ((null (setq self (vclip:self-lisp-path-v312)))
         (princ "\nVPOCFG: nie odnaleziono VPOCLIP_v3.39_brics.lsp."))
        ((null (setq cfg (vclip:config-path-v312)))
         (princ "\nVPOCFG: nie odnaleziono VPOCLIP_CONF.txt."))
        ((null (setq config (vclip:read-config-v324 cfg)))
         (princ "\nVPOCFG: konfiguracja jest niepoprawna."))
        (T
         (princ (strcat "\nVPOCFG 3.39: konfiguracja: " cfg))
         (if (vclip:config-value-v324 'PROCESS_ALL_LAYOUTS config)
             (if (vclip:config-value-v324 'IGNORE_XREF config)
                 (princ
                     "\nVPOCFG: wszystkie layouty; [TASKS] ignorowane; wszystkie XREF-y beda wczytane.")
                 (princ
                     "\nVPOCFG: wszystkie layouty; [TASKS] ignorowane; klucz XREF powstaje z 2 pierwszych znakow layoutu.")))
         (if (vclip:confirm-ignore-all-xrefs-v333 config)
             (progn
                 (initget "Tak Nie")
                 (setq overwrite-key
                     (getkword
                         "\nVPOCFG: bezpiecznie zastapic istniejace wyniki? [Tak/Nie] <Nie>: ")
                       overwrite (= overwrite-key "Tak")
                       built (vclip:build-config-tasks-v324
                                 srcpath config overwrite)
                       tasks (nth 0 built)
                       ok (nth 1 built)
                       skip (nth 2 built)
                       fail (nth 3 built)
                       output-dir (nth 4 built))
                 (if tasks
                     (progn
                         (setq script
                                   (vclip:new-batch-path-v312 srcpath ".scr")
                               report
                                   (vclip:new-batch-path-v312 srcpath ".txt")
                               oldfiledia
                                   (vclip:getvar-safe-v35 'FILEDIA 1)
                               oldcmddia
                                   (vclip:getvar-safe-v35 'CMDDIA 1)
                               vclip:batch-report-v312 report)
                         (vclip:file-delete-confirmed-v312 report)
                         (if (vclip:write-acad-batch-script-v312
                                 script tasks overwrite report
                                 oldfiledia oldcmddia
                                 (vclip:config-value-v324
                                     'PROCESS_ALL_LAYOUTS config))
                             (progn
                                 (princ
                                     (strcat
                                         "\nVPOCFG: przygotowano=" (itoa ok)
                                         " / pominieto=" (itoa skip)
                                         " / bledy=" (itoa fail)))
                                 (princ
                                     (strcat
                                         "\nVPOCFG: katalog wynikowy: "
                                         output-dir))
                                 (initget "Tak Nie")
                                 (setq run-key
                                     (getkword
                                         "\nVPOCFG: uruchomic eksport teraz? [Tak/Nie] <Tak>: "))
                                 (if (/= run-key "Nie")
                                     (vclip:run-acad-script-v312
                                         script oldfiledia oldcmddia)
                                     (princ
                                         (strcat
                                             "\nVPOCFG: skrypt oczekuje na uruchomienie: "
                                             script))))
                             (princ
                                 "\nVPOCFG: nie udalo sie utworzyc skryptu SCR.")))
                     (princ
                         (strcat
                             "\nVPOCFG: brak zadan / pominieto="
                             (itoa skip)
                             " / bledy=" (itoa fail))))))))
    (princ)
)

;;------------------------------------------------------------------;;
;;  LCLIP v3.39 - prosty eksport bez VPOCLIP_CONF.txt               ;;
;;------------------------------------------------------------------;;

(defun vclip:lclip-select-layouts-v339 ( / key current name layouts )
    (initget "Current Select All")
    (setq key
        (getkword
            "\nLCLIP: scope [Current/Select/All] <Current>: "))
    (if (null key) (setq key "Current"))
    (cond
        ((= key "All")
         (setq layouts (layoutlist))
         (if layouts
             (list T layouts)
             (progn
                 (princ "\nLCLIP: rysunek nie zawiera layoutow papieru.")
                 nil)))
        ((= key "Select")
         (setq name (vclip:trim-v34
                        (getstring T "\nLCLIP: podaj nazwe layoutu: ")))
         (if (and (/= name "")
                  (/= "MODEL" (strcase name))
                  (vclip:layout-exists-p name))
             (list nil (list name))
             (progn
                 (princ (strcat "\nLCLIP: layout nie istnieje: " name))
                 nil)))
        (T
         (setq current (getvar 'CTAB))
         (if (and current (/= "MODEL" (strcase current)))
             (list nil (list current))
             (progn
                 (princ "\nLCLIP: aktywna jest zakladka Model. Wybierz layout papieru.")
                 nil))))
)

(defun vclip:lclip-format-v339 ( / key )
    (initget "DWG PDF Oba")
    (setq key
        (getkword "\nLCLIP: format wyniku [DWG/PDF/Oba] <Oba>: "))
    (cond
        ((= key "DWG") (list T nil))
        ((= key "PDF") (list nil T))
        (T (list T T)))
)

(defun vclip:lclip-output-name-v339 ( layout ext / s last )
    (setq s (vclip:trim-v34 layout)
          last (if (> (strlen s) 0) (substr s (strlen s) 1) ""))
    (if (and (/= s "")
             (not (member last '("." " ")))
             (not (vclip:string-has-any-v312
                      s (list "\\" "/" ":" "*" "?" "<" ">" "|" (chr 34))))
             (not (vl-string-search ".." s))
             (not (vclip:reserved-filename-p-v312 s)))
        (strcat s ext))
)

(defun vclip:lclip-export-dir-v339 ( / self )
    (if (setq self (vclip:self-lisp-path-v312))
        (vclip:ensure-directory-v324
            (strcat (vclip:dir-with-sep-v34 self) "VPOCLIP_export")))
)

(defun vclip:lclip-results-exist-p-v339
       ( layouts output-dir create-dwg create-pdf / hit lay name path )
    (setq hit nil)
    (foreach lay layouts
        (if (and (not hit) create-dwg
                 (setq name (vclip:lclip-output-name-v339 lay ".dwg"))
                 (setq path (vclip:path-in-dir-v324 output-dir name))
                 (findfile path))
            (setq hit T))
        (if (and (not hit) create-pdf
                 (setq name (vclip:lclip-output-name-v339 lay ".pdf"))
                 (setq path (vclip:path-in-dir-v324 output-dir name))
                 (findfile path))
            (setq hit T)))
    hit
)

(defun vclip:lclip-confirm-xrefs-v339 ( create-pdf / count answer )
    (if (and create-pdf
             (> (setq count (vclip:top-level-xref-count-v333)) 8))
        (progn
            (initget "Tak Nie")
            (setq answer
                (getkword
                    (strcat "\nLCLIP: wykryto " (itoa count)
                            " wstawionych XREF-ow. Wczytac wszystkie? [Tak/Nie] <Nie>: ")))
            (if (= answer "Tak")
                T
                (progn
                    (princ "\nLCLIP: eksport anulowany.")
                    nil)))
        T)
)

(defun vclip:lclip-build-tasks-v339
       ( src layouts output-dir overwrite create-dwg create-pdf
         / tasks ok skip fail lay dwgname pdfname finaldwg finalpdf
           exists-output needs-cleanup )
    (setq tasks nil
          ok 0
          skip 0
          fail 0
          needs-cleanup create-dwg)
    (foreach lay layouts
        (setq dwgname (vclip:lclip-output-name-v339 lay ".dwg")
              pdfname (vclip:lclip-output-name-v339 lay ".pdf"))
        (cond
            ((or (null dwgname) (null pdfname))
             (setq fail (1+ fail))
             (princ (strcat "\nLCLIP: nazwa layoutu nie moze byc nazwa pliku: " lay)))
            ((and needs-cleanup
                  (not (vclip:layout-ready-for-cleanup-v339 lay T)))
             (setq fail (1+ fail))
             (princ (strcat "\nLCLIP: nie mozna przygotowac ramek: " lay)))
            (T
             (setq finaldwg (vclip:path-in-dir-v324 output-dir dwgname)
                   finalpdf (vclip:path-in-dir-v324 output-dir pdfname)
                   exists-output
                       (or (and create-dwg (findfile finaldwg))
                           (and create-pdf (findfile finalpdf))))
             (cond
                 ((and create-dwg
                       (vclip:same-canonical-path-p-v312 src finaldwg))
                  (setq fail (1+ fail))
                  (princ (strcat "\nLCLIP: wynik wskazuje plik zrodlowy: " lay)))
                 ((and exists-output (not overwrite))
                  (setq skip (1+ skip))
                  (princ (strcat "\nLCLIP: pomijam istniejacy wynik: " lay)))
                 (T
                  (setq tasks
                      (cons
                          (list lay finaldwg finaldwg "*"
                                finalpdf finalpdf ""
                                (if create-dwg "1" "0")
                                (if create-pdf "1" "0")
                                vclip:always-keep-layer-v34
                                "1" "1" "1")
                          tasks)
                        ok (1+ ok)))))))
    (list (reverse tasks) ok skip fail)
)

(defun vclip:lclip-control-base-v339 ( / dir millis )
    (setq dir (getenv "TEMP"))
    (if (or (null dir) (= dir "")) (setq dir "C:\\TMP"))
    (setq millis (vclip:getvar-safe-v35 "MILLISECS" 0))
    (strcat (vclip:dir-with-sep-v34 dir)
            "VPOCLIP_LCLIP_" (vclip:timestamp) "_" (itoa millis))
)

(defun vclip:lclip-launch-v339
       ( src tasks overwrite mode
         / base report manifest worker progress done results
           lisp helper acad ok path )
    (setq base     (vclip:lclip-control-base-v339)
          report   (strcat base ".txt")
          manifest (strcat base ".manifest")
          worker   (strcat base "_worker.scr")
          progress (strcat base ".progress")
          done     (strcat base ".done")
          results  (strcat base ".results")
          lisp     (vclip:self-lisp-path-v312)
          helper   (vclip:worker-helper-path-v324)
          acad     (vclip:acad-exe-path-v314))
    (foreach path (list report manifest worker progress done results)
        (vclip:file-delete-confirmed-v312 path))
    (setq ok
        (and lisp helper acad tasks
             (vclip:write-fast-manifest-v324 manifest tasks)
             (vclip:write-fast-worker-script-v324
                 worker lisp manifest progress results done)
             (vclip:launch-controller-v324
                 helper acad src manifest report worker progress done results
                 (if overwrite 1 0) mode)))
    (if (not ok)
        (progn
            (foreach path (list manifest worker progress done results)
                (vclip:file-delete-confirmed-v312 path))
            (princ "\nLCLIP: nie udalo sie uruchomic kontrolera.")))
    ok
)

(defun c:LCLIP
       ( / src selection all-p layouts format create-dwg create-pdf
           output-dir overwrite-key overwrite built tasks ok skip fail mode )
    (vl-load-com)
    (setq src (vclip:current-dwg-path-v31))
    (cond
        ((or (null src) (not (findfile src)) (= 0 (getvar 'DWGTITLED)))
         (princ "\nLCLIP: najpierw zapisz rysunek zrodlowy jako DWG."))
        ((/= 0 (getvar 'DBMOD))
         (princ "\nLCLIP: zapisz niezapisane zmiany przed eksportem."))
        ((/= 0 (vclip:getvar-safe-v35 'SDI 0))
         (princ "\nLCLIP: wymagane jest SDI=0."))
        ((null (vclip:self-lisp-path-v312))
         (princ "\nLCLIP: nie odnaleziono VPOCLIP_v3.39_brics.lsp."))
        ((null (setq selection (vclip:lclip-select-layouts-v339))) nil)
        (T
         (setq all-p (car selection)
               layouts (cadr selection)
               format (vclip:lclip-format-v339)
               create-dwg (car format)
               create-pdf (cadr format))
         (if (vclip:lclip-confirm-xrefs-v339 create-pdf)
             (if (setq output-dir (vclip:lclip-export-dir-v339))
                 (progn
                     (setq overwrite nil)
                     (if (vclip:lclip-results-exist-p-v339
                             layouts output-dir create-dwg create-pdf)
                         (progn
                             (initget "Tak Nie")
                             (setq overwrite-key
                                 (getkword
                                     "\nLCLIP: bezpiecznie zastapic istniejace wyniki? [Tak/Nie] <Nie>: ")
                                   overwrite (= overwrite-key "Tak"))))
                     (setq built
                             (vclip:lclip-build-tasks-v339
                                 src layouts output-dir overwrite
                                 create-dwg create-pdf)
                           tasks (nth 0 built)
                           ok (nth 1 built)
                           skip (nth 2 built)
                           fail (nth 3 built))
                     (princ
                         (strcat "\nLCLIP: przygotowano=" (itoa ok)
                                 " / pominieto=" (itoa skip)
                                 " / bledy=" (itoa fail)))
                     (princ (strcat "\nLCLIP: katalog wynikowy: " output-dir))
                     (if tasks
                         (progn
                             (setq mode (if all-p T 'LCLIP))
                             (if (vclip:lclip-launch-v339
                                     src tasks overwrite mode)
                                 (princ "\nLCLIP: eksport uruchomiono; postep pokazuje panel.")))
                         (princ "\nLCLIP: brak zadan do wykonania.")))
                 (princ "\nLCLIP: nie mozna utworzyc folderu eksportu.")))))
    (princ)
)
(defun c:VPOBATCH () (c:VPOEXPORTCFG))
(defun c:VPOCFG () (c:VPOEXPORTCFG))
(vclip:disable-proxy-dialog-v324)
(princ
    "\nVPOCLIP/VPOEXPORT v3.39-brics załadowany. Komendy: VPOCLIP, LCLIP, VPOEXPORT, VPOEXPORTCFG, VPOBATCH, VPORESET.")
(princ)

;;==================================================================;;
;;                    End of File v3.39-brics                         ;;
;;==================================================================;;