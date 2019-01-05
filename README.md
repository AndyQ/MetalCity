MetalCity
=========

MetalCity is night city scape full procedurally generated, for both iOS and macOS.  Its fully written in Swift (4.2) and uses Metal for the rendering engine.

It features:
- Procedurally generated road and - building plots
- 4 different styles of buildings (simple, tower, blocky and modern)
- Procedurally generated textures
- Traffic
- Static and Autocam modes
- Fireworks

Its heavily based off Shamus Young's PixelCity - http://www.shamusyoung.com/twentysidedtale/?p=2940

The fireworks are based on Karl Pickett's Fireworks Graphics Demo (https://github.com/kjpgit/fireworks) - updated for Swift 4.2 and changes in Metal.

The menu was done by Simeon Saëns of TwoLivesLeft - https://github.com/TwoLivesLeft/Menu

This was written as a way for me to get more familiar with Metal and as its my second Metal app, I'm sure that there are many things I'm doing wrong (feedback and comments welcomed!).


## iOS Version

<p align="center"><img title="iOS" src="https://raw.githubusercontent.com/AndyQ/MetalCity/master/ios.gif"/></p>

### Important note:
The app will compile and run on the Simulator BUT the city won't render as Metal currently isn't supported on the iOS Simulator yet.

### Controls
Tap on screen to toggle the control menu<br>
From here you can:
- Toggle the autocam on/off
- Change to the next autocam mode (if autocam is running)
- Regenerate the city
- Regenerate the textures (usually also requires regenerating the city afterwards)

If Autocam is running, the camera switches between different camera angles.

If Autocam is off then you can manually move the camera using:

- 1 finger:
  - Left of screen - drag up and down will rotate camera up and down
  - Right of screen - drag up and down will move camera up and down
  - Center of screen - drag left and right will rotate camera left and right

- 2 fingers:
  - Drag up and down will move camera forward and backward
  - Drag left and right will rotate camera left and right

- 3 fingers:
  - Drag up and down will move camera up and down
  - Drag left and right will strafe camera left and right


## macOS Version

<p align="center"><img title="iOS" src="https://raw.githubusercontent.com/AndyQ/MetalCity/master/macos.gif"/></p>

### Controls

**Keyboard**
 - c - toggles Autocam on/off
 - [space] - change to next autocam mode
 - r - rebuild city
 - t - Regenerate the textures (usually also requires regenerating the city afterwards)

**Mouse**
- Click and drag to look around
- Hold Command and click and drag up and down to rotate camera up and down
- Hold Option and click and drag up and down to move camera up and down
- Hold Option and click and drag left and right to strafe camera up and down


## License

The MIT License (MIT)
Copyright (c) 2018 Andy Qua

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.