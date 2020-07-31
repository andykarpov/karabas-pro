/* Quartus II 32-bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(EPM3128AT100) MfrSpec(OpMask(0) FullPath("/home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro/firmware/src/cpld/syn/output_files/karabas_pro_cpld.pof"));
	P ActionCode(Cfg)
		Device PartName(EP4CE6F17) Path("/home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro/firmware/src/fpga/syn/") File("sfl_enhanced_ep4ce6.sof") MfrSpec(OpMask(1) SEC_Device(EPCS16) Child_OpMask(1 1) SFLPath("/home/andy/Documents/Projects/Retrocomp/ZX-Spectrum/karabas-pro/firmware/src/fpga/syn/karabas_pro.jic"));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
