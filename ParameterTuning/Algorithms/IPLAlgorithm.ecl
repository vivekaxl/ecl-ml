IMPORT ML;
IMPORT ML.Types AS Types;
IMPORT ParameterTuning AS PT;

EXPORT IPLAlgorithm := MODULE, VIRTUAL
    SHARED PT.Types.SplitDatasetField SplitDataset(DATASET(Types.NumericField) input_data) := FUNCTION
        // Split into training and Tuning
        // Since the input is in NumericField, so total number of points would len(dataset)/total_number of fields in the dataset
        number_points := COUNT(input_data)/ MAX(input_data, number);
        class_field := MAX(input_data, number);
        spliting_rec := RECORD
            INTEGER id;
            REAL random_number;
        END;
        splitting_ds := DATASET(number_points, TRANSFORM(spliting_rec,
                                                 SELF.id := COUNTER;
                                                 SELF.random_number := RANDOM() % 100;
                                                    ));
                                                    
        // To find the indexes which would be the part of training and tuning
        t_training_indexes := splitting_ds(random_number > 50);
        training_indexes := PROJECT(t_training_indexes, TRANSFORM({spliting_rec, INTEGER new_id}, SELF.new_id := COUNTER, SELF:= LEFT));
        t_tuning_indexes := splitting_ds(random_number <= 50);
        tuning_indexes := PROJECT(t_tuning_indexes, TRANSFORM({spliting_rec, INTEGER new_id}, SELF.new_id := COUNTER, SELF:= LEFT));

        // Get the actual data
        training_ds := JOIN(training_indexes, input_data, LEFT.id = RIGHT.id, TRANSFORM(Types.NumericField, SELF.id := LEFT.new_id, SELF := RIGHT));
        tuning_ds := JOIN(tuning_indexes, input_data, LEFT.id = RIGHT.id, TRANSFORM(Types.NumericField, SELF.id := LEFT.new_id, SELF := RIGHT));

        //Split into independent and dependent
        training_indep_ds := training_ds(number <> class_field);
        training_dep_ds := PROJECT(training_ds(number = class_field), TRANSFORM(Types.NumericField, SELF.number:=1, SELF:=LEFT));

        tuning_indep_ds :=tuning_ds(number <> class_field);
        tuning_dep_ds := PROJECT(tuning_ds(number = class_field), TRANSFORM(Types.NumericField, SELF.number:=1, SELF:=LEFT));
        
        RETURN DATASET([{training_indep_ds, training_dep_ds, tuning_indep_ds, tuning_dep_ds}], PT.Types.SplitDatasetField)[1];
    END;


    SHARED DATASET(ML.Types.NumericField) GenerateTuningPoints(DATASET(PT.Types.TuningField) tuning_ranges, INTEGER number_of_points=10):= FUNCTION
        // number_of_points should not be less than 1
        // ASSERT(number_of_points>1, 'Number of points requested should be greater than 1', FAIL);
        // check if all the step_size is -1 in that case it is not grid search
        return_grid_points := IF(SUM(tuning_ranges, step_size) <> -1 * COUNT(tuning_ranges), 
                                            PT.Utils.MakeGrid(tuning_ranges),              // Generate Grid
                                            PT.Utils.MakeRandom(tuning_ranges, number_of_points)); // Generate Random Points
        RETURN return_grid_points;
    END;
    
    SHARED DATASET(ML.Types.NumericField) EvaluateParameters(DATASET(Types.NumericField) training_indep_ds, 
                                                            DATASET(Types.NumericField) training_dep_ds, 
                                                            DATASET(Types.NumericField) tuning_indep_ds, 
                                                            DATASET(Types.NumericField) tuning_dep_ds, 
                                                            DATASET(Types.NumericField) parameters, 
                                                            PT.Helper.actionPrototype algorithm):= FUNCTION
        ML.Types.NumericField runner(INTEGER c) := TRANSFORM
            SELF.id := c;
            SELF.number := 1;
            SELF.value := algorithm(training_indep_ds, training_dep_ds, tuning_indep_ds, tuning_dep_ds, parameters(id=c));
        END;
        RETURN NORMALIZE(DATASET([{0,0,0}], Types.NumericField), 
                        COUNT(parameters)/MAX(parameters, parameters.number), 
                        runner(COUNTER));
    END;
    EXPORT DATASET(Types.NumericField) Run();
END;