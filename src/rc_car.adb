------------------------------------------------------------------------------
--                                                                          --
--                   Copyright (C) 2018-2020, AdaCore                       --
--                                                                          --
--  Redistribution and use in source and binary forms, with or without      --
--  modification, are permitted provided that the following conditions are  --
--  met:                                                                    --
--     1. Redistributions of source code must retain the above copyright    --
--        notice, this list of conditions and the following disclaimer.     --
--     2. Redistributions in binary form must reproduce the above copyright --
--        notice, this list of conditions and the following disclaimer in   --
--        the documentation and/or other materials provided with the        --
--        distribution.                                                     --
--     3. Neither the name of STMicroelectronics nor the names of its       --
--        contributors may be used to endorse or promote products derived   --
--        from this software without specific prior written permission.     --
--                                                                          --
--   THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS    --
--   "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT      --
--   LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR  --
--   A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT   --
--   HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, --
--   SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT       --
--   LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,  --
--   DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY  --
--   THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT    --
--   (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE  --
--   OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.   --
--                                                                          --
------------------------------------------------------------------------------

--  This program, and the physical car itself, are based on the HiTechnic IR
--  RC Car, with several significant differences. Not least is the fact that no
--  LEGO NXT brick is used, requiring a "cage" to hold the selected MCU card and
--  a place to put the battery.
--
--  Instructions for building their original car are here:
--  http://www.hitechnic.com/models
--
--  A video of their car is available on YouTube:
--  https://www.youtube.com/watch?v=KltnZBSvLu4

--  The computer replacing the Lego Brick is a 32-bit ARM Cortex-M4 MCU on the
--  STM32F4 Discovery card by STMicroelectronics. An FPU is included so we use
--  floating-point in the program.
--
--  https://www.st.com/en/evaluation-tools/stm32f4discovery.html

--  In addition, we use a third-party hardware card known as the NXT_Shield to
--  interface to the NXT motors and sonar scanner. Specifically, we use "NXT
--  Shield Version 2" produced by TKJ Electronics.
--
--  http://blog.tkjelectronics.dk/2011/10/nxt-shield-ver2/
--  http://shop.tkjelectronics.dk/product_info.php?products_id=29

--  We use a battery that provides separate connections for +5 and +9 (or +12)
--  volts. The 5V is provided via USB connector, which is precisely what the
--  STM32F4 card requires for power. It isn't light but holds a charge for a
--  long time. The battery is the "XTPower AE-MP-10000-External-Battery" pack.
--
--  https://www.xtpower.com/

--  Available remote controls:
--
--      Power_Functions_IR_TX_8879
--      see https://www.lego.com/en-us/themes/power-functions/products/ir-speed-remote-control-8879
--
--      AdaFruit app on cell phone, using BLE for the connection
--      see https://learn.adafruit.com/bluefruit-le-connect/controller
--
--
--  The AdaFruit remote app uses a Bluetooth connection from the iPhone or
--  Android mobile phone. The other two remotes use IR, so for those we use the
--  HiTechnic IR receiver. If the AdaFruit BLE is used we must swap out the IR
--  receiver for the Bluefruit LE UART Friend receiver.
--
--  There is one package declaration for the remote control interface. Each
--  different remote control device above has a corresponding package body
--  implementing the single shared package spec. To have the selected remote be
--  used in the RC_Car program you must build the program with the package body
--  corresponding to the desired controller. This selection is accomplished via
--  the "Remote_Control" scenario variable.
--
--  See the package bodies for how to use the corresponding remote controls.

with Last_Chance_Handler;  pragma Unreferenced (Last_Chance_Handler);
with Engine_Control;       pragma Unreferenced (Engine_Control);
with Steering_Control;     pragma Unreferenced (Steering_Control);
with Remote_Control;       pragma Unreferenced (Remote_Control);
with Vehicle;
with Global_Initialization;
with System_Configuration;
with STM32.Board;
with Ada.Real_Time;

procedure RC_Car is
   pragma Priority (System_Configuration.Main_Priority);
begin
   STM32.Board.Initialize_LEDs;
   --  do the above first

   Vehicle.Initialize;

   --  Allow the tasks to start doing their post-initialization work, ie the
   --  epoch starts for their periodic loops with the value passed
   Global_Initialization.Critical_Instant.Signal (Epoch => Ada.Real_Time.Clock);

   loop
      delay until Ada.Real_Time.Time_Last;
   end loop;
end RC_Car;
