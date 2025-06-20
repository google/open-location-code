' Code to test the VisualBasic OpenLocationCode functions.
' Copy this into your VB macro and run the TEST_All() function.

Private Function loadEncodingTestCSV() AS Variant

    Dim testCases(302) As Variant
    testCases(0) = Array(20.375, 2.775, 2759375000, 1497292800, 6, "7FG49Q00+")
    testCases(1) = Array(20.3700625, 2.7821875, 2759251562, 1497351680, 10, "7FG49QCJ+2V")
    testCases(2) = Array(20.3701125, 2.782234375, 2759252812, 1497352064, 11, "7FG49QCJ+2VX")
    testCases(3) = Array(20.3701135, 2.78223535156, 2759252837, 1497352071, 13, "7FG49QCJ+2VXGJ")
    testCases(4) = Array(47.0000625, 8.0000625, 3425001562, 1540096512, 10, "8FVC2222+22")
    testCases(5) = Array(-41.2730625, 174.7859375, 1218173437, 2906406400, 10, "4VCPPQGP+Q9")
    testCases(6) = Array(0.5, -179.5, 2262500000, 4096000, 4, "62G20000+")
    testCases(7) = Array(-89.5, -179.5, 12500000, 4096000, 4, "22220000+")
    testCases(8) = Array(20.5, 2.5, 2762500000, 1495040000, 4, "7FG40000+")
    testCases(9) = Array(-89.9999375, -179.9999375, 1562, 512, 10, "22222222+22")
    testCases(10) = Array(0.5, 179.5, 2262500000, 2945024000, 4, "6VGX0000+")
    testCases(11) = Array(1, 1, 2275000000, 1482752000, 11, "6FH32222+222")
    testCases(12) = Array(90, 1, 4499999999, 1482752000, 4, "CFX30000+")
    testCases(13) = Array(92, 1, 4499999999, 1482752000, 4, "CFX30000+")
    testCases(14) = Array(90, 1, 4499999999, 1482752000, 10, "CFX3X2X2+X2")
    testCases(15) = Array(1, 180, 2275000000, 0, 4, "62H20000+")
    testCases(16) = Array(1, 181, 2275000000, 8192000, 4, "62H30000+")
    testCases(17) = Array(20.3701135, 362.78223535156, 2759252837, 1497352071, 13, "7FG49QCJ+2VXGJ")
    testCases(18) = Array(47.0000625, 728.0000625, 3425001562, 1540096512, 10, "8FVC2222+22")
    testCases(19) = Array(-41.2730625, 1254.7859375, 1218173437, 2906406400, 10, "4VCPPQGP+Q9")
    testCases(20) = Array(20.3701135, -357.217764648, 2759252837, 1497352072, 13, "7FG49QCJ+2VXGJ")
    testCases(21) = Array(47.0000625, -711.9999375, 3425001562, 1540096512, 10, "8FVC2222+22")
    testCases(22) = Array(-41.2730625, -905.2140625, 1218173437, 2906406400, 10, "4VCPPQGP+Q9")
    testCases(23) = Array(1.2, 3.4, 2280000000, 1502412800, 10, "6FH56C22+22")
    testCases(24) = Array(37.539669125, -122.375069724, 3188491728, 472063428, 15, "849VGJQF+VX7QR3J")
    testCases(25) = Array(37.539669125, -122.375069724, 3188491728, 472063428, 16, "849VGJQF+VX7QR3J")
    testCases(26) = Array(37.539669125, -122.375069724, 3188491728, 472063428, 100, "849VGJQF+VX7QR3J")
    testCases(27) = Array(35.6, 3.033, 3140000000, 1499406336, 10, "8F75J22M+26")
    testCases(28) = Array(-48.71, 142.78, 1032250000, 2644213760, 8, "4R347QRJ+")
    testCases(29) = Array(-70, 163.7, 500000000, 2815590400, 8, "3V252P22+")
    testCases(30) = Array(-2.804, 7.003, 2179900000, 1531928576, 13, "6F9952W3+C6222")
    testCases(31) = Array(13.9, 164.88, 2597500000, 2825256960, 12, "7V56WV2J+2222")
    testCases(32) = Array(-13.23, 172.77, 1919250000, 2889891840, 8, "5VRJQQCC+")
    testCases(33) = Array(40.6, 129.7, 3265000000, 2537062400, 8, "8QGFJP22+")
    testCases(34) = Array(-52.166, 13.694, 945850000, 1586741248, 14, "3FVMRMMV+JJ2222")
    testCases(35) = Array(-14, 106.9, 1900000000, 2350284800, 6, "5PR82W00+")
    testCases(36) = Array(70.3, -87.64, 4007500000, 756613120, 13, "C62J8926+22222")
    testCases(37) = Array(66.89, -106, 3922250000, 606208000, 10, "95RPV2R2+22")
    testCases(38) = Array(2.5, -64.23, 2312500000, 948387840, 11, "67JQGQ2C+222")
    testCases(39) = Array(-56.7, -47.2, 832500000, 1087897600, 14, "38MJ8R22+222222")
    testCases(40) = Array(-34.45, -93.719, 1388750000, 706813952, 6, "46Q8H700+")
    testCases(41) = Array(-35.849, -93.75, 1353775000, 706560000, 12, "46P85722+C222")
    testCases(42) = Array(65.748, 24.316, 3893700000, 1673756672, 12, "9GQ6P8X8+6C22")
    testCases(43) = Array(-57.32, 130.43, 817000000, 2543042560, 12, "3QJGMCJJ+2222")
    testCases(44) = Array(17.6, -44.4, 2690000000, 1110835200, 6, "789QJJ00+")
    testCases(45) = Array(-27.6, -104.8, 1560000000, 616038400, 6, "554QC600+")
    testCases(46) = Array(41.87, -145.59, 3296750000, 281886720, 13, "83HPVCC6+22222")
    testCases(47) = Array(-4.542, 148.638, 2136450000, 2692202496, 13, "6R7CFJ5Q+66222")
    testCases(48) = Array(-37.014, -159.936, 1324650000, 164364288, 10, "43J2X3P7+CJ")
    testCases(49) = Array(-57.25, 125.49, 818750000, 2502574080, 15, "3QJ7QF2R+2222222")
    testCases(50) = Array(48.89, -80.52, 3472250000, 814940160, 13, "86WXVFRJ+22222")
    testCases(51) = Array(53.66, 170.97, 3591500000, 2875146240, 14, "9V5GMX6C+222222")
    testCases(52) = Array(0.49, -76.97, 2262250000, 844021760, 15, "67G5F2RJ+2222222")
    testCases(53) = Array(40.44, -36.7, 3261000000, 1173913600, 12, "89G5C8R2+2222")
    testCases(54) = Array(58.73, 69.95, 3718250000, 2047590400, 8, "9JCFPXJ2+")
    testCases(55) = Array(16.179, 150.075, 2654475000, 2703974400, 12, "7R8G53HG+J222")
    testCases(56) = Array(-55.574, -70.061, 860650000, 900620288, 12, "37PFCWGQ+CJ22")
    testCases(57) = Array(76.1, -82.5, 4152500000, 798720000, 15, "C68V4G22+2222222")
    testCases(58) = Array(58.66, 149.17, 3716500000, 2696560640, 10, "9RCFM56C+22")
    testCases(59) = Array(-67.2, 48.6, 570000000, 1872691200, 6, "3H4CRJ00+")
    testCases(60) = Array(-5.6, -54.5, 2110000000, 1028096000, 14, "6867CG22+222222")
    testCases(61) = Array(-34, 145.5, 1400000000, 2666496000, 14, "4RR72G22+222222")
    testCases(62) = Array(-34.2, 66.4, 1395000000, 2018508800, 12, "4JQ8RC22+2222")
    testCases(63) = Array(17.8, -108.5, 2695000000, 585728000, 6, "759HRG00+")
    testCases(64) = Array(10.734, -168.294, 2518350000, 95895552, 10, "722HPPM4+JC")
    testCases(65) = Array(-28.732, 54.32, 1531700000, 1919549440, 8, "5H3P789C+")
    testCases(66) = Array(64.1, 107.9, 3852500000, 2358476800, 12, "9PP94W22+2222")
    testCases(67) = Array(79.7525, 6.9623, 4243812500, 1531595161, 8, "CFF8QX36+")
    testCases(68) = Array(-63.6449, -25.1475, 658877500, 1268551680, 8, "398P9V43+")
    testCases(69) = Array(35.019, 148.827, 3125475000, 2693750784, 11, "8R7C2R9G+JR2")
    testCases(70) = Array(71.132, -98.584, 4028300000, 666959872, 15, "C6334CJ8+RC22222")
    testCases(71) = Array(53.38, -51.34, 3584500000, 1053982720, 12, "985C9MJ6+2222")
    testCases(72) = Array(-1.2, 170.2, 2220000000, 2868838400, 12, "6VCGR622+2222")
    testCases(73) = Array(50.2, -162.8, 3505000000, 140902400, 11, "922V6622+222")
    testCases(74) = Array(-25.798, -59.812, 1605050000, 984580096, 10, "5862652Q+R6")
    testCases(75) = Array(81.654, -162.422, 4291350000, 143998976, 14, "C2HVMH3H+J62222")
    testCases(76) = Array(-75.7, -35.4, 357500000, 1184563200, 8, "29P68J22+")
    testCases(77) = Array(67.2, 115.1, 3930000000, 2417459200, 11, "9PVQ6422+222")
    testCases(78) = Array(-78.137, -42.995, 296575000, 1122344960, 12, "28HVV274+6222")
    testCases(79) = Array(-56.3, 114.5, 842500000, 2412544000, 11, "3PMPPG22+222")
    testCases(80) = Array(10.767, -62.787, 2519175000, 960208896, 13, "772VQ687+R6222")
    testCases(81) = Array(-19.212, 107.423, 1769700000, 2354569216, 10, "5PG9QCQF+66")
    testCases(82) = Array(21.192, -45.145, 2779800000, 1104732160, 15, "78HP5VR4+R222222")
    testCases(83) = Array(16.701, 148.648, 2667525000, 2692284416, 14, "7R8CPJ2X+C62222")
    testCases(84) = Array(52.25, -77.45, 3556250000, 840089600, 15, "97447H22+2222222")
    testCases(85) = Array(-68.54504, -62.81725, 536374000, 959961088, 11, "373VF53M+X4J")
    testCases(86) = Array(76.7, -86.172, 4167500000, 768638976, 12, "C68MPR2H+2622")
    testCases(87) = Array(-6.2, 96.6, 2095000000, 2265907200, 13, "6M5RRJ22+22222")
    testCases(88) = Array(59.32, -157.21, 3733000000, 186695680, 12, "93F48QCR+2222")
    testCases(89) = Array(29.7, 39.6, 2992500000, 1798963200, 12, "7GXXPJ22+2222")
    testCases(90) = Array(-18.32, 96.397, 1792000000, 2264244224, 10, "5MHRM9JW+2R")
    testCases(91) = Array(-30.3, 76.5, 1492500000, 2101248000, 11, "4JXRPG22+222")
    testCases(92) = Array(50.342, -112.534, 3508550000, 552681472, 15, "95298FR8+RC22222")
    testCases(93) = Array(80.0100000001, 58.57, 4250250000, 1954365440, 15, "CHGW2H6C+2222222")
    testCases(94) = Array(80.00999996, 58.57, 4250249999, 1954365440, 15, "CHGW2H5C+X2RRRRR")
    testCases(95) = Array(-80.0099999999, 58.57, 249750000, 1954365440, 15, "2HFWXHRC+2222222")
    testCases(96) = Array(-80.0100000399, 58.57, 249749999, 1954365440, 15, "2HFWXHQC+X2RRRRR")
    testCases(97) = Array(47.000000080000000, 8.00022229, 3425000002, 1540097820, 15, "8FVC2222+235235C")
    testCases(98) = Array(68.3500147997595, 113.625636875353, 3958750369, 2405381217, 15, "9PWM9J2G+272FWJV")
    testCases(99) = Array(38.1176000887231, 165.441989844555, 3202940002, 2829860780, 15, "8VC74C9R+2QX445C")
    testCases(100) = Array(-28.1217794010122, -154.066811473758, 1546955514, 212444680, 15, "5337VWHM+77PR2GR")
    testCases(101) = Array(37.539669125, -122.375069724, 3188491728, 472063428, 2, "84000000+")
    testCases(102) = Array(51.1276857, -184.2279861, 3528192142, 2914484337, 11, "9V3Q4QHC+3RC")
    testCases(103) = Array(-93.84140, -162.06820, 0, 146897305, 10, "222V2W2J+2P")
    testCases(104) = Array(-25.1585965, -176.4414937, 1621035087, 29151283, 14, "5265RHR5+HC62QC")
    testCases(105) = Array(82.806550, 30.229187, 4320163750, 1722197499, 13, "CGJGR64H+JMF55")
    testCases(106) = Array(52.67256, -4.55204, 3566814000, 1437269688, 13, "9C4QMCFX+25GG5")
    testCases(107) = Array(14.9420223132, -24.1698775963, 2623550557, 1276560362, 2, "79000000+")
    testCases(108) = Array(50.46, 112.02, 3511500000, 2392227840, 12, "9P2JF26C+2222")
    testCases(109) = Array(-72.929463, 42.000964, 426763425, 1818631897, 4, "2HV40000+")
    testCases(110) = Array(76.091456, -125.608062, 4152286400, 445578756, 8, "C48P39RR+")
    testCases(111) = Array(-94.103, -38.308, 0, 1160740864, 14, "29232M2R+2R2222")
    testCases(112) = Array(88.1, 86.0, 4452500000, 2179072000, 4, "CMW80000+")
    testCases(113) = Array(-44.545247, -40.700335, 1136368825, 1141142855, 10, "487XF73X+WV")
    testCases(114) = Array(20.67, -133.40, 2766750000, 381747200, 8, "74G8MJC2+")
    testCases(115) = Array(91.37590, -96.45974, 4499999999, 684361809, 10, "C6X5XGXR+X4")
    testCases(116) = Array(64.61, -192.97, 3865250000, 2842869760, 12, "9VP9J26J+2222")
    testCases(117) = Array(-19.427, -156.355, 1764325000, 193699840, 12, "53G5HJFW+6222")
    testCases(118) = Array(-77.172610657, -122.783537134, 320684733, 468717263, 8, "24JVR6G8+")
    testCases(119) = Array(-48, -141, 1050000000, 319488000, 10, "434X2222+22")
    testCases(120) = Array(-48, -111, 1050000000, 565248000, 2, "45000000+")
    testCases(121) = Array(34.59271625, 33.43832676, 3114817906, 1748486772, 15, "8G6MHCVQ+38PM976")
    testCases(122) = Array(-18.70036, -9.64681, 1782491000, 1395533332, 6, "5CHG7900+")
    testCases(123) = Array(82.14, 194.83, 4303500000, 121487360, 6, "C2JP4R00+")
    testCases(124) = Array(-83.0611, -53.5201, 173472500, 1036123340, 6, "2888WF00+")
    testCases(125) = Array(-90.5, -61.8, 0, 968294400, 14, "272W2622+222222")
    testCases(126) = Array(23.857492947, -38.922971931, 2846437323, 1155703013, 8, "79M3V34G+")
    testCases(127) = Array(71.301289, -127.202151, 4032532225, 432519979, 15, "C43J8Q2X+G49CW45")
    testCases(128) = Array(22.613410, -65.531218, 2815335250, 937728262, 2, "77000000+")
    testCases(129) = Array(-59.5, 100.8, 762500000, 2300313600, 2, "3P000000+")
    testCases(130) = Array(87.021195762, -199.388732204, 4425529894, 2790287505, 15, "CVV22JC6+FGCW3JV")
    testCases(131) = Array(58.5932701, 172.4650093, 3714831752, 2887393356, 12, "9VCJHFV8+822V")
    testCases(132) = Array(-31.17610, 41.37565, 1470597500, 1813509324, 8, "4HW3R9FG+")
    testCases(133) = Array(44, 58, 3350000000, 1949696000, 6, "8HPW2200+")
    testCases(134) = Array(-4.0070, 154.7493, 2149825000, 2742266265, 6, "6R7PXP00+")
    testCases(135) = Array(2.8, -119.9, 2320000000, 492339200, 12, "65J2R422+2222")
    testCases(136) = Array(77.296962202, -118.449652886, 4182424055, 504220443, 4, "C5930000+")
    testCases(137) = Array(35.48003, 96.52265, 3137000750, 2265273548, 15, "8M7RFGJF+2369252")
    testCases(138) = Array(52.42264, 60.49549, 3560566000, 1970139054, 8, "9J42CFFW+")
    testCases(139) = Array(29.096, 166.130, 2977400000, 2835496960, 10, "7VX834WJ+C2")
    testCases(140) = Array(67.496291, 38.248585, 3937407275, 1787892408, 10, "9GVWF6WX+GC")
    testCases(141) = Array(69.298163526, -181.784436557, 3982454088, 2934501895, 11, "9VXW76X8+768")
    testCases(142) = Array(48.44527393761, 195.13608085747, 3461131848, 123994774, 8, "82WQC4WP+")
    testCases(143) = Array(-28.8394, 166.9146, 1529015000, 2841924403, 6, "5V385W00+")
    testCases(144) = Array(46.01263, 109.23175, 3400315750, 2369386496, 15, "8PRF267J+3P26222")
    testCases(145) = Array(-61.385416741, -100.103564052, 715364581, 654511603, 8, "35CXJV7W+")
    testCases(146) = Array(85.6301065, 194.7590568, 4390752662, 120906193, 8, "C2QPJQJ5+")
    testCases(147) = Array(-74.602, 189.932, 384950000, 81362944, 8, "22QF9WXJ+")
    testCases(148) = Array(-90.930, -145.371, 0, 283680768, 11, "232P2J2H+2J2")
    testCases(149) = Array(-58.618133, 64.746630, 784546675, 2004964392, 4, "3JH60000+")
    testCases(150) = Array(66.1423, -96.6000, 3903557500, 683212800, 10, "96R54CR2+W2")
    testCases(151) = Array(-39.962, 168.233, 1250950000, 2852724736, 4, "4VGC0000+")
    testCases(152) = Array(98.31, 86.17, 4499999999, 2180464640, 11, "CMX8X5XC+X2R")
    testCases(153) = Array(47.858925, -75.223290, 3446473125, 858330808, 14, "87V6VQ5G+HMG454")
    testCases(154) = Array(-17.150, -84.306, 1821250000, 783925248, 12, "56JQVM2V+2J22")
    testCases(155) = Array(-95.31345221, -172.90260796, 0, 58141835, 15, "2229232W+2X24245")
    testCases(156) = Array(-79.859625, 177.096808, 253509375, 2925337051, 14, "2VGV43RW+5P3534")
    testCases(157) = Array(88.265429, -198.447568, 4456635725, 2797997522, 14, "CVW37H82+5XF5V2")
    testCases(158) = Array(13.325, 34.920, 2583125000, 1760624640, 2, "7G000000+")
    testCases(159) = Array(-63.6, -145.4, 660000000, 283443200, 2, "33000000+")
    testCases(160) = Array(-54.4872370910, -142.4976735090, 887819072, 307219058, 15, "33QVGG72+4W4FHRG")
    testCases(161) = Array(89.796622, 61.685912, 4494915550, 1979890991, 6, "CJX3QM00+")
    testCases(162) = Array(-25.2, 50.7, 1620000000, 1889894400, 8, "5H6GRP22+")
    testCases(163) = Array(-78.7376, 66.6281, 281560000, 2020377395, 6, "2JH87J00+")
    testCases(164) = Array(-83.5768747454, -84.1155546149, 160578131, 785485376, 10, "268QCVFM+7Q")
    testCases(165) = Array(87.1741743283, -98.9097172279, 4429354358, 664291596, 10, "C6V353FR+M4")
    testCases(166) = Array(-92.1234, 147.2214, 0, 2680597708, 6, "2R292600+")
    testCases(167) = Array(-96.081, 30.930, 0, 1727938560, 14, "2G2G2W2J+222222")
    testCases(168) = Array(58.544790, 0.954987, 3713619750, 1482383253, 4, "9FC20000+")
    testCases(169) = Array(85.223791, 166.317567, 4380594775, 2837033508, 8, "CVQ868F9+")
    testCases(170) = Array(22.4144501873, 161.5737330425, 2810361254, 2798172021, 15, "7VJ3CH7F+QFQ353V")
    testCases(171) = Array(-81, -189, 225000000, 2875392000, 4, "2VFH0000+")
    testCases(172) = Array(-3.87, 106.31, 2153250000, 2345451520, 6, "6P884800+")
    testCases(173) = Array(-86.07687005, 17.43081941, 98078248, 1617353272, 14, "2F5VWCFJ+7842XW")
    testCases(174) = Array(4.00247742, -147.71777983, 2350061935, 264455947, 6, "63PJ2700+")
    testCases(175) = Array(-34.13283986879, 143.93778642288, 1396679003, 2653698346, 2, "4R000000+")
    testCases(176) = Array(-42.77927502, 197.58056291, 1180518124, 144019971, 13, "429V6HCJ+76PRR")
    testCases(177) = Array(71.797168141, 116.102605255, 4044929203, 2425672542, 15, "CP3RQ4W3+V29MM5P")
    testCases(178) = Array(-14.52796652, -19.29446968, 1886800837, 1316499704, 13, "5CQ2FPC4+R669Q")
    testCases(179) = Array(-46.42436011120, -134.97185393078, 1089390997, 368870572, 11, "4457H2GH+772")
    testCases(180) = Array(-83.95, 57.33, 151250000, 1944207360, 12, "2H8V382J+2222")
    testCases(181) = Array(-81.15680196, 116.13215255, 221079951, 2425914593, 12, "2PCRR4VJ+7VCX")
    testCases(182) = Array(-69.8553608, 38.5416297, 503615980, 1790293030, 10, "3G2W4GVR+VM")
    testCases(183) = Array(70.06392017, 142.68513577, 4001598004, 2643436632, 8, "CR243M7P+")
    testCases(184) = Array(-37.87035641911, 31.45160895416, 1303241089, 1732211580, 15, "4GJH4FH2+VJ5MQHR")
    testCases(185) = Array(-3.31237547, 55.93515507, 2167190613, 1932780790, 15, "6H8QMWQP+23RXXFP")
    testCases(186) = Array(-36.7954655, 151.3817689, 1330113362, 2714679450, 14, "4RMH693J+RP68VG")
    testCases(187) = Array(95.854385181, 79.466306447, 4499999999, 2125547982, 10, "CJXXXFX8+XG")
    testCases(188) = Array(31.53982775, 98.72663309, 3038495693, 2283328578, 11, "8M3WGPQG+WMJ")
    testCases(189) = Array(25.5118795897, 57.7948659543, 2887796989, 1948015541, 14, "7HQVGQ6V+QW54XF")
    testCases(190) = Array(71, 121, 4025000000, 2465792000, 2, "CQ000000+")
    testCases(191) = Array(-82, -9, 200000000, 1400832000, 2, "2C000000+")
    testCases(192) = Array(-76.08163425, 173.15964020, 347959143, 2893083772, 6, "2VMMW500+")
    testCases(193) = Array(40.53562804190, -79.76323109809, 3263390701, 821139610, 2, "87000000+")
    testCases(194) = Array(-61.40656, -81.69399, 714836000, 805322833, 6, "36CWH800+")
    testCases(195) = Array(27.8722, -178.2141, 2946805000, 14630092, 10, "72V3VQCP+V9")
    testCases(196) = Array(-92.2718492, 40.5508329, 0, 1806752423, 11, "2H222H22+284")
    testCases(197) = Array(70.3331, -67.4144, 4008327500, 922301235, 15, "C72J8HMP+66X2525")
    testCases(198) = Array(-63.163054, 106.207383, 670923650, 2344610881, 6, "3P88R600+")
    testCases(199) = Array(57.234, 92.971, 3680850000, 2236178432, 15, "9M9J6XMC+JC22222")
    testCases(200) = Array(37.1, -195.4, 3177500000, 2822963200, 12, "8V964J22+2222")
    testCases(201) = Array(31.197, 9.919, 3029925000, 1555816448, 8, "8F3F5WW9+")
    testCases(202) = Array(85.557757154, -182.229592353, 4388943928, 2930855179, 12, "CVQVHQ5C+4536")
    testCases(203) = Array(1.50383657, -69.55623429, 2287595914, 904755328, 4, "67HG0000+")
    testCases(204) = Array(50.409, 7.402, 3510225000, 1535197184, 15, "9F29CC52+JR22222")
    testCases(205) = Array(-88, 30, 50000000, 1720320000, 11, "2G4G2222+222")
    testCases(206) = Array(-98, 139, 0, 2613248000, 10, "2Q2X2222+22")
    testCases(207) = Array(11.4, 150.4, 2535000000, 2706636800, 4, "7R3G0000+")
    testCases(208) = Array(-88.504244, 67.742247, 37393900, 2029504487, 4, "2J390000+")
    testCases(209) = Array(-84.13904, -22.90719, 146524000, 1286904299, 8, "297VV36V+")
    testCases(210) = Array(-12.874997750, -26.081150643, 1928125056, 1260903213, 12, "59VM4WG9+2G52")
    testCases(211) = Array(-95.978240742, 83.957497847, 0, 2162339822, 15, "2M252X24+2X55454")
    testCases(212) = Array(52.797623, 55.332651, 3569940575, 1927845076, 2, "9H000000+")
    testCases(213) = Array(-25.57754103, -60.87933236, 1610561474, 975836509, 15, "576XC4CC+X7M7MXV")
    testCases(214) = Array(57.1960, 82.5535, 3679900000, 2150838272, 14, "9M945HW3+CC2222")
    testCases(215) = Array(-26, 27, 1600000000, 1695744000, 8, "5G692222+")
    testCases(216) = Array(-27.0, -122.3, 1575000000, 472678400, 11, "545V2P22+222")
    testCases(217) = Array(-99.118211, 34.329996, 0, 1755791327, 8, "2G2P282H+")
    testCases(218) = Array(25.33671, 8.65920, 2883417750, 1545496166, 8, "7FQC8MP5+")
    testCases(219) = Array(-77.54, 110.22, 311500000, 2377482240, 11, "2PJGF66C+222")
    testCases(220) = Array(-55.69363663291, -8.13133426255, 857659084, 1407948109, 8, "3CPH8V49+")
    testCases(221) = Array(12.0752578562, 90.0309556122, 2551881446, 2212093588, 15, "7M4G32GJ+4948FV6")
    testCases(222) = Array(-38.11355992107, -14.54083447411, 1297161001, 1355441483, 13, "4CH7VFP5+HMFM2")
    testCases(223) = Array(-67.52, -133.23, 562000000, 383139840, 13, "3448FQJC+22222")
    testCases(224) = Array(-41.5789128, -76.9932090, 1210527180, 843831631, 12, "47C5C2C4+CPMF")
    testCases(225) = Array(63.50396935, 144.75232815, 3837599233, 2660371072, 6, "9RM6GQ00+")
    testCases(226) = Array(-99.10, -77.98, 0, 835747840, 11, "2724222C+222")
    testCases(227) = Array(-13.502, 122.955, 1912450000, 2481807360, 13, "5QR4FXX4+62222")
    testCases(228) = Array(99.595382598, -71.110954356, 4499999999, 892019061, 12, "C7XCXVXQ+XJVV")
    testCases(229) = Array(8.68, 180.22, 2467000000, 1802240, 13, "62W2M6JC+22222")
    testCases(230) = Array(96.0835607732, -29.0019350420, 4499999999, 1236976148, 10, "C9XGXXXX+X6")
    testCases(231) = Array(26.4022965, -31.1647767, 2910057412, 1219258149, 11, "79RCCR2P+W39")
    testCases(232) = Array(80.99, -174.37, 4274750000, 46120960, 4, "C2G70000+")
    testCases(233) = Array(68.0, -35.1, 3950000000, 1187020800, 15, "99W62W22+2222222")
    testCases(234) = Array(82.4789853525, 71.0194066612, 4311974633, 2056350979, 13, "CJJHF2H9+HQVC2")
    testCases(235) = Array(-84.78480, 166.71891, 130380000, 2840321310, 4, "2V780000+")
    testCases(236) = Array(-10.5782, 25.7779, 1985545000, 1685732556, 11, "5GX7CQCH+P5C")
    testCases(237) = Array(-3.91348310257, -109.55392470032, 2152162922, 577094248, 13, "658G3CPW+JC4M8")
    testCases(238) = Array(-55.7416641607, 136.4834168428, 856458395, 2592632150, 11, "3QPR7F5M+89M")
    testCases(239) = Array(-55.80137, 105.59937, 854965750, 2339630039, 2, "3P000000+")
    testCases(240) = Array(70.49, 104.87, 4012250000, 2333655040, 2, "CP000000+")
    testCases(241) = Array(1.6479856942, 181.1761286225, 2291199642, 9634845, 14, "62H3J5XG+5FRC3Q")
    testCases(242) = Array(-94.2098, 53.1707, 0, 1910134374, 14, "2H2M252C+274343")
    testCases(243) = Array(96.6461284508, 37.5309875240, 4499999999, 1782013849, 4, "CGXV0000+")
    testCases(244) = Array(13.403331980, 132.878412474, 2585083299, 2563099954, 13, "7Q5JCV3H+89M69")
    testCases(245) = Array(23.01778459, -75.75490333, 2825444614, 853975831, 10, "77M6269W+42")
    testCases(246) = Array(-48.4381338, 140.8468367, 1039046655, 2628377286, 6, "4R32HR00+")
    testCases(247) = Array(-38.2448857266, -111.9149619865, 1293877856, 557752631, 10, "45HCQ34P+22")
    testCases(248) = Array(-64.0, -94.4, 650000000, 701235200, 4, "36870000+")
    testCases(249) = Array(-47.0346874447, -51.1267770629, 1074132813, 1055729442, 6, "484CXV00+")
    testCases(250) = Array(66.6814, -78.9160, 3917035000, 828080128, 8, "97R3M3JM+")
    testCases(251) = Array(-82.22446, 143.24158, 194388500, 2647995023, 4, "2R950000+")
    testCases(252) = Array(-31.80606, -102.08156, 1454848500, 638307860, 4, "45WV0000+")
    testCases(253) = Array(14.94989456, 96.10671106, 2623747364, 2261866177, 12, "7M6RW4X4+XM4Q")
    testCases(254) = Array(-15.10033816850, 99.53259414053, 1872491545, 2289931011, 11, "5MPXVGXM+V29")
    testCases(255) = Array(-69.4546558690, 97.3697260830, 513633603, 2272212796, 6, "3M2VG900+")
    testCases(256) = Array(47.6915368, -109.0087879, 3442288420, 581560009, 6, "85VGMX00+")
    testCases(257) = Array(99.2751473, 147.8120144, 4499999999, 2685436021, 10, "CRX9XRX6+XR")
    testCases(258) = Array(27.6309, -98.7061, 2940772500, 665959628, 2, "76000000+")
    testCases(259) = Array(27.24379, 92.39247, 2931094750, 2231439114, 12, "7MVJ69VR+GX9J")
    testCases(260) = Array(-79.78071, 133.66290, 255482250, 2569526476, 10, "2QGM6M97+P5")
    testCases(261) = Array(-94.55098016, -95.68553772, 0, 690704074, 11, "26262827+2Q4")
    testCases(262) = Array(-18.100, -83.091, 1797500000, 793878528, 13, "56HRWW25+2J222")
    testCases(263) = Array(-35.015055, 73.717570, 1374623625, 2078454333, 12, "4JPMXPM9+X2GR")
    testCases(264) = Array(-87.7171, 177.5628, 57072500, 2929154457, 13, "2V4V7HM7+54743")
    testCases(265) = Array(56.55872, 54.19708, 3663968000, 1918542479, 11, "9H8PH55W+FRP")
    testCases(266) = Array(-28.6420, 71.2607, 1533950000, 2058327654, 11, "5J3H9756+674")
    testCases(267) = Array(-44.755, 21.329, 1131125000, 1649287168, 10, "4G7368WH+2J")
    testCases(268) = Array(-58.284, 44.435, 792900000, 1838571520, 15, "3HH6PC8P+C222222")
    testCases(269) = Array(13.469, -118.034, 2586725000, 507625472, 11, "7553FX98+JC2")
    testCases(270) = Array(40.615, 173.901, 3265375000, 2899156992, 2, "8V000000+")
    testCases(271) = Array(62, -95, 3800000000, 696320000, 12, "96J72222+2222")
    testCases(272) = Array(-5.2221889, 139.2054401, 2119445277, 2614930965, 4, "6Q6X0000+")
    testCases(273) = Array(-24.8, -7.1, 1630000000, 1416396800, 4, "5C7J0000+")
    testCases(274) = Array(41.5, 0.4, 3287500000, 1477836800, 8, "8FH2GC22+")
    testCases(275) = Array(-58.89638156814, -177.07241353875, 777590460, 23982788, 8, "32H44W3H+")
    testCases(276) = Array(99.9924124, 168.8859945, 4499999999, 2858074066, 13, "CVXCXVXP+X9XXV")
    testCases(277) = Array(-81.83814, 13.38568, 204046500, 1584215490, 10, "2FCM596P+P7")
    testCases(278) = Array(-81.641294, -26.677758, 208967650, 1256015806, 12, "29CM985C+FVQ8")
    testCases(279) = Array(-38.1, -34.8, 1297500000, 1189478400, 6, "49H7W600+")
    testCases(280) = Array(30.760710361, 5.623188694, 3019017759, 1520625161, 12, "8F27QJ6F+77PC")
    testCases(281) = Array(-41, -7, 1225000000, 1417216000, 8, "4CFM2222+")
    testCases(282) = Array(80.2976, 17.4494, 4257440000, 1617505484, 6, "CFGV7C00+")
    testCases(283) = Array(-0.8932, -141.8127, 2227670000, 312830361, 10, "63FW454P+PW")
    testCases(284) = Array(51.1973191264, -176.2844505770, 3529932978, 30437780, 14, "92355PW8+W6FPV3")
    testCases(285) = Array(64.3538, 37.6501, 3858845000, 1782989619, 6, "9GPV9M00+")
    testCases(286) = Array(-7.741571, -114.569063, 2056460725, 536010235, 4, "65470000+")
    testCases(287) = Array(59.668, -73.133, 3741700000, 875454464, 6, "97F8MV00+")
    testCases(288) = Array(72.146589, -166.255204, 4053664725, 112597368, 4, "C24M0000+")
    testCases(289) = Array(45.7536561, -77.9826424, 3393841402, 835726193, 11, "87Q4Q238+FW9")
    testCases(290) = Array(20.59532, 58.43522, 2764883000, 1953261322, 15, "7HGWHCWP+43HR244")
    testCases(291) = Array(-2.22208790893, -129.52868305886, 2194447802, 413461028, 11, "649GQFHC+5G8")
    testCases(292) = Array(21.37734168211, -19.82122122854, 2784433542, 1312184555, 2, "7C000000+")
    testCases(293) = Array(71.0833633113, -21.3584667975, 4027084082, 1299591439, 12, "C93W3JMR+8JVC")
    testCases(294) = Array(48.64, 42.02, 3466000000, 1818787840, 10, "8HW4J2RC+22")
    testCases(295) = Array(2.28, 65.18, 2307000000, 2008514560, 11, "6JJ775JJ+222")
    testCases(296) = Array(66, -15, 3900000000, 1351680000, 14, "9CR72222+222222")
    testCases(297) = Array(82.988994321, -114.039676643, 4324724858, 540346968, 2, "C5000000+")
    testCases(298) = Array(-32.04, -9.54, 1449000000, 1396408320, 11, "4CVGXF66+222")
    testCases(299) = Array(98.43557, -184.42545, 4499999999, 2912866713, 12, "CVXQXHXF+XRVW")
    testCases(300) = Array(71.75744246, -62.00099498, 4043936061, 966647849, 2, "C7000000+")
    testCases(301) = Array(51.089925, 72.339482, 3527248125, 2067165036, 15, "9J3J38QQ+XQH3452")

    loadEncodingTestCSV = testCases
End Function

' Check the degrees to integer conversions.
' Due to floating point precision limitations, we may get values 1 less than expected.
Sub TEST_IntegerConversion()
    Dim encodingTests As Variant
    Dim i As Integer
    Dim tc As Variant
    Dim degrees AS Double
    Dim got_integer As Double
    Dim want_integer As Double

    encodingTests = loadEncodingTestCSV()

    For i = 0 To 301
        tc = encodingTests(i)
        degrees = tc(0)
        want_integer = tc(2)
        got_integer = latitudeToInteger(degrees)
        If got_integer < want_integer - 1 Or got_integer > want_integer Then
            MsgBox ("Encoding test " + CStr(i) + ": latitudeToInteger(" + CStr(degrees) + "): got " + CStr(got_integer) + ", want " + CStr(want_integer))
            Exit Sub
        End If
        degrees = tc(1)
        want_integer = tc(3)
        got_integer = longitudeToInteger(degrees)
        If got_integer < want_integer - 1 Or got_integer > want_integer Then
            MsgBox ("Encoding test " + CStr(i) + ": longitudeToInteger(" + CStr(degrees) + "): got " + CStr(got_integer) + ", want " + CStr(want_integer))
            Exit Sub
        End If
    Next

    MsgBox ("TEST_IntegerConversion passes")
End Sub

' Check the integer encoding.
Sub TEST_IntegerEncoding()
    Dim encodingTests As Variant
    Dim i As Integer
    Dim tc As Variant
    Dim latitude As Double
    Dim longitude As Double
    Dim code_length As Integer
    Dim want_code As String
    Dim got_code As String

    encodingTests = loadEncodingTestCSV()

    For i = 0 To 301
        tc = encodingTests(i)
        ' Latitude and longitude are the integer values, not degrees.
        latitude = tc(2)
        longitude = tc(3)
        code_length = tc(4)
        want_code = tc(5)
        got_code = encodeIntegers(latitude, longitude, code_length)
        If got_code <> want_code Then
            MsgBox ("Encoding test " + CStr(i) + ": encodeIntegers(" + CStr(latitude) + ", " + CStr(longitude) + ", " + CStr(code_length) + "): got " + got_code + ", want " + want_code)
            Exit Sub
        End If
    Next

    MsgBox ("TEST_IntegerEncoding passes")
End Sub
' This is a subroutine to test the functions of the library, using test data
' copied from the Github project. This should be migrated to being generated
' from the CSV files.
Sub TEST_OLCLibrary()
  Dim i As Integer
  Dim c As String
  Dim a As OLCArea

  Dim validity(17) As Variant
  ' Fields code,isValid,isShort,isFull
  validity(0) = Array("8fwc2345+G6", "true", "false", "true")
  validity(1) = Array("8FWC2345+G6G", "true", "false", "true")
  validity(2) = Array("8fwc2345+", "true", "false", "true")
  validity(3) = Array("8FWCX400+", "true", "false", "true")
  validity(4) = Array("WC2345+G6g", "true", "true", "false")
  validity(5) = Array("2345+G6", "true", "true", "false")
  validity(6) = Array("45+G6", "true", "true", "false")
  validity(7) = Array("+G6", "true", "true", "false")
  validity(8) = Array("G+", "false", "false", "false")
  validity(9) = Array("+", "false", "false", "false")
  validity(10) = Array("8FWC2345+G", "false", "false", "false")
  validity(11) = Array("8FWC2_45+G6", "false", "false", "false")
  validity(12) = Array("8FWC2η45+G6", "false", "false", "false")
  validity(13) = Array("8FWC2345+G6+", "false", "false", "false")
  validity(14) = Array("8FWC2300+G6", "false", "false", "false")
  validity(15) = Array("WC2300+G6g", "false", "false", "false")
  validity(16) = Array("WC2345+G", "false", "false", "false")
  For i = 0 To 16
    Dim v, s, f As Boolean
    v = OLCIsValid(validity(i)(0))
    s = OLCIsShort(validity(i)(0))
    f = OLCIsFull(validity(i)(0))
    If v <> (validity(i)(1) = "true") Then
      MsgBox ("IsValid test " + CStr(i) + ", expected: " + CStr(validity(i)(1) = "true") + ", actual: " + CStr(v))
      Exit Sub
    End If
    If s <> (validity(i)(2) = "true") Then
      MsgBox ("IsShort test " + CStr(i) + ", expected: " + CStr(validity(i)(2) = "true") + ", actual: " + CStr(s))
      Exit Sub
    End If
    If f <> (validity(i)(3) = "true") Then
      MsgBox ("IsFull test " + CStr(i) + ", expected: " + CStr(validity(i)(3) = "true") + ", actual: " + CStr(f))
      Exit Sub
    End If
  Next

  Dim shortCodes(11) As Variant
  shortCodes(0) = Array("9C3W9QCJ+2VX", "+2VX")
  shortCodes(1) = Array("9C3W9QCJ+2VX", "CJ+2VX")
  shortCodes(2) = Array("9C3W9QCJ+2VX", "CJ+2VX")
  shortCodes(3) = Array("9C3W9QCJ+2VX", "CJ+2VX")
  shortCodes(4) = Array("9C3W9QCJ+2VX", "CJ+2VX")
  shortCodes(5) = Array("9C3W9QCJ+2VX", "9QCJ+2VX")
  shortCodes(6) = Array("9C3W9QCJ+2VX", "9QCJ+2VX")
  shortCodes(7) = Array("9C3W9QCJ+2VX", "9QCJ+2VX")
  shortCodes(8) = Array("9C3W9QCJ+2VX", "9QCJ+2VX")
  shortCodes(9) = Array("8FJFW222+", "22+")
  shortCodes(10) = Array("796RXG22+", "22+")
  Dim shortCoordinates(11) As Variant
  shortCoordinates(0) = Array(51.3701125, -1.217765625)
  shortCoordinates(1) = Array(51.3708675, -1.217765625)
  shortCoordinates(2) = Array(51.3693575, -1.217765625)
  shortCoordinates(3) = Array(51.3701125, -1.218520625)
  shortCoordinates(4) = Array(51.3701125, -1.217010625)
  shortCoordinates(5) = Array(51.3852125, -1.217765625)
  shortCoordinates(6) = Array(51.3550125, -1.217765625)
  shortCoordinates(7) = Array(51.3701125, -1.232865625)
  shortCoordinates(8) = Array(51.3701125, -1.202665625)
  shortCoordinates(9) = Array(42.899, 9.012)
  shortCoordinates(10) = Array(14.95125, -23.5001)
  For i = 0 To 10
    c = OLCShorten(shortCodes(i)(0), shortCoordinates(i)(0), shortCoordinates(i)(1))
    If c <> shortCodes(i)(1) Then
      MsgBox ("Shorten test " + CStr(i) + ", expected: " + shortCodes(i)(1) + ", actual: " + c)
      Exit Sub
    End If
    c = OLCRecoverNearest(shortCodes(i)(1), shortCoordinates(i)(0), shortCoordinates(i)(1))
    If c <> shortCodes(i)(0) Then
      MsgBox ("Recover test " + CStr(i) + ", expected: " + shortCodes(i)(0) + ", actual: " + c)
      Exit Sub
    End If
  Next

  ' North pole recovery test.
  c = OLCRecoverNearest("2222+22", 89.6, 0.0)
  If c <> "CFX22222+22" Then
    MsgBox ("North pole recovery test, expected: CFX22222+22, actual: " + c)
    Exit Sub
  End If
  ' South pole recovery test.
  c = OLCRecoverNearest("XXXXXX+XX", -81.0, 0.0)
  If c <> "2CXXXXXX+XX" Then
    MsgBox ("South pole recovery test, expected: 2CXXXXXX+XX, actual: " + c)
    Exit Sub
  End If

  MsgBox ("TEST_OLCLibrary passes")
End Sub

Sub TEST_All()
    TEST_OLCLibrary

    TEST_IntegerConversion
    TEST_IntegerEncoding
End Sub
