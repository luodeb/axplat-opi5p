mmc dev 1
fatload mmc 1:1 0x400000 kernel.bin
go 0x400000