------------------------------------------------------------------------------
--                                                                          --
--                      Copyright (C) 2018, AdaCore                         --
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

--  This package declares all the hardware devices and related values on the
--  STM32 board actually used by the application. The purpose is to specify
--  them all in one place, so that changes and/or additions can be checked
--  easily for conflicts.

--  There are multiple versions of this package, depending on the remote
--  receiver communication hardware. For example, there is one package for
--  IR receivers and one for BLE. This is the package for the IR receiver.

--  Only the remote receiver connections vary among the versions of this
--  package, suggesting that the other values should be in a single, separate
--  package to avoid duplication and thus potential inconsistencies over time.
--  However, the ability to check for device and GPIO conflicts is so valuable
--  as to override the desire to avoid uplication.

with STM32;        use STM32;
with STM32.GPIO;   use STM32.GPIO;
with STM32.Timers; use STM32.Timers;
with STM32.Device; use STM32.Device;

with Ada.Interrupts.Names;  use Ada.Interrupts.Names;
with STM32.USARTs;          use STM32.USARTs;

package Hardware_Configuration is

   --  The hardware on the STM32 board used by the Ultrasonic Sonar sensor (on
   --  the NXT_Shield)

   Sonar_Clock_Frequency : constant := 9600;
   Sonar_Clock_Pin       : GPIO_Point renames PB13;  -- SCL
   Sonar_Data_Pin        : GPIO_Point renames PB11;  -- SDA
   --  The choice of pins is largely arbitrary because we are bit-banging the
   --  I/O instead of using an ob-board I2C device. Nonetheless, the internal
   --  pull-up resistor values are not the same across all pins. Specifically,
   --  PB10 and PB12 have approximately 11K pull-up resistors, whereas the
   --  other pins have approximately 40K pull-up resistors. See table 47
   --  "I/O Static Characteristics" in the STM32F405xx STM32F407xx Datasheet.

   --  The hardware on the STM32 board used by the two motors (on the
   --  NXT_Shield)

   Motor_PWM_Frequency : constant := 490;

   Motor1_Encoder_Input1     : GPIO_Point renames PA15;
   Motor1_Encoder_Input2     : GPIO_Point renames PB3;
   Motor1_Encoder_Timer      : constant access Timer := Timer_2'Access;
   Motor1_Encoder_AF         : constant STM32.GPIO_Alternate_Function := GPIO_AF_TIM2_1;
   Motor1_PWM_Timer          : constant access Timer := Timer_4'Access;
   Motor1_PWM_AF             : constant STM32.GPIO_Alternate_Function := GPIO_AF_TIM4_2;
   Motor1_PWM_Output         : GPIO_Point renames PB6;
   Motor1_PWM_Output_Channel : constant Timer_Channel := Channel_1;
   Motor1_Polarity1          : GPIO_Point renames PA10;
   Motor1_Polarity2          : GPIO_Point renames PB1;

   Motor2_Encoder_Input1     : GPIO_Point renames PA0;
   Motor2_Encoder_Input2     : GPIO_Point renames PA1;
   Motor2_Encoder_Timer      : constant access Timer := Timer_5'Access;
   Motor2_Encoder_AF         : constant STM32.GPIO_Alternate_Function := GPIO_AF_TIM5_2;
   Motor2_PWM_Timer          : constant access Timer := Timer_3'Access;
   Motor2_PWM_AF             : constant STM32.GPIO_Alternate_Function := GPIO_AF_TIM3_2;
   Motor2_PWM_Output         : GPIO_Point renames PB4;
   Motor2_PWM_Output_Channel : constant Timer_Channel := Channel_1;
   Motor2_Polarity1          : GPIO_Point renames PA2;
   Motor2_Polarity2          : GPIO_Point renames PA3;

   --  The hardware used by the remote control AdaFruit BLE USART breakout board

   BLE_UART_MOD_Pin : GPIO_Point renames PD0;
   BLE_UART_CTS_Pin : GPIO_Point renames PD3;
   BLE_UART_RTS_Pin : GPIO_Point renames PD4;
   BLE_UART_Tx_Pin  : GPIO_Point renames PD5;  -- RXI pin on breakout board
   BLE_UART_Rx_Pin  : GPIO_Point renames PD6;  -- TXO pin on breakout board

   BLE_UART_Transceiver     : constant access USART := USART_2'Access;
   BLE_UART_Transceiver_AF  : constant STM32.GPIO_Alternate_Function := GPIO_AF_USART2_7;
   BLE_UART_Transceiver_IRQ : constant Ada.Interrupts.Interrupt_ID := USART2_Interrupt;

end Hardware_Configuration;
