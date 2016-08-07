IMPORT ML;
IMPORT ParameterTuning AS PT;
tuning_range := DATASET([
                        {1,'Integer',40, 80, -1},
                        {2, 'Integer',3, 4, -1},
                        {3, 'Real',0.9, 1.0, -1},
                        {4, 'Integer',28, 29, -1}
                        ],
                        PT.Types.TuningField);

grid := PT.Utils.MakeRandom(tuning_range);

// Since grid is of ML.Types.NumericField
OUTPUT(COUNT(grid)/COUNT(tuning_range));

OUTPUT(grid, ALL);