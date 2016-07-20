IMPORT ML.Mat AS ML_Mat;

/*
	Lanczos method is a technique that can be used to solve eigenproblems (Ax = lambda*x)
	for a large, sparse, square, symmetric matrix. This method involves tridiagonalization of
	the given matrix, and unlike the Householder approach, no intermediate, full submatrices
	are generated. Equaly important, information about A's eigenvalues tends to emerge
	before tridiagonalization is complete. This makes the Lanczos algorithm useful in 
	situations where a few of A's largest or smallest eigenvalues are desired. 
	(Source: Golub and Van Loan, "Matrix Computations")

	Implementation based on: http://bickson.blogspot.com/search/label/Lanczos
*/
EXPORT Lanczos(DATASET(ML_Mat.Types.Element) A, UNSIGNED eig_cnt) := MODULE

	SHARED l_comp := ENUM ( V = 1, alpha = 2, beta = 3, T = 4 );
	Stats := ML_Mat.Has(A).Stats;
	
EXPORT DATASET(ML_Mat.Types.Element) TV() := FUNCTION

	// V(:,2)=V(:,2)/norm(V(:,2),2);
	B1 := 1000000;
	V00 := PROJECT( ML_Mat.Vec.From(Stats.YMax),TRANSFORM(ML_Mat.Types.Element,SELF.x := LEFT.x, SELF.Value := (RANDOM()%B1) / (REAL8)B1,SELF.y:=2));	
	V0 := ML_Mat.Scale(V00, 1/ML_Mat.Vec.Norm(V00));
	Alpha0 := DATASET([],ML_Mat.Types.Element);	
	Beta0 := DATASET([],ML_Mat.Types.Element);	
	
	loopBody(DATASET(ML_Mat.Types.MUElement) ds, UNSIGNED4 k) := FUNCTION
	  j := k+1;

		V := ML_Mat.MU.From(ds, l_comp.V);
		Alpha := ML_Mat.MU.From(ds, l_comp.alpha);
		Beta := ML_Mat.MU.From(ds, l_comp.beta);
		// w = A*V(:,j) - beta(j)*V(:,j-1);
	  W := Sub(Mul(A, ML_Mat.Vec.FromCol(V, j)), Scale(ML_Mat.Vec.FromCol(V(y=j-1),j-1),Beta(y=j)[1].value));
		// alpha(j) = w'*V(:,j)
		newAlphaElem := ML_Mat.Mul(Trans(W), V(y=j));
		Alpha1 := Alpha + newAlphaElem;
		//w1 = w - alpha(j)*V(:,j);
		W1 := ML_Mat.Sub(W, ML_Mat.Scale(Vec.FromCol(V(y=j),j),newAlphaElem[1].value));
		
		/*
		// ToDo: Orthogonalize
    for k=2:j-1
      tmpalpha = w'*V(:,k);
      w = w -tmpalpha*V(:,k);
    end
		*/
		
		// beta(j+1) = norm(W1)
		newBetaElem := PROJECT(ML_Mat.Each.Each_SQRT(Mul(ML_Mat.Trans(W1), W1)),TRANSFORM(ML_Mat.Types.Element,SELF.x:=1,SELF.y:=j+1,SELF := LEFT));
		Beta1 := Beta + newBetaElem;	
		// V(:,j+1) = w/beta(j+1);
   	newVCol := PROJECT(W1,TRANSFORM(ML_Mat.Types.Element,SELF.value:=LEFT.value/newBetaElem[1].value, SELF := LEFT));
		
	RETURN ML_Mat.MU.To(V+ML_Mat.Vec.ToCol(newVCol, j+1), l_comp.V)+ML_Mat.MU.To(Alpha1, l_comp.alpha)+ML_Mat.MU.To(Beta1, l_comp.beta);
  END;
	

	V_Alpha_Beta := LOOP(ML_Mat.Mu.To(V0, l_comp.V)+	ML_Mat.Mu.To(Alpha0, l_comp.alpha)+
		          				 ML_Mat.Mu.To(Beta0, l_comp.beta), eig_cnt, loopBody(ROWS(LEFT),COUNTER));
							
  // At this point, Alpha and Beta represent diagonal elements of the tri-diagonal 
	// symetric matrix T. 
	V := ML_Mat.MU.From(V_Alpha_Beta, l_comp.V)(y<=eig_cnt+1);
	Vshift := PROJECT(V,TRANSFORM(ML_Mat.Types.Element,SELF.y:=LEFT.y-1, SELF := LEFT));
	Alpha := ML_Mat.Thin(ML_Mat.MU.From(V_Alpha_Beta, l_comp.alpha));
	Beta := ML_Mat.Thin(MU.From(V_Alpha_Beta, l_comp.beta)(y<=eig_cnt+1));
        T1 := ML_Mat.Vec.ToDiag(ML_Mat.Trans(Alpha), 2);
	T2 := ML_Mat.Vec.ToUpperDiag(ML_Mat.Trans(Beta),3);
	T3 := ML_Mat.Vec.ToLowerDiag(ML_Mat.Trans(Beta),3);
	RETURN ML_Mat.Mu.To(Vshift, l_comp.V) + ML_Mat.Mu.To(T1+T2+T3, l_comp.T);
	
END;

EXPORT TComp := ML_Mat.MU.From(TV(), l_comp.T);
EXPORT VComp := ML_Mat.MU.From(TV(), l_comp.V);

END;