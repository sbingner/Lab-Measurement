package Lab::Instrument::ITC;

use strict;
use Lab::Instrument;

our $version = '3.10';
our @ISA=('Lab::Instrument');


our %fields = (
	supported_connections => [ 'VISA', 'VISA_GPIB', 'GPIB', 'VISA_RS232', 'RS232', 'IsoBus', 'DEBUG' ],

	# default settings for the supported connections
	connection_settings => {
		gpib_board => undef,
		gpib_address => undef,
		baudrate => 9600,
		databits => 8,
		stopbits => 2,
		parity => 'none',
		handshake => 'none',
		termchar => "\r",
		timeout => 2,
	},

	device_settings => { 
		read_default => 'device'
	},
	
	device_cache =>{
		id => 'Oxford ITC',
		#T => undef,
		proportional => undef,
		integral => undef,
		derivative => undef

	}

);

sub new {
	my $proto = shift;
	my $class = ref($proto) || $proto;
	my $self = $class->SUPER::new(@_);
	$self->${\(__PACKAGE__.'::_construct')}(__PACKAGE__);
	
	return $self;
}

sub _device_init {
	my $self = shift;

	$self->_set_control(3); # REMOTE & unlocked
    $self->connection()->Clear();
}

# sub _clear { # internal only
	# my $self = shift;
	# my $status;
	# my $timeout = 100;
	
	# if ( $self->{CONNECTION_TYPE} eq 'GPIB' )
		# {
		# my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, $timeout);
		# if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting TIMEOUT VALUE: $status";}
		# }
	# elsif ( $self->{CONNECTION_TYPE} eq 'RS232' )
		# {
		# my $status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, $timeout);
		# if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting TIMEOUT VALUE: $status";}
		# }
	
	# while(1) {
		# if ($self->read(100) =~ /ERROR/) 
			# {last;}
		# }
		
	# if ( $self->{CONNECTION_TYPE} eq 'GPIB' )
		# {
		# my $status=Lab::VISA::viSetAttribute($self->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, 3000);
		# if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting TIMEOUT VALUE: $status";}
		# }
	# elsif ( $self->{CONNECTION_TYPE} eq 'RS232' )
		# {
		# my $status=Lab::VISA::viSetAttribute($self->{vi}->{config}->{RS232}->{vi}->{instr},  $Lab::VISA::VI_ATTR_TMO_VALUE, 3000);
		# if ($status != $Lab::VISA::VI_SUCCESS) { die "Error while setting TIMEOUT VALUE: $status";}
		# }
	
	
# }

# sub _init { # internal only
	# my $self = shift;
	
	# $self->_set_control(3); # REMOTE & unlocked
	# $self->set_heatercontrol("MAN"); 
	# $self->set_heateroutput(0);
	# $self->set_heatersensor(1); 
	# $self->_set_heaterlimit(25);	#max would be 40V
	# $self->set_PID(15,0.1,1);
	# $self->set_T(0);	
	
# }

sub _get_parameter { # internal only
# 0 Demand SET TEMPERATURE     
# 1 Sensor 1 Temperature     
# 2 Sensor 2 Temperature     
# 3 Sensor 3 Temperature     
# 4 Temperature Error (+ve when SET>Measured)
# 5 Heater O/P (as % of current limit)
# 6 Heater O/P (as Volts, approx)
# 7 Gas Flow O/P (arbitratry units)
# 8 Proportional Band
# 9 Integral Action Time
#10 Derivative Actionb Time
#11 Channel 1 Freq/4
#12 Channel 2 Freq/4
#13 Channel 3 Freq/4

    my $self=shift;
    my $parameter=shift;
	
	if ( $parameter != 0 and $parameter != 1 and  $parameter != 2 and $parameter != 3 and $parameter != 4 and $parameter != 5 and $parameter != 6 and $parameter != 7 and $parameter != 8 and $parameter != 9 and $parameter != 10 and $parameter != 11 and $parameter != 12 and $parameter != 13)
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for MODE in sub read_parameter. Expected values are:\n 0 --> Demand SET TEMPERATURE\n 1 --> Sensor 1 Temperature\n 2 --> Sensor 2 Temperature\n 3 --> Sensor 3 Temperature\n 4 --> Temperature Error (+ve when SET>Measured)\n 5 --> Heater O/P (as % of current limit)\n 6 --> Heater O/P (as Volts, approx)\n 7 --> Gas Flow O/P (arbitratry units)\n 8 --> Proportional Band\n 9 --> Integral Action Time\n10 --> Derivative Actionb Time\n11 --> Channel 1 Freq/4\n12 --> Channel 2 Freq/4\n13 --> Channel 3 Freq/4");
		}
	
    my $cmd=sprintf("R%d\r",$parameter);
    my $result=$self->query($cmd);
    chomp $result;
    $result =~ s/^R//;
    return sprintf("%e",$result);
}

sub get_value {
	my $self = shift;
	my ($sensor, $read_mode) = $self->_check_args( \@_, ['channel', 'read_mode'] );
	
	return $self->get_T($sensor, $read_mode);
}

sub get_T { # basic
	my $self=shift;
	my ($sensor, $read_mode) = $self->_check_args( \@_, ['channel', 'read_mode'] );
	
	if ( $sensor != 1 and $sensor != 2 and $sensor != 3)
		{
		$sensor = 1;
		}
		
	my $cmd=sprintf("R%d\r",$sensor);
		
	if (not defined $read_mode or not $read_mode =~ /device|cache|request|fetch/)
    {
        $read_mode = $self->device_settings()->{read_default};
    }
	
	if($read_mode eq 'cache' and defined $self->{'device_cache'}->{'T'})
    {
     	return $self->{'device_cache'}->{'T'};
    } 
	elsif($read_mode eq 'request')
    {
		if ($self->{'request'} != 0) {
    		$self->read();
    	}
		$self->write($cmd);
		$self->{'request'} = 1;
		return;
	}
	elsif ( $read_mode eq 'fetch' and $self->{'request'} == 1 )
	{
		$self->{'request'} = 0;
		my $result = $self->read();
		chomp $result;
		$result =~ s/^R//;
		return $self->device_cache()->{T} = $result;
	}
	else {
		$self->{'request'} = 0;
		my $result = $self->query($cmd);
		chomp $result;
		$result =~ s/^R//;
		return $self->device_cache()->{T} = $result;
	}
	
}

sub set_T { # basic
#  Setpoint 
    my $self=shift;
    my ($value) = $self->_check_args( \@_, ['value'] );
	
	if ( not defined $value or $value > 200 or $value < 0)
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for SETPOINT in sub set_T. Expected values are between 0 .. 200 K");
		}
		
    $value=sprintf("%.3f",$value);
    $self->query("T$value\r");
}

sub _get_version { # internal only
	my $self = shift;
	return $self->query("V\r");
}
  
sub _get_status { # internal only
# Examine Status
    my $self=shift;
    return $self->query("X\r");
	
}   

sub _set_control { # don't use it if you get an error message during reading out sensors:"Cading Sensor"; # internal only
# 0 Local & Locked
# 1 Remote & Locked
# 2 Local & Unlocked
# 3 Remote & Unlocked
    my $self=shift;
    my ($mode) = $self->_check_args( \@_, ['mode'] );
	
	if ( $mode != 0 and $mode != 1 and $mode != 2 and $mode != 3 )
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for MODE in sub _set_control. Expected values are:\n 0 --> Local & Locked\n 1 --> Remote & Locked\n 2 --> Local & Unlocked\n 3 --> Remote & Unlocked");
		}
    my $cmd=sprintf("C%d\r",$mode);
    $self->query($cmd);
    sleep(1);
}

#
sub _set_communicationsprotocol { # internal only
# 0 "Normal" (default)
# 2 Sends <LF> after each <CR>
    my $self=shift;
    my ($mode) = $self->_check_args( \@_, ['mode'] );
	
	if ( $mode != 0 and $mode != 2 )
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for MODE in sub set_comunicationsprotocol. Expected values are:\n 0 --> Normal (default)\n 2 --> Sends <LF> after each <CR>");
		}
	
    $self->write("Q$mode\r"); #no aswer from IPS expected
}

sub set_heatercontrol { # basic
# 0 Heater Manual, Gas Manual;
# 1 Heater Auto, Gas Manual
# 2 Heater Manual, Gas Auto
# 3 Heater Auto, Gas Auto
    my $self=shift;
    my ($mode) = $self->_check_args( \@_, ['mode'] );
		
	if ( $mode =~/\b(MANUAL|manual|MAN|man)\b/ )
		{
		$self->query("A0\r");
		}
	elsif ( $mode =~/\b(AUTOMATIC|automatic|AUTO|auto)\b/ )
		{
		$self->query("A1\r");
		}
	else
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for MODE in sub set_heatercontrol. Expected values are:\n 0 --> Heater Manual, Gas Manual\n 1 --> Heater Auto");
		}
	
}

sub set_proportional { # internal only
    my $self=shift;
    my ($value) = $self->_check_args( \@_, ['value'] );
	
    $value=sprintf("%d",$value);
    $self->query("P$value\r");
}

sub get_proportional {
}

sub set_integral { # internal only
    my $self=shift;
    my ($value) = $self->_check_args( \@_, ['value'] );
	
    $value=sprintf("%d",$value);
    $self->query("I$value\r");
}

sub get_integral {
}

sub set_derivative { # internal only
    my $self=shift;
    my ($value) = $self->_check_args( \@_, ['value'] );
	
    $value=sprintf("%d",$value);
    $self->query("D$value\r");
}

sub get_derivative {
}

sub set_PID { # basic
	my $self = shift;
	my ($P, $I, $D) = $self->_check_args( \@_, ['P', 'I', 'D'] );
	
	if ((not defined $P or not defined $I or not defined $D) and ( $P ne "auto" or $P ne "AUTO" or $P ne "man" or $P ne "MAN"))
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected values for PID in sub set_PID. Exactly three arguments are required.");
		}
	
	if ( $P eq "auto" or $P eq "AUTO" )
		{
		$self->query("L1\r"); # enable AUTO-PID
		}
	elsif ($P eq "man" or $P eq "MAN")
		{
		$self->query("L0\r"); # disable AUTO-PID
		}
	else 
		{
		$self->query("L0\r"); # disable AUTO-PID
		$self->set_proportional($P);
		$self->set_integral($I);
		$self->set_derivative($D);
		}

}

sub set_heatersensor { # basic
# 1 Sensor 1
# 2 Sensor 2
# 3 Sensor 3
    my $self=shift;
    my ($sensor) = $self->_check_args( \@_, ['channel'] );

	if ( $sensor != 1 and $sensor != 2 and $sensor != 3)
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for SENSOR in sub set_heatersensor. Expected values are:\n 1 --> Sensor #1\n 2 --> Sensor #2\n 3 --> Sensor #3");
		}
	
    $self->query("H$sensor");
}

sub _set_heaterlimit { # internal only
# in steps of 0.1 V;  MAX = 40V --> 80W at 20 Ohm load
# 0 dynamical varying limit
    my $self=shift;
    my ($limit) = $self->_check_args( \@_, ['value'] );
	
	if ( not defined $limit or $limit > 40 or $limit < 0)
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for LIMIT in sub _set_heaterlimit. Expected values are between 0 .. 40 V");
		}
 
    $self->query("M$limit\r");
}

sub set_heateroutput { # basic
# from 0 to 99.9 % of HEATERLIMIT.
    my $self=shift;
    my ($value) = $self->_check_args( \@_, ['value'] );

	if ( not defined $value or $value > 99.9 or $value < 0)
		{
		Lab::Exception::CorruptParameter->throw( error => "unexpected value for OUTPUT in sub set_heateroutput. Expected values are between 0 .. 999. (100 == 10.0% * HEATERLIMIT.)");
		}
	
    $self->query("O$value\r");
}





####################################################################################################
####    TEMPERATURE-SWEEP not implemented yet ######################################################
####################################################################################################


#sub itc_sweep {
# 0 Stop Sweep 
# 1 Start Sweep
#nn=2P-1 Sweeping to step P
#nn=2P Sweeping to step P
#    my $self=shift;
#    my $value=shift;
#    $value=sprintf("%d",$value);
#    $self->query("S$value\r");
#}

#sub itc_set_pointer{
# Sets Pointer in internal ITC memory
#    my $self=shift;
#    my $x=shift;
#    my $y=shift;
#    if ($x<0 or $x>128){ printf "x=$x no valid ITC Pointer value\n";die };
#    if ($y<0 or $y>128){ printf "y=$y no valid ITC Pointer value\n";die };
#    my $cmd=sprintf("x%d\r",$x);
#    $self->query($cmd);
#    $cmd=sprintf("y%d\r",$y);
#    $self->query($cmd);
#}

#sub itc_program_sweep_table{
#    my $self=shift;
#    my $setpoint=shift; #K Sweep Stop Point
#    my $sweeptime=shift; #Min. Total Sweep Time
#    my $holdtime=shift; #sec. Hold Time
    
#    if ($setpoint<0. or $setpoint >9.9){printf "Cannot reach setpoint: $setpoint\n";die};
    
#    $self->itc_set_pointer(1,1);
#    $setpoint=sprintf("%1.4f",$setpoint);
#    $self->query("s$setpoint\r");

#    $self->itc_set_pointer(1,2);
#   $sweeptime=sprintf("%.4f",$sweeptime);
#    $self->query("s$sweeptime\r");    
    
#    $self->itc_set_pointer(1,3);
#    $holdtime=sprintf("%.4f",$holdtime);
#    $self->query("s$holdtime\r");
    
#    $self->itc_set_pointer(0,0);
#}

#sub itc_read_sweep_table {
# Clears Sweep Program Table
#    my $self=shift;
#    $self->query("r\r");
#}

#sub itc_clear_sweep_table {
# Clears Sweep Program Table
#    my $self=shift;
#    $self->query("w\r");
#}

1;

=head1 NAME

	Lab::Instrument::ITC - Oxford Instruments ITC Intelligent Temperature Control

.

=head1 SYNOPSIS

	use Lab::Instrument::ITC;
	my $irc=new Lab::Instrument::ILM($gpibadaptor,3);

.

=head1 DESCRIPTION

The Lab::Instrument::ITC class implements an interface to the Oxford Instruments

=head1 CONSTRUCTOR

	my $itc=new Lab::Instrument::ITC($isobus,$addr);

Instantiates a new ITC object, for example attached to the IsoBus device 
(of type C<Lab::Instrument::IsoBus>) C<$IsoBus>, with IsoBus address C<$addr>. 
All constructor forms of C<Lab::Instrument> are available.

.

=head1 METHODS

=head2 get_T

	$temperature=$itc->get_T(<$sensor>);

Returns the value of the selected temperature sensor.

=over 4

=item $sensor

SENSOR is an optional parameter and can be 1, 2 or 3.
If not defined DEF = 1.

=back

.

=head2 set_T

	$temperature=$itc->set_T($temperature);

Set target value for the temperature control circuit.

=over 4

=item $temperature

TEMPERATURE can be between 0 ... 200 K.

=back

.

=head2 set_heatercontrol

	$temperature=$itc->set_heatercontrol($mode);

Set HEATER CONTROL to MANUAL or AUTOMATIC.

=over 4

=item $mode

MODE can be MANUAL, MAN, AUTOMATIC or AUTO.

=back

.

=head2 set_PID

$temperature=$itc->set_PID($P, $I, $D);

Set the PID-values for the temperature control circuit.

=over 4

=item $P

PROPORTIONAL element

=item $I

INTEGRAL element

=item $D

DERIVATIVE element

=back

.

=head2 set_heatersensor

$temperature=$itc->set_heatersensor($sensor);

Select the C<SENSOR> to be used for the temperature control circuit.

=over 4

=item $sensor

SENSOR can be 1, 2 or 3. DEFAULT = 1.

=back

.

=head2 set_heateroutput

$temperature=$itc->set_heateroutput($percent);

Set the power for the C<HEATER OUTPUT> in percent of full range defined by C<HEATER LIMIT>.

=over 4

=item $percent

PERCENT can be 0 ... 99.9.

=back

.

=head1 CAVEATS/BUGS

probably many

.

=head1 SEE ALSO

=over 4

=item L<Lab::Instrument>

=back

.

=head1 AUTHOR/COPYRIGHT

This is $Id: ITC503.pm 618 2010-04-15 10:16:04Z huettel $

Copyright 2010 David Kalok and Andreas K. H�ttel (L<http://www.akhuettel.de/>)

Modified 2011 by Stefan Geissler

This library is free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

.

=cut