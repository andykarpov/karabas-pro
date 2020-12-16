/* Quartus II 64-Bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(EPM3128AT100) MfrSpec(OpMask(0) FullPath("D:/GitHub/karabas-pro/firmware/src/cpld/syn/output_files/karabas_pro_cpld.pof"));
	P ActionCode(Cfg)
		Device PartName(EP4CE6) Path("D:/GitHub/karabas-pro/firmware/src/fpga/profi/syn/") File("karabas_pro_revA_tda1543a.jic") MfrSpec(OpMask(1) SEC_Device(EPCS16) Child_OpMask(1 7));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
