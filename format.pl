#!/usr/bin/env perl
use strict;
use warnings;

use Cwd qw(abs_path getcwd);
use File::Basename qw(dirname);
use File::Find qw(find);
use File::Spec;
use Getopt::Long qw(GetOptions);

my $script_dir = dirname(abs_path($0));
my $root       = $script_dir;
my $style_dir  = getcwd();
my $clang_fmt  = 'clang-format';
my $dry_run    = 0;
my $verbose    = 0;
my $help       = 0;

GetOptions(
	'root=s'       => \$root,
	'style-dir=s'  => \$style_dir,
	'clang-format=s' => \$clang_fmt,
	'dry-run'      => \$dry_run,
	'verbose'      => \$verbose,
	'help|h'       => \$help,
) or usage(1);

usage(0) if $help;

$root      = abs_path($root)      or die "Unable to resolve --root path: $root\n";
$style_dir = abs_path($style_dir) or die "Unable to resolve --style-dir path: $style_dir\n";

my $style_file = File::Spec->catfile($style_dir, '.clang-format');
if (!-f $style_file) {
	die "No .clang-format found in --style-dir ($style_dir).\n"
	  . "Tip: run with --style-dir pointing to the folder that has .clang-format.\n";
}

my %glsl_ext = map { $_ => 1 } qw(
	glsl frag vert geom tesc tese comp
	fs vs gs cs vsh fsh gsh csh
);

my @shader_files;
find(
	{
		wanted => sub {
			return if -d $_;

			my $name = $_;
			if ($name =~ /\.([A-Za-z0-9]+)$/) {
				my $ext = lc $1;
				if ($glsl_ext{$ext}) {
					push @shader_files, $File::Find::name;
				}
			}
		},
		no_chdir => 1,
	},
	$root
);

if (!@shader_files) {
	print "No GLSL files found under: $root\n";
	exit 0;
}

@shader_files = sort @shader_files;

my $formatted = 0;
for my $file (@shader_files) {
	my @cmd = (
		$clang_fmt,
		'-i',
		"-style=file:$style_file",
		$file,
	);

	if ($dry_run) {
		print "[dry-run] @cmd\n";
		$formatted++;
		next;
	}

	print "Formatting $file\n" if $verbose;
	my $rc = system(@cmd);
	if ($rc != 0) {
		my $exit_code = $rc >> 8;
		die "clang-format failed for: $file (exit code $exit_code)\n";
	}
	$formatted++;
}

print "Formatted $formatted GLSL file(s) under $root using $style_file\n";

sub usage {
	my ($exit_code) = @_;
	print <<'USAGE';
Usage: perl format.pl [options]

Formats GLSL shader files recursively with clang-format.
Only GLSL-like extensions are processed; C++ files are ignored.

Options:
  --root PATH           Root directory to scan (default: script directory)
  --style-dir PATH      Directory containing .clang-format (default: current directory)
  --clang-format PATH   clang-format executable (default: clang-format)
  --dry-run             Print commands without modifying files
  --verbose             Print each file as it is formatted
  --help, -h            Show this help
USAGE
	exit($exit_code);
}
