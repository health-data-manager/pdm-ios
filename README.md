# Patient Data Manager

There is currently one setup part that has to be done before the app will work. You will need to copy `Settings-Example.plist` in `pdm-ui` to `Settings.plist` and fill in the missing fields. Otherwise the application will immediately fail on launch, because the settings are loaded from that plist.

# Contributing to PDM

We love your input! We want to make contributing to this project as easy and transparent as possible, whether it's:

* Reporting a bug
* Discussing the current state of the code
* Submitting a fix
* Proposing new features
* Becoming a maintainer

### We Develop with Github

We use github to host code, to track issues and feature requests, as well as accept pull requests.

### We Use [Github Flow](https://guides.github.com/introduction/flow/index.html), So All Code Changes Happen Through Pull Requests

Pull requests are the best way to propose changes to the codebase. We actively welcome your pull requests:

* Fork the repo and create your branch from master.
* If you've added code that should be tested, add tests.
* If you've changed APIs, update the documentation.
* Ensure the test suite passes.
* Make sure your code lints.
* Issue that pull request!

### Any contributions you make will be under the Apache 2 Software License

In short, when you submit code changes, your submissions are understood to be under the same Apache 2 license that covers the project. Feel free to contact the maintainers if that's a concern.

### Report bugs using Github's issues

We use GitHub issues to track public bugs. Report a bug by opening a new issue it's that easy!

### Write bug reports with detail, background, and sample code

Great Bug Reports tend to have:

* A quick summary and/or background
* Steps to reproduce
* Be specific!
* Give sample code if you can. 
* What you expected would happen
* What actually happens
* Notes (possibly including why you think this might be happening, or stuff you tried that didn't work)
* People love thorough bug reports. I'm not even kidding.

### Use a Consistent Coding Style

The PDM project uses Rubocop as a means to ensure code style consistency.  This is run as part of the test suite.  Contributions that do not pass the conformance tests will be rejected.

# License

Copyright (c) 2019 by MITRE.

Licensed under the [Apache 2.0 License](LICENSE).
