use v6.d;

use Gnome::Gtk3::Statusbar;

#use QAManager::QATypes;
#use QAManager::Gui::Frame;
#use QAManager::Question;
#use QAManager::Gui::Value;

#-------------------------------------------------------------------------------
unit class QAManager::Gui::Statusbar;
also is Gnome::Gtk3::Statusbar;

#-------------------------------------------------------------------------------
my QAManager::Gui::Statusbar $instance;

#-------------------------------------------------------------------------------
method new ( ) { !!! }

#-------------------------------------------------------------------------------
submethod BUILD ( ) {
  # need to catch this to invalidate the object after $dialog.widget-destroy()
  # is called. the destroy will destroy the native widget held in the parent
  # class. so next time, displaying the dialog again, gtk generates an error;
  #
  # (SheetDialog.pl6:163411): Gtk-CRITICAL **: 12:30:43.336:
  # gtk_statusbar_get_context_id: assertion 'GTK_IS_STATUSBAR (statusbar)'
  # failed
  #
  # so next call must recreate the statusbar
  self.register-signal( self, 'invalidate', 'destroy');
}

#-------------------------------------------------------------------------------
method instance ( |c --> QAManager::Gui::Statusbar ) {
  $instance //= self.bless( :GtkStatusbar, |c);

  $instance
}

#-------------------------------------------------------------------------------
method invalidate ( ) {
  $instance = Nil;
}
