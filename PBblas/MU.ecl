IMPORT PBblas;
EXPORT MU := MODULE
        // These fundamental (but trivial) routines move a regular matrix in and out of matrix-universe format
        // The matrix universe exists to allow multiple matrices to co-reside inside one dataflow
        // This eases passing of them in and out of functions - but also reduces the number of operations required to co-locate elements
        EXPORT To(DATASET(PBblas.Types.Layout_Part) d, PBblas.Types.t_mu_no num) := PROJECT(d, TRANSFORM(PBblas.Types.MUElement, SELF.no := num, SELF := LEFT));
        EXPORT From(DATASET(PBblas.Types.MUElement) d, PBblas.Types.t_mu_no num) := PROJECT(d(no=num), TRANSFORM(PBblas.Types.Layout_Part, SELF := LEFT));
END;