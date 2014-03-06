// Calculate the estimate values for history and future
IMPORT TS;
IMPORT TS.Types;
ModelObs := TS.Types.ModelObs;
Parameter_Extension := TS.Types.Parameter_Extension;
Co_eff := TS.Types.CO_efficient;
ObsRec := TS.Types.UniObservation;
ObsWork := RECORD
    INTEGER period;
    ObsRec.dependent;
END;
EXPORT DATASET(TS.Types.Obs_Estimated)
       EstimatedObs(DATASET(TS.Types.ModelObs) model_obs,
                    DATASET(TS.Types.Model_Parameters) models,
                    UNSIGNED2 forecast_periods=0) := FUNCTION
  diffed := TS.DifferenceSeries(model_obs, models, keepInitial:=TRUE);
  extend_specs := TS.ExtendedParameters(models);
  // Score the models
  WorkRec := RECORD(Parameter_Extension)
    TS.Types.t_time_ord period;
    TS.Types.t_value dependent;
    TS.Types.t_value estimate;
  END;
  DATASET(ObsWork) jumpStart(UNSIGNED t, REAL8 mu) := FUNCTION
    ObsWork genObs(UNSIGNED c) := TRANSFORM
      SELF.period := 1 - c;
      SELF.dependent := mu;
    END;
    dummy := DATASET([{1}], {UNSIGNED1 x});
    rslt := NORMALIZE(dummy, t, genObs(COUNTER));
    RETURN rslt;
  END;
  HistRec := RECORD
    DATASET(ObsWork) act;
    DATASET(ObsWork) fcst;
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
    SHARED act := IF(EXISTS(hr.act),
                     PROJECT(hr.act, ObsWork),
                     jumpStart(wr.terms, wr.mu));
    SHARED fct := IF(EXISTS(hr.fcst),
                     PROJECT(hr.fcst, ObsWork),
                     jumpStart(wr.terms, wr.mu));
    SHARED actN:= DATASET([{wr.period, wr.dependent}], ObsWork) & act;
    //poly := JOIN(wr.theta_phi, act
    EXPORT HistRec histUpd() := TRANSFORM
      SELF.act := CHOOSEN(actN, wr.terms);
      SELF := [];
    END;
    EXPORT WorkRec obsUpd() := TRANSFORM
      SELF := [];
    END;
  END;
  initH := ROW({DATASET([],ObsWork), DATASET([], ObsWork)}, HistRec);
  withEst := PROCESS(grpdModObs, initH, UpdRec(LEFT,RIGHT).obsUpd(), UpdRec(LEFT,RIGHT).histUpd());
  RETURN PROJECT(model_obs, TS.Types.Obs_Estimated);
END;