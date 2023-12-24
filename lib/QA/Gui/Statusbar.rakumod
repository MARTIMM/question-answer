use v6.d;

use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk4::Statusbar:api<2>;
use Gnome::Gtk4::StyleContext:api<2>;

use QA::Status;

#-------------------------------------------------------------------------------
unit class QA::Gui::Statusbar:auth<github:MARTIMM>;
also is Gnome::Gtk4::Statusbar;

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

  my Gnome::Gtk4::StyleContext $context .= new(
    :native-object(self.get-style-context)
  );
  $context.add-class('QAStatusbar');

  self!listen-status;
}

#-------------------------------------------------------------------------------
method !listen-status ( ) {
  my QA::Status $status .= instance;
  $status.tap( -> Hash $status-info {
#note 'sts info: ', $status-info.gist;

      # Test for statusbar messages
      if $status-info<statusbar>:exists {

        # Get a context id only when nesessary, i.e. 
        %!cids{$status-info<msg-id>} //= self.get-context-id($status-info<msg-id>);

        my $cid = %!cids{$status-info<msg-id>};
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

#        else {
#          note 'sts: ', $status-info;
#        }
      }   # if $status-info<statusbar>:exists
    }     # Hash $status-info
  );      # tap
}
