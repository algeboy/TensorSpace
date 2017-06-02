/* 
    Copyright 2016, 2017, Joshua Maglione, James B. Wilson.
    Distributed under GNU GPLv3.
*/


/*
  This file contains all the low-level definitions for tensor categories (TenCat).
*/


// ------------------------------------------------------------------------------
//                                      Print
// ------------------------------------------------------------------------------
intrinsic Print( t::TenCat )
{Print t}
  if t`Contra then
    s := "Cotensor category of valence ";
  else
    s := "Tensor category of valence ";
  end if;
  s cat:= Sprintf( "%o (", t`Valence );
  a := t`Arrows;
  i := t`Valence-1;
  while i ge 0 do
    s cat:= ( i @ a eq 1 ) select "->" else (i @ a eq -1) select "<-" else "==";
    i -:= 1;
    s cat:= (i eq -1) select ")" else ",";
  end while;
  
  P := t`Repeats;
  i := #P;
  s cat:= " (";
  for X in P do
  	s cat:= Sprintf( "%o", X);
    i -:= 1;
    s cat:= (i eq 0) select ")" else ",";
  end for;

  printf s;
end intrinsic;

// ------------------------------------------------------------------------------
//                                    Compare
// ------------------------------------------------------------------------------
intrinsic 'eq'(TC1::TenCat, TC2::TenCat) -> BoolElt
{TC1 eq TC2}
  return (TC1`Valence eq TC2`Valence) and (TC1`Repeats eq TC2`Repeats) and forall{ x : x in Domain(TC1`Arrows) | (x @ TC1`Arrows) eq (x @ TC2`Arrows) };
end intrinsic;
