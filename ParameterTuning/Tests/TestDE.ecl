IMPORT ML;
IMPORT ParameterTuning AS PT;
tuning_range := DATASET([
                        {1, 'Integer', 40, 80, -1},
                        {2, 'Integer', 3, 4, -1},
                        {3, 'Real', 0.9, 1.0, -1},
                        {4, 'Integer', 28, 29, -1}
                        ],
                        PT.Types.TuningField);

INTEGER c_parameters := COUNT(tuning_range);
INTEGER c_tuning_range := 16;    

AnyDataSet := PT.ecoliDS.content;
ML.ToField(AnyDataSet, NF_AnyDataSet);
tuner := PT.Algorithms.DE(NF_AnyDataSet, tuning_range);  //, PT.PLhelper.RandomForestClassfier);
result := tuner.run();
OUTPUT(result,NAMED('RecommenedConfiguration'), ALL);