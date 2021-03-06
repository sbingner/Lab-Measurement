package Lab::Connection::LinuxGPIB::Log;
#ABSTRACT: Add logging capability to the LinuxGPIB connection

use 5.010;
use warnings;
use strict;

use parent 'Lab::Connection::LinuxGPIB';

use Role::Tiny::With;
use Carp;
use autodie;

our %fields = (
    logfile   => undef,
    log_index => 0,
);

with 'Lab::Connection::Log';

1;

