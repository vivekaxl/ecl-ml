IMPORT ML;
IMPORT ML.StepRegression AS Step;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT ForwardRegression(DATASET(Types.NumericField) X,
												DATASET(Types.NumericField) Y) := MODULE(Step.StepRegression(X,Y))
											

	SHARED DATASET(StepRec) EmptyRecs := PROJECT(Indices, TRANSFORM(StepRec, SELF.AIC := 0; 
																									SELF.Final := DATASET([], VarIndex);
																									SELF.StepRecs := DATASET([], VarRec);
																									SELF.Initial := DATASET([], VarIndex)
																					));
		
	//Main Regression Transform		
	StepRec Step_Trans_Forward(StepRec le, StepRec ri) := TRANSFORM
	
			//Variables Selected in Previous Best Model
			Selected := SET(le.Final, number);
			//Variables still left to add + <None>
			NotChosen := Indices(number NOT IN Selected) + DATASET([{0}], VarIndex);			
			ChooseRecs := PROJECT(NotChosen, TRANSFORM(VarRec, SELF.VarID := LEFT.number; SELF.AIC := 0));
			
			//Create model after adding each variable from NotChosen 
			VarRec T(VarRec le) := TRANSFORM
				x_subset := X(number IN (Selected + [le.VarID]));
				reg := OLS2Use(x_subset, Y);
				SELF.AIC := (reg.AIC)[1].AIC;
				SELF := le;
			END;			
			Calculated := PROJECT(ChooseRecs, T(LEFT));
			
			//Choose best Model among models calculated
			bestRec := Calculated(AIC = MIN(Calculated, AIC))[1];
			
			//Add Record for Best Model obtained in this Step
			SELF.Initial := le.Final;
			SELF.StepRecs := Calculated;
			SELF.Final := le.Final + DATASET([{bestRec.VarID}], VarIndex);
			SELF.AIC := bestRec.AIC;
	END;

	//Dataset of All Steps Taken
	EXPORT DATASET(StepRec) FillRecs := ITERATE(EmptyRecs, Step_Trans_Forward(LEFT, RIGHT));
	
END;