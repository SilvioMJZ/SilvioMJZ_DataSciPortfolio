#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Mon Mar 25 13:18:48 2024

@author: mao
"""

from smjz.calculator import Calculator

def test_add():
    Calculator.reset()
    Calculator.add(5)
    assert Calculator.init_value == 5
    print("test_add passed")

def test_subtract():
    Calculator.reset()
    Calculator.subtract(3)
    assert Calculator.init_value == -3
    print("test_subtract passed")

def test_multiply():
    Calculator.reset()
    Calculator.add(2)  
    Calculator.multiply(4)
    assert Calculator.init_value == 8
    print("test_multiply passed")

def test_divide():
    Calculator.reset()
    Calculator.add(8)  
    Calculator.divide(2)
    assert Calculator.init_value == 4
    print("test_divide passed")

def test_n_root():
    Calculator.reset()
    Calculator.add(4)  
    Calculator.n_root(2)
    assert Calculator.init_value == 2
    print("test_n_root passed")

def test_reset():
    Calculator.reset()
    Calculator.add(10)  
    Calculator.reset()
    assert Calculator.init_value == 0
    print("test_reset passed")

def test_divide_by_zero():
    Calculator.reset()
    try:
        Calculator.divide(0)
        print("test_divide_by_zero failed: No ValueError raised")
    except ValueError:
        print("test_divide_by_zero passed")

test_add()
test_subtract()
test_multiply()
test_divide()
test_n_root()
test_reset()
test_divide_by_zero()
