//
IMPORT TS;
Model_Score := TS.Types.Model_Score;
Model_Parm := TS.Types.Model_Parameters;
ObsRec := TS.Types.UniObservation;
ModelObs := TS.Types.ModelObs;
EXPORT DATASET(Model_Score)
       Diagnosis(DATASET(TS.Types.UniObservation) obs,
                 DATASET(TS.Types.Model_Parameters) models) := FUNCTION
  // Generate data for each model and difference
  byModel := TS.SeriesByModel(obs, models);
  diffed := TS.DifferenceSeries(byModel, models, keepInitial:=TRUE);
  // Score the models
  ModelExt := RECORD(TS.Types.Model_Parameters)
    UNSIGNED2 history;
    TS.Types.t_value mu;
  END;
  ModelExt calcExtend(Model_Parm prm) := TRANSFORM
    SELF.history := MAX(prm.ar_terms, prm.ma_terms) + prm.degree + 1;
    SELF.mu := IF(prm.ar_terms>0, prm.c*(1.0-SUM(prm.ar,cv)), prm.c);
    SELF := prm;
  END;
  extend_specs := PROJECT(models, calcExtend(LEFT));
  WorkRec := RECORD(ModelExt)
    TS.Types.t_time_ord period;
    TS.Types.t_value dependent;
    TS.Types.t_value estimate;
    DATASET(ObsRec) independents;    // historical and forecast
  END;
  WorkRec makeBase(ModelObs obs, ModelExt mod) := TRANSFORM
    SELF := obs;
    SELF := mod;
    SELF := [];
  END;
  withModel := JOIN(diffed, extend_specs, LEFT.model_id=RIGHT.model_id,
                     makeBase(LEFT,RIGHT), LOOKUP);
  WorkRec calcEstimate(WorkRec mod, DATASET(ModelObs) obs) := TRANSFORM
    indies := obs(period BETWEEN mod.period-mod.history AND mod.period);
    SELF.independents := PROJECT(indies, ObsRec);
    SELF := mod;
  END;
  withData := DENORMALIZE(withModel, diffed, LEFT.model_id=RIGHT.model_id,
                          GROUP, calcEstimate(LEFT, ROWS(RIGHT)));
  RETURN DATASET([], Model_Score);
END;
