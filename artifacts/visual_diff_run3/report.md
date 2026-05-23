# Relatorio de Comparacao Visual

- Slides comparados: 16
- Mismatch global: 16.598%
- MAE global: 17.424

## Renders sem referencia
- artifacts/actual_slides\test_960.png
- artifacts/actual_slides\test_fittedbox.png
- artifacts/actual_slides\test_fullscreen.png
- artifacts/actual_slides\test_raw.png
- artifacts/actual_slides\test_reload.png

## Slides por severidade

| Slide | Mismatch % | MAE | Areas (top 3) |
|---|---:|---:|---|
| slide_016 | 42.752 | 25.580 | [x:312 y:50 w:289 h:243 p:70092] [x:21 y:248 w:269 h:35 p:9090] [x:25 y:183 w:93 h:30 p:1349] |
| slide_006 | 24.743 | 27.915 | [x:228 y:132 w:364 h:42 p:5393] [x:309 y:293 w:283 h:36 p:4823] [x:20 y:306 w:260 h:16 p:3376] |
| slide_010 | 21.579 | 25.081 | [x:12 y:56 w:297 h:227 p:14565] [x:188 y:18 w:157 h:21 p:1841] [x:329 y:80 w:57 h:41 p:980] |
| slide_015 | 20.725 | 21.749 | [x:22 y:251 w:267 h:38 p:6623] [x:323 y:259 w:267 h:44 p:5983] [x:346 y:211 w:149 h:30 p:1947] |
| slide_013 | 18.391 | 20.426 | [x:327 y:283 w:255 h:42 p:6432] [x:88 y:88 w:92 h:36 p:983] [x:48 y:17 w:77 h:22 p:962] |
| slide_005 | 17.191 | 19.066 | [x:391 y:281 w:204 h:44 p:6531] [x:13 y:10 w:360 h:48 p:5072] [x:101 y:146 w:281 h:100 p:4002] |
| slide_009 | 15.680 | 13.970 | [x:99 y:51 w:140 h:48 p:2311] [x:10 y:96 w:580 h:136 p:2137] [x:108 y:184 w:468 h:25 p:1694] |
| slide_002 | 14.252 | 13.974 | [x:14 y:76 w:357 h:131 p:4113] [x:15 y:64 w:586 h:15 p:1860] [x:246 y:254 w:167 h:19 p:1178] |
| slide_014 | 13.616 | 16.333 | [x:33 y:106 w:319 h:161 p:14257] [x:92 y:18 w:59 h:21 p:710] [x:442 y:93 w:57 h:24 p:580] |
| slide_011 | 13.208 | 15.088 | [x:34 y:317 w:555 h:28 p:3004] [x:55 y:16 w:137 h:29 p:1729] [x:193 y:16 w:94 h:28 p:1138] |
| slide_012 | 12.364 | 14.443 | [x:28 y:85 w:88 h:25 p:955] [x:410 y:83 w:66 h:32 p:843] [x:92 y:16 w:62 h:28 p:802] |
| slide_007 | 12.044 | 14.542 | [x:170 y:238 w:114 h:19 p:2064] [x:48 y:16 w:122 h:29 p:1648] [x:172 y:17 w:115 h:28 p:1490] |
| slide_004 | 11.704 | 14.156 | [x:48 y:16 w:113 h:28 p:1465] [x:265 y:306 w:85 h:30 p:934] [x:96 y:307 w:103 h:14 p:616] |
| slide_003 | 10.656 | 12.891 | [x:47 y:56 w:523 h:30 p:2137] [x:47 y:17 w:115 h:22 p:1375] [x:430 y:114 w:110 h:14 p:1038] |
| slide_008 | 10.575 | 13.539 | [x:206 y:260 w:217 h:80 p:3446] [x:206 y:180 w:161 h:40 p:2350] [x:205 y:52 w:159 h:43 p:1928] |
| slide_001 | 6.094 | 10.033 | [x:231 y:189 w:82 h:29 p:1237] [x:398 y:190 w:68 h:28 p:1105] [x:263 y:231 w:115 h:21 p:937] |

## Detalhes por slide

### slide_016
- Referencia: artifacts/reference_slides\Slide16.PNG
- Atual: artifacts/actual_slides\slide_016.png
- Mismatch: 42.752%
- MAE: 25.580
- Mask: artifacts/visual_diff_run3\masks\slide_016_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_016_overlay.png
- Areas de diferenca:
  - x:312 y:50 w:289 h:243 pixels:70092 cover:32.7381%
  - x:21 y:248 w:269 h:35 pixels:9090 cover:4.2457%
  - x:25 y:183 w:93 h:30 pixels:1349 cover:0.6301%
  - x:28 y:129 w:64 h:19 pixels:663 cover:0.3097%
  - x:39 y:96 w:172 h:9 pixels:659 cover:0.3078%
  - x:118 y:237 w:167 h:9 pixels:649 cover:0.3031%
  - x:33 y:62 w:236 h:11 pixels:583 cover:0.2723%
  - x:26 y:161 w:67 h:14 pixels:478 cover:0.2233%
  - x:33 y:110 w:236 h:2 pixels:472 cover:0.2205%
  - x:26 y:236 w:91 h:10 pixels:375 cover:0.1752%

### slide_006
- Referencia: artifacts/reference_slides\Slide6.PNG
- Atual: artifacts/actual_slides\slide_006.png
- Mismatch: 24.743%
- MAE: 27.915
- Mask: artifacts/visual_diff_run3\masks\slide_006_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_006_overlay.png
- Areas de diferenca:
  - x:228 y:132 w:364 h:42 pixels:5393 cover:2.5189%
  - x:309 y:293 w:283 h:36 pixels:4823 cover:2.2527%
  - x:20 y:306 w:260 h:16 pixels:3376 cover:1.5768%
  - x:20 y:147 w:179 h:33 pixels:3316 cover:1.5488%
  - x:396 y:81 w:103 h:48 pixels:1343 cover:0.6273%
  - x:341 y:228 w:117 h:23 pixels:1235 cover:0.5768%
  - x:167 y:18 w:80 h:21 pixels:929 cover:0.4339%
  - x:104 y:18 w:62 h:26 pixels:774 cover:0.3615%
  - x:48 y:18 w:57 h:21 pixels:629 cover:0.2938%
  - x:136 y:264 w:80 h:14 pixels:600 cover:0.2802%

### slide_010
- Referencia: artifacts/reference_slides\Slide10.PNG
- Atual: artifacts/actual_slides\slide_010.png
- Mismatch: 21.579%
- MAE: 25.081
- Mask: artifacts/visual_diff_run3\masks\slide_010_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_010_overlay.png
- Areas de diferenca:
  - x:12 y:56 w:297 h:227 pixels:14565 cover:6.8029%
  - x:188 y:18 w:157 h:21 pixels:1841 cover:0.8599%
  - x:329 y:80 w:57 h:41 pixels:980 cover:0.4577%
  - x:47 y:18 w:59 h:21 pixels:718 cover:0.3354%
  - x:108 y:303 w:99 h:13 pixels:688 cover:0.3213%
  - x:329 y:200 w:115 h:10 pixels:640 cover:0.2989%
  - x:12 y:297 w:582 h:25 pixels:629 cover:0.2938%
  - x:107 y:18 w:47 h:21 pixels:610 cover:0.2849%
  - x:344 y:246 w:72 h:24 pixels:588 cover:0.2746%
  - x:331 y:125 w:46 h:26 pixels:466 cover:0.2177%

### slide_015
- Referencia: artifacts/reference_slides\Slide15.PNG
- Atual: artifacts/actual_slides\slide_015.png
- Mismatch: 20.725%
- MAE: 21.749
- Mask: artifacts/visual_diff_run3\masks\slide_015_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_015_overlay.png
- Areas de diferenca:
  - x:22 y:251 w:267 h:38 pixels:6623 cover:3.0934%
  - x:323 y:259 w:267 h:44 pixels:5983 cover:2.7945%
  - x:346 y:211 w:149 h:30 pixels:1947 cover:0.9094%
  - x:46 y:105 w:144 h:17 pixels:1300 cover:0.6072%
  - x:141 y:18 w:85 h:26 pixels:1069 cover:0.4993%
  - x:102 y:219 w:121 h:17 pixels:1042 cover:0.4867%
  - x:72 y:89 w:104 h:12 pixels:665 cover:0.3106%
  - x:47 y:18 w:43 h:26 pixels:590 cover:0.2756%
  - x:99 y:170 w:72 h:17 pixels:588 cover:0.2746%
  - x:46 y:170 w:52 h:18 pixels:580 cover:0.2709%

### slide_013
- Referencia: artifacts/reference_slides\Slide13.PNG
- Atual: artifacts/actual_slides\slide_013.png
- Mismatch: 18.391%
- MAE: 20.426
- Mask: artifacts/visual_diff_run3\masks\slide_013_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_013_overlay.png
- Areas de diferenca:
  - x:327 y:283 w:255 h:42 pixels:6432 cover:3.0042%
  - x:88 y:88 w:92 h:36 pixels:983 cover:0.4591%
  - x:48 y:17 w:77 h:22 pixels:962 cover:0.4493%
  - x:422 y:266 w:112 h:12 pixels:722 cover:0.3372%
  - x:339 y:145 w:53 h:37 pixels:645 cover:0.3013%
  - x:331 y:265 w:90 h:16 pixels:615 cover:0.2873%
  - x:144 y:234 w:41 h:52 pixels:615 cover:0.2873%
  - x:122 y:191 w:85 h:14 pixels:568 cover:0.2653%
  - x:169 y:16 w:38 h:23 pixels:514 cover:0.2401%
  - x:126 y:16 w:42 h:23 pixels:505 cover:0.2359%

### slide_005
- Referencia: artifacts/reference_slides\Slide5.PNG
- Atual: artifacts/actual_slides\slide_005.png
- Mismatch: 17.191%
- MAE: 19.066
- Mask: artifacts/visual_diff_run3\masks\slide_005_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_005_overlay.png
- Areas de diferenca:
  - x:391 y:281 w:204 h:44 pixels:6531 cover:3.0505%
  - x:13 y:10 w:360 h:48 pixels:5072 cover:2.3690%
  - x:101 y:146 w:281 h:100 pixels:4002 cover:1.8692%
  - x:160 y:62 w:89 h:76 pixels:1574 cover:0.7352%
  - x:397 y:126 w:58 h:57 pixels:903 cover:0.4218%
  - x:411 y:219 w:49 h:39 pixels:671 cover:0.3134%
  - x:228 y:12 w:49 h:22 pixels:650 cover:0.3036%
  - x:454 y:142 w:49 h:44 pixels:612 cover:0.2858%
  - x:460 y:219 w:40 h:25 pixels:510 cover:0.2382%
  - x:393 y:24 w:41 h:35 pixels:477 cover:0.2228%

### slide_009
- Referencia: artifacts/reference_slides\Slide9.PNG
- Atual: artifacts/actual_slides\slide_009.png
- Mismatch: 15.680%
- MAE: 13.970
- Mask: artifacts/visual_diff_run3\masks\slide_009_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_009_overlay.png
- Areas de diferenca:
  - x:99 y:51 w:140 h:48 pixels:2311 cover:1.0794%
  - x:10 y:96 w:580 h:136 pixels:2137 cover:0.9981%
  - x:108 y:184 w:468 h:25 pixels:1694 cover:0.7912%
  - x:426 y:60 w:132 h:29 pixels:1510 cover:0.7053%
  - x:293 y:263 w:119 h:30 pixels:1478 cover:0.6903%
  - x:10 y:46 w:85 h:59 pixels:1290 cover:0.6025%
  - x:46 y:18 w:105 h:26 pixels:1272 cover:0.5941%
  - x:180 y:17 w:102 h:22 pixels:1225 cover:0.5722%
  - x:10 y:242 w:83 h:59 pixels:1209 cover:0.5647%
  - x:20 y:300 w:562 h:2 pixels:1124 cover:0.5250%

### slide_002
- Referencia: artifacts/reference_slides\Slide2.PNG
- Atual: artifacts/actual_slides\slide_002.png
- Mismatch: 14.252%
- MAE: 13.974
- Mask: artifacts/visual_diff_run3\masks\slide_002_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_002_overlay.png
- Areas de diferenca:
  - x:14 y:76 w:357 h:131 pixels:4113 cover:1.9211%
  - x:15 y:64 w:586 h:15 pixels:1860 cover:0.8688%
  - x:246 y:254 w:167 h:19 pixels:1178 cover:0.5502%
  - x:392 y:129 w:58 h:41 pixels:1138 cover:0.5315%
  - x:33 y:129 w:64 h:41 pixels:1006 cover:0.4699%
  - x:262 y:209 w:84 h:19 pixels:985 cover:0.4601%
  - x:508 y:120 w:71 h:29 pixels:739 cover:0.3452%
  - x:151 y:120 w:67 h:30 pixels:736 cover:0.3438%
  - x:116 y:16 w:61 h:23 pixels:685 cover:0.3199%
  - x:47 y:16 w:47 h:23 pixels:609 cover:0.2844%

### slide_014
- Referencia: artifacts/reference_slides\Slide14.PNG
- Atual: artifacts/actual_slides\slide_014.png
- Mismatch: 13.616%
- MAE: 16.333
- Mask: artifacts/visual_diff_run3\masks\slide_014_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_014_overlay.png
- Areas de diferenca:
  - x:33 y:106 w:319 h:161 pixels:14257 cover:6.6591%
  - x:92 y:18 w:59 h:21 pixels:710 cover:0.3316%
  - x:442 y:93 w:57 h:24 pixels:580 cover:0.2709%
  - x:46 y:18 w:45 h:21 pixels:545 cover:0.2546%
  - x:216 y:18 w:41 h:21 pixels:504 cover:0.2354%
  - x:387 y:132 w:51 h:16 pixels:438 cover:0.2046%
  - x:384 y:77 w:75 h:10 pixels:431 cover:0.2013%
  - x:183 y:18 w:32 h:21 pixels:407 cover:0.1901%
  - x:384 y:110 w:57 h:8 pixels:342 cover:0.1597%
  - x:152 y:23 w:30 h:16 pixels:299 cover:0.1397%

### slide_011
- Referencia: artifacts/reference_slides\Slide11.PNG
- Atual: artifacts/actual_slides\slide_011.png
- Mismatch: 13.208%
- MAE: 15.088
- Mask: artifacts/visual_diff_run3\masks\slide_011_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_011_overlay.png
- Areas de diferenca:
  - x:34 y:317 w:555 h:28 pixels:3004 cover:1.4031%
  - x:55 y:16 w:137 h:29 pixels:1729 cover:0.8076%
  - x:193 y:16 w:94 h:28 pixels:1138 cover:0.5315%
  - x:288 y:16 w:55 h:29 pixels:723 cover:0.3377%
  - x:32 y:142 w:59 h:33 pixels:670 cover:0.3129%
  - x:80 y:86 w:43 h:36 pixels:463 cover:0.2163%
  - x:79 y:196 w:52 h:24 pixels:386 cover:0.1803%
  - x:73 y:139 w:56 h:15 pixels:372 cover:0.1738%
  - x:36 y:100 w:41 h:20 pixels:363 cover:0.1695%
  - x:443 y:176 w:48 h:13 pixels:312 cover:0.1457%

### slide_012
- Referencia: artifacts/reference_slides\Slide12.PNG
- Atual: artifacts/actual_slides\slide_012.png
- Mismatch: 12.364%
- MAE: 14.443
- Mask: artifacts/visual_diff_run3\masks\slide_012_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_012_overlay.png
- Areas de diferenca:
  - x:28 y:85 w:88 h:25 pixels:955 cover:0.4461%
  - x:410 y:83 w:66 h:32 pixels:843 cover:0.3937%
  - x:92 y:16 w:62 h:28 pixels:802 cover:0.3746%
  - x:221 y:226 w:56 h:25 pixels:618 cover:0.2887%
  - x:48 y:17 w:43 h:25 pixels:564 cover:0.2634%
  - x:509 y:83 w:50 h:25 pixels:425 cover:0.1985%
  - x:176 y:17 w:34 h:22 pixels:411 cover:0.1920%
  - x:496 y:212 w:53 h:13 pixels:401 cover:0.1873%
  - x:410 y:212 w:52 h:13 pixels:396 cover:0.1850%
  - x:211 y:186 w:4 h:123 pixels:370 cover:0.1728%

### slide_007
- Referencia: artifacts/reference_slides\Slide7.PNG
- Atual: artifacts/actual_slides\slide_007.png
- Mismatch: 12.044%
- MAE: 14.542
- Mask: artifacts/visual_diff_run3\masks\slide_007_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_007_overlay.png
- Areas de diferenca:
  - x:170 y:238 w:114 h:19 pixels:2064 cover:0.9640%
  - x:48 y:16 w:122 h:29 pixels:1648 cover:0.7697%
  - x:172 y:17 w:115 h:28 pixels:1490 cover:0.6959%
  - x:449 y:103 w:103 h:18 pixels:1082 cover:0.5054%
  - x:171 y:103 w:90 h:18 pixels:716 cover:0.3344%
  - x:171 y:126 w:72 h:15 pixels:685 cover:0.3199%
  - x:142 y:282 w:119 h:13 pixels:630 cover:0.2943%
  - x:310 y:103 w:50 h:18 pixels:563 cover:0.2630%
  - x:310 y:165 w:44 h:22 pixels:503 cover:0.2349%
  - x:64 y:127 w:48 h:14 pixels:439 cover:0.2050%

### slide_004
- Referencia: artifacts/reference_slides\Slide4.PNG
- Atual: artifacts/actual_slides\slide_004.png
- Mismatch: 11.704%
- MAE: 14.156
- Mask: artifacts/visual_diff_run3\masks\slide_004_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_004_overlay.png
- Areas de diferenca:
  - x:48 y:16 w:113 h:28 pixels:1465 cover:0.6843%
  - x:265 y:306 w:85 h:30 pixels:934 cover:0.4362%
  - x:96 y:307 w:103 h:14 pixels:616 cover:0.2877%
  - x:254 y:16 w:40 h:23 pixels:511 cover:0.2387%
  - x:194 y:16 w:42 h:23 pixels:506 cover:0.2363%
  - x:343 y:191 w:52 h:13 pixels:447 cover:0.2088%
  - x:421 y:217 w:64 h:10 pixels:397 cover:0.1854%
  - x:162 y:16 w:30 h:23 pixels:395 cover:0.1845%
  - x:343 y:134 w:48 h:13 pixels:364 cover:0.1700%
  - x:343 y:152 w:26 h:30 pixels:355 cover:0.1658%

### slide_003
- Referencia: artifacts/reference_slides\Slide3.PNG
- Atual: artifacts/actual_slides\slide_003.png
- Mismatch: 10.656%
- MAE: 12.891
- Mask: artifacts/visual_diff_run3\masks\slide_003_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_003_overlay.png
- Areas de diferenca:
  - x:47 y:56 w:523 h:30 pixels:2137 cover:0.9981%
  - x:47 y:17 w:115 h:22 pixels:1375 cover:0.6422%
  - x:430 y:114 w:110 h:14 pixels:1038 cover:0.4848%
  - x:68 y:117 w:63 h:24 pixels:870 cover:0.4064%
  - x:283 y:117 w:52 h:24 pixels:663 cover:0.3097%
  - x:160 y:56 w:103 h:12 pixels:614 cover:0.2868%
  - x:52 y:170 w:73 h:13 pixels:561 cover:0.2620%
  - x:241 y:185 w:41 h:27 pixels:512 cover:0.2391%
  - x:219 y:16 w:39 h:23 pixels:502 cover:0.2345%
  - x:164 y:16 w:36 h:23 pixels:436 cover:0.2036%

### slide_008
- Referencia: artifacts/reference_slides\Slide8.PNG
- Atual: artifacts/actual_slides\slide_008.png
- Mismatch: 10.575%
- MAE: 13.539
- Mask: artifacts/visual_diff_run3\masks\slide_008_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_008_overlay.png
- Areas de diferenca:
  - x:206 y:260 w:217 h:80 pixels:3446 cover:1.6095%
  - x:206 y:180 w:161 h:40 pixels:2350 cover:1.0976%
  - x:205 y:52 w:159 h:43 pixels:1928 cover:0.9005%
  - x:371 y:94 w:188 h:46 pixels:1733 cover:0.8094%
  - x:206 y:112 w:185 h:63 pixels:1233 cover:0.5759%
  - x:211 y:164 w:150 h:18 pixels:1188 cover:0.5549%
  - x:430 y:241 w:88 h:23 pixels:1006 cover:0.4699%
  - x:202 y:18 w:73 h:26 pixels:866 cover:0.4045%
  - x:62 y:18 w:60 h:26 pixels:718 cover:0.3354%
  - x:276 y:18 w:60 h:21 pixels:700 cover:0.3270%

### slide_001
- Referencia: artifacts/reference_slides\Slide1.PNG
- Atual: artifacts/actual_slides\slide_001.png
- Mismatch: 6.094%
- MAE: 10.033
- Mask: artifacts/visual_diff_run3\masks\slide_001_mask.png
- Overlay: artifacts/visual_diff_run3\overlays\slide_001_overlay.png
- Areas de diferenca:
  - x:231 y:189 w:82 h:29 pixels:1237 cover:0.5778%
  - x:398 y:190 w:68 h:28 pixels:1105 cover:0.5161%
  - x:263 y:231 w:115 h:21 pixels:937 cover:0.4376%
  - x:185 y:189 w:45 h:29 pixels:724 cover:0.3382%
  - x:348 y:189 w:48 h:29 pixels:690 cover:0.3223%
  - x:435 y:270 w:87 h:11 pixels:558 cover:0.2606%
  - x:315 y:196 w:31 h:22 pixels:420 cover:0.1962%
  - x:295 y:270 w:70 h:13 pixels:390 cover:0.1822%
  - x:148 y:270 w:65 h:10 pixels:348 cover:0.1625%
  - x:298 y:282 w:47 h:15 pixels:327 cover:0.1527%

