autotakeoff = func {
  ato_start();      # Initiation stuff.
  ato_mode();       # Take-off/Climb-out mode handler.
  ato_spddep();     # Speed dependent actions.
  
  # Re-schedule the next loop
  if(getprop("/autopilot/locks/auto-take-off") != "Enabled") {
    print("Auto Take-Off disabled");
  } else {
    settimer(autotakeoff, 0.5);
  }
}
#--------------------------------------------------------------------
ato_start = func {
  # This script checks that the ground-roll-heading has been reset
  # (<-999) and that the a/c is on the ground.
  if(getprop("/autopilot/settings/ground-roll-heading-deg") < -999) {
    if(getprop("/position/altitude-agl-ft") < 0.01) {
      hdgdeg = getprop("/orientation/heading-deg");
      setprop("/autopilot/settings/ground-roll-heading-deg", hdgdeg);
      setprop("/autopilot/settings/true-heading-deg", hdgdeg);
      setprop("/controls/flight/flaps", 0.64);
      setprop("/autopilot/locks/altitude", "ground-roll");
      setprop("/autopilot/locks/speed", "speed-with-throttle");
      setprop("/autopilot/locks/heading", "wing-leveler");
      setprop("/autopilot/locks/rudder-control", "rudder-hold");
    }
  }
}
#--------------------------------------------------------------------
ato_mode = func {
  # This script sets the auto-takeoff mode and handles the switch
  # to climb-out mode.
  agl = getprop("position/altitude-agl-ft");
  if(agl < 50) {
    if(getprop("/velocities/airspeed-kt") > 100) {
      setprop("/autopilot/locks/altitude", "take-off");
    }
  } else {
    if(agl < 100) {
      setprop("/autopilot/locks/altitude", "climb-out");
      setprop("/controls/gear/gear-down", "false");
      setprop("/autopilot/locks/rudder-control", "reset");
      interpolate("/controls/flight/rudder", 0, 10);
    }
  }
}
#--------------------------------------------------------------------
ato_spddep = func {
  # This script controls speed dependent actions.
  airspeed = getprop("/velocities/airspeed-kt");
  if(airspeed < 160) {
    # Do not do anything until airspeed > 160kt.
  } else {
    if(airspeed < 170) {
      setprop("/controls/flight/flaps", 0.48);
    } else {
      if(airspeed < 180) {
        setprop("/controls/flight/flaps", 0.32);
      } else {
        if(airspeed < 190) {
          setprop("/controls/flight/flaps", 0.16);
        } else {
          if(airspeed < 200) {
            setprop("/controls/flight/flaps", 0.08);
          } else {
            if(airspeed < 210) {
              setprop("/controls/flight/flaps", 0);
            } else {
              # Switch to true-heading-hold, switch to Mach-Hold
              # throttle mode, mach-hold-climb mode and disable
              # Take-Off mode.
              setprop("/autopilot/locks/heading", "true-heading-hold");
              setprop("/autopilot/locks/speed", "mach-with-throttle");
              setprop("/autopilot/locks/altitude", "mach-climb");
              setprop("/autopilot/locks/auto-take-off", "Disabled");
            }
          }
        }
      }
    }
  }
}
#--------------------------------------------------------------------
autoland = func {
  # Get the agl, kias, vfps & heading.
  agl = getprop("/position/altitude-agl-ft");
  hdgdeg = getprop("/orientation/heading-deg");
  
  if(agl > 80) {
    # Glide Slope phase.
    atl_spddep();
    atl_glideslope();

    if(getprop("/autopilot/locks/heading") != "nav1-hold") {
      setprop("/autopilot/locks/heading", "nav1-hold");
      setprop("/autopilot/locks/speed", "speed-with-throttle");
    }

  } else {
    # Touch Down Phase
    atl_touchdown();
  }
  # Re-schedule the next loop if the Landing function is enabled.
  if(getprop("/autopilot/locks/auto-landing") != "Enabled") {
    print("Auto Landing disabled");
  } else {
    settimer(autoland, 0.5);
  }
}
#--------------------------------------------------------------------
atl_glideslope = func {
  # This script handles the Glide Slope phase
  gsvfps = getprop("/radios/nav[0]/gs-rate-of-climb");
  if(gsvfps > 40) {
    setprop("/autopilot/settings/target-vfps", 40);
    setprop("/autopilot/locks/altitude", "gs-vfps-lock1");
  } else {
    if(gsvfps > 20) {
      setprop("/autopilot/settings/target-vfps", 20);
      setprop("/autopilot/locks/altitude", "gs-vfps-lock2");
    } else {
      if(gsvfps > 10) {
        setprop("/autopilot/settings/target-vfps", 10);
        setprop("/autopilot/locks/altitude", "gs-vfps-lock3");
      } else {
        setprop("/autopilot/locks/altitude", "gs1-hold");
      }
    }
  }
}
#--------------------------------------------------------------------
atl_spddep = func {
  # This script handles the speed dependent actions.

  # Set the target speed to 250 max.
  if(getprop("/autopilot/settings/target-speed-kt") > 250) {
    setprop("/autopilot/settings/target-speed-kt", 250);
  }

  gsvfps = getprop("/radios/nav[0]/gs-rate-of-climb");
  kias = getprop("/velocities/airspeed-kt");
  if(kias < 155) {
    setprop("/autopilot/locks/approach-AoA-lock", "Engaged");
  } else {
    if(kias < 160) {
      setprop("/controls/flight/spoilers", 0);
      setprop("/controls/flight/flaps", 1.0);
    } else {
      if(kias < 170) {
        setprop("/controls/flight/spoilers", 0.1);
        setprop("/controls/flight/flaps", 0.82);
        setprop("/controls/gear/gear-down", "true");
      } else {
        if(kias < 180) {
          setprop("/controls/flight/spoilers", 0.2);
          setprop("/controls/flight/flaps", 0.64);
        } else {
          if(kias < 190) {
            setprop("/controls/flight/spoilers", 0.3);
            setprop("/controls/flight/flaps", 0.48);
          } else {
            if(kias < 200) {
              setprop("/controls/flight/spoilers", 0.4);
              setprop("/controls/flight/flaps", 0.32);
            } else {
              if(kias < 210) {
                setprop("/controls/flight/spoilers", 0.6);
                setprop("/controls/flight/flaps", 0.16);
              } else {
                if(kias < 220) {
                  setprop("/controls/flight/spoilers", 0.8);
                  setprop("/controls/flight/flaps", 0.08);
                } else {
                  if(getprop("/velocities/vertical-speed-fps") < -15) {
                    if(gsvfps < 0) {
                      setprop("/autopilot/settings/target-speed-kt", 150);
                      setprop("/controls/flight/spoilers", 1.0);
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
#--------------------------------------------------------------------
atl_touchdown = func {
  # Touch Down Phase
  agl = getprop("/position/altitude-agl-ft");
  setprop("/autopilot/locks/approach-AoA-lock", "Off");
  setprop("/autopilot/locks/altitude", "Touch Down");
  setprop("/autopilot/locks/auto-flap-control", "Manual");

  if(agl < 20) {
    setprop("/autopilot/locks/heading", "wing-leveler");
  }
  if(agl < 0.1) {
    setprop("/autopilot/locks/heading", "Off");
    setprop("/controls/flight/spoilers", 1);
    setprop("/autopilot/locks/speed", "Off");
    setprop("/controls/engines/engine[0]/throttle", 0);
    setprop("/controls/engines/engine[1]/throttle", 0);
  }
  if(agl < 0.01) {
    setprop("/controls/gear/brake-left", 0.4);
    setprop("/controls/gear/brake-right", 0.4);
    setprop("/autopilot/settings/ground-roll-heading-deg", -999.9);
    setprop("/autopilot/locks/auto-landing", "Disabled");
    setprop("/autopilot/locks/auto-take-off", "Enabled");
    setprop("/autopilot/locks/altitude", "Off");
    interpolate("/controls/flight/elevator-trim", 0, 10.0);
  }
}
#--------------------------------------------------------------------
