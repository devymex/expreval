#!/usr/bin/python3

import ctypes, os

# Loading module from so file
module = ctypes.CDLL('%s/libexpreval.so' % os.getcwd())

# Setup interfaces
module.initialize_py.argtypes = [ctypes.py_object]
module.set_variable_value.argtypes = [ctypes.c_char_p, ctypes.c_double]
module.evaluate.argtypes = [ctypes.c_char_p]
module.evaluate.restype = ctypes.c_double

def initialze():
	# Setup variables
	vars = {}
	vars['img_h'] = 500.;
	vars['img_w'] = 1000.;
	vars['input_h'] = 224.;
	vars['input_w'] = 224.;
	print(vars)
	module.initialize_py(vars)
	for x in range(5):
		module.set_variable_value('img_w'.encode('utf-8'), 300.)
		module.set_variable_value('input_h'.encode('utf-8'), 112.)

# Evaluate
def evaluate(str):
	ret = module.evaluate(str.encode('utf-8'))
	print('%s=%f' % (str, ret))

initialze()
evaluate('(!(img_h < img_w) ? (input_h * max(max(img_h / input_h / 1.2, img_w / input_w / 1.2), 1)) : img_w)')

