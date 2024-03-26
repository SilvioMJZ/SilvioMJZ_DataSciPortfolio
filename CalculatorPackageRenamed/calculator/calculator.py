#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Sun Mar 24 10:10:21 2024

@author: mao
"""

class Calculator:
    
    """A calculator class which adds, subtracts, multiplies, divides, 
    takes nth root and resets.
    """
    
    init_value = 0
    
    @classmethod
    def add(cls, number: float) -> float:
        """Adds a number to the initial value"""
        cls.init_value += number
        return cls.init_value
    
    @classmethod
    def subtract(cls, number: float) -> float:
        """Subtracts a number from the initial value"""
        cls.init_value -= number
        return cls.init_value
    
    @classmethod
    def multiply(cls, number: float) -> float:
        """Multiplies the initial value by a number"""
        cls.init_value *= number
        return cls.init_value
    
    @classmethod
    def divide(cls, number: float) -> float:
        """Divides initial value by a number. 
        Dividing by zero raises ValueError
        """
        if number == 0 :
           raise ValueError("Cannot divide by zero") 
        cls.init_value /= number
        return cls.init_value
    
    @classmethod
    def n_root(cls, number: float) -> float:
        """Takes the nth root of the initial value.
        Negative number values raise ValueError
        """
        if number == 0 :
           raise ValueError("Cannot take the root as a negative number")
        cls.init_value **= (1/number)
        return cls.init_value
    
    @classmethod
    def reset(cls) -> float:
        """Resets calculator to zero"""
        cls.init_value = 0
        return cls.init_value