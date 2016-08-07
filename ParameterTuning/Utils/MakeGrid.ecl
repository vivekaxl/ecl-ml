IMPORT ML;
IMPORT ML.Types;
IMPORT ParameterTuning AS PT;
EXPORT DATASET(Types.NumericField) MakeGrid(DATASET(PT.Types.TuningField) tuning_ranges, INTEGER number_of_points=0) := FUNCTION
    rec_tuning_field := {PT.Types.TuningField, INTEGER no_count};

    count_tuning_ranges := PROJECT(tuning_ranges, 
                        TRANSFORM(rec_tuning_field, 
                        SELF.no_count := 1 + ROUNDUP((REAL)(LEFT.maximum_value - LEFT.minimun_value)/(REAL)LEFT.step_size);
                        SELF := LEFT));

    grid_rec := {INTEGER id, SET OF REAL value};

    grid_rec grid_transform(rec_tuning_field R, INTEGER c) := TRANSFORM
        SELF.value := [R.minimun_value + ((c-1) * R.step_size)];
        SELF.id := R.parameter_id;
    END;
    raw_grid := NORMALIZE(count_tuning_ranges, LEFT.no_count, grid_transform(LEFT, COUNTER));

    grid_rec temp_gen(DATASET(grid_rec) anyds, INTEGER c):= FUNCTION
        RETURN IF(c=1,
                anyds + PROJECT(anyds(id=1), TRANSFORM(grid_rec, SELF.id := LEFT.id + 100; SELF := LEFT)),
                anyds + JOIN(anyds(id=99+c), anyds(id=c), TRUE, TRANSFORM(grid_rec, 
                                                            SELF.id := LEFT.id + 1;
                                                            SELF.value := LEFT.value + RIGHT.value
                                                            ), ALL));
    END;

    grid := PROJECT(
                    LOOP(raw_grid, 
                    COUNTER<=COUNT(tuning_ranges), 
                    temp_gen(ROWS(LEFT), COUNTER))(id= 100 + COUNT(tuning_ranges)),
                    TRANSFORM(grid_rec, SELF.id := COUNTER, SELF:= LEFT));

    Types.NumericField convert_to_numericfield(grid_rec R, INTEGER c) := TRANSFORM
        SELF.id := R.id;
        SELF.number := c;
        SELF.value := R.value[c];
    END;
    RETURN NORMALIZE(grid, COUNT(LEFT.value), convert_to_numericfield(LEFT, COUNTER));
END;