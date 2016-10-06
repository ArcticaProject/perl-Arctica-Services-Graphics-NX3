################################################################################
#          _____ _
#         |_   _| |_  ___
#           | | | ' \/ -_)
#           |_| |_||_\___|
#                   _   _             ____            _           _
#    / \   _ __ ___| |_(_) ___ __ _  |  _ \ _ __ ___ (_) ___  ___| |_
#   / _ \ | '__/ __| __| |/ __/ _` | | |_) | '__/ _ \| |/ _ \/ __| __|
#  / ___ \| | | (__| |_| | (_| (_| | |  __/| | | (_) | |  __/ (__| |_
# /_/   \_\_|  \___|\__|_|\___\__,_| |_|   |_|  \___// |\___|\___|\__|
#                                                  |__/
#          The Arctica Modular Remote Computing Framework
#
################################################################################
#
# Copyright (C) 2015-2016 The Arctica Project
# http://http://arctica-project.org/
#
# This code is dual licensed: strictly GPL-2 or AGPL-3+
#
# GPL-2
# -----
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; version 2 of the License.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
#
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# AGPL-3+
# -------
# This programm is free software; you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.
#
# This programm is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this program; if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin St, Fifth Floor, Boston, MA 02110-1301, USA.
#
# Copyright (C) 2015-2016 Guangzhou Nianguan Electronics Technology Co.Ltd.
#                         <opensource@gznianguan.com>
# Copyright (C) 2015-2016 Mike Gabriel <mike.gabriel@das-netzwerkteam.de>
#
################################################################################
package Arctica::Services::Graphics::NX3::Server;
use strict;

use Arctica::Core::eventInit qw( genARandom BugOUT );
use Arctica::Core::ManageDirs qw( create_new_adir );
use Arctica::Core::Mother::Forker;

sub new {

    BugOUT(9,"NX3::Server new->ENTER");
    my $class_name = $_[0];# Be EXPLICIT!! DON'T SHIFT OR "@_";
    my $arctica_core_object = $_[1];
    my $the_tmpdir = $arctica_core_object->{'a_dirs'}{'tmp_adir'};

    my $dev_conf = $_[2];

    # sanitize parameters (or fail)

    # display: X11 display address (e.g. ":1", "localhost-ipv6:50", etc.)
    my $display = $dev_conf->{'display'};
    # FIXME: check provided value

    # bind_address: hostname, IPv6 address, IPv4 address, path to Unix file socket, special keyword "local"
    my $bind_address = $dev_conf->{'bind_address'};
    # FIXME: check provided value

    # bind_port: positive integer between 1025 and 60000
    my $bind_port = $dev_conf->{'bind_port'};
    # FIXME: check provided value

    # disabled_extensions: list of extensions that shall be disabled at NXv3 agent startup
    my $disabled_extensions = $dev_conf->{'disabled_extensions'};
    # FIXME: check provided value list

    # extra_options: list of additional NXv3 agent command line options
    my $extra_options = $dev_conf->{'extra_options'};
    # FIXME: check provided value list

    # instantiate the NXv3 agent forker
    my $forking_child = Arctica::Core::Mother::Forker->new($arctica_core_object, {
	child_name	=>	'nxagent',
	fork_style	=>	'interactive_pty',
#	handle_stdout	=>	\&my_stdout_handler,
	handle_stderr	=>	\&stderr2BugOUT_handler,
#	handle_death	=>	\&my_death_handler,
	return_stdin	=>	0,
	exec_hold	=>	1,
	env_strict	=>	1,
	env_pass	=> {
		'ARCTICA'	=> 1,
		'DISPLAY'	=> 1,
		'HOME'		=> 1,
		'TEMP'		=> 1,
		'USER'		=> 1,
		'XAUTHORITY'	=> 1,
	},
	env_set		=> {
		'NX_CLIENT'	=> '/usr/bin/arctica-services-graphics-nx3-server-callback',	# nxagent callback handler
#		'NX_HOME'	=> '',								# don't set!!!
#		'NX_ROOT'	=> $nx_root,							# will be set the next moment, see below...
#		'NX_SYSTEM'	=> '',								# don't set!!!
		'NX_TEMP'	=> '/tmp',							# set NX_TEMP to /tmp, make sure nxagent
												# starts when pam_tmpdir.so is in use
	},
	exec_path	=>	"/usr/bin/nxagent",
	exec_cl_argv	=>	[ "-nolisten", "tcp", "-ac", $display ],
#	on_exit	=>	\&my_on_exit_handler,
});

    # create NX_ROOT directory
    my $nx_root = $forking_child->new_empty_dir();
    $forking_child->envset_append('NX_ROOT', $nx_root);

    BugOUT(2,"Creating new NXv3 server object");

    my $self = {
	isArctica => 1, # Declare that this is an Arctica "something"
	aobject_name => "Graphics_NX3_Server",
	aobject_id => genARandom("id"),
	mode => '',
	display => $display,
	bind_address => $bind_address,
	bind_port => $bind_port,
	disabled_extensions => $disabled_extensions,
	extra_options => $extra_options,
	forker => $forking_child,
    };

    bless($self, $class_name);

    $arctica_core_object->{'aobj'}{'Services'}{$self->{'aobject_name'}}{$self->{'aobject_id'}}
	= \$self;

    BugOUT(9,"NX3::Server new->DONE");

    return $self;
}


sub reconfigure {
}

sub start {

    BugOUT(8,"Services::Graphics::Server::NX3 about to start()...");
    my $self = $_[0];

    $self->{'forker'}->run_child();

}

sub stop {

    BugOUT(8,"Services::Graphics::Server::NX3 about to stop()...");
    my $self = $_[0];

    $self->{'forker'}->signal('SIGTERM');

}

sub resume {

    BugOUT(8,"Services::Graphics::Server::NX3 about to resume()...");
    my $self = $_[0];

    # FIXME: check statefile and only if state is SUSPENDED:
    $self->{'forker'}->signal('SIGHUP');

}

sub suspend {

    BugOUT(8,"Services::Graphics::Server::NX3 about to suspend()...");
    my $self = $_[0];

    # FIXME: check statefile and only if state is RUNNING:
    $self->{'forker'}->signal('SIGHUP');

}

sub stderr2BugOUT_handler {
    BugOUT (2, "$_[0]\n");
}


1;
