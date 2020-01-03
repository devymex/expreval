#ifndef __VALUE_HPP
#define __VALUE_HPP

#include <map>

enum VALUE_TYPE {VT_UNKNOWN = 0, VT_FLOAT, VT_INT, VT_VAR, VT_BFUNC, VT_UFUNC};

struct VALUE {
	union {
		int ival;
		double fval;
		size_t id;
	};
	VALUE_TYPE type;
};

inline VALUE MakeValue(VALUE_TYPE _vt, size_t _id) {
	VALUE val;
	val.type = _vt;
	val.id = _id;
	return val;
}

extern std::map<std::string, VALUE> namedValues;

#endif
