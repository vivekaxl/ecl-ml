﻿IMPORT * FROM $;

EXPORT Det(DATASET(Types.Element) matrix) := 
        AGGREGATE(LU.Decompose(matrix)(x=y), Types.Element, TRANSFORM(Types.Element, SELF.value := IF(RIGHT.x<>0,LEFT.Value*RIGHT.Value,LEFT.Value), SELF := LEFT))[1].value;
