//
IMPORT TS;
Model_Score := TS.Types.Model_Score;
Model_Parm := TS.Types.Model_Parameters;
ObsRec := TS.Types.UniObservation;
ModelObs := TS.Types.ModelObs;
Parameter_Extension := TS.Types.Parameter_Extension;
Co_eff := TS.Types.CO_efficient;
EXPORT DATASET(Model_Score)
       Diagnosis(DATASET(TS.Types.UniObservation) obs,
                 DATASET(TS.Types.Model_Parameters) models) := FUNCTION
  // Generate data for each model and difference
  byModel := TS.SeriesByModel(obs, models);
  diffed := TS.DifferenceSeries(byModel, models, keepInitial:=TRUE);
  // Score the models
  extend_specs := TS.ExtendedParameters(models);
  WorkRec := RECORD(Parameter_Extension)
    TS.Types.t_time_ord period;
    TS.Types.t_value dependent;
    TS.Types.t_value estimate;
  END;
  HistRec := RECORD
    DATASET(ObsRec) act;
    DATASET(ObsRec) fcst;
  END;
  WorkRec makeBase(ModelObs obs, Parameter_Extension mod) := TRANSFORM
    SELF.estimate := 0.0;
    SELF := obs;
    SELF := mod;
  END;
  withModel := JOIN(diffed, extend_specs, LEFT.model_id=RIGHT.model_id,
                     makeBase(LEFT,RIGHT), LOOKUP);
  RETURN DATASET([], Model_Score);
END;
