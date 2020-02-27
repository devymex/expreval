// Expreval: A "C-like" Syntax Expression Evaluator
// Yumeng Wang (devymex@gmail.com)

#ifndef __VALUE_HPP
#define __VALUE_HPP

#include <unordered_map>
#include <string>
#include <functional>
#include <vector>

enum VALUE_TYPE {
	VT_UNKNOWN = 0,
	VT_FLOAT,
	VT_INT,
	VT_VAR,
	VT_BFUNC,
	VT_UFUNC
};

struct VALUE {
	union {
		int ival;
		double fval;
		uint32_t id;
		std::function<double(double, double)> *bfunc;
		std::function<double(double)> *ufunc;
	};
	VALUE_TYPE type;
};

inline VALUE MakeValue(VALUE_TYPE _vt, uint32_t _id) {
	VALUE val;
	val.type = _vt;
	val.id = _id;
	return val;
}

struct EXPREVAL {
	std::vector<double> varList;
	std::vector<std::function<double(double, double)>> bfuncList;
	std::vector<std::function<double(double)>> ufuncList;
	std::unordered_map<std::string, VALUE> namedTokens;
	double dResult;
	void *pScannerHdl;
};

#endif // #ifndef __VALUE_HPP
