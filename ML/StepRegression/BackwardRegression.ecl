IMPORT ML;
IMPORT ML.StepRegression AS Step;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT BackwardRegression(DATASET(Types.NumericField) X,
												DATASET(Types.NumericField) Y) := MODULE(Step.StepRegression(X,Y))
											

	AIC := OLS2Use(X, Y).AIC[1].AIC;
	SHARED DATASET(StepRec) InitialRec := DATASET([{DATASET([], VarIndex), DATASET([], VarRec), Indices, AIC}], StepRec);
		
	DATASET(StepRec) Step_Backward(DATASET(StepRec) recs, INTEGER c) := FUNCTION
	
			le := recs[c];			
			Selected := SET(le.Final, number);
			
			SelectList := Indices(number IN Selected) + DATASET([{0}], VarIndex);			
			SelectRecs := PROJECT(SelectList, TRANSFORM(VarRec, SELF.VarID := LEFT.number; SELF.AIC := 0));
			
			VarRec T_Select(VarRec le) := TRANSFORM
				x_subset := X(number IN Selected AND number NOT IN [le.VarID]);
				reg := OLS2Use(x_subset, Y);
				SELF.AIC := (reg.AIC)[1].AIC;
				SELF.Op := '-';
				SELF := le;
			END;			
			
			SelectCalculated := PROJECT(SelectRecs, T_Select(LEFT));
			bestSR := SelectCalculated(AIC = MIN(SelectCalculated, AIC))[1];		
			
			Initial := le.Final;
			StepRecs := SelectCalculated;
			Final := Indices(number IN Selected AND number NOT IN [bestSR.VarID]);
			AIC := bestSR.AIC;
			
			RETURN recs + ROW({Initial, StepRecs, Final, AIC}, Steprec);
	END;

	EXPORT DATASET(StepRec) Steps := LOOP(InitialRec, 
																						COUNTER = 1 OR ROWS(LEFT)[COUNTER].Initial != ROWS(LEFT)[COUNTER].Final,
																						Step_Backward(ROWS(LEFT), COUNTER));
	
END;