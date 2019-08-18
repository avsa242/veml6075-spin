{
    --------------------------------------------
    Filename: VEML6075-Test.spin
    Author: Jesse Burt
    Description: Test of the VEML6075 driver
    Copyright (c) 2019
    Started Aug 18, 2019
    Updated Aug 18, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    uv      : "sensor.uv.veml6075.i2c"

VAR

    byte _ser_cog

PUB Main | tmp, i

    Setup
    tmp := %0_000_0_0_0_0
    uv.writeReg ($00, 1, @tmp)
    repeat
        ser.Position (0, 4)
        repeat i from $00 to $0C
            ser.Hex (i, 2)
            ser.Str (string(": "))
            uv.readReg (i, 2, @tmp)'(reg, nr_bytes, buff_addr)
            ser.Hex (tmp, 4)
            ser.NewLine
        time.MSleep (200)

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if uv.Startx (28, 29, 400_000)
        ser.Str (string("VEML6075 driver started", ser#NL))
    else
        ser.Str (string("VEML6075 driver failed to start - halting", ser#NL))
        uv.Stop
        time.MSleep (500)
        ser.Stop
        repeat

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
