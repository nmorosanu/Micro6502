import serial
import sys

DEV     =   "/dev/cuaU0"
SPEED   =   19200

#def uartup():
#    ser = serial.Serial(DEV, SPEED)
#    with open("bin/program.bin", "rb") as f:
#        date = f.read()
#        ser.write(date)
#        ser.write(b"\xDB")
#        ser.close()
#
#        print(date + b"\xDB")

def uartup():
    ser = serial.Serial(DEV, SPEED)
    ser.write(b"p");
    ser.close();

if __name__ == "__main__":
    uartup()
