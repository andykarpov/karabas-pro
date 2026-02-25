<?php

$filename = 'icons4.pf';
$size = filesize($filename);
$f = fopen($filename, 'rb');
$contents = fread($f, $size);
fclose($f);

$o = fopen('icons.mif', 'w');

fwrite($o, "-- icons.mif file\n");
fwrite($o, "DEPTH = 2048;\n");
fwrite($o, "WIDTH = 1;\n");
fwrite($o, "ADDRESS_RADIX = DEC;\n");
fwrite($o, "DATA_RADIX = BIN;\n");
fwrite($o, "CONTENT\n");
fwrite($o, "BEGIN\n\n");

$a = 0;
for ($j=0; $j<256; $j++) {
	for ($i=0; $i<8; $i++) {
		fwrite($o, $a . " : " .  (((ord($contents[$j]) >> (7-$i)) & 1) ? '1': '0') . ";\n");
		$a++;
	}
}

fwrite($o, "\nEND;\n");
fclose($o);
