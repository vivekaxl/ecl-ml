//Produce a series from a differenced series of degree 0, 1, or 2
IMPORT TS;
ModelObs := TS.Types.ModelObs;
Spec := TS.Types.Ident_Spec;
EXPORT AccumSeries(DATASET(TS.Types.ModelObs) obs,
                        DATASET(TS.Types.Ident_Spec) degree) := FUNCTION
  ObsRec := RECORD(TS.Types.ModelObs)
    UNSIGNED2 degree;
  END;
  ObsRec markDegree(ModelObs obs, Spec sp) := TRANSFORM
    SELF.degree := sp.degree;
    SELF := obs;
  END;
  marked := JOIN(obs, degree, LEFT.model_id=RIGHT.model_id,
                 markDegree(LEFT, RIGHT), LOOKUP);
  ObsRec accumObs(ObsRec prev, ObsRec curr, UNSIGNED2 pass) := TRANSFORM
    no_accum := pass > curr.degree OR prev.model_id <> curr.model_id;
    SELF.dependent := IF(no_accum, curr.dependent, curr.dependent+prev.dependent);
    SELF := curr;
  END;
  accum1 := ITERATE(marked, accumObs(LEFT, RIGHT, 1));
  accum2 := ITERATE(accum1, accumObs(LEFT, RIGHT, 2));
  rslt := PROJECT(accum2, ModelObs);
  RETURN rslt;
END;
