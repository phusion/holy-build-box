# Security hardening binaries

Holy Build Box makes it easy to compile your application with special security hardening features:

 * Protection against stack overflows and stack smashing
 * Extra bounds checking in common functions
 * Load time address randomization
 * Read-only global offset table

This is done through the `deadstrip_hardened_pie` library variant. See [tutorial 5](TUTORIAL-5-LIBRARY-VARIANTS) for more information about library variants. When this variant is activated, Holy Build Box will set the necessary security hardening flags in `$CLFAGS`, `$CXXFLAGS` and `$LDFLAGS`.

## The `hardening-check` tool

Holy Build Box also includes the `hardening-check` tool. Originally from Debian, this tool checks whether an executable is compiled with all the recommended security hardening flags.

Inside a Holy Build Box container, use it as `hardening-check <FILENAME>`.

If you want to use it outside a Holy Build Box container, use it as follows:

    docker run -t -i --rm \
      -v /path-to-your-binary:/exe:ro \
      phusion/holy-build-box-64:latest \
      hardening-check /exe

Replace `/path-to-your-binary` with the actual path.

See also [the hardening-check man page](http://manpages.ubuntu.com/manpages/trusty/man1/hardening-check.1.html).
