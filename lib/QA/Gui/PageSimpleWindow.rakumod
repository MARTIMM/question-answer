#tl:1:QA::Gui::PageWindow
use v6.d;

#use Gnome::N::X;
use Gnome::N::GlibToRakuTypes;

use Gnome::Gtk3::Enums;
use Gnome::Gtk3::Button;
use Gnome::Gtk3::Widget;
use Gnome::Gtk3::Box;
use Gnome::Gtk3::Grid;
use Gnome::Gtk3::Dialog;

use QA::Types;
use QA::Status;

use QA::Gui::YNMsgDialog;
use QA::Gui::OkMsgDialog;
use QA::Gui::PageTools;
#use QA::Gui::QALabel;

#-------------------------------------------------------------------------------
=begin pod
=head1 QA::Gui::PageSimpleWindow

=end pod

unit class QA::Gui::PageSimpleWindow:auth<github:MARTIMM>;
also does QA::Gui::PageTools;

#-------------------------------------------------------------------------------
has Bool $!show-cancel-warning;
has Int $!response;
has Gnome::Gtk3::Widget $!widget;
has Any $!result-handler-object;
has Str $!result-handler-method;

#-------------------------------------------------------------------------------
submethod BUILD (
  Str :$!qst-name, Hash :$user-data? is copy,
  Bool :$!show-cancel-warning = True, Bool :$!save-data = True,
  Gnome::Gtk3::Widget :$!widget,
  Any :$!result-handler-object?, Str :$!result-handler-method?
) {
  $!qst .= new(:$!qst-name);
  self.load-user-data($user-data);
  self.set-style('QAPageSimple');

  # todo width and height spec must go to sets
  with $!qst {
    $!widget.set-border-width(2);
    $!widget.set-size-request( .width, .height) if ? .width and ? .height;
  }

  # set the grid and fill it
  self.set-grid($!widget);
  self.set-grid-content($!widget);

  # add some buttons specific for this
  with my Gnome::Gtk3::Grid $button-grid .= new {
    with my Gnome::Gtk3::Box $strut .= new {
      .set-hexpand(True);
      .set-vexpand(False);
      .set-halign(GTK_ALIGN_START);
      .set-valign(GTK_ALIGN_START);
      .set-margin-top(0);
      .set-margin-start(0);
    }
    .attach( $strut, 0, 0, 1, 1);

    my $button = self.create-button(
      'cancel', :method-object(self), :method-name<cancel-response>
    );

    .attach( $button, 1, 0, 1, 1) if ?$button;


    $button = self.create-button(
    'save-quit', :method-object(self), :method-name<ok-response>
    );
    .attach( $button, 2, 0, 1, 1) if ?$button;


    $button = self.create-button(
    'save-continue', :method-object(self), :method-name<apply-response>
    );
    .attach( $button, 3, 0, 1, 1) if ?$button;


    $button = self.create-button(
    'help-info', :method-object(self), :method-name<help-response>
    );
    .attach( $button, 4, 0, 1, 1) if ?$button;
  }
  $!grid.attach( $button-grid, 0, 2, 1, 1);

  QA::Status.instance.clear-status;
}

#-------------------------------------------------------------------------------
method cancel-response ( ) {
  note 'cancel-response';

  if self.show-cancel {
    $!widget.destroy;
  }
}

#-------------------------------------------------------------------------------
method ok-response ( ) {

  my QA::Status $status .= instance;

  if $status.faulty-state {
    self.show-message(
      "There are still missing or wrong answers, cannot save data"
    );
  }

  else {
    self.save-data;

    if ?$!result-handler-object and
        $!result-handler-object.^can($!result-handler-method) {
      $!result-handler-object."$!result-handler-method"($!result-user-data);
    }

    $!widget.destroy;
  }
}

#-------------------------------------------------------------------------------
method apply-response ( ) {

  my QA::Status $status .= instance;

  if $status.faulty-state {
    self.show-message(
      "There are still missing or wrong answers, cannot save data"
    );
  }

  else {
    self.save-data;

    if ?$!result-handler-object and
        $!result-handler-object.^can($!result-handler-method) {
      $!result-handler-object."$!result-handler-method"($!result-user-data);
    }
  }
}

#-------------------------------------------------------------------------------
method help-response ( ) {

  my Str $text = $!qst.button-map<help-info><message>;
  self.show-message($text) if ?$text;
}

#-------------------------------------------------------------------------------
method show-sheet ( ) {
  $!widget.show-all;
}

#-------------------------------------------------------------------------------
method show-message ( Str:D $message --> Int ) {
  my QA::Gui::OkMsgDialog $ok .= new(:$message);
  my $r = $ok.run;
  $ok.destroy;

  $r
}

#-------------------------------------------------------------------------------
method show-cancel ( --> Bool ) {
  my Bool $done = True;
  if $!show-cancel-warning {
    my QA::Gui::YNMsgDialog $yn .= new(
      :message("Are you sure to cancel?\nAll changes will be lost!")
    );

    my $r = GtkResponseType($yn.run);
    $yn.destroy;
    $done = ( $r ~~ GTK_RESPONSE_YES );
  }

  $done
}
