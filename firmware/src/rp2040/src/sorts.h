#pragma once

#include <Arduino.h>
#include <algorithm>
#include <tuple>
#include "types.h"
#include <SPI.h>
#include "config.h"

inline bool operator<(const file_list_sort_item_t a, const file_list_sort_item_t b) {
  String s1 = String(a.hash); String s2 = String(b.hash);
  s1.toLowerCase(); s2.toLowerCase();
  return s1 < s2;
}

inline bool operator<(const core_list_item_t a, const core_list_item_t b) {
  return a.order < b.order;
}

inline bool operator<(const file_list_item_t a, const file_list_item_t b) {
  String s1 = String(a.name); String s2 = String(b.name);
  s1.toLowerCase(); s2.toLowerCase();
  return s1 < s2;
}
