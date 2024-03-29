{
    --------------------------------------------
    Filename: sensor.light.veml6075.spin
    Author: Jesse Burt
    Description: Driver for the Vishay VEML6075 UVA/UVB sensor
    Copyright (c) 2022
    Started Aug 18, 2019
    Updated Sep 26, 2022
    See end of file for terms of use.
    --------------------------------------------
}

CON

    SLAVE_WR        = core#SLAVE_ADDR
    SLAVE_RD        = core#SLAVE_ADDR|1

    DEF_SCL         = 28
    DEF_SDA         = 29
    DEF_HZ          = 100_000
    I2C_MAX_FREQ    = core#I2C_MAX_FREQ

' Dynamic settings
    DYNAMIC_NORM    = 0
    DYNAMIC_HI      = 1

' Measurement modes
    CONT            = 0
    SINGLE          = 1

' Coefficients for calculating UV Index
    CO_A            = 2_22
    CO_B            = 1_33
    CO_C            = 2_95
    CO_D            = 1_74
    UVA_RESP        = 0_001461
    UVB_RESP        = 0_002591

OBJ

    i2c : "com.i2c"                             ' PASM I2C engine
    core: "core.con.veml6075"                   ' HW-specific constants
    time: "time"                                ' timekeeping methods

PUB null{}
' This is not a top-level object

PUB start{}: status
' Start using "standard" Propeller I2C pins and 100kHz
    return startx(DEF_SCL, DEF_SDA, DEF_HZ)

PUB startx(SCL_PIN, SDA_PIN, I2C_HZ): status
' Start using custom settings
    if lookdown(SCL_PIN: 0..31) and lookdown(SDA_PIN: 0..31) and I2C_HZ =< core#I2C_MAX_FREQ
        if (status := i2c.init(SCL_PIN, SDA_PIN, I2C_HZ))
            time.usleep(core#T_POR)
            i2c.stop{}                          ' attempt to make startup
            i2c.write($ff)                      '   more reliable
            if (dev_id{} == core#DEV_ID_RESP)
                return
    ' if this point is reached, something above failed
    ' Double check I/O pin assignments, connections, power
    ' Lastly - make sure you have at least one free core/cog
    return FALSE

PUB stop{}
' Stop the driver
    powered(FALSE)
    time.msleep(1)
    i2c.deinit{}

PUB preset_active{}
' Enable sensor power, set to 100ms integration time, continuous measurements
    powered(TRUE)
    dynamic(DYNAMIC_NORM)
    integr_time(100)
    opmode(CONT)

PUB dev_id{}: id
' Device ID of the chip
'   Known values: $0026
    id := 0
    readreg(core#DEV_ID, 2, @id)

PUB dynamic(level): curr_lvl
' Set sensor dynamic
'   Valid values: DYNAMIC_NORM (0), DYNAMIC_HI (1)
'   Any other value polls the chip and returns the current setting
    curr_lvl := 0
    readreg(core#UV_CONF, 2, @curr_lvl)
    case level
        DYNAMIC_NORM, DYNAMIC_HI:
            level <<= core#HD
        other:
            return (curr_lvl >> core#HD) & 1

    level := ((curr_lvl & core#HD_MASK) | level) & core#UV_CONF_MASK
    writereg(core#UV_CONF, 2, @level)

PUB integr_time(itime): curr_itime
' Set sensor ADC integration time, in ms
'   Valid values: 50, 100, 200, 400, 800
'   Any other value polls the chip and returns the current setting
    curr_itime := 0
    readreg(core#UV_CONF, 2, @curr_itime)
    case itime
        50, 100, 200, 400, 800:
            itime := lookdownz(itime: 50, 100, 200, 400, 800) << core#UV_IT
        other:
            curr_itime := (curr_itime >> core#UV_IT) & core#UV_IT
            return lookupz(curr_itime: 50, 100, 200, 400, 800)

    itime := ((curr_itime & core#UV_IT_MASK) | itime) & core#UV_CONF_MASK
    writereg(core#UV_CONF, 2, @itime)

PUB ir_data{}: ir
' Read Infrared sensor data
'   Returns: 16-bit word
    readreg(core#UVCOMP2, 2, @ir)

PUB measure{} | tmp
' Trigger a single measurement
'   NOTE: For use when opmode() is set to SINGLE
    tmp := 0
    readreg(core#UV_CONF, 2, @tmp)
    tmp.byte[0] |= (1 << core#UV_TRIG)
    tmp.byte[1] := 0
    writereg(core#UV_CONF, 2, @tmp)

PUB opmode(mode): curr_mode
' Set measurement mode
'   Valid values:
'       CONT (0): Continuous measurement mode
'       SINGLE (1): Single-measurement mode
'   Any other value polls the chip and returns the current setting
'   NOTE: In SINGLE mode, measurements must be triggered manually using the
'       measure() method
    curr_mode := 0
    readreg(core#UV_CONF, 2, @curr_mode)
    case mode
        CONT, SINGLE:
            mode <<= core#UV_AF
        other:
            return (curr_mode >> core#UV_AF) & 1

    mode := ((curr_mode & core#UV_AF_MASK) | mode) & core#UV_CONF_MASK
    writereg(core#UV_CONF, 2, @mode)

PUB powered(state): curr_state
' Power on sensor
'   Valid values:
'       TRUE (-1 or 1): Power on
'       FALSE (0): Power off
'   Any other value polls the chip and returns the current setting
    curr_state := 0
    readreg(core#UV_CONF, 2, @curr_state)
    case ||(state)
        0, 1:
            state := (||(state) ^ 1) & 1        ' logic on chip is inverted,
        other:                                  ' so flip the bit
            return ((curr_state & 1) == 1)

    state := ((curr_state & core#SD_MASK) | state) & core#UV_CONF_MASK
    writereg(core#UV_CONF, 2, @state)

PUB uva_data{}: uva
' Read UV-A sensor data
'   Returns: 16-bit word
    readreg(core#UVA_DATA, 2, @uva)

PUB uvb_data{}: uvb
' Read UV-B sensor data
'   Returns: 16-bit word
    readreg(core#UVB_DATA, 2, @uvb)

PUB uv_index{}: uvidx | uva_raw, uva_comp, uvb_raw, uvb_comp, uvcomp1, uvcomp2
' Return UV Index, in hundredths of a point (e.g. 103 == 1.03)
    uva_raw := uva_data{} * 100
    uvb_raw := uvb_data{} * 100
    uvcomp1 := white_data{}
    uvcomp2 := ir_data{}

    uva_comp := uva_raw - (CO_A * uvcomp1) - (CO_B * uvcomp2)
    uvb_comp := uvb_raw - (CO_C * uvcomp1) - (CO_D * uvcomp2)
    return (((uva_comp * UVA_RESP) + (uvb_comp * UVB_RESP)) / 2) / 1_000_000

PUB white_data{}: w
' Read white/visible sensor data
'   Returns: 16-bit word
    readreg(core#UVCOMP1, 2, @w)

PRI present{}: flag
' Flag indicating the device responds on the I2C bus
    i2c.start{}
    flag := i2c.write(SLAVE_WR)
    i2c.stop{}                                  ' <P> needed by this device
    return (flag == i2c#ACK)

PRI readreg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Read nr_bytes from slave device into ptr_buff
    case reg_nr
        core#UV_CONF, core#UVA_DATA..core#DEV_ID:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wait(SLAVE_RD)
            i2c.rdblock_lsbf(ptr_buff, nr_bytes, i2c#NAK)
            i2c.stop{}
        other:
            return

PRI writereg(reg_nr, nr_bytes, ptr_buff) | cmd_pkt
' Write nr_bytes from ptr_buff to slave device
    case reg_nr
        core#UV_CONF:
            cmd_pkt.byte[0] := SLAVE_WR
            cmd_pkt.byte[1] := reg_nr
            i2c.start{}
            i2c.wrblock_lsbf(@cmd_pkt, 2)
            i2c.wrblock_lsbf(ptr_buff, nr_bytes)
            i2c.stop{}
        other:
            return

DAT
{
Copyright 2022 Jesse Burt

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
}
