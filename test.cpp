#include <map>
#include <iostream>

extern "C" void initialize(const std::map<std::string, double> &vars);
extern "C" void set_variable_value(const char *pKey, double dValue);
extern "C" double evaluate(const char *pStr);

int main(int nArgCnt, char *ppArgs[]) {
	std::map<std::string, double> vars;
	vars["img_h"] = 500.;
	vars["img_w"] = 1000.;
	vars["input_h"] = 224.;
	vars["input_w"] = 224.;
	vars["box_x"] = 0;
	vars["box_y"] = 0;
	vars["box_w"] = 400;
	vars["box_h"] = 200;

	initialize(vars);
	set_variable_value("input_h", 112);

	std::string strExpr = "((img_h < img_w) ? (input_h * max(max(img_h / input_h / 1.2, img_w / input_w / 1.2), 1)) : img_w)";
	std::cout << strExpr << std::endl << evaluate(strExpr.c_str()) << std::endl;

	strExpr = "box_x - max(3 * box_w, 4 * box_h) * 1.25 / box_w";
	std::cout << strExpr << std::endl << evaluate(strExpr.c_str()) << std::endl;
	return 0;
}
