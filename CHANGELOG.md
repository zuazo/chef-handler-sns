# CHANGELOG for chef-handler-sns

This file is used to list changes made in each version of `chef-handler-sns`.

## 2.0.0 (2015-12-28)

### Breaking Changes on v2.0.0

* Drop Ruby `< 2` support.
* Update AWS SDK to version `2`.

### Fixes on v2.0.0

* Improve wrong encoding support (issues [#6](https://github.com/zuazo/chef-handler-sns/pull/6) and [#7](https://github.com/zuazo/chef-handler-sns/pull/7), thanks [Michael Hobbs](https://github.com/michaelshobbs)).
* Limit subject and body size properly.

### Improvements on v2.0.0

* Fix all RuboCop offenses.
* Document all the code.

### Documentation Changes on v2.0.0

* Update contact information and links after migration.
* Update chef links to use *chef.io* domain.
* README:
 * Multiple fixes, improvements and added some examples.
 * Split README file into multiple files.
 * Add GitHub and License badges.

### Changes on Tests on v2.0.0

* Tests clean up.
* Fix assertion arguments order.
* Travis CI: Test against Ruby `2.2` and Chef `12`.
* Integrate tests with `should_not` gem.

## 1.2.0 (2014-07-04)

* README:
 * Added Method 2.2: LWRP inside OpsWorks (related to [issue #4](https://github.com/zuazo/chef-handler-sns/issues/4)).
 * Add a note in the method 2 about convergence phase (related to [issue #3](https://github.com/zuazo/chef-handler-sns/issues/3)).
 * Some capitals fixed.
 * Added ohai credentials explanation (related to [cookbook issue #1](https://github.com/zuazo/chef_handler_sns-cookbook/issues/1)).
 * *filter_opsworks_activities* documentation improved.
 * Use [shields.io](http://shields.io/) badges.
 * *Contributing* section completed.
* Fixed *AWS::SNS::Errors::InvalidClientTokenId* when using version 1.1.0 ([issue #5](https://github.com/zuazo/chef-handler-sns/issues/5), thanks [Michael Hobbs](https://github.com/michaelshobbs) for reporting and testing).

## 1.1.0 (2014-03-17)

* Filter Notifications by Opsworks Activity ([issue #2](https://github.com/zuazo/chef-handler-sns/pull/2), thanks [Florian Holzhauer](https://github.com/fh))

## 1.0.0 (2014-02-19)

* Replaced `right_aws` dependency with `aws-sdk` gem.
  * Update the tests and the README.
* Add security tokens support.
* IAM roles support ([issue #1](https://github.com/zuazo/chef-handler-sns/issues/1), thanks [Michael T. Halligan](https://github.com/mhalligan) for reporting).
  * Read AWS credentials from Ohai (IAM role) by default.
* Gemfile: add_development_dependency for Ruby 1.8 compatibility now checks ruby version.
* Travis: added Ruby 2.1 to the tests.
* LICENSE: brackets replaced by copyright owner.
* Added Coverall badge again.
* Multiple README improvements and fixes.

## 0.2.6 (2013-11-15)

* Gemspec: added license.

## 0.2.5 (2013-11-01)

A Bug fix release:
* Multiple fixes in the README examples.
* Removed coveralls link from the README, sends erroneus reports.
* Added `.coveralls.yml` file.
* Removed the needless `require 'rubygems'` from the tests.
* Added `simplecov` gem for coverage tests.
* Force `mime-type` version to `~> 1.0` to fix the tests on some cases (travis related).
* Homepage changed to *GitHub Pages*.

