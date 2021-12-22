use v6.d;

use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk3::Statusbar;
use Gnome::Gtk3::StyleContext;

use QA::Status;

#-------------------------------------------------------------------------------
unit class QA::Gui::Statusbar;
also is Gnome::Gtk3::Statusbar:auth<github:MARTIMM>;

#-------------------------------------------------------------------------------
has %!cids = %();
has %!mids = %();

#-------------------------------------------------------------------------------
method new ( |c ) {
  self.bless( :GtkStatusbar, |c)
}

#-------------------------------------------------------------------------------
submethod BUILD ( ) {

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

      # Test for statusbar messages
      if $status-info<statusbar>:exists {
        %!cids{$status-info<id>} //= self.get-context-id($status-info<id>);

        my $cid = %!cids{$status-info<id>};
        my Str $message = $status-info<message> // '';
        my Str $msg-id = $status-info<msg-id> // '';

        if %!mids{$msg-id} and ?$status-info<drop-msg> {
          self.remove( $cid, %!mids{$msg-id});
          %!mids{$msg-id}:delete;
        }

        elsif $message and ?$status-info<set-msg> {
          # set message but prevent a second one
          %!mids{$msg-id} = self.statusbar-push( $cid, $message)
            unless %!mids{$msg-id};
        }

        else {
          note 'sts: ', $status-info;
        }
      }   # if $status-info<statusbar>:exists
    }     # Hash $status-info
  );      # tap
}
