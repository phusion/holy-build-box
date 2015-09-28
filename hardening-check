#!/usr/bin/perl
# Report the hardening characterists of a set of binaries.
# Copyright (C) 2009-2013 Kees Cook <kees@debian.org>
# License: GPLv2 or newer
use strict;
use warnings;
use Getopt::Long qw(:config no_ignore_case bundling);
use Pod::Usage;
use IPC::Open3;
use Symbol qw(gensym);
use Term::ANSIColor;

my $skip_pie = 0;
my $skip_stackprotector = 0;
my $skip_fortify = 0;
my $skip_relro = 0;
my $skip_bindnow = 0;
my $report_functions = 0;
my $find_libc_functions = 0;
my $color = 0;
my $lintian = 0;
my $verbose = 0;
my $debug = 0;
my $quiet = 0;
my $help = 0;
my $man = 0;

GetOptions(
        "nopie|p+" => \$skip_pie,
        "nostackprotector|s+" => \$skip_stackprotector,
        "nofortify|f+" => \$skip_fortify,
        "norelro|r+" => \$skip_relro,
        "nobindnow|b+" => \$skip_bindnow,
        "report-functions|R!" => \$report_functions,
        "find-libc-functions|F!" => \$find_libc_functions,
        "color|c!" => \$color,
        "lintian|l!" => \$lintian,
        "verbose|v!" => \$verbose,
        "debug!" => \$debug,
        "quiet|q!" => \$quiet,
        "help|h|?" => \$help,
        "man|H" => \$man,
    ) or pod2usage(2);
pod2usage(1) if $help;
pod2usage(-exitstatus => 0, -verbose => 2, -noperldoc => 1) if $man;

my $overall = 0;
my $rc = 0;
my $report = "";
my @tags;
my %libc = (
    'asprintf' => 1,
    'confstr' => 1,
    'dprintf' => 1,
    'fdelt' => 1,
    'fgets' => 1,
    'fgets_unlocked' => 1,
    'fgetws' => 1,
    'fgetws_unlocked' => 1,
    'fprintf' => 1,
    'fread' => 1,
    'fread_unlocked' => 1,
    'fwprintf' => 1,
    'getcwd' => 1,
    'getdomainname' => 1,
    'getgroups' => 1,
    'gethostname' => 1,
    'getlogin_r' => 1,
    'gets' => 1,
    'getwd' => 1,
    'longjmp' => 1,
    'mbsnrtowcs' => 1,
    'mbsrtowcs' => 1,
    'mbstowcs' => 1,
    'memcpy' => 1,
    'memmove' => 1,
    'mempcpy' => 1,
    'memset' => 1,
    'obstack_printf' => 1,
    'obstack_vprintf' => 1,
    'poll' => 1,
    'ppoll' => 1,
    'pread64' => 1,
    'pread' => 1,
    'printf' => 1,
    'ptsname_r' => 1,
    'read' => 1,
    'readlink' => 1,
    'readlinkat' => 1,
    'realpath' => 1,
    'recv' => 1,
    'recvfrom' => 1,
    'snprintf' => 1,
    'sprintf' => 1,
    'stpcpy' => 1,
    'stpncpy' => 1,
    'strcat' => 1,
    'strcpy' => 1,
    'strncat' => 1,
    'strncpy' => 1,
    'swprintf' => 1,
    'syslog' => 1,
    'ttyname_r' => 1,
    'vasprintf' => 1,
    'vdprintf' => 1,
    'vfprintf' => 1,
    'vfwprintf' => 1,
    'vprintf' => 1,
    'vsnprintf' => 1,
    'vsprintf' => 1,
    'vswprintf' => 1,
    'vsyslog' => 1,
    'vwprintf' => 1,
    'wcpcpy' => 1,
    'wcpncpy' => 1,
    'wcrtomb' => 1,
    'wcscat' => 1,
    'wcscpy' => 1,
    'wcsncat' => 1,
    'wcsncpy' => 1,
    'wcsnrtombs' => 1,
    'wcsrtombs' => 1,
    'wcstombs' => 1,
    'wctomb' => 1,
    'wmemcpy' => 1,
    'wmemmove' => 1,
    'wmempcpy' => 1,
    'wmemset' => 1,
    'wprintf' => 1,
);

# Report a good test.
sub good {
    my ($name, $msg_color, $msg) = @_;
    $msg_color = colored($msg_color, 'green') if $color;
    if (defined $msg) {
        $msg_color .= $msg;
    }
    good_msg("$name: $msg_color");
}
sub good_msg($) {
    my ($msg) = @_;
    if ($quiet == 0) {
        $report .= "\n$msg";
    }
}

sub unknown {
    my ($name, $msg) = @_;
    $msg = colored($msg, 'yellow') if $color;
    good_msg("$name: $msg");
}

# Report a failed test, possibly ignoring it.
sub bad($$$$$) {
    my ($name, $file, $long_name, $msg, $ignore) = @_;

    $msg = colored($msg, 'red') if $color;

    $msg = "$long_name: " . $msg;
    if ($ignore) {
        $msg .= " (ignored)";
    }
    else {
        $rc = 1;
        if ($lintian) {
            push(@tags, "$name:$file");
        }
    }
    $report .= "\n$msg";
}

# Safely run list-based command line and return stdout.
sub output(@) {
    my (@cmd) = @_;
    my ($pid, $stdout, $stderr);
    if ($debug) {
        print join(" ", @cmd),"\n";
    }
    $stdout = gensym;
    $stderr = gensym;
    $pid = open3(gensym, $stdout, $stderr, @cmd);
    my $collect = "";
    while ( <$stdout> ) {
        $collect .= $_;
    }
    waitpid($pid, 0);
    my $rc = $?;
    if ($rc != 0) {
        while ( <$stderr> ) {
            print STDERR;
        }
        return "";
    }
    return $collect;
}

# Find the libc used in this executable, if any.
sub find_libc($) {
    my ($file) = @_;
    my $ldd = output("ldd", $file);
    $ldd =~ /^\s*libc\.so\.\S+\s+\S+\s+(\S+)/m;
    return $1 || "";
}

sub find_functions($$) {
    my ($file, $undefined) = @_;
    my (%funcs);

    # Catch "NOTYPE" for object archives.
    my $func_regex = " (I?FUNC|NOTYPE) ";

    my $relocs = output("readelf", "-sW", $file);
    for my $line (split("\n", $relocs)) {
        next if ($line !~ /$func_regex/);
        next if ($undefined && $line !~ /$func_regex.* UND /);

        $line =~ s/ \([0-9]+\)$//;
        $line =~ s/.* //;
        $line =~ s/@.*//;
        $funcs{$line} = 1;
    }

    return \%funcs;
}


$ENV{'LANG'} = "C";

if ($find_libc_functions) {
    pod2usage(1) if (!defined($ARGV[0]));
    my $libc_path = find_libc($ARGV[0]);

    my $funcs = find_functions($libc_path, 0);
    for my $func (sort(keys(%{$funcs}))) {
        if ($func =~ /^__(\S+)_chk$/) {
            print "    '$1' => 1,\n";
        }
    }
    exit(0);
}
die "List of libc functions not defined!" if (scalar(keys %libc) < 1);

my $name;
foreach my $file (@ARGV) {
    $rc = 0;
    my $elf = 1;

    $report = "$file:";
    @tags = ();

    # Get program headers.
    my $PROG_REPORT=output("readelf", "-lW", $file);
    if (length($PROG_REPORT) == 0) {
        $overall = 1;
        next;
    }

    # Get ELF headers.
    my $DYN_REPORT=output("readelf", "-dW", $file);

    # Get list of all symbols needing external resolution.
    my $functions = find_functions($file, 1);

    # PIE
    # First, verify this is an executable, not a library. This seems to be
    # best seen by checking for the PHDR program header.
    $name = " Position Independent Executable";
    $PROG_REPORT =~ /^Elf file type is (\S+)/m;
    my $elftype = $1 || "";
    if ($elftype eq "DYN") {
        if ($PROG_REPORT =~ /^ *\bPHDR\b/m) {
            # Executable, DYN ELF type.
            good($name, "yes");
        }
        else {
            # Shared library, DYN ELF type.
            good($name, "no, regular shared library (ignored)");
        }
    }
    elsif ($elftype eq "EXEC") {
        # Executable, EXEC ELF type.
        bad("no-pie", $file, $name,
            "no, normal executable!", $skip_pie);
    }
    else {
        $elf = 0;
        # Is this an ar file with objects?
        open(AR, "<$file");
        my $header = <AR>;
        close(AR);
        if ($header eq "!<arch>\n") {
            good($name, "no, object archive (ignored)");
        }
        else {
            # ELF type is neither DYN nor EXEC.
            bad("unknown-elf", $file, $name,
                "not a known ELF type!? ($elftype)", 0);
        }
    }

    # Stack-protected
    $name = " Stack protected";
    if (defined($functions->{'__stack_chk_fail'}) ||
        (!$elf && defined($functions->{'__stack_chk_fail_local'}))) {
        good($name, "yes")
    }
    else {
        bad("no-stackprotector", $file, $name,
            "no, not found!", $skip_stackprotector);
    }

    # Fortified Source
    $name = " Fortify Source functions";
    my @unprotected;
    my @protected;
    for my $name (keys(%libc)) {
        if (defined($functions->{$name})) {
            push(@unprotected, $name);
        }
        if (defined($functions->{"__${name}_chk"})) {
            push(@protected, $name);
        }
    }
    if ($#protected > -1) {
        if ($#unprotected == -1) {
            # Certain.
            good($name, "yes");
        }
        else {
            # Vague, due to possible compile-time optimization,
            # multiple linkages, etc. Assume "yes" for now.
            good($name, "yes", " (some protected functions found)");
        }
    }
    else {
        if ($#unprotected == -1) {
            unknown($name, "unknown, no protectable libc functions used");
        }
        else {
            # Vague, since it's possible to have the compile-time
            # optimizations do away with them, or be unverifiable
            # at runtime. Assume "no" for now.
            bad("no-fortify-functions", $file, $name,
                "no, only unprotected functions found!", $skip_fortify);
        }
    }
    if ($verbose) {
        for my $name (@unprotected) {
            good_msg("\tunprotected: $name");
        }
        for my $name (@protected) {
            good_msg("\tprotected: $name");
        }
    }

    # Format
    # Unfortunately, I haven't thought of a way to test for this after
    # compilation. What it really needs is a lintian-like check that
    # reviews the build logs and looks for the warnings, or that the
    # argument is changed to use -Werror=format-security to stop the build.

    # RELRO
    $name = " Read-only relocations";
    if ($PROG_REPORT =~ /^ *\bGNU_RELRO\b/m) {
        good($name, "yes");
    } else {
        if ($elf) {
            bad("no-relro", $file, $name, "no, not found!", $skip_relro);
        } else {
            good($name, "no", ", non-ELF (ignored)");
        }
    }

    # BIND_NOW
    # This marking keeps changing:
    # 0x0000000000000018 (BIND_NOW)           
    # 0x000000006ffffffb (FLAGS)              Flags: BIND_NOW
    # 0x000000006ffffffb (FLAGS_1)            Flags: NOW

    $name = " Immediate binding";
    if ($DYN_REPORT =~ /^\s*\S+\s+\(BIND_NOW\)/m ||
        $DYN_REPORT =~ /^\s*\S+\s+\(FLAGS\).*\bBIND_NOW\b/m ||
        $DYN_REPORT =~ /^\s*\S+\s+\(FLAGS_1\).*\bNOW\b/m) {
        good($name, "yes");
    } else {
        if ($elf) {
            bad("no-bindnow", $file, $name, "no, not found!", $skip_bindnow);
        } else {
            good($name, "no", ", non-ELF (ignored)");
        }
    }

    if (!$lintian && (!$quiet || $rc != 0)) {
        print $report,"\n";
    }

    if ($report_functions) {
        for my $name (keys(%{$functions})) {
            print $name,"\n";
        }
    }

    if (!$lintian && $rc) {
        $overall = $rc;
    }

    if ($lintian) {
        for my $tag (@tags) {
            print $tag, "\n";
        }
    }
}

exit($overall);

__END__

=pod

=head1 NAME

hardening-check - check binaries for security hardening features

=head1 SYNOPSIS

hardening-check [options] [ELF ...]

Examine a given set of ELF binaries and check for several security hardening
features, failing if they are not all found.

=head1 DESCRIPTION

This utility checks a given list of ELF binaries for several security
hardening features that can be compiled into an executable. These
features are:

=over 8

=item B<Position Independent Executable>

This indicates that the executable was built in such a way (PIE) that
the "text" section of the program can be relocated in memory. To take
full advantage of this feature, the executing kernel must support text
Address Space Layout Randomization (ASLR).

=item B<Stack Protected>

This indicates that there is evidence that the ELF was compiled with the
L<gcc(1)> option B<-fstack-protector> (e.g. uses B<__stack_chk_fail>). The
program will be resistant to having its stack overflowed.

When an executable was built without any character arrays being allocated
on the stack, this check will lead to false alarms (since there is no
use of B<__stack_chk_fail>), even though it was compiled with the correct
options.

=item B<Fortify Source functions>

This indicates that the executable was compiled with
B<-D_FORTIFY_SOURCE=2> and B<-O1> or higher. This causes certain unsafe
glibc functions with their safer counterparts (e.g. B<strncpy> instead
of B<strcpy>), or replaces calls that are verifiable at runtime with the
runtime-check version (e.g. B<__memcpy_chk> insteade of B<memcpy>).

When an executable was built such that the fortified versions of the glibc
functions are not useful (e.g. use is verified as safe at compile time, or
use cannot be verified at runtime), this check will lead to false alarms.
In an effort to mitigate this, the check will pass if any fortified function
is found, and will fail if only unfortified functions are found. Uncheckable
conditions also pass (e.g. no functions that could be fortified are found, or
not linked against glibc).

=item B<Read-only relocations>

This indicates that the executable was build with B<-Wl,-z,relro> to
have ELF markings (RELRO) that ask the runtime linker to mark any
regions of the relocation table as "read-only" if they were resolved
before execution begins. This reduces the possible areas of memory in
a program that can be used by an attacker that performs a successful
memory corruption exploit.

=item B<Immediate binding>

This indicates that the executable was built with B<-Wl,-z,now> to have
ELF markings (BIND_NOW) that ask the runtime linker to resolve all
relocations before starting program execution. When combined with RELRO
above, this further reduces the regions of memory available to memory
corruption attacks.

=back

=head1 OPTIONS

=over 8

=item B<--nopie>, B<-p>

No not require that the checked binaries be built as PIE.

=item B<--nostackprotector>, B<-s>

No not require that the checked binaries be built with the stack protector.

=item B<--nofortify>, B<-f>

No not require that the checked binaries be built with Fority Source.

=item B<--norelro>, B<-r>

No not require that the checked binaries be built with RELRO.

=item B<--nobindnow>, B<-b>

No not require that the checked binaries be built with BIND_NOW.

=item B<--quiet>, B<-q>

Only report failures.

=item B<--verbose>, B<-v>

Report verbosely on failures.

=item B<--report-functions>, B<-R>

After the report, display all external functions needed by the ELF.

=item B<--find-libc-functions>, B<-F>

Instead of the regular report, locate the libc for the first ELF on the
command line and report all the known "fortified" functions exported by
libc.

=item B<--color>, B<-c>

Enable colorized status output.

=item B<--lintian>, B<-l>

Switch reporting to lintian-check-parsable output.

=item B<--debug>

Report some debugging during processing.

=item B<--help>, B<-h>, B<-?>

Print a brief help message and exit.

=item B<--man>, B<-H>

Print the manual page and exit.

=back

=head1 RETURN VALUE

When all checked binaries have all checkable hardening features detected,
this program will finish with an exit code of 0. If any check fails, the
exit code with be 1. Individual checks can be disabled via command line
options.

=head1 AUTHOR

Kees Cook <kees@debian.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2013 Kees Cook <kees@debian.org>.

This program is free software; you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the
Free Software Foundation; version 2 or later.

=head1 SEE ALSO

L<gcc(1)>, L<hardening-wrapper(1)>

=cut
