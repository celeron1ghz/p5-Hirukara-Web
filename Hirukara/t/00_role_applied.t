use Test::AllModules;
BEGIN {
    all_ok(
        search_path => 'Hirukara::Command',
        use => 1,
        check => {
            moose_role_applied => sub {
                my($clazz,$idx) = @_;
                $clazz->can('does') && $clazz->does('MooseX::Getopt')
            },
            hirukara_role_applied => sub {
                my($clazz,$idx) = @_;
                $clazz->can('does') && $clazz->does('Hirukara::Command')
            },
        },
        except => [
            qr/^Hirukara::Command$/,
            qr/^Hirukara::Command::Exhibition$/,
        ],
    );
}
