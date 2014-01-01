// Model Identification.  Produces Autocorrelation function and
//the partial autocorrelation function datasets.
IMPORT TS.Types;
ObsRec := Types.UniObservation;
EXPORT Identification(DATASET(Types.UniObservation) obs,
                      UNSIGNED degree=0) := MODULE
  EXPORT DATASET(Types.UniObservation) post_difference := FUNCTION
    ObsRec deltaObs(TObsRec prev, ObsRec) := TRANSFORM
      SELF.dependent := curr.dependent = prev.dependent;
      SELF.period := curr.period;
    END;
    diff1 := ITERATE(obs, deltaObs(LEFT.RIGHT))(period > 1);
    diff2 := ITERATE(diff1, deltaObs(LEFT.RIGHT))(period > 2);
    rslt := IF(degree > 1,
                diff2,
                IF(degree > 0,
                    diff1,
                    obs));
    RETURN rslt;
  END;
  SHARED LagRec := RECORD
    Types.t_time_ord period;
    Types.t_time_ord lag_per;
    Types.t_value v;
  END;
  EXPORT DATASET(Types.PACF_ACF) Correlations(UNSIGNED2 lags) := FUNCTION
    RETURN DATASET([], Types.PACF_ACF);
  END;
  EXPORT DATASET(Types.CorrRec) ACF(UNSIGNED2 lags) := FUNCTION
    RETURN PROJECT(Correlations(lags),
                   TRANSFORM(Types.CorrRec, SELF.lag:=LEFT.lag,
                             SELF.corr:=LEFT.ac, SELF.t_like:=LEFT.ac_t_like));
  END;
  EXPORT DATASET(Types.CorrRec) PACF(UNSIGNED2 lags) := FUNCTION
    RETURN PROJECT(Correlations(lags),
                   TRANSFORM(Types.CorrRec, SELF.lag:=LEFT.lag,
                            SELF.corr:=LEFT.pac, SELF.t_like:=LEFT.pac_t_like));
  END;
END;