/* 
    Copyright 2016, 2017, Joshua Maglione, James B. Wilson.
    Distributed under GNU GPLv3.
*/


/*
  This file contains all the constuctors for tensor categories (TenCat).
*/


__GetTensorCategory := function( a, P : Con := false )
  C := New(TenCat);
  C`Contra := Con;
  C`Valence := #Domain(a);
  C`Arrows := a;
  C`Repeats := P;
  return C;
end function;

__TensorCatSanity := function( F, C )
  v := #F;
  if (not C`Contra and (#F ne C`Valence)) or (C`Contra and (#F+1 ne C`Valence)) then
    return false, "Valences do not match.";
  end if;
  parts := [ P : P in C`Repeats | #P gt 1 ];
  for P in parts do
    if not forall{ p : p in P | p @ C`Arrows eq Minimum(P) @ C`Arrows } then
      return false, "Arrows do not match repeated modules.";
    end if;
    if not forall{ p : p in P | Dimension(F[v-p]) eq Dimension(F[v-Minimum(P)]) } then
      return false, "Repeated modules are not isomorphic.";
    end if;
  end for;
  return true,_;
end function;

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                                  Intrinsics
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
// Covariant
intrinsic TensorCategory( A::Map, P::{SetEnum} ) -> TenCat
{Create a tensor category with arrows oriented by arrows A and repeated module 
partition P.}
	require Codomain(A) subset {-1,0,1} : 
		"Arrows must be 1 ``right'', 0 ``constant'', or -1 ``left''";
	D := Domain(A);
	v := #D-1;
	require ({0..v} eq D ) : "Domain of arrows should be {0..v}.";
	S := &join P;
	require ({0..v} eq S) : "Repeats should partition {0..v}";
    require not exists(t){ <a,b> : a,b in P | not ( ( a eq b ) 
    	or IsEmpty(a meet b)) } : "Repeats should partition {0..v}";
    
    require not exists(t){ X : X in P | #{ x@A : x in X} gt 1} : 
    	"Arrows must refine repeats.";
  return __GetTensorCategory( A, P );
end intrinsic;

intrinsic TensorCategory( A::[RngIntElt], P::{SetEnum} ) -> TenCat
{Create a tensor category with arrows oriented by arrows A and repeated module partition P.}
  require Set(A) subset {-1,0,1} : "Arrows must be 1 ``right'', 0 ``constant'', or -1 ``left''";
  v := #A - 1; 
  
  require {0..v} eq &join P : "Number of arrows must match range of repeat partition.";
  require not exists(t){ <A,B> : A, B in P | not ( ( A eq B ) or IsEmpty(A meet B)) } : "Repeated modules do not partition valence.";

	// Make a function on P of the arrows, no checks, just use
	// one value from each representative.
	a := map<{0..v}->{-1,0,1} | x:->A[v+1-x]>;
	return __GetTensorCategory(a,P);
end intrinsic;

// Contravariant
intrinsic CotensorCategory( A::Map, P::{SetEnum} ) -> TenCat
{Create a cotensor category with arrows oriented by arrows A and repeated module 
partition P.}
	require Codomain(A) subset {-1,0,1} : 
		"Arrows must be 1 ``right'', 0 ``constant'', or -1 ``left''";
	D := Domain(A);
	v := #D;
	require ({1..v} eq D ) : "Domain of arrows should be {1..v}.";
	S := &join P;
	require ({1..v} eq S) : "Repeats should partition {1..v}";
    require not exists(t){ <a,b> : a,b in P | not ( ( a eq b ) 
    	or IsEmpty(a meet b)) } : "Repeats should partition {1..v}";
    
    require not exists(t){ X : X in P | #{ x@A : x in X} gt 1} : 
    	"Arrows must refine repeats.";
  a_map := map< {0..v} -> {-1,0,1} | x :-> (x eq 0) select 0 else x@A >;
  Include(~P,{0});
  return __GetTensorCategory( a_map, P : Con := true );
end intrinsic;

intrinsic CotensorCategory( A::[RngIntElt], P::{SetEnum} ) -> TenCat
{Create a cotensor category with arrows oriented by arrows A and repeated module partition P.}
  require Set(A) subset {-1,0,1} : "Arrows must be 1 ``right'', 0 ``constant'', or -1 ``left''";
  v := #A; 
  
  require {1..v} eq &join P : "Number of arrows must match range of repeat partition.";
  require not exists(t){ <A,B> : A, B in P | not ( ( A eq B ) or IsEmpty(A meet B)) } : "Repeated modules do not partition valence.";

	// Make a function on P of the arrows, no checks, just use
	// one value from each representative.
  A cat:= [0];
  Include(~P,{0});
	a := map<{0..v}->{-1,0,1} | x:->A[v+1-x] >;
	return __GetTensorCategory(a,P : Con := true);
end intrinsic;

intrinsic HomotopismCategory( v::RngIntElt : Contravariant := false ) -> TenCat
{Albert's homotopism category with valence v.}
  if Contravariant then
    return CotensorCategory( [ 1 : i in [1..v-1] ], { {i} : i in [1..v-1]} );
  end if;
  return TensorCategory( [ 1 : i in [0..v-1] ], { {i} : i in [0..v-1]} );
end intrinsic;

intrinsic CohomotopismCategory( v::RngIntElt ) -> TenCat
{Albert's cohomotopism category with valence v.}
  return TensorCategory( [ 1 : i in [1..v-1] ] cat [-1], { {i} : i in [0..v-1]} );
end intrinsic;

intrinsic AdjointCategory( v::RngIntElt, s::RngIntElt, t::RngIntElt ) -> TenCat
{The adjoint, or linear, category between positions s and t in a given valence v.}
  require v ge 2 : "Valence must be at least 2.";
  require {s,t} subset {0..v-1} : "Positions of adjoints must be within valance range.";
  require s ne t : "Adjoint positions cannot be equal.";

  A := [ 0 : i in [1..v]];
  A[v-s] := (s gt 0) select -1 else 1;
  A[v-t] := (t gt 0) select 1 else -1;

  P := {{s}, {t}, {i : i in [0..v-1] | not ( (i eq s) or (i eq t))}};
  return TensorCategory( A, P );
end intrinsic;

intrinsic LinearCategory( v::RngIntElt, s::RngIntElt, t::RngIntElt ) -> TenCat
{The linear category between positions s and t in a given valence v.}
  return AdjointCategory(v,s,t);
end intrinsic;
