/* Quartus II 64-Bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(EPM3128AT100) MfrSpec(OpMask(0) FullPath("C:/GitHub/karabas-pro/firmware/releases/profi/karabas_pro_cpld.pof"));
	P ActionCode(Cfg)
		Device PartName(EP4CE6E22) Path("C:/GitHub/karabas-pro/firmware/src/fpga/profi/syn/") File("karabas_pro.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
