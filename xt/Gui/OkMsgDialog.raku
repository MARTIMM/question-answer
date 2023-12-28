use v6.d;
use NativeCall;

use QA::Gui::OkMsgDialog;

use Gnome::Gtk4::Window:api<2>;
use Gnome::Gtk4::Button:api<2>;

use Gnome::Glib::N-MainLoop:api<2>;

use Gnome::N::GlibToRakuTypes:api<2>;
use Gnome::N::X:api<2>;
Gnome::N::debug(:on);


#-------------------------------------------------------------------------------
my Gnome::Glib::N-MainLoop $main-loop .= new-mainloop;

#-------------------------------------------------------------------------------
class SH {
  method stopit ( --> gboolean ) {
    say 'close request';
    $main-loop.quit;

    0
  }

  method show-msg ( Gnome::Gtk4::Window :$window ) {

    my Str $message = q:to/EOTXT/;
      Ut consequatur ab sequi qui repellat. Laboriosam et consequuntur
      voluptatem. Nam porro a consequatur saepe. Eum beatae ratione
      fugiat et. Quasi modi eaque nulla voluptatem incidunt animi 
      exercitationem. Ea quas consequatur expedita dolore aut eveniet a.
      EOTXT

    my QA::Gui::OkMsgDialog $okidoki .= new( $message, $window);
    my $r = $okidoki.show;
#    $okidoki.destroy;

    note 'return code: ', $r;
  }
}

#-------------------------------------------------------------------------------
my SH $sh .= new;

my Gnome::Gtk4::Window $window .= new-window;

with my Gnome::Gtk4::Button $button .= new-with-label('show message') {
  .register-signal( $sh, 'show-msg', 'clicked', :$window);
}

with $window {
  .register-signal( $sh, 'stopit', 'close-request');
  .set-title('Test QA::Gui::QALabel');
  .set-child($button);
  .show;
}

$main-loop.run;

