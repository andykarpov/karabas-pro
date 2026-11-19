/* mouse.c with an entry for the stand: a report as the PS/2 interrupt would queue it. */
#include "mouse.c"

void sim_mouse_push(uint8_t status, int8_t x, int8_t y)
{
  uint8_t next = s_ms_head + 1;
  if (next >= MS_BUFFER_SIZE) next = 0;
  if (next == s_ms_tail) return;
  s_ms_buffer[next].status = status;
  s_ms_buffer[next].x = x;
  s_ms_buffer[next].y = y;
  s_ms_buffer[next].z = 0;
  s_ms_head = next;
}
