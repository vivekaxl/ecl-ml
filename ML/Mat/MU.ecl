IMPORT ML.Mat AS ML_Mat;

EXPORT MU := MODULE
    // These fundamental (but trivial) routines move a regular matrix in and out of matrix-universe format
    // The matrix universe exists to allow multiple matrices to co-reside inside one dataflow
    // This eases passing of them in and out of functions - but also reduces the number of operations required to co-locate elements
    EXPORT To(DATASET(ML_Mat.Types.Element) d, ML_Mat.Types.t_mu_no num) := PROJECT(d, TRANSFORM(ML_Mat.Types.MUElement, SELF.no := num, SELF := LEFT));
    EXPORT From(DATASET(ML_Mat.Types.MUElement) d, ML_Mat.Types.t_mu_no num) := PROJECT(d(no=num), TRANSFORM(ML_Mat.Types.Element, SELF := LEFT));
END;