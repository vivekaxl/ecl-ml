//
IMPORT TS;
EXPORT DATASET(TS.Types.Model_Parameters)
       Estimation(DATASET(TS.Types.UniObservation) obs,
                  DATASET(TS.Types.Model_Spec) spec) := FUNCTION
  // Calculate parameters
  RETURN DATASET([], TS.Types.Model_Parameters);
END;
