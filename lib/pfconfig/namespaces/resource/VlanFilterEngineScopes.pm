package pfconfig::namespaces::resource::VlanFilterEngineScopes;

=head1 NAME

pfconfig::namespaces::resource::VlanFilterEngineScopes

=cut

=head1 DESCRIPTION

pfconfig::namespaces::resource::VlanFilterEngineScopes

=cut

use strict;
use warnings;
use pf::log;
use pfconfig::namespaces::config;
use pfconfig::namespaces::config::VlanFilters;
use pf::factory::condition::vlanfilter;
use pf::filter;
use pf::filter_engine;
use pf::condition_parser qw(parse_condition_string);

use base 'pfconfig::namespaces::resource';


sub build {
    my ($self)            = @_;
    my $config_profiles   = pfconfig::namespaces::config::VlanFilters->new($self->{cache});
    my %VlanFiltersConfig = %{$config_profiles->build};
    $self->{prebuilt_conditions} = {};
    my (%VlanFilterEngineScopes, @filter_data, %filters_scopes);
    foreach my $rule (@{$config_profiles->{ordered_sections}}) {
        my $data = $VlanFiltersConfig{$rule};
        if ($rule =~ /^\w+:(.*)$/) {
            my ($parsed_conditions, $msg) = parse_condition_string($1);
            next unless defined $parsed_conditions;
            push @filter_data, [$parsed_conditions, $data];
        }
        else {
            $self->{prebuilt_conditions}{$rule} = pf::factory::condition::vlanfilter->instantiate($data);
        }
    }

    foreach my $filter_data (@filter_data) {
        $self->build_filter(\%filters_scopes, @$filter_data);
    }
    while (my ($scope, $filters) = each %filters_scopes) {
        $VlanFilterEngineScopes{$scope} = pf::filter_engine->new({filters => $filters});
    }
    return \%VlanFilterEngineScopes;
}

sub build_filter {
    my ($self, $filters_scopes, $parsed_conditions, $data) = @_;
    push @{$filters_scopes->{$data->{scope}}}, pf::filter->new({
        answer    => $data,
        condition => $self->build_filter_condition($parsed_conditions)
    });
}

sub build_filter_condition {
    my ($self, $parsed_condition) = @_;
    if (ref $parsed_condition) {
        local $_;
        my ($type, @parsed_conditions) = @$parsed_condition;
        my $conditions = [map {$self->build_filter_condition($_)} @parsed_conditions];
        if($type eq 'NOT' ) {
            return pf::condition::not->new({condition => $conditions->[0]});
        }
        my $module = $type eq 'AND' ? 'pf::condition::all' : 'pf::condition::any';
        return $module->new({conditions => $conditions});
    }
    else {
        return $self->{prebuilt_conditions}->{$parsed_condition};
    }
}

=head1 AUTHOR

Inverse inc. <info@inverse.ca>

=head1 COPYRIGHT

Copyright (C) 2005-2015 Inverse inc.

=head1 LICENSE

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
USA.

=cut

1;
