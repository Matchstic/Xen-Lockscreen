The names available can be found in a README.txt at /Library/Application Support/Xen/Themes/Ivory/Toggles/Glyphs. The toggles ideally should be around the same size as the default, which is 47 x 47 px for @1x.

The previews in Launchpad can also be themed as of Xen 0.3.1 in the folder Launchpad/Previews in your theme. Each preview image is always portrait, and to account for different display sizes, uses the following format for image names:

<bundle_identifier>-<screentype>.png
<bundle_identifier>-<screentype>@2x.png
<bundle_identifier>-<screentype>@3x.png

where screentype will be one of the following:
480 (iPhone 4S) (will have only a @2x variant)
568 (iPhone 5, 5S, 5C, and SE, plus the iTouch 5) (only needs a @2x variant)
667 (iPhone 6, 6S, 6+ and 6S+) (needs a @2x and @3x)
ipad (all types of iPad) (needs a non @, and a @2x)

Size wise, use the screen size of the device. Eg:

iPhone 4S == 640 × 960 px.