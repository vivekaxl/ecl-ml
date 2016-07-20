IMPORT ML.Mat as ML_Mat;
// This module exists to handle a special sub-case of a matrix; the Vector
// The vector is really just a matrix with only one dimension
EXPORT Vec := MODULE

// Create a vector from 'thin air' - with N entries each of value def
EXPORT From(ML_Mat.Types.t_Index N,ML_Mat.Types.t_value def = 1.0) := FUNCTION
	seed := DATASET([{0,0,0}], ML_Mat.Types.VecElement);
  PerCluster := ROUNDUP(N/CLUSTERSIZE);
	ML_Mat.Types.VecElement addNodeNum(ML_Mat.Types.VecElement L, UNSIGNED4 c) := transform
    SELF.x := (c-1)*PerCluster;
		SELF.y := 1;
		SELF.value := DEF;
  END;
	// Create eventual vector across all nodes (in case it is huge)
	one_per_node := DISTRIBUTE(NORMALIZE(seed, CLUSTERSIZE, addNodeNum(LEFT, COUNTER)), x DIV PerCluster);

	ML_Mat.Types.VecElement fillRow(ML_Mat.Types.VecElement L, UNSIGNED4 c) := TRANSFORM
		SELF.x := l.x+c;
		SELF.y := 1;
		SELF.value := def;
	END;
	// Now generate on each node; filter 'clips' of the possible extra '1' generated on some nodes
	m := NORMALIZE(one_per_node, PerCluster, fillRow(LEFT,COUNTER))(x <= N);
	RETURN m;

END;

// The 'To' routines - used to create a matrix from a vector
// Fill in the leading diagonal of a matrix starting with the vector element N
EXPORT ToDiag(DATASET(ML_Mat.Types.VecElement) v, ML_Mat.Types.t_index N=1) := PROJECT( v(x>=N), TRANSFORM(ML_Mat.Types.Element,SELF.x:=LEFT.x-N+1,SELF.y:=LEFT.x-N+1,SELF := LEFT));

// Fill in the upper diagonal of a matrix starting with the vector element N
EXPORT ToLowerDiag(DATASET(ML_Mat.Types.VecElement) v, ML_Mat.Types.t_index N=1) := PROJECT( v(x>=N), TRANSFORM(ML_Mat.Types.Element,SELF.x:=LEFT.x-N+2,SELF.y:=LEFT.x-N+1,SELF := LEFT));

// Fill in the Lower diagonal of a matrix starting with the vector element N
EXPORT ToUpperDiag(DATASET(ML_Mat.Types.VecElement) v, ML_Mat.Types.t_index N=1) := PROJECT( v(x>=N), TRANSFORM(ML_Mat.Types.Element,SELF.x:=LEFT.x-N+1,SELF.y:=LEFT.x-N+2,SELF := LEFT));

// Fill in a column
EXPORT ToCol(DATASET(ML_Mat.Types.VecElement) v,ML_Mat.Types.t_index N) := PROJECT( v, TRANSFORM(ML_Mat.Types.Element,SELF.x:=LEFT.x,SELF.y:=N,SELF := LEFT));

// Fill in a row
EXPORT ToRow(DATASET(ML_Mat.Types.VecElement) v,ML_Mat.Types.t_index N) := PROJECT( v, TRANSFORM(ML_Mat.Types.Element,SELF.y:=LEFT.x,SELF.x:=N,SELF := LEFT));

// The 'Rep' routines - used to replace part of a matrix with a vector

EXPORT RepDiag(DATASET(ML_Mat.Types.Element) M, DATASET(ML_Mat.Types.VecElement) v, ML_Mat.Types.t_index N=1) := M(X<>Y)+ ToDiag(v, N);

EXPORT RepCol(DATASET(ML_Mat.Types.Element) M,DATASET(ML_Mat.Types.VecElement) v,ML_Mat.Types.t_index N) := M(Y<>N)+ToCol(v, N);

EXPORT RepRow(DATASET(ML_Mat.Types.Element) M,DATASET(ML_Mat.Types.VecElement) v,ML_Mat.Types.t_index N) := M(X<>N)+ToRow(v, N);

// The 'From' routines - extract a vector from part of a matrix
// FromDiag returns a vector formed from the elements of the Kth diagonal of M
EXPORT FromDiag(DATASET(ML_Mat.Types.Element) M, INTEGER4 K=0) := PROJECT( M(x=y-k), TRANSFORM(ML_Mat.Types.VecElement,SELF.x:=IF(K<0,LEFT.y,LEFT.x),SELF.y:=1,SELF := LEFT));

EXPORT FromCol(DATASET(ML_Mat.Types.Element) M,ML_Mat.Types.t_index N) := PROJECT( M(Y=N), TRANSFORM(ML_Mat.Types.VecElement,SELF.x:=LEFT.x,SELF.y:=1,SELF := LEFT));

EXPORT FromRow(DATASET(ML_Mat.Types.Element) M,ML_Mat.Types.t_index N) := PROJECT( M(X=N), TRANSFORM(ML_Mat.Types.VecElement,SELF.x:=LEFT.y,SELF.y:=1,SELF := LEFT));

// Vector math
// Compute the dot product of two vectors
EXPORT Dot(DATASET(ML_Mat.Types.VecElement) X,DATASET(ML_Mat.Types.VecElement) Y) := FUNCTION
  J := JOIN(x,y,LEFT.x=RIGHT.x,TRANSFORM(ML_Mat.Types.VecElement,SELF.x := LEFT.x, SELF.value := LEFT.value*RIGHT.value, SELF:=LEFT));
	RETURN SUM(J,value);
END; 

EXPORT Norm(DATASET(ML_Mat.Types.VecElement) X) := SQRT(Dot(X,X));

EXPORT Length(DATASET(ML_Mat.Types.VecElement) X) := ML_Mat.Has(X).Dimension;

END;