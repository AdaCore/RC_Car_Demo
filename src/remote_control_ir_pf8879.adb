--  This package body implements the remote control package spec using a Lego
--  infrared receiver and a specific IR control pad using a matching IR
--  transmitter. The control pad is a Lego Power Functions 8879 with two
--  rotary switches, two red buttons (used for stopping), and various other
--  switches.

--  This remote provides 7 positive and 7 negative non-zero input values per
--  rotary switch, plus zero itself. The absolute values are 0, 16, 30, 44, 58,
--  72, 86, and 100. Continuing to turn either switch past the point that it
--  presents a max value of 100 has no effect. The software below smooths those
--  direcrete values out somewhat, in a mostly arbitrary manner.

--  see https://www.lego.com/en-us/themes/power-functions/products/ir-speed-remote-control-8879

--  NOTE THAT THE ROTARY SWITCHES DO NOT GO BACK TO ZERO WHEN RELEASED, THEY
--  MUST BE MANUALLY DIALED BACK DOWN. That's just the way the remote works.
--  The car will require this re-zeroing to be done manually, on startup, if the
--  switches are not at zero when starting. In this case the blue LED will be
--  lit when the steering switch is non-zero, and the red LED will be lit when
--  the power switch is non-zero. One or both may be lit.

--  The rotary switch on the right is for controlling the engine, ie the motion
--  of the vehicle itself. Turning it to the right will cause the vehicle to
--  go forward, to the left will cause backward travel. The speed will increase
--  as the switch is turned further in the same direction. Speed will decrease
--  if the switch is turned in the opposite direction, and will continue
--  to decrease until it goes to zero and then starts going in the oposite
--  direction entirely.

--  The rotary switch on the left controls the steering direction. Turning to
--  the right steers the vehicle to the right, the reverse for turning to the
--  left. The switch behaves like the engine power switch on the right, in
--  that turning in the opposite direction reduces the degree of turn currently
--  applied.

--  Pressing the red button below the switch on the right will cause the vehicle
--  to stop immediately. Although the car will stop, the controls will not go to
--  zero on the remote automatically. Therefore the on-board program will force
--  the user to manually zero them before resuming, as described above.

--  In addition to connections for power (+5V) and ground, the HiTechnic IR
--  receiver also has connections at PB8 (yellow wire) and PB9 (green wire).

with Global_Initialization;
with Ada.Real_Time;          use Ada.Real_Time;
with STM32.Board;            use STM32.Board;
with HAL;                    use HAL;
with Hardware_Configuration;
with HiTechnic.IR_Receivers; use HiTechnic.IR_Receivers;
with NXT.Digital;            use NXT.Digital;

package body Remote_Control
  with SPARK_Mode
is

   IR_Sensor_Address : constant I2C_Device_Address := 1;  --  unshifted!

   Receiver : IR_Receiver (Device_Hardware_Address => IR_Sensor_Address);
   --  The HiTechnic sensor receiving data from the LEGO IR remote

   Steering_LED : User_LED renames Orange_LED;  -- arbitrary
   Engine_LED   : User_LED renames Blue_LED;    -- arbitrary

   Brake_Button_Pushed : constant := -128;
   --  For the right-hand side red button on the PF8879 Remote Control.

   Period : constant Time_Span := Milliseconds (System_Configuration.Remote_Control_Period);

   Initial_Steering_Angle : constant := 0;

   procedure Zero_Remote_Rotary_Switches;
   --  Interact with human driver so that the 8879 rotary inputs are at the zero
   --  position. On this remote, the left and right switches used for steering
   --  and power control will be at whatever value they were when the remote
   --  was last used. The control software must not use those inputs because the
   --  car could immediately turn and move unexpectedly, instead of being still.
   --  There is no physical indicator on the remote to show what position they
   --  are in, so the user cannot simply dial back to zero before powering up
   --  the car. Thus we blink the two LEDs until the received inputs are zero.

   procedure Initialize;
   --  init the hardware

   procedure Receive
     (Requested_Power     : in out Percentage;
      Requested_Direction : in out Travel_Directions;
      Emergency_Braking   : in out Boolean;
      Requested_Steering  : in out Integer);
   --  Get the requested control values from the IR Receiver sensor

   --  This remote provides 7 positive and 7 negative non-zero input values per
   --  rotary switch, plus zero itself. The absolute values are 0, 16, 30, 44,
   --  58, 72, 86, and 100.

   function Mapped_Angle (Requested : Integer) return Integer;
   --  Map the the non-continuous steering inputs from the remote to smoothed
   --  turn angles

   function Mapped_Power (Requested : Percentage) return Percentage;
   --  Map the non-continuous power inputs received from the remote to smoothed
   --  power settings

   Current_Steering_Target : Integer := Initial_Steering_Angle with
      Atomic, Async_Readers, Async_Writers;

   Current_Vector : Travel_Vector := Travel_Vector'(0, Forward, Emergency_Braking => False) with
      Atomic, Async_Readers, Async_Writers;

   Temp : Travel_Vector;

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
      Next_Release        : Time;
      Requested_Steering  : Integer := 0;
      Requested_Power     : Percentage := 0;
      Requested_Direction : Travel_Directions := Forward;
      Requested_Braking   : Boolean := False;
   begin
      Global_Initialization.Critical_Instant.Wait (Epoch => Next_Release);
      loop
         Receive (Requested_Power,
                  Requested_Direction,
                  Requested_Braking,
                  Requested_Steering);

         Current_Steering_Target := Mapped_Angle (Requested_Steering);

         Temp.Power := Mapped_Power (Requested_Power);
         Temp.Direction := Requested_Direction;
         Temp.Emergency_Braking := Requested_Braking;
         Current_Vector := Temp;

         if Requested_Braking then
            --  The car will come to an immediate stop as a result of the
            --  braking but the controls will not go to zero on the remote.
            --  Therefore we must wait for the user to manually zero them
            --  before resuming.
            Zero_Remote_Rotary_Switches;
         end if;

         Next_Release := Next_Release + Period;
         delay until Next_Release;
      end loop;
   end Pump;

   -------------
   -- Receive --
   -------------

   procedure Receive
     (Requested_Power     : in out Percentage;
      Requested_Direction : in out Travel_Directions;
      Emergency_Braking   : in out Boolean;
      Requested_Steering  : in out Integer)
   is
      Switches          : Raw_Sensor_Data;
      Steering_Switches : Raw_Sensor_Values renames Switches.A;
      Engine_Switches   : Raw_Sensor_Values renames Switches.B;
      IO_Successful     : Boolean;
      Power             : Integer;
   begin
      Receiver.Get_Raw_Data (Switches, IO_Successful);
      if not IO_Successful then
         Blue_LED.Set;
         Emergency_Braking := True;
         return;
      end if;

      --  Compute the engine power. Only one of Engine_Switches will be nonzero
      --  (assuming only one control used) so we can simpy add them all up without
      --  trying to find which one it is.
      Power := Integer (Engine_Switches (1)) +
               Integer (Engine_Switches (2)) +
               Integer (Engine_Switches (3)) +
               Integer (Engine_Switches (4));

      Emergency_Braking := False;
      Requested_Direction := Neither;
      if Power = Brake_Button_Pushed then
         Emergency_Braking := True;
         return;
      elsif Power > 0 then
         Requested_Direction := Forward;
      elsif Power < 0 then
         Requested_Direction := Backward;
         Power := -Power;  -- hence power is positive
      end if;
      Requested_Power := Integer'Min (100, Power);

      --  Compute the steering target angle. Only one of Steering_Switches will
      --  be nonzero (assuming only one control used).
      Requested_Steering := Integer (Steering_Switches (1)) +
                            Integer (Steering_Switches (2)) +
                            Integer (Steering_Switches (3)) +
                            Integer (Steering_Switches (4));
   end Receive;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize is
      pragma SPARK_Mode (Off);
      use Hardware_Configuration;
   begin
      Receiver.Configure
        (Port        => Receiver_I2C_Port,
         SCL         => Receiver_I2C_Clock_Pin,
         SDA         => Receiver_I2C_Data_Pin,
         AF_Code     => Receiver_I2C_Port_AF,
         Clock_Speed => Lego_NXT_I2C_Frequency);

      Zero_Remote_Rotary_Switches;
   end Initialize;

   ------------------
   -- Mapped_Angle --
   ------------------

   function Mapped_Angle (Requested : Integer) return Integer is
      Negative : constant Boolean := Requested < 0;
      Result   : Integer;
   begin
      --  Map the received steering angle from the remote to a smoother set of
      --  values. These Result values are arbitrary but intended to make the
      --  steering responsive. Note that the steering control computer will
      --  limit the input to whatever maximum angle is physically possible.
      case abs (Requested) is
         when   0 => Result := 0;
         when  16 => Result := 5;
         when  30 => Result := 9;
         when  44 => Result := 15;
         when  58 => Result := 20;
         when  72 => Result := 25;
         when  86 => Result := 30;
         when 100 => Result := 40;
         when others =>
            --  shouldn't be possible, but don't trust the hardware...
            Result := 0;
      end case;
      Result := (if Negative then -Result else Result);
      return Result;
   end Mapped_Angle;

   ------------------
   -- Mapped_Power --
   ------------------

   function Mapped_Power (Requested : Percentage) return Percentage is
      Result : Percentage;
   begin
      --  Map the received power selection from the remote to a smoother set of
      --  values.
      case Requested is
         when   0 => Result := 0;
         when  16 => Result := 30;
         when  30 => Result := 40;
         when  44 => Result := 50;
         when  58 => Result := 60;
         when  72 => Result := 70;
         when  86 => Result := 80;
         when 100 => Result := 100;
         when others =>
            --  shouldn't happen, but don't trust the hardware...
            Result := 0;
      end case;
      return Result;
   end Mapped_Power;

   ---------------------------------
   -- Zero_Remote_Rotary_Switches --
   ---------------------------------

   procedure Zero_Remote_Rotary_Switches is
      Switches          : Raw_Sensor_Data;
      Steering_Switches : Raw_Sensor_Values renames Switches.A;
      Engine_Switches   : Raw_Sensor_Values renames Switches.B;

      IO_Successful     : Boolean;
      IO_Failure_Count  : Natural := 0;
      Max_IO_Failures   : constant := 5; -- arbitrary

      Steering_Input    : Integer;
      Power_Input       : Integer;

      Blink_Rate        : constant Time_Span := Milliseconds (200); -- arbitrary
      Next_Release      : Time;
   begin
      All_LEDs_Off;
      Next_Release := Clock;
      loop
         Receiver.Get_Raw_Data (Switches, IO_Successful);
         if not IO_Successful then
            IO_Failure_Count := IO_Failure_Count + 1;
            if IO_Failure_Count = Max_IO_Failures then
               raise Program_Error with "IR sensor failure";
            end if;
         else
            --  The user rotates the switches until they both reach the zero
            --  points. We don't care which channel the user is using, so we
            --  just add them up.
            Power_Input := Integer (Engine_Switches (1)) +
                           Integer (Engine_Switches (2)) +
                           Integer (Engine_Switches (3)) +
                           Integer (Engine_Switches (4));

            Steering_Input := Integer (Steering_Switches (1)) +
                              Integer (Steering_Switches (2)) +
                              Integer (Steering_Switches (3)) +
                              Integer (Steering_Switches (4));

            --  indicate to the user which switches need to go to zero
            if Steering_Input /= 0 then
               Steering_LED.Set;
            else
               Steering_LED.Clear;
            end if;
            if Power_Input /= 0 then
               Engine_LED.Set;
            else
               Engine_LED.Clear;
            end if;
         end if;

         exit when Steering_Input = 0 and Power_Input = 0;

         Next_Release := Next_Release + Blink_Rate;
         delay until Next_Release;
      end loop;
   end Zero_Remote_Rotary_Switches;

begin
   Initialize;
end Remote_Control;
