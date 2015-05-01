IMPORT ML;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT StepRegression(DATASET(Types.NumericField) X,
                      DATASET(Types.NumericField) Y) := MODULE
											
	VarIndex := RECORD
		UNSIGNED1 number;
	END;
	
	DATASET(VarIndex) Indices := PROJECT(DEDUP(X, number, ALL), TRANSFORM(VarIndex, SELF.number := LEFT.number));
	
	StepRec := RECORD
		DATASET(VarIndex) Selected := DATASET([], VarIndex);
		REAL R2 := 0;
		UNSIGNED1 numVar := 0;
	END;
	
	DATASET(StepRec) EmptyRecs := PROJECT(Indices, TRANSFORM(StepRec, SELF.numVar := LEFT.number; 
																									SELF.R2 := 0; 
																									SELF.Selected := DATASET([], VarIndex)
																					));
																					
	StepRec Step_Trans(StepRec le, StepRec ri) := TRANSFORM
			Selected := SET(le.Selected, number);
			NotChosen := Indices(number NOT IN Selected);
			R := RECORD
				UNSIGNED1 VarID;
				REAL R2 := 0;
			END;
			
			ChooseRecs := PROJECT(NotChosen, TRANSFORM(R, SELF.VarID := LEFT.number; SELF.R2 := 0));
			R T(R le) := TRANSFORM
				x_subset := X(number IN (Selected + [le.VarID]));
				reg := OLS2Use(x_subset, Y);
				SELF.r2 := (reg.RSquared)[1].rsquared;
				SELF := le;
			END;
			
			Calculated := PROJECT(ChooseRecs, T(LEFT));
			bestRec := Calculated(R2 = MAX(Calculated, R2))[1];
			
			SELF.Selected := le.Selected + DATASET([{bestRec.VarID}], VarIndex);
			SELF.R2 := bestRec.R2;
			SELF.numVar := ri.numVar;
	END;

	EXPORT DATASET(StepRec) FillRecs := ITERATE(EmptyRecs, Step_Trans(LEFT, RIGHT));

END;
