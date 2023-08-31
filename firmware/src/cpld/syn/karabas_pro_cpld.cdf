/* Quartus II 64-Bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(EPM3128AT100) Path("C:/hobby/karabas-pro/firmware/src/cpld/syn/") File("karabas_pro_cpld.pof") MfrSpec(OpMask(1));
	P ActionCode(Ign)
		Device PartName(EP4CE10) MfrSpec(OpMask(0));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
