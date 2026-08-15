//==============================================================================
//  Project:     MoonPhaseWallpaper
//------------------------------------------------------------------------------
//  File:        set_wallpaper.js
//  Author:      Uli Treuer
//  Purpose:     Update the KDE Plasma wallpaper for the selected
//               Activity and screen.
//
// Input:
//      Activity ID
//      screen
//      wallpaper image incl. path
//
// Output:
//      Prints "1" if a wallpaper was updated.
//      Prints "0" if no matching desktop was found.
//
//  Copyright (c) 2026 Uli Treuer
//  License: MIT
//==============================================================================

var targetActivity = '__ACTIVITY__';
var targetScreen = __SCREEN__;
var wallpaper_changed = false;

print('Target Activity ID: ' + targetActivity + "\n");
print('Target Screen     : ' + targetScreen + "\n");

var desktops = desktopsForActivity(targetActivity);

print('Number of desktops: ' + desktops.length + "\n");

var targetDesktop = null;

for (var i = 0; i < desktops.length; i++) {
    var desktop = desktops[i];

    // For inactive Activities, desktop.screen is not reliable.
    // The lastScreen configuration entry identifies the physical screen.
    var lastScreen = desktop.readConfig('lastScreen', -1);

    print(
        'Containment ' + desktop.id + "\n" +
        ': screen=' + desktop.screen + "\n" +
        ', lastScreen=' + lastScreen + "\n"
    );

    if (lastScreen === targetScreen) {
        targetDesktop = desktop;
        break;
    }
}

if (targetDesktop === null) {
    print('ERROR: Target screen not found.' + "\n");
} else {
    print(
        'Selected containment: ' +
        targetDesktop.id + "\n"
    );

    targetDesktop.wallpaperPlugin = "org.kde.image";
    targetDesktop.currentConfigGroup = ["Wallpaper", "org.kde.image", "General"];
    targetDesktop.writeConfig("Image", "file://__WALLPAPER_IMAGE__");

    targetDesktop.reloadConfig();
    wallpaper_changed = true;
}

print("__RESULT__:" + (wallpaper_changed ? "1" : "0"));

// --- This is the end, my friend ------------------------------------------------------------------
