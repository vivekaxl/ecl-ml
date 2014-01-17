//Produce a difference series of degree 0, 1, or 2
IMPORT TS.Types;
ModelObs := Types.ModelObs;
Spec := Types.Ident_Spec;
EXPORT DATASET(ModelObs)
       DifferenceSeries(DATASET(ModelObs) obs,
                        DATASET(Spec) degree,
                        BOOLEAN keepInitial=FALSE) := FUNCTION
  ObsRec := RECORD(ModelObs)
    UNSIGNED2 degree;
  END;
  ObsRec markDegree(ModelObs obs, Spec sp) := TRANSFORM
    SELF.degree := sp.degree;
    SELF := obs;
  END;
  marked := JOIN(obs, degree, LEFT.model_id=RIGHT.model_id,
                 markDegree(LEFT, RIGHT), LOOKUP);
  ObsRec deltaObs(ObsRec prev, ObsRec curr, UNSIGNED2 pass) := TRANSFORM
    no_diff := pass > curr.degree OR prev.model_id <> curr.model_id;
    SELF.dependent := IF(no_diff, curr.dependent, curr.dependent-prev.dependent);
    SELF := curr;
  END;
  diff1 := ITERATE(marked, deltaObs(LEFT, RIGHT, 1));
  diff2 := ITERATE(diff1, deltaObs(LEFT, RIGHT, 2));
  rslt := PROJECT(diff2(keepInitial OR period>degree), ModelObs);
  RETURN rslt;
END;
