IMPORT ML;
IMPORT ML.Types;
IMPORT ParameterTuning AS PT;

EXPORT SWAY(DATASET(Types.NumericField) input_data, DATASET(PT.Types.TuningField) tuning_ranges, PT.Helper.actionPrototype algorithm=PT.Helper.DummyObjectiveFunction):= MODULE(PT.Algorithms.IPLAlgorithm)
         SHARED REAL euclidean_distance(DATASET(Types.NumericField) a, DATASET(Types.NumericField) b):= FUNCTION
                        temp := JOIN(a, b, LEFT.number = RIGHT.number, TRANSFORM(Types.NumericField, 
                                                                        SELF.id := -1;
                                                                        SELF.number := LEFT.number;
                                                                        SELF.value := POWER(LEFT.value-RIGHT.value, 2)
                                                                        ));
                        return (SQRT(SUM(temp, temp.value)));
        END;
        
        SHARED REAL real_random_between(INTEGER lower_limit, ANY upper_limit) := FUNCTION
                        RETURN lower_limit + ((RANDOM()%100)/100) * (upper_limit - lower_limit);
                END;
        
        EXPORT DATASET(ML.Types.NumericField)  run():= FUNCTION
            no_of_fields := COUNT(tuning_ranges);
            split := SplitDataset(input_data);
            training_indep_ds := split.IndepTrain;
            training_dep_ds := split.DepTrain;
            tuning_indep_ds := split.IndepTest;
            tuning_dep_ds := split.DepTest;
            
            DATASET(ML.Types.NumericField) run_one_split(DATASET(ML.Types.NumericField) raw_population) := FUNCTION
                Distances := ML.Cluster.distances(raw_population, raw_population);
                poles_index := Distances(value = MAX(Distances, Distances.value))[1];
                east := raw_population(id = poles_index.x);
                west := raw_population(id = poles_index.y);
                c_2 := POWER(poles_index.value, 2);

                INTEGER projected(DATASET(Types.NumericField) east, DATASET(Types.NumericField) west, DATASET(Types.NumericField) individual):= FUNCTION
                        a_2 := POWER(euclidean_distance(east, individual), 2);
                        b_2 := POWER(euclidean_distance(west, individual), 2);
                        RETURN (a_2 + c_2 - b_2) / (2*SQRT(c_2));
                END;

                add_proj_rec := {INTEGER id, REAL projected_distance};

                // Find projections on to the first principal component                
                ids := DEDUP(SORT(raw_population, id), id);
                projected_population := SORT(PROJECT(ids, TRANSFORM(add_proj_rec, 
                                                        SELF.projected_distance := projected(east, west, raw_population(id=LEFT.id));
                                                        SELF.id := LEFT.id;
                                                        )), projected_distance);
                split_point := COUNT(projected_population)/2;
                DATASET(ML.Types.NumericField) get_split_data(DATASET(add_proj_rec) selected_points, DATASET(ML.Types.NumericField) population) := FUNCTION
                        RETURN JOIN(selected_points, population, LEFT.id = RIGHT.id, TRANSFORM(RECORDOF(population),SELF := RIGHT));
                END;
                t_east := PROJECT(east, TRANSFORM(ML.Types.NumericField, SELF.id:= 1, SELF:=LEFT));
                t_west := PROJECT(west, TRANSFORM(ML.Types.NumericField, SELF.id:= 2, SELF:=LEFT));
                scores := EvaluateParameters(training_indep_ds,
                                                           training_dep_ds,
                                                           tuning_indep_ds,
                                                           tuning_dep_ds,
                                                           t_east+t_west,
                                                           algorithm);
                // id =1 -> East and id=2 -> West (look at definition of t_east and t_west)                                           
                surviving_split := IF(scores(id=1)[1].value >=  scores(id=2)[1].value,  
                                        get_split_data(projected_population[1..split_point], raw_population), 
                                        get_split_data(projected_population[split_point+1..], raw_population)
                                        );
                RETURN surviving_split;
            END;            
            
            
            
            population := GenerateTuningPoints(tuning_ranges, 100);
            stopping_point :=  (INTEGER)(SQRT(100));
            return_population := LOOP(population,    
                                    COUNTER <= stopping_point AND COUNT(ROWS(LEFT))/no_of_fields > (INTEGER)(COUNT(population)/no_of_fields)/10,
                                    run_one_split(ROWS(LEFT))
                                    );

            chosen_one := SORT(return_population, -value)[1].id;
            RETURN return_population(id=chosen_one); // number <> no_of_fields+1 -> to remove the objective function
        END;
        
END;







/*
// To reuse distances
subset_distances_1 := JOIN(surviving_split, Distances, LEFT.id = RIGHT.x, TRANSFORM(RECORDOF(Distances),SELF := RIGHT));
subset_distances := JOIN(surviving_split, subset_distances_1, LEFT.id = RIGHT.y, TRANSFORM(RECORDOF(Distances),SELF := RIGHT));
subset_distances;
*/