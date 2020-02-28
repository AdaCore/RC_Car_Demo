--  This package provides a synchronization mechanism used to signal to the
--  various tasks that the critical instant has arrived and that, as a result,
--  their periodic executon can now commence (with the Time value specified for
--  the epoch).

with System_Configuration;
with Ada.Real_Time;  use Ada.Real_Time;

package Global_Initialization
  with SPARK_Mode
is

   protected Critical_Instant
     with Priority => System_Configuration.Highest_Priority
   is
      procedure Signal (Epoch : Time);
      --  signal completion of the global initialization sequence and specify
      --  the beginnning of the epoch for task periodic processing

      entry Wait (Epoch : out Time);
      --  await completion of the global initialization sequence and get
      --  the beginnning of the epoch for task periodic processing

   private
      Signalled    : Boolean := False;
      Global_Epoch : Time := Time_First;  -- overwritten by Signal
   end Critical_Instant;

end Global_Initialization;
