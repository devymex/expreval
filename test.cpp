#include <iostream>
#include "expreval.h"

int main(int nArgCnt, char *ppArgs[]) {
	initialize();

	add_variable("img_h", 500.);
	add_variable("img_w", 1000.);
	add_variable("input_h", 224.);
	add_variable("input_w", 224.);
	add_variable("box_x", 0);
	add_variable("box_y", 0);
	add_variable("box_w", 400);
	add_variable("box_h", 200);

	int nRet = remove_variable("_bad_var");
	if (nRet != 0) {
		std::cout << format_error_message(nRet) << std::endl;
	}
	set_variable_value("input_h", 112);

	std::string strExpr = "((img_h < img_w) ? (input_h * max(max(img_h / input_h / 1.2, img_w / input_w / 1.2), 1)) : img_w)";
	std::cout << strExpr << '\n' << evaluate(strExpr.c_str()) << std::endl;

	strExpr = "box_x - max(3 * box_w, 4 * box_h) * 1.25 / box_w";
	std::cout << strExpr << '\n' << evaluate(strExpr.c_str()) << std::endl;
	return 0;
}
