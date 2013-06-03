/*
 * global.h
 *
 *  Created on: Apr 5, 2013
 *      Authors: vgomez, Sep Thijssen
 */

#ifndef GLOBAL_H_
#define GLOBAL_H_

#include <vector>
#include <math.h>
#include <iostream>

typedef std::vector<double> vec;
typedef std::vector<vec> vvec;

template<typename G>
std::ostream& operator<<(std::ostream& os, const std::vector<G>& v)
{
	typename std::vector<G>::const_iterator it;
	for (it=v.begin(); it!=v.end(); it++)
		std::cout << *it << " ";
	std::cout << std::endl;
	return os;
}

#endif /* GLOBAL_H_ */
