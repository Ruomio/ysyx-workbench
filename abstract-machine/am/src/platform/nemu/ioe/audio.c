#include <am.h>
#include <nemu.h>

#define AUDIO_FREQ_ADDR      (AUDIO_ADDR + 0x00)
#define AUDIO_CHANNELS_ADDR  (AUDIO_ADDR + 0x04)
#define AUDIO_SAMPLES_ADDR   (AUDIO_ADDR + 0x08)
#define AUDIO_SBUF_SIZE_ADDR (AUDIO_ADDR + 0x0c)
#define AUDIO_INIT_ADDR      (AUDIO_ADDR + 0x10)
#define AUDIO_COUNT_ADDR     (AUDIO_ADDR + 0x14)

static uint32_t sb_idx = 0;

void __am_audio_init() {

}

void __am_audio_config(AM_AUDIO_CONFIG_T *cfg) {
  cfg->present = true;
}

void __am_audio_ctrl(AM_AUDIO_CTRL_T *ctrl) {
    int freq = ctrl->freq, channels = ctrl->channels, samples = ctrl->samples;
    outl(AUDIO_FREQ_ADDR, freq);
    outl(AUDIO_CHANNELS_ADDR, channels);
    outl(AUDIO_SAMPLES_ADDR, samples);
    outl(AUDIO_INIT_ADDR, 1);
}

void __am_audio_status(AM_AUDIO_STATUS_T *stat) {
  stat->count = inl(AUDIO_COUNT_ADDR);
}

void __am_audio_play(AM_AUDIO_PLAY_T *ctl) {
  uint8_t *fram = (uint8_t *)(uintptr_t)AUDIO_SBUF_ADDR;
  int len = ctl->buf.end - ctl->buf.start;
  uint32_t sb_size = inl(AUDIO_SBUF_SIZE_ADDR);

  for(int i=0; i<len; i++) {
    fram[sb_idx] = *(uint8_t *)(ctl->buf.start + i);
    sb_idx = (sb_idx + 1) % sb_size; 
  }
  uint32_t cnt = inl(AUDIO_COUNT_ADDR);
  outl(AUDIO_COUNT_ADDR, cnt + len);
}
