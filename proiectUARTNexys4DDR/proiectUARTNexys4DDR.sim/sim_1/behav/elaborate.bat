@echo off
set xv_path=C:\\Xilinx\\Vivado\\2016.4\\bin
call %xv_path%/xelab  -wto 703813088037464fbc6341ca569b479b -m64 --debug typical --relax --mt 2 -L xil_defaultlib -L secureip --snapshot rx_fsm_tb_behav xil_defaultlib.rx_fsm_tb -log elaborate.log
if "%errorlevel%"=="0" goto SUCCESS
if "%errorlevel%"=="1" goto END
:END
exit 1
:SUCCESS
exit 0
