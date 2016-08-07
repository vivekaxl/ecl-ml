IMPORT ML;
EXPORT Types := MODULE
        EXPORT TuningField := RECORD
            UNSIGNED4 parameter_id;
            STRING id_type; // 'Integer' or 'Real'
            REAL8 minimun_value;
            REAL8 maximum_value;
            REAL8 step_size := -1; // -1 for Random               
        END;
        EXPORT SplitDatasetField := RECORD
            DATASET(ML.Types.NumericField) IndepTrain;
            DATASET(ML.Types.NumericField) DepTrain;
            DATASET(ML.Types.NumericField) IndepTest;
            DATASET(ML.Types.NumericField) DepTest;
        END;
END;

