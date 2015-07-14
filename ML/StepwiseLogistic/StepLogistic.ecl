IMPORT ML;
IMPORT ML.Types AS Types;
IMPORT ML.Utils AS Utils;
IMPORT ML.Classify AS Classify;
IMPORT ML.StepwiseLogistic.TypesSL AS TypesSL;
IMPORT Std.Str;

EXPORT StepLogistic(REAL8 Ridge=0.00001, REAL8 Epsilon=0.000000001, UNSIGNED2 MaxIter=200) 
																				:= MODULE(Classify.Default)
																				
	SHARED LogReg := Classify.Logistic_sparse(Ridge, Epsilon, MaxIter);
	SHARED Parameter := TypesSL.Parameter;
	SHARED ParamRec := TypesSL.ParamRec;
	SHARED StepRec := TypesSL.StepRec;
	
	SHARED findAIC(DATASET(Types.NumericField) X,DATASET(Types.DiscreteField) Y, DATASET(Types.NumericField) mod) := FUNCTION
			dev := LogReg.DevianceC(X, Y, mod);
			RETURN dev.AIC[1].AIC;
	END;
	
	EXPORT ForwardReg(DATASET(Types.NumericField) X,DATASET(Types.DiscreteField) Y) := MODULE
	
		SHARED DATASET(Parameter) Indices := NORMALIZE(DATASET([{0}], Parameter), COUNT(ML.FieldAggregates(X).Cardinality), 
							TRANSFORM(Parameter, SELF.number := COUNTER));
		InitMod := LogReg.LearnC(X(number IN [0]), Y);
		AIC := findAIC(X(number IN [0]), Y, InitMod);
		
		SHARED DATASET(StepRec) InitialStep := DATASET([{DATASET([], Parameter), DATASET([], ParamRec), DATASET([], Parameter), AIC}], StepRec);
		
		DATASET(StepRec) Step_Forward(DATASET(StepRec) recs, INTEGER c) := FUNCTION
	
			le := recs[c];			
			Selected := SET(le.Final, number);
						
			NotChosen := Indices(number NOT IN Selected) + DATASET([{0}], Parameter);
			NumChosen := COUNT(NotChosen);
			 
			DATASET(ParamRec) T_Choose(DATASET(ParamRec) precs, INTEGER paramNum) := FUNCTION
				x_subset := X(number IN (Selected + [paramNum]));
				RebaseX := Utils.RebaseNumericField(x_subset);
				X_Map := RebaseX.Mapping(1);
				X_0 := RebaseX.ToNew(X_Map);
				reg := LogReg.LearnC(X_0, Y);
				AIC := findAIC(IF(EXISTS(X_0), X_0, X), Y, reg);
				Op := '+';
				RETURN precs + ROW({Op, paramNum, AIC}, ParamRec);
			END;		
			
			ChooseCalculated := LOOP(DATASET([], ParamRec), COUNTER <= NumChosen, T_Choose(ROWS(LEFT), NotChosen[COUNTER].number));
			bestCR := TOPN(ChooseCalculated, 1, AIC);			
			
			Initial := le.Final;
			StepRecs := ChooseCalculated;
			Final := Indices(number IN Selected OR number IN [bestCR[1].ParamNum]);
			AIC := bestCR[1].AIC;
				
			RETURN recs + ROW({Initial, StepRecs, Final, AIC}, Steprec);
		END;
		
		EXPORT DATASET(StepRec) Steps := LOOP(InitialStep, 
						COUNTER = 1 OR ROWS(LEFT)[COUNTER].Initial != ROWS(LEFT)[COUNTER].Final,
						Step_Forward(ROWS(LEFT), COUNTER));
		
		BestStep := Steps[COUNT(Steps)];
		var_subset := SET(BestStep.Final, number);
		x_subset := X(number IN var_subset);
		RebaseX := Utils.RebaseNumericField(x_subset);
		X_Map := RebaseX.Mapping(1);
		X_0 := RebaseX.ToNew(X_Map);
		EXPORT mod := LogReg.LearnC(X_0, Y);
	END;
	
	EXPORT LearnCS(DATASET(Types.NumericField) Indep,DATASET(Types.DiscreteField) Dep) := ForwardReg(Indep,Dep).mod;
	EXPORT LearnC(DATASET(Types.NumericField) Indep,DATASET(Types.DiscreteField) Dep) := LearnCConcat(Indep,Dep,LearnCS);
END;