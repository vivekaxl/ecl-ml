// Apply the model to generate forecast observations.  The last MAX(p,q)
//observations are used for the first forecasts for each of the model
//specifications provided.  The p,q parameters vary by model.
IMPORT TS;
Model_Score := TS.Types.Model_Score;
Model_Parm := TS.Types.Model_Parameters;
ObsRec := TS.Types.UniObservation;
ModelObs := TS.Types.ModelObs;
EXPORT DATASET(TS.Types.ModelObs)
       Forecast(DATASET(ObsRec) obs, UNSIGNED2 forcast_periods,
                DATASET(Model_Parm) parms) := FUNCTION
  // Generate data for each model and difference
  byModel := TS.SeriesByModel(obs, parms) ;
  diffed := TS.DifferenceSeries(byModel, parms, keepInitial:=TRUE);
  // Select last part for forecast
  ModelExt := RECORD(TS.Types.Model_Parameters)
    UNSIGNED2 history;
    TS.Types.t_value mu;
  END;
  ModelExt calcExtend(Model_Parm prm) := TRANSFORM
    SELF.history := MAX(prm.ar_terms, prm.ma_terms) + prm.degree + 1;
    SELF.mu := IF(prm.ar_terms>0, prm.c*(1.0-SUM(prm.ar,cv)), prm.c);
    SELF := prm;
  END;
  extend_specs := PROJECT(parms, calcExtend(LEFT));
  WorkRec := RECORD(ModelExt)
    TS.Types.t_time_ord period;
    DATASET(ObsRec) obs;    // historical and forecast
  END;
  WorkRec makeBase(ModelExt ex, DATASET(ModelObs) obs) := TRANSFORM
    SELF.period := MAX(obs, period);
    SELF.obs := TOPN(obs, ex.history, -period);
    SELF := ex;
  END;
  base := DENORMALIZE(extend_specs, diffed, LEFT.model_id=RIGHT.model_id,
                      GROUP, makeBase(LEFT, ROWS(RIGHT)), NOSORT);
  // Apply model to base records
  RETURN DATASET([], TS.Types.ModelObs);
END;
