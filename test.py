import ctypes, os

# Loading module from so file
module = ctypes.CDLL('%s/eval.so' % os.getcwd())

# Setup interfaces
module.set_variables_py.argtypes = [ctypes.py_object]
module.evaluate.argtypes = [ctypes.c_char_p]
module.evaluate.restype = ctypes.c_double

# Setup variables
vars = {}
vars['_a'] = 3.4
vars['_v2'] = 5.6
module.set_variables_py(vars)

# Evaluate
expr = '_v2<1?-(3)*-(2+-5):max(-min(2.6,1),_a)';
ret = module.evaluate(expr.encode('utf-8'))
print('%s=%f' % (expr, ret))

