use v6.d;

use QA::Gui::Frame;

use Gnome::Gtk4::Window:api<2>;

use Gnome::Glib::N-MainLoop:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
#use Gnome::N::X:api<2>;

#-------------------------------------------------------------------------------
my Gnome::Glib::N-MainLoop $main-loop .= new-mainloop;

#-------------------------------------------------------------------------------
class SH {
  method stopit ( --> gboolean ) {
    say 'close request';
    $main-loop.quit;

    0
  }
}

#-------------------------------------------------------------------------------
my SH $sh .= new;

my QA::Gui::Frame $frame .= new-frame('set data');

with my Gnome::Gtk4::Window $window .= new-window {
  .register-signal( $sh, 'stopit', 'close-request');
  .set-title('Test QA::Gui::Frame');
  .set-size-request( 300, 200);
  .set-child($frame);
  .show;
}

$main-loop.run;

