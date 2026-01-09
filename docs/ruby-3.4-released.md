 Ruby 3.4.0 Released | Ruby                               (function() { const theme = localStorage.getItem('theme-preference') || 'auto'; if (theme === 'dark') { document.documentElement.classList.add('dark'); } else if (theme === 'light') { document.documentElement.classList.remove('dark'); } else if (window.matchMedia('(prefers-color-scheme: dark)').matches) { document.documentElement.classList.add('dark'); } })(); (function() { if (document.fonts && document.fonts.load) { document.fonts.load('24px "Material Symbols Rounded"').then(function() { document.documentElement.classList.add('fonts-loaded'); }).catch(function() { document.documentElement.classList.add('fonts-loaded'); }); } else { document.documentElement.classList.add('fonts-loaded'); } })();

 [![Ruby](/images/header-ruby-logo.svg) Ruby](/en/)

[Install](/en/documentation/installation/) [Docs](/en/documentation/) [Libraries](/en/libraries/) [Contribution](/en/community/ruby-core/) [Community](/en/community/) [News](/en/news/)

English (en)

[Български (bg)](/bg/news/2024/12/25/ruby-3-4-0-released/) [Deutsch (de)](/de/news/2024/12/25/ruby-3-4-0-released/) [English (en)](/en/news/2024/12/25/ruby-3-4-0-released/) [Español (es)](/es/news/2024/12/25/ruby-3-4-0-released/) [Français (fr)](/fr/news/2024/12/25/ruby-3-4-0-released/) [Indonesia (id)](/id/news/2024/12/25/ruby-3-4-0-released/) [Italiano (it)](/it/news/2024/12/25/ruby-3-4-0-released/) [日本語 (ja)](/ja/news/2024/12/25/ruby-3-4-0-released/) [한국어 (ko)](/ko/news/2024/12/25/ruby-3-4-0-released/) [polski (pl)](/pl/news/2024/12/25/ruby-3-4-0-released/) [Português (pt)](/pt/news/2024/12/25/ruby-3-4-0-released/) [Русский (ru)](/ru/news/2024/12/25/ruby-3-4-0-released/) [Türkçe (tr)](/tr/news/2024/12/25/ruby-3-4-0-released/) [Українська (uk)](/uk/news/2024/12/25/ruby-3-4-0-released/) [Tiếng Việt (vi)](/vi/news/2024/12/25/ruby-3-4-0-released/) [简体中文 (zh\_cn)](/zh_cn/news/2024/12/25/ruby-3-4-0-released/) [繁體中文 (zh\_tw)](/zh_tw/news/2024/12/25/ruby-3-4-0-released/)

[Install](/en/documentation/installation/) [Docs](/en/documentation/) [Libraries](/en/libraries/) [Contribution](/en/community/ruby-core/) [Community](/en/community/) [News](/en/news/)

### News

[News](/en/news/)

[Security](/en/security/)

[Recent News (RSS)](/en/feeds/news.rss)

### News

[News](/en/news/)

[Security](/en/security/)

[Recent News (RSS)](/en/feeds/news.rss)

Table of Contents

### Table of Contents

Ruby 3.4.0 Released
===================

Posted by **naruse** on 25 Dec 2024

We are pleased to announce the release of Ruby 3.4.0. Ruby 3.4 adds `it` block parameter reference, changes Prism as default parser, adds Happy Eyeballs Version 2 support to socket library, improves YJIT, adds Modular GC, and so on.

`it` is introduced
------------------

`it` is added to reference a block parameter with no variable name. \[[Feature #18980](https://bugs.ruby-lang.org/issues/18980)\]

    ary = ["foo", "bar", "baz"]
    
    p ary.map { it.upcase } #=> ["FOO", "BAR", "BAZ"]
    

`it` very much behaves the same as `_1`. When the intention is to only use `_1` in a block, the potential for other numbered parameters such as `_2` to also appear imposes an extra cognitive load onto readers. So `it` was introduced as a handy alias. Use `it` in simple cases where `it` speaks for itself, such as in one-line blocks.

Prism is now the default parser
-------------------------------

Switch the default parser from parse.y to Prism. \[[Feature #20564](https://bugs.ruby-lang.org/issues/20564)\]

This is an internal improvement and there should be little change visible to the user. If you notice any compatibility issues, please report them to us.

To use the conventional parser, use the command-line argument `--parser=parse.y`.

The socket library now features Happy Eyeballs Version 2 (RFC 8305)
-------------------------------------------------------------------

The socket library now features [Happy Eyeballs Version 2 (RFC 8305)](https://datatracker.ietf.org/doc/html/rfc8305), the latest standardized version of a widely adopted approach for better connectivity in many programming languages, in `TCPSocket.new` (`TCPSocket.open`) and `Socket.tcp`. This improvement enables Ruby to provide efficient and reliable network connections, adapted to modern internet environments.

Until Ruby 3.3, these methods performed name resolution and connection attempts serially. With this algorithm, they now operate as follows:

1.  Performs IPv6 and IPv4 name resolution concurrently
2.  Attempt connections to the resolved IP addresses, prioritizing IPv6, with parallel attempts staggered at 250ms intervals
3.  Return the first successful connection while canceling any others

This ensures minimized connection delays, even if a specific protocol or IP address is delayed or unavailable. This feature is enabled by default, so additional configuration is not required to use it. To disable it globally, set the environment variable `RUBY_TCP_NO_FAST_FALLBACK=1` or call `Socket.tcp_fast_fallback=false`. Or to disable it on a per-method basis, use the keyword argument `fast_fallback: false`.

YJIT
----

### TL;DR

*   Better performance across most benchmarks on both x86-64 and arm64 platforms.
*   Reduced memory usage through compressed metadata and a unified memory limit.
*   Various bug fixes: YJIT is now more robust and thoroughly tested.

### New features

*   Command-line options
    *   `--yjit-mem-size` introduces a unified memory limit (default 128MiB) to track total YJIT memory usage, providing a more intuitive alternative to the old `--yjit-exec-mem-size` option.
    *   `--yjit-log` enables a compilation log to track what gets compiled.
*   Ruby API
    *   `RubyVM::YJIT.log` provides access to the tail of the compilation log at run-time.
*   YJIT stats
    *   `RubyVM::YJIT.runtime_stats` now always provides additional statistics on invalidation, inlining, and metadata encoding.

### New optimizations

*   Compressed context reduces memory needed to store YJIT metadata
*   Allocate registers for local variables and Ruby method arguments
*   When YJIT is enabled, use more Core primitives written in Ruby:
    *   `Array#each`, `Array#select`, `Array#map` rewritten in Ruby for better performance \[[Feature #20182](https://bugs.ruby-lang.org/issues/20182)\].
*   Ability to inline small/trivial methods such as:
    *   Empty methods
    *   Methods returning a constant
    *   Methods returning `self`
    *   Methods directly returning an argument
*   Specialized codegen for many more runtime methods
*   Optimize `String#getbyte`, `String#setbyte` and other string methods
*   Optimize bitwise operations to speed up low-level bit/byte manipulation
*   Support shareable constants in multi-ractor mode
*   Various other incremental optimizations

Modular GC
----------

*   Alternative garbage collector (GC) implementations can be loaded dynamically through the modular garbage collector feature. To enable this feature, configure Ruby with `--with-modular-gc` at build time. GC libraries can be loaded at runtime using the environment variable `RUBY_GC_LIBRARY`. \[[Feature #20351](https://bugs.ruby-lang.org/issues/20351)\]
    
*   Ruby’s built-in garbage collector has been split into a separate file at `gc/default/default.c` and interacts with Ruby using an API defined in `gc/gc_impl.h`. The built-in garbage collector can now also be built as a library using `make modular-gc MODULAR_GC=default` and enabled using the environment variable `RUBY_GC_LIBRARY=default`. \[[Feature #20470](https://bugs.ruby-lang.org/issues/20470)\]
    
*   An experimental GC library is provided based on [MMTk](https://www.mmtk.io/). This GC library can be built using `make modular-gc MODULAR_GC=mmtk` and enabled using the environment variable `RUBY_GC_LIBRARY=mmtk`. This requires the Rust toolchain on the build machine. \[[Feature #20860](https://bugs.ruby-lang.org/issues/20860)\]
    

Language changes
----------------

*   String literals in files without a `frozen_string_literal` comment now emit a deprecation warning when they are mutated. These warnings can be enabled with `-W:deprecated` or by setting `Warning[:deprecated] = true`. To disable this change, you can run Ruby with the `--disable-frozen-string-literal` command line argument. \[[Feature #20205](https://bugs.ruby-lang.org/issues/20205)\]
    
*   Keyword splatting `nil` when calling methods is now supported. `**nil` is treated similarly to `**{}`, passing no keywords, and not calling any conversion methods. \[[Bug #20064](https://bugs.ruby-lang.org/issues/20064)\]
    
*   Block passing is no longer allowed in index. \[[Bug #19918](https://bugs.ruby-lang.org/issues/19918)\]
    
*   Keyword arguments are no longer allowed in index. \[[Bug #20218](https://bugs.ruby-lang.org/issues/20218)\]
    
*   The toplevel name `::Ruby` is reserved now, and the definition will be warned when `Warning[:deprecated]`. \[[Feature #20884](https://bugs.ruby-lang.org/issues/20884)\]
    

Core classes updates
--------------------

Note: We’re only listing notable updates of Core class.

*   Exception
    
    *   `Exception#set_backtrace` now accepts an array of `Thread::Backtrace::Location`. `Kernel#raise`, `Thread#raise` and `Fiber#raise` also accept this new format. \[[Feature #13557](https://bugs.ruby-lang.org/issues/13557)\]
*   GC
    
    *   `GC.config` added to allow setting configuration variables on the Garbage Collector. \[[Feature #20443](https://bugs.ruby-lang.org/issues/20443)\]
        
    *   GC configuration parameter `rgengc_allow_full_mark` introduced. When `false` GC will only mark young objects. Default is `true`. \[[Feature #20443](https://bugs.ruby-lang.org/issues/20443)\]
        
*   Ractor
    
    *   `require` in Ractor is allowed. The requiring process will be run on the main Ractor. `Ractor._require(feature)` is added to run requiring process on the main Ractor. \[[Feature #20627](https://bugs.ruby-lang.org/issues/20627)\]
        
    *   `Ractor.main?` is added. \[[Feature #20627](https://bugs.ruby-lang.org/issues/20627)\]
        
    *   `Ractor.[]` and `Ractor.[]=` are added to access the ractor local storage of the current Ractor. \[[Feature #20715](https://bugs.ruby-lang.org/issues/20715)\]
        
    *   `Ractor.store_if_absent(key){ init }` is added to initialize ractor local variables in thread-safty. \[[Feature #20875](https://bugs.ruby-lang.org/issues/20875)\]
        
*   Range
    
    *   `Range#size` now raises `TypeError` if the range is not iterable. \[[Misc #18984](https://bugs.ruby-lang.org/issues/18984)\]

Standard Library updates
------------------------

Note: We’re only listing notable updates of Standard libraries.

*   RubyGems
    *   Add `--attestation` option to gem push. It enabled to store signature to [sigstore.dev](https://www.sigstore.dev)
*   Bundler
    *   Add a `lockfile_checksums` configuration to include checksums in fresh lockfiles
    *   Add bundle lock `--add-checksums` to add checksums to an existing lockfile
*   JSON
    
    *   Performance improvements of `JSON.parse` about 1.5 times faster than json-2.7.x.
*   Tempfile
    
    *   The keyword argument `anonymous: true` is implemented for Tempfile.create. `Tempfile.create(anonymous: true)` removes the created temporary file immediately. So applications don’t need to remove the file. \[[Feature #20497](https://bugs.ruby-lang.org/issues/20497)\]
*   win32/sspi.rb
    
    *   This library is now extracted from the Ruby repository to [ruby/net-http-sspi](https://github.com/ruby/net-http-sspi). \[[Feature #20775](https://bugs.ruby-lang.org/issues/20775)\]

The following bundled gems are promoted from default gems.

*   mutex\_m 0.3.0
*   getoptlong 0.2.1
*   base64 0.2.0
*   bigdecimal 3.1.8
*   observer 0.1.2
*   abbrev 0.1.2
*   resolv-replace 0.1.1
*   rinda 0.2.0
*   drb 2.2.1
*   nkf 0.2.0
*   syslog 0.2.0
*   csv 3.3.2
*   repl\_type\_completor 0.1.9

Compatibility issues
--------------------

Note: Excluding feature bug fixes.

*   Error messages and backtrace displays have been changed.
    
    *   Use a single quote instead of a backtick as a opening quote. \[[Feature #16495](https://bugs.ruby-lang.org/issues/16495)\]
    *   Display a class name before a method name (only when the class has a permanent name). \[[Feature #19117](https://bugs.ruby-lang.org/issues/19117)\]
    *   `Kernel#caller`, `Thread::Backtrace::Location`’s methods, etc. are also changed accordingly.
    
        Old:
        test.rb:1:in `foo': undefined method `time' for an instance of Integer
                from test.rb:2:in `<main>'
        
        New:
        test.rb:1:in 'Object#foo': undefined method 'time' for an instance of Integer
                from test.rb:2:in '<main>'
        
    
*   Hash#inspect rendering have been changed. \[[Bug #20433](https://bugs.ruby-lang.org/issues/20433)\]
    
    *   Symbol keys are displayed using the modern symbol key syntax: `"{user: 1}"`
    *   Other keys now have spaces around `=>`: `'{"user" => 1}'`, while previously they didn’t: `'{"user"=>1}'`
*   Kernel#Float() now accepts a decimal string with decimal part omitted. \[[Feature #20705](https://bugs.ruby-lang.org/issues/20705)\]
    
        Float("1.")    #=> 1.0 (previously, an ArgumentError was raised)
        Float("1.E-1") #=> 0.1 (previously, an ArgumentError was raised)
        
    
*   String#to\_f now accepts a decimal string with decimal part omitted. Note that the result changes when an exponent is specified. \[[Feature #20705](https://bugs.ruby-lang.org/issues/20705)\]
    
        "1.".to_f    #=> 1.0
        "1.E-1".to_f #=> 0.1 (previously, 1.0 was returned)
        
    
*   Refinement#refined\_class has been removed. \[[Feature #19714](https://bugs.ruby-lang.org/issues/19714)\]

Standard library compatibility issues
-------------------------------------

*   DidYouMean
    
    *   `DidYouMean::SPELL_CHECKERS[]=` and `DidYouMean::SPELL_CHECKERS.merge!` are removed.
*   Net::HTTP
    
    *   Removed the following deprecated constants:
        
        *   `Net::HTTP::ProxyMod`
        *   `Net::NetPrivate::HTTPRequest`
        *   `Net::HTTPInformationCode`
        *   `Net::HTTPSuccessCode`
        *   `Net::HTTPRedirectionCode`
        *   `Net::HTTPRetriableCode`
        *   `Net::HTTPClientErrorCode`
        *   `Net::HTTPFatalErrorCode`
        *   `Net::HTTPServerErrorCode`
        *   `Net::HTTPResponseReceiver`
        *   `Net::HTTPResponceReceiver`
        
        These constants were deprecated from 2012.
        
*   Timeout
    
    *   Reject negative values for Timeout.timeout. \[[Bug #20795](https://bugs.ruby-lang.org/issues/20795)\]
*   URI
    
    *   Switched default parser to RFC 3986 compliant from RFC 2396 compliant. \[[Bug #19266](https://bugs.ruby-lang.org/issues/19266)\]

C API updates
-------------

*   `rb_newobj` and `rb_newobj_of` (and corresponding macros `RB_NEWOBJ`, `RB_NEWOBJ_OF`, `NEWOBJ`, `NEWOBJ_OF`) have been removed. \[[Feature #20265](https://bugs.ruby-lang.org/issues/20265)\]
*   Removed deprecated function `rb_gc_force_recycle`. \[[Feature #18290](https://bugs.ruby-lang.org/issues/18290)\]

Miscellaneous changes
---------------------

*   Passing a block to a method which doesn’t use the passed block will show a warning on verbose mode (`-w`). \[[Feature #15554](https://bugs.ruby-lang.org/issues/15554)\]
    
*   Redefining some core methods that are specially optimized by the interpreter and JIT like `String.freeze` or `Integer#+` now emits a performance class warning (`-W:performance` or `Warning[:performance] = true`). \[[Feature #20429](https://bugs.ruby-lang.org/issues/20429)\]
    

See [NEWS](https://docs.ruby-lang.org/en/3.4/NEWS_md.html) or [commit logs](https://github.com/ruby/ruby/compare/v3_3_0...v3_4_0) for more details.

With those changes, [4942 files changed, 202244 insertions(+), 255528 deletions(-)](https://github.com/ruby/ruby/compare/v3_3_0...v3_4_0#file_bucket) since Ruby 3.3.0!

Merry Christmas, Happy Holidays, and enjoy programming with Ruby 3.4!

Download
--------

*   [https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.0.tar.gz](https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.0.tar.gz)
    
        SIZE: 23153022
        SHA1: 8ccb561848a7c460ae08e1a120a47c4a88a79335
        SHA256: 068c8523442174bd3400e786f4a6952352c82b1b9f6210fd17fb4823086d3379
        SHA512: bc70ecba27d1cdea00879f03487cad137a7d9ab2ad376cfb7a65780ad14da637fa3944eeeede2c04ab31eeafb970c64ccfeeb854c99c1093937ecc1165731562
        
    
*   [https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.0.tar.xz](https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.0.tar.xz)
    
        SIZE: 17215572
        SHA1: eb25447cc404e8d2e177c62550d0224ebd410e68
        SHA256: 0081930db22121eb997207f56c0e22720d4f5d21264b5907693f516c32f233ca
        SHA512: 776a2cf3e9ccc77c27500240f168aa3e996b0c7c1ee1ef5a7afc291a06c118444016fde38b5b139c0b800496b8eb1b5456562d833f0edc0658917164763b1af7
        
    
*   [https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.0.zip](https://cache.ruby-lang.org/pub/ruby/3.4/ruby-3.4.0.zip)
    
        SIZE: 28310193
        SHA1: 26254ca5d3decc28a4e5faec255995265e5270b5
        SHA256: c120228038af04554f6363e716b0a32cbf53cf63c6adf9f2c22a24f43dc8b555
        SHA512: 4d535ed10db76a6aa74f8a025df319deb28483a7a781c24045906ee7663f1cff9d9f9e71dbc993c9e050113a34b37c7fa2143c355a0a6e1e1029bf2c92213ecc
        
    

What is Ruby
------------

Ruby was first developed by Matz (Yukihiro Matsumoto) in 1993, and is now developed as Open Source. It runs on multiple platforms and is used all over the world especially for web development.

[Recent News](/en/news/)
------------------------

### [Ruby 4.0.0 Released](/en/news/2025/12/25/ruby-4-0-0-released/)

We are pleased to announce the release of Ruby 4.0.0. Ruby 4.0 introduces “Ruby Box” and “ZJIT”, and adds many improvements.

Posted by **naruse** on 25 Dec 2025

### [A New Look for Ruby's Documentation](/en/news/2025/12/23/new-look-for-ruby-documentation/)

Following the ruby-lang.org redesign, we have more news to celebrate Ruby’s 30th anniversary: docs.ruby-lang.org has a completely new look with Aliki—RDoc’s new default theme.

Posted by **Stan Lo** on 23 Dec 2025

### [Redesign our Site Identity](/en/news/2025/12/22/redesign-site-identity/)

We are excited to announce a comprehensive redesign of our site. The design for this update was created by Taeko Akatsuka.

Posted by **Hiroshi SHIBATA** on 22 Dec 2025

### [Ruby 4.0.0 preview3 Released](/en/news/2025/12/18/ruby-4-0-0-preview3-released/)

We are pleased to announce the release of Ruby 4.0.0-preview3. Ruby 4.0 introduces Ruby::Box and “ZJIT”, and adds many improvements.

Posted by **naruse** on 18 Dec 2025

[More News...](/en/news/)

Table of Contents

### Table of Contents

![Happy Hacking!](/images/footer/happy-hacking.svg) ![](/images/home/why_ruby/line.svg)

[Security](/en/security/) [About This Website](/en/about/website/) [About the Logo](/en/about/logo/) [News RSS](/en/feeds/news.rss) [Ruby License](/en/about/license.txt)

[This website](/en/about/website/) is proudly maintained by members of the Ruby community.