#
# $Id: Kakasi.pm,v 2.3 2003/05/26 04:59:05 dankogai Exp dankogai $

package Text::Kakasi;
use strict;
# use warnings; # 5.00503 does not have one!
use Carp;
require Exporter;
require DynaLoader;

use vars qw($VERSION $DEBUG @ISA @EXPORT_OK %EXPORT_TAGS $HAS_ENCODE);
$VERSION = do { my @r = (q$Revision: 2.3 $ =~ /\d+/g); sprintf "%d."."%02d" x $#r, @r };
@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(getopt_argv do_kakasi close_kanwadict);
%EXPORT_TAGS = (all => [qw(getopt_argv do_kakasi close_kanwadict)]);

bootstrap Text::Kakasi $VERSION;

$HAS_ENCODE = load_encode();

sub load_encode{
    $INC{Encode} and return 1;
    if ($] >= 5.008){
	eval { require Encode };
	$@ and return 0;
	eval { 
	    Encode->import(qw/find_encoding from_to _utf8_on _utf8_off/)
	};
	return $@ ? 0 : 1;
    }else{
	return 0;
    }
}

sub new{
    my $thingy = shift;
    my $class = ref $thingy ? ref $thingy : $thingy;
    my $self = bless {} => $class;
    @_ and $self->set(@_);
    return $self
}

my %k2p = 
    (
     oldjis => "7bit-jis",
     newjis => "7bit-jis",
     dec    => "euc-jp",
     euc    => "euc-jp",
     sjis   => "shiftjis",
    );

sub set{
    my $self = shift;
    my @argv;
    if ($HAS_ENCODE){
	for (@_){
	    if (/(-[io])\s*(\S+)/){
		my $name = $k2p{lc($2)} || $2;
		my $enc = find_encoding($name);;
		unless (ref $enc){
		    carp "encoding $name is not supported";
		    next;
		}
		$self->{$1} = $enc->name;
		# push @argv, "$1euc";
	    }else{
		push @argv, $_;
	    }
	}
    }else{
	@argv = @_;
    }
    my $error = getopt_argv(@argv);
    $error and 
	carp "Kakasi returned $error for ", join " " => @argv;
    $self->{error} = $error;
    $self->{argv}  = [ @argv ];
    return $self;
}

sub getopt_argv{
    my @argv = @_;
    $argv[0] and $argv[0] eq 'kakasi' or unshift @argv, 'kakasi';
    xs_getopt_argv(@argv);
}

sub error{ shift->{error} };

sub get{
    my $self   = shift; 
    my $str    = shift;
    if ($HAS_ENCODE){
	if ($self->{'-i'}){
	    $self->{'-i'} eq 'utf8' and _utf8_off($str);
	    from_to($str, $self->{'-i'} =>'eucjp');
	}
    }
    $str = do_kakasi($str);
    if (defined $str){
	$self->{error} = 0;
	if ($HAS_ENCODE){
	    if ($self->{'-o'}){
		from_to($str, 'eucjp' => $self->{'-o'});
		$self->{'-o'} eq 'utf8' and _utf8_on($str);
	    }
	}
    }else{
	warn;
	$self->{error} = 1;
    }
    return $str;
}

sub do_kakasi{
    my $str = shift;
    $str =~ tr/\0//d;
    return xs_do_kakasi($str);
}

sub close_kanwadict { xs_close_kanwadict() };

1;
__END__

=head1 NAME

Text::Kakasi - kakasi library module for perl

=head1 DESCRIPTION

This module provides interface to kakasi (kanji kana simple inverter).
kakasi is a set of programs and libraries which does what Japanese
input methods do in reverse order.  You feed Japanese and kakasi
converts it to phonetic representation thereof.  kakasi can also be
used to tokenizing Japanese text. To find more about kakasi, see
L<http://kakasi.namazu.org/> .

=cut
