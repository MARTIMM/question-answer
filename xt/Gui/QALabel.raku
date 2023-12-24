use v6.d;

use QA::Gui::QALabel;

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

my QA::Gui::QALabel $qa-label .= new-label(q:to/EOTXT/);
  Ut consequatur ab sequi qui repellat. Laboriosam et consequuntur
  voluptatem. Nam porro a consequatur saepe. Eum beatae ratione
  fugiat et. Quasi modi eaque nulla voluptatem incidunt animi 
  exercitationem. Ea quas consequatur expedita dolore aut eveniet a.
  EOTXT

with my Gnome::Gtk4::Window $window .= new-window {
  .register-signal( $sh, 'stopit', 'close-request');
  .set-title('Test QA::Gui::QALabel');
  .set-child($qa-label);
  .show;
}

$main-loop.run;

