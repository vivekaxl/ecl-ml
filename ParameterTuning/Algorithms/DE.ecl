IMPORT ML;
IMPORT ML.Types;
IMPORT ParameterTuning AS PT;

EXPORT DE(DATASET(Types.NumericField) input_data, DATASET(PT.Types.TuningField) tuning_ranges, PT.Helper.actionPrototype algorithm=PT.Helper.DummyObjectiveFunction, INTEGER no_of_generation=10, REAL CF=0.75, REAL F=0.3):= MODULE(PT.Algorithms.IPLAlgorithm)
    SHARED REAL mutation(REAL a, REAL b, REAL c, INTEGER field_no):= FUNCTION
                param := tuning_ranges(parameter_id=field_no)[1];
                maxval := param.maximum_value;
                minval := param.minimun_value;
                RETURN IF(param.id_type='INTEGER', 
                        (INTEGER)MAX(minval, MIN((a + F * (b - c)), maxval)), 
                        MAX(minval, MIN((a + F * (b - c)), maxval))
                        );
    END;
    
    SHARED REAL real_random_between(ANY lower_limit, ANY upper_limit) :=  lower_limit + ((RANDOM()%100)/100) * (upper_limit - lower_limit);
    
    SHARED DATASET(Types.NumericField) GenerateNew(DATASET(Types.NumericField) a, DATASET(Types.NumericField) b, DATASET(Types.NumericField) c, DATASET(Types.NumericField) existing_population):= FUNCTION
        no_of_fields := COUNT(a);
        ML.Types.NumericField crossover_op(INTEGER field_no):= TRANSFORM
            SELF.id := a(number=field_no)[1].id;
            SELF.number := a(number=field_no)[1].number;
            SELF.value := IF(real_random_between(0, 1) < CF, mutation(a(number=field_no)[1].value, 
                                                                       b(number=field_no)[1].value, 
                                                                       c(number=field_no)[1].value,
                                                                       field_no), 
                                                              a[field_no].value);
        END;
        RETURN existing_population + NORMALIZE(DATASET([{0, 0, 0}], ML.Types.NumericField), no_of_fields, crossover_op(COUNTER));        
    END;
    
    SHARED DATASET(Types.NumericField) fetch_random_member(DATASET(Types.NumericField) population):= FUNCTION
                        RETURN population(id=(INTEGER)real_random_between(1, COUNT(population)));
    END;
    
    SHARED DATASET(Types.NumericField) GenerateNewPopulation(DATASET(Types.NumericField) original_population):= FUNCTION
        no_of_members := MAX(original_population, original_population.id); 
        RETURN LOOP(DATASET([], ML.Types.NumericField), no_of_members, GenerateNew(original_population(id=COUNTER), 
                                                                            fetch_random_member(original_population),
                                                                            fetch_random_member(original_population),
                                                                            ROWS(LEFT)));
    END;
    
    EXPORT DATASET(Types.NumericField) Run() := FUNCTION 
        no_of_fields := COUNT(tuning_ranges);
        split := SplitDataset(input_data);
        training_indep_ds := split.IndepTrain;
        training_dep_ds := split.DepTrain;
        tuning_indep_ds := split.IndepTest;
        tuning_dep_ds := split.DepTest;
        
        DATASET(ML.Types.NumericField) RunOneGeneration(DATASET(ML.Types.NumericField) raw_population) := FUNCTION
            no_of_members := MAX(raw_population, raw_population.id); // Assumption: id always starts from 1 and stays that way.            
            population := raw_population(number <> no_of_fields + 1); // Field of evaluated score is always 1 (see EvaluateParameters)
            evaluated_old_population := raw_population(number = no_of_fields + 1);
            new_population := GenerateNewPopulation(population);
            evaluated_new_population := EvaluateParameters(training_indep_ds,
                                                           training_dep_ds,
                                                           tuning_indep_ds,
                                                           tuning_dep_ds,
                                                           new_population,
                                                           algorithm);
            // check if old is better than new
            ASSERT(COUNT(evaluated_old_population) = COUNT(evaluated_new_population), 'The size of old and new population should be the same');
            comparision := JOIN(evaluated_old_population, evaluated_new_population, LEFT.id=RIGHT.id, 
                                TRANSFORM({ML.Types.NumericField, INTEGER old_new},
                                            SELF.id := LEFT.id;
                                            SELF.number := LEFT.number;  // Doesn't need to do the project operation
                                            SELF.value := IF(LEFT.value < RIGHT.value, RIGHT.value, LEFT.value);
                                            SELF.old_new := IF(LEFT.value < RIGHT.value, 1, 0); // Assumption: Higher the better; 1 means new is better
                                        ));
            old_accepted_population_i := JOIN(comparision, population, LEFT.id=RIGHT.id AND LEFT.old_new=0, TRANSFORM(ML.Types.NumericField, SELF:= RIGHT));
            new_accepted_population_i := JOIN(comparision, new_population, LEFT.id=RIGHT.id AND LEFT.old_new=1, TRANSFORM(ML.Types.NumericField, SELF:= RIGHT));
            accepted_population_d := PROJECT(comparision, TRANSFORM(ML.Types.NumericField, SELF.id:= LEFT.id, SELF.number:=LEFT.number, SELF.value := LEFT.value));
            ASSERT(COUNT(old_accepted_population_i) + COUNT(new_accepted_population_i) + COUNT(accepted_population_d) = COUNT(raw_population), 'The output should be same as input');
            RETURN old_accepted_population_i + new_accepted_population_i + accepted_population_d;
        END;
        
        initial_points := GenerateTuningPoints(tuning_ranges);
        
        evaluated_intial_points := EvaluateParameters(training_indep_ds,training_dep_ds,tuning_indep_ds,
                                                           tuning_dep_ds,initial_points,algorithm);
        t_evaluated_initial_points := PROJECT(evaluated_intial_points, TRANSFORM(ML.Types.NumericField, SELF.number := LEFT.number + no_of_fields, SELF:=LEFT)); 
        comb_pop := initial_points + t_evaluated_initial_points;
        return_population :=  LOOP(comb_pop, no_of_generation, RunOneGeneration(ROWS(LEFT))); // Passing the independent and dependent values
        chosen_one := SORT(return_population(number=no_of_fields+1), -value)[1].id;
        RETURN return_population(id=chosen_one AND number <> no_of_fields+1); // number <> no_of_fields+1 -> to remove the objective function
    END; 
END;
