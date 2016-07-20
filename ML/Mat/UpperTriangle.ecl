IMPORT ML.Mat AS ML_Mat;
// the lower triangular portion of the matrix
EXPORT UpperTriangle(DATASET(ML_Mat.Types.Element) matrix) := matrix(x<=y);
