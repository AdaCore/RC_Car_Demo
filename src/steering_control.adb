with Global_Initialization;
with Ada.Real_Time;  use Ada.Real_Time;
with Interfaces;     use Interfaces;
with Vehicle;        use Vehicle;
with NXT.Motors;     use NXT.Motors;
with Remote_Control;
with Ada_Steering_Controller;

package body Steering_Control
   with SPARK_Mode
is

   Period  : constant Time_Span := Milliseconds (System_Configuration.Steering_Control_Period);
   --  NB: important to PID tuning!

   procedure Initialize_Steering_Mechanism (Center_Offset : out Float) with
     Post => Center_Offset > 0.0;
   --  Compute the steering zero offset value by powering the steering mechanism
   --  to the mechanical limits.

   function Current_Motor_Angle (This : Basic_Motor) return Float with Inline;
   --  Returns the current angle of This motor in degree units

   -----------
   -- Servo --
   -----------

   task body Servo is
      Controller_State   : Ada_Steering_Controller.Ada_Steering_Controller_State;
      Next_Release       : Time;
      Target_Angle       : Integer_8;
      Motor_Power        : NXT.Motors.Power_Level;
      Rotation_Direction : NXT.Motors.Directions;
   begin
      Global_Initialization.Critical_Instant.Wait (Epoch => Next_Release);

      declare
         Steering_Offset : Float;
      begin
         Initialize_Steering_Mechanism (Steering_Offset);

         Ada_Steering_Controller.Configure (Steering_Offset);
      end;

      Ada_Steering_Controller.Initialize (Controller_State);

      loop
         pragma Loop_Invariant (Ada_Steering_Controller.Within_Limits (Controller_State));

         Target_Angle := Integer_8 (Remote_Control.Requested_Steering_Angle);

         Ada_Steering_Controller.Compute
           (Encoder_Count            => Steering_Motor.Encoder_Count,
            Requested_Steering_Angle => Target_Angle,
            Motor_Power              => Motor_Power,
            Rotation_Direction       => Rotation_Direction,
            State                    => Controller_State);

         Steering_Motor.Engage (Rotation_Direction, Motor_Power);

         Next_Release := Next_Release + Period;
         delay until Next_Release;
      end loop;
   end Servo;

   -------------------------
   -- Current_Motor_Angle --
   -------------------------

   function Current_Motor_Angle (This : Basic_Motor) return Float is
     (Float (This.Encoder_Count) / Float (Encoder_Counts_Per_Degree));

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
