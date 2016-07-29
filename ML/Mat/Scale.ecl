IMPORT ML.Mat AS ML_Mat;
EXPORT Scale(DATASET(ML_Mat.Types.Element) d,ML_Mat.Types.t_Value factor) := FUNCTION
    ML_Mat.Types.Element mul(d le) := TRANSFORM
        SELF.value := le.value * factor;
        SELF := le;
    END;
    RETURN PROJECT(d,mul(LEFT));
END;