IMPORT ML;
IMPORT ML.Types;
IMPORT ParameterTuning AS PT;

EXPORT DATASET(Types.NumericField) MakeRandom(DATASET(PT.Types.TuningField) tuning_ranges, INTEGER number_of_points=10) := FUNCTION
    // Generate a Random Number between lower limit and upper limit
    REAL real_random_between(ANY lower_limit, ANY upper_limit) :=  lower_limit + ((RANDOM()%100)/100) * (upper_limit - lower_limit);
    
    INTEGER number_of_parameters := COUNT(tuning_ranges);
    point_rec := RECORD
        INTEGER id;
    END;
    t_points_ds := DATASET([{0}], point_rec);
    point_rec update_t(point_rec l, INTEGER c):= TRANSFORM
        SELF.id := c;
    END;
    points_ds := NORMALIZE(t_points_ds, number_of_points, update_t(LEFT, COUNTER));
    fields_ds := NORMALIZE(t_points_ds, number_of_parameters, update_t(LEFT, COUNTER));

    combination := JOIN(points_ds, fields_ds, TRUE, TRANSFORM(Types.NumericField, 
                                                               SELF.id := LEFT.id;
                                                               SELF.number := RIGHT.id;
                                                               t_field := tuning_ranges[ RIGHT.id];
                                                               SELF.value := IF((QSTRING)t_field.id_type = 'INTEGER', 
                                                                            (INTEGER)(real_random_between(t_field.minimun_value, t_field.maximum_value)), 
                                                                            (REAL)(real_random_between(t_field.minimun_value, t_field.maximum_value)));
                                                               ), ALL);
    RETURN combination;
END;

/*
//Example
tuning_range := DATASET([
                        {1,'Integer',40, 80, 40},
                        {2, 'Integer',3, 4, 1},
                        {3, 'Real',0.9, 1.0, 0.1},
                        {4, 'Integer',28, 29, 1}
                        ],
                        PT.Types.TuningField);
                        
temp := MakeRandom(tuning_range, 16);
OUTPUT(temp);
*/