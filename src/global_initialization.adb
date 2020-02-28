package body Global_Initialization
  with SPARK_Mode
is

   protected body Critical_Instant is

      ------------
      -- Signal --
      ------------

      procedure Signal (Epoch : Time) is
      begin
         Signalled := True;
         Global_Epoch := Epoch;
      end Signal;

      ----------
      -- Wait --
      ----------

      entry Wait (Epoch : out Time) when Signalled is
      begin
         Epoch := Global_Epoch;
      end Wait;

   end Critical_Instant;


end Global_Initialization;
