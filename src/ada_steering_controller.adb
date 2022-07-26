with Steering_Control;
with Vehicle;

package body Ada_Steering_Controller with
   SPARK_Mode
is
   --  steering PID gain constants
   Kp : constant := 6.0;
   Ki : constant := 5.0;
   Kd : constant := 0.1;

   Power_Level_Last : constant Float := Float (Power_Level'Last);

   Power_Level_Limits : constant Closed_Loop.Bounds :=
      (Min => -Power_Level_Last, Max => +Power_Level_Last);
   --  The limits for the PID controller output power values, based on the
   --  NXT motor's largest power value. The NXT Power_Level type is an integer
   --  ranging from 0 to 100. The PID controller wil compute negative values
   --  as well as posiitve values, to turn the steering mechanism in either
   --  direction, so we want to limit the PID to -100 .. 100. We later take the
   --  absolute value after using the sign to get the direction, in procedure
   --  Convert_To_Motor_Values.

   function Convert_To_Motor_Angle (Encoder_Count : Motor_Encoder_Counts) return Float with Inline;
   --  Returns the current encoder count for This motor in degree units

   procedure Convert_To_Motor_Values
     (Signed_Power : Float;
      Motor_Power  : out NXT.Motors.Power_Level;
      Direction    : out NXT.Motors.Directions)
   with
      Inline;
   --  Convert the signed power value from the PID controller to NXT motor
   --  values. We know the precondition will hold because we set those limits
   --  via the call to Steering_Computer.Configure

   Steering_Offset : Float;
   --  The angle at which the vehicle is steering straight ahead. Hard
   --  right is always 0 and hard left is always Steering_Offset * 2.
   --  This value is used to convert from the "observer's" frame of
   --  reference to the vehicle's frame of reference.

   ---------------
   -- Configure --
   ---------------

   procedure Configure (Steering_Offset : Float) is
   begin
      Ada_Steering_Controller.Steering_Offset := Steering_Offset;
   end Configure;

   ----------------
   -- Initialize --
   ----------------

   procedure Initialize (State : in out Ada_Steering_Controller_State)
   is
   begin
      State.Steering_Computer.Configure
        (Proportional_Gain => Kp,
         Integral_Gain     => Ki,
         Derivative_Gain   => Kd,
         Period            => 10, -- 10 ms = 100Hz = 0.01 seconds
         Output_Limits     => Power_Level_Limits,
         Direction         => Closed_Loop.Direct);

      State.Current_Angle  := 0.0;  -- zero for call to Steering_Computer.Enable
      State.Steering_Power := 0.0;  -- zero for call to Steering_Computer.Enable

      State.Steering_Computer.Enable (
         Process_Variable => State.Current_Angle,
         Control_Variable => State.Steering_Power);
   end Initialize;

   -------------
   -- Compute --
   -------------

   procedure Compute
     (Encoder_Count            : Motor_Encoder_Counts;
      Requested_Steering_Angle : Integer_8;
      Motor_Power              : out Power_Level;
      Rotation_Direction       : out Directions;
      State                    : in out Ada_Steering_Controller_State)
   is
      Target_Angle : Float;
   begin
      State.Current_Angle := Convert_To_Motor_Angle (Encoder_Count) - Steering_Offset;

      Target_Angle := Float (Requested_Steering_Angle);

      if Target_Angle < -Steering_Offset then
         Target_Angle := -Steering_Offset;
      elsif Target_Angle > Steering_Offset then
         Target_Angle := Steering_Offset;
      end if;

      State.Steering_Computer.Compute_Output
        (Process_Variable => State.Current_Angle,
         Setpoint         => Target_Angle,
         Control_Variable => State.Steering_Power);

      Convert_To_Motor_Values (State.Steering_Power, Motor_Power, Rotation_Direction);
   end Compute;


   function Within_Limits (State : Ada_Steering_Controller_State) return Boolean is
     ((State.Steering_Computer.Current_Output_Limits = Power_Level_Limits) and
      (Closed_Loop.Within_Limits (State.Steering_Power, Power_Level_Limits)));


   -------------------------
   -- Convert_To_Motor_Angle --
   -------------------------

   function Convert_To_Motor_Angle (Encoder_Count : Motor_Encoder_Counts) return Float is
      (Float (Encoder_Count) / Float (Steering_Control.Encoder_Counts_Per_Degree));


   -----------------------------
   -- Convert_To_Motor_Values --
   -----------------------------

   procedure Convert_To_Motor_Values
     (Signed_Power : Float;
      Motor_Power  : out NXT.Motors.Power_Level;
      Direction    : out NXT.Motors.Directions)
   is
   begin
      Direction := Vehicle.To_Steering_Motor_Direction (Signed_Power);
      --  The motor values are a percentage from 0 .. 100. The sign of the value
      --  is only used in the statement above, for "turn" directions.
      Motor_Power := Power_Level (abs (Signed_Power));
   end Convert_To_Motor_Values;

end Ada_Steering_Controller;