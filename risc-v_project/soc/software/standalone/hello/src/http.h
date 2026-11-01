#pragma once
#include <stdint.h>

void http_poll(void);
void http_set_status(const char *evt, int score, int pd_on, int pd, int lp,
                     int sht, int ta, int to, int ntrk, int infer_ms,
                     int x0, int y0, int x1, int y1, int voice);
void http_set_thumb(const uint8_t *th48, unsigned n);
