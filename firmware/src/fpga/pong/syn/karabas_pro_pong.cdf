/* Quartus II 32-bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(EPM3128A) MfrSpec(OpMask(0));
	P ActionCode(Cfg)
		Device PartName(EP4CE6E22) Path("/home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro/firmware/src/fpga/pong/syn/") File("karabas_pro_pong.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
