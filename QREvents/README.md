QREvents
=====

Building
-----

1. Install [mogenerator](http://rentzsch.github.io/mogenerator/). mogenerator, manages Core Data entities better.
2. Download this repo: ```git clone https://github.com/paul-delange/sakai.git ```
3. Navigate to the new folder and update git with: ```git submodule update --init --recursive```. This will install dependent projects (RestKit, zbar)
3.1 ごめんなさい。RestKitを追加したときに失敗したみたいです。Move into the folder ```cd QREvents/RestKit```, and then use this command ```git checkout ed7657020c9804364447c5b438c7504a85545cf7```
4. Open **QREvents.xcworkspace** and build　**QREvents** target

Project Help
------

1. Inside the .pch file, there is a variable ```USING_PARSE_DOT_COM```. Change this to switch between the prototype parse.com API and the production API we developed.
2. App works on iPad2, iPad (3rd Gen), iPad (4th Gen) & iPad Mini
3. QR code scanning only works on a device.
4. This project requires Xcode 5 or higher to build, and iOS6 or higher to run.

Known issues
-----

1. If you delete a participant on the server, it is not removed from the app. Fix: reset the event
2. Sometimes, when you scan a bad QR code, the scanner stops reading new codes. Fix: close the scan view and start again.



