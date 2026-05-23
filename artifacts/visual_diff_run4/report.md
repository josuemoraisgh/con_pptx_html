# Relatorio de Comparacao Visual

- Slides comparados: 16
- Mismatch global: 11.719%
- MAE global: 11.821

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
| slide_006 | 15.764 | 17.868 | [x:138 y:20 w:80 h:18 p:978] [x:47 y:20 w:87 h:21 p:958] [x:391 y:58 w:80 h:43 p:925] |
| slide_010 | 15.010 | 15.300 | [x:12 y:56 w:297 h:227 p:6129] [x:326 y:66 w:122 h:45 p:1460] [x:247 y:20 w:98 h:18 p:1078] |
| slide_015 | 12.786 | 12.958 | [x:46 y:59 w:106 h:25 p:1274] [x:46 y:83 w:141 h:38 p:1239] [x:343 y:130 w:110 h:30 p:1202] |
| slide_013 | 12.113 | 13.232 | [x:76 y:68 w:145 h:48 p:1760] [x:40 y:159 w:152 h:38 p:1453] [x:131 y:131 w:111 h:40 p:815] |
| slide_014 | 11.887 | 13.863 | [x:33 y:106 w:319 h:161 p:14257] [x:381 y:98 w:52 h:26 p:617] [x:398 y:67 w:88 h:12 p:478] |
| slide_005 | 9.770 | 10.221 | [x:391 y:138 w:64 h:48 p:990] [x:156 y:16 w:69 h:18 p:782] [x:277 y:16 w:75 h:18 p:752] |
| slide_009 | 9.694 | 7.831 | [x:56 y:20 w:203 h:21 p:2060] [x:10 y:96 w:580 h:136 p:1388] [x:103 y:180 w:476 h:29 p:1052] |
| slide_012 | 9.536 | 10.519 | [x:27 y:65 w:89 h:64 p:2018] [x:410 y:194 w:99 h:42 p:1690] [x:56 y:194 w:113 h:43 p:1400] |
| slide_011 | 9.306 | 10.376 | [x:53 y:20 w:139 h:22 p:1609] [x:325 y:65 w:67 h:44 p:953] [x:32 y:135 w:66 h:32 p:808] |
| slide_002 | 8.829 | 8.423 | [x:126 y:243 w:117 h:30 p:1369] [x:273 y:248 w:139 h:23 p:1285] [x:27 y:243 w:97 h:30 p:1279] |
| slide_007 | 8.289 | 9.802 | [x:144 y:20 w:141 h:22 p:1588] [x:171 y:75 w:90 h:41 p:1374] [x:310 y:82 w:96 h:36 p:1235] |
| slide_004 | 8.142 | 9.569 | [x:58 y:20 w:86 h:22 p:904] [x:155 y:97 w:75 h:25 p:833] [x:366 y:99 w:102 h:23 p:825] |
| slide_003 | 7.320 | 9.110 | [x:429 y:100 w:95 h:33 p:1550] [x:51 y:100 w:45 h:53 p:1043] [x:163 y:20 w:94 h:18 p:1003] |
| slide_008 | 6.503 | 8.007 | [x:206 y:255 w:161 h:80 p:1260] [x:195 y:20 w:111 h:22 p:1172] [x:238 y:279 w:98 h:21 p:1021] |
| slide_001 | 3.681 | 6.248 | [x:377 y:198 w:55 h:21 p:734] [x:169 y:199 w:45 h:20 p:443] [x:343 y:198 w:32 h:21 p:405] |

## Detalhes por slide

### slide_016
- Referencia: artifacts/reference_slides\Slide16.PNG
- Atual: artifacts/actual_slides\slide_016.png
- Mismatch: 38.870%
- MAE: 25.809
- Mask: artifacts/visual_diff_run4\masks\slide_016_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_016_overlay.png
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
- Mismatch: 15.764%
- MAE: 17.868
- Mask: artifacts/visual_diff_run4\masks\slide_006_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_006_overlay.png
- Areas de diferenca:
  - x:138 y:20 w:80 h:18 pixels:978 cover:0.4568%
  - x:47 y:20 w:87 h:21 pixels:958 cover:0.4475%
  - x:391 y:58 w:80 h:43 pixels:925 cover:0.4320%
  - x:60 y:94 w:68 h:33 pixels:802 cover:0.3746%
  - x:381 y:228 w:71 h:24 pixels:773 cover:0.3610%
  - x:303 y:79 w:90 h:24 pixels:568 cover:0.2653%
  - x:453 y:228 w:70 h:14 pixels:558 cover:0.2606%
  - x:376 y:102 w:57 h:16 pixels:467 cover:0.2181%
  - x:108 y:222 w:45 h:15 pixels:365 cover:0.1705%
  - x:152 y:237 w:55 h:18 pixels:341 cover:0.1593%

### slide_010
- Referencia: artifacts/reference_slides\Slide10.PNG
- Atual: artifacts/actual_slides\slide_010.png
- Mismatch: 15.010%
- MAE: 15.300
- Mask: artifacts/visual_diff_run4\masks\slide_010_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_010_overlay.png
- Areas de diferenca:
  - x:12 y:56 w:297 h:227 pixels:6129 cover:2.8627%
  - x:326 y:66 w:122 h:45 pixels:1460 cover:0.6819%
  - x:247 y:20 w:98 h:18 pixels:1078 cover:0.5035%
  - x:132 y:20 w:112 h:18 pixels:1064 cover:0.4970%
  - x:441 y:66 w:74 h:19 pixels:515 cover:0.2405%
  - x:474 y:130 w:72 h:14 pixels:437 cover:0.2041%
  - x:193 y:304 w:69 h:10 pixels:404 cover:0.1887%
  - x:442 y:83 w:59 h:20 pixels:343 cover:0.1602%
  - x:108 y:304 w:56 h:10 pixels:313 cover:0.1462%
  - x:329 y:130 w:40 h:16 pixels:310 cover:0.1448%

### slide_015
- Referencia: artifacts/reference_slides\Slide15.PNG
- Atual: artifacts/actual_slides\slide_015.png
- Mismatch: 12.786%
- MAE: 12.958
- Mask: artifacts/visual_diff_run4\masks\slide_015_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_015_overlay.png
- Areas de diferenca:
  - x:46 y:59 w:106 h:25 pixels:1274 cover:0.5951%
  - x:46 y:83 w:141 h:38 pixels:1239 cover:0.5787%
  - x:343 y:130 w:110 h:30 pixels:1202 cover:0.5614%
  - x:335 y:169 w:102 h:25 pixels:1186 cover:0.5539%
  - x:46 y:111 w:130 h:36 pixels:958 cover:0.4475%
  - x:47 y:20 w:91 h:22 pixels:951 cover:0.4442%
  - x:347 y:104 w:118 h:25 pixels:947 cover:0.4423%
  - x:227 y:20 w:79 h:21 pixels:912 cover:0.4260%
  - x:30 y:142 w:131 h:16 pixels:900 cover:0.4204%
  - x:90 y:124 w:93 h:14 pixels:798 cover:0.3727%

### slide_013
- Referencia: artifacts/reference_slides\Slide13.PNG
- Atual: artifacts/actual_slides\slide_013.png
- Mismatch: 12.113%
- MAE: 13.232
- Mask: artifacts/visual_diff_run4\masks\slide_013_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_013_overlay.png
- Areas de diferenca:
  - x:76 y:68 w:145 h:48 pixels:1760 cover:0.8220%
  - x:40 y:159 w:152 h:38 pixels:1453 cover:0.6787%
  - x:131 y:131 w:111 h:40 pixels:815 cover:0.3807%
  - x:241 y:20 w:48 h:22 pixels:590 cover:0.2756%
  - x:107 y:20 w:60 h:18 pixels:572 cover:0.2672%
  - x:404 y:171 w:80 h:13 pixels:519 cover:0.2424%
  - x:127 y:118 w:84 h:14 pixels:460 cover:0.2149%
  - x:339 y:201 w:62 h:17 pixels:445 cover:0.2078%
  - x:432 y:124 w:53 h:13 pixels:429 cover:0.2004%
  - x:414 y:142 w:42 h:26 pixels:403 cover:0.1882%

### slide_014
- Referencia: artifacts/reference_slides\Slide14.PNG
- Atual: artifacts/actual_slides\slide_014.png
- Mismatch: 11.887%
- MAE: 13.863
- Mask: artifacts/visual_diff_run4\masks\slide_014_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_014_overlay.png
- Areas de diferenca:
  - x:33 y:106 w:319 h:161 pixels:14257 cover:6.6591%
  - x:381 y:98 w:52 h:26 pixels:617 cover:0.2882%
  - x:398 y:67 w:88 h:12 pixels:478 cover:0.2233%
  - x:194 y:20 w:53 h:18 pixels:468 cover:0.2186%
  - x:152 y:20 w:41 h:18 pixels:400 cover:0.1868%
  - x:426 y:125 w:56 h:16 pixels:355 cover:0.1658%
  - x:381 y:125 w:44 h:17 pixels:354 cover:0.1653%
  - x:115 y:20 w:32 h:18 pixels:328 cover:0.1532%
  - x:496 y:67 w:57 h:10 pixels:320 cover:0.1495%
  - x:56 y:20 w:29 h:18 pixels:293 cover:0.1369%

### slide_005
- Referencia: artifacts/reference_slides\Slide5.PNG
- Atual: artifacts/actual_slides\slide_005.png
- Mismatch: 9.770%
- MAE: 10.221
- Mask: artifacts/visual_diff_run4\masks\slide_005_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_005_overlay.png
- Areas de diferenca:
  - x:391 y:138 w:64 h:48 pixels:990 cover:0.4624%
  - x:156 y:16 w:69 h:18 pixels:782 cover:0.3653%
  - x:277 y:16 w:75 h:18 pixels:752 cover:0.3512%
  - x:204 y:146 w:126 h:74 pixels:725 cover:0.3386%
  - x:113 y:164 w:122 h:109 pixels:639 cover:0.2985%
  - x:13 y:16 w:52 h:22 pixels:577 cover:0.2695%
  - x:227 y:16 w:49 h:18 pixels:527 cover:0.2461%
  - x:82 y:16 w:42 h:18 pixels:412 cover:0.1924%
  - x:410 y:21 w:39 h:25 pixels:350 cover:0.1635%
  - x:442 y:72 w:33 h:23 pixels:328 cover:0.1532%

### slide_009
- Referencia: artifacts/reference_slides\Slide9.PNG
- Atual: artifacts/actual_slides\slide_009.png
- Mismatch: 9.694%
- MAE: 7.831
- Mask: artifacts/visual_diff_run4\masks\slide_009_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_009_overlay.png
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

### slide_012
- Referencia: artifacts/reference_slides\Slide12.PNG
- Atual: artifacts/actual_slides\slide_012.png
- Mismatch: 9.536%
- MAE: 10.519
- Mask: artifacts/visual_diff_run4\masks\slide_012_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_012_overlay.png
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
- Mismatch: 9.306%
- MAE: 10.376
- Mask: artifacts/visual_diff_run4\masks\slide_011_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_011_overlay.png
- Areas de diferenca:
  - x:53 y:20 w:139 h:22 pixels:1609 cover:0.7515%
  - x:325 y:65 w:67 h:44 pixels:953 cover:0.4451%
  - x:32 y:135 w:66 h:32 pixels:808 cover:0.3774%
  - x:229 y:20 w:69 h:22 pixels:748 cover:0.3494%
  - x:116 y:137 w:64 h:38 pixels:633 cover:0.2957%
  - x:52 y:65 w:46 h:22 pixels:400 cover:0.1868%
  - x:467 y:66 w:40 h:31 pixels:359 cover:0.1677%
  - x:433 y:66 w:33 h:33 pixels:355 cover:0.1658%
  - x:195 y:24 w:31 h:14 pixels:348 cover:0.1625%
  - x:32 y:111 w:66 h:10 pixels:318 cover:0.1485%

### slide_002
- Referencia: artifacts/reference_slides\Slide2.PNG
- Atual: artifacts/actual_slides\slide_002.png
- Mismatch: 8.829%
- MAE: 8.423
- Mask: artifacts/visual_diff_run4\masks\slide_002_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_002_overlay.png
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
- Mismatch: 8.289%
- MAE: 9.802
- Mask: artifacts/visual_diff_run4\masks\slide_007_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_007_overlay.png
- Areas de diferenca:
  - x:144 y:20 w:141 h:22 pixels:1588 cover:0.7417%
  - x:171 y:75 w:90 h:41 pixels:1374 cover:0.6418%
  - x:310 y:82 w:96 h:36 pixels:1235 cover:0.5768%
  - x:47 y:20 w:75 h:22 pixels:794 cover:0.3709%
  - x:68 y:94 w:60 h:22 pixels:746 cover:0.3484%
  - x:481 y:94 w:57 h:25 pixels:669 cover:0.3125%
  - x:32 y:81 w:40 h:35 pixels:644 cover:0.3008%
  - x:33 y:131 w:82 h:12 pixels:500 cover:0.2335%
  - x:448 y:94 w:36 h:22 pixels:467 cover:0.2181%
  - x:264 y:284 w:106 h:8 pixels:459 cover:0.2144%

### slide_004
- Referencia: artifacts/reference_slides\Slide4.PNG
- Atual: artifacts/actual_slides\slide_004.png
- Mismatch: 8.142%
- MAE: 9.569
- Mask: artifacts/visual_diff_run4\masks\slide_004_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_004_overlay.png
- Areas de diferenca:
  - x:58 y:20 w:86 h:22 pixels:904 cover:0.4222%
  - x:155 y:97 w:75 h:25 pixels:833 cover:0.3891%
  - x:366 y:99 w:102 h:23 pixels:825 cover:0.3853%
  - x:190 y:20 w:46 h:18 pixels:539 cover:0.2518%
  - x:343 y:133 w:73 h:13 pixels:434 cover:0.2027%
  - x:237 y:21 w:45 h:17 pixels:431 cover:0.2013%
  - x:448 y:134 w:58 h:13 pixels:360 cover:0.1681%
  - x:331 y:99 w:38 h:21 pixels:332 cover:0.1551%
  - x:82 y:71 w:35 h:22 pixels:320 cover:0.1495%
  - x:491 y:71 w:54 h:15 pixels:320 cover:0.1495%

### slide_003
- Referencia: artifacts/reference_slides\Slide3.PNG
- Atual: artifacts/actual_slides\slide_003.png
- Mismatch: 7.320%
- MAE: 9.110
- Mask: artifacts/visual_diff_run4\masks\slide_003_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_003_overlay.png
- Areas de diferenca:
  - x:429 y:100 w:95 h:33 pixels:1550 cover:0.7240%
  - x:51 y:100 w:45 h:53 pixels:1043 cover:0.4872%
  - x:163 y:20 w:94 h:18 pixels:1003 cover:0.4685%
  - x:47 y:20 w:85 h:18 pixels:859 cover:0.4012%
  - x:277 y:100 w:29 h:43 pixels:379 cover:0.1770%
  - x:93 y:100 w:31 h:40 pixels:338 cover:0.1579%
  - x:241 y:100 w:16 h:40 pixels:338 cover:0.1579%
  - x:290 y:100 w:27 h:40 pixels:336 cover:0.1569%
  - x:440 y:145 w:46 h:11 pixels:307 cover:0.1434%
  - x:134 y:20 w:28 h:18 pixels:291 cover:0.1359%

### slide_008
- Referencia: artifacts/reference_slides\Slide8.PNG
- Atual: artifacts/actual_slides\slide_008.png
- Mismatch: 6.503%
- MAE: 8.007
- Mask: artifacts/visual_diff_run4\masks\slide_008_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_008_overlay.png
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
- Mask: artifacts/visual_diff_run4\masks\slide_001_mask.png
- Overlay: artifacts/visual_diff_run4\overlays\slide_001_overlay.png
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

