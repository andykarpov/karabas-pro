/* Quartus II 64-Bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(EPM3128A) MfrSpec(OpMask(0));
	P ActionCode(Cfg)
		Device PartName(EP4CE10) Path("C:/hobby/karabas_main/karabas-pro/firmware/src/fpga/profi/syn/ep4ce10/") File("karabas_pro_ep4ce10_revDS_tda1543.jic") MfrSpec(OpMask(1) SEC_Device(EPCS16) Child_OpMask(1 1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
