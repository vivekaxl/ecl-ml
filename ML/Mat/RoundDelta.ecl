IMPORT ML.Mat AS ML_Mat;
IMPORT ML.Config As Config;
EXPORT RoundDelta(DATASET(ML_Mat.Types.Element) d, REAL delta=Config.RoundingError) := PROJECT(d, TRANSFORM(ML_Mat.Types.Element,
                                                                                SELF.value := IF(ABS(LEFT.value-ROUND(LEFT.value))<delta,
                                                                                ROUND(LEFT.value), 
                                                                                LEFT.value ), 
                                                                                SELF := LEFT));