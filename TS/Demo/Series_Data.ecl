// Generate time series data fro demonstration of TS attributes
IMPORT Std.system.thorlib;
IMPORT TS;
IMPORT TS.Types;

EXPORT Series_Data(UNSIGNED2 test_records=100,
                   REAL8 start_val, REAL8 incr_val) := FUNCTION
  Work0 := RECORD
    UNSIGNED2 rec_id := 0;
    REAL8 val_flat := 0.0;
    REAL8 val_slope := 0.0;
    REAL8 val_accum := 0.0;
    REAL8 val_lag_2 := 0.0;
  END;
  State_Rec := RECORD
    REAL8 prev_val;
    REAL8 prev_prev_val;
    REAL8 accum;
  END;
  REAL8 genNoise := (RANDOM()%1000)/10000;
  w0 := DATASET([{0}], {UNSIGNED2 x});
  w1 := NORMALIZE(w0, test_records, TRANSFORM(Work0, SELF.rec_id:=COUNTER));
  s_init := ROW({start_val-incr_val, start_val-2*incr_val, 0.0}, State_Rec);
  Work0 nextVal(Work0 w, State_Rec s) := TRANSFORM
    SELF.rec_id := w.rec_id;
    SELF.val_flat := start_val + genNoise;
    SELF.val_slope := s.prev_val + incr_val + genNoise;
    SELF.val_accum := s.prev_val + s.accum + genNoise;
    SELF.val_lag_2 := s.prev_prev_val + genNoise;
  END;
  State_Rec nextState(Work0 w, State_Rec s) := TRANSFORM
    SELF.accum := s.accum + s.prev_val + incr_val;
    SELF.prev_val := s.prev_val + incr_val;
    SELF.prev_prev_val := s.prev_val;
  END;
  w2 := PROCESS(w1, s_init, nextVal(LEFT,RIGHT),nextState(LEFT,RIGHT))
     : PERSIST('TEMP::TIME_SERIES_DATA::PERSIST');
  RETURN w2;
END;