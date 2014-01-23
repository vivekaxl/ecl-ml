//
IMPORT TS;
Model_Score := TS.Types.Model_Score;
Model_Parm := TS.Types.Model_Parameters;
ObsRec := TS.Types.UniObservation;
ModelObs := TS.Types.ModelObs;
Co_eff := TS.Types.CO_efficient;
EXPORT DATASET(Model_Score)
       Diagnosis(DATASET(TS.Types.UniObservation) obs,
                 DATASET(TS.Types.Model_Parameters) models) := FUNCTION
  // Generate data for each model and difference
  byModel := TS.SeriesByModel(obs, models);
  diffed := TS.DifferenceSeries(byModel, models, keepInitial:=TRUE);
  // Score the models
  ModelWork := RECORD
    TS.Types.t_model_id model_id;
    UNSIGNED2 terms;
    TS.Types.t_value c;
    TS.Types.t_value mu;
    DATASET(Co_eff) theta_phi;
    DATASET(Co_eff) phi;
  END;
  Co_eff mrgF(Co_eff theta, Co_eff phi) := TRANSFORM
    SELF.lag := IF(theta.lag<>0, theta.lag, phi.lag);
    SELF.cv := theta.cv + phi.cv;
  END;
  ModelWork calcExtend(Model_Parm prm) := TRANSFORM
    SELF.terms := MAX(prm.ar_terms, prm.ma_terms) + prm.degree + 1;
    SELF.mu := IF(prm.ar_terms>0, prm.c*(1.0-SUM(prm.ar,cv)), prm.c);
    SELF.theta_phi := JOIN(prm.ar, prm.ma, LEFT.lag=RIGHT.lag,
                           mrgF(LEFT,RIGHT), FULL OUTER);
    SELF.phi := prm.ma;
    SELF := prm;
  END;
  extend_specs := PROJECT(models, calcExtend(LEFT));
  WorkRec := RECORD(ModelWork)
    TS.Types.t_time_ord period;
    TS.Types.t_value dependent;
    TS.Types.t_value estimate;
  END;
  HistRec := RECORD
    DATASET(ObsRec) act;
    DATASET(ObsRec) fcst;
  END;
  WorkRec makeBase(ModelObs obs, ModelWork mod) := TRANSFORM
    SELF.estimate := 0.0;
    SELF := obs;
    SELF := mod;
  END;
  withModel := JOIN(diffed, extend_specs, LEFT.model_id=RIGHT.model_id,
                     makeBase(LEFT,RIGHT), LOOKUP);
  RETURN DATASET([], Model_Score);
END;
