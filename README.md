# Build iOS Projects with Ruby

### Impetus

I was frustrated with the usual build apps - Gradle, Fastlane, etc. They didn't always work right. But mostly they tried to do to much. I don't need my build script to maintain my App IDs or my provision files. I know what I'm doing, thank you very much.

What I wanted was just something what would do a command line iOS build and upload it to HockeyApp or iTunes Connect.  It took a long time to find and organize the information on how to do all this stuff. But this ruby lib is the result.

There is currently no documentation on this other than the example build script. But I think if you read through the code, you'll find it easy to see what it's doing.

### What is it?
A ruby library (ruby\_build\_ios.rb) that contains methods to assist in building ios projects from the command line, and then (potentially) uploading the result to HockeyApp or iTunes Connect. Also included is an example ruby script (example.rb) that shows how to use the lib.

### Installation
Just download the two files and modify the example script to your needs.

### Use
It is assumed that your provision files are checked in to your repository and that the neccessary cert to cover those provision files is in the keychain on your build machine(s). We use ruby\_build\_ios for a number of build-machine builds. It gets along fine with Jenkins.

### Licensing
Both the library and the example script are covered by the MIT license in the repository.

### Suggestions and Bugs
Post something in the issues.

