IMPORT ML.Mat AS ML_Mat;
EXPORT InsertColumn(DATASET(ML_Mat.Types.Element) d, ML_Mat.Types.t_Index col_i, ML_Mat.Types.t_value filler) := FUNCTION
    filler_col := ML_Mat.Vec.ToCol( ML_Mat.Vec.From( MAX(d,x), filler ), col_i );
    ML_Mat.Types.Element shiftRight(d le) := TRANSFORM
        SELF.y := IF(le.y>= col_i, le.y +1, le.y);
        SELF := le;
    END;
    d1 := PROJECT(d,shiftRight(LEFT));
    RETURN filler_col+d1;
END;