IMPORT ML.Mat AS ML_Mat;
EXPORT Det(DATASET(ML_Mat.Types.Element) matrix) := 
        AGGREGATE(ML_Mat.Decomp.LU(matrix)(x=y), ML_Mat.Types.Element, TRANSFORM(ML_Mat.Types.Element, SELF.value := IF(RIGHT.x<>0,LEFT.Value*RIGHT.Value,LEFT.Value), SELF := LEFT),
				TRANSFORM(ML_Mat.Types.Element, SELF.value := RIGHT1.Value*RIGHT2.Value, SELF := RIGHT2))[1].value;