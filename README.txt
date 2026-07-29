Microcalculator cu microprocesorul 65C02 (WDC).

Pe masura ce proiectul merge mai departe se vor dezvolta si alte capacitati software / hardware.

Impartirea memoriei
===================

        +-----------+
        |           |
        |           |
        |           |
        |           | 
        |    RAM    |   [0x0000, 0x7FFF] (32 KiB)
        |           |
        |           |
        |           |
        |           |
        |           |
        +-----------+
        |   65C51   |   [0x8000, 0x800F] (16 B)
        +-----------+
        |   LIBER   |   [0x8010, 0x801F] (16 B)
        +-----------+
        |   LIBER   |   [0x8020, 0x802F] (16 B)
        +-----------+
        |   LIBER   |   [0x8030, 0x803F] (16 B)
        +-----------+
        |           |
        |           |
        |           |
        |           |
        |    ROM    |   [0x8040, 0xFFFF] (~32 KiB)
        |           | 
        |           |
        |           |
        |           |
        +-----------+
