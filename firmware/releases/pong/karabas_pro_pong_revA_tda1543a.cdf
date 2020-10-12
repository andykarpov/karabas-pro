/* Quartus II 32-bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Cfg)
		Device PartName(EPM3128AT100) Path("") File("karabas_pro_cpld.pof") MfrSpec(OpMask(1));
	P ActionCode(Cfg)
		Device PartName(EP4CE6E22) Path("") File("") MfrSpec(OpMask(1) SEC_Device(EPCS16) Child_OpMask(1 1) SFLPath("karabas_pro_pong_revA_tda1543a.jic"));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
