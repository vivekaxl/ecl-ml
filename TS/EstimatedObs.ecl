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
    BOOLEAN future;
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
    SELF.future := FALSE;
    SELF := obs;
    SELF := mod;
  END;
  withParm := JOIN(diffed, extend_specs, LEFT.model_id=RIGHT.model_id,
                     makeBase(LEFT,RIGHT), LOOKUP);
  srtdModObs := SORT(withParm, model_id, period);
  srtdModLast:= DEDUP(srtdModObs, model_id, RIGHT);
  WorkRec makeFuture(WorkRec lstRec, UNSIGNED c) := TRANSFORM
    SELF.estimate := 0.0;
    SELF.future := TRUE;
    SELF.period := lstRec.period + c;
    SELF.dependent := 0.0;
    SELF := lstRec; // pick up model stuff
  END;
  srtdModFtr := NORMALIZE(srtdModLast, forecast_periods, makeFuture(LEFT, COUNTER));
  grpdModObs := GROUP(SORT(srtdModObs+srtdModFtr, model_id, period), period);
  // Process definition from iteration through observations
  UpdRec(WorkRec wr, HistRec hr) := MODULE
    SHARED act := IF(EXISTS(hr.act),
                     PROJECT(hr.act, ObsWork),
                     jumpStart(wr.terms, wr.mu));
    SHARED fct := IF(EXISTS(hr.fcst),
                     PROJECT(hr.fcst, ObsWork),
                     jumpStart(wr.terms, wr.mu));
    SHARED actN:= DATASET([{wr.period, wr.dependent}], ObsWork) & act;
    ObsWork prodTerm(Co_eff cof, ObsWork t, INTEGER sgn) := TRANSFORM
      SELF.period := t.period;
      SELF.dependent := cof.cv * t.dependent * (REAL8)sgn;
    END;
    poly1 := JOIN(wr.theta_phi, act,
                  LEFT.lag = wr.period - RIGHT.period,
                  prodTerm(LEFT,RIGHT, 1));
    poly2 := JOIN(wr.phi, fct,
                  LEFT.lag = wr.period - RIGHT.period,
                  prodTerm(LEFT,RIGHT,-1));
    SHARED forecast_val := SUM(poly1 + poly2, dependent);
    SHARED fctN:= DATASET([{wr.period, forecast_val}], ObsWork) & fct;
    EXPORT HistRec histUpd() := TRANSFORM
      SELF.act := CHOOSEN(actN, wr.terms);
      SELF.fcst:= CHOOSEN(fctN, wr.terms);
    END;
    EXPORT WorkRec obsUpd() := TRANSFORM
      SELF.dependent := IF(wr.future, forecast_val, wr.dependent);
      SELF.estimate := forecast_val;
      SELF := wr;
    END;
  END;
  initH := ROW({DATASET([],ObsWork), DATASET([], ObsWork)}, HistRec);
  withEst := PROCESS(grpdModObs, initH, UpdRec(LEFT,RIGHT).obsUpd(), UpdRec(LEFT,RIGHT).histUpd());
  //reverse differencing
  WorkRec accumObs(WorkRec prev, WorkRec curr, UNSIGNED2 pass) := TRANSFORM
    no_accum := pass > curr.degree OR prev.model_id <> curr.model_id;
    SELF.dependent := IF(no_accum, curr.dependent, curr.dependent+prev.dependent);
    SELF.estimate  := IF(no_accum, curr.estimate, curr.estimate+prev.estimate);
    SELF := curr;
  END;
  accum1 := ITERATE(UNGROUP(withEst), accumObs(LEFT, RIGHT, 1));
  accum2 := ITERATE(accum1, accumObs(LEFT, RIGHT, 2));
  //
  RETURN PROJECT(accum2, TS.Types.Obs_Estimated);
END;