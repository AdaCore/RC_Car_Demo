--  This package body implements the remote control package spec using a
--  Bluetooth LE (BLE) breakout board sold by AdaFruit for the communication
--  medium. The controller is a free app also produced by AdaFruit, available
--  for both Android and iOS. The app is named "Bluefruit" since it uses a BLE
--  connection.
--
--  To use the AdaFruit app as controller, follow these steps *in the order
--  shown* below:
--
--  1) First power up the RC car itself
--
--  2) Rotate your cellphone so that the major axis is in landscape
--  orientation. You must do this before you connect to the BLE device on the
--  car. This order is necessary because we are using data sent
--  from the app, reflecting the phone's orientation, and we don't want the
--  rotation to landscape mode to be included in the state.
--
--  3) Start the app and connect to the "Adafruit Bluefruit LE" board listed in
--  the app window. There may be other devices discovered and listed as well,
--  but don't use those.
--
--  4) Select the "Controller" option in the app.
--
--  5) Slide the control to enable the Accelerometer data. A little window will
--  appear, showing the values. These values are now being sent from the phone to the
--  car. The car is interpreting these values as speed/direction controls.
--
--  6) Rotate the phone like you're driving with a steering wheel. The car's
--  wheels should turn in response to these rotations.
--
--  7) Tip the phone forward or backward to make the wheels run forward or
--  backward. The speed is proportional to the angle tipped.

with Global_Initialization;
with Ada.Real_Time;              use Ada.Real_Time;
with HAL;                        use HAL;
with Hardware_Configuration;     use Hardware_Configuration;
with Serial_IO.Interrupt_Driven; use Serial_IO.Interrupt_Driven;
with BlueFruit_LE_Friend_USART;  use BlueFruit_LE_Friend_USART;
with AdaFruit.BLE_Msg_Utils;     use AdaFruit.BLE_Msg_Utils;

package body Remote_Control
  with SPARK_Mode
is

   BLE_Port : aliased Serial_Port (BLE_UART_Transceiver_IRQ);

   BLE : Bluefruit_LE_Transceiver (BLE_Port'Access);

   Period : constant Time_Span := Milliseconds (System_Configuration.Remote_Control_Period);

   Current_Vector : Travel_Vector := (0, Forward, Emergency_Braking => False) with
      Atomic, Async_Readers, Async_Writers;

   Temp_Vector : Travel_Vector;

   Current_Steering_Target : Integer := 0 with
     Atomic, Async_Readers, Async_Writers;

   Temp_Target : Integer;

   procedure Initialize;
   --  initialize the BLE receiver

   procedure Receive
     (Requested_Vector   : out Travel_Vector;
      Requested_Steering : out Integer);
   --  Get the requested control values from the input device

   ----------------------
   -- Requested_Vector --
   ----------------------

   function Requested_Vector return Travel_Vector is
   begin
      return Current_Vector;
   end Requested_Vector;

   ------------------------------
   -- Requested_Steering_Angle --
   ------------------------------

   function Requested_Steering_Angle return Integer is
   begin
      return Current_Steering_Target;
   end Requested_Steering_Angle;

   ----------
   -- Pump --
   ----------

   task body Pump is
      Next_Release : Time;
   begin
      Global_Initialization.Critical_Instant.Wait (Epoch => Next_Release);
      loop
         Receive (Temp_Vector, Temp_Target);
         Current_Vector := Temp_Vector;
         Current_Steering_Target := Temp_Target;
         Next_Release := Next_Release + Period;
         delay until Next_Release;
      end loop;
   end Pump;

   -----------------------
   -- Parse_App_Message --
   -----------------------

   procedure Parse_App_Message is
     new Parse_AdaFruit_Controller_Message (Payload => Three_Axes_Data);

   -------------
   -- Receive --
   -------------

   procedure Receive
     (Requested_Vector   : out Travel_Vector;
      Requested_Steering : out Integer)
   is
      Buffer_Size        : constant := 2 * Accelerometer_Msg_Length;
      --  Buffer size is arbitrary but should be bigger than just one message
      --  length. An integer multiple of that message length is a good idea.
      --  The issue is that we will be receiving a continuous stream of such
      --  messages from the phone, and we will not necessarily start receiving
      --  just as a new message arrives. We might instead receive a partial
      --  message at the beginning of the buffer. Thus when parsing we look for
      --  the start of the message, but the point is that we need a big enough
      --  buffer to handle at least one message and a partial message too. We
      --  don't want the buffer size to be too big, though.
      Buffer             : String (1 .. Buffer_Size);
      TAD                : Three_Axes_Data;
      Successful_Parse   : Boolean;
      Power              : Integer;
   begin
      BLE.Get (Buffer);
      Parse_App_Message (Buffer, Accelerometer_Msg, TAD, Successful_Parse);
      if not Successful_Parse then
         Requested_Vector.Emergency_Braking := True;
         Requested_Vector.Power := 0;
         Requested_Steering := 0;
         return;
      end if;

      Requested_Steering := Integer (TAD.Y * 100.0);
      Power := Integer (-TAD.X * 100.0);

      if Power > 0 then
         Requested_Vector.Direction := Forward;
      elsif Power < 0 then
         Requested_Vector.Direction := Backward;
         Power := -Power;  -- hence is positive
      else -- zero
         Requested_Vector.Direction := Neither;
      end if;

      Requested_Vector.Power := Integer'Min (100, Power);
      --  we don't have a way to signal Emergency braking with the phone...
   end Receive;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      BLE_Friend_Baudrate : constant := 9600;
   begin
      BLE_Port.Initialize
        (Transceiver    => BLE_UART_Transceiver,
         Transceiver_AF => BLE_UART_Transceiver_AF,
         Tx_Pin         => BLE_UART_TXO_Pin,
         Rx_Pin         => BLE_UART_RXI_Pin,
         CTS_Pin        => BLE_UART_CTS_Pin,
         RTS_Pin        => BLE_UART_RTS_Pin);

      BLE_Port.Configure (Baud_Rate => BLE_Friend_Baudrate);
      BLE_Port.Set_CTS (False); -- essential!!

      BLE.Configure (Mode_Pin => BLE_UART_MOD_Pin);
      BLE.Set_Mode (Data);
   end Initialize;

begin
   --  initialize the BLE port for receiving messages
   Initialize;
end Remote_Control;
