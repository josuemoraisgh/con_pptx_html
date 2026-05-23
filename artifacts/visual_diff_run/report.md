# Relatorio de Comparacao Visual

- Slides comparados: 16
- Mismatch global: 16.031%
- MAE global: 15.556

## Renders sem referencia
- artifacts/actual_slides\test_960.png
- artifacts/actual_slides\test_fittedbox.png
- artifacts/actual_slides\test_fullscreen.png
- artifacts/actual_slides\test_raw.png
- artifacts/actual_slides\test_reload.png

## Slides por severidade

| Slide | Mismatch % | MAE | Areas (top 3) |
|---|---:|---:|---|
| slide_016 | 57.589 | 25.768 | [x:648 y:104 w:600 h:504 p:301434] [x:44 y:177 w:558 h:332 p:172765] [x:44 y:513 w:558 h:75 p:41121] |
| slide_006 | 20.310 | 24.149 | [x:436 y:90 w:807 h:587 p:4127] [x:818 y:538 w:195 h:66 p:4102] [x:346 y:38 w:167 h:43 p:3902] |
| slide_010 | 19.472 | 20.923 | [x:25 y:117 w:617 h:471 p:30651] [x:23 y:617 w:1221 h:52 p:7575] [x:682 y:187 w:121 h:73 p:4461] |
| slide_015 | 17.395 | 18.679 | [x:86 y:162 w:271 h:65 p:5959] [x:810 y:272 w:153 h:94 p:4978] [x:82 y:405 w:215 h:52 p:4888] |
| slide_009 | 15.766 | 11.685 | [x:21 y:94 w:1203 h:407 p:21031] [x:21 y:500 w:1203 h:127 p:7834] [x:884 y:127 w:274 h:56 p:6709] |
| slide_013 | 15.705 | 17.959 | [x:262 y:34 w:168 h:47 p:4219] [x:100 y:36 w:158 h:45 p:3939] [x:328 y:366 w:143 h:59 p:2681] |
| slide_014 | 13.036 | 16.391 | [x:69 y:220 w:661 h:334 p:58001] [x:797 y:189 w:218 h:98 p:6900] [x:0 y:704 w:1280 h:16 p:2588] |
| slide_011 | 13.034 | 14.740 | [x:208 y:40 w:191 h:46 p:4780] [x:470 y:652 w:267 h:29 p:4223] [x:597 y:34 w:115 h:60 p:2991] |
| slide_002 | 12.773 | 12.275 | [x:281 y:178 w:491 h:251 p:8552] [x:772 y:191 w:461 h:231 p:5772] [x:814 y:245 w:122 h:84 p:4610] |
| slide_005 | 12.587 | 13.375 | [x:125 y:233 w:662 h:290 p:8510] [x:27 y:25 w:237 h:63 p:6969] [x:814 y:44 w:170 h:106 p:5932] |
| slide_007 | 11.670 | 13.687 | [x:100 y:34 w:251 h:60 p:6822] [x:355 y:36 w:241 h:58 p:6099] [x:644 y:272 w:130 h:116 p:4587] |
| slide_004 | 11.457 | 13.606 | [x:162 y:34 w:173 h:58 p:4461] [x:0 y:704 w:1280 h:16 p:2588] [x:752 y:324 w:163 h:29 p:2519] |
| slide_012 | 11.241 | 13.456 | [x:190 y:34 w:128 h:58 p:3319] [x:0 y:704 w:1280 h:16 p:2588] [x:76 y:175 w:163 h:31 p:2295] |
| slide_003 | 10.031 | 11.949 | [x:98 y:36 w:238 h:45 p:5705] [x:108 y:231 w:164 h:50 p:4447] [x:893 y:229 w:228 h:29 p:4090] |
| slide_008 | 8.502 | 10.692 | [x:465 y:598 w:257 h:25 p:3644] [x:129 y:38 w:125 h:54 p:3049] [x:420 y:38 w:120 h:54 p:3044] |
| slide_001 | 5.921 | 9.555 | [x:479 y:393 w:171 h:58 p:5118] [x:721 y:393 w:100 h:58 p:2771] [x:0 y:704 w:1280 h:16 p:2588] |

## Detalhes por slide

### slide_016
- Referencia: artifacts/reference_slides\Slide16.PNG
- Atual: artifacts/actual_slides\slide_016.png
- Mismatch: 57.589%
- MAE: 25.768
- Mask: artifacts/visual_diff_run\masks\slide_016_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_016_overlay.png
- Areas de diferenca:
  - x:648 y:104 w:600 h:504 pixels:301434 cover:32.7077%
  - x:44 y:177 w:558 h:332 pixels:172765 cover:18.7462%
  - x:44 y:513 w:558 h:75 pixels:41121 cover:4.4619%
  - x:0 y:692 w:1280 h:28 pixels:4012 cover:0.4353%
  - x:68 y:129 w:489 h:23 pixels:2739 cover:0.2972%
  - x:1278 y:0 w:2 h:335 pixels:670 cover:0.0727%
  - x:23 y:125 w:1 h:465 pixels:465 cover:0.0505%
  - x:0 y:8 w:233 h:1 pixels:233 cover:0.0253%
  - x:382 y:610 w:106 h:2 pixels:212 cover:0.0230%
  - x:351 y:156 w:26 h:13 pixels:179 cover:0.0194%

### slide_006
- Referencia: artifacts/reference_slides\Slide6.PNG
- Atual: artifacts/actual_slides\slide_006.png
- Mismatch: 20.310%
- MAE: 24.149
- Mask: artifacts/visual_diff_run\masks\slide_006_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_006_overlay.png
- Areas de diferenca:
  - x:436 y:90 w:807 h:587 pixels:4127 cover:0.4478%
  - x:818 y:538 w:195 h:66 pixels:4102 cover:0.4451%
  - x:346 y:38 w:167 h:43 pixels:3902 cover:0.4234%
  - x:924 y:245 w:79 h:98 pixels:3190 cover:0.3461%
  - x:215 y:38 w:128 h:54 pixels:3144 cover:0.3411%
  - x:669 y:499 w:174 h:39 pixels:2757 cover:0.2992%
  - x:100 y:38 w:118 h:43 pixels:2628 cover:0.2852%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:831 y:274 w:91 h:77 pixels:2568 cover:0.2786%
  - x:751 y:189 w:189 h:25 pixels:2524 cover:0.2739%

### slide_010
- Referencia: artifacts/reference_slides\Slide10.PNG
- Atual: artifacts/actual_slides\slide_010.png
- Mismatch: 19.472%
- MAE: 20.923
- Mask: artifacts/visual_diff_run\masks\slide_010_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_010_overlay.png
- Areas de diferenca:
  - x:25 y:117 w:617 h:471 pixels:30651 cover:3.3258%
  - x:23 y:617 w:1221 h:52 pixels:7575 cover:0.8219%
  - x:682 y:187 w:121 h:73 pixels:4461 cover:0.4840%
  - x:240 y:627 w:189 h:27 pixels:2958 cover:0.3210%
  - x:888 y:210 w:168 h:54 pixels:2642 cover:0.2867%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:221 y:38 w:99 h:43 pixels:2569 cover:0.2788%
  - x:391 y:38 w:99 h:43 pixels:2440 cover:0.2648%
  - x:689 y:397 w:152 h:39 pixels:1948 cover:0.2114%
  - x:842 y:397 w:137 h:45 pixels:1757 cover:0.1906%

### slide_015
- Referencia: artifacts/reference_slides\Slide15.PNG
- Atual: artifacts/actual_slides\slide_015.png
- Mismatch: 17.395%
- MAE: 18.679
- Mask: artifacts/visual_diff_run\masks\slide_015_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_015_overlay.png
- Areas de diferenca:
  - x:86 y:162 w:271 h:65 pixels:5959 cover:0.6466%
  - x:810 y:272 w:153 h:94 pixels:4978 cover:0.5401%
  - x:82 y:405 w:215 h:52 pixels:4888 cover:0.5304%
  - x:796 y:362 w:157 h:64 pixels:4161 cover:0.4515%
  - x:710 y:266 w:101 h:75 pixels:3536 cover:0.3837%
  - x:718 y:345 w:90 h:77 pixels:3201 cover:0.3473%
  - x:286 y:225 w:164 h:50 pixels:3039 cover:0.3298%
  - x:303 y:376 w:160 h:27 pixels:2609 cover:0.2831%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:188 y:223 w:158 h:48 pixels:2531 cover:0.2746%

### slide_009
- Referencia: artifacts/reference_slides\Slide9.PNG
- Atual: artifacts/actual_slides\slide_009.png
- Mismatch: 15.766%
- MAE: 11.685
- Mask: artifacts/visual_diff_run\masks\slide_009_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_009_overlay.png
- Areas de diferenca:
  - x:21 y:94 w:1203 h:407 pixels:21031 cover:2.2820%
  - x:21 y:500 w:1203 h:127 pixels:7834 cover:0.8500%
  - x:884 y:127 w:274 h:56 pixels:6709 cover:0.7280%
  - x:214 y:373 w:988 h:61 pixels:6262 cover:0.6795%
  - x:231 y:117 w:156 h:79 pixels:5446 cover:0.5909%
  - x:660 y:523 w:145 h:77 pixels:4873 cover:0.5288%
  - x:498 y:285 w:204 h:47 pixels:4598 cover:0.4989%
  - x:758 y:274 w:203 h:65 pixels:4550 cover:0.4937%
  - x:739 y:262 w:463 h:91 pixels:4545 cover:0.4932%
  - x:436 y:36 w:150 h:45 pixels:3597 cover:0.3903%

### slide_013
- Referencia: artifacts/reference_slides\Slide13.PNG
- Atual: artifacts/actual_slides\slide_013.png
- Mismatch: 15.705%
- MAE: 17.959
- Mask: artifacts/visual_diff_run\masks\slide_013_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_013_overlay.png
- Areas de diferenca:
  - x:262 y:34 w:168 h:47 pixels:4219 cover:0.4578%
  - x:100 y:36 w:158 h:45 pixels:3939 cover:0.4274%
  - x:328 y:366 w:143 h:59 pixels:2681 cover:0.2909%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:686 y:507 w:160 h:32 pixels:2184 cover:0.2370%
  - x:552 y:34 w:77 h:52 pixels:2061 cover:0.2236%
  - x:679 y:345 w:141 h:32 pixels:2022 cover:0.2194%
  - x:863 y:257 w:115 h:38 pixels:2008 cover:0.2179%
  - x:704 y:301 w:110 h:34 pixels:1944 cover:0.2109%
  - x:432 y:36 w:64 h:45 pixels:1732 cover:0.1879%

### slide_014
- Referencia: artifacts/reference_slides\Slide14.PNG
- Atual: artifacts/actual_slides\slide_014.png
- Mismatch: 13.036%
- MAE: 16.391
- Mask: artifacts/visual_diff_run\masks\slide_014_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_014_overlay.png
- Areas de diferenca:
  - x:69 y:220 w:661 h:334 pixels:58001 cover:6.2935%
  - x:797 y:189 w:218 h:98 pixels:6900 cover:0.7487%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:98 y:38 w:91 h:43 pixels:2261 cover:0.2453%
  - x:448 y:38 w:86 h:43 pixels:2139 cover:0.2321%
  - x:191 y:38 w:95 h:43 pixels:2094 cover:0.2272%
  - x:380 y:38 w:67 h:43 pixels:1757 cover:0.1906%
  - x:316 y:47 w:61 h:34 pixels:1251 cover:0.1357%
  - x:832 y:363 w:80 h:28 pixels:855 cover:0.0928%
  - x:878 y:143 w:80 h:15 pixels:817 cover:0.0887%

### slide_011
- Referencia: artifacts/reference_slides\Slide11.PNG
- Atual: artifacts/actual_slides\slide_011.png
- Mismatch: 13.034%
- MAE: 14.740
- Mask: artifacts/visual_diff_run\masks\slide_011_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_011_overlay.png
- Areas de diferenca:
  - x:208 y:40 w:191 h:46 pixels:4780 cover:0.5187%
  - x:470 y:652 w:267 h:29 pixels:4223 cover:0.4582%
  - x:597 y:34 w:115 h:60 pixels:2991 cover:0.3245%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:401 y:34 w:106 h:58 pixels:2574 cover:0.2793%
  - x:113 y:34 w:93 h:60 pixels:2498 cover:0.2711%
  - x:507 y:44 w:87 h:43 pixels:2068 cover:0.2244%
  - x:851 y:330 w:118 h:62 pixels:2057 cover:0.2232%
  - x:113 y:266 w:76 h:97 pixels:1988 cover:0.2157%
  - x:276 y:289 w:58 h:95 pixels:1797 cover:0.1950%

### slide_002
- Referencia: artifacts/reference_slides\Slide2.PNG
- Atual: artifacts/actual_slides\slide_002.png
- Mismatch: 12.773%
- MAE: 12.275
- Mask: artifacts/visual_diff_run\masks\slide_002_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_002_overlay.png
- Areas de diferenca:
  - x:281 y:178 w:491 h:251 pixels:8552 cover:0.9280%
  - x:772 y:191 w:461 h:231 pixels:5772 cover:0.6263%
  - x:814 y:245 w:122 h:84 pixels:4610 cover:0.5002%
  - x:75 y:245 w:127 h:84 pixels:4596 cover:0.4987%
  - x:30 y:191 w:246 h:231 pixels:3473 cover:0.3768%
  - x:364 y:34 w:107 h:52 pixels:2832 cover:0.3073%
  - x:241 y:503 w:181 h:89 pixels:2777 cover:0.3013%
  - x:241 y:34 w:120 h:47 pixels:2720 cover:0.2951%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:98 y:34 w:98 h:47 pixels:2533 cover:0.2748%

### slide_005
- Referencia: artifacts/reference_slides\Slide5.PNG
- Atual: artifacts/actual_slides\slide_005.png
- Mismatch: 12.587%
- MAE: 13.375
- Mask: artifacts/visual_diff_run\masks\slide_005_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_005_overlay.png
- Areas de diferenca:
  - x:125 y:233 w:662 h:290 pixels:8510 cover:0.9234%
  - x:27 y:25 w:237 h:63 pixels:6969 cover:0.7562%
  - x:814 y:44 w:170 h:106 pixels:5932 cover:0.6437%
  - x:814 y:401 w:156 h:105 pixels:5502 cover:0.5970%
  - x:268 y:25 w:148 h:44 pixels:3283 cover:0.3562%
  - x:473 y:25 w:102 h:44 pixels:2599 cover:0.2820%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:88 y:337 w:66 h:54 pixels:2113 cover:0.2293%
  - x:949 y:403 w:76 h:71 pixels:1943 cover:0.2108%
  - x:993 y:447 w:86 h:27 pixels:1245 cover:0.1351%

### slide_007
- Referencia: artifacts/reference_slides\Slide7.PNG
- Atual: artifacts/actual_slides\slide_007.png
- Mismatch: 11.670%
- MAE: 13.687
- Mask: artifacts/visual_diff_run\masks\slide_007_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_007_overlay.png
- Areas de diferenca:
  - x:100 y:34 w:251 h:60 pixels:6822 cover:0.7402%
  - x:355 y:36 w:241 h:58 pixels:6099 cover:0.6618%
  - x:644 y:272 w:130 h:116 pixels:4587 cover:0.4977%
  - x:932 y:210 w:214 h:27 pixels:3674 cover:0.3987%
  - x:67 y:306 w:79 h:85 pixels:3010 cover:0.3266%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:644 y:210 w:116 h:27 pixels:2008 cover:0.2179%
  - x:389 y:310 w:85 h:64 pixels:1640 cover:0.1780%
  - x:409 y:243 w:96 h:27 pixels:1576 cover:0.1710%
  - x:355 y:210 w:101 h:27 pixels:1525 cover:0.1655%

### slide_004
- Referencia: artifacts/reference_slides\Slide4.PNG
- Atual: artifacts/actual_slides\slide_004.png
- Mismatch: 11.457%
- MAE: 13.606
- Mask: artifacts/visual_diff_run\masks\slide_004_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_004_overlay.png
- Areas de diferenca:
  - x:162 y:34 w:173 h:58 pixels:4461 cover:0.4840%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:752 y:324 w:163 h:29 pixels:2519 cover:0.2733%
  - x:712 y:264 w:100 h:54 pixels:2305 cover:0.2501%
  - x:527 y:34 w:83 h:47 pixels:2197 cover:0.2384%
  - x:402 y:34 w:87 h:47 pixels:2075 cover:0.2252%
  - x:337 y:34 w:62 h:47 pixels:1684 cover:0.1827%
  - x:100 y:36 w:61 h:45 pixels:1458 cover:0.1582%
  - x:662 y:140 w:14 h:458 pixels:1359 cover:0.1475%
  - x:335 y:223 w:93 h:24 pixels:1299 cover:0.1410%

### slide_012
- Referencia: artifacts/reference_slides\Slide12.PNG
- Atual: artifacts/actual_slides\slide_012.png
- Mismatch: 11.241%
- MAE: 13.456
- Mask: artifacts/visual_diff_run\masks\slide_012_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_012_overlay.png
- Areas de diferenca:
  - x:190 y:34 w:128 h:58 pixels:3319 cover:0.3601%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:76 y:175 w:163 h:31 pixels:2295 cover:0.2490%
  - x:100 y:36 w:89 h:50 pixels:2292 cover:0.2487%
  - x:59 y:434 w:97 h:57 pixels:1801 cover:0.1954%
  - x:366 y:36 w:68 h:45 pixels:1631 cover:0.1770%
  - x:127 y:208 w:104 h:27 pixels:1576 cover:0.1710%
  - x:515 y:46 w:58 h:35 pixels:1432 cover:0.1554%
  - x:851 y:469 w:100 h:27 pixels:1424 cover:0.1545%
  - x:830 y:386 w:7 h:256 pixels:1287 cover:0.1396%

### slide_003
- Referencia: artifacts/reference_slides\Slide3.PNG
- Atual: artifacts/actual_slides\slide_003.png
- Mismatch: 10.031%
- MAE: 11.949
- Mask: artifacts/visual_diff_run\masks\slide_003_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_003_overlay.png
- Areas de diferenca:
  - x:98 y:36 w:238 h:45 pixels:5705 cover:0.6190%
  - x:108 y:231 w:164 h:50 pixels:4447 cover:0.4825%
  - x:893 y:229 w:228 h:29 pixels:4090 cover:0.4438%
  - x:587 y:231 w:108 h:50 pixels:2752 cover:0.2986%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:1022 y:364 w:142 h:35 pixels:2095 cover:0.2273%
  - x:453 y:34 w:83 h:47 pixels:2094 cover:0.2272%
  - x:599 y:337 w:84 h:66 pixels:2019 cover:0.2191%
  - x:108 y:330 w:69 h:73 pixels:1952 cover:0.2118%
  - x:341 y:34 w:73 h:47 pixels:1763 cover:0.1913%

### slide_008
- Referencia: artifacts/reference_slides\Slide8.PNG
- Atual: artifacts/actual_slides\slide_008.png
- Mismatch: 8.502%
- MAE: 10.692
- Mask: artifacts/visual_diff_run\masks\slide_008_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_008_overlay.png
- Areas de diferenca:
  - x:465 y:598 w:257 h:25 pixels:3644 cover:0.3954%
  - x:129 y:38 w:125 h:54 pixels:3049 cover:0.3308%
  - x:420 y:38 w:120 h:54 pixels:3044 cover:0.3303%
  - x:428 y:301 w:334 h:83 pixels:3028 cover:0.3286%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:511 y:220 w:191 h:29 pixels:2582 cover:0.2802%
  - x:930 y:225 w:199 h:24 pixels:2565 cover:0.2783%
  - x:428 y:627 w:334 h:69 pixels:2351 cover:0.2551%
  - x:513 y:577 w:162 h:23 pixels:2208 cover:0.2396%
  - x:583 y:391 w:117 h:45 pixels:1999 cover:0.2169%

### slide_001
- Referencia: artifacts/reference_slides\Slide1.PNG
- Atual: artifacts/actual_slides\slide_001.png
- Mismatch: 5.921%
- MAE: 9.555
- Mask: artifacts/visual_diff_run\masks\slide_001_mask.png
- Overlay: artifacts/visual_diff_run\overlays\slide_001_overlay.png
- Areas de diferenca:
  - x:479 y:393 w:171 h:58 pixels:5118 cover:0.5553%
  - x:721 y:393 w:100 h:58 pixels:2771 cover:0.3007%
  - x:0 y:704 w:1280 h:16 pixels:2588 cover:0.2808%
  - x:826 y:395 w:66 h:56 pixels:2317 cover:0.2514%
  - x:383 y:393 w:58 h:58 pixels:2091 cover:0.2269%
  - x:654 y:407 w:64 h:44 pixels:1740 cover:0.1888%
  - x:597 y:584 w:119 h:27 pixels:1492 cover:0.1619%
  - x:968 y:559 w:115 h:22 pixels:1364 cover:0.1480%
  - x:645 y:559 w:113 h:29 pixels:1308 cover:0.1419%
  - x:258 y:395 w:43 h:56 pixels:1207 cover:0.1310%

