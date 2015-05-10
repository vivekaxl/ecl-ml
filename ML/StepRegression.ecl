/*
AIC = n * log(SSE/n) + 2 * (Total_DF - Error_DF)
AdjustedRSquared
*/

IMPORT ML;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT StepRegression(DATASET(Types.NumericField) X,
                      DATASET(Types.NumericField) Y,
											UNSIGNED1 maxN) := MODULE
											
	VarIndex := RECORD
		UNSIGNED1 number;
	END;
	
	//Use Normalize
	DATASET(VarIndex) Indices := NORMALIZE(DATASET([{0}], VarIndex), maxN, TRANSFORM(VarIndex, SELF.number := COUNTER));
	
	StepRec := RECORD
		DATASET(VarIndex) Selected := DATASET([], VarIndex);
		REAL AIC := 0;
		UNSIGNED1 numVar := 0;
	END;
	
	DATASET(StepRec) EmptyRecs := PROJECT(Indices, TRANSFORM(StepRec, SELF.numVar := LEFT.number; 
																									SELF.AIC := 0; 
																									SELF.Selected := DATASET([], VarIndex)
																					));
																					
	StepRec Step_Trans(StepRec le, StepRec ri) := TRANSFORM
			Selected := SET(le.Selected, number);
			NotChosen := Indices(number NOT IN Selected);
			R := RECORD
				UNSIGNED1 VarID;
				REAL AIC := 0;
			END;
			
			ChooseRecs := PROJECT(NotChosen, TRANSFORM(R, SELF.VarID := LEFT.number; SELF.AIC := 0));
			R T(R le) := TRANSFORM
				x_subset := X(number IN (Selected + [le.VarID]));
				reg := OLS2Use(x_subset, Y);
				SELF.AIC := (reg.AIC)[1].AIC;
				SELF := le;
			END;
			
			Calculated := PROJECT(ChooseRecs, T(LEFT));
			bestRec := Calculated(AIC = MIN(Calculated, AIC))[1];
			
			SELF.Selected := le.Selected + DATASET([{bestRec.VarID}], VarIndex);
			SELF.AIC := bestRec.AIC;
			SELF.numVar := ri.numVar;
	END;

	EXPORT DATASET(StepRec) FillRecs := ITERATE(EmptyRecs, Step_Trans(LEFT, RIGHT));

END;
