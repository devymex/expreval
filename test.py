#!/usr/bin/python3

import ctypes, os

# Loading module from so file
module = ctypes.CDLL('%s/libexpreval.so' % os.getcwd())

# Setup interfaces
module.initialize_py.argtypes = [ctypes.py_object]
module.evaluate.argtypes = [ctypes.c_char_p]
module.evaluate.restype = ctypes.c_double

# Setup variables
vars = {}
vars['a'] = 3.4
vars['v2'] = 5.6
print(vars)
module.initialize_py(vars)

# Evaluate
def evaluate(str):
	ret = module.evaluate(str.encode('utf-8'))
	print('%s=%f' % (str, ret))

evaluate('v2>1?-(3)*-(log(2)+-5):max(-min(2.6,1),a)')

