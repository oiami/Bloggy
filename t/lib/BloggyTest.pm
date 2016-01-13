package BloggyTest;

use File::Copy;

sub init_data {
    copy('t/data/bloggy.db','t/data/bloggy.db.tmp') or die "Copy failed ~!!";
}

sub rollback_data {
    copy('t/data/bloggy.db.tmp','t/data/bloggy.db') or die "Copy failed ~!!";
}

1;