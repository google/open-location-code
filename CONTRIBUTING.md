Want to contribute? Great! First, read this page (including the small print at the end).

## Before you contribute
Before we can use your code, you must sign the
[Google Individual Contributor License Agreement](https://developers.google.com/open-source/cla/individual?csw=1)
(CLA), which you can do online.

The CLA is necessary mainly because you own the
copyright to your changes, even after your contribution becomes part of our
codebase, so we need your permission to use and distribute your code. We also
need to be sure of various other things—for instance that you'll tell us if you
know that your code infringes on other people's patents.

You don't have to sign
the CLA until after you've submitted your code for review and a member has
approved it, but you must do it before we can put your code into our codebase.
Before you start working on a larger contribution, you should get in touch with
us first through the issue tracker with your idea so that we can help out and
possibly guide you. Coordinating up front makes it much easier to avoid
frustration later on.

## Writing a new implementation

Before you start writing a new implementation, look at some of the existing ones. If you copy the
code structure from them, you are more likely to have fewer bugs and an easier review cycle.

If you create new algorithms to encode or decode, then your reviewer will have to spend more time
trying to understand your code in a language they may not be familiar with, and the review cycle
will take longer.

The reason we say this is because once code is accepted into our repository, we have the responsibility
to maintain and look after it. You are not writing the code for you, but for the OLC project team.

## Code reviews
All submissions, including submissions by project members, require review. We
use Github pull requests for this purpose.

## Code Style
Programs written in Go must be formatted with `gofmt`. For other languages, we use the 
[Google style guides](https://google.github.io/styleguide/) for code styling. Specifically, this means:

* Line length: 80 chars (Java 100)
* No extra whitespace around arguments `(code)` not `( code )`
*  K & R style braces:
```java
if (condition()) {
  something();
} else {
  somethingElse();
}
```

## The small print
Contributions made by corporations are covered by a different agreement than
the one above, the Software Grant and Corporate Contributor License Agreement.
