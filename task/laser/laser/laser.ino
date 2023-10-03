#define LASER_PIN0 (3)
#define LASER_PIN1 (5)
#define LASER_HI (127)
#define LASER_DEBUG (0)
#define TRIGGER_MODE_ON_OFF (0)
#define TRIGGER_MODE_TIMED_PULSE (1)

unsigned long millis_last_frame;

unsigned long millis_remaining[2] = {0, 0};
int need_set_hi[2] = {0, 0};
int need_set_lo[2] = {0, 0};
int trigger_modes[2] = {0, 0};
int current_states[2] = {0, 0};

#if LASER_DEBUG
unsigned long interval_ts[2] = {0, 0};
int interval_states[2] = {0, 0};
#endif

void reset_trigger(int i) {
  need_set_hi[i] = 0;
  need_set_lo[i] = 1;
  trigger_modes[i] = 0;
  millis_remaining[i] = 0;
}

void setup() {
  const int pins[2] = {LASER_PIN0, LASER_PIN1};
  for (int i = 0; i < 2; i++) {
    pinMode(pins[i], OUTPUT);
    analogWrite(pins[i], 0);
    reset_trigger(i);
  }

  Serial.begin(9600);
  millis_last_frame = millis();
  Serial.write('*');
}

void cycle_trigger_mode(int i) {
  trigger_modes[i] = 1 - trigger_modes[i];
}

void start_trigger(int i) {
  if (trigger_modes[i] == TRIGGER_MODE_ON_OFF) {
    if (current_states[i] == 0) {
      need_set_hi[i] = 1;
    } else {
      need_set_lo[i] = 1;
    }
  } else {
    millis_remaining[i] = 500;
    need_set_hi[i] = 1;
  }
}

void loop() {
  while (Serial.available() > 0) {
    const int byte = Serial.read();

    if (byte == int('c')) {
      cycle_trigger_mode(0);

    } else if (byte == int('d')) {
      cycle_trigger_mode(1);

    } else if (byte == int('a')) {
      start_trigger(0);

    } else if (byte == int('b')) {
      start_trigger(1);

    } else if (byte == int('r')) {
      for (int i = 0; i < 2; i++) {
        reset_trigger(i);
      }
    }
  }

  unsigned long millis_this_frame = millis();
  unsigned long dt = millis_this_frame - millis_last_frame;
  millis_last_frame = millis_this_frame;

  const unsigned long pins[2] = {LASER_PIN0, LASER_PIN1};
#if LASER_DEBUG //  debug - at interval
  for (int i = 0; i < 2; i++) {
    if (interval_states[i] == 0) {
      //  between pulses
      interval_ts[i] += dt;
      if (interval_ts[i] >= 500) {
        //  init pulse
        interval_ts[i] = 0;
        interval_states[i] = 1;
        millis_remaining[i] = 1000;
        analogWrite(pins[i], LASER_HI);
      }
    } else if (interval_states[i] == 1) {
      //  within pulse
      unsigned long rem = millis_remaining[i];
      if (rem > 0) {
        unsigned long left = rem >= dt ? rem - dt : 0;
        millis_remaining[i] = left;
        if (left == 0) {
          //  terminate pulse
          analogWrite(pins[i], 0);
          interval_states[i] = 0;
        }
      }
    }
  }
#else
  for (int i = 0; i < 2; i++) {
    unsigned long rem = millis_remaining[i];
    if (rem > 0) {
      unsigned long left = rem >= dt ? rem - dt : 0;
      millis_remaining[i] = left;
      if (left == 0) {
        //  terminate pulse
        need_set_lo[i] = 1;
      }
    }

    if (need_set_hi[i]) {
      need_set_hi[i] = 0;
      analogWrite(pins[i], LASER_HI);
      current_states[i] = 1;

    } else if (need_set_lo[i]) {
      need_set_lo[i] = 0;
      analogWrite(pins[i], 0);
      current_states[i] = 0;
    }
  }
#endif
}
