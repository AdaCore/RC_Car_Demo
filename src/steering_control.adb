with Global_Initialization;
with Ada.Real_Time;  use Ada.Real_Time;
with Vehicle;        use Vehicle;
with NXT.Motors;     use NXT.Motors;
with Remote_Control;
with Math_Utilities;
with Process_Control_Floating_Point;

package body Steering_Control
   with SPARK_Mode
is

   Period  : constant Time_Span := Milliseconds (System_Configuration.Steering_Control_Period);
   --  NB: important to PID tuning!

   package Closed_Loop is new Process_Control_Floating_Point (Float, Long_Float);
   use Closed_Loop;

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

   Encoder_Counts_Per_Degree : constant Float := Float (NXT.Motors.Encoder_Counts_Per_Revolution) / 360.0;

   procedure Limit is new Math_Utilities.Bound_Floating_Value (Float);

   procedure Initialize_Steering_Mechanism (Center_Offset : out Float) with
     Post => Center_Offset > 0.0;
   --  Compute the steering zero offset value by powering the steering mechanism
   --  to the mechanical limits.

   function Current_Motor_Angle (This : Basic_Motor) return Float with Inline;
   --  Returns the current encoder count for This motor in degree units

   procedure Convert_To_Motor_Values
     (Signed_Power : Float;
      Motor_Power  : out NXT.Motors.Power_Level;
      Direction    : out NXT.Motors.Directions)
   with
     Inline,
     Pre => Within_Limits (Signed_Power, Power_Level_Limits);
   --  Convert the signed power value from the PID controller to NXT motor
   --  values. We know the precondition will hold because we set those limits
   --  via the call to Steering_Computer.Configure

   -----------
   -- Servo --
   -----------

   task body Servo is
      Next_Release       : Time;
      Target_Angle       : Float;
      Current_Angle      : Float := 0.0;  -- zero for call to Steering_Computer.Enable
      Steering_Power     : Float := 0.0;  -- zero for call to Steering_Computer.Enable
      Motor_Power        : NXT.Motors.Power_Level;
      Rotation_Direction : NXT.Motors.Directions;
      Steering_Offset    : Float;
      Steering_Computer  : Closed_Loop.PID_Controller;
   begin
      Steering_Computer.Configure
        (Proportional_Gain => Kp,
         Integral_Gain     => Ki,
         Derivative_Gain   => Kd,
         Period            => System_Configuration.Steering_Control_Period,
         Output_Limits     => Power_Level_Limits,
         Direction         => Closed_Loop.Direct);

      Global_Initialization.Critical_Instant.Wait (Epoch => Next_Release);

      Initialize_Steering_Mechanism (Steering_Offset);

      Steering_Computer.Enable (Process_Variable => Current_Angle, Control_Variable => Steering_Power);
      loop
         pragma Loop_Invariant (Steering_Computer.Current_Output_Limits = Power_Level_Limits);
         pragma Loop_Invariant (Within_Limits (Steering_Power, Power_Level_Limits));

         Current_Angle := Current_Motor_Angle (Steering_Motor) - Steering_Offset;

         Target_Angle := Float (Remote_Control.Requested_Steering_Angle);
         Limit (Target_Angle, -Steering_Offset, Steering_Offset);

         Steering_Computer.Compute_Output
           (Process_Variable => Current_Angle,
            Setpoint         => Target_Angle,
            Control_Variable => Steering_Power);

         Convert_To_Motor_Values (Steering_Power, Motor_Power, Rotation_Direction);

         Steering_Motor.Engage (Rotation_Direction, Motor_Power);

         Next_Release := Next_Release + Period;
         delay until Next_Release;
      end loop;
   end Servo;

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

   -------------------------
   -- Current_Motor_Angle --
   -------------------------

   function Current_Motor_Angle (This : Basic_Motor) return Float is
     ((Float (This.Encoder_Count) / Encoder_Counts_Per_Degree));

   -----------------------------------
   -- Initialize_Steering_Mechanism --
   -----------------------------------

   procedure Initialize_Steering_Mechanism (Center_Offset : out Float) is
      Current_Angle  : Float;
      Previous_Angle : Float;
      Sample_Inteval : constant Time_Span := Milliseconds (100);  -- arbitrary
      Next_Release   : Time;
      Testing_Power  : constant Power_Level := 80;
      --  The power setting is arbitrary, but should be kept realtively low so
      --  as to avoid stressing the steering mechanism unduly. That said, it
      --  must be enough to really go to the physical limits, even on carpet.
   begin
      --  The pupose of this routine is to determine the value of the global
      --  mechanical steering "zero," ie, the value when steering straight
      --  ahead. This value is used as an offset when steering to commanded
      --  angles received from the remote control. Therefore, we drive the
      --  steering mechanism all the way to the maximums for left and right,
      --  then compute half of that angle for the center steering offset.

      --  steer to right-most mechanical limit
      Current_Angle := Current_Motor_Angle (Steering_Motor);
      Steering_Motor.Engage (To_The_Right, Power => Testing_Power);
      Next_Release := Clock;
      loop
         --  give the motor time to move
         Next_Release := Next_Release + Sample_Inteval;
         delay until Next_Release;

         Previous_Angle := Current_Angle;
         Current_Angle := Current_Motor_Angle (Steering_Motor);
         --  Exit when no further progress made. We are driving the motor
         --  backward so the encoder count will be decreasing, hence "<"
         exit when not (Current_Angle < Previous_Angle);
      end loop;

      --  Now that we are at the right-most limit, we reset the motor encoder
      --  count to zero before driving the motor to the left-most limit. As
      --  a result, the value read at the left-most limit will give us the
      --  full angle range possible for steering.
      Steering_Motor.Reset_Encoder_Count;

      --  steer to left-most mechanical limit
      Current_Angle := Current_Motor_Angle (Steering_Motor);
      Steering_Motor.Engage (To_The_Left, Power => Testing_Power);
      Next_Release := Clock;
      loop
         --  give the motor time to move
         Next_Release := Next_Release + Sample_Inteval;
         delay until Next_Release;

         Previous_Angle := Current_Angle;
         Current_Angle := Current_Motor_Angle (Steering_Motor);
         --  Exit when no further progress made. We are driving the motor
         --  foreward so the encoder count will be increasing, hence ">"
         exit when not (Current_Angle > Previous_Angle);
      end loop;

      --  Current_Angle is now the maximum steering angle mechanically possible,
      --  from far right to far left. Therefore the center is half that angle.
      Center_Offset := Current_Angle / 2.0;

      --  Because our "To_The_Left" is "Forward" to the NXT motor direction, the
      --  encoder values will be increasing away from zero.
      pragma Assert (To_The_Left = Forward); -- make sure...
      --  The encoder was reset before moving to the left-most limit, therefore
      --  Center_Offset is positive.
      pragma Assume (Center_Offset > 0.0);
      --  NB: if the above assertion fails during debugging, make sure that
      --  the battery is supplying power to the motors etc so that the steering
      --  motor actually moves.

      --  Rationale for this procedure, in light of the above:
      --
      --  The steering control computer receives steering angle requests
      --  from the user via the remote control. These requests use a frame
      --  of reference oriented on the major axis of the vehicle. Because we
      --  use the steering motor rotation angle to steer the vehicle, we must
      --  translate the requests from the user's frame of reference (ie, the
      --  vehicle's) into the frame of reference of the steering motor. The
      --  steering motor's frame of reference is defined by the steering
      --  mechanism's physical connection to the motor shaft when the shaft
      --  rotation encoder count is zero.
      --
      --  Therefore, to do the translation we set the motor encoder to zero at
      --  some known point relative to the vehicle's major axis and then handle
      --  the difference between that motor "zero" and the "zero" corresponding
      --  to the major axis. We thus orient the motor's frame of reference to
      --  that of the vehicle.
      --
      --  Ideally, the two frames of reference would be aligned (both zero) on
      --  the vehicle's major axis, but in the software there's no way to know
      --  where that major axis is. This is a matter of physical reality.
      --
      --  So, how can the software identify some known point on the vehicle (to
      --  set the motor encoder to zero there)?
      --
      --  We know how the steering mechanism is physically oriented to the
      --  vehicle's major axis: the angle for steering "straight ahead"
      --  corresponds with the axis. We also know (or can safely assume) that
      --  the steering mechanism is symmetric, ie, it can steer equally in
      --  either direction. Therefore, the center of the arc described by the
      --  steering mechanism is "straight ahead" and is, therefore, aligned
      --  with the major axis of the vehicle.
      --
      --  We (the software) can measure the steering arc because we can locate
      --  the mechanical far-left and far-right steering mechanism extents.
      --
      --  In addition, those mechanical extents are known points on the
      --  vehicle relative to the major axis so we can set the motor's frame of
      --  reference to one of them. It doesn't matter which one we use. In the
      --  code above, we had chosen, arbitrarily, to measure from far-right to
      --  far-left, so we had set the encoder to zero at the far-right extent.
      --  Therefore, we simply use the far-right extent to set the motor's frame
      --  of reference.
      --
      --  Now the difference between the two frames of reference is simply the
      --  difference between the far-right steering extent and the center of the
      --  steering arc. That value is precisely half the total number of degrees
      --  in the arc. Therefore, the steering computer will subtract that value
      --  from the motor's reported angle to translate the reported value into
      --  the vehicle's frame of reference.
   end Initialize_Steering_Mechanism;

end Steering_Control;
