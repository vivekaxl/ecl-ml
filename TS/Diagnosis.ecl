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
  DATASET(ObsRec) jumpStart(UNSIGNED t, REAL8 mu) := FUNCTION
    ObsRec genObs() := TRANSFORM
      SELF.period := 0;
      SELF.dependent := mu;
    END;
    dummy := DATASET([{1}], {UNSIGNED1 x});
    rslt := NORMALIZE(dummy, t, genObs());
    RETURN rslt;
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
  withParm := JOIN(diffed, extend_specs, LEFT.model_id=RIGHT.model_id,
                     makeBase(LEFT,RIGHT), LOOKUP);
  grpdModObs := GROUP(SORT(withParm, model_id, period), model_id);
  UpdRec(WorkRec wr, HistRec hr) := MODULE
    SHARED act := IF(EXISTS(hr.act), hr.act, jumpStart(wr.terms, wr.mu));
    SHARED fct := IF(EXISTS(hr.fcst), hr.fcst, jumpStart(wr.terms, wr.mu));
    SHARED actN:= DATASET([{wr.period, wr.dependent}], ObsRec) & act;
    EXPORT HistRec histUpd() := TRANSFORM
      SELF.act := CHOOSEN(actN, wr.terms);
      SELF := [];
    END;
    EXPORT WorkRec obsUpd() := TRANSFORM
      SELF := [];
    END;
  END;
  initH := ROW({DATASET([],ObsRec), DATASET([], ObsRec)}, HistRec);
  withEst := PROCESS(grpdModObs, initH, UpdRec(LEFT,RIGHT).obsUpd(), UpdRec(LEFT,RIGHT).histUpd());
  RETURN DATASET([], Model_Score);
END;
