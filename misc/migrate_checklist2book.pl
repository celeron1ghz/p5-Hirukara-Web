use strict;
use Hirukara;
use Encode;
use Log::Minimal;
my $h = Hirukara->bootstrap;

my @circles = $h->db->select(circle => { comiket_no => 'ComicMarket89' })->all;
my $txn = $h->db->txn_scope;

for my $c (@circles)    {
    my $id = $c->id;

    #my @book = $h->db->select(circle_book => { circle_id => $id })->all;
    my $book = $h->run_command('circle_book.create', { circle_id => $id, created_by => 'hirukara' });
    my @chk = $h->db->select(checklist => { circle_id => $id })->all;

    for my $chk (@chk)  {
        local *CORE::GLOBAL::time = sub { $chk->created_at };

        $h->run_command('circle_order.update', {
            circle_id => $id,
            book_id   => $book->id,
            count     => $chk->count,
            member_id => $chk->member_id,
            comment   => $chk->comment || '',
        });
    }
}

$txn->commit;
