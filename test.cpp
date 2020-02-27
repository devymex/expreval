#include <iostream>
#include <mutex>
#include <thread>
#include <unistd.h>

#include "expreval.h"

int main(int nArgCnt, char *ppArgs[]) {
	std::mutex outputLock;
	auto PrintOutput = [&](const std::string &strExpr, double dResult) {
			std::lock_guard<std::mutex> locker(outputLock);
			std::cout << strExpr << '\n' << dResult << std::endl;
		};
	std::thread test1([&PrintOutput] {
			auto pExprHdl = initialize();
			add_variable(pExprHdl, "img_h", 500.);
			add_variable(pExprHdl, "img_w", 1000.);
			add_variable(pExprHdl, "input_h", 224.);
			add_variable(pExprHdl, "input_w", 224.);
			add_variable(pExprHdl, "box_x", 0);
			add_variable(pExprHdl, "box_y", 0);
			add_variable(pExprHdl, "box_w", 400);
			add_variable(pExprHdl, "box_h", 200);
			int nRet = remove_variable(pExprHdl, "_bad_var");
			if (nRet != 0) {
				std::cout << format_error_message(nRet) << std::endl;
			}
			set_variable_value(pExprHdl, "input_h", 112);
			for (int i = 0; i < 10; ++i) {
				std::string strExpr = "((img_h < img_w) ? (input_h * max(max(img_h / input_h / 1.2, img_w / input_w / 1.2), 1)) : img_w)";
				auto dResult = evaluate(pExprHdl, strExpr.c_str());
				PrintOutput(strExpr, dResult);
				usleep(100 * 1000);
			}
			unintialize(pExprHdl);
		});
	std::thread test2([&PrintOutput] {
			for (int i = 0; i < 10; ++i) {
				auto pExprHdl = initialize();
				add_variable(pExprHdl, "box_x", 0);
				add_variable(pExprHdl, "box_y", 0);
				add_variable(pExprHdl, "box_w", 400);
				add_variable(pExprHdl, "box_h", 200);

				std::string strExpr = "box_x - max(3 * box_w, 4 * box_h) * 1.25 / box_w";
				auto dResult = evaluate(pExprHdl, strExpr.c_str());
				PrintOutput(strExpr, dResult);
				unintialize(pExprHdl);
				usleep(100 * 1000);
			}
		});
	if (test1.joinable()) {
		test1.join();
	}
	if (test2.joinable()) {
		test2.join();
	}
	return 0;
}
