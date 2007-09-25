/*
GenOpt.c -- An XOP for curvefitting via Differential Evolution.
@copyright: Andrew Nelson and the Australian Nuclear Science and Technology Organisation 2007.
*/

/*
 * \brief Create a two-dimensional array in a single allocation
 *
 * The effect is the same as an array of "element p[ii][jj];
 * The equivalent declaration is "element** p;"
 * The array is created as an array of pointer to element, followed by an array of arrays of elements.
 * \param ii first array bound
 * \param jj second array bound
 * \param sz size in bytes of an element of the 2d array
 * \return NULL on error or pointer to array
 *
 * assign return value to (element**)
 */

/* to use this in practice one would write 

	double **pp = NULL;
	pp = (double**)malloc2d(5, 11, sizeof(double));
	if(pp==NULL)
		return NOMEM;
	
	<use pp as required>
	free(pp);

Note you can access elements by
	 *(*(p+i)+j) is equivalent to p[i][j]
 In addition *(p+i) points to a whole row.
	*/
#include "XOPStandardHeaders.h"

void* malloc2d(int ii, int jj, int sz)
{
  void** p;
  int sz_ptr_array;
  int sz_elt_array;
  int sz_allocation;
  int i;

  sz_ptr_array = ii * sizeof(void*);
  sz_elt_array = jj * sz;
  sz_allocation = sz_ptr_array + ii * sz_elt_array;
 
  p = (void**) malloc(sz_allocation);
  if (p == NULL)
    return p;
  memset(p, 0, sz_allocation);
  for (i = 0; i < ii; ++i)
  {
    *(p+i) = (void*) ((int)p + sz_ptr_array + i * sz_elt_array);
  }
  return p;
}