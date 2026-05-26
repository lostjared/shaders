#!/usr/bin/env perl

use strict;
use warnings;

use File::Copy qw(copy);
use File::Find qw(find);
use File::Path qw(make_path);
use File::Spec;
use File::Basename qw(basename);
use Getopt::Long qw(GetOptions);

my $default_src = '~/gpu/acidcam-gpu/shaders';
my $default_dst = '~/gpu/shaders_repo/shaders';

my $src     = $default_src;
my $dst     = $default_dst;
my $dry_run = 0;
my $help    = 0;
my $exts    = 'glsl,frag,vert,geom,comp,tese,tesc';

GetOptions(
    'src=s'   => \$src,
    'dst=s'   => \$dst,
    'exts=s'  => \$exts,
    'dry-run' => \$dry_run,
    'help'    => \$help,
) or usage(1);

usage(0) if $help;

$src = expand_tilde($src);
$dst = expand_tilde($dst);

die "Source directory does not exist: $src\n" unless -d $src;
die "Destination directory does not exist: $dst\n" unless -d $dst;

my %dst_files;
my %allowed_ext = map { lc($_) => 1 } grep { length($_) } map { s/^\.+//r } split /\s*,\s*/, $exts;

find(
    {
        wanted => sub {
            return if -d $File::Find::name;
            return if $File::Find::name =~ m{/\.git(?:/|$)};

            my $name = basename($File::Find::name);
            return unless is_allowed_shader_file( $name, \%allowed_ext );
            $dst_files{$name} = 1;
        },
        no_chdir => 1,
    },
    $dst
);

my @to_copy;

find(
    {
        wanted => sub {
            return if -d $File::Find::name;

            my $abs_path = $File::Find::name;
            my $name     = basename($abs_path);

            return unless is_allowed_shader_file( $name, \%allowed_ext );

            return if exists $dst_files{$name};

            my $bucket   = destination_bucket($name);
            my $dst_path = File::Spec->catfile( $dst, $bucket, $name );

            push @to_copy, [ $abs_path, $dst_path ];
        },
        no_chdir => 1,
    },
    $src
);

my $copied = 0;

for my $pair (@to_copy) {
    my ( $src_path, $dst_path ) = @{$pair};
    my ( undef, $dst_dir ) = File::Spec->splitpath($dst_path);

    if ( !-d $dst_dir ) {
        if ($dry_run) {
            print "[DRY-RUN] mkdir -p $dst_dir\n";
        }
        else {
            make_path($dst_dir) or die "Failed to create directory $dst_dir: $!\n";
        }
    }

    if ($dry_run) {
        print "[DRY-RUN] copy $src_path -> $dst_path\n";
    }
    else {
        copy( $src_path, $dst_path )
          or die "Failed to copy $src_path to $dst_path: $!\n";
        print "Copied: $src_path -> $dst_path\n";
    }

    $copied++;
}

if ($dry_run) {
    print "\nDry run complete. Missing files found: $copied\n";
}
else {
    print "\nDone. Files copied: $copied\n";
}

exit 0;

sub expand_tilde {
    my ($path) = @_;
    $path =~ s{^~(?=/|$)}{$ENV{HOME}}e;
    return $path;
}

sub usage {
    my ($exit_code) = @_;

    print <<'USAGE';
Copy shader files that exist in source but are missing in destination.
New files are copied into sorted folders in destination:
    - material_* -> material/
    - starts with digit -> 0-9/
    - starts with letter -> A-Z/ (uppercase letter folder)

Usage:
    copy_missing_shaders.pl [--src PATH] [--dst PATH] [--exts csv] [--dry-run]

Defaults:
  --src ~/gpu/acidcam-gpu/shaders
  --dst ~/gpu/shaders_repo/shaders

Options:
  --src PATH   Source shader directory
  --dst PATH   Destination shader directory
    --exts csv   Comma-separated shader extensions (default: glsl,frag,vert,geom,comp,tese,tesc)
  --dry-run    Show what would be copied, but make no changes
  --help       Show this help
USAGE

    exit $exit_code;
}

sub destination_bucket {
    my ($name) = @_;

    return 'material' if $name =~ /^material_/i;
    return '0-9'      if $name =~ /^[0-9]/;

    if ( $name =~ /^([A-Za-z])/ ) {
        return uc($1);
    }

    return '0-9';
}

sub is_allowed_shader_file {
    my ( $name, $allowed_ext_ref ) = @_;

    return 0 unless $name =~ /\.([^.]+)$/;
    my $ext = lc($1);
    return exists $allowed_ext_ref->{$ext};
}
