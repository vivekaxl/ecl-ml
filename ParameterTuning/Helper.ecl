IMPORT ML;
IMPORT ML.Types;
EXPORT Helper := MODULE
    EXPORT REAL RandomForestClassfier(DATASET(ML.Types.NumericField) trainIndepData, DATASET(ML.Types.NumericField) trainDepData, DATASET(ML.Types.NumericField) testIndepData, DATASET(ML.Types.NumericField) testDepData, DATASET(ML.Types.NumericField) Parameters):= FUNCTION
            treeNum := Parameters(number=1)[1].value;
            fsNum :=  Parameters(number=2)[1].value;
            Purity := Parameters(number=3)[1].value; 
            maxLevel := Parameters(number=4)[1].value;
            learner := ML.Classify.RandomForest(treeNum, fsNum, Purity, maxLevel);  
            result := learner.LearnD(ML.Discretize.ByRounding(trainIndepData),  ML.Discretize.ByRounding(trainDepData)); 
            model:= learner.model(result);  
            class:= learner.classifyD( ML.Discretize.ByRounding(testIndepData), result); 
            performance:= ML.Classify.Compare( ML.Discretize.ByRounding(testDepData), class);
            return performance.Accuracy[1].accuracy;
    END;

    EXPORT REAL DecisionTreeClassfier(DATASET(ML.Types.NumericField) trainIndepData, DATASET(ML.Types.NumericField) trainDepData, DATASET(ML.Types.NumericField) testIndepData, DATASET(ML.Types.NumericField) testDepData, DATASET(ML.Types.NumericField) Parameters):= FUNCTION
            Depth := Parameters(number=1)[1].value;
            Purity := Parameters(number=2)[1].value;
            learner := ML.Classify.DecisionTree.GiniImpurityBased(Depth, Purity);  
            result := learner.LearnD( ML.Discretize.ByRounding(trainIndepData), ML.Discretize.ByRounding(trainDepData)); 
            model:= learner.model(result);  
            class:= learner.classifyD(ML.Discretize.ByRounding(testIndepData), result); 
            performance:= ML.Classify.Compare(ML.Discretize.ByRounding(testDepData), class);
            return performance.Accuracy[1].accuracy;
    END;

    EXPORT REAL DummyObjectiveFunction(DATASET(ML.Types.NumericField) trainIndepData, DATASET(ML.Types.NumericField) trainDepData, DATASET(ML.Types.NumericField) testIndepData, DATASET(ML.Types.NumericField) testDepData, DATASET(ML.Types.NumericField) Parameters) := FUNCTION
            RETURN SUM(Parameters, Parameters.value);
    END;

    EXPORT REAL actionPrototype(DATASET(ML.Types.NumericField) trainIndepData, DATASET(ML.Types.NumericField) trainDepData, DATASET(ML.Types.NumericField) testIndepData, DATASET(ML.Types.NumericField) testDepData, DATASET(ML.Types.NumericField) Parameters) := 0;
END;

