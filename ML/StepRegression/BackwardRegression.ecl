IMPORT ML;
IMPORT ML.StepRegression AS Step;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT BackwardRegression(DATASET(Types.NumericField) X,
			DATASET(Types.NumericField) Y) := MODULE(Step.StepRegression(X,Y))
											

	AIC := OLS2Use(X, Y).AIC[1].AIC;
	SHARED DATASET(StepRec) InitialStep := DATASET([{DATASET([], Parameter), DATASET([], ParamRec), Indices, AIC}], StepRec);
		
	DATASET(StepRec) Step_Backward(DATASET(StepRec) recs, INTEGER c) := FUNCTION
	
		le := recs[c];			
		Selected := SET(le.Final, number);
		
		SelectList := Indices(number IN Selected) + DATASET([{0}], Parameter);			
		SelectRecs := PROJECT(SelectList, TRANSFORM(ParamRec, SELF.ParamNum := LEFT.number; SELF.AIC := 0));
		
		ParamRec T_Select(ParamRec le) := TRANSFORM
			x_subset := X(number IN Selected AND number NOT IN [le.ParamNum]);
			reg := OLS2Use(x_subset, Y);
			SELF.RSS := (reg.Anova)[1].Error_SS;
			SELF.AIC := (reg.AIC)[1].AIC;
			SELF.Op := '-';
			SELF := le;
		END;			
		
		SelectCalculated := SORT(PROJECT(SelectRecs, T_Select(LEFT)), AIC);
		bestSR := SelectCalculated[1];		
		
		Initial := le.Final;
		StepRecs := SelectCalculated;
		Final := Indices(number IN Selected AND number NOT IN [bestSR.ParamNum]);
		AIC := bestSR.AIC;
		
		RETURN recs + ROW({Initial, StepRecs, Final, AIC}, Steprec);
	END;

	EXPORT DATASET(StepRec) Steps := LOOP(InitialStep, 		
						COUNTER = 1 OR ROWS(LEFT)[COUNTER].Initial != ROWS(LEFT)[COUNTER].Final,
						Step_Backward(ROWS(LEFT), COUNTER));
	
END;