use v6.d;

use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk3::Statusbar;
use Gnome::Gtk3::StyleContext;

use QA::Status;

#use QA::Types;
#use QA::Gui::Frame;
#use QA::Question;
#use QA::Gui::Value;

#-------------------------------------------------------------------------------
unit class QA::Gui::Statusbar;
also is Gnome::Gtk3::Statusbar:auth<github:MARTIMM>:ver<0.1.0>;

#-------------------------------------------------------------------------------
#my QA::Gui::Statusbar $instance;
has %!cids = %();
has %!mids = %();

#-------------------------------------------------------------------------------
method new ( |c ) {
  self.bless( :GtkStatusbar, |c)
}

#-------------------------------------------------------------------------------
submethod BUILD ( ) {
  # need to catch this to invalidate the object after $dialog.widget-destroy()
  # is called. the destroy() method will destroy the native widget held in the
  # parent class. so next time, displaying the dialog again, gtk generates an
  # error;
  #
  # (SheetDialog.pl6:163411): Gtk-CRITICAL **: 12:30:43.336:
  # gtk_statusbar_get_context_id: assertion 'GTK_IS_STATUSBAR (statusbar)'
  # failed
  #
  # so next call must recreate the statusbar
#  self.register-signal( self, 'invalidate', 'destroy');

  %!cids = %();
  %!mids = %();

  my Gnome::Gtk3::StyleContext $context .= new(
    :native-object(self.get-style-context)
  );
  $context.add-class('QAStatusbar');

  self!listen-status;
}

#-------------------------------------------------------------------------------
method !listen-status ( ) {
  my QA::Status $status .= instance;
  $status.tap( -> Hash $status-info {
note "Status info: $status-info.raku()";

CONTROL { when CX::Warn {  note .gist; .resume; } }

      # Test for statusbar messages
      if $status-info<statusbar>:exists {
        %!cids{$status-info<id>} //= self.get-context-id($status-info<id>);

        my $cid = %!cids{$status-info<id>};
        my Str ( $kmsg, $vmsg ) = $status-info<message>.kv;
note "kv $cid: $kmsg, $vmsg";
        if %!mids{$kmsg} and !$vmsg {
          self.remove( $cid, %!mids{$kmsg});
          %!mids{$kmsg}:delete;
        }

        elsif $vmsg {
          %!mids{$kmsg} = self.statusbar-push( $cid, $vmsg);
        }

        else {
          note 'sts: ', $status-info;
        }
      }
    }
  );
}

#`{{
#-------------------------------------------------------------------------------
method instance ( |c --> QA::Gui::Statusbar ) {
  $instance //= self.bless( :GtkStatusbar, |c);

  $instance
}

#-------------------------------------------------------------------------------
method invalidate ( ) {
  $instance = Nil;
}
}}

#-------------------------------------------------------------------------------
#`{{
TODO add method to statusbar

method statusbar-push (
  guint $context_id, Str $text --> uint32
) {
note 'stb puch';
  callsame;
}
}}
