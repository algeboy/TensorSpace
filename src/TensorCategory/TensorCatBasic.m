/* 
    Copyright 2016, 2017, Joshua Maglione, James B. Wilson.
    Distributed under MIT License.
*/


/*
  This file contains basic functions for tensor categories (TenCat).
*/


// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
//                                  Intrinsics
// ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
intrinsic Valence( C::TenCat ) -> RngIntElt
{Returns the valence of the tensor category.}
  return C`Valence;
end intrinsic;

intrinsic RepeatPartition( C::TenCat ) -> SetEnum
{Returns the repeat partition of the tensor category.}
  P := C`Repeats;
  if C`Contra then
    assert {0} in P;
    Exclude(~P,{0});
  end if;
  return P;
end intrinsic;

intrinsic IsCovariant( C::TenCat ) -> BoolElt
{Decides if the tensor category is covariant .}
  return not C`Contra;
end intrinsic;

intrinsic IsContravariant( C::TenCat ) -> BoolElt
{Decides if the tensor category is contravariant.}
  return C`Contra;
end intrinsic;

intrinsic Arrows( C::TenCat ) -> SeqEnum
{Returns the directions of the arrows of the category. 
A -1 signifies an up arrow, a 0 signifies an equal arrow, and a 1 signifies a down arrow.}
  if C`Contra then 
    return [ i @ C`Arrows : i in Reverse([1..C`Valence-1]) ];
  else
    return [ i @ C`Arrows : i in Reverse([0..C`Valence-1]) ];
  end if;
end intrinsic;
