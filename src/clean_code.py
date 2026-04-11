"""Clean code example - should pass SonarQube quality gate."""

from typing import List, Optional


def calculate_average(numbers: List[float]) -> Optional[float]:
    """Calculate the average of a list of numbers safely."""
    if not numbers:
        return None
    
    total = sum(numbers)
    return total / len(numbers)


def greet_user(name: str) -> str:
    """Return a greeting message."""
    if not name:
        return "Hello, Guest!"
    
    return f"Hello, {name}!"


class TemperatureConverter:
    """Convert temperatures between Celsius and Fahrenheit."""
    
    @staticmethod
    def celsius_to_fahrenheit(celsius: float) -> float:
        """Convert Celsius to Fahrenheit."""
        return (celsius * 9 / 5) + 32
    
    @staticmethod
    def fahrenheit_to_celsius(fahrenheit: float) -> float:
        """Convert Fahrenheit to Celsius."""
        return (fahrenheit - 32) * 5 / 9
