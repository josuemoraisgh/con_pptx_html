# Relatorio de Comparacao Visual

- Slides comparados: 16
- Mismatch global: 11.759%
- MAE global: 11.882

## Renders sem referencia
- artifacts/actual_slides\test_960.png
- artifacts/actual_slides\test_fittedbox.png
- artifacts/actual_slides\test_fullscreen.png
- artifacts/actual_slides\test_raw.png
- artifacts/actual_slides\test_reload.png

## Slides por severidade

| Slide | Mismatch % | MAE | Areas (top 3) |
|---|---:|---:|---|
| slide_016 | 38.870 | 25.809 | [x:312 y:50 w:289 h:243 p:70084] [x:24 y:110 w:245 h:38 p:1514] [x:33 y:85 w:187 h:9 p:842] |
| slide_006 | 16.199 | 18.419 | [x:138 y:20 w:80 h:18 p:978] [x:47 y:20 w:87 h:21 p:958] [x:321 y:83 w:57 h:42 p:619] |
| slide_010 | 14.910 | 15.255 | [x:12 y:56 w:297 h:227 p:6129] [x:247 y:20 w:98 h:18 p:1078] [x:132 y:20 w:112 h:18 p:1064] |
| slide_015 | 13.171 | 13.396 | [x:347 y:183 w:111 h:23 p:1041] [x:346 y:217 w:73 h:37 p:953] [x:47 y:20 w:91 h:22 p:951] |
| slide_013 | 11.967 | 13.030 | [x:76 y:68 w:145 h:48 p:1760] [x:399 y:241 w:59 h:25 p:704] [x:339 y:242 w:62 h:27 p:646] |
| slide_014 | 11.930 | 13.936 | [x:33 y:106 w:319 h:161 p:14257] [x:384 y:110 w:73 h:12 p:471] [x:194 y:20 w:53 h:18 p:468] |
| slide_009 | 9.694 | 7.831 | [x:56 y:20 w:203 h:21 p:2060] [x:10 y:96 w:580 h:136 p:1388] [x:103 y:180 w:476 h:29 p:1052] |
| slide_005 | 9.665 | 10.127 | [x:392 y:142 w:96 h:47 p:1837] [x:156 y:16 w:69 h:18 p:782] [x:277 y:16 w:75 h:18 p:752] |
| slide_012 | 9.536 | 10.519 | [x:27 y:65 w:89 h:64 p:2018] [x:410 y:194 w:99 h:42 p:1690] [x:56 y:194 w:113 h:43 p:1400] |
| slide_011 | 9.382 | 10.475 | [x:53 y:20 w:139 h:22 p:1609] [x:229 y:20 w:69 h:22 p:748] [x:32 y:135 w:48 h:26 p:627] |
| slide_002 | 8.829 | 8.423 | [x:126 y:243 w:117 h:30 p:1369] [x:273 y:248 w:139 h:23 p:1285] [x:27 y:243 w:97 h:30 p:1279] |
| slide_007 | 8.275 | 9.865 | [x:144 y:20 w:141 h:22 p:1588] [x:47 y:20 w:75 h:22 p:794] [x:310 y:144 w:62 h:31 p:667] |
| slide_004 | 8.152 | 9.567 | [x:58 y:20 w:86 h:22 p:904] [x:343 y:190 w:104 h:10 p:572] [x:190 y:20 w:46 h:18 p:539] |
| slide_003 | 7.384 | 9.206 | [x:429 y:100 w:89 h:24 p:1231] [x:163 y:20 w:94 h:18 p:1003] [x:47 y:20 w:85 h:18 p:859] |
| slide_008 | 6.503 | 8.007 | [x:206 y:255 w:161 h:80 p:1260] [x:195 y:20 w:111 h:22 p:1172] [x:238 y:279 w:98 h:21 p:1021] |
| slide_001 | 3.681 | 6.248 | [x:377 y:198 w:55 h:21 p:734] [x:169 y:199 w:45 h:20 p:443] [x:343 y:198 w:32 h:21 p:405] |

## Detalhes por slide

### slide_016
- Referencia: artifacts/reference_slides\Slide16.PNG
- Atual: artifacts/actual_slides\slide_016.png
- Mismatch: 38.870%
- MAE: 25.809
- Mask: artifacts/visual_diff_run6\masks\slide_016_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_016_overlay.png
- Areas de diferenca:
  - x:312 y:50 w:289 h:243 pixels:70084 cover:32.7344%
  - x:24 y:110 w:245 h:38 pixels:1514 cover:0.7071%
  - x:33 y:85 w:187 h:9 pixels:842 cover:0.3933%
  - x:26 y:183 w:78 h:19 pixels:625 cover:0.2919%
  - x:26 y:215 w:90 h:9 pixels:404 cover:0.1887%
  - x:24 y:237 w:52 h:19 pixels:385 cover:0.1798%
  - x:133 y:258 w:46 h:20 pixels:356 cover:0.1663%
  - x:210 y:237 w:75 h:9 pixels:337 cover:0.1574%
  - x:25 y:96 w:78 h:9 pixels:333 cover:0.1555%
  - x:25 y:161 w:67 h:9 pixels:297 cover:0.1387%

### slide_006
- Referencia: artifacts/reference_slides\Slide6.PNG
- Atual: artifacts/actual_slides\slide_006.png
- Mismatch: 16.199%
- MAE: 18.419
- Mask: artifacts/visual_diff_run6\masks\slide_006_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_006_overlay.png
- Areas de diferenca:
  - x:138 y:20 w:80 h:18 pixels:978 cover:0.4568%
  - x:47 y:20 w:87 h:21 pixels:958 cover:0.4475%
  - x:321 y:83 w:57 h:42 pixels:619 cover:0.2891%
  - x:460 y:219 w:75 h:20 pixels:616 cover:0.2877%
  - x:393 y:228 w:66 h:11 pixels:478 cover:0.2233%
  - x:432 y:82 w:31 h:43 pixels:474 cover:0.2214%
  - x:476 y:92 w:29 h:36 pixels:439 cover:0.2050%
  - x:393 y:82 w:49 h:36 pixels:402 cover:0.1878%
  - x:384 y:126 w:49 h:16 pixels:396 cover:0.1850%
  - x:457 y:272 w:57 h:22 pixels:366 cover:0.1709%

### slide_010
- Referencia: artifacts/reference_slides\Slide10.PNG
- Atual: artifacts/actual_slides\slide_010.png
- Mismatch: 14.910%
- MAE: 15.255
- Mask: artifacts/visual_diff_run6\masks\slide_010_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_010_overlay.png
- Areas de diferenca:
  - x:12 y:56 w:297 h:227 pixels:6129 cover:2.8627%
  - x:247 y:20 w:98 h:18 pixels:1078 cover:0.5035%
  - x:132 y:20 w:112 h:18 pixels:1064 cover:0.4970%
  - x:326 y:220 w:102 h:10 pixels:438 cover:0.2046%
  - x:193 y:304 w:69 h:10 pixels:404 cover:0.1887%
  - x:335 y:113 w:51 h:15 pixels:365 cover:0.1705%
  - x:456 y:220 w:73 h:10 pixels:323 cover:0.1509%
  - x:108 y:304 w:56 h:10 pixels:313 cover:0.1462%
  - x:329 y:193 w:33 h:16 pixels:265 cover:0.1238%
  - x:329 y:135 w:42 h:11 pixels:257 cover:0.1200%

### slide_015
- Referencia: artifacts/reference_slides\Slide15.PNG
- Atual: artifacts/actual_slides\slide_015.png
- Mismatch: 13.171%
- MAE: 13.396
- Mask: artifacts/visual_diff_run6\masks\slide_015_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_015_overlay.png
- Areas de diferenca:
  - x:347 y:183 w:111 h:23 pixels:1041 cover:0.4862%
  - x:346 y:217 w:73 h:37 pixels:953 cover:0.4451%
  - x:47 y:20 w:91 h:22 pixels:951 cover:0.4442%
  - x:227 y:20 w:79 h:21 pixels:912 cover:0.4260%
  - x:91 y:102 w:143 h:20 pixels:776 cover:0.3624%
  - x:46 y:124 w:89 h:16 pixels:775 cover:0.3620%
  - x:46 y:170 w:74 h:18 pixels:664 cover:0.3101%
  - x:154 y:20 w:53 h:18 pixels:595 cover:0.2779%
  - x:347 y:148 w:86 h:19 pixels:546 cover:0.2550%
  - x:30 y:147 w:88 h:11 pixels:487 cover:0.2275%

### slide_013
- Referencia: artifacts/reference_slides\Slide13.PNG
- Atual: artifacts/actual_slides\slide_013.png
- Mismatch: 11.967%
- MAE: 13.030
- Mask: artifacts/visual_diff_run6\masks\slide_013_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_013_overlay.png
- Areas de diferenca:
  - x:76 y:68 w:145 h:48 pixels:1760 cover:0.8220%
  - x:399 y:241 w:59 h:25 pixels:704 cover:0.3288%
  - x:339 y:242 w:62 h:27 pixels:646 cover:0.3017%
  - x:402 y:197 w:82 h:14 pixels:603 cover:0.2816%
  - x:241 y:20 w:48 h:22 pixels:590 cover:0.2756%
  - x:107 y:20 w:60 h:18 pixels:572 cover:0.2672%
  - x:408 y:152 w:78 h:11 pixels:484 cover:0.2261%
  - x:127 y:118 w:84 h:14 pixels:460 cover:0.2149%
  - x:338 y:213 w:55 h:18 pixels:429 cover:0.2004%
  - x:361 y:96 w:52 h:25 pixels:427 cover:0.1994%

### slide_014
- Referencia: artifacts/reference_slides\Slide14.PNG
- Atual: artifacts/actual_slides\slide_014.png
- Mismatch: 11.930%
- MAE: 13.936
- Mask: artifacts/visual_diff_run6\masks\slide_014_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_014_overlay.png
- Areas de diferenca:
  - x:33 y:106 w:319 h:161 pixels:14257 cover:6.6591%
  - x:384 y:110 w:73 h:12 pixels:471 cover:0.2200%
  - x:194 y:20 w:53 h:18 pixels:468 cover:0.2186%
  - x:152 y:20 w:41 h:18 pixels:400 cover:0.1868%
  - x:384 y:60 w:62 h:18 pixels:348 cover:0.1625%
  - x:115 y:20 w:32 h:18 pixels:328 cover:0.1532%
  - x:384 y:97 w:69 h:10 pixels:317 cover:0.1481%
  - x:461 y:61 w:45 h:15 pixels:301 cover:0.1406%
  - x:56 y:20 w:29 h:18 pixels:293 cover:0.1369%
  - x:86 y:20 w:24 h:18 pixels:242 cover:0.1130%

### slide_009
- Referencia: artifacts/reference_slides\Slide9.PNG
- Atual: artifacts/actual_slides\slide_009.png
- Mismatch: 9.694%
- MAE: 7.831
- Mask: artifacts/visual_diff_run6\masks\slide_009_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_009_overlay.png
- Areas de diferenca:
  - x:56 y:20 w:203 h:21 pixels:2060 cover:0.9622%
  - x:10 y:96 w:580 h:136 pixels:1388 cover:0.6483%
  - x:103 y:180 w:476 h:29 pixels:1052 cover:0.4914%
  - x:400 y:51 w:174 h:48 pixels:613 cover:0.2863%
  - x:115 y:65 w:64 h:22 pixels:577 cover:0.2695%
  - x:20 y:301 w:562 h:1 pixels:562 cover:0.2625%
  - x:285 y:66 w:83 h:20 pixels:533 cover:0.2490%
  - x:473 y:126 w:106 h:44 pixels:508 cover:0.2373%
  - x:215 y:126 w:149 h:44 pixels:485 cover:0.2265%
  - x:99 y:51 w:141 h:48 pixels:464 cover:0.2167%

### slide_005
- Referencia: artifacts/reference_slides\Slide5.PNG
- Atual: artifacts/actual_slides\slide_005.png
- Mismatch: 9.665%
- MAE: 10.127
- Mask: artifacts/visual_diff_run6\masks\slide_005_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_005_overlay.png
- Areas de diferenca:
  - x:392 y:142 w:96 h:47 pixels:1837 cover:0.8580%
  - x:156 y:16 w:69 h:18 pixels:782 cover:0.3653%
  - x:277 y:16 w:75 h:18 pixels:752 cover:0.3512%
  - x:399 y:206 w:77 h:41 pixels:727 cover:0.3396%
  - x:204 y:146 w:126 h:74 pixels:725 cover:0.3386%
  - x:113 y:164 w:122 h:109 pixels:639 cover:0.2985%
  - x:13 y:16 w:52 h:22 pixels:577 cover:0.2695%
  - x:227 y:16 w:49 h:18 pixels:527 cover:0.2461%
  - x:400 y:95 w:73 h:18 pixels:512 cover:0.2391%
  - x:498 y:214 w:76 h:15 pixels:486 cover:0.2270%

### slide_012
- Referencia: artifacts/reference_slides\Slide12.PNG
- Atual: artifacts/actual_slides\slide_012.png
- Mismatch: 9.536%
- MAE: 10.519
- Mask: artifacts/visual_diff_run6\masks\slide_012_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_012_overlay.png
- Areas de diferenca:
  - x:27 y:65 w:89 h:64 pixels:2018 cover:0.9426%
  - x:410 y:194 w:99 h:42 pixels:1690 cover:0.7894%
  - x:56 y:194 w:113 h:43 pixels:1400 cover:0.6539%
  - x:221 y:194 w:66 h:45 pixels:1106 cover:0.5166%
  - x:410 y:65 w:66 h:43 pixels:997 cover:0.4657%
  - x:27 y:194 w:40 h:43 pixels:650 cover:0.3036%
  - x:170 y:20 w:49 h:18 pixels:562 cover:0.2625%
  - x:70 y:20 w:54 h:22 pixels:530 cover:0.2475%
  - x:118 y:69 w:47 h:29 pixels:482 cover:0.2251%
  - x:249 y:66 w:34 h:46 pixels:479 cover:0.2237%

### slide_011
- Referencia: artifacts/reference_slides\Slide11.PNG
- Atual: artifacts/actual_slides\slide_011.png
- Mismatch: 9.382%
- MAE: 10.475
- Mask: artifacts/visual_diff_run6\masks\slide_011_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_011_overlay.png
- Areas de diferenca:
  - x:53 y:20 w:139 h:22 pixels:1609 cover:0.7515%
  - x:229 y:20 w:69 h:22 pixels:748 cover:0.3494%
  - x:32 y:135 w:48 h:26 pixels:627 cover:0.2929%
  - x:69 y:89 w:41 h:31 pixels:442 cover:0.2064%
  - x:195 y:24 w:31 h:14 pixels:348 cover:0.1625%
  - x:467 y:66 w:40 h:26 pixels:347 cover:0.1621%
  - x:354 y:66 w:38 h:26 pixels:336 cover:0.1569%
  - x:80 y:137 w:30 h:24 pixels:324 cover:0.1513%
  - x:42 y:167 w:56 h:11 pixels:321 cover:0.1499%
  - x:106 y:135 w:36 h:26 pixels:301 cover:0.1406%

### slide_002
- Referencia: artifacts/reference_slides\Slide2.PNG
- Atual: artifacts/actual_slides\slide_002.png
- Mismatch: 8.829%
- MAE: 8.423
- Mask: artifacts/visual_diff_run6\masks\slide_002_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_002_overlay.png
- Areas de diferenca:
  - x:126 y:243 w:117 h:30 pixels:1369 cover:0.6394%
  - x:273 y:248 w:139 h:23 pixels:1285 cover:0.6002%
  - x:27 y:243 w:97 h:30 pixels:1279 cover:0.5974%
  - x:228 y:77 w:126 h:128 pixels:951 cover:0.4442%
  - x:269 y:150 w:70 h:19 pixels:704 cover:0.3288%
  - x:391 y:151 w:66 h:19 pixels:563 cover:0.2630%
  - x:143 y:20 w:44 h:18 pixels:537 cover:0.2508%
  - x:188 y:20 w:37 h:22 pixels:451 cover:0.2107%
  - x:347 y:93 w:24 h:112 pixels:405 cover:0.1892%
  - x:43 y:129 w:45 h:22 pixels:405 cover:0.1892%

### slide_007
- Referencia: artifacts/reference_slides\Slide7.PNG
- Atual: artifacts/actual_slides\slide_007.png
- Mismatch: 8.275%
- MAE: 9.865
- Mask: artifacts/visual_diff_run6\masks\slide_007_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_007_overlay.png
- Areas de diferenca:
  - x:144 y:20 w:141 h:22 pixels:1588 cover:0.7417%
  - x:47 y:20 w:75 h:22 pixels:794 cover:0.3709%
  - x:310 y:144 w:62 h:31 pixels:667 cover:0.3115%
  - x:202 y:94 w:59 h:18 pixels:646 cover:0.3017%
  - x:68 y:94 w:60 h:18 pixels:641 cover:0.2994%
  - x:171 y:144 w:48 h:28 pixels:604 cover:0.2821%
  - x:310 y:82 w:46 h:30 pixels:586 cover:0.2737%
  - x:32 y:81 w:35 h:31 pixels:520 cover:0.2429%
  - x:264 y:284 w:106 h:8 pixels:459 cover:0.2144%
  - x:355 y:94 w:39 h:18 pixels:409 cover:0.1910%

### slide_004
- Referencia: artifacts/reference_slides\Slide4.PNG
- Atual: artifacts/actual_slides\slide_004.png
- Mismatch: 8.152%
- MAE: 9.567
- Mask: artifacts/visual_diff_run6\masks\slide_004_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_004_overlay.png
- Areas de diferenca:
  - x:58 y:20 w:86 h:22 pixels:904 cover:0.4222%
  - x:343 y:190 w:104 h:10 pixels:572 cover:0.2672%
  - x:190 y:20 w:46 h:18 pixels:539 cover:0.2518%
  - x:237 y:21 w:45 h:17 pixels:431 cover:0.2013%
  - x:155 y:137 w:52 h:19 pixels:362 cover:0.1691%
  - x:343 y:162 w:48 h:13 pixels:347 cover:0.1621%
  - x:491 y:71 w:54 h:15 pixels:320 cover:0.1495%
  - x:161 y:20 w:26 h:18 pixels:288 cover:0.1345%
  - x:377 y:310 w:67 h:9 pixels:284 cover:0.1326%
  - x:460 y:310 w:43 h:11 pixels:235 cover:0.1098%

### slide_003
- Referencia: artifacts/reference_slides\Slide3.PNG
- Atual: artifacts/actual_slides\slide_003.png
- Mismatch: 7.384%
- MAE: 9.206
- Mask: artifacts/visual_diff_run6\masks\slide_003_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_003_overlay.png
- Areas de diferenca:
  - x:429 y:100 w:89 h:24 pixels:1231 cover:0.5750%
  - x:163 y:20 w:94 h:18 pixels:1003 cover:0.4685%
  - x:47 y:20 w:85 h:18 pixels:859 cover:0.4012%
  - x:51 y:100 w:43 h:34 pixels:844 cover:0.3942%
  - x:240 y:166 w:34 h:32 pixels:468 cover:0.2186%
  - x:51 y:153 w:55 h:28 pixels:428 cover:0.1999%
  - x:134 y:20 w:28 h:18 pixels:291 cover:0.1359%
  - x:290 y:100 w:27 h:34 pixels:289 cover:0.1350%
  - x:241 y:100 w:15 h:34 pixels:286 cover:0.1336%
  - x:277 y:100 w:17 h:34 pixels:268 cover:0.1252%

### slide_008
- Referencia: artifacts/reference_slides\Slide8.PNG
- Atual: artifacts/actual_slides\slide_008.png
- Mismatch: 6.503%
- MAE: 8.007
- Mask: artifacts/visual_diff_run6\masks\slide_008_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_008_overlay.png
- Areas de diferenca:
  - x:206 y:255 w:161 h:80 pixels:1260 cover:0.5885%
  - x:195 y:20 w:111 h:22 pixels:1172 cover:0.5474%
  - x:238 y:279 w:98 h:21 pixels:1021 cover:0.4769%
  - x:62 y:24 w:87 h:18 pixels:856 cover:0.3998%
  - x:206 y:180 w:161 h:40 pixels:772 cover:0.3606%
  - x:250 y:55 w:96 h:20 pixels:691 cover:0.3227%
  - x:466 y:101 w:68 h:29 pixels:668 cover:0.3120%
  - x:285 y:152 w:49 h:21 pixels:519 cover:0.2424%
  - x:282 y:189 w:45 h:20 pixels:472 cover:0.2205%
  - x:307 y:23 w:48 h:15 pixels:433 cover:0.2022%

### slide_001
- Referencia: artifacts/reference_slides\Slide1.PNG
- Atual: artifacts/actual_slides\slide_001.png
- Mismatch: 3.681%
- MAE: 6.248
- Mask: artifacts/visual_diff_run6\masks\slide_001_mask.png
- Overlay: artifacts/visual_diff_run6\overlays\slide_001_overlay.png
- Areas de diferenca:
  - x:377 y:198 w:55 h:21 pixels:734 cover:0.3428%
  - x:169 y:199 w:45 h:20 pixels:443 cover:0.2069%
  - x:343 y:198 w:32 h:21 pixels:405 cover:0.1892%
  - x:299 y:198 w:40 h:21 pixels:372 cover:0.1738%
  - x:365 y:269 w:51 h:9 pixels:273 cover:0.1275%
  - x:295 y:269 w:25 h:20 pixels:242 cover:0.1130%
  - x:435 y:269 w:44 h:11 pixels:235 cover:0.1098%
  - x:327 y:269 w:28 h:20 pixels:231 cover:0.1079%
  - x:516 y:269 w:44 h:11 pixels:229 cover:0.1070%
  - x:208 y:231 w:32 h:14 pixels:213 cover:0.0995%

