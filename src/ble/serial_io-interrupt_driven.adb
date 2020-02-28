------------------------------------------------------------------------------
--                                                                          --
--                    Copyright (C) 2015-2018, AdaCore                      --
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

package body Serial_IO.Interrupt_Driven is

   ---------
   -- Put --
   ---------

   overriding
   procedure Put (This : in out Serial_Port;  Data : Character) is
   begin
      This.Controller.Put (Data);
   end Put;

   ---------
   -- Get --
   ---------

   overriding
   procedure Get (This : in out Serial_Port;  Data : out Character) is
   begin
      Enable_Interrupts (This.Transceiver.all, Received_Data_Not_Empty);
      This.Controller.Get (Data);
   end Get;

   ----------------
   -- IO_Manager --
   ----------------

   protected body IO_Manager is

      -------------------------
      -- Handle_Transmission --
      -------------------------

      procedure Handle_Transmission is
      begin
         Serial_IO.Put (Serial_IO.Device (Port.all), Outgoing);
         Disable_Interrupts (Port.Transceiver.all, Source => Transmission_Complete);
      end Handle_Transmission;

      ----------------------
      -- Handle_Reception --
      ----------------------

      procedure Handle_Reception is
      begin
         Serial_IO.Get (Serial_IO.Device (Port.all), Incoming);
         loop
            exit when not Status (Port.Transceiver.all, Read_Data_Register_Not_Empty);
         end loop;
         Disable_Interrupts (Port.Transceiver.all, Source => Received_Data_Not_Empty);
      end Handle_Reception;

      -----------------
      -- IRQ_Handler --
      -----------------

      procedure IRQ_Handler is
      begin
         --  check for data arrival
         if Status (Port.Transceiver.all, Read_Data_Register_Not_Empty) and
            Interrupt_Enabled (Port.Transceiver.all, Received_Data_Not_Empty)
         then
            Handle_Reception;
            Clear_Status (Port.Transceiver.all, Read_Data_Register_Not_Empty);
            Incoming_Data_Available := True;
         end if;

         --  check for transmission ready
         if Status (Port.Transceiver.all, Transmission_Complete_Indicated) and
            Interrupt_Enabled (Port.Transceiver.all, Transmission_Complete)
         then
            Handle_Transmission;
            Clear_Status (Port.Transceiver.all, Transmission_Complete_Indicated);
            Transmission_Pending := False;
         end if;
      end IRQ_Handler;

      ---------
      -- Put --
      ---------

      entry Put (Datum : Character) when not Transmission_Pending is
      begin
         Transmission_Pending := True;
         Outgoing := Datum;
         Enable_Interrupts (Port.Transceiver.all, Transmission_Complete);
      end Put;

      ---------
      -- Get --
      ---------

      entry Get (Datum : out Character) when Incoming_Data_Available is
      begin
         Datum := Incoming;
         Incoming_Data_Available := False;
      end Get;

   end IO_Manager;

end Serial_IO.Interrupt_Driven;
