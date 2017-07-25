package Lab::XPRESS::Sweep::VM_DIR;
#ABSTRACT: Vector magnet sweep

use Lab::XPRESS::Sweep::SweepND;
use Time::HiRes qw/usleep/, qw/time/;
use strict;

our @ISA = ('Lab::XPRESS::Sweep::SweepND');

sub new {
    my $proto                  = shift;
    my @args                   = @_;
    my $class                  = ref($proto) || $proto;
    my $self->{default_config} = {
        id                  => 'VectorMagnet_sweep',
        filename_extension  => 'VM_DIR=',
        dimension           => 3,
        convinience         => 0,
        interval            => 1,
        points              => [],
        duration            => [],
        mode                => 'continuous',
        coordinate_system   => 'cartesian',            # or 'spherical'
        allowed_instruments => [
            'Lab::Instrument::Vectormagnet',
            'Lab::Instrument::VectormagnetNoY'
        ],
        allowed_sweep_modes => [ 'continuous', 'list', 'step' ],
        number_of_points    => [undef]
    };

    $self = $class->SUPER::new( $self->{default_config}, @args );
    bless( $self, $class );
    return $self;
}

sub go_to_sweep_start {
    my $self = shift;

    # go to start:
    print "going to start ... ";

    @{ $self->{config}->{instrument} }[0]->config_DIR_sweep(
        @{ @{ $self->{config}->{points} }[0] },
        @{ $self->{config}->{rate} }[0],
        1, $self->{config}->{coordinate_system}
    );
    @{ $self->{config}->{instrument} }[0]->trg();
    @{ $self->{config}->{instrument} }[0]->wait();

    print "done\n";

}

sub start_continuous_sweep {
    my $self = shift;

    # continuous sweep:
    @{ $self->{config}->{instrument} }[0]->config_DIR_sweep(
        @{ @{ $self->{config}->{points} }[ $self->{sequence} + 1 ] },
        @{ $self->{config}->{rate} }[ $self->{sequence} + 1 ],
        1,
        $self->{config}->{coordinate_system}
    );
    @{ $self->{config}->{instrument} }[0]->trg();

}

sub go_to_next_step {
    my $self = shift;

    # step mode:
    @{ $self->{config}->{instrument} }[0]->config_DIR_sweep(
        @{ @{ $self->{config}->{points} }[ $self->{iterator} ] },
        @{ $self->{config}->{rate} }[ $self->{iterator} ],
        1,
        $self->{config}->{coordinate_system}
    );
    @{ $self->{config}->{instrument} }[0]->trg();
    @{ $self->{config}->{instrument} }[0]->wait();

}

sub exit_loop {
    my $self = shift;
    if ( not @{ $self->{config}->{instrument} }[0]->active() ) {
        if ( $self->{config}->{mode} =~ /step|list/ ) {
            if (
                not defined @{ $self->{config}->{points} }
                [ $self->{iterator} + 1 ] ) {
                return 1;
            }
            else {
                return 0;
            }
        }
        elsif ( $self->{config}->{mode} eq "continuous" ) {
            if (
                not defined @{ $self->{config}->{points} }
                [ $self->{sequence} + 2 ] ) {
                return 1;
            }
            $self->{sequence}++;
            @{ $self->{config}->{instrument} }[0]->config_DIR_sweep(
                @{
                    @{ $self->{config}->{points} }[ $self->{sequence} + 1 ]
                },
                @{ $self->{config}->{rate} }[ $self->{sequence} + 1 ],
                1,
                $self->{config}->{coordinate_system}
            );
            @{ $self->{config}->{instrument} }[0]->trg();

        }

        return 0;
    }
    else {
        return 0;
    }
}

sub get_value {
    my $self = shift;

    my @field = @{ $self->{config}->{instrument} }[0]
        ->get_field( $self->{coordinate_system} );

    return \@field;
}

sub exit {
    my $self = shift;
    @{ $self->{config}->{instrument} }[0]->abort();
}

1;

=encoding utf8

=head1 SYNOPSIS

	use Lab::XPRESS::hub;
	my $hub = new Lab::XPRESS::hub();


	my $IPS = $hub->Instrument('IPS',
		{
		connection_type => 'VISA_GPIB',
		gpib_address => 24
		});

	my $sweep_magnet = $hub->Sweep('Magnet',
		{
		instrument => $IPS,
		points => [-10,10],
		rate => [1.98,1],
		mode => 'continuous',
		interval => 1,
		backsweep => 1
		});

.

=head1 DESCRIPTION

Parent: Lab::XPRESS::Sweep

The Lab::XPRESS::Sweep::Magnet class implements a module for magnetic field Sweeps in the Lab::XPRESS::Sweep framework.

.

=head1 CONSTRUCTOR


	my $sweep_magnet = $hub->Sweep('Magnet',
		{
		instrument => $IPS,
		points => [-10,10],
		rate => [1.98,1],
		mode => 'continuous',
		interval => 1,
		backsweep => 1
		});

Instantiates a new Magnet-sweep.

.

=head1 SWEEP PARAMETERS

=head2 instrument [Lab::Instrument] (mandatory)

Instrument, conducting the sweep. Must be of type Lab:Instrument.
Allowed instruments: Lab::Instrument::IPS, Lab::Instrument::IPSWeiss1, Lab::Instrument::IPSWeiss2, Lab::Instrument::IPSWeissDillFridge

.

=head2 mode [string] (default = 'continuous' | 'step' | 'list')

continuous: perform a continuous magnetic field sweep. Measurements will be performed constantly at the time-interval defined in interval.

step: measurements will be performed at discrete values of the magnetic field between start and end points defined in parameter points, seperated by the magnetic field values defined in parameter stepwidth

list: measurements will be performed at a list of magnetic field values defined in parameter points

.

=head2 points [float array] (mandatory)

array of magnetic field values (in Tesla) that defines the characteristic points of the sweep.
First value is appraoched before measurement begins.

Case mode => 'continuous' :
List of at least 2 values, that define start and end point of the sweep or a sequence of consecutive sweep-sections (e.g. if changing the sweep-rate for different sections or reversing the sweep direction).
	 	points => [-5, 5]	# Start: -5 / Stop: 5

		points => [-5, -1, 1, 5]

		points => [0, -5, 5]

Case mode => 'step' :
Same as in 'continuous' but magnetic field will be swept in stop and go mode. I.e. Magnet approaches field values between start and stop at the interval defined in 'stepwidth'. A measurement is performed, when magnet is idle.

Case mode => 'list' :
Array of magnetic field values, with minimum length 1, that are approached in sequence to perform a measurment.

.

=head2 rate [float array] (mandatory if not defined duration)

array of rates, at which the magnetic field is swept (Tesla / min).
Has to be of length 1 or greater (Maximum length: length of points-array).
The first value defines the rate to approach the starting point.
The following values define the rates to approach the magnetic field values defined by the points-array.
If the number of values in the rates-array is less than the length of the points-array, the last defined rate will be used for the remaining sweep sections.


	points => [-5, -1, 1, 5],
	rates => [1, 0.5, 0.2]

	rate to approach -5 T (the starting point): 1 T/min
	rate to approach -1 T  : 0.5 T/min
	rate to approach 1 T  : 0.2 T/min
	rate to approach 5 T   : 0.2 T/min (last defined rate)

.


=head2 duration [float array] (mandatory if not defined rate)

can be used instead of 'rate'. Attention: Use only the 'duration' or the 'rate' parameter. Using both will cause an Error!

The first value defines the duration to approach the starting point.
The second value defines the duration to approach the magnetic field value defined by the second value of the points-array.
...
If the number of values in the duration-array is less than the length of the points-array, last defined duration will be used for the remaining sweep sections.

.

=head2 stepwidth [float array]

This parameter is relevant only if mode = 'step' has been selected.
Stepwidth has to be an array of length '1' or greater. The values define the width for each step within the corresponding sweep sequence.
If the length of the defined sweep sequence devided by the stepwidth is not an integer number, the last step will be smaller in order to reach the defined points-value.

	points = [0, 0.5, 3]
	stepwidth = [0.2, 0.5]

	==> steps: 0, 0.2, 0.4, 0.5, 1.0, 1.5, 2.0, 2.5, 3

.

=head2 number_of_points [int array]

can be used instead of 'stepwidth'. Attention: Use only the 'number_of_points' or the 'stepwidth' parameter. Using both will cause an Error!
This parameter is relevant only if mode = 'step' has been selected.
Number_of_points has to be an array of length '1' or greater. The values defines the number of steps within the corresponding sweep sequence.

	points = [0, 0.5, 3]
	number_of_points = [5, 2]

	==> steps: 0, 0.1, 0.2, 0.3, 0.4, 0.5, 1.75, 3

.

=head2 interval [float] (default = 1)

interval in seconds for taking measurement points. Only relevant in mode 'continuous'.

.

=head2 backsweep [int] (default = 0 | 1 | 2)

0 : no backsweep (default)
1 : a backsweep will be performed
2 : no backsweep performed automatically, but sweep sequence will be reverted every second time the sweep is started (relevant eg. if sweep operates as a slave. This way the sweep sequence is reverted at every second step of the master)

.

=head2 id [string] (default = 'Magnet_sweep')

Just an ID.

.

=head2 filename_extention [string] (default = 'B=')

Defines a postfix, that will be appended to the filenames if necessary.

.

=head2 delay_before_loop [int] (default = 0)

defines the time in seconds to wait after the starting point has been reached.

.

=head2 delay_in_loop [int] (default = 0)

This parameter is relevant only if mode = 'step' or 'list' has been selected.
Defines the time in seconds to wait after the value for the next step has been reached.

.

=head2 delay_after_loop [int] (default = 0)

Defines the time in seconds to wait after the sweep has been finished. This delay will be executed before an optional backsweep or optional repetitions of the sweep.

.

=head1 CAVEATS/BUGS

probably none

.

=head1 SEE ALSO

=over 4

=item L<Lab::XPRESS::Sweep>

=back

=cut