package Lab::MooseInstrument::Common;
our $VERSION = '3.520';

use Moose::Role;
use MooseX::Params::Validate;

use Lab::MooseInstrument qw/
  validated_getter
  validated_setter
  /;
use Carp;

use namespace::autoclean;

sub cls {
    my ( $self, %args ) = validated_getter(@_);
    return $self->write( command => '*CLS', %args );
}

sub idn {
    my ( $self, %args ) = validated_getter(@_);
    return $self->query( command => '*IDN?', %args );
}

sub opc {
    my ( $self, %args ) = validated_getter(@_);
    return $self->write( command => '*OPC', %args );
}

sub opc_query {
    my ( $self, %args ) = validated_getter(@_);
    return $self->query( command => '*OPC?', %args );
}

sub opc_sync {
    my ( $self, %args ) = validated_getter(@_);
    my $one = $self->opc_query(%args);
    if ( $one ne '1' ) {
        croak "OPC query did not return '1'";
    }
    return $one;
}

sub wai {
    my ( $self, %args ) = validated_getter(@_);
    return $self->write( command => '*WAI', %args );
}

1;
