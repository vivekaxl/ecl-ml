/*
Perform Forward Stepwise Regression
*/

IMPORT ML;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT Std.Str;
OLS2Use := ML.Regression.Sparse.OLS_LU;

EXPORT StepRegression(DATASET(Types.NumericField) X,
                      DATASET(Types.NumericField) Y) := MODULE, VIRTUAL
											
	SHARED VarIndex := RECORD
		UNSIGNED1 number;
	END;
	
	//Numeric Index of all the variables in X
	SHARED DATASET(VarIndex) Indices := NORMALIZE(DATASET([{0}], VarIndex), 
																					COUNT(ML.FieldAggregates(X).Cardinality), 
																					TRANSFORM(VarIndex, SELF.number := COUNTER));
	
	//Record for Each variable tested at every Step
	SHARED VarRec := RECORD
		//Variable's Numeric Index
		UNSIGNED1 VarID;
		//AIC obtained after adding this Variable
		REAL AIC := 0;
	END;
	
	//Record for Each Step Taken
	EXPORT StepRec := RECORD
		//Variables in model before in this Step
		DATASET(VarIndex) Initial := DATASET([], VarIndex);
		//Records of Steps Taken
		DATASET(VarRec) StepRecs := DATASET([], VarRec);
		//Selected Variables at end of this Step
		DATASET(VarIndex) Final := DATASET([], VarIndex);
		//Best AIC obtained at End of this Step
		REAL AIC := 0;
	END;
	
	//Dataset of All Steps Taken
	EXPORT DATASET(StepRec) FillRecs;
	
	//Choose best Model among all Steps
	BestRec := FillRecs(AIC = MIN(FillRecs, AIC))[1];
	var_subset := SET(BestRec.Final, number);
	x_subset := X(number IN var_subset);
	EXPORT BestModel := OLS2Use(x_subset, Y);
	
END;
