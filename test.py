#!/usr/bin/python3

import ctypes, os, libexpreval as expr

# Setup variables

expr.add_variable("img_h", 500)
expr.add_variable("img_w", 1000)
expr.add_variable("input_h", 224)
expr.add_variable("input_w", 224)
expr.add_variable("box_x", 0)
expr.add_variable("box_y", 0)
expr.add_variable("box_w", 400)
expr.add_variable("box_h", 200)
expr.add_variable("_bad_var")

expr.remove_variable('_bad_var')
expr.set_variable_value('input_h', 112)

# Evaluate
def evaluate(str):
	ret = expr.evaluate(str)
	print('%s\n%f' % (str, ret))

evaluate('((img_h < img_w) ? (input_h * max(max(img_h / input_h / 1.2, img_w / input_w / 1.2), 1)) : img_w)')

evaluate('box_x - max(3 * box_w, 4 * box_h) * 1.25 / box_w')
