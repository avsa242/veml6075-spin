# veml6075-spin 
---------------

This is a P8X32A/Propeller driver object for the Vishay VEML6075 UVA/B sensor.

## Salient Features

* I2C connection up to 400kHz
* Reads UVA, UVB, Visible, IR sensor data
* Supports changing ADC integration time

## Requirements

* 1 extra core/cog for the PASM I2C driver

## Limitations

* Very early in development - may malfunction or outright fail to build
* Not calibrated

## TODO

- [x] Add methods to configure the device
- [ ] Add method to calculate UV index
