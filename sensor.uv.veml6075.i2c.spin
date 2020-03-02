{
    --------------------------------------------
    Filename: sensor.uv.veml6075.i2c.spin
    Author: Jesse Burt
    Description: Driver for the Vishay VEML6075 UVA/UVB sensor
    Copyright (c) 2019
    Started Aug 18, 2019
    Updated Aug 19, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR            = core#SLAVE_ADDR
    SLAVE_RD            = core#SLAVE_ADDR|1

    DEF_SCL             = 28
    DEF_SDA             = 29
    DEF_HZ              = 400_000
    I2C_MAX_FREQ        = core#I2C_MAX_FREQ

' Dynamic settings
    DYNAMIC_NORM        = 0
    DYNAMIC_HI          = 1

' Measurement modes
    CONT                = 0
    SINGLE              = 1

VAR


OBJ

    i2c : "com.i2c"                                             'PASM I2C Driver
    core: "core.con.veml6075"
    time: "time"                                                'Basic timing functions

PUB Null
''This is not a top-level object

PUB Start: okay                                                 'Default to "standard" Propeller I2C pins and 400kHz

    okay := Startx (DEF_SCL, DEF_SDA, DEF_HZ)

PUB Startx(SCL_PIN, SDA_PIN, I2C_HZ): okay | tmp

    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31)
        if I2C_HZ =< core#I2C_MAX_FREQ
            if okay := i2c.setupx (SCL_PIN, SDA_PIN, I2C_HZ)    'I2C Object Started?
                time.MSleep (100)
                if present
                    if DeviceID == core#DEV_ID_RESP
                        return okay

    return FALSE                                                'If we got here, something went wrong

PUB Stop

    Powered(FALSE)
    time.MSleep(1)
    i2c.terminate

PUB DeviceID
' Device ID of the chip
'   Known values: $0026
    result := $0000
    readReg(core#DEV_ID, 2, @result)

PUB Dynamic(level) | tmp
' Set sensor dynamic
'   Valid values: DYNAMIC_NORM (0), DYNAMIC_HI (1)
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#UV_CONF, 2, @tmp)
    case level
        DYNAMIC_NORM, DYNAMIC_HI:
            level <<= core#FLD_HD
        OTHER:
            result := (tmp >> core#FLD_HD) & %1
            return
    tmp &= core#MASK_HD
    tmp := (tmp | level) & core#UV_CONF_MASK
    tmp.byte[1] := $00
    writeReg(core#UV_CONF, 2, @tmp)

PUB IntegrationTime(ms) | tmp
' Set sensor ADC integration time, in ms
'   Valid values: 50, 100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#UV_CONF, 2, @tmp)
    case ms
        50, 100, 200, 400, 800:
            ms := lookdownz(ms: 50, 100, 200, 400, 800) << core#FLD_UV_IT
        OTHER:
            tmp := (tmp >> core#FLD_UV_IT) & core#BITS_UV_IT
            result := lookupz(tmp: 50, 100, 200, 400, 800)
            return
    tmp &= core#MASK_UV_IT
    tmp := (tmp | ms) & core#UV_CONF_MASK
    tmp.byte[1] := $00
    writeReg(core#UV_CONF, 2, @tmp)

PUB Measure | tmp
' Trigger a single measurement
'   NOTE: For use when MeasureMode is set to SINGLE
    tmp := $0000
    readReg(core#UV_CONF, 2, @tmp)
    tmp &= core#MASK_UV_TRIG    ' Supposed to be cleared by the device automatically - just being thorough
    tmp.byte[0] |= (1 << core#FLD_UV_TRIG)
    tmp.byte[1] := $00
    writeReg(core#UV_CONF, 2, @tmp)

PUB OpMode(mode) | tmp
' Set measurement mode
'   Valid values:
'       CONT (0): Continuous measurement mode
'       SINGLE (1): Single-measurement mode only
'   Any other value polls the chip and returns the current setting
'   NOTE: In MMODE_ONE mode, measurements must be triggered manually using the Measure method
    tmp := $0000
    readReg(core#UV_CONF, 2, @tmp)
    case mode
        CONT, SINGLE:
            mode <<= core#FLD_UV_AF
        OTHER:
            result := (tmp >> core#FLD_UV_AF) & %1
            return
    tmp &= core#MASK_UV_AF
    tmp := (tmp | mode) & core#UV_CONF_MASK
    tmp.byte[1] := $00
    writeReg(core#UV_CONF, 2, @tmp)

PUB Powered(enabled) | tmp
' Power on sensor
'   Valid values:
'       TRUE (-1 or 1): Power on
'       FALSE (0): Power off
'   Any other value polls the chip and returns the current setting
    tmp := $0000
    readReg(core#UV_CONF, 2, @tmp)
    case ||enabled
        0, 1:
            enabled := (||enabled ^ 1) & %1
        OTHER:
            return (tmp & %1) * TRUE

    tmp &= core#MASK_SD
    tmp := (tmp | enabled) & core#UV_CONF_MASK
    tmp.byte[1] := $00
    writeReg(core#UV_CONF, 2, @tmp)

PUB UVAData
' Read UV-A sensor data
'   Returns: 16-bit word
    readReg(core#UVA_DATA, 2, @result)

PUB UVBData
' Read UV-B sensor data
'   Returns: 16-bit word
    readReg(core#UVB_DATA, 2, @result)

PUB VisibleData
' Read Visible sensor data
'   Returns: 16-bit word
    readReg(core#UVCOMP1, 2, @result)

PUB IRData
' Read Infrared sensor data
'   Returns: 16-bit word
    readReg(core#UVCOMP2, 2, @result)

PRI present | tmp
' Flag indicating the device responds on the I2C bus
    i2c.Start
    tmp := i2c.Write (SLAVE_WR)
    i2c.Stop
    result := (tmp == i2c#ACK)

PRI readReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Read num_bytes from the slave device into the address stored in buff_addr
    case reg                                                    'Basic register validation
        core#UV_CONF, core#UVA_DATA..core#DEV_ID:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.start
            i2c.wr_block (@cmd_packet, 2)
            i2c.Wait (SLAVE_RD)
            i2c.rd_block (buff_addr, nr_bytes, TRUE)
            i2c.stop
        OTHER:
            return

PRI writeReg(reg, nr_bytes, buff_addr) | cmd_packet, tmp
'' Write num_bytes to the slave device from the address stored in buff_addr
    case reg                                                    'Basic register validation
        core#UV_CONF:
            cmd_packet.byte[0] := SLAVE_WR
            cmd_packet.byte[1] := reg
            i2c.start
            i2c.wr_block (@cmd_packet, 2)
            repeat tmp from 0 to nr_bytes-1
                i2c.write (byte[buff_addr][tmp])
            i2c.stop
        OTHER:
            return


DAT
{
    --------------------------------------------------------------------------------------------------------
    TERMS OF USE: MIT License

    Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
    associated documentation files (the "Software"), to deal in the Software without restriction, including
    without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the
    following conditions:

    The above copyright notice and this permission notice shall be included in all copies or substantial
    portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT
    LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
    IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
    WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
    SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
    --------------------------------------------------------------------------------------------------------
}
