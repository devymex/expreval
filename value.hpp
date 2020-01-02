#ifndef __VALUE_HPP
#define __VALUE_HPP

#include <map>
typedef enum {VT_FLOAT, VT_INT} VALUE_TYPE;

typedef struct _VALUE {
	union {
		int ival;
		float fval;
	};
	VALUE_TYPE type;
} VALUE;

extern std::map<std::string, float> varValue;

#endif
