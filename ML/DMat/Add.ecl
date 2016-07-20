//Pure dense matrix add based upon PB-BLAS
IMPORT PBblas;
Part := PBblas.Types.Layout_Part;
IMatrix_Map := PBblas.IMatrix_Map;
EXPORT DATASET(Part) Add(IMatrix_Map a1_map, DATASET(Part) addend1,
                         IMatrix_Map a2_map, DATASET(Part) addend2) := FUNCTION
  RETURN PBblas.PB_daxpy(1.0, addend1, addend2);
END;
