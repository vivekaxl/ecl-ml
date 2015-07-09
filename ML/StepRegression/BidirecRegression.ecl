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
	SHARED DATASET(StepRec) InitialStep := DATASET([{DATASET([], Parameter), DATASET([], ParamRec), InputVars, AIC}], StepRec);
		
	DATASET(StepRec) Step_Bidirec(DATASET(StepRec) recs, INTEGER c) := FUNCTION
	
		le := recs[c];			
		Selected := SET(le.Final, number);
			
		SelectList := Indices(number IN Selected);			
		NotChosen := Indices(number NOT IN Selected) + DATASET([{0}], Parameter);
		SelectRecs := PROJECT(SelectList, TRANSFORM(ParamRec, SELF.ParamNum := LEFT.number; SELF.AIC := 0));
		ChooseRecs := PROJECT(NotChosen, TRANSFORM(ParamRec, SELF.ParamNum := LEFT.number; SELF.AIC := 0));
		 
		ParamRec T_Select(ParamRec le) := TRANSFORM
			x_subset := X(number IN Selected AND number NOT IN [le.ParamNum]);
			reg := OLS2Use(x_subset, Y);
			SELF.RSS := (reg.Anova)[1].Error_SS;
			SELF.AIC := (reg.AIC)[1].AIC;
			SELF.Op := '-';
			SELF := le;
		END;			
		
		ParamRec T_Choose(ParamRec le) := TRANSFORM
			x_subset := X(number IN (Selected + [le.ParamNum]));
			reg := OLS2Use(x_subset, Y);
			SELF.RSS := (reg.Anova)[1].Error_SS;
			SELF.AIC := (reg.AIC)[1].AIC;
			SELF.Op := '+';
			SELF := le;
		END;		
			
		SelectCalculated := SORT(PROJECT(SelectRecs, T_Select(LEFT)), AIC);
		ChooseCalculated := SORT(PROJECT(ChooseRecs, T_Choose(LEFT)), AIC);
		bestSR := SelectCalculated[1];
		bestCR := ChooseCalculated[1];			
		
		Initial := le.Final;
		StepRecs := MERGE(SelectCalculated,ChooseCalculated,SORTED(AIC));
		Final := IF(bestSR.AIC < bestCR.AIC, Indices(number IN Selected AND number NOT IN [bestSR.ParamNum]),
						Indices(number IN Selected OR number IN [bestCR.ParamNum]));
		AIC := IF(bestSR.AIC < bestCR.AIC, bestSR.AIC, bestCR.AIC);
		
		RETURN recs + ROW({Initial, StepRecs, Final, AIC}, Steprec);
	END;

	EXPORT DATASET(StepRec) Steps := LOOP(InitialStep, 
						COUNTER = 1 OR ROWS(LEFT)[COUNTER].Initial != ROWS(LEFT)[COUNTER].Final,
						Step_Bidirec(ROWS(LEFT), COUNTER));
	
END;