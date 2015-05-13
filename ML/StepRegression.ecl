/*
Perform Forward Stepwise Regression
*/

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
	
	//Numeric Index of all the variables in X
	DATASET(VarIndex) Indices := NORMALIZE(DATASET([{0}], VarIndex), 
																					COUNT(ML.FieldAggregates(X).Cardinality), 
																					TRANSFORM(VarIndex, SELF.number := COUNTER));
	
	//Record for Each variable tested at every Step
	VarRec := RECORD
		//Variable's Numeric Index
		UNSIGNED1 VarID;
		//AIC obtained after adding this Variable
		REAL AIC := 0;
	END;
	
	//Record for Each Step Taken
	StepRec := RECORD
		//Variables Tested in this Step
		DATASET(VarRec) StepRecs := DATASET([], VarRec);
		//Selected Variables at end of this Step
		DATASET(VarIndex) Selected := DATASET([], VarIndex);
		//Best AIC obtained at End of this Step
		REAL AIC := 0;
		//Number of Variables added at end of this Step
		UNSIGNED1 numVar := 0;
	END;
	
	DATASET(StepRec) EmptyRecs := PROJECT(Indices, TRANSFORM(StepRec, SELF.numVar := LEFT.number; 
																									SELF.AIC := 0; 
																									SELF.Selected := DATASET([], VarIndex);
																									SELF.StepRecs := DATASET([], VarRec)
																					));
		
	//Main Regression Transform		
	StepRec Step_Trans(StepRec le, StepRec ri) := TRANSFORM
	
			//Variables Selected in Previous Best Model
			Selected := SET(le.Selected, number);
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
			SELF.StepRecs := Calculated;
			SELF.Selected := le.Selected + DATASET([{bestRec.VarID}], VarIndex);
			SELF.AIC := bestRec.AIC;
			SELF.numVar := ri.numVar;
	END;

	//Dataset of All Steps Taken
	EXPORT DATASET(StepRec) FillRecs := ITERATE(EmptyRecs, Step_Trans(LEFT, RIGHT));
	
	//Choose best Model among all Steps
	BestRec := FillRecs(AIC = MIN(FillRecs, AIC))[1];
	var_subset := SET(BestRec.Selected, number);
	x_subset := X(number IN var_subset);
	EXPORT BestModel := OLS2Use(x_subset, Y);
	
END;
