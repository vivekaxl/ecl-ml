IMPORT ML;
IMPORT ML.StepRegression AS Step;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT BidirecRegression(DATASET(Types.NumericField) X,
												DATASET(Types.NumericField) Y,
												DATASET({UNSIGNED4 number}) InputVars) := MODULE(Step.StepRegression(X,Y))
											
	AIC := OLS2Use(X(number IN SET(InputVars, number)), Y).AIC[1].AIC;
	SHARED DATASET(StepRec) InitialRec := DATASET([{DATASET([], VarIndex), DATASET([], VarRec), InputVars, AIC}], StepRec);
		
	DATASET(StepRec) Step_Bidirec(DATASET(StepRec) recs, INTEGER c) := FUNCTION
	
			le := recs[c];			
			Selected := SET(le.Final, number);
			
			SelectList := Indices(number IN Selected);			
			NotChosen := Indices(number NOT IN Selected) + DATASET([{0}], VarIndex);
			SelectRecs := PROJECT(SelectList, TRANSFORM(VarRec, SELF.VarID := LEFT.number; SELF.AIC := 0));
			ChooseRecs := PROJECT(NotChosen, TRANSFORM(VarRec, SELF.VarID := LEFT.number; SELF.AIC := 0));
			 
			VarRec T_Select(VarRec le) := TRANSFORM
				x_subset := X(number IN Selected AND number NOT IN [le.VarID]);
				reg := OLS2Use(x_subset, Y);
				SELF.AIC := (reg.AIC)[1].AIC;
				SELF.Op := '-';
				SELF := le;
			END;			
			
			VarRec T_Choose(VarRec le) := TRANSFORM
				x_subset := X(number IN (Selected + [le.VarID]));
				reg := OLS2Use(x_subset, Y);
				SELF.AIC := (reg.AIC)[1].AIC;
				SELF.Op := '+';
				SELF := le;
			END;		
			
			SelectCalculated := PROJECT(SelectRecs, T_Select(LEFT));
			ChooseCalculated := PROJECT(ChooseRecs, T_Choose(LEFT));
			bestSR := SelectCalculated(AIC = MIN(SelectCalculated, AIC))[1];
			bestCR := ChooseCalculated(AIC = MIN(ChooseCalculated, AIC))[1];			
			
			Initial := IF(c = 1, InputVars, le.Final);
			StepRecs := SelectCalculated + ChooseCalculated;
			Final := IF(bestSR.AIC < bestCR.AIC, Indices(number IN Selected AND number NOT IN [bestSR.VarID]),
																								Indices(number IN Selected OR number IN [bestCR.VarID]));
			AIC := IF(bestSR.AIC < bestCR.AIC, bestSR.AIC, bestCR.AIC);
			
			RETURN recs + ROW({Initial, StepRecs, Final, AIC}, Steprec);
	END;

	EXPORT DATASET(StepRec) Steps := LOOP(InitialRec, 
																						ROWS(LEFT)[COUNTER].Initial != ROWS(LEFT)[COUNTER].Final,
																						Step_Bidirec(ROWS(LEFT), COUNTER));
	
END;