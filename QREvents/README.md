QREvents
=====

Building
-----

This project requires Xcode 5 or higher to build, and iOS6 or higher to run.

1. Install [mogenerator](http://rentzsch.github.io/mogenerator/). mogenerator, manages CoreData entities better.
2. Download this repo: ```git clone https://github.com/paul-delange/sakai.git ```
3. Navigate to the new folder and update git with: ```git submodule update --init --recursive```. This will install dependent projects (RestKit, zbar)
4. Open **QREvents.xcworkspace** and build

Project Help
------

1. Inside the .pch file, there is a variable ```USING_PARSE_DOT_COM```. Change this to switch between the prototype parse.com API and the production API we developed.
2. App works on iPad2, iPad (3rd Gen), iPad (4th Gen), iPad Mini
3. QR code scanning only works on a device.


