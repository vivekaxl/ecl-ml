IMPORT ML;
IMPORT ML.Types;
IMPORT ParameterTuning AS PT;


EXPORT GridSearch(DATASET(Types.NumericField) input_data, DATASET(PT.Types.TuningField) tuning_ranges, PT.Helper.actionPrototype algorithm=PT.Helper.DummyObjectiveFunction):= MODULE(PT.Algorithms.IPLAlgorithm)
    EXPORT DATASET(Types.NumericField) Run() := FUNCTION
        split := SplitDataset(input_data);
        training_indep_ds := split.IndepTrain;
        training_dep_ds := split.DepTrain;
        tuning_indep_ds := split.IndepTest;
        tuning_dep_ds := split.DepTest;
        
        grid := GenerateTuningPoints(tuning_ranges)[1..32];
        results := EvaluateParameters(training_indep_ds, training_dep_ds, tuning_indep_ds, tuning_dep_ds, grid, algorithm);
        best_performer := SORT(results, -value)[1].id;
        RETURN grid(id=best_performer);
    END;
END;


