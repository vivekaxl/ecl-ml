IMPORT ML;
IMPORT ML.StepRegression AS Step;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT ForwardRegression(DATASET(Types.NumericField) X,
			DATASET(Types.NumericField) Y) := MODULE(Step.StepRegression(X,Y))
											

	AIC := OLS2Use(X(number IN [0]), Y).AIC[1].AIC;
	SHARED DATASET(StepRec) InitialStep := DATASET([{DATASET([], Parameter), DATASET([], ParamRec), DATASET([], Parameter), AIC}], StepRec);
		
	DATASET(StepRec) Step_Forward(DATASET(StepRec) recs, INTEGER c) := FUNCTION
	
		le := recs[c];			
		Selected := SET(le.Final, number);
					
		NotChosen := Indices(number NOT IN Selected) + DATASET([{0}], Parameter);
		ChooseRecs := PROJECT(NotChosen, TRANSFORM(ParamRec, SELF.ParamNum := LEFT.number; SELF.AIC := 0));
		 
		DATASET(ParamRec) T_Choose(DATASET(ParamRec) precs, INTEGER c) := FUNCTION
			chooser := NotChosen[c];
			x_subset := X(number IN (Selected + [chooser.number]));
			reg := OLS2Use(x_subset, Y);
			RSS := (reg.Anova)[1].Error_SS;
			AIC := (reg.AIC)[1].AIC;
			Op := '+';
			RETURN precs + ROW({Op, chooser.number, RSS, AIC}, ParamRec);
		END;		
		
		ChooseCalculated := SORT(LOOP(DATASET([], ParamRec),COUNT(NotChosen), T_Choose(ROWS(LEFT), COUNTER)), AIC);
		bestCR := ChooseCalculated[1];			
		
		Initial := le.Final;
		StepRecs := ChooseCalculated;
		Final := Indices(number IN Selected OR number IN [bestCR.ParamNum]);
		AIC := bestCR.AIC;
			
		RETURN recs + ROW({Initial, StepRecs, Final, AIC}, Steprec);
	END;

	EXPORT DATASET(StepRec) Steps := LOOP(InitialStep, 
						COUNTER = 1 OR ROWS(LEFT)[COUNTER].Initial != ROWS(LEFT)[COUNTER].Final,
						Step_Forward(ROWS(LEFT), COUNTER));
	
END;