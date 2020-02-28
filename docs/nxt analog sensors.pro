(UMLStudio "7.1" project)
(repository "" 0)
(notation "UML.not")
(genProfile 178 "C++" ("" "" "" "" "") "" 0 ("" "" "" "" "") ("" "" "" "" "") 
            700 360 362 578 70 50 80 50 80 60 0 0)
(codeFiles)
(docFiles)
(otherFiles)
(revFiles "C++")
(masters (master "j&!MicE(!'@]D)!" 1 3 "NXT_Analog_Sensor_DMA" "" "" "" "" "" 
                 5 
                 (("Controller" "DMA_Controller" "" "" "" "" 2 16 
                                "h&!kbcE(!'@]D)!")) 
                 (("Initialize" "" "" 3 16 nil nil "s&!^"icE(!'@]D)!" "") 
                  ("Get_Raw_Reading" "" "" 3 16 nil nil "l&!2icE(!'@]D)!" "")) 
                 nil nil nil 10 "") 
         (master "9(!8ncE(!'@]D)!" 1 3 "NXT_Sound_Sensor" "" "" "" "" "" 1 nil 
                 (("Initialize" "" "" 3 16 nil nil "U(!hlcE(!'@]D)!" "") 
                  ("Set_Mode" "" "" 3 16 nil nil "V(!SlcE(!'@]D)!" "") 
                  ("Current_Mode" "" "" 3 16 nil nil "W(!LlcE(!'@]D)!" "")) 
                 nil nil nil 10 "") 
         (master "4(!KncE(!'@]D)!" 1 3 "NXT_Light_Sensor" "" "" "" "" "" 1 nil 
                 (("Initialize" "" "" 3 16 nil nil "?(!KmcE(!'@]D)!" "") 
                  ("Enable_Floodlight" "" "" 3 16 nil nil "F(!0mcE(!'@]D)!" "") 
                  ("Disable_Floodlight" "" "" 3 16 nil nil "G(!)mcE(!'@]D)!" 
                                        "") 
                  ("Floodlight_Enabled" "Boolean" "" 3 16 nil nil 
                                        "H(!xlcE(!'@]D)!" "")) nil nil nil 10 
                 "") 
         (master "M'!7scE(!'@]D)!" 1 3 "NXT_Analog_Sensor_Polled" "" "" "" "" 
                 "" 5 nil 
                 (("Initialize" "" "" 3 16 nil nil "b'!hpcE(!'@]D)!" "") 
                  ("Get_Raw_Reading" "" "" 3 16 nil nil "['!}pcE(!'@]D)!" "")) 
                 nil nil nil 10 "") 
         (master "7&!}vcE(!'@]D)!" 1 3 "NXT_Analog_Sensor" "" "" "" "" "" 5 
                 (("Converter" "ADC" "" "" "" "" 2 16 "W&!*ccE(!'@]D)!")) 
                 (("Initialize" "" "" 3 16 nil nil "_&!sscE(!'@]D)!" "") 
                  ("Get_Intensity" "" "" 3 16 nil nil "=&!+ucE(!'@]D)!" "") 
                  ("Get_Raw_Reading" "" "" 3 144 nil nil "E&!YtcE(!'@]D)!" 
                                     "")) nil nil nil 10 ""))
(customModel "6&!DwcE(!'@]D)!" 0 3 "Untitled" "" "" 17 "" "" 1.000000 1.000000 
             (0 0 827 1168) (0 0 827 1168) 
             (place "7&!}vcE(!'@]D)!" (3) "" 10 "8&!}vcE(!'@]D)!" 
                    (232 98 472 262) (227 93 477 267) (235 101 469 259) 1 0 
                    (nil 1 -24 2 18 12 18 0) "") 
             (place "M'!7scE(!'@]D)!" (3) "" 10 "N'!7scE(!'@]D)!" 
                    (27 338 349 446) (22 333 354 451) (31 340 345 444) 1 0 
                    (nil 1 -24 0 18 12 18 0) "") 
             (link "N'!7scE(!'@]D)!" "8&!}vcE(!'@]D)!" (229 337 287 261) 3 "" 
                   "" "%%" "%%" "" "" "" 1 0 (249 292 267 306) 
                   (225 329 225 329) (291 269 291 269) 0 0 "S'!MrcE(!'@]D)!" 
                   (229 261 287 337) (220 252 296 346) (248 291 268 307) 2 0 
                   (nil 1 -12 32 18 12 18 18) "") 
             (place "j&!MicE(!'@]D)!" (3) "" 10 "'(!<ocE(!'@]D)!" 
                    (399 337 705 471) (394 332 710 476) (403 339 700 469) 1 0 
                    (nil 1 -24 0 18 12 18 0) "") 
             (link "'(!<ocE(!'@]D)!" "8&!}vcE(!'@]D)!" (491 336 424 261) 3 "" 
                   "" "%%" "%%" "" "" "" 1 0 (448 291 466 305) 
                   (495 328 495 328) (420 269 420 269) 0 0 "3(!incE(!'@]D)!" 
                   (424 261 491 336) (415 252 500 345) (447 290 467 306) 2 0 
                   (nil 1 -12 32 18 12 18 18) "") 
             (place "4(!KncE(!'@]D)!" (3) "" 10 "5(!KncE(!'@]D)!" 
                    (111 547 441 709) (106 542 446 714) (115 550 437 706) 1 0 
                    (nil 1 -24 0 18 12 18 0) "") 
             (place "9(!8ncE(!'@]D)!" (3) "" 10 ":(!8ncE(!'@]D)!" 
                    (523 545 757 679) (518 540 762 684) (526 547 754 677) 1 0 
                    (nil 1 -24 0 18 12 18 0) "") 
             (link "5(!KncE(!'@]D)!" "'(!<ocE(!'@]D)!" (374 546 468 470) 3 "" 
                   "" "%%" "%%" "" "" "" 1 0 (412 501 430 515) 
                   (382 550 382 550) (460 466 460 466) 0 0 "`(!AlcE(!'@]D)!" 
                   (374 470 468 546) (366 459 476 557) (411 500 431 516) 2 0 
                   (nil 1 -12 32 18 12 18 18) "") 
             (link ":(!8ncE(!'@]D)!" "'(!<ocE(!'@]D)!" (610 544 579 470) 3 "" 
                   "" "%%" "%%" "" "" "" 1 0 (585 500 603 514) 
                   (614 536 614 536) (575 478 575 478) 0 0 "a(!<lcE(!'@]D)!" 
                   (579 470 610 544) (567 463 622 551) (584 499 604 515) 2 0 
                   (nil 1 -12 32 18 12 18 18) ""))
