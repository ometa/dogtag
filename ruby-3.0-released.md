 Ruby 2.7.0 Released            

[

Ruby
====

A Programmer's Best Friend
--------------------------

](/en/)

[Home](/en/) [Downloads](/en/downloads/) [Documentation](/en/documentation/) [Libraries](/en/libraries/) [Community](/en/community/) [News](/en/news/) [Security](/en/security/) [About Ruby](/en/about/) [Menu](#)

  

Ruby 2.7.0 Released
===================

Posted by naruse on 25 Dec 2019

We are pleased to announce the release of Ruby 2.7.0.

It introduces a number of new features and performance improvements, most notably:

*   Pattern Matching
*   REPL improvement
*   Compaction GC
*   Separation of positional and keyword arguments

Pattern Matching \[Experimental\]
---------------------------------

Pattern matching, a widely used feature in functional programming languages, is introduced as an experimental feature. [\[Feature #14912\]](https://bugs.ruby-lang.org/issues/14912)

It can traverse a given object and assign its value if it matches a pattern.

    require "json"
    
    json = <<END
    {
      "name": "Alice",
      "age": 30,
      "children": [{ "name": "Bob", "age": 2 }]
    }
    END
    
    case JSON.parse(json, symbolize_names: true)
    in {name: "Alice", children: [{name: "Bob", age: age}]}
      p age #=> 2
    end
    

For more details, please see [Pattern matching - New feature in Ruby 2.7](https://speakerdeck.com/k_tsj/pattern-matching-new-feature-in-ruby-2-dot-7).

REPL improvement
----------------

`irb`, the bundled interactive environment (REPL; Read-Eval-Print-Loop), now supports multi-line editing. It is powered by `reline`, a `readline`\-compatible library implemented in pure Ruby. It also provides rdoc integration. In `irb` you can display the reference for a given class, module, or method. [\[Feature #14683\]](https://bugs.ruby-lang.org/issues/14683), [\[Feature #14787\]](https://bugs.ruby-lang.org/issues/14787), [\[Feature #14918\]](https://bugs.ruby-lang.org/issues/14918)

Besides, source lines shown by `Binding#irb` and inspect results for core-class objects are now colorized.

Compaction GC
-------------

This release introduces Compaction GC which can defragment a fragmented memory space.

Some multi-threaded Ruby programs may cause memory fragmentation, leading to high memory usage and degraded speed.

The `GC.compact` method is introduced for compacting the heap. This function compacts live objects in the heap so that fewer pages may be used, and the heap may be more CoW (copy-on-write) friendly. [\[Feature #15626\]](https://bugs.ruby-lang.org/issues/15626)

Separation of positional and keyword arguments
----------------------------------------------

Automatic conversion of keyword arguments and positional arguments is deprecated, and conversion will be removed in Ruby 3. [\[Feature #14183\]](https://bugs.ruby-lang.org/issues/14183)

See the article “[Separation of positional and keyword arguments in Ruby 3.0](https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/)” in detail. Only the changes are as follows.

*   When a method call passes a Hash at the last argument, and when it passes no keywords, and when the called method accepts keywords, a warning is emitted. To continue treating the hash as keywords, add a double splat operator to avoid the warning and ensure correct behavior in Ruby 3.
    
        def foo(key: 42); end; foo({key: 42})   # warned
        def foo(**kw);    end; foo({key: 42})   # warned
        def foo(key: 42); end; foo(**{key: 42}) # OK
        def foo(**kw);    end; foo(**{key: 42}) # OK
        
    
*   When a method call passes keywords to a method that accepts keywords, but it does not pass enough required positional arguments, the keywords are treated as a final required positional argument, and a warning is emitted. Pass the argument as a hash instead of keywords to avoid the warning and ensure correct behavior in Ruby 3.
    
        def foo(h, **kw); end; foo(key: 42)      # warned
        def foo(h, key: 42); end; foo(key: 42)   # warned
        def foo(h, **kw); end; foo({key: 42})    # OK
        def foo(h, key: 42); end; foo({key: 42}) # OK
        
    
*   When a method accepts specific keywords but not a keyword splat, and a hash or keywords splat is passed to the method that includes both Symbol and non-Symbol keys, the hash will continue to be split, and a warning will be emitted. You will need to update the calling code to pass separate hashes to ensure correct behavior in Ruby 3.
    
        def foo(h={}, key: 42); end; foo("key" => 43, key: 42)   # warned
        def foo(h={}, key: 42); end; foo({"key" => 43, key: 42}) # warned
        def foo(h={}, key: 42); end; foo({"key" => 43}, key: 42) # OK
        
    
*   If a method does not accept keywords, and is called with keywords, the keywords are still treated as a positional hash, with no warning. This behavior will continue to work in Ruby 3.
    
        def foo(opt={});  end; foo( key: 42 )   # OK
        
    
*   Non-symbols are allowed as keyword argument keys if the method accepts arbitrary keywords. [\[Feature #14183\]](https://bugs.ruby-lang.org/issues/14183)
    
        def foo(**kw); p kw; end; foo("str" => 1) #=> {"str"=>1}
        
    
*   `**nil` is allowed in method definitions to explicitly mark that the method accepts no keywords. Calling such a method with keywords will result in an ArgumentError. [\[Feature #14183\]](https://bugs.ruby-lang.org/issues/14183)
    
        def foo(h, **nil); end; foo(key: 1)       # ArgumentError
        def foo(h, **nil); end; foo(**{key: 1})   # ArgumentError
        def foo(h, **nil); end; foo("str" => 1)   # ArgumentError
        def foo(h, **nil); end; foo({key: 1})     # OK
        def foo(h, **nil); end; foo({"str" => 1}) # OK
        
    
*   Passing an empty keyword splat to a method that does not accept keywords no longer passes an empty hash, unless the empty hash is necessary for a required parameter, in which case a warning will be emitted. Remove the double splat to continue passing a positional hash. [\[Feature #14183\]](https://bugs.ruby-lang.org/issues/14183)
    
        h = {}; def foo(*a) a end; foo(**h) # []
        h = {}; def foo(a) a end; foo(**h)  # {} and warning
        h = {}; def foo(*a) a end; foo(h)   # [{}]
        h = {}; def foo(a) a end; foo(h)    # {}
        
    

If you want to disable the deprecation warnings, please use a command-line argument `-W:no-deprecated` or add `Warning[:deprecated] = false` to your code.

Other Notable New Features
--------------------------

*   Numbered parameters as default block parameters are introduced. [\[Feature #4475\]](https://bugs.ruby-lang.org/issues/4475)
    
*   A beginless range is experimentally introduced. It might not be as useful as an endless range, but would be good for DSL purposes. [\[Feature #14799\]](https://bugs.ruby-lang.org/issues/14799)
    
        ary[..3]  # identical to ary[0..3]
        rel.where(sales: ..100)
        
    
*   `Enumerable#tally` is added. It counts the occurrence of each element.
    
        ["a", "b", "c", "b"].tally
        #=> {"a"=>1, "b"=>2, "c"=>1}
        
    
*   Calling a private method with a literal `self` as the receiver is now allowed. [\[Feature #11297\]](https://bugs.ruby-lang.org/issues/11297), [\[Feature #16123\]](https://bugs.ruby-lang.org/issues/16123)
    
        def foo
        end
        private :foo
        self.foo
        
    
*   `Enumerator::Lazy#eager` is added. It generates a non-lazy enumerator from a lazy enumerator. [\[Feature #15901\]](https://bugs.ruby-lang.org/issues/15901)
    
        a = %w(foo bar baz)
        e = a.lazy.map {|x| x.upcase }.map {|x| x + "!" }.eager
        p e.class               #=> Enumerator
        p e.map {|x| x + "?" }  #=> ["FOO!?", "BAR!?", "BAZ!?"]
        
    

Performance improvements
------------------------

*   JIT \[Experimental\]
    
    *   JIT-ed code is recompiled to less-optimized code when an optimization assumption is invalidated.
        
    *   Method inlining is performed when a method is considered as pure. This optimization is still experimental and many methods are NOT considered as pure yet.
        
    *   The default value of `--jit-min-calls` is changed from 5 to 10,000.
        
    *   The default value of `--jit-max-cache` is changed from 1,000 to 100.
        
*   Fiber’s cache strategy is changed and fiber creation is speeded up. [GH-2224](https://github.com/ruby/ruby/pull/2224)
    
*   `Module#name`, `true.to_s`, `false.to_s`, and `nil.to_s` now always return a frozen String. The returned String is always the same for a given object. \[Experimental\] [\[Feature #16150\]](https://bugs.ruby-lang.org/issues/16150)
    
*   The performance of `CGI.escapeHTML` is improved. [GH-2226](https://github.com/ruby/ruby/pull/2226)
    
*   The performance of Monitor and MonitorMixin is improved. [\[Feature #16255\]](https://bugs.ruby-lang.org/issues/16255)
    
*   Per-call-site method cache, which has been there since around 1.9, was improved: cache hit rate raised from 89% to 94%. See [GH-2583](https://github.com/ruby/ruby/pull/2583)
    
*   RubyVM::InstructionSequence#to\_binary method generates compiled binary. The binary size is reduced. \[Feature #16163\]
    

Other notable changes since 2.6
-------------------------------

*   Some standard libraries are updated.
    *   Bundler 2.1.2 ([Release note](https://github.com/bundler/bundler/releases/tag/v2.1.2))
    *   RubyGems 3.1.2
        *   ([Release note for 3.1.0](https://github.com/rubygems/rubygems/releases/tag/v3.1.0))
        *   ([Release note for 3.1.1](https://github.com/rubygems/rubygems/releases/tag/v3.1.1))
        *   ([Release note for 3.1.2](https://github.com/rubygems/rubygems/releases/tag/v3.1.2))
    *   Racc 1.4.15
    *   CSV 3.1.2 ([NEWS](https://github.com/ruby/csv/blob/v3.1.2/NEWS.md))
    *   REXML 3.2.3 ([NEWS](https://github.com/ruby/rexml/blob/v3.2.3/NEWS.md))
    *   RSS 0.2.8 ([NEWS](https://github.com/ruby/rss/blob/v0.2.8/NEWS.md))
    *   StringScanner 1.0.3
    *   Some other libraries that have no original version are also updated.
*   The following libraries are no longer bundled gems. Install corresponding gems to use these features.
    *   CMath (cmath gem)
    *   Scanf (scanf gem)
    *   Shell (shell gem)
    *   Synchronizer (sync gem)
    *   ThreadsWait (thwait gem)
    *   E2MM (e2mmap gem)
*   `profile.rb` was removed from standard library.
    
*   Promote stdlib to default gems
    *   The following default gems were published on rubygems.org
        *   benchmark
        *   cgi
        *   delegate
        *   getoptlong
        *   net-pop
        *   net-smtp
        *   open3
        *   pstore
        *   singleton
    *   The following default gems were only promoted at ruby-core, but not yet published on rubygems.org.
        *   monitor
        *   observer
        *   timeout
        *   tracer
        *   uri
        *   yaml
*   `Proc.new` and `proc` with no block in a method called with a block is warned now.
    
*   `lambda` with no block in a method called with a block raises an exception.
    
*   Update Unicode version and Emoji version from 11.0.0 to 12.0.0. [\[Feature #15321\]](https://bugs.ruby-lang.org/issues/15321)
    
*   Update Unicode version to 12.1.0, adding support for U+32FF SQUARE ERA NAME REIWA. [\[Feature #15195\]](https://bugs.ruby-lang.org/issues/15195)
    
*   `Date.jisx0301`, `Date#jisx0301`, and `Date.parse` support the new Japanese era. [\[Feature #15742\]](https://bugs.ruby-lang.org/issues/15742)
    
*   Require compilers to support C99. [\[Misc #15347\]](https://bugs.ruby-lang.org/issues/15347)
    *   Details of our dialect: [https://bugs.ruby-lang.org/projects/ruby-master/wiki/C99](https://bugs.ruby-lang.org/projects/ruby-master/wiki/C99)

See [NEWS](https://github.com/ruby/ruby/blob/v2_7_0/NEWS) or [commit logs](https://github.com/ruby/ruby/compare/v2_6_0...v2_7_0) for more details.

With those changes, [4190 files changed, 227498 insertions(+), 99979 deletions(-)](https://github.com/ruby/ruby/compare/v2_6_0...v2_7_0) since Ruby 2.6.0!

Merry Christmas, Happy Holidays, and enjoy programming with Ruby 2.7!

Download
--------

*   [https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.0.tar.bz2](https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.0.tar.bz2)
    
        SIZE: 14703381
        SHA1: b54f4633174dbc55db77d9fd6d0ef90cc35503af
        SHA256: 7aa247a19622a803bdd29fdb28108de9798abe841254fe8ea82c31d125c6ab26
        SHA512: 8b8dd0ceba65bdde53b7c59e6a84bc6bf634c676bfeb2ff0b3604c362c663b465397f31ff6c936441b3daabb78fb7a619be5569480c95f113dd0453488761ce7
        
    
*   [https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.0.tar.gz](https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.0.tar.gz)
    
        SIZE: 16799684
        SHA1: 6f4e99b5556010cb27e236873cb8c09eb8317cd5
        SHA256: 8c99aa93b5e2f1bc8437d1bbbefd27b13e7694025331f77245d0c068ef1f8cbe
        SHA512: 973fc29b7c19e96c5299817d00fbdd6176319468abfca61c12b5e177b0fb0d31174a5a5525985122a7a356091a709f41b332454094940362322d1f42b77c9927
        
    
*   [https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.0.tar.xz](https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.0.tar.xz)
    
        SIZE: 11990900
        SHA1: 943c767cec037529b8e2d3cc14fc880cad5bad8d
        SHA256: 27d350a52a02b53034ca0794efe518667d558f152656c2baaf08f3d0c8b02343
        SHA512: dd5690c631bf3a2b76cdc06902bcd76a89713a045e136debab9b8a81ff8c433bbb254aa09e4014ca1cf85a69ff4bcb13de11da5e40c224e7268be43ef2194af7
        
    
*   [https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.0.zip](https://cache.ruby-lang.org/pub/ruby/2.7/ruby-2.7.0.zip)
    
        SIZE: 20571744
        SHA1: fbebdd3a2a641f9a81f7d8db5abd926acea27e80
        SHA256: 8bf2050fa1fc76882f878fd526e4184dc54bd402e385efa80ef5fd3b810522e0
        SHA512: 5060f2dd3bfd271ef255b17589d6d014260d7ec2d97b48112b717ee01c62fe125c3fe04f813e02d607cea3f0a2a812b14eb3a28d06c2551354dfeff5f4c3dd6b
        
    

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