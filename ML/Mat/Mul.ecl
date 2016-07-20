IMPORT ML.Mat AS ML_Mat;
IMPORT ML.Config AS Config;

MulMethod := ENUM ( Default = 1, SymmetricResult  = 2 );
Mul_Default(DATASET(ML_Mat.Types.Element) l,DATASET(ML_Mat.Types.Element) r) := FUNCTION

	ML_Mat.Types.Element Mu(l le,r ri) := TRANSFORM
		SELF.x := le.x;
		SELF.y := ri.y;
		SELF.value := le.value * ri.value;
	END;
	
  J := JOIN(l,r,LEFT.y=RIGHT.x,Mu(LEFT,RIGHT)); // Form all of the intermediate computations
	
	Inter := RECORD
		J.x;
		J.y;
		ML_Mat.Types.t_value value := SUM(GROUP,J.value);
	END;
	
	// Combine all the parts back into a matrix - note if your matrices fit in memory on 1 node - FEW will help
	T := IF(ML_Mat.Has(l).Stats.XMax*ML_Mat.Has(r).Stats.YMax*sizeof(ML_Mat.Types.Element)>Config.MaxLookup, 
				TABLE(J,Inter,x,y,MERGE), 
				TABLE(J,Inter,x,y,FEW));

	RETURN PROJECT( T , TRANSFORM( ML_Mat.Types.Element, SELF := LEFT ) ); // Cast back into matrix type

END;

Mul_SymmetricResult(DATASET(ML_Mat.Types.Element) l,DATASET(ML_Mat.Types.Element) r) := FUNCTION

	ML_Mat.Types.Element Mu(l le,r ri) := TRANSFORM
		SELF.x := le.x;
		SELF.y := ri.y;
		SELF.value := le.value * ri.value;
	END;
	
	// Form all of the intermediate computations below diagonal
  J := JOIN(l,r,LEFT.y=RIGHT.x AND LEFT.x>=RIGHT.y,Mu(LEFT,RIGHT)); 
	
	Inter := RECORD
		J.x;
		J.y;
		ML_Mat.Types.t_value value := SUM(GROUP,J.value);
	END;
	
	// Combine all the parts back into a matrix - note if your matrices fit in memory on 1 node - FEW will help
	T := IF(ML_Mat.Has(l).Stats.XMax*ML_Mat.Has(r).Stats.YMax*sizeof(ML_Mat.Types.Element)>Config.MaxLookup, 
				TABLE(J,Inter,x,y,MERGE), 
				TABLE(J,Inter,x,y,FEW));
				
	mT := PROJECT( T , TRANSFORM( ML_Mat.Types.Element, SELF := LEFT ) ); // Cast back into matrix type
		
	// reflect the matrix	
	ML_Mat.Types.Element ReflectM(ML_Mat.Types.Element le, UNSIGNED c) := TRANSFORM, SKIP (c=2 AND le.x=le.y)
		SELF.x := IF(c=1,le.x,le.y);
		SELF.y := IF(c=1,le.y,le.x);
		SELF := le;
	END;
	
	RETURN NORMALIZE(mT,2,ReflectM(LEFT,COUNTER)); 
	
END;

EXPORT Mul(DATASET(ML_Mat.Types.Element) l,DATASET(ML_Mat.Types.Element) r, MulMethod method=MulMethod.Default) := FUNCTION
		StatsL := ML_Mat.Has(l).Stats;
		StatsR := ML_Mat.Has(r).Stats;
		SizeMatch := ~ML_Mat.Strict OR (StatsL.YMax=StatsR.XMax);
		
		assertCondition := ~(ML_Mat.Debug AND ~SizeMatch);	
		checkAssert := ASSERT(assertCondition, 'Mul FAILED - Size mismatch', FAIL);		
		result := IF(SizeMatch, IF(method=MulMethod.Default, Mul_Default(l,r), Mul_SymmetricResult(l,r)),DATASET([], ML_Mat.Types.Element));
		RETURN WHEN(result, checkAssert);
END;		