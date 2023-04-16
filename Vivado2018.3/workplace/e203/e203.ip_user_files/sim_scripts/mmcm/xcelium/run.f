-makelib xcelium_lib/xil_defaultlib -sv \
  "D:/Vivado2018.3/Vivado/2018.3/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
-endlib
-makelib xcelium_lib/xpm \
  "D:/Vivado2018.3/Vivado/2018.3/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  "../../../../e203.srcs/sources_1/ip/mmcm/mmcm_clk_wiz.v" \
  "../../../../e203.srcs/sources_1/ip/mmcm/mmcm.v" \
-endlib
-makelib xcelium_lib/xil_defaultlib \
  glbl.v
-endlib

