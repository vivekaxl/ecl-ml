IMPORT ML;
IMPORT ML.StepRegression AS Step;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT BackwardRegression(DATASET(Types.NumericField) X,
												DATASET(Types.NumericField) Y) := MODULE(Step.StepRegression(X,Y))
											

	SHARED DATASET(StepRec) EmptyRecs := PROJECT(Indices, TRANSFORM(StepRec, SELF.AIC := 0; 
																												SELF.Initial := DATASET([], VarIndex);
																												SELF.StepRecs := DATASET([], VarRec);
																												SELF.Final := DATASET([], VarIndex)));
		
	StepRec Step_Trans_Forward(StepRec le, StepRec ri, INTEGER c) := TRANSFORM, SKIP(COUNT(le.Initial) = COUNT(le.Final) AND c > 1)
	
			Selected := IF(c = 1, SET(Indices, number), SET(le.Final, number));
			SelectList := Indices(number in Selected) + DATASET([{0}], VarIndex);			
			ChooseRecs := PROJECT(SelectList, TRANSFORM(VarRec, SELF.VarID := LEFT.number; SELF.AIC := 0));
			 
			VarRec T(VarRec le) := TRANSFORM
				x_subset := X(number IN Selected AND number NOT IN [le.VarID]);
				reg := OLS2Use(x_subset, Y);
				SELF.AIC := (reg.AIC)[1].AIC;
				SELF := le;
			END;			
			Calculated := PROJECT(ChooseRecs, T(LEFT));
			
			bestRec := Calculated(AIC = MIN(Calculated, AIC))[1];
			SELF.Initial := IF(c = 1, Indices, le.Final);
			SELF.StepRecs := Calculated;
			SELF.Final := Indices(number IN Selected AND number NOT IN [bestRec.VarID]);
			SELF.AIC := bestRec.AIC;
	END;

	EXPORT DATASET(StepRec) FillRecs := ITERATE(EmptyRecs, Step_Trans_Forward(LEFT, RIGHT, COUNTER));
	
END;