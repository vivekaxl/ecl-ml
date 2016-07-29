IMPORT ML.Mat AS ML_Mat;
EXPORT Trans(DATASET(ML_Mat.Types.Element) d) := PROJECT(d,TRANSFORM(ML_Mat.Types.Element, SELF.x := LEFT.y, SELF.y := LEFT.x, SELF := LEFT));