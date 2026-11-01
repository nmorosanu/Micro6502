# ***YAMC65X (Microcomputer 65X)***
*"Yet another microcomputer using the W65C02 CPU"*

**As the project advances, there will be more software and hardware capabilities added and polished.**

### Compiling / Simulating
First of all, be sure to have **cc65** installed on your system.

To compile the source files just execute ```make``` in the project's directory.

To simulate using **sim65**, you will need to comment out the ```.word``` directives from the ```vectors.s``` file, recompile and execute in your terminal ```make sim```.

```
.segment "VECTORS"
.word    HOME
;.word    NMI
;.word    RESET
;.word    IRQ
```

### LICENSE
This project is licensed under the MIT License.
