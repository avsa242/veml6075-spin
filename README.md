# veml6075-spin 
---------------

This is a P8X32A/Propeller 1, P2X8C4M64P/Propeller 2 driver object for the Vishay VEML6075 UVA/B sensor.

## Salient Features

* I2C connection up to 400kHz
* Reads UVA, UVB, Visible, IR sensor data
* Supports changing ADC integration time
* Supports continuous or single-measurement modes

## Requirements

* P1: 1 extra core/cog for the PASM I2C driver
* P2: N/A

## Compiler Compatibility

- [x] P1/SPIN1: OpenSpin (tested with 1.00.81)
- [x] P2/SPIN2: FastSpin (tested with 4.0.3-beta)

## Limitations

* Very early in development - may malfunction or outright fail to build
* Not calibrated

## TODO

- [x] Add methods to configure the device
- [ ] Add method to calculate UV index
