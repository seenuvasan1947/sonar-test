import os
import sys
import subprocess
import pickle

# BUG: Using eval, hardcoded credentials, unused imports

DB_PASSWORD = "password123"  # BUG: Hardcoded password
SECRET_KEY = "my-secret-key-123"  # BUG: Hardcoded secret

def process_data(data):
    """Process user input dangerously"""
    # BUG: Using eval on user input - security vulnerability
    result = eval(data)
    return result

def execute_command(user_input):
    # BUG: Command injection vulnerability
    os.system("echo " + user_input)
    subprocess.call("ls " + user_input, shell=True)

def load_config(config_path):
    # BUG: Using pickle on untrusted data
    with open(config_path, 'rb') as f:
        config = pickle.load(f)
    return config

def calculate_average(numbers):
    # BUG: No validation for empty list
    total = sum(numbers)
    average = total / len(numbers)
    return average

# BUG: Function defined but never used
def unused_function():
    x = 10
    y = 20
    z = 30
    return x + y + z

class DataHandler:
    def __init__(self):
        # BUG: Using mutable default argument
        self.data = []
        self.cache = {}
    
    def get_item(self, key):
        # BUG: No key validation, will raise KeyError
        return self.cache[key]
    
    def update(self, key, value):
        # BUG: No type checking
        self.cache[key] = value
        print("Updated: " + str(key) + " = " + str(value))

# BUG: Global variable modified in function
counter = 0

def increment_counter():
    global counter
    counter += 1

# BUG: Catching bare Exception
def risky_operation():
    try:
        result = 10 / 0
        return result
    except Exception:
        pass  # BUG: Silent exception handling
