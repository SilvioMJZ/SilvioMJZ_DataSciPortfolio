# Calculator Package

## Introduction
This package provides a simple calculator class that performs operations such as addition, subtraction, multiplication, division, nth root calculation, and the ability to reset the calculator's state.

## Installation
To install the package from a private repository, use the following pip command in your shell. Replace `{token}` with your actual GitHub personal access token:

    pip install git+https://github.com/TuringCollegeSubmissions/mjurad-DWWP.1.5.git

Note: In Jupyter notebooks (like Google Colab), replace `pip` with `!pip`.

## Installation in Google Colab
For Google Colab users needing to install the package from a private repository:

    from getpass import getpass
    token = getpass('Enter your GitHub token: ')
    repository_url = f"https://YOUR_GITHUB_USERNAME:{token}@github.com/TuringCollegeSubmissions/mjurad-DWWP.1.5.git"
    !pip install git+{repository_url}

Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username. This method keeps your token secure.

## Usage

Here’s how you can use the calculator module:

    from smjz.calculator import Calculator

    # Initialize the Calculator
    calc = Calculator()

    # Perform basic arithmetic operations
    print("Addition:", calc.add(5))           # Output: 5
    print("Subtraction:", calc.subtract(2))   # Output: 3
    print("Multiplication:", calc.multiply(4))# Output: 12
    print("Division:", calc.divide(2))        # Output: 6.0
    print("Nth Root:", calc.n_root(2))        # Output: 2.449489742783178

    # Reset the calculator to its initial state
    calc.reset()
    print("After reset:", calc.init_value)    # Output: 0

Note: The calculator uses a class variable for maintaining its state, so the operations are cumulative as demonstrated above.

## Testing

The package includes tests to ensure the functionality of the Calculator module, found in `test_calculator.py`. Additionally, there is a Google Colab notebook, `testing_calculator.ipynb`, for testing without local environment setup.

### Running Tests Locally

To run tests locally (requires pytest):

    pytest smjz/test_calculator.py

### Running Tests in Google Colab

For testing the Calculator module in Google Colab:

1. Open the [Testing Calculator Notebook](https://github.com/TuringCollegeSubmissions/mjurad-DWWP.1.5/blob/master/smjz/testing_calculator.ipynb) in Google Colab.

2. Authenticate and install the package:

       from getpass import getpass
       token = getpass('Enter your GitHub token: ')
       !pip install git+https://YOUR_GITHUB_USERNAME:{token}@github.com/TuringCollegeSubmissions/mjurad-DWWP.1.5.git

   Replace `YOUR_GITHUB_USERNAME` with your GitHub username.

3. Run the provided test functions within the notebook. Just as in `test_calculator.py`, a successful test will print a confirmation message; a failure will indicate an error.
