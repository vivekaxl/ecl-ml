//This goes in ML.Regression directory.
IMPORT ML;
IMPORT ML.Types;
IMPORT ML.Mat.Types AS MatTypes;
NumericField := Types.NumericField;

EXPORT DATASET(NumericField) Predict(DATASET(NumericField) X, DATASET(NumericField) model) := FUNCTION
      mX_0 := Types.ToMatrix(X);
      mXloc := ML.Mat.InsertColumn(mX_0, 1, 1.0); // Insert X1=1 column
      //For model, the following 1) converts to Matrix, 2) transposes, 3) increases x by 1.
      mModel:=PROJECT(ML.Mat.Trans(Types.ToMatrix(model)),TRANSFORM(recordof(mXloc),SELF.x:=LEFT.x+1,SELF:=LEFT));
      // The following, 1) calculates Y, 2) converts to NumericField      
      RETURN Types.FromMatrix(ML.Mat.Mul(mXloc, mModel));
END;
