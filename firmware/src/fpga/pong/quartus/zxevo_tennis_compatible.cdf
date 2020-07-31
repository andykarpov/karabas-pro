/* Quartus II 64-Bit Version 13.0.1 Build 232 06/12/2013 Service Pack 1 SJ Web Edition */
JedecChain;
	FileRevision(JESD32A);
	DefaultMfr(6E);

	P ActionCode(Ign)
		Device PartName(EPM3128AT100) MfrSpec(OpMask(0) FullPath("D:/Google_Drive/ZX/Karabas/karabas-pro-master/firmware/src/cpld/syn/output_files/karabas_pro_cpld.pof"));
	P ActionCode(Cfg)
		Device PartName(EP4CE6E22) Path("D:/Google_Drive/ZX/Karabas/Karabas-Pro/tennis/quartus/") File("zxevo_tennis_compatible.sof") MfrSpec(OpMask(1));

ChainEnd;

AlteraBegin;
	ChainType(JTAG);
AlteraEnd;
