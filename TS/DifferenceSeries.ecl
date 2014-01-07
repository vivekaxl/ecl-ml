//Produce a difference series of degree 1 or 2
IMPORT TS.Types;
ObsRec := Types.UniObservation;
EXPORT DATASET(ObsRec) DifferenceSeries(DATASET(ObsRec) obs,
                                        UNSIGNED degree=0) := FUNCTION
  ObsRec deltaObs(ObsRec prev, ObsRec curr) := TRANSFORM
    SELF.dependent := curr.dependent - prev.dependent;
    SELF.period := curr.period;
  END;
  diff1 := ITERATE(obs, deltaObs(LEFT, RIGHT))(period > 1);
  diff2 := ITERATE(diff1, deltaObs(LEFT, RIGHT))(period > 2);
  rslt := IF(degree > 1,
              diff2,
              IF(degree > 0,
                  diff1,
                  obs));
  RETURN rslt;
END;
