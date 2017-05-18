/*
  Global variables
*/
__VERSION := "1.1";
__SANITY_CHECK := false;
__LIST := { ModTupFld, ModFld, ModMatFld }; // suitable types we can do most computations with.
__FRAME := function( T ) // returns the 'domain' and the 'codomain'.
  if Type(T) eq TenSpcElt then
    return T`Domain cat [*T`Codomain*];
  else
    return T`Frame;
  end if;
end function;


/*
  Verbose names
*/
declare verbose Multilinear, 1; // turns verbose on for all functions below

declare verbose Centroid, 1;
declare verbose DerivationAlgebra, 1;
declare verbose DerivationClosure, 1;
declare verbose Nucleus, 1;
