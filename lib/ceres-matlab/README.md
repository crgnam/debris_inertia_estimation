# CERES MatLab
This repository currently contains the prototype layout of CERES written natively in MATLAB

## Setup

1. To use `ceres-matlab`, first clone the repository to your local machine.  
2. Once it is cloned to your machine, startup MATLAB
3. Once MATLAB has started, navigate to ceres-matlab/setup
4. Run the script `install_mice.m` from within the ceres-matlab/setup directory

While most 3rd party libraries/dependencies have been included directly in `lib/`, JPL's MICE has been excluded due to its large size.  Therefore, the above steps are used to automatically obtain the most recent version of MICE to be used with CERES.

## Demos
Several demos demonstrating various capabilities of CERES have been included in `ceres-matlab/demos`.  All of these projects should run without issue, and can serve as a basis for understanding the inner workings of CERES.

***
# Documentation

*Coming Soon*

***
### Additional Information
This project is maintained by Chris Gnam: crgnam@buffalo.edu
Future releases, the MATLAB API will be a binding to an implementation in C++

For more information, please visit: www.ceresnavigation.org
