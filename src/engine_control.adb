with Global_Initialization;
with Ada.Real_Time;          use Ada.Real_Time;
with NXT.Motors;             use NXT.Motors;
with Remote_Control;         use Remote_Control;
with Collision_Detection;
with Vehicle;                use Vehicle;
with STM32.Board;            use STM32.Board;
with NXT.Ultrasonic_Sensors; use NXT.Ultrasonic_Sensors;

package body Engine_Control with
  SPARK_Mode --  =>  Off -- for now...
is

   Period : constant Time_Span := Milliseconds (System_Configuration.Engine_Control_Period);

   Vector : Remote_Control.Travel_Vector with Atomic, Async_Readers, Async_Writers;
   --  we must declare this here, and access it as shown in the task body, for SPARK

   procedure Indicate_Emergency_Stopped;

   procedure Indicate_Running;

   procedure Apply
     (Direction : Remote_Control.Travel_Directions;
      Power     : Remote_Control.Percentage);

   procedure Emergency_Stop;

   type Controller_States is (Running, Braked, Awaiting_Reversal);

   ----------------
   -- Controller --
   ----------------

   task body Controller is
      Current_State       : Controller_States := Running;
      Next_Release        : Time;
      Requested_Direction : Remote_Control.Travel_Directions;
      Requested_Braking   : Boolean;
      Requested_Power     : Remote_Control.Percentage;
      Collision_Imminent  : Boolean;
      Current_Speed       : Float;
   begin
      Global_Initialization.Critical_Instant.Wait (Epoch => Next_Release);

      --  In the following loop, the call to get the requested vector does not
      --  block awaiting some change of input. The vectors are received as a
      --  continuous stream of values, often not changing from their previous
      --  values, rather than as a set of discrete commanded changes sent only
      --  when a new vector is commanded by the user.
      loop
         pragma Loop_Invariant (Configured (Vehicle.Sonar) and then
                                Enabled (Vehicle.Sonar) and then
                                Current_Scan_Mode (Vehicle.Sonar) = Continuous);

         Vector := Remote_Control.Requested_Vector;
         Requested_Direction := Vector.Direction;
         Requested_Braking   := Vector.Emergency_Braking;
         Requested_Power     := Vector.Power;
         Current_Speed := Vehicle.Speed;

         case Current_State is
            when Running =>
               Collision_Detection.Check (Requested_Direction, Current_Speed, Collision_Imminent);
               if Collision_Imminent then
                  Emergency_Stop;
                  Current_State := Awaiting_Reversal;
               elsif Requested_Braking then
                  Emergency_Stop;
                  Current_State := Braked;
               else
                  Apply (Requested_Direction, Requested_Power);
               end if;
            when Braked =>
               if not Requested_Braking then
                  Current_State := Running;
               end if;
            when Awaiting_Reversal =>
               if Requested_Direction = Backward then
                  Current_State := Running;
               end if;
         end case;

         Next_Release := Next_Release + Period;
         delay until Next_Release;
      end loop;
   end Controller;

   --------------------
   -- Emergency_Stop --
   --------------------

   procedure Emergency_Stop is
   begin
      Engine.Stop;
      Indicate_Emergency_Stopped;
   end Emergency_Stop;

   -----------
   -- Apply --
   -----------

   procedure Apply
     (Direction : Remote_Control.Travel_Directions;
      Power     : Remote_Control.Percentage)
   is
   begin
      if Direction /= Neither then
         Engine.Engage (Vehicle.To_Propulsion_Motor_Direction (Direction), Power);
      else
         Engine.Coast;
      end if;
      Indicate_Running;
   end Apply;

   --------------------------------
   -- Indicate_Emergency_Stopped --
   --------------------------------

   procedure Indicate_Emergency_Stopped is
   begin
      Red_LED.Set;
      Green_LED.Clear;
   end Indicate_Emergency_Stopped;

   ----------------------
   -- Indicate_Running --
   ----------------------

   procedure Indicate_Running is
   begin
      Red_LED.Clear;
      Green_LED.Toggle;
   end Indicate_Running;

end Engine_Control;
