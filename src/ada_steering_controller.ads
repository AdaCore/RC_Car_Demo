with Interfaces; use Interfaces;

with NXT.Motors; use NXT.Motors;

with Process_Control_Floating_Point;

package Ada_Steering_Controller with
   SPARK_Mode
is
   type Ada_Steering_Controller_State is tagged limited private;

   procedure Configure (Steering_Offset : Float);
   --  Configure the Ada steering controller.

   procedure Initialize (State : in out Ada_Steering_Controller_State);
   --  Initialize the states for the Ada controller.

   procedure Compute (
      Encoder_Count            : Motor_Encoder_Counts;
      Requested_Steering_Angle : Integer_8;
      Motor_Power              : out Power_Level;
      Rotation_Direction       : out Directions;
      State                    : in out Ada_Steering_Controller_State);
   --  Compute control outputs based on inputs and state. Note: this also
   --  updates state.

   function Within_Limits (State : Ada_Steering_Controller_State) return Boolean
      with Inline;

private
   package Closed_Loop is new Process_Control_Floating_Point (Float, Long_Float);
   use Closed_Loop;

   type Ada_Steering_Controller_State is tagged limited record
      Steering_Computer  : Closed_Loop.PID_Controller;
      Current_Angle      : Float;
      Steering_Power     : Float;
   end record;
end Ada_Steering_Controller;