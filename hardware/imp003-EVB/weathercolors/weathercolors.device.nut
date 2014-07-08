// imp003-EVB example code
// show current temperature as color with RGB LED
// Copyright (C) 2014 Electric Imp, Inc.

// PWM frequency
const PWMFREQ = 1000.0; // 1 kHz

// imp003 EVB pin assignments
redled <- hardware.pinE;
grnled <- hardware.pinF;
bluled <- hardware.pinK;

// GLOBAL FUNCTION AND CLASS DEFINITIONS ---------------------------------------

// set the current color of the RGB LED
// color is a table with three keys ("red", "grn", "blu")
// valid values are 0.0 to 255.0
function setColor(color) {
    redled.write(1.0 - (color.red / 255.0));
    grnled.write(1.0 - (color.grn / 255.0));
    bluled.write(1.0 - (color.blu / 255.0));
}

// AGENT CALLBACKS -------------------------------------------------------------

// register a callback for the "newcolor" event from the agent
agent.on("setcolor", setColor);

// RUNTIME BEGINS HERE ---------------------------------------------------------

// configure pins
redled.configure(PWM_OUT, 1.0/PWMFREQ, 1.0);
grnled.configure(PWM_OUT, 1.0/PWMFREQ, 1.0);
bluled.configure(PWM_OUT, 1.0/PWMFREQ, 1.0);

// notify the agent that we've just restarted and need a new color setting
agent.send("start", 0);
