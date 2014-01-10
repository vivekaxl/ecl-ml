//
IMPORT TS;
Model_Score := TS.Types.Model_Score;
Model_Spec := TS.Types.Model_Spec;
ObsRec := TS.Types.UniObservation;
EXPORT DATASET(TS.Types.ForecastObs)
       Forecast(DATASET(ObsRec) obs, UNSIGNED2 forcast_periods,
                DATASET(Model_Spec) specs) := FUNCTION
  // Apply model
  RETURN DATASET([], TS.Types.ForecastObs);
END;
