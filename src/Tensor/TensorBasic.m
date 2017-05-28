/*
  This file contains basic functions for tensors (TenSpcElt).
*/


import "../GlobalVars.m" : __LIST, __SANITY_CHECK, __FRAME;
import "Tensor.m" : __GetTensor, __TensorOnVectorSpaces;
import "../TensorCategory/Hom.m" : __GetHomotopism;
import "../TensorCategory/TensorCat.m" : __TensorCatSanity;

__HasBasis := function( X )
  try 
    B := Basis(X);
  catch e
    if assigned e`Object then
      return false;
    end if;
  end try;
  return true;
end function;

// A function which takes a multimap M, and a list D of objects in the domain of M.
// Returns a list of spaces in the domain, provided the objects are in the domain of M.
__GenerateDomain := function( M, D )
  dom := M`Domain;
  n := #dom;
  list := [* *];
  i := 1;
  while i le n do
    if __HasBasis(D[i]) then
      // subspace
      B := Basis(D[i]);
      if forall{ b : b in B | IsCoercible(dom[i],b) } then
        Append(~list, sub< dom[i] | [ dom[i]!b : b in B ] >);
      else
        return false;
      end if;
    else
      // generators
      if Type(D[i]) in {SeqEnum,SetEnum,SetIndx,List} then
        if forall{ b : b in D[i] | IsCoercible(dom[i],b) } then
          Append(~list, sub< dom[i] | [ dom[i]!b : b in D[i] ] >);
        else
          return false;
        end if;
      else
        if IsCoercible(dom[i],D[i]) then
          Append(~list, sub< dom[i] | D[i] >);
        else
          return false;
        end if;
      end if;
    end if;
    i +:= 1;
  end while;
  return list;
end function;

// A function which takes a multimap M, and anything for C.
// Returns a list of generators for C in the codomain, provided it is coercible.
// Otherwise, returns false.
__GenerateCodomain := function( M, C )
  cod := M`Codomain;
  if __HasBasis(C) then
    //subspace
    B := Basis(C);
    if forall{ b : b in B | IsCoercible(cod,b) } then
      S := sub< cod | [ cod!b : b in B ] >;
    else
      return false;
    end if;
  else
    //generators
    if Type(C) in {SeqEnum,SetEnum,SetIndx,List} then
      if forall{ b : b in C | IsCoercible(cod,b) } then
        S := sub< cod | [ cod!b : b in C ] >;
      else
        return false;
      end if;
    else
      if IsCoercible(cod,C) then
        S := sub< cod | C >;
      else
        return false;
      end if;
    end if;
  end if;
  return S;
end function;

__CopyTensorWithCat := function( t, C )
  F := function(x)
    return x @ t;
  end function;
  s := __GetTensor( t`Domain, t`Codomain, F : Cat := C );
  if assigned t`CoordImages then
    s`CoordImages := t`CoordImages;
  end if;
  return s;
end function;

// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                                  Intrinsics
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
intrinsic Domain( t::TenSpcElt ) -> SetCart
{Returns the domain of t.}
  return CartesianProduct(< X : X in t`Domain >);
end intrinsic;

intrinsic Codomain( t::TenSpcElt ) -> .
{Returns the codomain of t.}
  return t`Codomain;
end intrinsic;

intrinsic Valence( t::TenSpcElt ) -> RngIntElt
{Returns the valence of t.}  
  return t`Valence;
end intrinsic;

intrinsic Frame( t::TenSpcElt ) -> List
{Returns the frame of t.}
  if t`Cat`Contra then
    return t`Domain;
  end if;
	return t`Domain cat [* t`Codomain *];
end intrinsic;

intrinsic TensorCategory( t::TenSpcElt ) -> TenCat
{Returns the tensor category of t.}
  return t`Cat;
end intrinsic;

intrinsic IsContravariant( t::TenSpcElt ) -> BoolElt
{Decides if the tensor is contravariant.}
  return t`Cat`Contra;
end intrinsic;

intrinsic IsCovariant( t::TenSpcElt ) -> BoolElt
{Decides if the tensor is covariant.}
  return not t`Cat`Contra;
end intrinsic;

intrinsic ChangeTensorCategory( t::TenSpcElt, C::TenCat ) -> TenSpcElt
{Returns the given tensor in the given category.}
  require t`Cat`Contra eq C`Contra : "Both must be co- or contravariant.";
  require C`Valence eq t`Valence : "Valence does not match.";
  passed, err := __TensorCatSanity( __FRAME(t), C );
  require passed : err;
  return __CopyTensorWithCat(t,C);
end intrinsic;

intrinsic ChangeTensorCategory( ~t::TenSpcElt, C::TenCat )
{Returns the given tensor in the given category.}
  require t`Cat`Contra eq C`Contra : "Both must be co- or contravariant.";
  require C`Valence eq t`Valence : "Valence does not match.";
  passed, err := __TensorCatSanity( __FRAME(t), C );
  require passed : err;
  t := __CopyTensorWithCat(t,C);
end intrinsic;

intrinsic BaseRing( t::TenSpcElt ) -> Rng
{For the tensor t, where each Vi is a R-bimodule, returns R. If Vi is not an R-bimodule, then returns false.}
  D := t`Domain;
  R := BaseRing( D[1] ); 
  try
    require forall{ X : X in t`Domain cat [* t`Codomain *] | BaseRing(X) eq R } : "Tensor does not have a common base ring.";
  catch err
    error "No covering ring for modules in frame.";
  end try;
  return R;
end intrinsic;

intrinsic BaseField( t::TenSpcElt ) -> Fld
{For the tensor t, where each Vi is a F-vector space, returns F. If Vi is not an F-vector space, then returns false.}
  K := BaseRing(t);
  require ISA( Type(K), Fld ) : "Base ring is not a field.";
  return K;
end intrinsic;

intrinsic Image( t::TenSpcElt ) -> ModTupRng, Map
{Returns the image of t as a subspace of the codomain.}
  if assigned t`Image then
    return t`Image[1],t`Image[2];
  end if;

  try
    passed, s, H, err := __TensorOnVectorSpaces(t);
  catch err
    error "Cannot extract vector space structure.";
  end try;
  require passed : err;

  try
    sc := Eltseq(t);
  catch err
    gens := [ g : g in CartesianProduct( < Basis(X) : X in s`Domain > ) ];
    i := 1;
    S := sub< s`Codomain | >;
    while i le #gens and Dimension(S) lt Dimension(s`Codomain) do
      S := sub< s`Codomain | S, gens[i] >;
      i +:= 1;
    end while;
    S := sub< S | Basis(S) >;// Magma work-around : remove superfluous generators
    t`Image := < S, H`Maps[#H`Maps] >;
    return S, H`Maps[#H`Maps];
  end try;

  d := Dimension(s`Codomain);
  if d eq 0 then
    t`Image := < s`Codomain, H`Maps[#H`Maps] >;
    return s`Codomain, H`Maps[#H`Maps];
  end if;
  i := 1;
  total := #sc div d;
  S := sub< s`Codomain | >;
  while i le total and Dimension(S) lt Dimension(s`Codomain) do
    S := sub< s`Codomain | S, s`Codomain!sc[(i-1)*d+1..i*d] >;
    i +:= 1;
  end while;
  S := sub< S | Basis(S) >;// Magma work-around : remove superfluous generators
  t`Image := < S, H`Maps[#H`Maps] >;
  return S, H`Maps[#H`Maps];
end intrinsic;

// ------------------------------------------------------------------------------
//                                   Sequences
// ------------------------------------------------------------------------------
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
  passed, M, _, err := __TensorOnVectorSpaces(t); // needed?
  require passed : err;
  v := M`Valence;
  d := Dimension(M`Codomain);
  B := < Basis(X) : X in M`Domain >;  
  dims := [ Dimension(X) : X in M`Domain ];
  sc := [];
  for cp in CartesianProduct( < [1..dims[i]] : i in [1..#dims] > ) do
    x := Coordinates(M`Codomain,< B[i][cp[i]] : i in [1..#cp] > @ M);
    sc cat:= x;
  end for;
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
  Grid := CartesianProduct(grid);
  spaces := __FRAME(t);
  require forall{ i : i in [1..#grid] | grid[i] subset {1..Dimension(spaces[i])} } : "Unknown value in grid.";
  K := BaseRing(t);
  dims := [ Dimension(X) : X in spaces ];
  offsets := [ &*dims[i+1..#dims] : i in [1..#dims-1] ] cat [1];
  perm := Eltseq(t`Permutation);
	indices := [ 1 + (&+[offsets[i]*(coord[i]-1): i in [1..#dims]]) : coord in Grid ];
	return sc[indices];
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
  v := #t`Domain;
  require i ne j : "Arguments 2 and 3 must be distinct.";
  require i in {0..v} : "Unknown argument 2.";
  require j in {0..v} : "Unkonwn arguemnt 3.";
  try 
    _ := StructureConstants(t);
  catch e
    error "Cannot compute structure constants of tensor.";
  end try;
  K := BaseRing(t);
  a := v-i+1;
  b := v-j+1;
  m := Minimum([a,b]);
  n := Maximum([a,b]);
  spaces := __FRAME(t);
  dims := [ Dimension(X) : X in spaces ];
  if dims[m] eq dims[n] then
    M := MatrixAlgebra(K,dims[m]);
  else
    M := RMatrixSpace(K,dims[m],dims[n]);
  end if;
  Forms := [];
  CP := CartesianProduct( < [1..dims[k]] : k in Remove(Remove([1..#dims],n),m) > );
  for cp in CP do
    x := [ {y} : y in Insert(Insert([ k : k in cp ],m,0),n,0) ];
    x[m] := {1..dims[m]};
    x[n] := {1..dims[n]};
    if m eq b then
      Append(~Forms, Transpose(M!Slice(t,x)));
    else
      Append(~Forms, M!Slice(t,x));
    end if;
  end for;

  return Forms;
end intrinsic;

intrinsic SystemOfForms( t::TenSpcElt ) -> SeqEnum
{Returns the system of forms for the given 2-tensor.}
  require t`Valence eq 3 : "Tensor must have valence 3.";
  return AsMatrices(t,2,1);
end intrinsic;

intrinsic Foliation( t::TenSpcElt, i::RngIntElt ) -> Mtrx
{Foliates along the ith component.}
  try 
    _ := StructureConstants(t);
  catch e
    error "Cannot compute structure constants of tensor.";
  end try;
  spaces := Frame(t);
  l := [ {1..Dimension(X)} : X in spaces ];
  j := t`Valence-i;
  F := [];
  for i in [1..Dimension(spaces[j])] do
    slice := l;
    slice[j] := {i};
    Append(~F,Slice(t,slice));
  end for;
  return Matrix(F);
end intrinsic;

intrinsic NondegenerateTensor( M::TenSpcElt ) -> TenSpcElt, Hmtp
{Returns the associated nondegenerate tensor of M along with a homotopism. 
Note that the domain and codomain of the returned tensor will be vector spaces.}
  if assigned M`Nondegenerate then
    return M`Nondegenerate[1], M`Nondegenerate[2];
  end if;
  if exists{ X : X in M`Domain cat [* M`Codomain *] | Type(X) ne ModTupFld } then
    passed, t, H2, err := __TensorOnVectorSpaces(M);
    require passed : err;
  else
    t := M;
  end if;
  R := BaseRing(t);
  D := t`Domain;
  Rad := Radical(t);
  dom := [* *];
  proj := [* *];
  for i in [1..#D] do
    Q,pi := D[i]/Rad[i];
    Append(~dom,Q);
    Append(~proj,pi);
  end for;
  Append(~proj,hom< t`Codomain -> t`Codomain | [ <b,b> : b in Basis(t`Codomain) ] >);
  
  F := function(x)
    return < x[i] @@ proj[i] : i in [1..#x] > @ t;
  end function;

  N := __GetTensor( dom, t`Codomain, F : Cat := M`Cat );
  N`Radicals := [* sub< dom[i] | > : i in [1..#dom] *];
  if assigned t`Coerce then
    N`Coerce := [* t`Coerce[i] * proj[i] : i in [1..#proj] *];
  end if;
  H := __GetHomotopism( M, N, proj : Cat := HomotopismCategory(M`Valence : Contravariant := M`Cat`Contra) );
  if assigned H2 then
    H := H2*H;
  end if;
  M`Nondegenerate := < N, H >;
  return N,H;
end intrinsic;

intrinsic IsNondegenerate( M::TenSpcElt ) -> BoolElt
{Decides if M is nondegenerate.}
  Rad := Radical(M);
  isit := forall{ R : R in Rad | #R eq 1 };
  if isit then
    id := [* hom< M`Domain[i] -> M`Domain[i] | [ <x,x> : x in Generators(M`Domain[i]) ] > : i in [1..#M`Domain] *];
    H := __GetHomotopism( M, M, id : Cat := HomotopismCategory(M`Valence : Contravariant := M`Cat`Contra) );
    M`Nondegenerate := <M,H>;
  end if;
  return isit;
end intrinsic;

intrinsic FullyNondegenerateTensor( M::TenSpcElt ) -> TenSpcElt, Hmtp
{Returns the fully nondegenerate tensor of M.}
  if assigned M`FullyNondeg then
    return M`FullyNondeg[1],M`FullyNondeg[2];
  end if;
  N, H := NondegenerateTensor( M );
  if M`Cat`Contra then
    return N,H;
  end if;
  I := Image( N );
  inc := hom< I -> N`Codomain | [ <b,b> : b in Basis(I) ] >;
  F := function(x)
    return x @ N;
  end function;
  FN := __GetTensor( N`Domain, I, F : Cat := M`Cat );
  H := __GetHomotopism(M,FN,H`Maps[1..#H`Maps-1] cat [* H`Maps[#H`Maps] * inc *]: Cat := CohomotopismCategory(M`Valence));
  M`FullyNondeg := <FN,H>;
  return FN,H;
end intrinsic;

intrinsic IsFullyNondegenerate( M::TenSpcElt ) -> BoolElt
{Decides if M is fully nondegenerate.}
  R := Radical(M);
  isit := forall{ i : i in [1..(M`Valence-1)] | R[i] eq sub< R[i] | > }; // CHECK THIS...
  if not isit then
    return false;
  end if;
  isit := Codomain(M) eq Image(M);
  if isit and not assigned M`FullyNondeg then
    M`FullyNondeg := M;
  end if;
  return isit;
end intrinsic;

intrinsic AssociatedForm( M::TenSpcElt ) -> TenSpcElt
{If M : Vn x ... x V1 >-> V0, returns the associated form F : Vn x ... x V0 >-> K as vector spaces.}
  if exists{ X : X in Frame(M) | Type(X) ne ModTupFld } then
    passed, M, _, err := __TensorOnVectorSpaces(M);
    require passed : err;
  end if;
  K := BaseRing(M);
  require ISA(Type(K),Fld) : "Base ring must be a field.";
  D := __FRAME(M);
  C := VectorSpace(K,1);
  F := function(x)
    y := < x[i] : i in [1..#x-1] >;
    return C![DotProduct(y @ M,x[#x])];
  end function;
  if M`Cat`Contra then 
    Cat := CotensorCategory( Prune(Arrows(M`Cat)) cat [1], { {x+1 : x in S} : S in M`Cat`Repeats } );
  else
    Cat := TensorCategory( Arrows(M`Cat) cat [1], { {x+1 : x in S} : S in M`Cat`Repeats } join {{0}} );
  end if;
  Form := Tensor( D, C, F, Cat );
  if assigned M`CoordImages then
    Form`CoordImages := Eltseq(M);
  end if;
  if assigned M`Coerce then
    Form`Coerce := M`Coerce cat [* hom< C -> C | <C.1,C.1> > *];
  end if;

  if __SANITY_CHECK then
    printf "Sanity check turned on... (AssociatedForm)";
    I := CartesianProduct( < Basis(X) : X in __FRAME(M) > );
    assert forall{ x : x in I | Coordinates(M`Codomain,< x[i] : i in [1..#x-1]> @ M)[Index(Basis(M`Codomain),x[#x])] eq (x@Form)[1] };
    printf "  DONE!\n";
  end if;
  return Form;
end intrinsic;

intrinsic IsAntisymmetric( M::TenSpcElt ) -> BoolElt
{Decides if M is antisymmetric.}
  if assigned M`Reflexive`Antisymmetric then
    return M`Reflexive`Antisymmetric;
  end if;
  if exists{ D : D in M`Domain | Dimension(D) ne Dimension(M`Domain[1]) } then
    M`Reflexive`Alternating := false;
    return false;
  end if;
  try
    _ := Eltseq(M);
  catch err
    error "Cannot compute structure constants.";
  end try;
  if M`Valence eq 3 then
    F := SystemOfForms(M);
    isit := forall{ f : f in F | Transpose(f) eq -f };
  else
    G := Parent(M`Permutation);
    Stab := Stabilizer(G,GSet(G),GSet(G)!0);

    ShuffleWithSign := function(M,g)
      s := Eltseq(Shuffle(M,g));
      if Sign(g) eq -1 then
        s := [ -x : x in s ];
      end if;
      return s;
    end function;

    isit := forall{ g : g in Stab | Eltseq(M) eq ShuffleWithSign(M,g) };
  end if;
  M`Reflexive`Antisymmetric := isit;
  if Characteristic(BaseRing(M)) ne 2 then
    M`Reflexive`Alternating := isit;
  end if;
  return isit;
end intrinsic;

intrinsic IsAlternating( t::TenSpcElt ) -> BoolElt
{Decides if t is alternating.}
  K := BaseRing(t);
  if Characteristic(K) ne 2 then
    return IsAntisymmetric(t);
  end if;
  if not IsAntisymmetric(t) then
    return false;
  end if;
  isit := forall{ i : i in [1..Dimension(t`Domain[1])] | 
          Slice(t, [ {i} : j in [1..#t`Domain] ] cat [{1..Dimension(t`Codomain)}] ) eq [0 : j in [1..Dimension(t`Codomain)]] };
  t`Reflexive`Alternating := isit;
  return isit;
end intrinsic;

intrinsic IsSymmetric( M::TenSpcElt ) -> BoolElt
{Decides if M is symmetric.}
  if assigned M`Reflexive`Symmetric then
    return M`Reflexive`Symmetric;
  end if;
  if exists{ D : D in M`Domain | Dimension(D) ne Dimension(M`Domain[1]) } then
    M`Reflexive`Symmetric := false;
    return false;
  end if;
  try
    _ := Eltseq(M);
  catch err
    error "Cannot compute structure constants.";
  end try;
  if M`Valence eq 3 then
    F := SystemOfForms(M);
    isit := forall{ f : f in F | Transpose(f) eq f };
  else
    G := Parent(M`Permutation);
    Stab := Stabilizer(G,GSet(G),GSet(G)!0);
    isit := forall{ g : g in Stab | Eltseq(M) eq Eltseq(Shuffle(M,g)) };
  end if;
  M`Reflexive`Symmetric := isit;
  return isit;
end intrinsic;

// ==============================================================================
//                               Categorical stuff
// ==============================================================================
// Only implemented for homotopism category.
// ------------------------------------------------------------------------------
//                                     Submaps
// ------------------------------------------------------------------------------
intrinsic Subtensor( M::TenSpcElt, D::List, C::. ) -> TenSpcElt
{Returns the smallest submap of M containing the Cartesian product of D in the domain and C in the codomain.}
  require #D eq #M`Domain : "Argument 2 does not match the valence of argument 1.";
  if exists{ X : X in Frame(M) | Type(X) notin __LIST } then
    passed, M, _, err := __TensorOnVectorSpaces(M);
    require passed : err;
  end if;
  // Get the domain and codomain down to standard objects. 
  // Also, check that they lie in the correct spaces.  
  Dom := __GenerateDomain( M, D );
  require Type(Dom) ne BoolElt : "Argument 2 is not in the domain.";
  Cod := __GenerateCodomain( M, C );
  require Type(Cod) ne BoolElt : "Argument 3 is not in the codomain.";

  // Fill the image
  gens := CartesianProduct( < Basis(Dom[i]) : i in [1..#M`Domain] > );
  Cod := sub< M`Codomain | Cod, { g @ M : g in gens } >;
  if __HasBasis(C) then // remove superfluous generators
    Cod := sub< M`Codomain | Basis(Cod) >;
  end if;

  F := function(x)
    return < (M`Domain)[i]!(x[i]) : i in [1..#M`Domain] > @ M;
  end function;

  S := __GetTensor( Dom, Cod, F : Cat := M`Cat );
  return S;
end intrinsic;

intrinsic Subtensor( M::TenSpcElt, S::List ) -> TenSpcElt
{Returns the smallest submap of M containing S. 
The first v entries of S are contained in the domain of M, and the last entry of S is contained in the codomain of M.}
  return Subtensor( M, S[1..M`Valence-1], S[M`Valence] );
end intrinsic;

intrinsic IsSubtensor( M::TenSpcElt, N::TenSpcElt ) -> BoolElt
{Decides if N is a subtensor of M.}
  require M`Cat eq N`Cat : "Tensors not in the same category.";
  if exists{ X : X in Frame(M) | Type(X) notin __LIST } then
    passed, M, H2, err := __TensorOnVectorSpaces(M);
    require passed : err;
  end if;
  if exists{ X : X in Frame(N) | Type(X) notin __LIST } then
    passed, N, _, err := __TensorOnVectorSpaces(N);
    require passed : err;
  end if;
  if Parent(M) ne Parent(N) then
    return false;
  end if;

  d := forall{ i : i in [1..#N`Domain] | forall{ b : b in Basis(N`Domain[i]) | IsCoercible(M`Domain[i],b) } };
  if d then
    c := forall{ b : b in Basis(N`Codomain) | IsCoercible(M`Codomain,b) };
  else
    return false;
  end if;
  return c;
end intrinsic;

// ------------------------------------------------------------------------------
//                                     Ideals
// ------------------------------------------------------------------------------
intrinsic LocalIdeal( M::TenSpcElt, D::List, C::., I::{RngIntElt} ) -> TenSpcElt
{Returns the smallest submap of M which is a local ideal containing D in the domain and C in the codomain. 
Here, I is a subset of integers corresponding to the Cartesian factors in the domain.}
  require Arrows(M`Cat) eq [ 1 : i in [1..M`Valence] ] : "Ideal not implemented for this category.";
  require #D eq #M`Domain : "Argument 2 does not match the valence of argument 1.";
  require forall{ X : X in Frame(M) | Type(X) in __LIST } : "Domain and codomain must be vector spaces.";
  require I subset {1..#M`Domain} : "Argument 4 contains unknown values.";
  I := {@ M`Valence-s : s in I @};
  // Get the domain and codomain down to standard objects. 
  // Also, check that they lie in the correct spaces.  
  Dom := __GenerateDomain( M, D );
  require Type(D) ne BoolElt : "Argument 2 is not in the domain.";
  Cod := __GenerateCodomain( M, C );
  require Type(C) ne BoolElt : "Argument 3 is not in the codomain.";

  // Fill the image.
  Im := {};
  for s in I do
    temp := [* X : X in Dom *];
    temp[s] := M`Domain[s];
    gens := CartesianProduct( < Basis( temp[i] ) : i in [1..#M`Domain] > );
    Im join:= { g : g in gens };
  end for;
  Cod := sub< M`Codomain | Cod, { g @ M : g in Im } >;
  Cod := sub< M`Codomain | Basis(Cod) >; // reduce the number of generators.
  
  F := function(x)
    return < (M`Domain)[i]!(x[i]) : i in [1..#M`Domain] > @ M;
  end function;

  N := __GetTensor( Dom, Cod, F : Cat := M`Cat );
  return N;
end intrinsic;

intrinsic LocalIdeal( M::TenSpcElt, S::List, I::{RngIntElt} ) -> TenSpcElt
{Returns the smallest submap of M which is a local ideal containing S. 
Here, I is a subset of integers corresponding to the Cartesian factors in the domain.}
  return LocalIdeal( M, S[1..M`Valence-1], S[M`Valence], I );
end intrinsic;

intrinsic LocalIdeal( M::TenSpcElt, N::TenSpcElt, I::{RngIntElt} ) -> TenSpcElt
{Returns the smallest submap of M which is a local ideal containing N. 
Here, I is a subset of integers corresponding to the Cartesian factors in the domain.}
  return LocalIdeal( M, [* x : x in N`Domain *], N`Codomain, I );
end intrinsic;

intrinsic IsLocalIdeal( M::TenSpcElt, N::TenSpcElt, S::{RngIntElt} ) -> BoolElt
{Decide if N is a local ideal of M. 
Here, S is a subset of integers corresponding to the Cartesian factors in the domain.}
  require M`Cat eq N`Cat : "Tensors not in the same category.";
  require Arrows(M`Cat) eq [ 1 : i in [1..M`Valence] ] : "Ideals not implemented for this category.";
  require forall{ X : X in Frame(M) | Type(X) in __LIST } : "Domain and codomain of tensors must be vector spaces.";
  require forall{ X : X in Frame(N) | Type(X) in __LIST } : "Domain and codomain of tensors must be vector spaces.";
  if Parent(M) ne Parent(N) then
    return false;
  end if;
  n := #M`Domain;
  require S subset {1..n} : "Argument 3 contains unknown values.";
  S := {@ n-s+1 : s in S @};

  if not IsSubtensor(M,N) then
    return false;
  end if;

  // Check the definition.
  for s in S do
    temp := [* x : x in N`Domain *];
    temp[s] := M`Domain[s];
    gens := CartesianProduct( < Basis( temp[i] ) : i in [1..n] > );
    if exists{ g : g in gens | g @ M notin N`Codomain } then
      return false;
    end if;
  end for;
  return true;
end intrinsic;

intrinsic Ideal( M::TenSpcElt, D::List, C::. ) -> TenSpcElt
{Returns the smallest submap of M containing D in the domain and C in the codomain that is an ideal of M.}
  return LocalIdeal( M, D, C, {1..#M`Domain} );
end intrinsic;

intrinsic Ideal( M::TenSpcElt, S::List ) -> TenSpcElt
{Returns the smallest submap of M containing S that is an ideal of M.}
  return LocalIdeal( M, S[1..M`Valence-1], S[M`Valence], {1..#M`Domain} );
end intrinsic;

intrinsic Ideal( M::TenSpcElt, N::TenSpcElt ) -> TenSpcElt
{Returns the smallest submap of M containing N that is an ideal of M.}
  require M`Valence eq N`Valence : "Valences do not match.";
  return LocalIdeal( M, [* x : x in N`Domain *], N`Codomain, {1..#M`Domain} );
end intrinsic;

intrinsic IsIdeal( M::TenSpcElt, N::TenSpcElt ) -> BoolElt
{Decides if N is an ideal of M.}
  return IsLocalIdeal( M, N, {1..#N`Domain} );
end intrinsic;

// ------------------------------------------------------------------------------
//                                    Quotients
// ------------------------------------------------------------------------------
intrinsic LocalQuotient( M::TenSpcElt, N::TenSpcElt, S::SetEnum : Check := true ) -> TenSpcElt, Hmtp
{Returns the local quotient of M by the local ideal N. 
Here, S is a subset of integers corresponding to the Cartesian factors in the domain.}
  require M`Cat eq N`Cat : "Tensors not in the same category.";
  require Arrows(M`Cat) eq [ 1 : i in [1..M`Valence] ] : "Quotient not implemented for this category.";
  if exists{ X : X in Frame(M) | Type(X) notin __LIST } then
    passed, M, H2, err := __TensorOnVectorSpaces(M);
    require passed : err;
  end if;
  if exists{ X : X in Frame(N) | Type(X) notin __LIST } then
    passed, N, _, err := __TensorOnVectorSpaces(N);
    require passed : err;
  end if;
  require Parent(M) eq Parent(N) : "Tensors are from different tensor spaces.";
  n := #M`Domain;
  require S subset {1..n} : "Argument 3 contains unknown values.";
  
  // Check S-ideal properties.
  if Check then
    require IsLocalIdeal( M, N, S ) : "Argument is not a local ideal.";
  end if;
  S := {@ n-s+1 : s in S @};

  D := [* *];
  projs := [* *];
  for i in [1..n] do
    if i in S then
      Q,pi := M`Domain[i] / N`Domain[i];
    else
      Q := M`Domain[i];
      pi := hom< Q -> Q | [ <x,x> : x in Basis( Q ) ] >;
    end if;
    Append( ~D, Q );
    Append( ~projs, pi );
  end for;
  C, pi := M`Codomain / N`Codomain;
  Append( ~projs, pi );

  F := function(x)
    return < x[i] @@ projs[i] : i in [1..n] > @ M @ pi;
  end function;

  Q := __GetTensor( D, C, F : Cat := M`Cat );
  H := __GetHomotopism( M, Q, projs : Cat := HomotopismCategory(M`Valence : Contravariant := M`Cat`Contra) );
  if assigned H2 then
    H := H2*H;
  end if;
  return Q, H;
end intrinsic;

intrinsic Quotient( M::TenSpcElt, N::TenSpcElt : Check := true ) -> TenSpcElt, Hmtp
{Returns the quotient of M by the ideal N.}
  require M`Cat eq N`Cat : "Tensors not in the same category.";
  require Arrows(M`Cat) eq [ 1 : i in [1..M`Valence] ] : "Quotient not implemented for this category.";
  if Check then
    require IsIdeal( M, N ) : "Arugment is not an ideal.";
  end if;
  return LocalQuotient( M, N, {1..#M`Domain} : Check := false );
end intrinsic;

intrinsic '/'( M::TenSpcElt, N::TenSpcElt ) -> TenSpcElt, Hmtp
{Returns the quotient M/N.}
  return Quotient(M,N);
end intrinsic;
