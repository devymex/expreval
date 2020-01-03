#include <map>
#include <iostream>

extern "C" void initialize(const std::map<std::string, double> &varMap);
extern "C" double evaluate(const char *pStr);

int main(int nArgCnt, char *ppArgs[]) {
	std::map<std::string, double> varMap;
	varMap["_a"] = 3.4;
	varMap["_v2"] = 5.6;
	initialize(varMap);

	std::string strExpr = "_v2<1?-(3)*-(2+-5):max(-min(2.6,1),_a)";
	std::cout << strExpr << "=" << evaluate(strExpr.c_str()) << std::endl;
	return 0;
}
