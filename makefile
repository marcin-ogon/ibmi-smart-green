
BIN_LIB=SMARTLIB
LIBLIST=SMARTLIB 
TESTLIBLIST=SMARTLIB RPGUNIT QDEVTOOLS
SHELL=/QOpenSys/usr/bin/qsh

all: smart.pgm.sqlrpgle smartd.pgm.sqlrpgle listener.pgm.clle
 
## Targets

smart.pgm.sqlrpgle: smart_device.table smart.rpgleinc 
smartd.pgm.sqlrpgle: smart_device.table smartdf.dspf smart.rpgleinc

## Rules

%.pgm.sqlrpgle: qrpglesrc/%.pgm.sqlrpgle
	liblist -a $(LIBLIST);\
	system "CRTSQLRPGI OBJ($(BIN_LIB)/$*) SRCSTMF('$<') COMMIT(*NONE) DBGVIEW(*SOURCE) COMPILEOPT('TGTCCSID(*JOB)') RPGPPOPT(*LVL2) TGTRLS(*CURRENT) OPTION(*EVENTF)"
	@touch $@

%.pgm.rpgle: qrpglesrc/%.pgm.rpgle
	liblist -a $(LIBLIST);\
	system "CRTBNDRPG PGM($(BIN_LIB)/$*) SRCSTMF('$<') OPTION(*EVENTF) DBGVIEW(*SOURCE) TGTRLS(*CURRENT) TGTCCSID(*JOB)"
	@touch $@

%.pgm.clle: qcllesrc/%.pgm.clle
	system -s "CHGATR OBJ('$<') ATR(*CCSID) VALUE(1252)"
	liblist -a $(LIBLIST);\
	system "CRTBNDCL PGM($(BIN_LIB)/$*) SRCSTMF('$<') TGTRLS(*CURRENT) DBGVIEW(*SOURCE) OPTION(*EVENTF)"

%.test.rpgle: qrpglesrc/%.test.rpgle
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QRPGLESRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('./qrpglesrc/$*.test.rpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLESRC.file/$*.mbr') MBROPT(*REPLACE)"
	system "CHGPFM FILE($(BIN_LIB)/QRPGLESRC) MBR($*) SRCTYPE(RPGLE)"
	liblist -a $(TESTLIBLIST);\
	system "RPGUNIT/RUCRTTST TSTPGM($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QRPGLESRC)"
	@touch $@

%.test.sqlrpgle: qrpglesrc/%.test.sqlrpgle
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QRPGLESRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('./qrpglesrc/$*.test.sqlrpgle') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QRPGLESRC.file/$*.mbr') MBROPT(*REPLACE)"
	system "CHGPFM FILE($(BIN_LIB)/QRPGLESRC) MBR($*) SRCTYPE(SQLRPGLE)"
	liblist -a $(TESTLIBLIST);\
	system "RPGUNIT/RUCRTTST TSTPGM($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QRPGLESRC)"
	@touch $@

%.dspf: qddssrc/%.dspf
	-system -qi "CRTSRCPF FILE($(BIN_LIB)/QDDSSRC) RCDLEN(112)"
	system "CPYFRMSTMF FROMSTMF('./qddssrc/$*.dspf') TOMBR('/QSYS.lib/$(BIN_LIB).lib/QDDSSRC.file/$*.mbr') MBROPT(*REPLACE)"
	liblist -a $(LIBLIST);\
	system -s "CRTDSPF FILE($(BIN_LIB)/$*) SRCFILE($(BIN_LIB)/QDDSSRC) SRCMBR($*)"
	@touch $@

%.table: qddssrc/%.table
	liblist -c $(LIBLIST);\
	system "RUNSQLSTM SRCSTMF('$<') COMMIT(*NONE)"
	@touch $@

%.rpgleinc: qrpgleref/%.rpgleinc
	@touch $@

clean:
	rm -f *.pgm.sqlrpgle *.pgm.rpgle *.dspf *.table *.rpgleinc
