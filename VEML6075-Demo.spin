{
    --------------------------------------------
    Filename: VEML6075-Demo.spin
    Author: Jesse Burt
    Description: Demo of the VEML6075 driver
    Copyright (c) 2019
    Started Aug 18, 2019
    Updated Aug 19, 2019
    See end of file for terms of use.
    --------------------------------------------
}

CON

    _clkmode    = cfg#_clkmode
    _xinfreq    = cfg#_xinfreq

    LED         = cfg#LED1

    SCL_PIN     = 28
    SDA_PIN     = 29
    I2C_HZ      = 400_000

    TEXT_COL    = 0
    DATA_COL    = 9

    UVA_RESP    = 0_001461  '0.001461
    UVB_RESP    = 0_002591  '0.002591

OBJ

    cfg     : "core.con.boardcfg.flip"
    ser     : "com.serial.terminal"
    time    : "time"
    uv      : "sensor.uv.veml6075.i2c"
    int     : "string.integer"

VAR

    long _fails, _expanded
    byte _ser_cog, _row

PUB Main | uva, uvb, vis, ir, i

    Setup
    uv.Power (TRUE)
    uv.Dynamic (uv#DYNAMIC_NORM)
    uv.IntegrationTime (100)
    uv.MeasureMode (uv#MMODE_CONT)

    repeat
        ser.Position (TEXT_COL, 5)
        ser.Str (string("UVI:"))
        ser.Position (DATA_COL, 5)
        ser.Str (string("0.000000"))
        ser.Str(int.DecPadded (UVI, 10))
        ser.NewLine
{
        ser.Position (TEXT_COL, 5)
        ser.Str (string("UVA:"))
        ser.Position (DATA_COL, 5)
        ser.Str(int.DecPadded (UVACalc(uv.UVA), 5))
        ser.NewLine

        ser.Position (TEXT_COL, 6)
        ser.Str (string("UVB:"))
        ser.Position (DATA_COL, 6)
        ser.Str(int.DecPadded (UVBCalc(uv.UVB), 5))
        ser.NewLine
}
    repeat
        uva := uv.UVA
        uvb := uv.UVB
        vis := uv.Visible
        ir := uv.IR

        ser.Position (TEXT_COL, 5)
        ser.Str (string("UVA:"))
        ser.Position (DATA_COL, 5)
        ser.Str(int.DecPadded (uva, 5))
        ser.NewLine

        ser.Position (TEXT_COL, 6)
        ser.Str (string("UVB:"))
        ser.Position (DATA_COL, 6)
        ser.Str(int.DecPadded (uvb, 5))
        ser.NewLine

        ser.Position (TEXT_COL, 7)
        ser.Str (string("Visible:"))
        ser.Position (DATA_COL, 7)
        ser.Str(int.DecPadded (vis, 5))
        ser.NewLine

        ser.Position (TEXT_COL, 8)
        ser.Str (string("IR:"))
        ser.Position (DATA_COL, 8)
        ser.Str(int.DecPadded (ir, 5))
        time.MSleep (50)
    Flash (LED, 100)

PUB UVACalc(uva_raw) | uva, a, b, uvcomp1, uvcomp2

    a := 2_22   '2.22
    b := 1_33   '1.33

    uva := uva_raw
    uvcomp1 := uv.Visible
    uvcomp2 := uv.IR
    result := uva - (a * uvcomp1) - (b * uvcomp2)

PUB UVBCalc(uvb_raw) | uvb, c, d, uvcomp1, uvcomp2

    c := 2_95   '2.95
    d := 1_74   '1.74

    uvb := uvb_raw
    uvcomp1 := uv.Visible
    uvcomp2 := uv.IR
    result := uvb - (c * uvcomp1) - (d * uvcomp2)

PUB UVI

    return ((UVACalc(uv.UVA) * UVA_RESP) + (UVBCalc(uv.UVB) * UVB_RESP)) / 2

PUB Setup

    repeat until _ser_cog := ser.Start (115_200)
    ser.Clear
    ser.Str(string("Serial terminal started", ser#NL))
    if uv.Startx (SCL_PIN, SDA_PIN, I2C_HZ)
        ser.Str (string("VEML6075 driver started", ser#NL))
    else
        ser.Str (string("VEML6075 driver failed to start - halting", ser#NL))
        uv.Stop
        time.MSleep (500)
        ser.Stop
        Flash (LED, 500)

PUB Flash(pin, delay_ms)

    dira[pin] := 1
    repeat
        !outa[pin]
        time.MSleep (delay_ms)

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
