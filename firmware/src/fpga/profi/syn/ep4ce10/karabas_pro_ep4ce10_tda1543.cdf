/* Quartus II 32-bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(EPM3128AT100) MfrSpec(OpMask(0) FullPath("../../../../cpld/syn/output_files/karabas_pro_cpld.pof"));
	P ActionCode(Cfg)
		Device PartName(EP4CE6) Path("") File("karabas_pro_ep4ce10_tda1543.jic") MfrSpec(OpMask(1) SEC_Device(EPCS16) Child_OpMask(1 1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
