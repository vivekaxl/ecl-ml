IMPORT ML.Mat AS ML_Mat;
EXPORT SetDimension(DATASET(ML_Mat.Types.Element) A, ML_Mat.Types.t_Index I, ML_Mat.Types.t_Index J) := IF( ML_Mat.Strict,
	IF(EXISTS(A(x=I,y=J)), A(x<=I,y<=J), A(x<=I,y<=J)+DATASET([{I,J,0}], ML_Mat.Types.Element)),A);