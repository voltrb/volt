Contributing to Volt
=====================

You want to contribute? Great! Thanks for being awesome!  Volt is work of [hundreds of contributors](https://github.com/voltrb/volt/graphs/contributors). You're encouraged to submit [pull requests](https://github.com/voltrb/volt/pulls), [propose features and discuss issues](https://github.com/voltrb/volt/issues). When in doubt, ask a question in the [Volt gitter.im chatroom](https://gitter.im/voltrb/volt).

#### Find Something to Work on

If you want to contribute, but aren't sure what to work on, we keep our list of current todos in Trello at https://trello.com/b/QdCx9Tqb/volt  Before starting, feel free to chat with me @ryanstout on [gitter](https://gitter.im/voltrb/volt).

#### Fork the Project

Fork the [project on Github](https://github.com/voltrb/volt) and check out your copy.

```
git clone https://github.com/contributor/volt.git
cd volt
git remote add upstream https://github.com/voltrb/volt.git
```

#### Create a Topic Branch

Make sure your fork is up-to-date and create a topic branch for your feature or bug fix.

```
git checkout master
git pull upstream master
git checkout -b my-feature-branch
```

#### Bundle Install and Test
Ensure that PhantomJS is installed on your computer.

```
phantomjs --version
```

If not installed, you can install from the source or use Homebrew:

```
brew upgrade && brew install phantomjs
```

#### Bundle Install and Test

Ensure that you can build the project and run tests.

```
bundle install
bundle exec rake
```

By default rake doesn't run the integration tests.  The integration tests use capybara to run the tests in a real browser, (read more [here](https://github.com/voltrb/docs/blob/master/en/docs/testing.md)).  You can run with integration tests in a browser with:

```
BROWSER=firefox bundle exec rake
````

#### Write Tests

Try to write a test that reproduces the problem you're trying to fix or describes a feature that you want to build. Add to [spec/volt](spec/volt).

We definitely appreciate pull requests that highlight or reproduce a problem, even without a fix.

#### Write Code

Implement your feature or bug fix.

Ruby style is enforced with [Rubocop](https://github.com/bbatsov/rubocop), run `bundle exec rubocop` and fix any style issues highlighted.

Make sure that `bundle exec rake` completes without errors.

#### Write Documentation

Document any external behavior in the [README](README.md).

#### Commit Changes

Make sure git knows your name and email address:

```
git config --global user.name "Your Name"
git config --global user.email "contributor@example.com"
```

Writing good commit logs is important. A commit log should describe what changed and why.

```
git add ...
git commit
```

#### Push

```
git push origin my-feature-branch
```

#### Make a Pull Request

Go to https://github.com/contributor/volt and select your feature branch. Click the 'Pull Request' button and fill out the form. Pull requests are usually reviewed within a few days.

#### Rebase

If you've been working on a change for a while, rebase with upstream/master.

```
git fetch upstream
git rebase upstream/master
git push origin my-feature-branch -f
```

#### Update CHANGELOG Again

Update the [CHANGELOG](CHANGELOG.md) with the pull request number. A typical entry looks as follows.

```
* [#123](https://github.com/voltrb/volt/pull/123): Reticulated splines - [@contributor](https://github.com/contributor).
```

Amend your previous commit and force push the changes.

```
git commit --amend
git push origin my-feature-branch -f
```

#### Check on Your Pull Request

Go back to your pull request after a few minutes and see whether it passed muster with Travis-CI. Everything should look green, otherwise fix issues and amend your commit as described above.

#### Thank You

Please do know that we really appreciate and value your time and work. We love you, really.