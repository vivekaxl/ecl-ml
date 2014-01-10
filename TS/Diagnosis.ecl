//
IMPORT TS;
Model_Score := TS.Types.Model_Score;
Model_Spec := TS.Types.Model_Spec;
ObsRec := TS.Types.UniObservation;
EXPORT DATASET(Model_Score)
       Diagnosis(DATASET(ObsRec) obs,
                 DATASET(Model_Spec) models) := FUNCTION
  // Score the models
  RETURN DATASET([], Model_Score);
END;
