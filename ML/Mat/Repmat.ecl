IMPORT ML.Mat AS ML_Mat;
// replicates/tiles a matrix - creates a large matrix consisiting of
// an M-by-N tiling of copies of A
EXPORT Repmat(DATASET(ML_Mat.Types.Element) A, UNSIGNED M, UNSIGNED N) := FUNCTION

	Stats := ML_Mat.Has(A).Stats;
	ML_Mat.Types.Element ReplicateM(ML_Mat.Types.Element le,UNSIGNED C) := TRANSFORM
		SELF.x := le.x+Stats.XMax*(C-1);
		SELF := le;
	END;
	
  AM := NORMALIZE(A,M,ReplicateM(LEFT,COUNTER)); 
	
	ML_Mat.Types.Element ReplicateN(ML_Mat.Types.Element le,UNSIGNED C) := TRANSFORM
		SELF.y := le.y+ Stats.YMax*(C-1);
		SELF := le;
	END;
	
  AMN := NORMALIZE(AM,N,ReplicateN(LEFT,COUNTER)); 	
	
	RETURN AMN; 
END;