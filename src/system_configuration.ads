--  Task periods and priorities

with System; use System;

package System_Configuration is

   --  These constants are the priorities of the tasks in the system, defined
   --  here for ease of setting with the big picture in view.

   Main_Priority           : constant Priority := Priority'First; -- ie lowest
   Engine_Monitor_Priority : constant Priority := Main_Priority + 1;
   Remote_Priority         : constant Priority := Engine_Monitor_Priority + 1;
   Engine_Control_Priority : constant Priority := Remote_Priority + 1;
   Steering_Priority       : constant Priority := Engine_Control_Priority + 1;

   --  The engine control priority needs high priority because it calls the
   --  sonar sensor via the collision detection module, and that sonar object
   --  uses bit-banged I/O (unfortunately) and so should not be preempted much.
   --  Ugh. I'd rather do the response-time analysis and set the priorities by
   --  period...

   Highest_Priority  : Priority renames Steering_Priority;
   --  Whichever is highest. All the tasks call into the global initialization
   --  PO to await completion before doing anything interesting, so the PO
   --  requires the highest of those caller priorities.

   --  These constants are the tasks' periods, defined here for ease of setting
   --  with the big picture in view. They are merely named numbers rather than
   --  values of type Time_Span because their values are also used for other
   --  purposes, eg configuring the steering PID controller.

   --  TODO: align priorities with periods!

   Engine_Control_Period   : constant := 200; -- milliseconds
   Engine_Monitor_Period   : constant := 150; -- milliseconds
   Remote_Control_Period   : constant := 100; -- milliseconds
   Steering_Control_Period : constant := 10;  -- milliseconds
   --  NB: important to PID tuning!

end System_Configuration;
