------------------------------------------------------------------------------
--                                                                          --
--                     Copyright (C) 2015-2016, AdaCore                     --
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
--     3. Neither the name of the copyright holder nor the names of its     --
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

with STM32.Device; use STM32.Device;

with HAL;

package body Serial_IO is

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize
     (This           : in out Device;
      Transceiver    : not null access USART;
      Transceiver_AF : GPIO_Alternate_Function;
      Tx_Pin         : GPIO_Point;
      Rx_Pin         : GPIO_Point;
      CTS_Pin        : GPIO_Point;
      RTS_Pin        : GPIO_Point)
   is
      Configuration : GPIO_Port_Configuration;
      IO_Pins       : constant GPIO_Points := Rx_Pin & Tx_Pin;
   begin
      This.Transceiver := Transceiver;
      This.Tx_Pin := Tx_Pin;
      This.Rx_Pin := Rx_Pin;
      This.CTS_Pin := CTS_Pin;
      This.RTS_Pin := RTS_Pin;

      Enable_Clock (Transceiver.all);

      Enable_Clock (IO_Pins);

      Configuration := (Mode_AF,
                        AF             => Transceiver_AF,
                        AF_Speed       => Speed_50MHz,
                        AF_Output_Type => Push_Pull,
                        Resistors      => Pull_Up);

      Configure_IO (IO_Pins, Configuration);

      Enable_Clock (RTS_Pin & CTS_Pin);

      Configuration := (Mode_In, Resistors => Pull_Up);
      Configure_IO (RTS_Pin, Configuration);

      Configuration := (Mode_Out,
                        Speed       => Speed_50MHz,
                        Output_Type => Push_Pull,
                        Resistors   => Pull_Up);

      Configure_IO (CTS_Pin, Configuration);
   end Initialize;

   ---------------
   -- Configure --
   ---------------

   procedure Configure
     (This      : in out Device;
      Baud_Rate : Baud_Rates;
      Parity    : Parities     := No_Parity;
      Data_Bits : Word_Lengths := Word_Length_8;
      End_Bits  : Stop_Bits    := Stopbits_1;
      Control   : Flow_Control := No_Flow_Control)
   is
   begin
      Disable (This.Transceiver.all);

      Set_Baud_Rate    (This.Transceiver.all, Baud_Rate);
      Set_Mode         (This.Transceiver.all, Tx_Rx_Mode);
      Set_Stop_Bits    (This.Transceiver.all, End_Bits);
      Set_Word_Length  (This.Transceiver.all, Data_Bits);
      Set_Parity       (This.Transceiver.all, Parity);
      Set_Flow_Control (This.Transceiver.all, Control);

      Enable (This.Transceiver.all);
   end Configure;

   -------------
   -- Set_CTS --
   -------------

   procedure Set_CTS (This : in out Device; Value : Boolean) is
   begin
      This.CTS_Pin.Drive (Value);
   end Set_CTS;

   -------------
   -- Set_RTS --
   -------------

   procedure Set_RTS (This : in out Device; Value : Boolean) is
   begin
      This.RTS_Pin.Drive (Value);
   end Set_RTS;

   ---------
   -- Put --
   ---------

   procedure Put (This : in out Device;  Data : Character) is
   begin
      Transmit (This.Transceiver.all, Character'Pos (Data));
   end Put;

   ---------
   -- Get --
   ---------

   procedure Get (This : in out Device;  Data : out Character) is
      Received : HAL.UInt9;
   begin
      Receive (This.Transceiver.all, Received);
      Data := Character'Val (Received);
   end Get;

end Serial_IO;
