package LANraragi::Controller::Backup;
use Mojo::Base 'Mojolicious::Controller';
use File::Temp qw(tempfile);

use LANraragi::Utils::Generic    qw(generate_themes_header);
use LANraragi::Utils::TempFolder qw(get_temp);
use LANraragi::Model::Backup;

# This action will render a template
sub index {
    my $self = shift;

    #GET with a parameter => do backup
    if ( $self->req->param('dobackup') ) {
        my $json = LANraragi::Model::Backup::build_backup_JSON();

        # Write json to file in temp and serve that file through render_static
        my ( $fh, $outfile ) = tempfile();

        print {$fh} $json;
        close $fh;

        $self->render_file( filepath => $outfile, filename => "backup.json", cleanup => 1 );

    } else {    #Get with no parameters => Regular HTML printout
        $self->render(
            template => "backup",
            title    => $self->LRR_CONF->get_htmltitle,
            descstr  => $self->LRR_DESC,
            csshead  => generate_themes_header($self),
            version  => $self->LRR_VERSION
        );
    }
}

sub restore {
    my $self = shift;
    my $file = $self->req->upload('file');

    if ( $file->headers->content_type eq "application/json" ) {

        my $json = $file->slurp;
        LANraragi::Model::Backup::restore_from_JSON($json);

        $self->render(
            json => {
                operation => "restore_backup",
                success   => 1
            }
        );
    } else {
        $self->render(
            json => {
                operation => "restore_backup",
                success   => 0,
                error     => "Not a JSON file."
            }
        );
    }
}

1;
