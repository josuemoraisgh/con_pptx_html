# Relatorio de Comparacao Visual

- Slides comparados: 16
- Mismatch global: 14.715%
- MAE global: 15.281

## Renders sem referencia
- artifacts/actual_slides\test_960.png
- artifacts/actual_slides\test_fittedbox.png
- artifacts/actual_slides\test_fullscreen.png
- artifacts/actual_slides\test_raw.png
- artifacts/actual_slides\test_reload.png

## Slides por severidade

| Slide | Mismatch % | MAE | Areas (top 3) |
|---|---:|---:|---|
| slide_016 | 39.228 | 25.589 | [x:312 y:50 w:289 h:243 p:69994] [x:25 y:183 w:93 h:30 p:1349] [x:28 y:129 w:64 h:19 p:663] |
| slide_006 | 20.173 | 23.534 | [x:377 y:105 w:67 h:64 p:1376] [x:273 y:116 w:88 h:49 p:1062] [x:391 y:260 w:97 h:31 p:1046] |
| slide_010 | 19.101 | 20.379 | [x:12 y:56 w:297 h:227 p:6225] [x:188 y:18 w:157 h:21 p:1841] [x:329 y:90 w:58 h:35 p:981] |
| slide_015 | 17.543 | 18.234 | [x:29 y:195 w:170 h:25 p:1815] [x:343 y:128 w:96 h:48 p:1742] [x:29 y:78 w:159 h:31 p:1591] |
| slide_013 | 15.661 | 17.724 | [x:48 y:17 w:77 h:22 p:962] [x:331 y:244 w:108 h:18 p:810] [x:172 y:134 w:90 h:20 p:726] |
| slide_014 | 13.749 | 16.248 | [x:33 y:106 w:319 h:161 p:14257] [x:384 y:91 w:108 h:48 p:1906] [x:92 y:18 w:59 h:21 p:710] |
| slide_009 | 13.558 | 10.869 | [x:10 y:96 w:580 h:136 p:2131] [x:111 y:56 w:105 h:38 p:1628] [x:47 y:18 w:104 h:26 p:1269] |
| slide_011 | 12.842 | 14.464 | [x:55 y:16 w:137 h:29 p:1729] [x:193 y:16 w:94 h:28 p:1138] [x:227 y:314 w:128 h:15 p:1063] |
| slide_005 | 12.566 | 13.354 | [x:392 y:193 w:102 h:54 p:1909] [x:13 y:12 w:114 h:30 p:1674] [x:392 y:21 w:83 h:51 p:1387] |
| slide_002 | 12.479 | 11.871 | [x:383 y:121 w:81 h:57 p:1721] [x:33 y:118 w:64 h:57 p:1691] [x:228 y:86 w:143 h:121 p:1622] |
| slide_012 | 11.917 | 13.527 | [x:92 y:16 w:62 h:28 p:802] [x:28 y:84 w:88 h:15 p:627] [x:28 y:100 w:83 h:16 p:601] |
| slide_007 | 11.405 | 13.462 | [x:48 y:16 w:122 h:29 p:1648] [x:172 y:17 w:115 h:28 p:1490] [x:310 y:118 w:98 h:69 p:1360] |
| slide_004 | 11.262 | 13.490 | [x:48 y:16 w:113 h:28 p:1465] [x:360 y:156 w:105 h:16 p:835] [x:343 y:127 w:48 h:26 p:555] |
| slide_003 | 9.640 | 11.775 | [x:47 y:17 w:115 h:22 p:1375] [x:430 y:100 w:110 h:24 p:1158] [x:52 y:111 w:79 h:24 p:1070] |
| slide_008 | 8.465 | 10.490 | [x:236 y:188 w:101 h:22 p:1011] [x:202 y:18 w:73 h:26 p:866] [x:206 y:180 w:161 h:40 p:772] |
| slide_001 | 5.845 | 9.486 | [x:231 y:189 w:82 h:29 p:1237] [x:398 y:190 w:68 h:28 p:1105] [x:185 y:189 w:45 h:29 p:724] |

## Detalhes por slide

### slide_016
- Referencia: artifacts/reference_slides\Slide16.PNG
- Atual: artifacts/actual_slides\slide_016.png
- Mismatch: 39.228%
- MAE: 25.589
- Mask: artifacts/visual_diff_run2\masks\slide_016_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_016_overlay.png
- Areas de diferenca:
  - x:312 y:50 w:289 h:243 pixels:69994 cover:32.6924%
  - x:25 y:183 w:93 h:30 pixels:1349 cover:0.6301%
  - x:28 y:129 w:64 h:19 pixels:663 cover:0.3097%
  - x:39 y:96 w:172 h:9 pixels:659 cover:0.3078%
  - x:124 y:258 w:63 h:20 pixels:651 cover:0.3041%
  - x:118 y:237 w:167 h:9 pixels:649 cover:0.3031%
  - x:33 y:62 w:236 h:11 pixels:583 cover:0.2723%
  - x:26 y:161 w:67 h:14 pixels:478 cover:0.2233%
  - x:33 y:110 w:236 h:2 pixels:472 cover:0.2205%
  - x:26 y:236 w:91 h:10 pixels:375 cover:0.1752%

### slide_006
- Referencia: artifacts/reference_slides\Slide6.PNG
- Atual: artifacts/actual_slides\slide_006.png
- Mismatch: 20.173%
- MAE: 23.534
- Mask: artifacts/visual_diff_run2\masks\slide_006_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_006_overlay.png
- Areas de diferenca:
  - x:377 y:105 w:67 h:64 pixels:1376 cover:0.6427%
  - x:273 y:116 w:88 h:49 pixels:1062 cover:0.4960%
  - x:391 y:260 w:97 h:31 pixels:1046 cover:0.4886%
  - x:23 y:295 w:98 h:27 pixels:979 cover:0.4573%
  - x:167 y:18 w:80 h:21 pixels:929 cover:0.4339%
  - x:445 y:118 w:47 h:49 pixels:877 cover:0.4096%
  - x:104 y:18 w:62 h:26 pixels:774 cover:0.3615%
  - x:335 y:91 w:118 h:12 pixels:771 cover:0.3601%
  - x:312 y:240 w:94 h:19 pixels:752 cover:0.3512%
  - x:69 y:234 w:89 h:15 pixels:650 cover:0.3036%

### slide_010
- Referencia: artifacts/reference_slides\Slide10.PNG
- Atual: artifacts/actual_slides\slide_010.png
- Mismatch: 19.101%
- MAE: 20.379
- Mask: artifacts/visual_diff_run2\masks\slide_010_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_010_overlay.png
- Areas de diferenca:
  - x:12 y:56 w:297 h:227 pixels:6225 cover:2.9075%
  - x:188 y:18 w:157 h:21 pixels:1841 cover:0.8599%
  - x:329 y:90 w:58 h:35 pixels:981 cover:0.4582%
  - x:338 y:191 w:134 h:22 pixels:874 cover:0.4082%
  - x:47 y:18 w:59 h:21 pixels:718 cover:0.3354%
  - x:108 y:302 w:99 h:13 pixels:693 cover:0.3237%
  - x:12 y:297 w:582 h:25 pixels:628 cover:0.2933%
  - x:107 y:18 w:47 h:21 pixels:610 cover:0.2849%
  - x:329 y:126 w:41 h:23 pixels:448 cover:0.2092%
  - x:346 y:215 w:45 h:22 pixels:372 cover:0.1738%

### slide_015
- Referencia: artifacts/reference_slides\Slide15.PNG
- Atual: artifacts/actual_slides\slide_015.png
- Mismatch: 17.543%
- MAE: 18.234
- Mask: artifacts/visual_diff_run2\masks\slide_015_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_015_overlay.png
- Areas de diferenca:
  - x:29 y:195 w:170 h:25 pixels:1815 cover:0.8477%
  - x:343 y:128 w:96 h:48 pixels:1742 cover:0.8136%
  - x:29 y:78 w:159 h:31 pixels:1591 cover:0.7431%
  - x:141 y:18 w:85 h:26 pixels:1069 cover:0.4993%
  - x:384 y:174 w:75 h:31 pixels:975 cover:0.4554%
  - x:157 y:108 w:83 h:25 pixels:818 cover:0.3821%
  - x:91 y:107 w:76 h:24 pixels:755 cover:0.3526%
  - x:346 y:166 w:43 h:38 pixels:741 cover:0.3461%
  - x:346 y:102 w:56 h:25 pixels:685 cover:0.3199%
  - x:30 y:143 w:86 h:16 pixels:673 cover:0.3143%

### slide_013
- Referencia: artifacts/reference_slides\Slide13.PNG
- Atual: artifacts/actual_slides\slide_013.png
- Mismatch: 15.661%
- MAE: 17.724
- Mask: artifacts/visual_diff_run2\masks\slide_013_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_013_overlay.png
- Areas de diferenca:
  - x:48 y:17 w:77 h:22 pixels:962 cover:0.4493%
  - x:331 y:244 w:108 h:18 pixels:810 cover:0.3783%
  - x:172 y:134 w:90 h:20 pixels:726 cover:0.3391%
  - x:158 y:176 w:69 h:29 pixels:703 cover:0.3284%
  - x:327 y:266 w:91 h:16 pixels:624 cover:0.2915%
  - x:172 y:101 w:90 h:18 pixels:610 cover:0.2849%
  - x:115 y:173 w:43 h:32 pixels:518 cover:0.2419%
  - x:169 y:16 w:38 h:23 pixels:514 cover:0.2401%
  - x:126 y:16 w:42 h:23 pixels:505 cover:0.2359%
  - x:266 y:16 w:37 h:26 pixels:493 cover:0.2303%

### slide_014
- Referencia: artifacts/reference_slides\Slide14.PNG
- Atual: artifacts/actual_slides\slide_014.png
- Mismatch: 13.749%
- MAE: 16.248
- Mask: artifacts/visual_diff_run2\masks\slide_014_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_014_overlay.png
- Areas de diferenca:
  - x:33 y:106 w:319 h:161 pixels:14257 cover:6.6591%
  - x:384 y:91 w:108 h:48 pixels:1906 cover:0.8902%
  - x:92 y:18 w:59 h:21 pixels:710 cover:0.3316%
  - x:47 y:18 w:44 h:21 pixels:542 cover:0.2532%
  - x:216 y:18 w:41 h:21 pixels:504 cover:0.2354%
  - x:183 y:18 w:32 h:21 pixels:407 cover:0.1901%
  - x:484 y:129 w:69 h:12 pixels:383 cover:0.1789%
  - x:413 y:66 w:63 h:13 pixels:340 cover:0.1588%
  - x:152 y:23 w:30 h:16 pixels:299 cover:0.1397%
  - x:382 y:78 w:48 h:10 pixels:298 cover:0.1392%

### slide_009
- Referencia: artifacts/reference_slides\Slide9.PNG
- Atual: artifacts/actual_slides\slide_009.png
- Mismatch: 13.558%
- MAE: 10.869
- Mask: artifacts/visual_diff_run2\masks\slide_009_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_009_overlay.png
- Areas de diferenca:
  - x:10 y:96 w:580 h:136 pixels:2131 cover:0.9953%
  - x:111 y:56 w:105 h:38 pixels:1628 cover:0.7604%
  - x:47 y:18 w:104 h:26 pixels:1269 cover:0.5927%
  - x:304 y:253 w:93 h:36 pixels:1261 cover:0.5890%
  - x:180 y:17 w:102 h:22 pixels:1225 cover:0.5722%
  - x:426 y:61 w:132 h:27 pixels:1150 cover:0.5371%
  - x:21 y:300 w:561 h:2 pixels:1121 cover:0.5236%
  - x:365 y:132 w:98 h:30 pixels:932 cover:0.4353%
  - x:19 y:163 w:78 h:21 pixels:678 cover:0.3167%
  - x:265 y:137 w:73 h:23 pixels:672 cover:0.3139%

### slide_011
- Referencia: artifacts/reference_slides\Slide11.PNG
- Atual: artifacts/actual_slides\slide_011.png
- Mismatch: 12.842%
- MAE: 14.464
- Mask: artifacts/visual_diff_run2\masks\slide_011_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_011_overlay.png
- Areas de diferenca:
  - x:55 y:16 w:137 h:29 pixels:1729 cover:0.8076%
  - x:193 y:16 w:94 h:28 pixels:1138 cover:0.5315%
  - x:227 y:314 w:128 h:15 pixels:1063 cover:0.4965%
  - x:288 y:16 w:55 h:29 pixels:723 cover:0.3377%
  - x:33 y:128 w:59 h:57 pixels:639 cover:0.2985%
  - x:128 y:139 w:41 h:46 pixels:565 cover:0.2639%
  - x:401 y:162 w:41 h:27 pixels:413 cover:0.1929%
  - x:356 y:314 w:54 h:13 pixels:366 cover:0.1709%
  - x:90 y:155 w:41 h:30 pixels:358 cover:0.1672%
  - x:86 y:111 w:50 h:16 pixels:357 cover:0.1667%

### slide_005
- Referencia: artifacts/reference_slides\Slide5.PNG
- Atual: artifacts/actual_slides\slide_005.png
- Mismatch: 12.566%
- MAE: 13.354
- Mask: artifacts/visual_diff_run2\masks\slide_005_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_005_overlay.png
- Areas de diferenca:
  - x:392 y:193 w:102 h:54 pixels:1909 cover:0.8916%
  - x:13 y:12 w:114 h:30 pixels:1674 cover:0.7819%
  - x:392 y:21 w:83 h:51 pixels:1387 cover:0.6478%
  - x:170 y:146 w:160 h:127 pixels:1254 cover:0.5857%
  - x:129 y:12 w:72 h:30 pixels:910 cover:0.4250%
  - x:228 y:12 w:49 h:22 pixels:650 cover:0.3036%
  - x:470 y:158 w:85 h:14 pixels:581 cover:0.2714%
  - x:479 y:215 w:41 h:29 pixels:476 cover:0.2223%
  - x:42 y:162 w:31 h:26 pixels:454 cover:0.2121%
  - x:411 y:108 w:30 h:33 pixels:431 cover:0.2013%

### slide_002
- Referencia: artifacts/reference_slides\Slide2.PNG
- Atual: artifacts/actual_slides\slide_002.png
- Mismatch: 12.479%
- MAE: 11.871
- Mask: artifacts/visual_diff_run2\masks\slide_002_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_002_overlay.png
- Areas de diferenca:
  - x:383 y:121 w:81 h:57 pixels:1721 cover:0.8038%
  - x:33 y:118 w:64 h:57 pixels:1691 cover:0.7898%
  - x:228 y:86 w:143 h:121 pixels:1622 cover:0.7576%
  - x:117 y:242 w:104 h:43 pixels:783 cover:0.3657%
  - x:14 y:92 w:118 h:111 pixels:728 cover:0.3400%
  - x:116 y:16 w:61 h:23 pixels:685 cover:0.3199%
  - x:508 y:123 w:71 h:26 pixels:681 cover:0.3181%
  - x:264 y:153 w:75 h:18 pixels:660 cover:0.3083%
  - x:151 y:123 w:67 h:27 pixels:622 cover:0.2905%
  - x:47 y:16 w:47 h:23 pixels:609 cover:0.2844%

### slide_012
- Referencia: artifacts/reference_slides\Slide12.PNG
- Atual: artifacts/actual_slides\slide_012.png
- Mismatch: 11.917%
- MAE: 13.527
- Mask: artifacts/visual_diff_run2\masks\slide_012_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_012_overlay.png
- Areas de diferenca:
  - x:92 y:16 w:62 h:28 pixels:802 cover:0.3746%
  - x:28 y:84 w:88 h:15 pixels:627 cover:0.2929%
  - x:28 y:100 w:83 h:16 pixels:601 cover:0.2807%
  - x:48 y:17 w:43 h:25 pixels:564 cover:0.2634%
  - x:221 y:210 w:75 h:11 pixels:500 cover:0.2335%
  - x:410 y:79 w:66 h:13 pixels:447 cover:0.2088%
  - x:176 y:17 w:34 h:22 pixels:411 cover:0.1920%
  - x:52 y:116 w:51 h:14 pixels:392 cover:0.1831%
  - x:211 y:186 w:4 h:123 pixels:370 cover:0.1728%
  - x:400 y:186 w:4 h:123 pixels:368 cover:0.1719%

### slide_007
- Referencia: artifacts/reference_slides\Slide7.PNG
- Atual: artifacts/actual_slides\slide_007.png
- Mismatch: 11.405%
- MAE: 13.462
- Mask: artifacts/visual_diff_run2\masks\slide_007_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_007_overlay.png
- Areas de diferenca:
  - x:48 y:16 w:122 h:29 pixels:1648 cover:0.7697%
  - x:172 y:17 w:115 h:28 pixels:1490 cover:0.6959%
  - x:310 y:118 w:98 h:69 pixels:1360 cover:0.6352%
  - x:171 y:149 w:48 h:49 pixels:903 cover:0.4218%
  - x:449 y:101 w:103 h:13 pixels:860 cover:0.4017%
  - x:32 y:147 w:39 h:41 pixels:770 cover:0.3596%
  - x:310 y:101 w:86 h:13 pixels:682 cover:0.3185%
  - x:142 y:281 w:119 h:13 pixels:673 cover:0.3143%
  - x:171 y:101 w:90 h:13 pixels:586 cover:0.2737%
  - x:477 y:148 w:57 h:34 pixels:438 cover:0.2046%

### slide_004
- Referencia: artifacts/reference_slides\Slide4.PNG
- Atual: artifacts/actual_slides\slide_004.png
- Mismatch: 11.262%
- MAE: 13.490
- Mask: artifacts/visual_diff_run2\masks\slide_004_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_004_overlay.png
- Areas de diferenca:
  - x:48 y:16 w:113 h:28 pixels:1465 cover:0.6843%
  - x:360 y:156 w:105 h:16 pixels:835 cover:0.3900%
  - x:343 y:127 w:48 h:26 pixels:555 cover:0.2592%
  - x:254 y:16 w:40 h:23 pixels:511 cover:0.2387%
  - x:194 y:16 w:42 h:23 pixels:506 cover:0.2363%
  - x:431 y:127 w:63 h:17 pixels:477 cover:0.2228%
  - x:343 y:188 w:53 h:27 pixels:464 cover:0.2167%
  - x:309 y:304 w:58 h:23 pixels:438 cover:0.2046%
  - x:115 y:304 w:59 h:17 pixels:432 cover:0.2018%
  - x:56 y:106 w:63 h:13 pixels:414 cover:0.1934%

### slide_003
- Referencia: artifacts/reference_slides\Slide3.PNG
- Atual: artifacts/actual_slides\slide_003.png
- Mismatch: 9.640%
- MAE: 11.775
- Mask: artifacts/visual_diff_run2\masks\slide_003_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_003_overlay.png
- Areas de diferenca:
  - x:47 y:17 w:115 h:22 pixels:1375 cover:0.6422%
  - x:430 y:100 w:110 h:24 pixels:1158 cover:0.5409%
  - x:52 y:111 w:79 h:24 pixels:1070 cover:0.4998%
  - x:160 y:55 w:163 h:14 pixels:916 cover:0.4278%
  - x:289 y:160 w:50 h:38 pixels:758 cover:0.3540%
  - x:283 y:111 w:52 h:24 pixels:664 cover:0.3101%
  - x:429 y:145 w:100 h:16 pixels:656 cover:0.3064%
  - x:47 y:55 w:103 h:14 pixels:609 cover:0.2844%
  - x:52 y:159 w:33 h:36 pixels:581 cover:0.2714%
  - x:219 y:16 w:39 h:23 pixels:502 cover:0.2345%

### slide_008
- Referencia: artifacts/reference_slides\Slide8.PNG
- Atual: artifacts/actual_slides\slide_008.png
- Mismatch: 8.465%
- MAE: 10.490
- Mask: artifacts/visual_diff_run2\masks\slide_008_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_008_overlay.png
- Areas de diferenca:
  - x:236 y:188 w:101 h:22 pixels:1011 cover:0.4722%
  - x:202 y:18 w:73 h:26 pixels:866 cover:0.4045%
  - x:206 y:180 w:161 h:40 pixels:772 cover:0.3606%
  - x:206 y:271 w:161 h:39 pixels:762 cover:0.3559%
  - x:62 y:18 w:60 h:26 pixels:718 cover:0.3354%
  - x:276 y:18 w:60 h:21 pixels:700 cover:0.3270%
  - x:246 y:106 w:92 h:14 pixels:586 cover:0.2737%
  - x:247 y:278 w:78 h:11 pixels:500 cover:0.2335%
  - x:275 y:288 w:73 h:12 pixels:488 cover:0.2279%
  - x:124 y:22 w:43 h:17 pixels:485 cover:0.2265%

### slide_001
- Referencia: artifacts/reference_slides\Slide1.PNG
- Atual: artifacts/actual_slides\slide_001.png
- Mismatch: 5.845%
- MAE: 9.486
- Mask: artifacts/visual_diff_run2\masks\slide_001_mask.png
- Overlay: artifacts/visual_diff_run2\overlays\slide_001_overlay.png
- Areas de diferenca:
  - x:231 y:189 w:82 h:29 pixels:1237 cover:0.5778%
  - x:398 y:190 w:68 h:28 pixels:1105 cover:0.5161%
  - x:185 y:189 w:45 h:29 pixels:724 cover:0.3382%
  - x:348 y:189 w:48 h:29 pixels:690 cover:0.3223%
  - x:435 y:269 w:87 h:11 pixels:551 cover:0.2574%
  - x:284 y:269 w:81 h:14 pixels:423 cover:0.1976%
  - x:315 y:196 w:31 h:22 pixels:420 cover:0.1962%
  - x:148 y:269 w:65 h:10 pixels:333 cover:0.1555%
  - x:124 y:190 w:21 h:27 pixels:284 cover:0.1326%
  - x:298 y:281 w:47 h:13 pixels:282 cover:0.1317%

