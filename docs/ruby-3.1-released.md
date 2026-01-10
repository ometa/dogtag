 Ruby 3.1.0 Released            

[

Ruby
====

A Programmer's Best Friend
--------------------------

](/en/)

[Home](/en/) [Downloads](/en/downloads/) [Documentation](/en/documentation/) [Libraries](/en/libraries/) [Community](/en/community/) [News](/en/news/) [Security](/en/security/) [About Ruby](/en/about/) [Menu](#)

  

Ruby 3.1.0 Released
===================

Posted by naruse on 25 Dec 2021

We are pleased to announce the release of Ruby 3.1.0. Ruby 3.1 keeps compatibility with Ruby 3.0 and also adds many features.

YJIT: New experimental in-process JIT compiler
----------------------------------------------

Ruby 3.1 merges YJIT, a new in-process JIT compiler developed by Shopify.

Since [Ruby 2.6 introduced MJIT in 2018](https://www.ruby-lang.org/en/news/2018/12/25/ruby-2-6-0-released/), its performance greatly improved, and finally [we achieved Ruby3x3 last year](https://www.ruby-lang.org/en/news/2020/12/25/ruby-3-0-0-released/). But even though the Optcarrot benchmark has shown impressive speedups, the JIT has not benefited real world business applications.

Recently Shopify contributed many Ruby improvements to speed up their Rails application. YJIT is an important contribution, and aims to improve the performance of Rails applications.

While MJIT is a method-based JIT compiler and uses an external C compiler, YJIT uses Basic Block Versioning and includes a JIT compiler inside it. With Lazy Basic Block Versioning (LBBV) it first compiles the beginning of a method, and incrementally compiles the rest when the type of arguments and variables are dynamically determined. See [YJIT: a basic block versioning JIT compiler for CRuby](https://dl.acm.org/doi/10.1145/3486606.3486781) for a detailed introduction.

With this technology, YJIT achieves both fast warmup time and performance improvements on most real-world software, up to 22% on railsbench, 39% on liquid-render.

YJIT is still an experimental feature, and as such, it is disabled by default. If you want to use this, specify the `--yjit` command-line option to enable YJIT. It is also limited to Unix-like x86-64 platforms for now.

*   [https://bugs.ruby-lang.org/issues/18229](https://bugs.ruby-lang.org/issues/18229)
*   [https://shopify.engineering/yjit-just-in-time-compiler-cruby](https://shopify.engineering/yjit-just-in-time-compiler-cruby)
*   [https://www.youtube.com/watch?v=PBVLf3yfMs8](https://www.youtube.com/watch?v=PBVLf3yfMs8)

debug gem: A new debugger
-------------------------

A completely rewritten debugger [debug.gem](https://github.com/ruby/debug) is bundled. debug.gem has the following features:

*   Improve the debugging performance (it does not slow down the application even with the debugger).
*   Support remote debugging.
*   Support rich debugging frontend (VS Code and Chrome browser are supported currently).
*   Support multi-process/multi-thread debugging.
*   Colorful REPL.
*   And other useful features like record & replay feature, tracing feature and so on.

Ruby had bundled lib/debug.rb, but it was not well maintained and it had issues about performance and features. debug.gem replaces lib/debug.rb completely.

error\_highlight: Fine-grained error location in backtrace
----------------------------------------------------------

A built-in gem, error\_highlight, has been introduced. It includes fine-grained error location in backtraces:

    $ ruby test.rb
    test.rb:1:in `<main>': undefined method `time' for 1:Integer (NoMethodError)
    
    1.time {}
     ^^^^^
    Did you mean?  times
    

Currently, only `NameError` is supported.

This gem is enabled by default. You can disable it by using the command-line option `--disable-error_highlight`. See the [error\_highlight repository](https://github.com/ruby/error_highlight) for details.

IRB Autocomplete and Documentation Display
------------------------------------------

The IRB now has an autocomplete feature, where you can just type in the code, and the completion candidates dialog will appear. You can use Tab and Shift+Tab to move up and down.

If documentation is installed when you select a completion candidate, the documentation dialog will appear next to the completion candidates dialog, showing part of the content. You can read the full documentation by pressing Alt+d.

Other Notable New Features
--------------------------

### Language

*   Values in Hash literals and keyword arguments can be omitted. [\[Feature #14579\]](https://bugs.ruby-lang.org/issues/14579)
    *   `{x:, y:}` is syntax sugar for `{x: x, y: y}`.
    *   `foo(x:, y:)` is syntax sugar for `foo(x: x, y: y)`.
*   The pin operator (`^`) in pattern matching now takes an expression. [\[Feature #17411\]](https://bugs.ruby-lang.org/issues/17411)
    
        Prime.each_cons(2).lazy.find_all{_1 in [n, ^(n + 2)]}.take(3).to_a
        #=> [[3, 5], [5, 7], [11, 13]]
        
    
*   Parentheses can be omitted in one-line pattern matching. [\[Feature #16182\]](https://bugs.ruby-lang.org/issues/16182)
    
        [0, 1] => _, x
        {y: 2} => y:
        x #=> 1
        y #=> 2
        
    

### RBS

RBS is a language to describe the structure of Ruby programs. See the [RBS repository](https://github.com/ruby/rbs) for details.

Updates since Ruby 3.0.0:

*   Generic type parameters can be bounded. ([PR](https://github.com/ruby/rbs/pull/844))
*   Generic type aliases are supported. ([PR](https://github.com/ruby/rbs/pull/823))
*   `rbs collection` has been introduced to manage gems’ RBSs. ([doc](https://github.com/ruby/rbs/blob/master/docs/collection.md))
*   Many signatures for built-in and standard libraries have been added/updated.
*   It includes many bug fixes and performance improvements too.

See the [RBS changelog](https://github.com/ruby/rbs/blob/master/CHANGELOG.md) for more information.

### TypeProf

TypeProf is a static type analyzer for Ruby. It generates a prototype of RBS from non-type-annotated Ruby code. See the [documentation](https://github.com/ruby/typeprof/blob/master/doc/doc.md) for details.

The main update since Ruby 3.0.0 is an experimental IDE support called “TypeProf for IDE”.

![Demo of TypeProf for IDE](https://cache.ruby-lang.org/pub/media/ruby310_typeprof_ide_demo.png)

The VS Code extension shows a guessed (or explicitly written in an RBS file) method signature above each method definition, draws a red underline under the code that may cause a name error or type error, and completes method names (i.e., shows method candidates). See the [documentation](https://github.com/ruby/typeprof/blob/master/doc/ide.md) for details.

Also, the release includes many bug fixes and performance improvements.

Performance improvements
------------------------

*   MJIT
    *   For workloads like Rails, the default `--jit-max-cache` is changed from 100 to 10000. The JIT compiler no longer skips compilation of methods longer than 1000 instructions.
    *   To support Zeitwerk of Rails, JIT-ed code is no longer cancelled when a TracePoint for class events is enabled.

Other notable changes since 3.0
-------------------------------

*   One-line pattern matching, e.g., `ary => [x, y, z]`, is no longer experimental.
*   Multiple assignment evaluation order has been changed slightly. [\[Bug #4443\]](https://bugs.ruby-lang.org/issues/4443)
    *   `foo[0], bar[0] = baz, qux` was evaluated in order `baz`, `qux`, `foo`, and then `bar` in Ruby 3.0. In Ruby 3.1, it is evaluated in order `foo`, `bar`, `baz`, and then `qux`.
*   Variable Width Allocation: Strings (experimental). [\[Bug #18239\]](https://bugs.ruby-lang.org/issues/18239)
    
*   Psych 4.0 changes `Psych.load` to use `safe_load` by default. You may need to use Psych 3.3.2 for migrating to this behavior. [\[Bug #17866\]](https://bugs.ruby-lang.org/issues/17866)

### Standard libraries updates

*   The following default gems are updated.
    *   RubyGems 3.3.3
    *   base64 0.1.1
    *   benchmark 0.2.0
    *   bigdecimal 3.1.1
    *   bundler 2.3.3
    *   cgi 0.3.1
    *   csv 3.2.2
    *   date 3.2.2
    *   did\_you\_mean 1.6.1
    *   digest 3.1.0
    *   drb 2.1.0
    *   erb 2.2.3
    *   error\_highlight 0.3.0
    *   etc 1.3.0
    *   fcntl 1.0.1
    *   fiddle 1.1.0
    *   fileutils 1.6.0
    *   find 0.1.1
    *   io-console 0.5.10
    *   io-wait 0.2.1
    *   ipaddr 1.2.3
    *   irb 1.4.1
    *   json 2.6.1
    *   logger 1.5.0
    *   net-http 0.2.0
    *   net-protocol 0.1.2
    *   nkf 0.1.1
    *   open-uri 0.2.0
    *   openssl 3.0.0
    *   optparse 0.2.0
    *   ostruct 0.5.2
    *   pathname 0.2.0
    *   pp 0.3.0
    *   prettyprint 0.1.1
    *   psych 4.0.3
    *   racc 1.6.0
    *   rdoc 6.4.0
    *   readline 0.0.3
    *   readline-ext 0.1.4
    *   reline 0.3.0
    *   resolv 0.2.1
    *   rinda 0.1.1
    *   ruby2\_keywords 0.0.5
    *   securerandom 0.1.1
    *   set 1.0.2
    *   stringio 3.0.1
    *   strscan 3.0.1
    *   tempfile 0.1.2
    *   time 0.2.0
    *   timeout 0.2.0
    *   tmpdir 0.1.2
    *   un 0.2.0
    *   uri 0.11.0
    *   yaml 0.2.0
    *   zlib 2.1.1
*   The following bundled gems are updated.
    *   minitest 5.15.0
    *   power\_assert 2.0.1
    *   rake 13.0.6
    *   test-unit 3.5.3
    *   rexml 3.2.5
    *   rbs 2.0.0
    *   typeprof 0.21.1
*   The following default gems are now bundled gems. You need to add the following libraries to `Gemfile` under the bundler environment.
    *   net-ftp 0.1.3
    *   net-imap 0.2.2
    *   net-pop 0.1.1
    *   net-smtp 0.3.1
    *   matrix 0.4.2
    *   prime 0.1.2
    *   debug 1.4.0

See [NEWS](https://github.com/ruby/ruby/blob/v3_1_0/NEWS.md) or the [commit logs](https://github.com/ruby/ruby/compare/v3_0_0...v3_1_0) for more details.

With those changes, [3124 files changed, 551760 insertions(+), 99167 deletions(-)](https://github.com/ruby/ruby/compare/v3_0_0...v3_1_0#file_bucket) since Ruby 3.0.0!

Merry Christmas, Happy Holidays, and enjoy programming with Ruby 3.1!

Download
--------

*   [https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.0.tar.gz](https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.0.tar.gz)
    
        SIZE: 20103517
        SHA1: e4e8c20dd2a1fdef4d3e5bd5a3461000dd17f226
        SHA256: 50a0504c6edcb4d61ce6b8cfdbddaa95707195fab0ecd7b5e92654b2a9412854
        SHA512: 76009d325e961e601d9a287e36490cbc1f3b5dbf4878fa6eab2c4daa5ff2fed78cbc7525cd87b09828f97cbe2beb30f528928bcc5647af745d03dffe7c5baaa9
        
    
*   [https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.0.tar.xz](https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.0.tar.xz)
    
        SIZE: 14709096
        SHA1: 92b603c2a69fb25d66c337a63e94280984edea11
        SHA256: 1a0e0b69b9b062b6299ff1f6c6d77b66aff3995f63d1d8b8771e7a113ec472e2
        SHA512: a2bb6b5e62d5fa06dd9c30cf84ddcb2c27cb87fbaaffd2309a44391a6b110e1dde6b7b0d8c659b56387ee3c9b4264003f3532d5a374123a7c187ebba9293f320
        
    
*   [https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.0.zip](https://cache.ruby-lang.org/pub/ruby/3.1/ruby-3.1.0.zip)
    
        SIZE: 24388179
        SHA1: e37435956d6f840a0e8758d7374bc7e0e346105f
        SHA256: a3bfcd486d09c065d46421da0ff3d430ce4423fefd80cea63c6595d83ae4af0e
        SHA512: 67db71144e06da2c1c25eaf413d1417c99a4b18738a573f9e3371c11ea242eee9dcbdc3de17336f25ab5060039fe034e57298943d344be9cd9eb33bb56e2e1c6
        
    

What is Ruby
------------

Ruby was first developed by Matz (Yukihiro Matsumoto) in 1993, and is now developed as Open Source. It runs on multiple platforms and is used all over the world especially for web development.

* * *

### **Recent News**

*   [Ruby 4.0.0 preview2 Released](/en/news/2025/11/17/ruby-4-0-0-preview2-released/)
*   [Ruby 3.3.10 Released](/en/news/2025/10/23/ruby-3-3-10-released/)
*   [The Transition of RubyGems Repository Ownership](/en/news/2025/10/17/rubygems-repository-transition/)
*   [Ruby 3.4.7 Released](/en/news/2025/10/07/ruby-3-4-7-released/)
*   [CVE-2025-61594: URI Credential Leakage Bypass previous fixes](/en/news/2025/10/07/uri-cve-2025-61594/)

### Syndicate

[Recent News (RSS)](/en/feeds/news.rss)

* * *

[Home](/en/) [Downloads](/en/downloads/) [Documentation](/en/documentation/) [Libraries](/en/libraries/) [Community](/en/community/) [News](/en/news/) [Security](/en/security/) [About Ruby](/en/about/)

This site in other languages: [Български](/bg/), [Deutsch](/de/), [English](/en/), [Español](/es/), [Français](/fr/), [Bahasa Indonesia](/id/), [Italiano](/it/), [日本語](/ja/), [한국어](/ko/), [polski](/pl/), [Português](/pt/), [Русский](/ru/), [Türkçe](/tr/), [Tiếng Việt](/vi/), [简体中文](/zh_cn/), [繁體中文](/zh_tw/).

[This website](/en/about/website/) is proudly maintained by members of the Ruby community.