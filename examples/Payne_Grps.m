/*
  In this example, we illustrate S. Payne's elation groups, G_f and G_(f-bar),
  are nonisomorphic using multilinear algebra techniques. Details can be found
  
  Finite groups that admit Kantor families. Finite geometries, groups, and 
  computation, 191–202, Walter de Gruyter GmbH & Co. KG, Berlin, 2006. 
*/

p := 3;
e := 4;
q := p^e; // q = 3^e >= 27
F := [KSpace(GF(q),2), KSpace(GF(q),2), KSpace(GF(q),1)];

DotProd := function(x)
  return KSpace(GF(q),1)!(x[1]*Matrix(2,1,x[2]));
end function;

DoubleForm := function(T)
  F := SystemOfForms(T)[1];
  K := BaseRing(F);
  n := Nrows(F);
  m := Ncols(F);
  MS := KMatrixSpace(K,n,m);
  Z := MS!0;
  M1 := HorizontalJoin(Z,-Transpose(F));
  M2 := HorizontalJoin(F,Z);
  D := VerticalJoin( M1, M2 );
  return Tensor( D, 2, 1 );
end function;

f := DoubleForm( Tensor( F, DotProd ) );
f;

IsAlternating(f);
Gf := HeisenbergGroupPC(f);


n := PrimitiveElement(GF(q)); // nonsquare
MS := KMatrixSpace(GF(q),2,2);
A := MS![-1,0,0,n];
B := MS![0,1,1,0];
C := MS![0,0,0,n^-1];
F1 := Frame(f);
F2 := [KSpace(GF(p),4*e), KSpace(GF(p),4*e),\
  KSpace(GF(p),e)];

// take 1/3^r root
Root := function(v,r) 
  k := Eltseq(v)[1];
  K := Parent(k);
  if k eq K!0 then return k; end if;
  R<x> := PolynomialRing(K);
  f := Factorization(x^(3^r)-k)[1][1];
  return K!(x-f);
end function;

// biadditive map defining elation grp
RomanGQ := function(x) 
  u := Matrix(1,2,x[1]);
  v := Matrix(2,1,x[2]);
  M := [A,B,C];
  f := &+[Root(u*M[i]*v,i-1) : i in [1..3]];
  return KSpace(GF(q),1)![f];
end function;

// vector space isomorphisms
phi := map< F2[1] -> F1[1] | \
  x :-> F1[1]![ GF(q)![ s : s in Eltseq(x)[i+1..e+i] ] : \
    i in [0,e,2*e,3*e] ] >;
gamma := map< F1[3] -> F2[3] | \
  x :-> F2[3]!&cat[ Eltseq(s) : s in Eltseq(x) ] >;

// bilinear commutator from RomanGQ
RomanGQComm := function(x)
  x1 := Eltseq(x[1]@phi)[1..2];
  x2 := Eltseq(x[1]@phi)[3..4];
  y1 := Eltseq(x[2]@phi)[1..2];
  y2 := Eltseq(x[2]@phi)[3..4];
  comm := RomanGQ( <x2,y1> ) - RomanGQ( <y2,x1> );
  return comm @ gamma;
end function;

f_bar := Tensor( F2, RomanGQComm );
f_bar;

IsAlternating(f_bar);
Gfb := HeisenbergGroupPC(f_bar);



Tf := pCentralTensor(Gf,1,1);
Tf;

Tfb := pCentralTensor(Gfb,1,1);
Tfb;

Cf := Centroid(Tf);
Cfb := Centroid(Tfb);
Dimension(Cf) eq Dimension(Cfb);

