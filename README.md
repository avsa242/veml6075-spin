# veml6075-spin 
---------------

This is a P8X32A/Propeller 1, P2X8C4M64P/Propeller 2 driver object for the Vishay VEML6075 UVA/B sensor.

**IMPORTANT**: This software is meant to be used with the [spin-standard-library](https://github.com/avsa242/spin-standard-library) (P8X32A) or [p2-spin-standard-library](https://github.com/avsa242/p2-spin-standard-library) (P2X8C4M64P). Please install the applicable library first before attempting to use this code, otherwise you will be missing several files required to build the project.

## Salient Features

* I2C connection up to 400kHz
* Reads UVA, UVB, Visible, IR sensor data
* Supports changing ADC integration time
* Supports continuous or single-measurement modes

## Requirements

P1/SPIN1:
* spin-standard-library
* P1: 1 extra core/cog for the PASM I2C driver

P2/SPIN2:
* p2-spin-standard-library

## Compiler Compatibility

* P1/SPIN1: OpenSpin (tested with 1.00.81)
* P2/SPIN2: FastSpin (tested with 4.1.10-beta)
* ~~BST~~ (incompatible - no preprocessor)
* ~~Propeller Tool~~ (incompatible - no preprocessor)
* ~~PNut~~ (incompatible - no preprocessor)

## Limitations

* Very early in development - may malfunction or outright fail to build
* Not calibrated

## TODO

- [x] Add methods to configure the device
- [ ] Add method to calculate UV index
