//==============================================================================
//  Project:     MoonPhaseWallpaper
//------------------------------------------------------------------------------
//  File:        verify_screen.js
//  Author:      Uli Treuer
//  Purpose:     Verify whether a specified screen is currently reported
//               by Plasma.
//
// Input:
//      screen
//
// Output:
//      Prints "1" if screen is available.
//      Prints "0" if screen is not available
//
//  Copyright (c) 2026 Uli Treuer
//  License: MIT
//==============================================================================

var allDesktops = desktops();
var screen_available = false;

for (var i = 0; i < allDesktops.length; i++) {
    var d = allDesktops[i];

    if (d.screen == "__SCREEN__") {
        screen_available = true;
    }
}

print(screen_available ? "1\n" : "0\n");

// --- This is the end, my friend ------------------------------------------------------------------
