# ERRATA rev.DS

1) Transistor Q2 has incorrect footprint 
2) R48 value should be 15k...100k

To avoid issuues with buzzer please use the following hotfixes:
- add 100nF capacitor instead of diode D10
- remove R48
- short transistor from base to emitter with 0 Ohm 0603 resistor
- use a piezzo buzzer instead of electromechanical one
