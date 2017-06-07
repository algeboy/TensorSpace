/* 
    Copyright 2016, 2017, Joshua Maglione, James B. Wilson.
    Distributed under GNU GPLv3.
*/


/*
  This file contains functions for data manipulation of tensors (TenSpcElt).
*/

import "../GlobalVars.m" : __FRAME;
import "Tensors.m" : __TensorOnVectorSpaces;

// s: seq of elements in K, dims: seq of dims of frame [V_vav, ..., V_0], grid: sequence of subsets of {1..dim(V_a)}. 
__GetSlice := function( s, dims, grid )
  Grid := CartesianProduct(grid);
  offsets := [ &*dims[i+1..#dims] : i in [1..#dims-1] ] cat [1];
	indices := [ 1 + (&+[offsets[i]*(coord[i]-1): i in [1..#dims]]) : coord in Grid ];
	return s[indices];
end function;

// s: seq of elements in K, dims: seq of dims of frame [V_vav, ..., V_0], m: max, n: min (m,n in {0..vav})
__GetForms := function( s, dims, m, n : op := false )
  v := #dims;
  m := v-m;
  n := v-n;
  K := Parent(s[1]);
  if dims[m] eq dims[n] then
    M := MatrixAlgebra(K,dims[m]);
  else
    M := RMatrixSpace(K,dims[m],dims[n]);
  end if;
  Forms := [];
  CP := CartesianProduct( < [1..dims[k]] : k in Remove(Remove([1..#dims],n),m) > );
  for cp in CP do
    grid := [ {y} : y in Insert(Insert([ k : k in cp ],m,0),n,0) ];
    grid[m] := {1..dims[m]};
    grid[n] := {1..dims[n]};
    if op then
      Append(~Forms, Transpose(M!__GetSlice(s, dims, grid)));
    else
      Append(~Forms, M!__GetSlice(s, dims, grid));
    end if;
  end for;
  return Forms;
end function;

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                                  Intrinsics
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
intrinsic StructureConstants( t::TenSpcElt ) -> SeqEnum
{Returns the structure constants of t.}
  if (assigned t`CoordImages) and (t`Permutation eq Parent(t`Permutation)!1) then // no work to do
    return t`CoordImages;
  elif assigned t`CoordImages then // came from shuffle but do not have to compute coord images from scratch
    g := t`Permutation^-1;
    perm := Reverse([ t`Valence-i : i in Eltseq(g) ]); // CHECK THIS...
    spaces := __FRAME(t);
    spaces_old := spaces[perm];
    dims := [ Dimension(X) : X in spaces ];
    dims_old := [ Dimension(X) : X in spaces_old ];
    CP := CartesianProduct(< [1..dims[i]] : i in [1..t`Valence] >);
    offsets_old := [ &*dims_old[i+1..#dims] : i in [1..#dims-1] ] cat [1]; 
    indices := [ 1 + (&+[offsets_old[i]*(cp[perm[i]]-1): i in [1..t`Valence]]) : cp in CP ];
    t`CoordImages := t`CoordImages[indices];
    t`Permutation := Parent(t`Permutation)!1;
    if not assigned t`Element then
      t`Element := RSpace(BaseRing(t),#t`CoordImages)!(t`CoordImages);
    end if;
    return t`CoordImages;
  end if;

  try
    K := BaseRing(t);
  catch err
    error "Tensor does not have a base ring.";
  end try;
  M := t;
  v := M`Valence;
  d := Dimension(M`Codomain);
  B := < Basis(X) : X in M`Domain >;  
  dims := [ Dimension(X) : X in M`Domain ];
  sc := [];
  for cp in CartesianProduct( < [1..dims[i]] : i in [1..#dims] > ) do
    x := Coordinates(M`Codomain,< B[i][cp[i]] : i in [1..#cp] > @ M);
    sc cat:= x;
  end for;
  ChangeUniverse(~sc, K); 
  t`CoordImages := sc;
  if not assigned t`Element then
    t`Element := RSpace(K,#sc)!sc;
  end if;
  return sc;
end intrinsic;

intrinsic Eltseq( t::TenSpcElt ) -> SeqEnum
{Returns the structure constants of t.}
  return StructureConstants(t);
end intrinsic;

intrinsic Slice( t::TenSpcElt, grid::[SetEnum] ) -> SeqEnum
{Returns the sequence of the tensor with the given grid.}
  if t`Cat`Contra and #grid+1 eq t`Valence then
    grid cat:= [{1}];
  end if;
  require #grid eq t`Valence : "Grid inconsistent with frame.";
  try
    sc := StructureConstants(t);
  catch err
    error "Cannot compute structure constants.";
  end try;
  spaces := __FRAME(t);
  dims := [ Dimension(X) : X in spaces ];
  require forall{ i : i in [1..#grid] | grid[i] subset {1..dims[i]} } : "Unknown value in grid.";
  return __GetSlice(sc, dims, grid);
end intrinsic;

intrinsic Assign( t::TenSpcElt, ind::[RngIntElt], k::. ) -> TenSpcElt
{Returns the tensor where the entry in t from the sequence ind is replaced by k. 
Equivalent to s = t; s[ind] = k;}
  require t`Valence eq #ind : "Inconsistent indices with frame.";
  dims := [ Dimension(X) : X in __FRAME(t) ];
  require forall{ i : i in [1..#ind] | ind[i] le dims[i] and ind[i] gt 0 } : "Unknown value in indices.";
  require IsCoercible(BaseRing(t`Codomain), k) : "Value not contained in codomain.";
  try
    s := Eltseq(t);
  catch err
    error "Cannot compute structure constants.";
  end try;
  offsets := [ &*dims[i+1..#dims] : i in [1..#dims-1] ] cat [1];
  index := 1 + (&+[offsets[i]*(ind[i]-1): i in [1..#dims]]); 
  s[index] := BaseRing(t`Codomain)!k;
  return Tensor(dims, s, t`Cat);
end intrinsic;

intrinsic Assign( ~t::TenSpcElt, ind::[RngIntElt], k::. )
{Returns the given tensor where the entry in t from the sequence ind is replaced by k. 
Equivalent to t[ind] = k;}
  t := Assign(t, ind, k);
end intrinsic;

intrinsic InducedTensor( t::TenSpcElt, grid::[SetEnum] ) -> TenSpcElt
{Returns the tensor induced by the grid.}
  seq := Slice(t,grid);
  dims := [#grid[i] : i in [1..#grid]];
  if t`Cat`Contra and #grid eq t`Valence then
    Prune(~dims);
  end if;
  return Tensor( BaseRing(t), dims, seq, t`Cat );
end intrinsic;

intrinsic Compress( t::TenSpcElt ) -> TenSpcElt
{Compress all 1-dimensional spaces in the domain.}
  try
    OneDims := [* <t`Domain[i], i> : i in [1..#t`Domain] | Dimension(t`Domain[i]) eq 1 *];
  catch err
    error "Cannot compute dimensions of the modules.";
  end try;
  if #OneDims eq 0 or #t`Domain - #OneDims lt 1 then
    return t;
  end if;
  m := t`Map;
  F := function(x)
    s := [* a : a in x *];
    for i in [1..#OneDims] do
      Insert(~s,OneDims[i][2],Basis(OneDims[i][1])[1]);
    end for;
    return < x : x in s > @ m;
  end function;
  dom := [*X : X in t`Domain | Dimension(X) ne 1*];
  cmpl := [ i : i in [1..#t`Domain] | forall{ j : j in [1..#OneDims] | OneDims[j][2] ne i } ] cat [t`Valence-1];
  surj := [0] cat Reverse([ t`Valence-i : i in [1..#t`Domain] | Dimension(t`Domain[i]) ne 1 ]);
  part := { { Index(surj,x)-1 : x in S | x in surj } : S in t`Cat`Repeats };
  if {} in part then
    Exclude(~part,{});
  end if;
  A := Arrows(t`Cat);
  if t`Cat`Contra then
    Prune(~cmpl);
    Cat := CotensorCategory( A[cmpl], part);
  else
    Cat := TensorCategory( A[cmpl], part);
  end if;
  s := Tensor( dom, t`Codomain, F, Cat );
  if assigned t`CoordImages then
    s`CoordImages := Eltseq(t);
  end if;
  return s;
end intrinsic;

intrinsic AsMatrices( t::TenSpcElt, i::RngIntElt, j::RngIntElt ) -> SeqEnum
{Returns the sequence of matrices.}
  require i ne j : "Arguments 2 and 3 must be distinct.";
  require i in {0..t`Valence-1} : "Unknown argument 2.";
  require j in {0..t`Valence-1} : "Unkonwn arguemnt 3.";
  try 
    sc := StructureConstants(t);
  catch e
    error "Cannot compute structure constants of tensor.";
  end try;
  spaces := __FRAME(t);
  dims := [ Dimension(X) : X in spaces ];
  return __GetForms(sc, dims, Maximum([i, j]), Minimum([i, j]) : op := i eq Minimum([i, j]));
end intrinsic;

intrinsic SliceAsMatrices( t::TenSpcElt, grid::SeqEnum[SetEnum], i::RngIntElt, j::RngIntElt ) -> SeqEnum
{Performs the slice of t with the given grid and returns the tensor as matrices with i and j.}
  if t`Cat`Contra and #grid+1 eq t`Valence then
    grid cat:= [{1}];
  end if;
  require #grid eq t`Valence : "Grid inconsistent with frame.";
  try
    sc := StructureConstants(t);
  catch err
    error "Cannot compute structure constants.";
  end try;
  spaces := __FRAME(t);
  dims := [ Dimension(X) : X in spaces ];
  require forall{ k : k in [1..#grid] | grid[k] subset {1..dims[k]} } : "Unknown value in grid.";
  require i ne j : "Arguments 3 and 4 must be distinct.";
  require i in {0..t`Valence-1} : "Unknown argument 3.";
  require j in {0..t`Valence-1} : "Unkonwn arguemnt 4.";
  return __GetForms(__GetSlice(sc, dims, grid), [ #S : S in grid ], i, j);
end intrinsic;

intrinsic SystemOfForms( t::TenSpcElt ) -> SeqEnum
{Returns the system of forms for the given 2-tensor.}
  require t`Valence eq 3 : "Tensor must have valence 3.";
  try 
    sc := StructureConstants(t);
  catch e
    error "Cannot compute structure constants of tensor.";
  end try;
  spaces := __FRAME(t);
  dims := [ Dimension(X) : X in spaces ];
  return __GetForms(sc, dims, 2, 1);
end intrinsic;

intrinsic Foliation( t::TenSpcElt, i::RngIntElt ) -> Mtrx
{Foliates along the ith component.}
  require i in {0..#t`Domain} : "Unknown argument 2.";
  try 
    sc := StructureConstants(t);
  catch e
    error "Cannot compute structure constants of tensor.";
  end try;
  spaces := Frame(t);
  dims := [ Dimension(X) : X in spaces ];
  l := [ {1..d} : d in dims ];
  j := t`Valence-i;
  F := [];
  for i in [1..dims[j]] do
    slice := l;
    slice[j] := {i};
    Append(~F, __GetSlice(sc, dims, slice));
  end for;
  return Matrix(F);
end intrinsic;
