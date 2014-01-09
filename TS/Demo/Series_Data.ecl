// Generate time series data fro demonstration of TS attributes
IMPORT Std.system.thorlib;
IMPORT TS;
IMPORT TS.Types;

EXPORT Series_Data(UNSIGNED2 test_records=100) := MODULE
  SHARED Work0 := RECORD
    UNSIGNED2 recID;
    REAL8 val_flat;
    REAL8 val_slope;
  END;
  EXPORT TestData := DATASET(test_records, genRec(COUNTER), DISTRIBUTED);
  EXPORT Flat_Data := TS.extract_ts(TestData, val_flat);
  EXPORT Slope_Data := TS.extract_ts(TestData, val_slope);
END;