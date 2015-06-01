IMPORT ML;
IMPORT ML.StepRegression AS Step;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT ForwardRegression(DATASET(Types.NumericField) X,
												DATASET(Types.NumericField) Y) := MODULE(Step.StepRegression(X,Y))
											

	AIC := OLS2Use(X(number IN [0]), Y).AIC[1].AIC;
	SHARED DATASET(StepRec) InitialRec := DATASET([{DATASET([], VarIndex), DATASET([], VarRec), DATASET([], VarIndex), AIC}], StepRec);
		
	DATASET(StepRec) Step_Forward(DATASET(StepRec) recs, INTEGER c) := FUNCTION
	
			le := recs[c];			
			Selected := SET(le.Final, number);
						
			NotChosen := Indices(number NOT IN Selected) + DATASET([{0}], VarIndex);
			ChooseRecs := PROJECT(NotChosen, TRANSFORM(VarRec, SELF.VarID := LEFT.number; SELF.AIC := 0));
			 
			VarRec T_Choose(VarRec le) := TRANSFORM
				x_subset := X(number IN (Selected + [le.VarID]));
				reg := OLS2Use(x_subset, Y);
				SELF.AIC := (reg.AIC)[1].AIC;
				SELF.Op := '+';
				SELF := le;
			END;		
			
			ChooseCalculated := PROJECT(ChooseRecs, T_Choose(LEFT));
			bestCR := ChooseCalculated(AIC = MIN(ChooseCalculated, AIC))[1];			
			
			Initial := le.Final;
			StepRecs := ChooseCalculated;
			Final := Indices(number IN Selected OR number IN [bestCR.VarID]);
			AIC := bestCR.AIC;
			
			RETURN recs + ROW({Initial, StepRecs, Final, AIC}, Steprec);
	END;

	EXPORT DATASET(StepRec) Steps := LOOP(InitialRec, 
																						COUNTER = 1 OR ROWS(LEFT)[COUNTER].Initial != ROWS(LEFT)[COUNTER].Final,
																						Step_Forward(ROWS(LEFT), COUNTER));
	
END;