<?php

class IpInfo {
    public $ip;
    public $city;
    public $region;
    public $country;
    public $lat;
    public $lng;
    public $timezone;
}

class Weather {
    public $current;
    public $forecast = [];
}

class CurrentWeather {
    public $time;
    public $temperature;
    public $code;
}

class ForecastItem {
    public $date;
    public $temperature_min;
    public $temperature_max;
    public $code;
    public $rain_sum;
    public $wind_speed;
}

function getIpInfo() {
    $addr = $_SERVER['REMOTE_ADDR'];
    $ip = json_decode(file_get_contents('https://ipinfo.io/' . $addr . '/json'), true);
    $result = new IpInfo();
    $result->ip = $ip['ip'];
    $result->city = $ip['city'];
    $result->region = $ip['region'];
    $result->country = $ip['country'];
    $loc = explode(',', $ip['loc']);
    $result->lat = $loc[0];
    $result->lng = $loc[1];
    $result->timezone = $ip['timezone'];
    return $result;
}

function getWeather(IpInfo $ip) {

    $url = 'https://api.open-meteo.com/v1/forecast?' . http_build_query([
        'latitude' => $ip->lat, 
        'longitude' => $ip->lng, 
        'daily' => 'weathercode,temperature_2m_max,temperature_2m_min,rain_sum,windspeed_10m_max',
        'current_weather' => 'true',
        'timezone' => $ip->timezone
    ]);

    $weather = json_decode(file_get_contents($url), true);

    $result = new Weather();
    $current = new CurrentWeather();
    $current->time = $weather['current_weather']['time'];
    $current->temperature = $weather['current_weather']['temperature'];
    $current->code = $weather['current_weather']['weathercode'];
    $result->current = $current;
    $forecast = [];
    foreach ($weather['daily']['time'] as $i => $date) {
        $item = new ForecastItem();
        $item->date = $date;
        $item->temperature_min = $weather['daily']['temperature_2m_min'][$i];
        $item->temperature_max = $weather['daily']['temperature_2m_max'][$i];
        $item->code = $weather['daily']['weathercode'][$i];
        $item->wind_speed = $weather['daily']['windspeed_10m_max'][$i];
        $item->rain_sum = $weather['daily']['rain_sum'][$i];
        $forecast[] = $item;
    }
    $result->forecast = $forecast;
    return $result;
}

function getTextByCode($code, $short = false) {
    $map = (!$short) ? [
        0 => 'Clear Sky',
        1 => 'Mainly Clear',
        2 => 'Partly Cloudly',
        3 => 'Overcast',
        45 => 'Fog',
        46 => 'Depositing Rime Fog',
        51 => 'Drizzle: Light',
        53 => 'Drizzle: Moderate',
        55 => 'Drizzle: Dense intensity',
        56 => 'Freezing Drizzle: Light',
        57 => 'Freezing Drizzle: Heavy',
        61 => 'Rain: Slight',
        63 => 'Rain: Moderate',
        65 => 'Rain: Heavy',
        66 => 'Freezing Rain: Slight',
        67 => 'Freezing Rain: Heavy',
        71 => 'Snow Fall: Slight',
        73 => 'Snow Fall: Moderate',
        75 => 'Snow Fall: Heavy',
        77 => 'Snow Grains',
        80 => 'Rain Showers: Slight',
        81 => 'Rain Shovers: Moderate',
        82 => 'Rain Shovers: Violent',
        85 => 'Snow Shovers: Slight',
        86 => 'Snow Shovers: Heavy',
        95 => 'Thunderstorm: Slight',
        96 => 'Thunderstorm: Slight Hail',
        99 => 'Thunderstorm: Heavy Hail'
    ] : [
        0 => 'Clear',
        1 => 'Clear',
        2 => 'Cloudly',
        3 => 'Overcast',
        45 => 'Fog',
        46 => 'Rime Fog',
        51 => 'Drizzle',
        53 => 'Drizzle',
        55 => 'Drizzle',
        56 => 'Frz Drizz',
        57 => 'Frz Drizz',
        61 => 'Rain',
        63 => 'Rain',
        65 => 'Rain',
        66 => 'Frz Rain',
        67 => 'Frz Rain',
        71 => 'Snow',
        73 => 'Snow',
        75 => 'Snow',
        77 => 'Snow',
        80 => 'Showers',
        81 => 'Shovers',
        82 => 'Shovers',
        85 => 'Shovers',
        86 => 'Shovers',
        95 => 'T.storm',
        96 => 'T.storm',
        99 => 'T.storm'
    ];
    if (array_key_exists($code, $map)) {
        return $map[$code];
    }
    return 'Unknown';
}

function getIconByCode($code) {
    $map = [
        0 => 'clear.png',
        1 => 'mostlysunny.png',
        2 => 'mostlycloudy.png',
        3 => 'cloudy.png',
        45 => 'fog.png',
        46 => 'fog.png',
        51 => 'rain.png',
        53 => 'rain.png',
        55 => 'rain.png',
        56 => 'sleet.png',
        57 => 'sleet.png',
        61 => 'rain.png',
        63 => 'rain.png',
        65 => 'rain.png',
        66 => 'sleet.png',
        67 => 'sleet.png',
        71 => 'snow.png',
        73 => 'snow.png',
        75 => 'snow.png',
        77 => 'snow.png',
        80 => 'rain.png',
        81 => 'rain.png',
        82 => 'rain.png',
        85 => 'snow.png',
        86 => 'snow.png',
        95 => 'tstorms.png',
        96 => 'tstorms.png',
        99 => 'tstorms.png'
    ];
    if (array_key_exists($code, $map)) {
        return $map[$code];
    }
    return 'unknown.png';
}

function formatTemperature($temp, $units = false) {
    $temp = round($temp);
    $result = '';
    if ($temp == 0) {
        $result .= " " . $temp;
    } elseif ($temp < 0) {
        $result .= "-" . $temp;
    } else {
        $result .= "+" . $temp;
    }
    if ($units) {
        $result .= chr(176) . "C";
    }
    return $result;
}

function formatDate($date, $timezone) {
    $tz = new DateTimezone($timezone);
    $curr = (new DateTime('now', $tz))->format('Y-m-d');
    $tomorrow = (new DateTime('now+1day', $tz))->format('Y-m-d');
    if ($date == $curr) {
        return 'Today';
    } elseif ($date == $tomorrow) {
        return 'Tomorrow';
    }
    $d = new DateTime($date, $tz);
    $n = $d->format('N');
    $map = [
        1 => 'Monday',
        2 => 'Tuesday',
        3 => 'Wednesday',
        4 => 'Thursday',
        5 => 'Friday',
        6 => 'Saturday',
        7 => 'Sunday'
    ];
    return (isset($map[$n])) ? $map[$n] : $date;
}

function centerTextOffset($text, $block_width, $font_width) {
    $len = strlen($text);
    $width = $len * $font_width;
    $offset = ceil(($block_width - $width)/2);
    return $offset;
}

function getProfiBinary($im) {
    $w = 512;
    $h = 256;
    $bin = '';
    $v0 = '';
    $v1 = '';

    // fill pixels
    for ($q=0; $q<4; $q++) { // quarters of screen 0-3
        for ($r=0; $r<8; $r++) { // row in a quarter 0-7
            for ($y=0; $y<8; $y++) { // y pos
                for ($x=0; $x<$w/8; $x++) { // byte pos
                    $pix_byte = 0;
                    for ($b=0; $b<8; $b++) {
                        $rgb = imagecolorat($im, $x*8 + $b, $y*8 + $r + $q*64);
                        $pix_byte += ($rgb) ? 1 << (7-$b) : 0;
                    }
                    if ($x % 2 == 0) {
                        $v1 .= pack('C', $pix_byte);                
                    } else {
                        $v0 .= pack('C', $pix_byte);
                    }
                }
            }
        }
    }
    $bin .= $v0 . $v1;

    // fill attributes
    for ($y=0; $y<$h; $y++) {
        for ($x=0; $x<$w/8; $x++) {
            $attr_byte = bindec('00001111');
            $bin .= pack('C', $attr_byte);
        }
    }
    return $bin;
}

function getSpeccyBinary($im) {
    $w = 256;
    $h = 192;
    $bin = '';

    // fill pixels (6144 bytes)
    for ($q=0; $q<3; $q++) { // quarters of screen 0-2
        for ($r=0; $r<8; $r++) { // row in a quarter 0-7
            for ($y=0; $y<8; $y++) { // y pos
                for ($x=0; $x<$w/8; $x++) { // byte pos
                    $pix_byte = 0;
                    for ($b=0; $b<8; $b++) {
                        $rgb = imagecolorat($im, $x*8 + $b, $y*8 + $r + $q*64);
                        $pix_byte += ($rgb) ? 1 << (7-$b) : 0;
                    }
                    $bin .= pack('C', $pix_byte);
                }
            }
        }
    }

    // fill attributes (768 bytes)
    for ($y=0; $y<$h/8; $y++) {
        for ($x=0; $x<32; $x++) {
            switch ($y) {
                case 0: $attr_byte = bindec('01000101'); break; // cyan
                case 1: $attr_byte = bindec('01000110'); break; // yellow
                case 12: $attr_byte = bindec('00000101'); break; // green
                case 13: $attr_byte = bindec('00000101'); break; // green
                case 20: $attr_byte = bindec('00000110'); break; // dark y
                case 21: $attr_byte = bindec('00000110'); break; // dark y
                case 22: $attr_byte = bindec('00000001'); break; // dark b
                case 23: $attr_byte = bindec('00000001'); break; // dark bb
                default: $attr_byte = bindec('01000111');
            }
            $bin .= pack('C', $attr_byte);
        }
    }
    // 6912
    return $bin;
}

if (isset($_REQUEST['profi'])) {

// profi image builder
$im = imagecreatetruecolor(512,240);
$black = imagecolorallocate($im, 0, 0, 0);
$white = imagecolorallocate($im, 255, 255, 255);

imagefilledrectangle($im, 0, 0, 512, 240, $black);

$font_header = imageloadfont('./fonts/Man+Bold++_8x16_LE.gdf');
$font_body = imageloadfont('./fonts/FidoIBM_B_8x8_LE.gdf');
$font_small = imageloadfont('./fonts/FidoIBM_8x8_LE.gdf');
$font_misc = imageloadfont('./fonts/MiscTT_12x20_LE.gdf');

$ip = getIpInfo();
$weather = getWeather($ip);

imagestring($im, $font_header, 16, 8, 'WEATHER REPORT ' . str_replace('T', ' ', $weather->current->time) . ' - IP: ' . $ip->ip, $white);
imagestring($im, $font_body, 16, 26, 'Region: ' . iconv('UTF8', 'ASCII//TRANSLIT', $ip->city) . ', ' . iconv('UTF8', 'ASCII//TRANSLIT', $ip->region) . ', ' . $ip->country, $white);
imagestring($im, $font_body, 16, 38, 'Location: ' . $ip->lat . ', ' . $ip->lng, $white);
imagestring($im, $font_body, 16, 50, 'Timezone: ' . $ip->timezone, $white);
imagestring($im, $font_body, 16, 62, 'Current weather:', $white);
imagestring($im, $font_misc, 64, 84, formatTemperature($weather->current->temperature, true), $white);
imagestring($im, $font_small, 64, 110, getTextByCode($weather->current->code), $white);

$icon = imagecreatefrompng("./icons/256x256/" . getIconByCode($weather->current->code));
imagecopyresized($im, $icon, 240, 32, 0, 0, 256, 128, 256, 256);

imageline($im, 0, 154, 512, 154, $white);
imageline($im, 0, 165, 512, 165, $white);
imageline($im, 128, 154, 128, 240, $white);
imageline($im, 256, 154, 256, 240, $white);
imageline($im, 384, 154, 384, 240, $white);

foreach ($weather->forecast as $i => $item) {
    if ($i >= 5 ) continue;
    $text = formatDate($item->date, $ip->timezone);
    $offset = centerTextOffset($text, 128, 8);
    imagestring($im, $font_body, $i*128+$offset, 156, $text, $white);    
    $icon = imagecreatefrompng("./icons/64x64/" . getIconByCode($item->code));
    imagecopyresized($im, $icon, $i*128+28, 170, 0, 0, 64, 32, 64, 64);
    $text = getTextByCode($item->code, true);
    $offset = centerTextOffset($text, 128, 8);
    imagestring($im, $font_small, $i*128+$offset, 204, $text, $white); 
    imagestring($im, $font_small, $i*128+42, 216, formatTemperature($item->temperature_max), $white); 
    imagestring($im, $font_small, $i*128+42, 226, formatTemperature($item->temperature_min), $white); 
}

// bw
imagefilter($im, IMG_FILTER_GRAYSCALE);
imagefilter($im, IMG_FILTER_CONTRAST, -100);

if (isset($_REQUEST['download'])) {
    header('Content-type: application/octet-stream');
    header('Content-Disposition: attachment; filename="profi.bin"');
    header('Content-Transfer-Encoding: binary');
    echo getProfiBinary($im);
} else {
    header ('Content-type: image/png');
    imagepng($im);
}
imagedestroy($im);

} elseif (isset($_REQUEST{'spectrum'})) {

// spectrum image builder
$im = imagecreatetruecolor(256,192);
$black = imagecolorallocate($im, 0, 0, 0);
$white = imagecolorallocate($im, 255, 255, 255);

imagefilledrectangle($im, 0, 0, 256, 192, $black);

$font_header = imageloadfont('./fonts/Man+Bold++_8x16_LE.gdf');
$font_body = imageloadfont('./fonts/FidoIBM_B_8x8_LE.gdf');
$font_small = imageloadfont('./fonts/Teletext_6x10_LE.gdf');
$font_misc = imageloadfont('./fonts/MiscTT_12x20_LE.gdf');

$ip = getIpInfo();
$weather = getWeather($ip);

imagestring($im, $font_header, 0, 0, 'WEATHER REPORT ' . str_replace('T', ' ', $weather->current->time) . ' - IP: ' . $ip->ip, $white);
imagestring($im, $font_body, 0, 16, 'Region: ' . iconv('UTF8', 'ASCII//TRANSLIT', $ip->city) . ', ' . $ip->country, $white);
imagestring($im, $font_body, 0, 26, 'Timezone: ' . $ip->timezone, $white);
imagestring($im, $font_body, 0, 36, 'Current weather:', $white);
imagestring($im, $font_misc, 26, 56, formatTemperature($weather->current->temperature, true), $white);
imagestring($im, $font_small, 26, 74, getTextByCode($weather->current->code), $white);

$icon = imagecreatefrompng("./icons/64x64/" . getIconByCode($weather->current->code));
imagecopyresized($im, $icon, 160, 32, 0, 0, 64, 64, 64, 64);

imageline($im, 0, 100, 256, 100, $white);
imageline($im, 0, 110, 256, 110, $white);
imageline($im, 64, 100, 64, 110, $white);
imageline($im, 128, 100, 128, 110, $white);
imageline($im, 192, 100, 192, 110, $white);

foreach ($weather->forecast as $i => $item) {
    if ($i >= 5 ) continue;
    $text = formatDate($item->date, $ip->timezone);
    $offset = centerTextOffset($text, 64, 6);
    imagestring($im, $font_small, $i*64+$offset, 101, $text, $white);    
    $icon = imagecreatefrompng("./icons/32x32/" . getIconByCode($item->code));
    imagecopyresized($im, $icon, $i*64+16, 111, 0, 0, 32, 32, 32, 32);
    $text =  getTextByCode($item->code, true);
    $offset = centerTextOffset($text, 64, 6);
    imagestring($im, $font_small, $i*64+$offset, 148, $text, $white); 
    imagestring($im, $font_small, $i*64+20, 166, formatTemperature($item->temperature_max), $white); 
    imagestring($im, $font_small, $i*64+20, 176, formatTemperature($item->temperature_min), $white); 
}

// bw
imagefilter($im, IMG_FILTER_GRAYSCALE);
imagefilter($im, IMG_FILTER_CONTRAST, -100);

if (isset($_REQUEST['download'])) {
    header('Content-type: application/octet-stream');
    header('Content-Disposition: attachment; filename="spectrum.scr"');
    header('Content-Transfer-Encoding: binary');
    echo getSpeccyBinary($im);
} else {
    header ('Content-type: image/png');
    imagepng($im);
}
imagedestroy($im);

} else {
?>
    <style>
        img {
          image-rendering: pixelated;
        }
    </style>
    <img src="weather.php?profi" width="512" height="480" alt=""/>
    <img src="weather.php?spectrum" width="512" height="384" alt=""/>
    <br/>
    <a href="weather.php?profi&download">Get profi screen dump</a>
    <a href="weather.php?spectrum&download">Get speccy screen dump</a>
<?php
}
